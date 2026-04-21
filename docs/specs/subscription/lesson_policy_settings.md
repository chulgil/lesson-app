# 레슨 정책 설정 시스템

> 작성일: 2026-01-25
> 상태: 📋 설계 중

---

## 개요

선생님/학원이 수업 운영 정책을 설정하고, 수강권 발급 시 자동 적용되는 시스템.

---

## 정책 카테고리

### 1. 수업 일정 정책 (LessonSchedulePolicy)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `lessonsPerMonth` | 월 수업 횟수 | 4 |
| `annualHolidays` | 연간 휴원 횟수 | 4 |
| `weeksPerYear` | 연간 수업 주수 | 48 |

### 2. 월정액 이월 정책 (MonthlyCarryoverPolicy)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `allowCarryover` | 이월 허용 여부 | true |
| `maxCarryoverLessons` | 최대 이월 횟수 | 1 |
| `carryoverPeriodMonths` | 이월 유효 기간 (월) | 1 |

```
예시: "당월에 못 받은 수업은 다음 달 재등록 시 1회 자동 이월"
→ allowCarryover: true, maxCarryoverLessons: 1, carryoverPeriodMonths: 1
```

### 3. 수업 변경/취소 정책 (LessonChangePolicy)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `minCancelHours` | 최소 취소 가능 시간 (시간 전) | 4 |
| `maxChangesPerMonth` | 월 최대 변경 횟수 | 2 |
| `allowSameDayCancel` | 당일 취소 허용 | false |
| `lateCancelDeadline` | 늦은 취소 마감 시간 (HH:mm) | "20:00" |

```
예시: "수업은 4시간 전까지 취소 및 변경 가능합니다 (월 2회)"
→ minCancelHours: 4, maxChangesPerMonth: 2
```

### 4. 환불 정책 (RefundPolicy)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `fullRefundDays` | 전액 환불 가능 일수 (수업 전) | 1 |
| `partialRefundRatio` | 첫 수업 후 환불 비율 | 0.67 (2/3) |
| `halfwayRefundRatio` | 1/2 경과 후 환불 비율 | 0 |
| `noShowRefundRatio` | 노쇼 시 환불 비율 | 0.67 |

```
예시:
- 수업 1일전까지 100% 환불
- 첫 수업 경과후(노쇼 포함): 2/3에 해당하는 금액
- 1/2 경과후(4주기준2회수업후): 환불하지 않음
```

### 5. 노쇼 정책 (NoShowPolicy)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `deductLesson` | 노쇼 시 횟수 차감 | true |
| `chargeNoShowFee` | 노쇼 수수료 부과 | false |
| `noShowFeeAmount` | 노쇼 수수료 금액 | 0 |
| `gracePeriodMinutes` | 지각 허용 시간 (분) | 15 |

### 6. 멤버십 혜택 (MembershipBenefits)

| 항목 | 설명 | 기본값 |
|------|------|--------|
| `freeInstrumentRental` | 악기 무료 대여 | false |
| `unlimitedPracticeRoom` | 연습실 무제한 사용 | false |
| `autoRenewal` | 정기수업 자동 연장 | true |
| `eventDiscount` | 행사 할인 적용 | false |
| `customBenefits` | 기타 혜택 (텍스트 목록) | [] |

---

## 엔티티 설계

### LessonPolicy (레슨 정책)

```dart
@HiveType(typeId: 70)
@JsonSerializable()
class LessonPolicy extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? lessonClassId;  // null이면 선생님 기본 정책

  @HiveField(2)
  final String teacherId;

  // 수업 일정
  @HiveField(3)
  final int lessonsPerMonth;

  @HiveField(4)
  final int annualHolidays;

  // 이월 정책 (월정액)
  @HiveField(5)
  final bool allowCarryover;

  @HiveField(6)
  final int maxCarryoverLessons;

  @HiveField(7)
  final int carryoverPeriodMonths;

  // 변경/취소 정책
  @HiveField(8)
  final int minCancelHours;

  @HiveField(9)
  final int maxChangesPerMonth;

  @HiveField(10)
  final bool allowSameDayCancel;

  // 환불 정책
  @HiveField(11)
  final int fullRefundDays;

  @HiveField(12)
  final double partialRefundRatio;

  @HiveField(13)
  final double halfwayRefundRatio;

  @HiveField(14)
  final double noShowRefundRatio;

  // 노쇼 정책
  @HiveField(15)
  final bool deductLessonOnNoShow;

  @HiveField(16)
  final int gracePeriodMinutes;

  // 메타
  @HiveField(17)
  final DateTime createdAt;

  @HiveField(18)
  final DateTime? updatedAt;
}
```

