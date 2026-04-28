# 스케줄 확인 카드 (Schedule Confirmation Card)

> 마지막 업데이트: 2026-04-28

## 개요

수강권 발급 후 학생에게 레슨 스케줄 확정을 유도하는 카드. 학생 대시보드 상단에 표시되며, 시나리오에 따라 다른 시간을 제안한다.

## 카드 타입 분기 로직

수강권 발급 시 **자동으로** 카드 타입이 결정된다:

| 시나리오 | 카드 타입 | 제안 시간 | 설명 |
|----------|-----------|-----------|------|
| 첫 수강권 (체험 후) | `afterTrial` | 체험 레슨 시간 | 이전 수강권 없음, 다른 악기 수강권도 없음 |
| 재등록 | `reEnrollment` | 이전 스케줄 | 같은 membership에 이전 수강권 존재 |
| 추가 악기 | `additionalInstrument` | 없음 (직접 선택) | 다른 membership에 수강권 존재 |

### 판단 순서

```
1. 같은 membershipId로 이전 수강권이 있는가?
   → YES: reEnrollment (이전 스케줄 제안)

2. 다른 membershipId로 수강권이 있는가?
   → YES: additionalInstrument (시간 선택 유도)

3. 이전 수강권이 전혀 없는가?
   → YES: afterTrial (체험 레슨 시간 제안)
```

## 제안 시간의 출처

- membership의 `lessonDay`, `lessonTime`, `lessonDuration` 필드에서 가져옴
- 체험 레슨 예약 시 설정된 요일/시간이 membership에 기록됨
- `additionalInstrument`는 제안 시간 없이 직접 선택 화면으로 이동

## UI 표시

- **위치**: 학생 대시보드 상단 (액션 필요 섹션)
- **상태**: `pending` → `confirmed` 또는 `changedTime`
- **버튼**:
  - 제안 있을 때: [다른 시간] [이 시간으로 예약]
  - 제안 없을 때: [시간 선택하기]

## 관련 파일

| 파일 | 역할 |
|------|------|
| `schedule/domain/entities/schedule_confirmation_card.dart` | 엔티티 |
| `schedule/presentation/widgets/schedule_confirmation_card_widget.dart` | UI 위젯 |
| `schedule/presentation/providers/schedule_confirmation_card_providers.dart` | Provider |
| `subscription/presentation/screens/issue_subscription_screen.dart` | 카드 생성 (`_detectScheduleCardType`) |
| `student_home/presentation/screens/student_dashboard_tab.dart` | 대시보드 표시 (현재 비활성) |

## 현재 상태

- 카드 타입 분기 로직: **구현 완료** (`issue_subscription_actions.dart::_detectScheduleCardType`)
- 대시보드 표시: **활성** (`student_dashboard_tab.dart::_StudentEventsGroup` → `_ScheduleConfirmationSection`)
- 진입점: 수강권 발급 직후 자동 카드 생성 → 학생 대시보드 이벤트 그룹에 노출

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-03-02 | 카드 타입 분기 로직 구현 (afterTrial/reEnrollment/additionalInstrument) |
| 2026-03-02 | 대시보드에서 카드 표시 비활성화 (하드코딩 afterTrial 문제 해결 전까지) |
| 2026-04-28 | Phase 3.2 spec ↔ 코드 일치 점검 — 분기 로직 정상 동작, 대시보드 재활성 상태 spec 반영 |
