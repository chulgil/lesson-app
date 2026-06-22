# 레슨 요청 → 수강권 발급 통합 플로우 스펙

> 작성일: 2026-05-04 | 상태: **GAP 6건 구현 완료** (2026-05-04) — 테스트 6/6 PASS, 회귀 282 PASS
>
> 관련 스펙:
> - [unified_lesson_request_spec.md](../booking/unified_lesson_request_spec.md) — 레슨 요청 v2.0
> - [subscription_master.md](../subscription/subscription_master.md) — 수강권 v7
> - [lesson_request_api_spec.md](../schedule/lesson_request_api_spec.md) — API 엔드포인트
> - [backend_spec.md](backend_spec.md) — 백엔드 전체 현황

---

## 1. 전체 플로우 (End-to-End)

```
학생                                선생님
 │                                   │
 ├─ 선생님 선택                       │
 ├─ [레슨 요청 화면]                   │
 │   타입/악기/목표 + 시간 3개 제안      │
 │                                   │
 │ ──── POST /lesson-requests ────→  │
 │                            [알림 수신]
 │                            [3개 시간 확인]
 │                            [승인 or 역제안 or 거절]
 │                                   │
 │ (시간 합의 — 최대 2라운드)            │
 │ ←── timeConfirmed ──────────       │
 │                                   │
 │                            [수강권 템플릿 선택]
 │                            [제안 발송 or 즉시 발급]
 │ ←── proposalSent ───────────       │
 │                                   │
 │ [제안 수락]                         │
 │ [무통장 입금]                        │
 │ ["입금했어요" 버튼]                   │
 │                                   │
 │ ──── paymentNotified ─────→        │
 │                            [입금 확인 1탭]
 │                                   │
 │ ←── subscriptionIssued ─────       │
 │  ├ 수강권 생성                       │
 │  ├ 사제관계 활성화                    │
 │  └ 스케줄 확인 카드 생성              │
 │                                   │
 │ [확인 카드 응답]                     │
 │ ["이 시간으로 예약" or "다른 시간"]    │
 │                                   │
 │ ←── 레슨 자동 생성 ────────          │
```

---

## 2. RequestStatus 상태 전이

```
pending
  ↓ teacher approves 1 of 3 / student accepts alternative
negotiating (teacher counter-proposes)
  ↓ agreement reached (max 2 rounds)
timeConfirmed
  ↓ teacher sends subscription proposal
proposalSent
  ↓ student accepts proposal
proposalAccepted
  ↓ student notifies payment
paymentNotified
  ↓ teacher confirms payment (1 tap)
subscriptionIssued
  ↓ lessons begin
inProgress
  ↓ all lessons completed
completed
```

분기:
- `pending → cancelled` (어느 쪽이든 취소)
- `pending → expired` (기간 초과)
- `pending → rejected` (선생님 거절)

---

## 3. DB 테이블 관계

```
LessonRequest (schedule.py)
  ├── student_id → User
  ├── teacher_id → User
  ├── proposal_id → SubscriptionProposal  [⚠️ 미연결]
  └── status: RequestStatus (15값)

SubscriptionProposal (subscription.py)
  ├── teacher_id → User
  ├── student_id → User
  ├── lesson_request_id → LessonRequest   [⚠️ 미연결]
  ├── recommended_template_id → SubscriptionTemplate
  ├── selected_template_id → SubscriptionTemplate
  ├── subscription_id → Subscription
  └── status: ProposalStatus (6값)

Subscription (subscription.py)
  ├── student_id → User
  ├── membership_id → ClassMembership     [⚠️ 빈 문자열]
  ├── payment_confirmed: Boolean
  └── status: SubscriptionStatus (4값)

TeacherStudentRelation (relationship.py)
  ├── teacher_id → User
  ├── student_id → User
  └── status: RelationStatus (7값)

ScheduleConfirmationCard (schedule_ext 추정)
  ├── student_id → User
  ├── teacher_id → User
  └── status: ConfirmationCardStatus
```

---

## 4. 스펙 vs 구현 검증 결과

### ✅ 구현 완료 (정상)

| 단계 | 스펙 | 구현 | 검증 |
|------|------|------|------|
| 레슨 요청 생성 | 3타입 통합 + 시간 3개 제안 | `POST /lesson-requests` | ✅ |
| 시간 협상 | approve/counter/reject (2라운드) | `apply_action()` — 6개 액션 | ✅ |
| 수강권 템플릿 관리 | CRUD + 카드 UI | `GET/POST/PUT/DELETE /templates` | ✅ |
| 수강권 제안 생성 | 1~3개 템플릿 제안 | `POST /proposals` | ✅ |
| 학생 제안 응답 | 수락/거절 | `PATCH /proposals/{id}/respond` | ✅ |
| 입금 확인 → 수강권 생성 | 1탭 확인 | `confirm_proposal()` → Subscription 생성 | ✅ |
| 요청 이벤트 (챗) | 이벤트 로그 | `GET/POST /request-events` | ✅ |
| 캘린더 히트맵 | 날짜별 요청 수 | `GET /lesson-requests/calendar` | ✅ |
| 만료 처리 | 기간 초과 자동 만료 | `POST /lesson-requests/expire` | ✅ |

### ✅ 구현 완료 (6건 — 2026-05-04 해소)

#### GAP-1: LessonRequest ↔ SubscriptionProposal 연결 끊김

**스펙**: timeConfirmed 후 선생님이 수강권 제안 → 요청과 제안이 양방향 연결
**구현**: 양쪽에 FK 컬럼 존재하나 **어떤 코드도 값을 채우지 않음**

