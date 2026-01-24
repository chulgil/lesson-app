# Subscription 엔티티

> 마지막 업데이트: 2026-01-25
> 관련 스펙: [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md)

## 개요

학생별 수강권 정보입니다. ClassMembership(소속 관계)과 연결됩니다.
**혼합형 모델**: 모든 수강권은 기간 + 횟수를 동시에 표시합니다.

- 월정액: "2/4회 남음 (D-15)" - `lessonsPerMonth` 필드로 월 포함 횟수 관리
- 패키지: "5/8회 남음 (D-45)" - `totalLessons` 필드로 총 횟수 관리
- 5주차 정책: [lesson_schedule.md](../../specs/lesson/lesson_schedule.md#5주차-정책-월-4회-기준-정기레슨) 참조

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
  final int? totalLessons;          // 패키지: 총 횟수 (예: 8회권)

  @HiveField(6)
  final int usedLessons;            // 사용 횟수 (월정액: 이번달 사용, 패키지: 누적)

  @HiveField(7)
  final DateTime? startDate;        // 시작일

  @HiveField(8)
  final DateTime? endDate;          // 만료일

  @HiveField(9)
  final int amount;                 // 금액

  @HiveField(13)
  final int? lessonsPerMonth;       // 월정액: 월 포함 횟수 (예: 4회)

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
    this.lessonsPerMonth,
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

  // 계산 필드 (혼합형)

  /// 잔여 횟수 (패키지 또는 월정액)
  int? get remainingLessons {
    if (type == SubscriptionType.package && totalLessons != null) {
      return totalLessons! - usedLessons;
    }
    if (type == SubscriptionType.monthly && lessonsPerMonth != null) {
      return lessonsPerMonth! - usedLessons;
    }
    return null;
  }

  /// 총 횟수 (패키지: totalLessons, 월정액: lessonsPerMonth)
  int? get totalLessonsForDisplay =>
      type == SubscriptionType.package ? totalLessons : lessonsPerMonth;

  /// 만료일까지 남은 일수
  int? get daysUntilExpiration =>
      endDate?.difference(DateTime.now()).inDays;

  /// 만료 임박 여부 (7일 이내 또는 2회 이하)
  bool get isExpiringSoon =>
      (daysUntilExpiration != null && daysUntilExpiration! <= 7) ||
      (remainingLessons != null && remainingLessons! <= 2);

  /// 사용률 (%)
  double? get usagePercentage {
    final total = totalLessonsForDisplay;
    if (total != null && total > 0) {
      return (usedLessons / total) * 100;
    }
    return null;
  }

  /// 요약 텍스트 (혼합형 표시)
  String get summaryText {
    final remaining = remainingLessons;
    final total = totalLessonsForDisplay;
    final days = daysUntilExpiration;

    if (type == SubscriptionType.trial) {
      return '체험중';
    }

    // 혼합형: "2/4회 남음 (D-15)"
    final countPart = (remaining != null && total != null)
        ? '$remaining/${total}회 남음'
        : '';
    final daysPart = (days != null && days > 0) ? 'D-$days' : '';

    if (countPart.isNotEmpty && daysPart.isNotEmpty) {
      return '$countPart ($daysPart)';
    }
    return countPart.isNotEmpty ? countPart : daysPart;
  }

  Subscription copyWith({
    String? id,
    String? studentId,
    String? membershipId,
    String? paymentId,
    SubscriptionType? type,
    int? totalLessons,
    int? lessonsPerMonth,
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
      lessonsPerMonth: lessonsPerMonth ?? this.lessonsPerMonth,
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
| `totalLessons` | int? | - | 패키지: 총 횟수 (예: 8) |
| `lessonsPerMonth` | int? | - | 🆕 월정액: 월 포함 횟수 (예: 4) |
| `usedLessons` | int | ✅ | 사용 횟수 (기본값: 0) |
| `startDate` | DateTime? | - | 시작일 |
| `endDate` | DateTime? | - | 만료일 |
| `amount` | int | ✅ | 금액 (원) |
| `status` | SubscriptionStatus | ✅ | active, expiringSoon, expired, paused |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

### 유형별 필드 사용

| 필드 | 체험 | 월정액 | 회차권 |
|------|:----:|:-----:|:------:|
| `totalLessons` | 1 | - | ✅ |
| `lessonsPerMonth` | - | ✅ | - |
| `endDate` | - | ✅ | ✅ |

---

## JSON 예시 (전체 케이스)

### 1. 체험 레슨

```json
{
  "id": "sub_trial_001",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "type": "trial",
  "totalLessons": 1,
  "lessonsPerMonth": null,
  "usedLessons": 0,
  "startDate": "2026-01-25T00:00:00.000Z",
  "endDate": null,
  "amount": 30000,
  "status": "active",
  "createdAt": "2026-01-25T00:00:00.000Z"
}
// 표시: "체험중"
```

### 2. 월정액 - 이용중 (2/4회 사용)

```json
{
  "id": "sub_monthly_001",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "paymentId": "pay_001",
  "type": "monthly",
  "totalLessons": null,
  "lessonsPerMonth": 4,
  "usedLessons": 2,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-01-31T23:59:59.000Z",
  "amount": 200000,
  "status": "active",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 표시: "2/4회 남음 (D-6)"
```

### 3. 월정액 - 만료 임박 (3/4회 사용, D-3)

```json
{
  "id": "sub_monthly_002",
  "studentId": "student_2",
  "membershipId": "cm_002",
  "paymentId": "pay_002",
  "type": "monthly",
  "lessonsPerMonth": 4,
  "usedLessons": 3,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-01-28T23:59:59.000Z",
  "amount": 200000,
  "status": "expiringSoon",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 표시: "1/4회 남음 (D-3)" ⚠️ 만료 임박
```

### 4. 월정액 - 만료됨 (지난달)

```json
{
  "id": "sub_monthly_003",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "paymentId": "pay_003",
  "type": "monthly",
  "lessonsPerMonth": 4,
  "usedLessons": 4,
  "startDate": "2025-12-01T00:00:00.000Z",
  "endDate": "2025-12-31T23:59:59.000Z",
  "amount": 200000,
  "status": "expired",
  "createdAt": "2025-12-01T00:00:00.000Z"
}
// 표시: "0/4회 남음 (만료됨)"
```

### 5. 패키지 8회권 - 이용중 (3/8회 사용)

```json
{
  "id": "sub_package_001",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "paymentId": "pay_004",
  "type": "package",
  "totalLessons": 8,
  "lessonsPerMonth": null,
  "usedLessons": 3,
  "startDate": "2026-01-05T00:00:00.000Z",
  "endDate": "2026-03-05T00:00:00.000Z",
  "amount": 380000,
  "status": "active",
  "createdAt": "2026-01-05T00:00:00.000Z"
}
// 표시: "5/8회 남음 (D-39)"
```

### 6. 패키지 8회권 - 만료 임박 (6/8회 사용)

```json
{
  "id": "sub_package_002",
  "studentId": "student_3",
  "membershipId": "cm_003",
  "paymentId": "pay_005",
  "type": "package",
  "totalLessons": 8,
  "usedLessons": 6,
  "startDate": "2025-12-01T00:00:00.000Z",
  "endDate": "2026-02-01T00:00:00.000Z",
  "amount": 380000,
  "status": "expiringSoon",
  "createdAt": "2025-12-01T00:00:00.000Z"
}
// 표시: "2/8회 남음 (D-7)" ⚠️ 만료 임박
```

### 7. 패키지 4회권 - 소진됨

```json
{
  "id": "sub_package_003",
  "studentId": "student_2",
  "membershipId": "cm_002",
  "paymentId": "pay_006",
  "type": "package",
  "totalLessons": 4,
  "usedLessons": 4,
  "startDate": "2025-11-01T00:00:00.000Z",
  "endDate": "2026-01-01T00:00:00.000Z",
  "amount": 200000,
  "status": "expired",
  "createdAt": "2025-11-01T00:00:00.000Z"
}
// 표시: "0/4회 남음 (소진됨)"
```

### 8. 일시정지

```json
{
  "id": "sub_paused_001",
  "studentId": "student_4",
  "membershipId": "cm_004",
  "paymentId": "pay_007",
  "type": "package",
  "totalLessons": 8,
  "usedLessons": 2,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-03-01T00:00:00.000Z",
  "amount": 380000,
  "status": "paused",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 표시: "6/8회 남음 (일시정지)"
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
| 만료 임박 (기간) | 만료일 7일 이내 |
| 만료 임박 (횟수) | 잔여 2회 이하 |
| 자동 상태 전환 | 만료일 경과 시 `expired`로 변경 |
| 레슨 차감 | 레슨 완료 시 `usedLessons` += 1 |
| 월정액 리셋 | 매월 1일 또는 결제일 기준 `usedLessons` = 0 |
| 5주차 정책 | 월 4회 기준에서 5주 있는 달 처리 ([상세](../../specs/lesson/lesson_schedule.md#5주차-정책-월-4회-기준-정기레슨)) |

---

## 관련 엔티티

- [ClassMembership](class_membership.md) - 소속 관계
- [Student](student.md) - 학생
- [Payment](../../specs/payment/payment_unified_spec.md) - 결제
