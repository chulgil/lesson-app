# 변경권(변경/취소권) SSOT 스펙

> 작성일: 2026-06-12 (launch-readiness audit P1-3)
> 상태: 확정
> **이 문서가 변경/취소권 차감·복원 규칙의 단일 SSOT이다.**
> 기존 문서(lesson_cancellation_flow_spec.md, design_master.md)에는 이 문서로의 포인터만 남긴다.

---

## 1. 용어 정의

| 내부 필드 | 표시 이름 | 설명 |
|----------|----------|------|
| `maxRescheduleCount` | 변경/취소권 총 횟수 | 수강권 템플릿의 `rescheduleLimit` 로 초기 설정 |
| `bonusRescheduleCount` | 추가 변경/취소권 | 선생님이 사후 추가 ([subscription_edit_spec.md §2.1](./subscription_edit_spec.md)) |
| `usedRescheduleCount` | 사용 횟수 | 차감 이벤트 누적값 |
| `remainingReschedule` | 잔여 변경/취소권 | `maxRescheduleCount + bonusRescheduleCount - usedRescheduleCount` |

> 용어 원천: [glossary.md](../glossary.md), [subscription_edit_spec.md §2.1](./subscription_edit_spec.md)

---

## 2. 부여 규칙

- 수강권 생성 시 템플릿의 `rescheduleLimit` 값이 `maxRescheduleCount` 로 지정된다.
- 기본 예시: 선생님 설정에서 "변경 가능 횟수 2회" → 수강권 발급 시 `maxRescheduleCount=2`.
- 선생님은 발급 후에도 `bonusRescheduleCount` 를 증가시켜 변경권을 추가할 수 있다 ([subscription_edit_spec.md §2.1](./subscription_edit_spec.md)).
- 학원 취소 정책의 `cancellation_credits` (강사 귀책 보상) 도 `usedRescheduleCount` 를 감소시키는 방식으로 복원된다 ([teacher_cancellation_policy_spec.md §7](../web/academy/teacher_cancellation_policy_spec.md)).

---

## 3. 차감 조건 통합표

> 아래 규칙은 기존 스펙에서 수집한 것이다. 새 정책을 발명하지 않는다.
> 모순이 발견된 항목은 "모순 — 결정 필요" 로 표시한다.

| 행동 주체 | 행동 | 마감 기준 | 차감 | 비고 |
|----------|------|----------|:----:|------|
| 학생 | 일정 변경 요청 | 마감 **전** | X | 잔여권과 무관하게 무료 |
| 학생 | 일정 변경 요청 | 마감 **후** | O (1회) | `scheduleChangeProposed` 이벤트 |
| 학생 | 레슨 취소 | 마감 **전** | X | `changeCreditUsed=0` |
| 학생 | 레슨 취소 | 마감 **후** | O (1회) | `lessonCancelled` 이벤트, `changeCreditUsed=1` |
| 학생 | 레슨 취소 (잔여권 0, 마감 후) | — | 차단 | "변경취소권이 소진되었습니다" 스낵바 |
| 선생님 | 일정 변경 제안 | — | X | 학생 변경권 미차감 |
| 선생님 | 레슨 취소 | — | X | 학생 귀책 없음 |
| 상호 합의 | 취소 | — | X | `mutual` 사유 |

**마감 기준**: 레슨 당일 기준. 정확한 시각 커트라인(`rescheduleDeadlineHours`)은 수강권별로 설정 ([subscription_edit_spec.md §5.2](./subscription_edit_spec.md)). 학생에게 노출되는 표현: "마감 24시간 전 취소는 무료" (실제 값은 수강권 정책에 따라 다를 수 있음 — 모순 주의 아래 참조).

> **모순 — 결정 필요**: `lesson_cancellation_flow_spec.md §3.3` 시퀀스 다이어그램은 "마감 24h 전"을 예시로 사용하고, `subscription_edit_spec.md §5.2`에는 `rescheduleDeadlineHours` 를 수강권별로 재정의할 수 있다고 명시한다. UI 고지 문구("마감 24시간 전 취소는 무료")가 수강권별 설정과 다를 경우 혼동 발생 가능 — 고지 문구를 수강권 정책에서 동적으로 읽어올지 결정 필요.

---

## 4. 복원 조건 통합표

