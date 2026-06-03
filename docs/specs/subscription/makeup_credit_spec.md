# 보강 크레딧 스펙 (Makeup Credit / Make-up Bank)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #7 H-002 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #427
> 관련 스펙: [subscription_master.md §2](subscription_master.md), [subscription_schedule_change_spec.md](../schedule/subscription_schedule_change_spec.md), [teacher_vacation_mode.md](../schedule/teacher_vacation_mode.md)
> 글로서리: [glossary.md §4](../../../.harness/knowledge/glossary.md) — "보강 크레딧", "스케줄된 회차"

---

## 1. 문제 정의

E2E 감사: 정규권 일괄 변경(요일·시간 변경) 후 5주차·보강·이월 회차 자동 재계산 로직 부재. `bulkChange` 후 학생 측 회차 표시와 실제 차감이 어긋남.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | `Subscription.remainingLessons` 만으로는 "실제 잡힌 레슨 수"와 "남은 권리"를 구분 못함 | 학생-선생님 회차 표시 불일치 |
| 2 | 일괄 변경 시 기존 `scheduledLessons` 취소 → 새 시간 재생성 로직 없음 | "5주차인데 4회만 차감됨" 분쟁 |
| 3 | 보강 회차가 정규 수강권에 섞여 카운팅 | 보강 1회 사용 시 정규 1회 차감 (회계 혼란) |
| 4 | 노쇼 면제·휴가 손실분 추적 불가 | 운영자가 수동 보전 |

### 1.2 영향 범위 (펀넬)

H (일정 조절·갱신) 단계의 가장 큰 분쟁 원인. "이번 달 5주차인데 수강권은 4회만 차감됨" → 한 달 단위 다툼 → 갱신 거부 → 매출 손실.

---

## 2. 설계 원칙

> **"보강 회차는 정규 수강권에서 분리한다. Teachworks 'Make-up bank' 패턴."**

| 원칙 | 의미 |
|---|---|
| 별도 엔티티 | `MakeupCredit` 를 정규 `Subscription` 과 독립 관리 |
| 사용 우선순위 | 학생이 차시 예약 시 정규 수강권 차감 vs 크레딧 사용을 명시적 선택 |
| 자동 적립 | 휴가·노쇼 면제·일괄변경 손실분에서 시스템이 자동 적립 |
| 만료 30일 | 무기한 적립 방지. 정규 수강권 만료 정책과 동일 |
| 회차 분리 | `remainingLessons` (남은 권리) vs `scheduledLessons` (실제 잡힌 수) 분리 트랙 |

---

## 3. 데이터 모델

### 3.1 MakeupCredit 신규 엔티티

```dart
@HiveType(typeId: 78)
class MakeupCredit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String teacherId;

  @HiveField(3)
  final String? sourceSubscriptionId;  // 적립 사유 수강권 (있으면)

  @HiveField(4)
  final MakeupCreditReason reason;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime expiresAt;            // 기본: createdAt + 30일

  @HiveField(7)
  final DateTime? usedAt;              // 사용 시각

  @HiveField(8)
  final String? usedLessonId;          // 사용된 레슨 ID

  @HiveField(9)
  final String? sourceEventId;         // 휴가 ID / 노쇼 ID / 일괄변경 ID
}

enum MakeupCreditReason {
  teacherVacation,        // 선생님 휴가 (teacher_vacation_mode.md 의존)
  noShowExempt,           // 학생 노쇼 면제 (선생님 재량)
  bulkChangeLoss,         // 정규 일괄변경 중 손실 회차
  manualGrant,            // 선생님 수동 지급 (예외 처리)
}
```

### 3.2 Subscription 모델 확장

기존 `Subscription` 에 다음 필드 추가:

| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `scheduledLessons` | `int` | 0 | 실제 잡힌 레슨 수 (`LessonBooking.status in [scheduled, completed]` 카운트) |
| `bonusCount` | `int` | 0 | 5주차 보너스 등 추가 회차 (기존 필드, 명시화) |

기존:
- `remainingLessons` = `totalLessons` + `bonusCount` - `usedLessons`

신규 트랙:
- `scheduledLessons` = `LessonBooking` 중 활성 상태 카운트 (재계산 가능)