### MembershipBenefit (멤버십 혜택)

```dart
@HiveType(typeId: 71)
@JsonSerializable()
class MembershipBenefit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lessonClassId;

  @HiveField(2)
  final bool freeInstrumentRental;

  @HiveField(3)
  final bool unlimitedPracticeRoom;

  @HiveField(4)
  final bool autoRenewal;

  @HiveField(5)
  final bool eventDiscount;

  @HiveField(6)
  final List<String> customBenefits;

  @HiveField(7)
  final DateTime createdAt;
}
```

---

## UI 설계

### 1. 정책 설정 화면 (선생님/학원 설정)

```
┌─────────────────────────────────────┐
│ ← 레슨 정책 설정                     │
├─────────────────────────────────────┤
│                                     │
│ 📅 수업 일정                         │
│ ┌─────────────────────────────────┐ │
│ │ 월 수업 횟수    [3][4][5][ 0 ]  │ │
│ │ 연간 휴원       [2][4][6][ 0 ]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🔄 이월 정책 (월정액)                │
│ ┌─────────────────────────────────┐ │
│ │ 이월 허용       [ON] / OFF      │ │
│ │ 최대 이월 횟수  [1][2][3][ 0 ]  │ │
│ │ 이월 유효기간   [1][2][3][ 0 ]월│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⏰ 변경/취소 정책                    │
│ ┌─────────────────────────────────┐ │
│ │ 최소 취소 시간  [2][4][24][ 0 ]H│ │
│ │ 월 변경 횟수    [1][2][무제한]  │ │
│ │ 당일 취소 허용  ON / [OFF]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 💰 환불 정책                         │
│ ┌─────────────────────────────────┐ │
│ │ 전액 환불      수업 [ 1 ]일 전  │ │
│ │ 첫수업 후      [1/2][2/3][전액] │ │
│ │ 절반 경과 후   [없음][1/3][1/2] │ │
│ │ 노쇼 시        [없음][1/3][2/3] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🚫 노쇼 정책                         │
│ ┌─────────────────────────────────┐ │
│ │ 횟수 차감      [ON] / OFF       │ │
│ │ 지각 허용      [10][15][30]분   │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [ 저장 ]                    │
└─────────────────────────────────────┘
```

### 2. 멤버십 혜택 설정 (학원용)

```
┌─────────────────────────────────────┐
│ ← 멤버십 혜택 설정                   │
├─────────────────────────────────────┤
│                                     │
│ 🎁 기본 혜택                         │
│ ┌─────────────────────────────────┐ │
│ │ ☑ 악기 무료 대여                 │ │
│ │ ☑ 연습실 무제한 사용             │ │
│ │ ☑ 정기수업 자동 연장             │ │
│ │ ☐ 행사 할인 적용                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ✨ 추가 혜택                         │
│ ┌─────────────────────────────────┐ │
│ │ • 오케스트라 입단 자격           │ │
│ │ • 개인악기 보관                  │ │
│ │                    [+ 혜택 추가] │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [ 저장 ]                    │
└─────────────────────────────────────┘
```

### 3. 수강권 발급 시 정책 표시

```
┌─────────────────────────────────────┐
│ 발급 요약                            │
├─────────────────────────────────────┤
│ 유형      회차제 (8회, 90일)         │
│ 금액      320,000원                  │
│ 시작일    2026년 1월 25일            │
│ 만료일    2026년 4월 25일            │
├─────────────────────────────────────┤
│ 📋 적용 정책                         │
│ • 취소: 4시간 전까지 (월 2회)        │
│ • 노쇼: 횟수 차감                    │
│ • 환불: 1일전 100%, 이후 2/3         │
└─────────────────────────────────────┘
```

