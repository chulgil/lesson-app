# Phase 3: 수강권 표시 & 레슨 진행 관리

> 작성일: 2026-04-04
> 상태: 🟡 계획 검토 중

## 이전 계획

레슨요청 개편 (Phase 1-2) — 2026-03-29 완료. 상세: docs/proposal/lesson-request-ux-improvement.pad.md

---

## 1. 요구사항 정리

### 핵심 기능 3가지

| # | 기능 | 설명 |
|---|------|------|
| 1 | **수강권 리스트 (콘서트 티켓형)** | 학생에게 발급된 수강권을 클래식 콘서트 티켓 스타일 카드로 표시 |
| 2 | **수강권 상세 (챕터 모델 재사용)** | 기존 레슨 요청 채팅 UI를 재사용하여 회차별 레슨 진행 표시 |
| 3 | **스케줄 변경/취소 (변경취소권)** | 변경취소권 소진 기반 스케줄 변경, 기준 시간(선생님 설정) 초과 시 소진 |

### 비즈니스 규칙

- **변경취소권**: 수강권 발급 시 선생님이 지정 (기본 2회, `totalRescheduleAllowance`)
- **기준 시간**: 선생님이 수강권 발급 시 설정 (기본 12시간, `rescheduleDeadlineHours`)
  - 레슨 시작 N시간 전 변경: 무료 (변경취소권 미소진)
  - 레슨 시작 N시간 이내 변경: 변경취소권 1회 소진
- **No-show**: 레슨 횟수 1회 차감 (변경취소권 무관)
- 이미 존재: `LessonPolicy.reschedule_deadline_hours` (백엔드), `Subscription.totalRescheduleAllowance` / `usedRescheduleCount` (프론트)

---

## 2. 아키텍처 다이어그램

```
[학생 앱]                           [선생님 앱]
    │                                    │
    ▼                                    ▼
┌──────────────────┐           ┌──────────────────┐
│ SubscriptionList │           │ IssueSubscription │
│ (콘서트 티켓 카드)│           │ + 변경취소권 설정  │
└────────┬─────────┘           │ + 기준시간 설정    │
         │ 탭                   └──────────────────┘
         ▼
┌──────────────────────────────────────────────┐
│ SubscriptionDetailScreen (챕터 모델)          │
│                                              │
│  ┌ Ch.1 수강권 정보 [▼] (접힌)              │
│  ┌ Ch.2 결제 내역   [▼] (접힌)              │
│  └ Ch.3 레슨 진행   [▽] (펼침 — 핵심)       │
│     ✅ 1회차 완료                             │
│     ✅ 2회차 완료                             │
│     📅 3회차 예정 ← [시간 변경] [취소]        │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ Action Box: [레슨완료][시간변경][취소] │   │
│  └──────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
         │ "시간 변경" 탭
         ▼
┌──────────────────────────────────────────────┐
│ RescheduleBottomSheet                         │
│                                              │
│  기존: 4/26(토) 14:00                        │
│  변경: [날짜 선택] [시간 선택]                │
│                                              │
│  ⚠️ 기준시간 12시간 이내                      │
│  → 변경취소권 1회 사용 (잔여 2→1)             │
│                                              │
│  [변경 요청]                                  │
└──────────────────────────────────────────────┘
```

---

## 3. 구현 Phase 분류

### Phase 3-1: 수강권 콘서트 티켓 카드 (UI Only)

> 기존 `SubscriptionCard` → `SubscriptionTicketCard`로 새 위젯 추가

**콘서트 티켓 디자인 컨셉:**
```
┌─────────────────────────────────────────┐
│                                         │
│  🎵  바이올린 정규 레슨                  │  ← 악기 아이콘 + 클래스명
│      김민지 선생님                       │  ← 선생님 이름
│                                         │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │  ← 티켓 절취선 (dashed)
│                                         │
│  10회권        7/10회 남음               │  ← 타입 + 잔여
│  ████████░░░   변경취소 2회              │  ← 프로그레스 + 변경취소권
│  2026.04~06    🟢 이용중                 │  ← 기간 + 상태
│                                         │
└─────────────────────────────────────────┘
```