### 3.3 일관성 불변식

```
remainingLessons >= 0
scheduledLessons <= remainingLessons + usedLessons
```

위배 시 백엔드 거부 (트랜잭션 롤백).

---

## 4. 적립 트리거

### 4.1 (a) 선생님 휴가 모드

`teacher_vacation_mode.md` 의 처리 옵션 (a) "보강 크레딧 자동 등록" 선택 시.

| 항목 | 값 |
|---|---|
| `reason` | `teacherVacation` |
| `sourceEventId` | `VacationPeriod.id` |
| `expiresAt` | `VacationPeriod.endDate + 30일` |
| 1건 생성 단위 | 영향 받는 `LessonBooking` 1건당 1 크레딧 |

### 4.2 (b) 학생 노쇼 면제

선생님이 노쇼 레슨에 대해 "예외 면제" 선택 시.

| 항목 | 값 |
|---|---|
| `reason` | `noShowExempt` |
| `sourceEventId` | `Lesson.id` |
| `expiresAt` | `createdAt + 30일` |

기존 `LessonStatus.studentAbsent` → 면제 시 `LessonStatus.cancelledMutual` 로 변경 + 크레딧 1건 적립.

### 4.3 (c) 정규 일괄변경 손실분

`subscription_schedule_change_spec.md` 의 일괄변경 시:

```
[일괄변경 재계산 로직]

1. 기존 scheduledLessons 의 미래 LessonBooking 식별
2. 새 요일/시간으로 재배치 시도
3. 재배치 가능 → LessonBooking 갱신, 크레딧 적립 없음
4. 재배치 불가 (휴무·휴가·중복 등) → 손실 회차 1건당 크레딧 1건 적립
5. remainingLessons 조정:
   - 손실 회차: usedLessons 감산 (회차 복원) + 크레딧 적립
   - 신규 회차: usedLessons 예약 차감
```

| 항목 | 값 |
|---|---|
| `reason` | `bulkChangeLoss` |
| `sourceEventId` | `SubscriptionScheduleChange.id` |

### 4.4 (d) 수동 지급

선생님이 학생 상세 → 보강 크레딧 → "수동 지급" 으로 직접 발급. 모든 케이스가 자동으로 처리되지 않을 때 안전망.

---

## 5. 사용 정책

### 5.1 학생 측 예약 시 선택

차시 예약 화면에서 학생이 "이번 예약은 보강 크레딧 사용" 토글 가능.

```
┌─────────────────────────────────────┐
│  레슨 예약                           │
│                                     │
│  바이올린 · 8/15(목) 16:00          │
│                                     │
│  ◉ 정규 수강권 사용                  │
│     남은 회차: 5/8회                 │
│                                     │
│  ○ 보강 크레딧 사용                  │
│     보유 크레딧: 2회                 │
│     (만료: 9/2)                     │
│                                     │
│  [예약하기]                          │
└─────────────────────────────────────┘
```

### 5.2 기본 우선순위

| 상황 | 기본 선택 |
|---|---|
| 정규 잔여 > 0 + 크레딧 > 0 | 정규 (사용자 변경 가능) |
| 정규 잔여 = 0 + 크레딧 > 0 | 크레딧 (자동) |
| 둘 다 = 0 | 예약 불가, 갱신 안내 |

### 5.3 사용 시 처리

크레딧 사용 시:
- `MakeupCredit.usedAt`, `usedLessonId` 기록
- `Subscription.usedLessons` 미차감
- `Subscription.scheduledLessons += 1`
- `LessonBooking.creditUsed = true` 플래그

---

## 6. 만료 정책

### 6.1 기본 만료

`createdAt + 30일`. 정규 수강권 만료 정책과 동일.

### 6.2 만료 처리

매일 00:00 cron:
- `expiresAt < now AND usedAt IS NULL` → 상태 `expired`
- 학생 측 알림 발송: D-3, D-1 만료 임박 ("보강 크레딧 N회 곧 만료")

### 6.3 만료 후 복구 불가

만료된 크레딧은 복구하지 않는다. 단, 운영 이슈 시 선생님 수동 지급으로 우회 가능 (§4.4).

---

## 7. 일괄변경 재계산 로직 (핵심)

