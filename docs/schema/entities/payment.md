# Payment 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [payment_unified_spec.md](../../specs/payment/payment_unified_spec.md)

## 개요

결제 및 청구서 관련 엔티티입니다. 2단계 입금확인 시스템을 지원합니다.

---

## Dart 엔티티

### Payment (결제)

```dart
// lib/features/lessons/domain/entities/payment.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// 결제 상태
@HiveType(typeId: 70)
enum PaymentStatus {
  @HiveField(0)
  pending,            // 청구됨 (입금 대기)

  @HiveField(1)
  studentConfirmed,   // 입금완료 표시 (학생이 클릭)

  @HiveField(2)
  confirmed,          // 확인 완료 (선생님이 확인)

  @HiveField(3)
  overdue,            // 연체 (납부기한 초과)

  @HiveField(4)
  cancelled,          // 취소

  @HiveField(5)
  refunded,           // 환불
}

/// 결제 단위
@HiveType(typeId: 71)
enum PaymentUnit {
  @HiveField(0)
  monthly,   // 월정액

  @HiveField(1)
  package,   // 패키지 (N회권)
}

/// 결제 수단
@HiveType(typeId: 72)
enum PaymentMethod {
  @HiveField(0)
  transfer,  // 계좌이체

  @HiveField(1)
  card,      // 카드

  @HiveField(2)
  cash,      // 현금
}

/// 결제 시점
@HiveType(typeId: 73)
enum PaymentTiming {
  @HiveField(0)
  prepaid,   // 선결제

  @HiveField(1)
  postpaid,  // 후결제
}

/// 청구 대상
@HiveType(typeId: 74)
enum BillingTarget {
  @HiveField(0)
  student,  // 학생 본인 (만 14세 이상)

  @HiveField(1)
  parent,   // 부모 계정 (만 14세 미만)
}

/// 결제 기록
@HiveType(typeId: 75)
@JsonSerializable()
class Payment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? studentId;

  @HiveField(2)
  final String? lessonClassId;

  @HiveField(3)
  final String? invoiceId;

  @HiveField(4)
  final int amount;

  @HiveField(5)
  final PaymentMethod method;

  @HiveField(6)
  final PaymentStatus status;

  @HiveField(7)
  final DateTime? dueDate;

  // 2단계 입금확인
  @HiveField(8)
  final bool studentConfirmed;

  @HiveField(9)
  final DateTime? studentConfirmedAt;

  @HiveField(10)
  final DateTime? confirmedAt;

  @HiveField(11)
  final String? confirmedBy;

  @HiveField(12)
  final String? memo;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    this.studentId,
    this.lessonClassId,
    this.invoiceId,
    required this.amount,
    required this.method,
    required this.status,
    this.dueDate,
    this.studentConfirmed = false,
    this.studentConfirmedAt,
    this.confirmedAt,
    this.confirmedBy,
    this.memo,
    required this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  /// 선생님 확인 대기 상태인지
  bool get isAwaitingTeacherConfirmation =>
      status == PaymentStatus.pending && studentConfirmed;

  /// 표시용 상태
  String get displayStatus {
    if (isAwaitingTeacherConfirmation) return '확인 대기';
    switch (status) {
      case PaymentStatus.pending:
        return '입금 대기';
      case PaymentStatus.studentConfirmed:
        return '확인 대기';
      case PaymentStatus.confirmed:
        return '완료';
      case PaymentStatus.overdue:
        return '연체';
      case PaymentStatus.cancelled:
        return '취소됨';
      case PaymentStatus.refunded:
        return '환불됨';
    }
  }
}
```

### Invoice (청구서)

```dart
// lib/features/lessons/domain/entities/invoice.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

/// 청구서 유형
@HiveType(typeId: 76)
enum InvoiceType {
  @HiveField(0)
  trial,       // 체험레슨

  @HiveField(1)
  monthly,     // 월정액

  @HiveField(2)
  package,     // 패키지

  @HiveField(3)
  additional,  // 추가레슨
}

/// 청구서 상태
@HiveType(typeId: 77)
enum InvoiceStatus {
  @HiveField(0)
  draft,       // 임시저장

  @HiveField(1)
  issued,      // 발행됨

  @HiveField(2)
  paid,        // 결제완료

  @HiveField(3)
  cancelled,   // 취소됨
}

/// 청구서
@HiveType(typeId: 78)
@JsonSerializable()
class Invoice {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final String? studentId;

  @HiveField(3)
  final String? childProfileId;

  @HiveField(4)
  final BillingTarget billingTarget;

  @HiveField(5)
  final String billingAccountId;

  @HiveField(6)
  final InvoiceType type;

  @HiveField(7)
  final PaymentUnit unit;

  @HiveField(8)
  final int amount;

  @HiveField(9)
  final int? discountAmount;

  @HiveField(10)
  final int finalAmount;

  @HiveField(11)
  final String? description;

  @HiveField(12)
  final DateTime issuedAt;

  @HiveField(13)
  final DateTime dueDate;

  @HiveField(14)
  final InvoiceStatus status;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime? updatedAt;

  const Invoice({
    required this.id,
    required this.teacherId,
    this.studentId,
    this.childProfileId,
    required this.billingTarget,
    required this.billingAccountId,
    required this.type,
    required this.unit,
    required this.amount,
    this.discountAmount,
    required this.finalAmount,
    this.description,
    required this.issuedAt,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceToJson(this);
}
```

### TeacherPaymentConfig (선생님 결제 설정)