**수정 파일:**
| 파일 | 변경 |
|------|------|
| `features/subscription/presentation/widgets/subscription_ticket_card.dart` | **NEW** — 콘서트 티켓 스타일 카드 |
| `features/subscription/presentation/screens/subscription_list_screen.dart` | `SubscriptionCard` → `SubscriptionTicketCard` 교체 |
| `core/l10n/app_strings.dart` | 티켓 관련 문자열 추가 |

**의존성:** 없음 (UI only, 기존 데이터 그대로 사용)

---

### Phase 3-2: 수강권 상세 — 챕터 모델 적용

> 기존 `SubscriptionDetailScreen` → 챕터 기반으로 리디자인

**챕터 구성:**
| 챕터 | 내용 | 상태 |
|------|------|------|
| Ch.1 수강권 정보 | 타입, 횟수, 금액, 변경취소권 | 접힌 (항상) |
| Ch.2 결제 내역 | 결제일, 방법, 금액 | 접힌 (항상) |
| Ch.3 레슨 진행 | 회차별 완료/예정/미정 리스트 | **펼침 (활성)** |

**수정 파일:**
| 파일 | 변경 |
|------|------|
| `features/subscription/presentation/screens/subscription_detail_screen.dart` | 챕터 모델로 리디자인 (기존 카드형 → 챕터형) |
| `features/subscription/presentation/widgets/subscription_chapter_info.dart` | **NEW** — Ch.1 수강권 정보 위젯 |
| `features/subscription/presentation/widgets/subscription_chapter_payment.dart` | **NEW** — Ch.2 결제 내역 위젯 |
| `features/subscription/presentation/widgets/subscription_chapter_lessons.dart` | **NEW** — Ch.3 레슨 진행 위젯 (핵심) |
| `core/widgets/chapter_summary.dart` | 기존 재사용 (변경 없음) |

**의존성:** Phase 3-1 (티켓 카드에서 상세로 진입)

---

### Phase 3-3: 스케줄 변경/취소 플로우

> 변경취소권 소진 기반 변경/취소 요청

**변경 플로우:**
```
회차 탭 → RescheduleBottomSheet
  → 새 일시 선택
  → 기준시간 체크 (rescheduleDeadlineHours)
    → 기준시간 전: "무료 변경" 안내
    → 기준시간 후: "변경취소권 1회 소진" 경고
  → 확인 → RequestEvent 생성 (챗에 기록)
  → 선생님 승인 대기
```

**수정 파일:**
| 파일 | 변경 |
|------|------|
| `features/subscription/presentation/widgets/reschedule_bottom_sheet.dart` | **NEW** — 변경 요청 바텀시트 |
| `features/subscription/presentation/widgets/cancel_lesson_bottom_sheet.dart` | **NEW** — 취소 요청 바텀시트 |
| `features/subscription/presentation/widgets/subscription_action_box.dart` | **NEW** — 하단 액션 박스 (레슨완료/시간변경/취소) |
| `features/schedule/domain/entities/request_event.dart` | 변경/취소 이벤트 타입 추가 (이미 일부 존재) |
| `core/l10n/app_strings.dart` | 변경/취소 관련 문자열 추가 |

**의존성:** Phase 3-2 (상세 화면에서 액션 트리거)

---

### Phase 3-4: 수강권 발급 시 변경취소권 설정 (선생님)

> 기존 발급 화면에 변경취소권 + 기준시간 필드 추가

**변경취소권이 수강권에 바인딩되는 흐름:**
```
선생님: 수강권 발급
  → 변경취소권 횟수: [2회] (칩 선택: 0/1/2/3)
  → 기준시간: [12시간] (칩 선택: 6/12/24/48시간)
  → 발급 완료
  → Subscription 엔티티에 저장
```