`subscription_schedule_change_spec.md` 의 `bulkChange` 흐름 수정:

```
[기존]
bulkChange(subscriptionId, newDayOfWeek, newTime)
  → 단순 요일/시간 변경 (실제 잡힌 레슨 재계산 없음)

[신규]
bulkChange(subscriptionId, newDayOfWeek, newTime)
  → 1. 미래 scheduledLessons 식별 (status in [scheduled])
  → 2. 각 레슨에 대해 새 요일/시간으로 후보 슬롯 계산
  → 3. 후보 슬롯 가용성 확인 (TeacherAvailability, 휴가, 중복)
  → 4. 가용 → LessonBooking 갱신
       불가 → cancelledByTeacher + MakeupCredit(reason=bulkChangeLoss) 적립
  → 5. Subscription 재계산:
       - scheduledLessons = 갱신된 LessonBooking 수
       - usedLessons 변경 없음 (이미 차감된 과거 레슨 유지)
  → 6. 학생/학부모 알림: "N건 변경 / M건 보강 크레딧 적립"
```

### 7.1 5주차 보너스 처리

| 상황 | 처리 |
|---|---|
| 일괄변경 결과 새 월에 5주차 발생 | `Subscription.bonusCount += 1` (FifthWeekPolicy=bonus 시) |
| 일괄변경 결과 5주차 제거 | `Subscription.bonusCount -= 1` (재계산 시 일관성 유지) |
| 정책이 skip | bonusCount 변경 없음 |

### 7.2 검증 케이스 (테스트 필수)

| 케이스 | 기대 |
|---|---|
| 일괄변경 후 학생-선생님 회차 표시 일치 | `subscription.scheduledLessons == LessonBooking 활성 카운트` |
| 일괄변경으로 손실 회차 N건 | `MakeupCredit 신규 N건 적립` |
| 5주차 정책 bonus + 일괄변경 | `bonusCount` 정확 반영 |
| 일괄변경 후 학생 측 크레딧 사용 가능 | 예약 화면에 크레딧 표시 |

---

## 8. 백엔드 API

### 8.1 신규 엔드포인트

| Method | 경로 | 설명 |
|---|---|---|
| GET | `/api/students/me/makeup-credits` | 학생 측 보유 크레딧 목록 |
| GET | `/api/teachers/me/makeup-credits` | 선생님 측 발급한 크레딧 목록 |
| POST | `/api/teachers/me/makeup-credits` | 수동 지급 (§4.4) |
| DELETE | `/api/teachers/me/makeup-credits/:id` | 미사용 크레딧 회수 (오발급 정리, 이미 사용 시 409) (코드 반영 2026-06-03) |
| POST | `/api/bookings` (확장) | `useCredit: bool` 파라미터 |

### 8.2 일괄변경 엔드포인트 확장

기존 `POST /api/subscriptions/:id/bulk-change` 응답에 추가:

```json
{
  "rescheduledCount": 8,
  "lostCount": 2,
  "creditsAccrued": 2,
  "newExpiresAt": "2026-09-15"
}
```

---

## 9. UI 정의

### 9.1 학생 측 — 보강 크레딧 카드

학생 홈 또는 수강권 상세에 노출:

```
┌─────────────────────────────────────┐
│ 보강 크레딧                          │
│                                     │
│ 보유: 2회                            │
│ 가장 빠른 만료: 9/2(D-15)            │
│                                     │
│ ▼ 내역 (3건)                         │
│   8/3 적립 — 선생님 휴가              │
│   8/10 적립 — 노쇼 면제               │
│   8/20 사용 — 정규 레슨               │
└─────────────────────────────────────┘
```

### 9.2 선생님 측 — 학생별 크레딧 관리

학생 상세 → 보강 크레딧 탭 → 발급/회수/수동 지급.

---

## 10. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 일괄변경 후 회차 일치 | `subscription.scheduledLessons == LessonBooking 활성 카운트` | 100% |
| 크레딧 사용률 | `usedAt != null / total` | 50-70% (만료 30-50%) |
| 일괄변경 후 분쟁 신고 | 운영 메트릭 | < 1% |
| 크레딧 적립-사용 격차 | `expiredCount / accrualCount` | < 30% (높으면 만료 정책 재검토) |