```python
# schedule.py — LessonRequest
proposal_id: Mapped[str | None]  # 사용되지 않음

# subscription.py — SubscriptionProposal
lesson_request_id: Mapped[str | None]  # 사용되지 않음
```

**필요 작업**:
- `create_proposal()` 호출 시 `lesson_request_id` 자동 채움
- proposal 생성 후 `LessonRequest.proposal_id` 역채움
- `LessonRequest.status` → `proposalSent`로 전이

#### GAP-2: confirm_proposal()에서 membership_id 미생성

**스펙**: 입금 확인 시 사제관계(ClassMembership) 자동 생성/연결
**구현**: `membership_id=""` 하드코딩

```python
# subscription_service.py — confirm_proposal()
sub = Subscription(
    membership_id="",  # ← 빈 문자열
    ...
)
```

**필요 작업**:
- ClassMembership 생성 또는 기존 membership 조회
- `Subscription.membership_id` 에 실제 ID 연결

#### GAP-3: confirm_proposal()에서 사제관계 미활성화

**스펙**: 수강권 발급 시 `TeacherStudentRelation.status → active`
**구현**: confirm_proposal()에 relationship 관련 코드 없음

**필요 작업**:
- `TeacherStudentRelation` 조회/생성
- `status → active` 전이
- 이미 active면 스킵

#### GAP-4: confirm_proposal()에서 스케줄 확인 카드 미생성

**스펙**: 수강권 발급 후 "이 시간으로 예약?" 카드 자동 생성
**구현**: 수동 API 호출로만 생성 가능

**필요 작업**:
- `confirm_proposal()` 마지막에 `ScheduleConfirmationCard` 자동 생성
- 신규 학생: 체험 시간 기반 / 재등록 학생: 이전 스케줄 기반

#### GAP-5: 확인 카드 승인 시 레슨 미생성

**스펙**: 학생이 확인 카드 승인 → 레슨 레코드 자동 생성
**구현**: `confirm_card()`는 카드 상태만 변경, 레슨 생성 코드 없음

**필요 작업**:
- Regular: 주간 반복 레슨 자동 생성 (수강권 totalLessons만큼)
- Package: 첫 레슨 생성
- Trial: 단일 레슨 생성
- LessonBooking 레코드도 함께 생성

> #301 주N회 (Option A): 자동 확인카드(`_create_confirmation_card`)는 **단일 대표 슬롯만**
> 운반한다(`proposed_day/time`). `LessonRequest.preferred_slots`는 **우선순위 대안**(priority
> 1·2·3 — 교사가 1개 선택)이지 동시 주간 슬롯이 아니므로 `proposed_slots`로 옮기지 않는다
> (옮기면 주1회+대안3개 학생이 주3회로 오생성됨). 주N회는 아래 standalone 경로에서만 생성.
> 생성기 자체는 `proposed_slots`가 채워져 있으면(standalone·수동 카드) 모든 슬롯에 주차별
> round-robin 분배한다(`_create_bookings_for_subscription`, PR #887).
>
> #301 standalone: 교사용 `register_regular_lesson_screen` → `POST /bookings`(`fixed_time_slots`)
> 가 N개 동시 주간 슬롯을 운반하면 `ScheduleService.create_booking`이 공유 헬퍼
> `_generate_recurring_lessons`(생성기에서 추출)로 위임해 동일하게 분배 생성한다. 회차는
> 구독 연동 시 `total_lessons`, 없으면 `lessons_per_week × 4`(1개월). FE 요일은 1=Mon..7=Sun
> → BE 0=Mon..6=Sun 변환. 마이그레이션 0.

#### GAP-6: RequestStatus 전이 불완전

**스펙**: 15개 상태 중 전체 전이 체인
**구현**: `apply_action()`이 처리하는 액션 6개만 (전반부만)

| 전이 | 스펙 | 구현 |
|------|------|------|
| pending → negotiating | approve/counter | ✅ |
| negotiating → timeConfirmed | accept | ✅ |
| timeConfirmed → proposalSent | 제안 발송 | ❌ 연결 없음 |
| proposalSent → proposalAccepted | 학생 수락 | ❌ 연결 없음 |
| proposalAccepted → paymentNotified | 입금 알림 | ❌ 연결 없음 |
| paymentNotified → subscriptionIssued | 입금 확인 | ❌ 연결 없음 |
| subscriptionIssued → inProgress | 레슨 시작 | ❌ 연결 없음 |

**필요 작업**:
- SubscriptionProposal 상태 변경 시 LessonRequest 상태 동기 전이
- 이벤트 기반 또는 서비스 레이어에서 직접 호출

---

## 5. 구현 우선순위

```
Phase 1 (핵심 연결 — 플로우가 끊어진 부분):
  ① GAP-1: LessonRequest ↔ SubscriptionProposal 양방향 연결
  ② GAP-6: RequestStatus 전이 체인 완성
  ③ GAP-2 + GAP-3: confirm_proposal() → membership + relationship 활성화

Phase 2 (자동화 — 수동 작업 제거):
  ④ GAP-4: confirm_proposal() → ScheduleConfirmationCard 자동 생성
  ⑤ GAP-5: confirm_card() → Lesson/LessonBooking 자동 생성

Phase 3 (검증):
  ⑥ 시나리오 테스트: 전체 플로우 E2E
  ⑦ 프론트엔드 Mock → Remote 전환 검증
```

---

## 6. 결제 경계 재확인

> 이 플로우에서 결제는 **앱 밖 무통장입금**만. 앱은 상태 기록만 담당.
> `/payments/*` 라우터 없음, PG SDK 없음, 웹훅 없음.
> 상세: [payment_architecture.md](../subscription/payment_architecture.md)