**수정 파일:**
| 파일 | 변경 |
|------|------|
| `features/subscription/presentation/screens/issue_subscription_screen.dart` | 변경취소권 + 기준시간 칩 필드 추가 |
| `features/subscription/domain/entities/subscription.dart` | `rescheduleDeadlineHours` 필드 추가 (현재 없음) |
| `backend/app/models/subscription.py` | `reschedule_deadline_hours` 컬럼 추가 |
| `backend/alembic/versions/` | 마이그레이션 추가 |

**의존성:** 없음 (독립 진행 가능)

---

## 4. 리스크 분석

| 리스크 | 수준 | 대응 |
|--------|------|------|
| **Subscription에 `rescheduleDeadlineHours` 필드 없음** | MEDIUM | Phase 3-4에서 추가. 현재 LessonPolicy에만 존재 → 수강권별 커스텀 위해 Subscription으로 복제 필요 |
| **레슨 회차별 데이터 모델** | MEDIUM | 현재 `SubscriptionUsage`가 사용 기록을 가짐. 예정 스케줄은 별도 모델 또는 Mock 필요 |
| **기존 SubscriptionDetailScreen 리디자인** | LOW | 기존 코드를 유지하면서 챕터 모델 적용 — 기존 위젯 분리하여 재조합 |
| **콘서트 티켓 디자인 퀄리티** | LOW | CustomPainter로 dashed line + 그림자 처리 필요 |

---

## 5. 수정 파일 총 정리

| Phase | 새 파일 | 수정 파일 | 합계 |
|-------|---------|----------|------|
| 3-1 티켓 카드 | 1 | 2 | 3 |
| 3-2 챕터 상세 | 3 | 1 | 4 |
| 3-3 변경/취소 | 3 | 2 | 5 |
| 3-4 발급 설정 | 0 | 4 | 4 |
| **합계** | **7 NEW** | **9 EDIT** | **16** |

> ⚠️ **범위 챌린지**: 16개 파일. Phase 단위로 나누어 진행 추천.
> **제안**: Phase 3-1 (티켓 카드) + Phase 3-4 (발급 설정)을 먼저 → Phase 3-2 (챕터 상세) → Phase 3-3 (변경/취소) 순서

---

## 6. 제안 구현 순서

```
Phase 3-4 (발급 설정) ──┐
                        ├── Phase 3-1 (티켓 카드) → Phase 3-2 (챕터 상세) → Phase 3-3 (변경/취소)
                        │
        [독립: 선생님 화면]   [순차: 학생 화면]
```

1. **Phase 3-4** 먼저 — 데이터 모델 변경 (엔티티 + 마이그레이션)
2. **Phase 3-1** — 콘서트 티켓 카드 (학생 리스트)
3. **Phase 3-2** — 챕터 모델 상세 화면
4. **Phase 3-3** — 변경/취소 플로우

---

## 7. 기존 자산 재사용 맵

| 기존 자산 | 재사용 위치 |
|----------|------------|
| `ChapterSummary` 위젯 | Phase 3-2 — 챕터 접기/펼치기 |
| `RequestHistoryChat` 패턴 | Phase 3-3 — 변경/취소 이벤트를 챗 형태로 기록 |
| `SubscriptionStatusColors` | Phase 3-1 — 티켓 카드 상태 색상 |
| `SubscriptionUsage` 엔티티 | Phase 3-2 — 회차별 완료 표시 |
| `ScheduleChangeTypeBottomSheet` | Phase 3-3 — 변경 타입 선택 참고 |
| `AlternativeTimeGrid` | Phase 3-3 — 대안 시간 제안 |

---

**WAITING FOR CONFIRMATION**: 이 계획으로 진행할까요?
- `yes` → Phase 3-4 (데이터 모델)부터 시작
- `modify: [변경사항]` → 수정 후 재확인
- Phase 특정 → "3-1만 먼저" 등 부분 진행 가능