### 10.1 정량 검증

```bash
# 백엔드 엔티티 확인
grep -rn "MakeupCredit" backend/app/models/  # ≥ 1
# 프론트 엔티티 확인
grep -rn "MakeupCredit" frontend/lib/features/subscription/domain/entities/  # ≥ 1
# scheduledLessons 트랙 확인
grep -rn "scheduledLessons" backend/app/models/  # ≥ 1
```

---

## 11. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- 본 스펙 작성
- glossary "보강 크레딧", "스케줄된 회차" 추가 (이미 완료)
- `subscription_master.md §2` 의 `scheduledLessons` 필드 참조 추가 (메인 세션이 처리)

### Phase 2: 백엔드 (2주)

- `MakeupCredit` 엔티티 + repository + 마이그레이션
- `Subscription.scheduledLessons` 필드 추가
- 적립 트리거 4종 (휴가·노쇼 면제·일괄변경·수동)
- 일괄변경 재계산 로직 수정
- 신규 엔드포인트 3개 + bookings 확장
- 만료 cron

### Phase 3: 프론트엔드 (1-2주)

- 학생: 크레딧 카드, 예약 시 사용 토글
- 선생님: 학생별 크레딧 관리, 수동 지급
- 일괄변경 결과 UI ("N건 변경 / M건 크레딧 적립")

### Phase 4: 의존성 통합

- `teacher_vacation_mode.md` 의 처리 옵션 (a) 연동
- 알림: 적립·만료 임박·사용 완료

---

## 12. 의존성

| 의존 스펙 | 의존 항목 |
|---|---|
| [teacher_vacation_mode.md](../schedule/teacher_vacation_mode.md) | 적립 트리거 (a) — 휴가 처리 옵션의 보강 크레딧 자동 등록 |
| [subscription_master.md](subscription_master.md) §2 | `scheduledLessons`, `bonusCount` 필드 확장 |
| [subscription_schedule_change_spec.md](../schedule/subscription_schedule_change_spec.md) | `bulkChange` 재계산 로직 |

---

## 코드 반영 추가 (2026-06-03)

> 코드(`features/subscription`)에 구현되었으나 위 본문에 누락된 항목. 코드→스펙 단방향 반영.

### A. MakeupCreditBalance 집계 (UI 편의)

학생 보유 크레딧 잔액을 요약하는 값 객체. `features/subscription/domain/entities/makeup_credit.dart`.

| 멤버 | 설명 |
|---|---|
| `available: List<MakeupCredit>` | 사용 가능(미사용 + 미만료) 크레딧, 만료 임박 순 정렬 |
| `availableCount: int` | 보유 가능 회차 수 |
| `hasAny: bool` | 보유 여부 |
| `earliestExpiry: DateTime?` | 가장 빠른 만료 시각 (§9.1 카드 "가장 빠른 만료" 표기 근거) |
| `MakeupCreditBalance.fromCredits(credits, now)` | 만료/사용 필터 + 정렬 팩토리 |

MakeupCredit 자체 헬퍼: `isUsed`, `isExpired(now)`, `isAvailable(now)`, `daysUntilExpiry(now)` (§6 만료 정책 판정에 사용).

### B. revokeCredit 회수 메서드

`MakeupCreditRepository.revokeCredit(creditId)` — §9.2 "회수" UI 의 백엔드 계약. 이미 사용된 크레딧은 서버가 409 로 거부. (위 §8.1 DELETE 엔드포인트 참조)

`grantCredit` 시그니처: `studentId`, `sourceSubscriptionId?`, `reasonNote?` (수동 지급은 항상 `reason=manualGrant`).

### C. 라우트

| 라우트 | 화면 | 비고 |
|---|---|---|
| `/subscriptions/makeup-credits` | `MakeupCreditScreen` | `?studentId=` 있으면 선생님 뷰(학생별 발급/회수), 없으면 학생 본인 보유 뷰. `AppRoutes.makeupCredits` |

---

## 13. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #7 H-002 대응. Teachworks Make-up bank 패턴 차용. MakeupCredit 별도 엔티티 + Subscription.scheduledLessons 트랙 분리 + 일괄변경 재계산 로직 정의 |