| 복원 트리거 | 복원 방법 | 출처 |
|-----------|----------|------|
| 선생님이 "무료 처리" 선택 | `cancellationCreditRefunded` 이벤트 → `usedRescheduleCount -= 1` | [lesson_cancellation_flow_spec.md §3.2](../schedule/lesson_cancellation_flow_spec.md) |
| 일정 변경 요청 72시간 무응답 자동 만료 | `scheduleChangeExpired` 이벤트 → 요청 시 차감된 경우 자동 복원 | [subscription_schedule_change_spec.md §8.1](../schedule/subscription_schedule_change_spec.md) |
| 학원 강사 12h 이내 취소 (귀책) | `cancellation_credits +1` (academy ownership 에서 보상) | [teacher_cancellation_policy_spec.md §3.1](../web/academy/teacher_cancellation_policy_spec.md) |
| 선생님이 변경권 직접 추가 | `bonusRescheduleCount` 증가 (사유 기록 필수) | [subscription_edit_spec.md §2.1](./subscription_edit_spec.md) |

---

## 5. UI 사전 고지 원칙

차감이 발생하는 액션을 실행하기 **전** 에 반드시 고지한다.

| 액션 버튼 위치 | 고지 문구 (예시) |
|--------------|----------------|
| 일정 변경 요청 전송 직전 (마감 후) | "변경/취소권 1회가 사용될 예정입니다. 잔여 N회" |
| 레슨 취소 확인 다이얼로그 (마감 후) | "변경/취소권 1회가 사용될 예정입니다. 잔여 N회" |
| 마감 전 취소 시 | "마감 시간 전 취소 · 변경/취소권 미사용" |
| 변경권 0회 상태에서 마감 후 액션 시도 | "변경취소권이 소진되었습니다" (차단) |

> 고지 문구 원천: [subscription_schedule_change_ux_spec.md §3](./subscription_schedule_change_ux_spec.md), [lesson_cancellation_flow_spec.md §5](../schedule/lesson_cancellation_flow_spec.md)

---

## 6. 데이터 필드 요약

```dart
// Subscription 엔티티 관련 필드
final int maxRescheduleCount;       // 템플릿에서 초기 설정된 허용 횟수
final int bonusRescheduleCount;     // 선생님이 추가한 보너스 (기본 0)
final int usedRescheduleCount;      // 누적 차감 횟수

int get totalRescheduleAllowance =>
    maxRescheduleCount + bonusRescheduleCount;
int get remainingReschedule =>
    totalRescheduleAllowance - usedRescheduleCount;

// RequestEvent 스냅샷 필드 (이벤트 발생 시점 기록)
final int changeCreditUsed;          // 이번 이벤트에서 사용한 횟수 (0 또는 1)
final int changeCreditRemainingAfter; // 이벤트 직후 잔여 횟수
```

> 참조: [lesson_cancellation_flow_spec.md §6](../schedule/lesson_cancellation_flow_spec.md), [subscription_schedule_change_ux_spec.md §3](./subscription_schedule_change_ux_spec.md)

---

## 7. 관련 스펙 역링크

| 스펙 | 관련 내용 |
|------|----------|
| [lesson_cancellation_flow_spec.md](../schedule/lesson_cancellation_flow_spec.md) | 취소 시 차감·복원 시퀀스, 이벤트 타입, 상태 전이 |
| [subscription_schedule_change_spec.md §8](../schedule/subscription_schedule_change_spec.md) | 일정 변경 요청 만료 시 변경권 복원 |
| [subscription_schedule_change_ux_spec.md §3](./subscription_schedule_change_ux_spec.md) | UI 고지 문구, 말풍선 스냅샷 |
| [subscription_edit_spec.md §2.1, §5.2](./subscription_edit_spec.md) | 변경권 추가, 마감 시간 수강권별 재정의 |
| [teacher_cancellation_policy_spec.md §3, §7](../web/academy/teacher_cancellation_policy_spec.md) | 학원 강사 귀책 취소 시 학생 변경권 보상 |
| [design_master.md §변경권 시스템](../design/design_master.md) | 초기 설계 원칙 (DEPRECATED 문서, 포인터만 유지) |
| [subscription_master.md §2.6](./subscription_master.md) | 변경/취소 횟수 제한 (Reschedule Limit) 설정 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-12 | 신규 — launch-readiness audit P1-3, 기존 3개 문서 산재 규칙 통합 |