```dart
// lib/features/profile/domain/entities/teacher_payment_config.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_payment_config.g.dart';

/// 미결제 처리 정책
@HiveType(typeId: 79)
enum UnpaidPolicy {
  @HiveField(0)
  allowLesson,     // 레슨 허용

  @HiveField(1)
  blockLesson,     // 레슨 차단

  @HiveField(2)
  reminderOnly,    // 알림만
}

/// 선생님 결제 설정
@HiveType(typeId: 80)
@JsonSerializable()
class TeacherPaymentConfig {
  @HiveField(0)
  final String teacherId;

  @HiveField(1)
  final PaymentTiming defaultTiming;

  @HiveField(2)
  final bool allowStudentChoice;

  @HiveField(3)
  final List<PaymentMethod> acceptedMethods;

  @HiveField(4)
  final String? bankAccount;

  @HiveField(5)
  final String? bankName;

  @HiveField(6)
  final String? accountHolder;

  @HiveField(7)
  final bool packageEnabled;

  @HiveField(8)
  final UnpaidPolicy unpaidPolicy;

  @HiveField(9)
  final int? graceDays;

  @HiveField(10)
  final List<int> reminderDays;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  const TeacherPaymentConfig({
    required this.teacherId,
    this.defaultTiming = PaymentTiming.prepaid,
    this.allowStudentChoice = false,
    this.acceptedMethods = const [PaymentMethod.transfer],
    this.bankAccount,
    this.bankName,
    this.accountHolder,
    this.packageEnabled = true,
    this.unpaidPolicy = UnpaidPolicy.reminderOnly,
    this.graceDays,
    this.reminderDays = const [7, 3, 1],
    required this.createdAt,
    this.updatedAt,
  });

  factory TeacherPaymentConfig.fromJson(Map<String, dynamic> json) =>
      _$TeacherPaymentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherPaymentConfigToJson(this);
}
```

---

## 필드 설명

### Payment

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `studentId` | String? | - | 학생 ID |
| `lessonClassId` | String? | - | 클래스 ID |
| `invoiceId` | String? | - | 청구서 ID |
| `amount` | int | ✅ | 금액 (원) |
| `method` | PaymentMethod | ✅ | 결제 수단 |
| `status` | PaymentStatus | ✅ | 결제 상태 |
| `dueDate` | DateTime? | - | 납부기한 |
| `studentConfirmed` | bool | ✅ | 학생 입금완료 표시 |
| `studentConfirmedAt` | DateTime? | - | 학생 확인 시점 |
| `confirmedAt` | DateTime? | - | 선생님 확인 시점 |
| `confirmedBy` | String? | - | 확인자 ID |

### Invoice

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `teacherId` | String | ✅ | 선생님 ID |
| `studentId` | String? | - | 학생 ID (만 14세 이상) |
| `childProfileId` | String? | - | 자녀 프로필 ID (만 14세 미만) |
| `billingTarget` | BillingTarget | ✅ | 청구 대상 |
| `type` | InvoiceType | ✅ | 청구서 유형 |
| `unit` | PaymentUnit | ✅ | 결제 단위 |
| `amount` | int | ✅ | 원금액 |
| `finalAmount` | int | ✅ | 최종 금액 |
| `dueDate` | DateTime | ✅ | 납부기한 |
| `status` | InvoiceStatus | ✅ | 청구서 상태 |

---

## JSON 예시

### Payment

```json
{
  "id": "pay_001",
  "studentId": "student_001",
  "invoiceId": "inv_001",
  "amount": 200000,
  "method": "transfer",
  "status": "studentConfirmed",
  "dueDate": "2026-01-31T23:59:59.000Z",
  "studentConfirmed": true,
  "studentConfirmedAt": "2026-01-25T10:30:00.000Z",
  "confirmedAt": null,
  "confirmedBy": null,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

### Invoice

```json
{
  "id": "inv_001",
  "teacherId": "teacher_001",
  "studentId": "student_001",
  "billingTarget": "student",
  "billingAccountId": "student_001",
  "type": "monthly",
  "unit": "monthly",
  "amount": 200000,
  "discountAmount": null,
  "finalAmount": 200000,
  "description": "2026년 1월 수강료",
  "issuedAt": "2026-01-01T00:00:00.000Z",
  "dueDate": "2026-01-10T23:59:59.000Z",
  "status": "issued",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| PaymentStatus | 70 |
| PaymentUnit | 71 |
| PaymentMethod | 72 |
| PaymentTiming | 73 |
| BillingTarget | 74 |
| Payment | 75 |
| InvoiceType | 76 |
| InvoiceStatus | 77 |
| Invoice | 78 |
| UnpaidPolicy | 79 |
| TeacherPaymentConfig | 80 |

---

## 2단계 입금확인 흐름

```
[청구서 발행]
      │
      ▼
  pending (🟡 입금 대기)
      │
      ├──[학생: 입금완료 클릭]──► studentConfirmed (🔔 확인 대기)
      │                              │
      │                              ├──[선생님: 입금확인]──► confirmed (🟢 완료)
      │                              │
      │                              └──[선생님: 반려]──► pending (다시 대기)
      │
      ├──[납부기한 초과]──► overdue (🔴 연체)
      │
      ├──[취소]──► cancelled
      │
      └──[환불]──► refunded
```

---

## 관련 엔티티

- [Subscription](subscription.md) - 결제 후 활성화되는 수강권
- [Student](student.md) - 학생
- [Parent](parent.md) - 학부모 (자녀 대신 결제)