### 3-1. 변경/취소 횟수 — 정책 기본값 + 수강권 단위 조정

> **원칙**: 선생님 기본 정책이 수강권 생성 시 **기본 표기**로 적용되지만,
> 실제 변경/취소권 컨트롤은 **수강권 단위**로 저장/차감된다.
> 즉, 발급 시점의 정책 값이 개별 수강권의 `totalRescheduleAllowance`로 스냅샷된다.

| 항목 | 필드 | 동작 |
|------|------|------|
| 정책 기본값 | `LessonPolicy.maxChangesPerMonth` | 선생님 "레슨 정책 설정"에서 관리 (default 2) |
| 수강권 스냅샷 | `Subscription.totalRescheduleAllowance` | 발급 시 정책값으로 자동 채움, 개별 조정 가능 |
| 사용량 카운터 | `Subscription.usedRescheduleCount` | 변경/취소할 때마다 +1 |
| 남은 횟수 | `remainingReschedule` | `total - used` (getter) |

**UI 동작 (`IssueSubscriptionScreen`)**:

1. 레슨(membership) 선택 시 → `LessonClass.teacherId` 도출 → `effectivePolicyProvider`로 정책 조회
2. 정책 로딩 성공 시 `_rescheduleAllowance` 기본값을 `maxChangesPerMonth`로 자동 시드
3. 섹션 헤더 옆 뱃지 표시:
   - 정책값과 동일: `[기본 정책]` (primary 색상)
   - 사용자가 개별 조정: `[개별 조정됨]` (회색)
4. 보조 문구로 "선생님 기본 정책: 월 N회 변경 가능 (이 수강권에서 개별 조정 가능)" 노출

**왜 스냅샷 방식인가**:
- 수강권 발급 이후 선생님이 정책을 변경해도 **기존 수강권의 취소권은 유지**되어야 법적 안정성 확보
- 학생마다 특별 협의(프로모션, 케어 학생 등)로 횟수를 달리할 수 있는 유연성
- 정책은 "다음 발급부터 적용", 기존 수강권은 "발급 당시 값 유지"

---

## 정책 적용 흐름

```
1. 선생님/학원이 기본 정책 설정
   └─ 설정 > 레슨 정책 설정

2. 클래스별 정책 오버라이드 (선택)
   └─ 클래스 설정 > 정책 커스텀

3. 수강권 발급 시 정책 자동 적용
   └─ 발급 화면에서 적용 정책 표시

4. 학생/학부모에게 정책 안내
   └─ 수강권 상세에서 정책 확인 가능
   └─ AppBar 우측 📋 아이콘 → "적용 정책" 바텀시트 (SubscriptionPolicySheet)
      · 변경/취소: 기준시간 + 월 한도 + 남은 횟수 (수강권 스냅샷)
      · 노쇼 / 이월 / 환불: 선생님의 현행 정책 (정보 안내)
      · 하단 안내: 발급 시점 정책 고정 (법적 안정성)
```

---

## 구현 우선순위

| 순위 | 기능 | 설명 |
|:----:|------|------|
| 1 | 변경/취소 정책 | 가장 자주 사용되는 정책 |
| 2 | 환불 정책 | 법적 근거 필요 |
| 3 | 이월 정책 | 월정액 필수 |
| 4 | 노쇼 정책 | 운영 효율화 |
| 5 | 멤버십 혜택 | 학원 차별화 |

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `lesson_policy.dart` | 정책 엔티티 |
| `membership_benefit.dart` | 혜택 엔티티 |
| `lesson_policy_screen.dart` | 정책 설정 화면 |
| `benefit_settings_screen.dart` | 혜택 설정 화면 |
| `subscription_policy_sheet.dart` | 수강권 상세 "적용 정책" 바텀시트 |
| `issue_form_summary_widgets.dart` | 발급 요약 카드 "적용 정책" 섹션 |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-01-25 | 초안 작성 |
| 2026-04-21 | §4 환불 정책 — `refundPolicySummary` getter 추가 + 발급 요약/정책 시트에 환불 라인 노출 |
