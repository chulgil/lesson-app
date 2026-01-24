# Subscription 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md)

## 개요

학생별 수강권 정보입니다. ClassMembership(소속 관계)과 연결됩니다.
회차제(8회, 16회), 월정액, 체험 레슨 등의 유형을 지원합니다.

---

## Dart 엔티티

```dart
// lib/features/subscription/domain/entities/subscription.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

/// 수강권 유형
@HiveType(typeId: 55)
enum SubscriptionType {
  @HiveField(0)
  trial,     // 체험 레슨 (무료/할인)

  @HiveField(1)
  monthly,   // 월정액 (기간제)

  @HiveField(2)
  package,   // 회차제 (8회, 16회 등)
}

/// 수강권 상태
@HiveType(typeId: 56)
enum SubscriptionStatus {
  @HiveField(0)
  active,        // 활성 (사용 가능)

  @HiveField(1)
  expiringSoon,  // 만료 임박 (7일 이내 또는 잔여 2회 이하)

  @HiveField(2)
  expired,       // 만료됨

  @HiveField(3)
  paused,        // 일시정지
}

/// 수강권 (학생별)
@HiveType(typeId: 57)
@JsonSerializable()
class Subscription {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;           // 학생 ID

  @HiveField(2)
  final String membershipId;        // 소속 관계 ID (FK → ClassMembership)

  @HiveField(3)
  final String? paymentId;          // 연결된 결제 ID (선택)

  // 수강권 정보
  @HiveField(4)
  final SubscriptionType type;      // trial, monthly, package

  @HiveField(5)
  final int? totalLessons;          // 회차제: 총 횟수

  @HiveField(6)
  final int usedLessons;            // 사용 횟수

  @HiveField(7)
  final DateTime? startDate;        // 시작일

  @HiveField(8)
  final DateTime? endDate;          // 만료일 (기간제)

  @HiveField(9)
  final int amount;                 // 금액

  // 상태
  @HiveField(10)
  final SubscriptionStatus status;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.studentId,
    required this.membershipId,
    this.paymentId,
    required this.type,
    this.totalLessons,
    this.usedLessons = 0,
    this.startDate,
    this.endDate,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  // 계산 필드
  int? get remainingLessons =>
      type == SubscriptionType.package ? (totalLessons! - usedLessons) : null;

  bool get isExpiringSoon =>
      (endDate != null && endDate!.difference(DateTime.now()).inDays <= 7) ||
      (remainingLessons != null && remainingLessons! <= 2);

  double? get usagePercentage =>
      type == SubscriptionType.package
          ? (usedLessons / totalLessons!) * 100
          : null;

  Subscription copyWith({
    String? id,
    String? studentId,
    String? membershipId,
    String? paymentId,
    SubscriptionType? type,
    int? totalLessons,
    int? usedLessons,
    DateTime? startDate,
    DateTime? endDate,
    int? amount,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      membershipId: membershipId ?? this.membershipId,
      paymentId: paymentId ?? this.paymentId,
      type: type ?? this.type,
      totalLessons: totalLessons ?? this.totalLessons,
      usedLessons: usedLessons ?? this.usedLessons,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

## 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `studentId` | String | ✅ | 학생 ID (FK → Student) |
| `membershipId` | String | ✅ | 소속 관계 ID (FK → ClassMembership) |
| `paymentId` | String? | - | 연결된 결제 ID |
| `type` | SubscriptionType | ✅ | trial, monthly, package |
| `totalLessons` | int? | - | 총 횟수 (회차제만) |
| `usedLessons` | int | ✅ | 사용 횟수 (기본값: 0) |
| `startDate` | DateTime? | - | 시작일 |
| `endDate` | DateTime? | - | 만료일 (월정액만) |
| `amount` | int | ✅ | 금액 (원) |
| `status` | SubscriptionStatus | ✅ | active, expiringSoon, expired, paused |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

### 회차제 (8회권)

```json
{
  "id": "sub_001",
  "studentId": "student_001",
  "membershipId": "cm_001",
  "paymentId": "pay_001",
  "type": "package",
  "totalLessons": 8,
  "usedLessons": 3,
  "startDate": "2026-01-05T00:00:00.000Z",
  "endDate": "2026-03-05T00:00:00.000Z",
  "amount": 200000,
  "status": "active",
  "createdAt": "2026-01-05T00:00:00.000Z",
  "updatedAt": null
}
```

### 월정액

```json
{
  "id": "sub_002",
  "studentId": "student_002",
  "membershipId": "cm_002",
  "paymentId": "pay_002",
  "type": "monthly",
  "totalLessons": null,
  "usedLessons": 2,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-01-31T23:59:59.000Z",
  "amount": 150000,
  "status": "active",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Repository 인터페이스

```dart
// lib/features/subscription/domain/repositories/subscription_repository.dart

abstract class SubscriptionRepository {
  /// 학생의 수강권 목록 조회
  Future<List<Subscription>> getByStudentId(String studentId);

  /// 멤버십의 활성 수강권 조회
  Future<Subscription?> getActiveByMembershipId(String membershipId);

  /// 수강권 생성
  Future<Subscription> create(Subscription subscription);

  /// 레슨 1회 사용 (usedLessons += 1)
  Future<Subscription> useLesson(String id);

  /// 상태 업데이트
  Future<void> updateStatus(String id, SubscriptionStatus status);

  /// 만료 임박 수강권 조회 (알림용)
  Future<List<Subscription>> getExpiringSoon();
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| SubscriptionType | 55 |
| SubscriptionStatus | 56 |
| Subscription | 57 |

---

## 비즈니스 규칙

| 규칙 | 설명 |
|------|------|
| 만료 임박 (기간제) | 만료일 7일 이내 |
| 만료 임박 (회차제) | 잔여 2회 이하 |
| 자동 상태 전환 | 만료일 경과 시 `expired`로 변경 |
| 레슨 차감 | 레슨 완료 시 `usedLessons` += 1 |

---

## 관련 엔티티

- [ClassMembership](class_membership.md) - 소속 관계
- [Student](student.md) - 학생
- [Payment](../../specs/payment/payment_unified_spec.md) - 결제
