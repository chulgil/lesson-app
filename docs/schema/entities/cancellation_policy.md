# CancellationPolicy 엔티티

> 작성일: 2026-01-24
> 상태: 📋 설계 완료 (미구현)
> 관련 스펙: [trial_lesson_system.md](../../specs/trial/trial_lesson_system.md#노쇼취소-정책-시스템-상세)

---

## 개요

레슨 취소 및 노쇼(무단결석) 상황을 처리하는 정책 시스템.
체험 레슨과 정규 레슨에 각각 다른 정책을 적용.

---

## Hive TypeId 할당 (예정)

> ⚠️ 구현 시 할당 필요

| TypeId | 엔티티 |
|:------:|--------|
| TBD | CancellationPolicy |
| TBD | CancellationPenaltyType |
| TBD | NoShowPolicy |
| TBD | TeacherNoShowCompensation |
| TBD | TeacherNoShowOption |
| TBD | CancellationRecord |
| TBD | CancellationType |
| TBD | PenaltyResult |
| TBD | PaymentMethod |

---

## CancellationPolicy (취소 정책)

```dart
/// 선생님별 취소/노쇼 정책 설정
class CancellationPolicy {
  final String teacherId;
  final int cancellationDeadlineHours;    // 취소 마감 (기본 24시간)
  final CancellationPenaltyType penaltyType;
  final int? freeCancellationsPerMonth;   // 무료 취소 횟수 (옵션 C)
  final NoShowPolicy noShowPolicy;
  final TeacherNoShowCompensation teacherNoShowCompensation;
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| teacherId | String | 선생님 ID | - |
| cancellationDeadlineHours | int | 취소 마감 시간 | 24 |
| penaltyType | CancellationPenaltyType | 페널티 유형 | fullCharge |
| freeCancellationsPerMonth | int? | 월 무료 취소 횟수 | null |
| noShowPolicy | NoShowPolicy | 노쇼 정책 | - |
| teacherNoShowCompensation | TeacherNoShowCompensation | 선생님 노쇼 보상 | - |

---

## CancellationPenaltyType (취소 페널티 유형)

```dart
/// 취소 페널티 유형
enum CancellationPenaltyType {
  fullCharge,         // A: 100% 과금
  halfCharge,         // B: 50% 과금
  freeThenCharge,     // C: 월 n회 무료 후 100% 과금
  rescheduleOnly,     // D: 취소 불가, 일정변경만 허용
}
```

| 값 | 설명 | 적용 |
|------|------|------|
| fullCharge | 100% 과금 (기본) | 가장 엄격 |
| halfCharge | 50% 과금 | 중간 |
| freeThenCharge | 월 n회 무료 후 100% | 유연함 |
| rescheduleOnly | 취소 불가, 변경만 | 노쇼 방지 |

---

## NoShowPolicy (노쇼 정책)

```dart
/// 노쇼 정책
class NoShowPolicy {
  final int graceMinutes;                 // 노쇼 판정 대기 시간 (기본 15분)
  final bool chargeFullAmount;            // 100% 과금 여부
  final int? warningsBeforeBlacklist;     // 블랙리스트 전 경고 횟수 (null=사용안함)
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| graceMinutes | int | 노쇼 판정 대기 시간 | 15 |
| chargeFullAmount | bool | 100% 과금 여부 | true |
| warningsBeforeBlacklist | int? | 블랙리스트 전 경고 횟수 | null |

---

## TeacherNoShowCompensation (선생님 노쇼 보상)

```dart
/// 선생님 노쇼 시 학생 보상 설정
class TeacherNoShowCompensation {
  final TeacherNoShowOption regularLessonOption;   // 정규레슨 기본 보상
  final TeacherNoShowOption trialLessonOption;     // 체험레슨 기본 보상
  final int? extraMinutes;                         // 시간 연장 시 추가 분 (기본 15분)
}
```

---

## TeacherNoShowOption (선생님 노쇼 보상 옵션)

```dart
/// 선생님 노쇼 보상 옵션
enum TeacherNoShowOption {
  // 정규 레슨용
  addLesson,              // A: 레슨 1회 추가
  extendNextLesson,       // D: 다음 레슨 시간 연장

  // 체험 레슨용
  freeRebooking,          // A: 무료 재예약
  freeRebookingWithCoupon, // C: 무료 재예약 + 정규레슨 할인 쿠폰
}
```

| 값 | 적용 | 설명 |
|------|------|------|
| addLesson | 정규 레슨 | 레슨 1회 추가 |
| extendNextLesson | 정규 레슨 | 다음 레슨 시간 연장 |
| freeRebooking | 체험 레슨 | 무료 재예약 |
| freeRebookingWithCoupon | 체험 레슨 | 무료 재예약 + 할인 쿠폰 |

---

## CancellationRecord (취소/노쇼 기록)

```dart
/// 취소/노쇼 기록
class CancellationRecord {
  final String id;
  final String lessonId;
  final String studentId;
  final CancellationType type;            // 취소 or 노쇼
  final DateTime requestedAt;
  final int hoursBeforeLesson;            // 레슨 몇 시간 전 취소
  final bool withinDeadline;              // 마감 내 취소 여부
  final PenaltyResult? penalty;           // 페널티 결과
  final bool isEmergencyException;        // 긴급상황 예외 처리 여부
}
```

---

## CancellationType (취소 유형)

```dart
enum CancellationType {
  cancelled,          // 학생이 취소
  noShow,             // 학생 노쇼
  teacherCancelled,   // 선생님이 취소
  teacherNoShow,      // 선생님 노쇼
}
```

---

## PenaltyResult (페널티 결과)

```dart
/// 페널티 처리 결과
class PenaltyResult {
  final PaymentMethod paymentMethod;      // 선결제/후결제
  final int chargeAmount;                 // 과금 금액
  final bool lessonDeducted;              // 레슨 차감 여부 (선결제)
  final String? invoiceId;                // 레거시 필드, 현행 청구서 기능 없음
}
```

---

## PaymentMethod (결제 방식)

```dart
enum PaymentMethod {
  prepaid,            // 선결제 (무통장입금 등)
  postpaid,           // 후결제
}
```

| 결제 방식 | 마감 전 취소 | 마감 후 취소 | 노쇼 |
|----------|-------------|-------------|------|
| prepaid | 전액 환불 | 레슨 1회 차감 | 레슨 1회 차감 |
| postpaid | 무료 | 100% 청구 | 100% 청구 |

---

## 파일 위치 (예정)

```
lib/features/schedule/domain/entities/cancellation_policy.dart
lib/features/schedule/domain/entities/no_show_policy.dart
lib/features/schedule/domain/entities/cancellation_record.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [trial_lesson_system.md](../../specs/trial/trial_lesson_system.md) | 체험 레슨 시스템 스펙 |
| [payment_architecture.md](../../specs/subscription/payment_architecture.md) | 현행 무통장입금 정책 + 미래 앱 사용료 과금 경계 |
