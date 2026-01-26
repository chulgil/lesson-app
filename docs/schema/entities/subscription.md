# Subscription 엔티티

> 마지막 업데이트: 2026-01-25
> 관련 스펙: [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md)

## 개요

학생별 수강권 정보입니다. ClassMembership(소속 관계)과 연결됩니다.

**혼합형 모델**: 모든 수강권은 기간 + 횟수를 동시에 표시합니다.
- 월정액: "2/4회 남음 (D-15)" - `lessonsPerMonth` 필드로 월 포함 횟수 관리
- 패키지: "5/8회 남음 (D-45)" - `totalLessons` 필드로 총 횟수 관리
- 5주차 정책: [lesson_schedule.md](../../specs/lesson/lesson_schedule.md#5주차-정책-월-4회-기준-정기레슨) 참조

**교차 수강권**: 하나의 수강권으로 여러 클래스를 자유롭게 수강
- `scope` 필드로 사용 범위 지정 (단일/복수/학원 전체)
- 참고 사례: 뮤라벨(Music Life Balance)

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

/// 🆕 수강권 사용 범위 (교차 수강 지원)
@HiveType(typeId: 61)
enum SubscriptionScope {
  @HiveField(0)
  singleClass,    // 단일 클래스 (기존 방식, 기본값)

  @HiveField(1)
  multiClass,     // 복수 클래스 지정 (특정 클래스들만)

  @HiveField(2)
  organization,   // 학원 전체 (교차 수강)
}

/// 🆕 결제 방식 (선생님/학원 설정용)
@HiveType(typeId: 33)
enum BillingType {
  @HiveField(0)
  perPackage,   // 회차 결제 (수업 시작 전 N회분)

  @HiveField(1)
  monthly,      // 월정액 결제 (매월 고정일)
}

/// 🆕 5주차 정책 (수강권용)
@HiveType(typeId: 34)
enum FifthWeekPolicy {
  @HiveField(0)
  skip,         // 휴강 (수업 없음)

  @HiveField(1)
  bonus,        // 보너스 수강권 지급 (+1회)

  @HiveField(2)
  deduct,       // 기존 수강권에서 차감

  @HiveField(3)
  optional,     // 학생 선택
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

  // 🆕 교차 수강 지원 필드
  @HiveField(14)
  final SubscriptionScope scope;    // 사용 범위 (기본: singleClass)

  @HiveField(15)
  final String? organizationId;     // 학원 ID (scope=organization일 때)

  @HiveField(16)
  final List<String>? allowedClassIds; // 허용 클래스 목록 (scope=multiClass일 때)

  // 🆕 결제/보너스 필드
  @HiveField(17)
  final BillingType billingType;      // 결제 방식 (perPackage, monthly)

  @HiveField(18)
  final int? billingDay;              // 결제일 (월정액: 1~31)

  @HiveField(19)
  final int bonusCount;               // 보너스 횟수 (5주차, 이벤트 등)

  @HiveField(20)
  final FifthWeekPolicy? fifthWeekPolicy; // 5주차 정책 (월정액만)

  // 🆕 수강권 이름 및 예약 정책 필드 (2026-01-26)
  @HiveField(21)
  final String? name;                     // 수강권 이름 (예: "그룹레슨수강권", "바이올린수강권")

  @HiveField(22)
  final int? maxRescheduleCount;          // 변경/취소 가능 횟수 (null = 무제한)

  @HiveField(23)
  final int usedRescheduleCount;          // 사용한 변경/취소 횟수

  @HiveField(24)
  final bool autoConfirm;                 // 학생 예약 시 자동 확정 (선생님 컨펌 불필요)

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
    this.scope = SubscriptionScope.singleClass,
    this.billingType = BillingType.perPackage,  // 🆕 기본값: 회차 결제
    this.billingDay,                             // 🆕
    this.bonusCount = 0,                         // 🆕 기본값: 0
    this.fifthWeekPolicy,                        // 🆕
    this.organizationId,                         // 🆕
    this.allowedClassIds,                        // 🆕
    this.name,                                   // 🆕 수강권 이름
    this.maxRescheduleCount,                     // 🆕 변경/취소 가능 횟수
    this.usedRescheduleCount = 0,                // 🆕 사용한 변경/취소 횟수
    this.autoConfirm = false,                    // 🆕 자동 확정 (기본: 컨펌 필요)
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

  /// 변경/취소 가능 여부
  bool get canReschedule {
    if (maxRescheduleCount == null) return true; // 무제한
    return usedRescheduleCount < maxRescheduleCount!;
  }

  /// 남은 변경/취소 횟수
  int? get remainingRescheduleCount {
    if (maxRescheduleCount == null) return null; // 무제한
    return maxRescheduleCount! - usedRescheduleCount;
  }

  /// 수강권 표시 이름 (name이 없으면 기본 이름 생성)
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    switch (type) {
      case SubscriptionType.trial:
        return '체험 레슨';
      case SubscriptionType.monthly:
        return '월정액 ${lessonsPerMonth ?? 4}회';
      case SubscriptionType.package:
        return '${totalLessons ?? 8}회권';
    }
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
    SubscriptionScope? scope,
    String? organizationId,
    List<String>? allowedClassIds,
    BillingType? billingType,
    int? billingDay,
    int? bonusCount,
    FifthWeekPolicy? fifthWeekPolicy,
    String? name,
    int? maxRescheduleCount,
    int? usedRescheduleCount,
    bool? autoConfirm,
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
      scope: scope ?? this.scope,
      organizationId: organizationId ?? this.organizationId,
      allowedClassIds: allowedClassIds ?? this.allowedClassIds,
      billingType: billingType ?? this.billingType,
      billingDay: billingDay ?? this.billingDay,
      bonusCount: bonusCount ?? this.bonusCount,
      fifthWeekPolicy: fifthWeekPolicy ?? this.fifthWeekPolicy,
      name: name ?? this.name,
      maxRescheduleCount: maxRescheduleCount ?? this.maxRescheduleCount,
      usedRescheduleCount: usedRescheduleCount ?? this.usedRescheduleCount,
      autoConfirm: autoConfirm ?? this.autoConfirm,
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
| `lessonsPerMonth` | int? | - | 월정액: 월 포함 횟수 (예: 4) |
| `usedLessons` | int | ✅ | 사용 횟수 (기본값: 0) |
| `startDate` | DateTime? | - | 시작일 |
| `endDate` | DateTime? | - | 만료일 |
| `amount` | int | ✅ | 금액 (원) |
| `scope` | SubscriptionScope | ✅ | 사용 범위 (기본: singleClass) |
| `organizationId` | String? | - | 학원 ID (scope=organization) |
| `allowedClassIds` | List\<String\>? | - | 허용 클래스 목록 (scope=multiClass) |
| `billingType` | BillingType | ✅ | 결제 방식 (기본: perPackage) |
| `billingDay` | int? | - | 결제일 (월정액: 1~31) |
| `bonusCount` | int | ✅ | 보너스 횟수 (기본값: 0) |
| `fifthWeekPolicy` | FifthWeekPolicy? | - | 5주차 정책 (월정액만) |
| `name` | String? | - | 🆕 수강권 이름 (예: "바이올린수강권") |
| `maxRescheduleCount` | int? | - | 🆕 변경/취소 가능 횟수 (null = 무제한) |
| `usedRescheduleCount` | int | ✅ | 🆕 사용한 변경/취소 횟수 (기본값: 0) |
| `autoConfirm` | bool | ✅ | 🆕 학생 예약 시 자동 확정 (기본: false) |
| `status` | SubscriptionStatus | ✅ | active, expiringSoon, expired, paused |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

### 유형별 필드 사용

| 필드 | 체험 | 월정액 | 회차권 |
|------|:----:|:-----:|:------:|
| `totalLessons` | 1 | - | ✅ |
| `lessonsPerMonth` | - | ✅ | - |
| `endDate` | - | ✅ | ✅ |

### 범위별 필드 사용 (교차 수강)

| 필드 | 단일 클래스 | 복수 클래스 | 학원 전체 |
|------|:----------:|:----------:|:--------:|
| `scope` | singleClass | multiClass | organization |
| `membershipId` | ✅ 필수 | ✅ 필수 (기본) | ✅ 필수 (기본) |
| `organizationId` | - | - | ✅ 필수 |
| `allowedClassIds` | - | ✅ 필수 | - (전체 허용) |

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

### 9. 🆕 교차 수강권 (학원 전체)

```json
{
  "id": "sub_cross_001",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "paymentId": "pay_008",
  "type": "package",
  "totalLessons": 8,
  "usedLessons": 3,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-03-01T00:00:00.000Z",
  "amount": 440000,
  "scope": "organization",
  "organizationId": "org_muralabel",
  "allowedClassIds": null,
  "status": "active",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 표시: "5/8회 남음 (D-35)" + 교차 수강 가능
// 이용 가능: 피아노, 바이올린, 첼로, 보컬 (학원 내 모든 클래스)
```

### 10. 🆕 복수 클래스 수강권 (특정 클래스만)

```json
{
  "id": "sub_multi_001",
  "studentId": "student_2",
  "membershipId": "cm_002",
  "paymentId": "pay_009",
  "type": "package",
  "totalLessons": 8,
  "usedLessons": 2,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-03-01T00:00:00.000Z",
  "amount": 400000,
  "scope": "multiClass",
  "organizationId": null,
  "allowedClassIds": ["class_piano", "class_violin"],
  "status": "active",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 표시: "6/8회 남음 (D-35)"
// 이용 가능: 피아노, 바이올린만
```

### 11. 🆕 월정액 + 5주차 보너스 (통합 표시)

```json
{
  "id": "sub_monthly_bonus_001",
  "studentId": "student_1",
  "membershipId": "cm_001",
  "paymentId": "pay_010",
  "type": "monthly",
  "totalLessons": null,
  "lessonsPerMonth": 4,
  "usedLessons": 2,
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-01-31T23:59:59.000Z",
  "amount": 200000,
  "scope": "singleClass",
  "billingType": "monthly",
  "billingDay": 27,
  "bonusCount": 1,
  "fifthWeekPolicy": "bonus",
  "status": "active",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
// 학생 화면 표시: "수강권 3회 남음" (2/4 잔여 + 1 보너스)
// 선생님 화면: "월정액 (4회) + 보너스 1회 | 결제일: 매월 27일"
```

### 12. 🆕 회차 결제 (perPackage)

```json
{
  "id": "sub_package_billing_001",
  "studentId": "student_3",
  "membershipId": "cm_003",
  "paymentId": "pay_011",
  "type": "package",
  "totalLessons": 8,
  "lessonsPerMonth": null,
  "usedLessons": 3,
  "startDate": "2026-01-15T00:00:00.000Z",
  "endDate": "2026-03-15T00:00:00.000Z",
  "amount": 380000,
  "scope": "singleClass",
  "billingType": "perPackage",
  "billingDay": null,
  "bonusCount": 0,
  "fifthWeekPolicy": null,
  "status": "active",
  "createdAt": "2026-01-15T00:00:00.000Z"
}
// 학생 화면 표시: "수강권 5회 남음 (D-49)"
// 선생님 화면: "8회권 | 5/8회 남음 (D-49)"
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
| SubscriptionOptionType | 58 |
| SubscriptionLimitType | 59 |
| SubscriptionOption | 60 |
| SubscriptionScope | 61 |
| SubscriptionUsage | 62 |
| BillingType | 33 |
| FifthWeekPolicy | 34 |

---

## 월정액 vs 회차권 핵심 차이

| 구분 | 월정액 (monthly) | 회차권 (package) |
|------|-----------------|-----------------|
| **결제 시점** | 매월 고정일 (예: 27일) | 수업 시작일 기준 |
| **결제 주기** | 규칙적 (매월) | 불규칙 (4주마다) |
| **유효기간** | 월 단위 (1일~말일) | 임의 기간 (예: 2~3개월) |
| **소멸 시점** | 매월 말일 (월 단위 리셋) | **endDate 경과 시** (미사용분 소멸) |
| **미사용분 처리** | ❌ **소멸** (다음달 이월 불가) | ✅ **이월** (유효기간 내), ❌ 유효기간 후 소멸 |
| **usedLessons** | 매월 리셋 (0으로 초기화) | 누적 (리셋 없음) |
| **5주차 정책** | ✅ 적용 (보너스/휴강) | ❌ 해당 없음 (재결제) |
| **적합 대상** | 장기/정기 수강 | 단기/유동 일정 |

### 회차권 유효기간 예시

```
8회권 구매 (startDate: 1/15, endDate: 3/15)
└── 유효기간: 2개월 (학원별 정책)
└── 3/15 이전: 미사용분 유지 (이월 가능)
└── 3/15 경과: 미사용분 소멸 (status → expired)
```

> 상세 스펙: [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md#-실제-학원-결제-패턴-비교)

---

## 비즈니스 규칙

| 규칙 | 설명 |
|------|------|
| 만료 임박 (기간) | 만료일 7일 이내 |
| 만료 임박 (횟수) | 잔여 2회 이하 |
| 자동 상태 전환 | 만료일(`endDate`) 경과 시 `expired`로 변경 |
| 레슨 차감 | 레슨 완료 시 `usedLessons` += 1 |
| 월정액 리셋 | 매월 1일 또는 결제일 기준 `usedLessons` = 0, 미사용분 소멸 |
| 회차권 이월 | 유효기간(`endDate`) 내 미사용분 유지 |
| **회차권 소멸** | `endDate` 경과 시 미사용분 소멸 (expired) |
| 5주차 정책 | 월 4회 기준에서 5주 있는 달 처리 ([상세](../../specs/lesson/lesson_schedule.md#5주차-정책-월-4회-기준-정기레슨)) |
| 보너스 지급 | 5주차 보너스 시 `bonusCount` += 1 |

### 회차권 유효기간 (학원별 정책 예시)

| 회차권 | 일반 유효기간 | 비고 |
|--------|:------------:|------|
| 4회권 | 1~2개월 | 단기 수강 |
| 8회권 | 2~3개월 | 일반적 |
| 16회권 | 4~6개월 | 장기 수강 |

> ⚠️ 유효기간은 학원/선생님별로 설정 가능

### 수강권 알림 정책 (🆕 2026-01-25)

| 알림 유형 | 타이밍 | 수신자 | 참조 |
|----------|--------|--------|------|
| 만료 임박 | D-7, D-3, D-1 | 학생 | [notification.md](notification.md) |
| 잔여 1회 | 마지막 레슨 완료 시 | 학생 | [notification.md](notification.md) |
| 다음 레슨 예약 요청 | 회차권 레슨 완료 시 | 선생님 | [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md#58-레슨-예약-방식-정기레슨-vs-회차권) |

> 정기레슨 vs 회차권 스케줄링 차이: [lesson_schedule.md](../../specs/lesson/lesson_schedule.md#-정기레슨-vs-회차권-스케줄링-비교)

---

## 부가 서비스 옵션 (SubscriptionOption)

> 학원의 연습실 이용, 악기 대여 등 부가 서비스를 수강권에 포함

### Enum 정의

```dart
/// 부가 서비스 유형
@HiveType(typeId: 58)
enum SubscriptionOptionType {
  @HiveField(0)
  practiceRoom,      // 연습실 이용

  @HiveField(1)
  instrumentRental,  // 악기 대여

  @HiveField(2)
  recordingStudio,   // 녹음실 이용

  @HiveField(3)
  ensembleRoom,      // 합주실 이용

  @HiveField(4)
  other,             // 기타
}

/// 부가 서비스 제한 유형
@HiveType(typeId: 59)
enum SubscriptionLimitType {
  @HiveField(0)
  unlimited,  // 무제한

  @HiveField(1)
  count,      // 횟수 제한 (예: 월 10회)

  @HiveField(2)
  hours,      // 시간 제한 (예: 월 20시간)
}
```

### 엔티티 정의

```dart
/// 수강권 부가 서비스 옵션
@HiveType(typeId: 60)
@JsonSerializable()
class SubscriptionOption {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId;  // FK → Subscription

  @HiveField(2)
  final SubscriptionOptionType type;

  @HiveField(3)
  final SubscriptionLimitType limitType;

  @HiveField(4)
  final int? limitValue;  // count: 횟수, hours: 시간 (null = 무제한)

  @HiveField(5)
  final int usedValue;  // 사용량 (횟수 or 시간)

  @HiveField(6)
  final String? description;  // 추가 설명 (예: "평일 09:00-18:00")

  const SubscriptionOption({
    required this.id,
    required this.subscriptionId,
    required this.type,
    required this.limitType,
    this.limitValue,
    this.usedValue = 0,
    this.description,
  });

  /// 잔여 사용량
  int? get remainingValue {
    if (limitType == SubscriptionLimitType.unlimited) return null;
    if (limitValue == null) return null;
    return limitValue! - usedValue;
  }

  /// 유형 라벨 (한글)
  String get typeLabel {
    switch (type) {
      case SubscriptionOptionType.practiceRoom:
        return '연습실';
      case SubscriptionOptionType.instrumentRental:
        return '악기 대여';
      case SubscriptionOptionType.recordingStudio:
        return '녹음실';
      case SubscriptionOptionType.ensembleRoom:
        return '합주실';
      case SubscriptionOptionType.other:
        return '기타';
    }
  }

  /// 요약 텍스트
  String get summaryText {
    if (limitType == SubscriptionLimitType.unlimited) {
      return '$typeLabel 무제한';
    }
    final unit = limitType == SubscriptionLimitType.count ? '회' : '시간';
    return '$typeLabel $remainingValue/$limitValue$unit';
  }
}
```

### 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `subscriptionId` | String | ✅ | 수강권 ID (FK → Subscription) |
| `type` | SubscriptionOptionType | ✅ | 옵션 유형 |
| `limitType` | SubscriptionLimitType | ✅ | 제한 유형 |
| `limitValue` | int? | - | 제한 값 (null = 무제한) |
| `usedValue` | int | ✅ | 사용량 (기본값: 0) |
| `description` | String? | - | 추가 설명 |

### JSON 예시

```json
// 연습실 무제한
{
  "id": "opt_001",
  "subscriptionId": "sub_001",
  "type": "practiceRoom",
  "limitType": "unlimited",
  "limitValue": null,
  "usedValue": 0,
  "description": "평일 09:00-22:00"
}
// 표시: "연습실 무제한"

// 연습실 월 20회
{
  "id": "opt_002",
  "subscriptionId": "sub_002",
  "type": "practiceRoom",
  "limitType": "count",
  "limitValue": 20,
  "usedValue": 12,
  "description": null
}
// 표시: "연습실 8/20회"

// 녹음실 월 10시간
{
  "id": "opt_003",
  "subscriptionId": "sub_003",
  "type": "recordingStudio",
  "limitType": "hours",
  "limitValue": 10,
  "usedValue": 3,
  "description": "예약 필수"
}
// 표시: "녹음실 7/10시간"
```

### Hive TypeId (부가 서비스)

| 타입 | TypeId |
|------|--------|
| SubscriptionOptionType | 58 |
| SubscriptionLimitType | 59 |
| SubscriptionOption | 60 |

---

## 교차 수강권 (SubscriptionScope)

> 하나의 수강권으로 여러 클래스를 자유롭게 수강할 수 있는 모델
> 참고 사례: 뮤라벨(Music Life Balance)

### Enum 정의

```dart
/// 수강권 사용 범위
@HiveType(typeId: 61)
enum SubscriptionScope {
  @HiveField(0)
  singleClass,    // 단일 클래스 (기존 방식, 기본값)

  @HiveField(1)
  multiClass,     // 복수 클래스 지정

  @HiveField(2)
  organization,   // 학원 전체 (교차 수강)
}
```

### 범위별 설명

| 범위 | 설명 | 사용 예시 |
|------|------|----------|
| `singleClass` | 지정 클래스에서만 사용 (기본값) | 바이올린 8회권 → 바이올린만 |
| `multiClass` | 지정한 클래스들에서만 사용 | 피아노+바이올린 패키지 |
| `organization` | 학원 내 모든 클래스 사용 | 뮤라벨 교차 수강권 |

---

## 수강권 사용 기록 (SubscriptionUsage)

> 교차 수강권에서 어떤 클래스에서 몇 회를 사용했는지 추적

### 엔티티 정의

```dart
/// 수강권 사용 기록
@HiveType(typeId: 62)
@JsonSerializable()
class SubscriptionUsage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId;  // FK → Subscription

  @HiveField(2)
  final String classId;         // 사용한 클래스 ID

  @HiveField(3)
  final String? lessonId;       // 연결된 레슨 ID (선택)

  @HiveField(4)
  final DateTime usedAt;        // 사용 일시

  @HiveField(5)
  final String? note;           // 메모 (선택)

  const SubscriptionUsage({
    required this.id,
    required this.subscriptionId,
    required this.classId,
    this.lessonId,
    required this.usedAt,
    this.note,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionUsageFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionUsageToJson(this);
}
```

### 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `subscriptionId` | String | ✅ | 수강권 ID (FK → Subscription) |
| `classId` | String | ✅ | 사용한 클래스 ID |
| `lessonId` | String? | - | 연결된 레슨 ID |
| `usedAt` | DateTime | ✅ | 사용 일시 |
| `note` | String? | - | 메모 |

### JSON 예시

```json
// 교차 수강권 사용 기록
[
  {
    "id": "usage_001",
    "subscriptionId": "sub_cross_001",
    "classId": "class_piano",
    "lessonId": "lesson_001",
    "usedAt": "2026-01-15T15:00:00.000Z",
    "note": null
  },
  {
    "id": "usage_002",
    "subscriptionId": "sub_cross_001",
    "classId": "class_violin",
    "lessonId": "lesson_002",
    "usedAt": "2026-01-20T14:00:00.000Z",
    "note": null
  },
  {
    "id": "usage_003",
    "subscriptionId": "sub_cross_001",
    "classId": "class_piano",
    "lessonId": "lesson_003",
    "usedAt": "2026-01-25T16:00:00.000Z",
    "note": null
  }
]
// 결과: 피아노 2회, 바이올린 1회 사용 (총 3/8회)
```

### 클래스별 사용량 집계

```dart
/// 클래스별 사용량 집계
Map<String, int> getUsageByClass(List<SubscriptionUsage> usages) {
  final result = <String, int>{};
  for (final usage in usages) {
    result[usage.classId] = (result[usage.classId] ?? 0) + 1;
  }
  return result;
}

// 예시 결과:
// {
//   "class_piano": 2,
//   "class_violin": 1
// }
```

### Hive TypeId (교차 수강)

| 타입 | TypeId |
|------|--------|
| SubscriptionScope | 61 |
| SubscriptionUsage | 62 |

---

## 수강권 템플릿 (SubscriptionTemplate) 🆕

> 추가일: 2026-01-26
> 선생님이 자주 사용하는 수강권을 템플릿으로 미리 저장하여 빠르게 발급

### 엔티티 정의

```dart
/// 수강권 템플릿 (선생님별)
@HiveType(typeId: 63)
@JsonSerializable()
class SubscriptionTemplate {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;             // 선생님 ID (FK → Teacher)

  @HiveField(2)
  final String? organizationId;       // 학원 ID (null = 개인 선생님)

  @HiveField(3)
  final String name;                  // 템플릿 이름 (예: "바이올린수강권", "그룹레슨수강권")

  @HiveField(4)
  final SubscriptionType type;        // trial, monthly, package

  @HiveField(5)
  final int? totalLessons;            // 패키지: 총 횟수 (예: 8)

  @HiveField(6)
  final int? lessonsPerMonth;         // 월정액: 월 포함 횟수 (예: 4)

  @HiveField(7)
  final int amount;                   // 금액

  @HiveField(8)
  final int? validityDays;            // 유효기간 (일 단위, 예: 60일)

  @HiveField(9)
  final BillingType billingType;      // 결제 방식

  @HiveField(10)
  final int? billingDay;              // 결제일 (월정액: 1~31)

  @HiveField(11)
  final FifthWeekPolicy? fifthWeekPolicy; // 5주차 정책 (월정액만)

  // 🆕 예약 정책
  @HiveField(12)
  final int? maxRescheduleCount;      // 변경/취소 가능 횟수 (null = 무제한)

  @HiveField(13)
  final bool autoConfirm;             // 학생 예약 시 자동 확정

  @HiveField(14)
  final String? description;          // 템플릿 설명 (선택)

  @HiveField(15)
  final bool isActive;                // 활성 여부 (비활성화 시 목록에서 숨김)

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime? updatedAt;

  const SubscriptionTemplate({
    required this.id,
    required this.teacherId,
    this.organizationId,
    required this.name,
    required this.type,
    this.totalLessons,
    this.lessonsPerMonth,
    required this.amount,
    this.validityDays,
    this.billingType = BillingType.perPackage,
    this.billingDay,
    this.fifthWeekPolicy,
    this.maxRescheduleCount,
    this.autoConfirm = false,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionTemplateToJson(this);

  /// 템플릿에서 수강권 생성
  Subscription createSubscription({
    required String studentId,
    required String membershipId,
    String? paymentId,
  }) {
    final now = DateTime.now();
    final endDate = validityDays != null
        ? now.add(Duration(days: validityDays!))
        : (type == SubscriptionType.monthly
            ? DateTime(now.year, now.month + 1, 0) // 월말
            : null);

    return Subscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      membershipId: membershipId,
      paymentId: paymentId,
      type: type,
      totalLessons: totalLessons,
      lessonsPerMonth: lessonsPerMonth,
      startDate: now,
      endDate: endDate,
      amount: amount,
      billingType: billingType,
      billingDay: billingDay,
      fifthWeekPolicy: fifthWeekPolicy,
      name: name,
      maxRescheduleCount: maxRescheduleCount,
      autoConfirm: autoConfirm,
      status: SubscriptionStatus.active,
      createdAt: now,
    );
  }
}
```

### 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `teacherId` | String | ✅ | 선생님 ID (FK → Teacher) |
| `organizationId` | String? | - | 학원 ID (null = 개인 선생님) |
| `name` | String | ✅ | 템플릿/수강권 이름 |
| `type` | SubscriptionType | ✅ | trial, monthly, package |
| `totalLessons` | int? | - | 패키지: 총 횟수 |
| `lessonsPerMonth` | int? | - | 월정액: 월 포함 횟수 |
| `amount` | int | ✅ | 금액 (원) |
| `validityDays` | int? | - | 유효기간 (일 단위) |
| `billingType` | BillingType | ✅ | 결제 방식 |
| `billingDay` | int? | - | 결제일 (월정액: 1~31) |
| `fifthWeekPolicy` | FifthWeekPolicy? | - | 5주차 정책 (월정액만) |
| `maxRescheduleCount` | int? | - | 변경/취소 가능 횟수 |
| `autoConfirm` | bool | ✅ | 자동 확정 여부 (기본: false) |
| `description` | String? | - | 템플릿 설명 |
| `isActive` | bool | ✅ | 활성 여부 (기본: true) |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

### JSON 예시

```json
// 바이올린 8회권 템플릿
{
  "id": "tpl_violin_8",
  "teacherId": "teacher_001",
  "organizationId": null,
  "name": "바이올린수강권",
  "type": "package",
  "totalLessons": 8,
  "lessonsPerMonth": null,
  "amount": 380000,
  "validityDays": 60,
  "billingType": "perPackage",
  "billingDay": null,
  "fifthWeekPolicy": null,
  "maxRescheduleCount": 2,
  "autoConfirm": true,
  "description": "1:1 개인 레슨 8회권 (2개월 유효)",
  "isActive": true,
  "createdAt": "2026-01-26T00:00:00.000Z"
}

// 그룹레슨 월정액 템플릿
{
  "id": "tpl_group_monthly",
  "teacherId": "teacher_001",
  "organizationId": "org_001",
  "name": "그룹레슨수강권",
  "type": "monthly",
  "totalLessons": null,
  "lessonsPerMonth": 4,
  "amount": 150000,
  "validityDays": null,
  "billingType": "monthly",
  "billingDay": 25,
  "fifthWeekPolicy": "bonus",
  "maxRescheduleCount": 1,
  "autoConfirm": true,
  "description": "그룹 레슨 월 4회 (5주차 보너스)",
  "isActive": true,
  "createdAt": "2026-01-26T00:00:00.000Z"
}

// 체험 레슨 템플릿
{
  "id": "tpl_trial",
  "teacherId": "teacher_001",
  "organizationId": null,
  "name": "체험레슨",
  "type": "trial",
  "totalLessons": 1,
  "lessonsPerMonth": null,
  "amount": 30000,
  "validityDays": 14,
  "billingType": "perPackage",
  "billingDay": null,
  "fifthWeekPolicy": null,
  "maxRescheduleCount": 1,
  "autoConfirm": true,
  "description": "30분 체험 레슨",
  "isActive": true,
  "createdAt": "2026-01-26T00:00:00.000Z"
}
```

### Repository 인터페이스

```dart
// lib/features/subscription/domain/repositories/subscription_template_repository.dart

abstract class SubscriptionTemplateRepository {
  /// 선생님의 템플릿 목록 조회
  Future<List<SubscriptionTemplate>> getByTeacherId(String teacherId);

  /// 활성 템플릿 목록 조회
  Future<List<SubscriptionTemplate>> getActiveByTeacherId(String teacherId);

  /// 템플릿 생성
  Future<SubscriptionTemplate> create(SubscriptionTemplate template);

  /// 템플릿 수정
  Future<SubscriptionTemplate> update(SubscriptionTemplate template);

  /// 템플릿 비활성화
  Future<void> deactivate(String id);

  /// 템플릿 삭제
  Future<void> delete(String id);
}
```

### Hive TypeId (템플릿)

| 타입 | TypeId |
|------|--------|
| SubscriptionTemplate | 63 |

---

## 관련 엔티티

- [ClassMembership](class_membership.md) - 소속 관계
- [Student](student.md) - 학생
- [Payment](../../specs/payment/payment_unified_spec.md) - 결제
