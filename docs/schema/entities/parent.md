# Parent 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [parent_system.md](../../specs/user/parent_system.md)

## 개요

학부모 계정 정보입니다. 학부모는 여러 자녀(Child)를 관리할 수 있습니다.
만 14세 미만 학생은 회원가입 없이 학부모 계정의 "자녀 프로필"로 존재합니다.

---

## Dart 엔티티

### Parent (학부모)

```dart
// lib/features/parent_home/domain/entities/parent.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'parent.g.dart';

@HiveType(typeId: 63)
@JsonSerializable()
class Parent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;           // User 테이블 FK

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final List<String> childIds;   // 연결된 자녀 ID 목록

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  const Parent({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.childIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Parent.fromJson(Map<String, dynamic> json) =>
      _$ParentFromJson(json);

  Map<String, dynamic> toJson() => _$ParentToJson(this);
}
```

### Child (자녀 프로필)

만 14세 미만 학생을 위한 자녀 프로필입니다. 회원 계정이 아닌 부모 계정에 종속된 데이터입니다.

```dart
// lib/features/parent_home/domain/entities/child.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'child.g.dart';

@HiveType(typeId: 64)
@JsonSerializable()
class Child {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentId;         // 부모 ID

  @HiveField(2)
  final String name;             // 이름/닉네임

  @HiveField(3)
  final int? birthYear;          // 생년 (만 14세 판단용)

  @HiveField(4)
  final String? instrument;      // 악기

  @HiveField(5)
  final String? level;           // 레벨

  // 선생님 연결 상태
  @HiveField(6)
  final ConnectionStatus connectionStatus;

  @HiveField(7)
  final String? connectedTeacherId;  // 연결된 선생님 ID (null이면 미연결)

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  const Child({
    required this.id,
    required this.parentId,
    required this.name,
    this.birthYear,
    this.instrument,
    this.level,
    this.connectionStatus = ConnectionStatus.offline,
    this.connectedTeacherId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) =>
      _$ChildFromJson(json);

  Map<String, dynamic> toJson() => _$ChildToJson(this);

  /// 선생님 연결 필요 기능
  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  /// 미연결 상태에서도 사용 가능한 기능
  bool get canPractice => true;
  bool get canUseMetronome => true;
  bool get canTrackStreak => true;
  bool get canManageRepertoire => true;

  /// 선생님 연결 필요 기능
  bool get canViewLessonNotes => isConnected;
  bool get canReceiveAssignments => isConnected;
  bool get canReceiveFeedback => isConnected;
}
```

### ParentChildRelation (학부모-자녀 관계)

```dart
// lib/features/parent_home/domain/entities/parent_child_relation.dart

@HiveType(typeId: 65)
@JsonSerializable()
class ParentChildRelation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final bool isPrimaryGuardian;  // 주 보호자 여부

  @HiveField(4)
  final bool isBillingTarget;    // 결제 담당 여부

  @HiveField(5)
  final DateTime linkedAt;

  const ParentChildRelation({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.isPrimaryGuardian = true,
    this.isBillingTarget = true,
    required this.linkedAt,
  });

  factory ParentChildRelation.fromJson(Map<String, dynamic> json) =>
      _$ParentChildRelationFromJson(json);

  Map<String, dynamic> toJson() => _$ParentChildRelationToJson(this);
}
```

---

## 필드 설명

### Parent

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `userId` | String | ✅ | User 테이블 FK |
| `name` | String | ✅ | 이름 |
| `phone` | String | ✅ | 연락처 |
| `email` | String? | - | 이메일 |
| `childIds` | List<String> | ✅ | 자녀 ID 목록 |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

### Child

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `parentId` | String | ✅ | 부모 ID (FK → Parent) |
| `name` | String | ✅ | 이름/닉네임 |
| `birthYear` | int? | - | 생년 (연도만) |
| `instrument` | String? | - | 악기 |
| `level` | String? | - | 레벨 |
| `connectionStatus` | ConnectionStatus | ✅ | 선생님 연결 상태 |
| `connectedTeacherId` | String? | - | 연결된 선생님 ID |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

### Parent

```json
{
  "id": "parent_001",
  "userId": "user_001",
  "name": "김철수",
  "phone": "010-1234-5678",
  "email": "parent@example.com",
  "childIds": ["child_001", "child_002"],
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

### Child

```json
{
  "id": "child_001",
  "parentId": "parent_001",
  "name": "김민수",
  "birthYear": 2014,
  "instrument": "바이올린",
  "level": "중급",
  "connectionStatus": "connected",
  "connectedTeacherId": "teacher_001",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| Parent | 63 |
| Child | 64 |
| ParentChildRelation | 65 |

---

## 연령별 계정 구조

| 연령 구분 | 계정 구조 | 학부모 연결 |
|----------|----------|------------|
| **만 14세 미만** | 회원가입 ❌ (Child 프로필) | 필수 (부모 계정에 포함) |
| **만 14세 이상** | Student 계정 가입 가능 | 선택적 연동 |
| **성인 (18+)** | Student 계정 단독 | 선택적 |

---

## Enums

### ConnectionStatus (연결 상태)

```dart
@HiveType(typeId: 66)
enum ConnectionStatus {
  @HiveField(0)
  offline,     // 미연결 (독립적 사용)

  @HiveField(1)
  inviteSent,  // 초대 발송됨 (대기중)

  @HiveField(2)
  connected,   // 선생님 연결됨
}
```

| 값 | 설명 | 사용 가능 기능 |
|------|------|--------------|
| offline | 미연결 | 연습기록, 메트로놈, 스트릭, 레퍼토리 |
| inviteSent | 초대 대기중 | offline과 동일 |
| connected | 연결됨 | 전체 기능 (레슨노트, 과제, 피드백 포함) |

### ProfileType (프로필 유형)

> 이중 역할 처리 (학부모이자 학생인 경우)용

```dart
@HiveType(typeId: 67)
enum ProfileType {
  @HiveField(0)
  parent,   // 학부모 (자녀 관리)

  @HiveField(1)
  student,  // 본인 학생 (성인)

  @HiveField(2)
  child,    // 자녀 프로필 (만 14세 미만)
}
```

| 값 | 설명 | 접근 가능 화면 |
|------|------|--------------|
| parent | 학부모 | 자녀 관리 대시보드, 결제 관리 |
| student | 본인 학생 | 내 레슨, 과제, 연습 |
| child | 자녀 프로필 | 학생용 UI (부모 계정에서 전환) |

### ParentPermission (권한 수준)

```dart
@HiveType(typeId: 68)
enum ParentPermission {
  @HiveField(0)
  viewOnly,       // 열람만 가능

  @HiveField(1)
  managePayments, // 결제 관리

  @HiveField(2)
  manageLessons,  // 레슨 관리

  @HiveField(3)
  fullAccess,     // 전체 권한
}
```

| 값 | 설명 | 권한 범위 |
|------|------|---------|
| viewOnly | 열람 전용 | 레슨/과제/연습 열람만 |
| managePayments | 결제 관리 | viewOnly + 결제 실행 |
| manageLessons | 레슨 관리 | viewOnly + 레슨 일정 조율 |
| fullAccess | 전체 권한 | 모든 기능 |

---

## 추가 엔티티

### UserProfile (프로필 전환)

> 이중 역할 처리 (학부모이자 학생인 경우)용 모델

```dart
// lib/features/parent_home/domain/entities/user_profile.dart

@HiveType(typeId: 69)
@JsonSerializable()
class UserProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;            // User 계정 FK

  @HiveField(2)
  final ProfileType profileType;  // parent, student, child

  @HiveField(3)
  final String displayName;

  @HiveField(4)
  final String? instrument;       // student/child만

  @HiveField(5)
  final bool isConnected;         // 선생님 연결 여부

  @HiveField(6)
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.profileType,
    required this.displayName,
    this.instrument,
    this.isConnected = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

### ParentTeacherConnection (학부모-선생님 연결)

```dart
// lib/features/parent_home/domain/entities/parent_teacher_connection.dart

@HiveType(typeId: 70)
@JsonSerializable()
class ParentTeacherConnection {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentId;

  @HiveField(2)
  final String teacherId;

  @HiveField(3)
  final String? studentId;       // 연결된 자녀 (null이면 자녀 미지정)

  @HiveField(4)
  final ParentPermission permission;

  @HiveField(5)
  final DateTime connectedAt;

  const ParentTeacherConnection({
    required this.id,
    required this.parentId,
    required this.teacherId,
    this.studentId,
    required this.permission,
    required this.connectedAt,
  });

  factory ParentTeacherConnection.fromJson(Map<String, dynamic> json) =>
      _$ParentTeacherConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$ParentTeacherConnectionToJson(this);
}
```

### ParentVisibilitySettings (열람 범위 설정)

> 선생님이 설정하는 학부모 열람 권한

```dart
// lib/features/parent_home/domain/entities/parent_visibility_settings.dart

@HiveType(typeId: 71)
@JsonSerializable()
class ParentVisibilitySettings {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final bool canViewSchedule;

  @HiveField(4)
  final bool canViewAssignments;

  @HiveField(5)
  final bool canViewPractice;

  @HiveField(6)
  final bool canViewLessonNotes;

  @HiveField(7)
  final bool canViewRecordings;

  @HiveField(8)
  final bool canViewDetailedFeedback;

  @HiveField(9)
  final bool canViewChat;

  const ParentVisibilitySettings({
    required this.id,
    required this.teacherId,
    required this.studentId,
    this.canViewSchedule = true,
    this.canViewAssignments = true,
    this.canViewPractice = true,
    this.canViewLessonNotes = true,
    this.canViewRecordings = false,
    this.canViewDetailedFeedback = false,
    this.canViewChat = false,
  });

  factory ParentVisibilitySettings.fromJson(Map<String, dynamic> json) =>
      _$ParentVisibilitySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ParentVisibilitySettingsToJson(this);
}
```

### ParentNotificationSettings (알림 설정)

> 학부모가 설정하는 알림 수신 여부

```dart
// lib/features/parent_home/domain/entities/parent_notification_settings.dart

@HiveType(typeId: 72)
@JsonSerializable()
class ParentNotificationSettings {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentId;

  // 결제 (필수 - 변경 불가)
  @HiveField(2)
  final bool paymentRequest;    // 기본 true, 변경 불가

  @HiveField(3)
  final bool paymentComplete;   // 기본 true, 변경 불가

  @HiveField(4)
  final bool paymentDueSoon;

  // 레슨
  @HiveField(5)
  final bool lessonChange;

  @HiveField(6)
  final bool lessonCancel;

  @HiveField(7)
  final bool lessonStart;

  @HiveField(8)
  final bool lessonEnd;

  // 과제/연습
  @HiveField(9)
  final bool newAssignment;

  @HiveField(10)
  final bool assignmentIncomplete;

  @HiveField(11)
  final bool practiceComplete;

  @HiveField(12)
  final bool streakAchievement;

  // 소통
  @HiveField(13)
  final bool teacherMessage;

  @HiveField(14)
  final bool lessonNoteUpdate;

  // 리포트
  @HiveField(15)
  final bool weeklyReport;

  @HiveField(16)
  final bool monthlyReport;

  const ParentNotificationSettings({
    required this.id,
    required this.parentId,
    this.paymentRequest = true,
    this.paymentComplete = true,
    this.paymentDueSoon = true,
    this.lessonChange = true,
    this.lessonCancel = true,
    this.lessonStart = false,
    this.lessonEnd = false,
    this.newAssignment = true,
    this.assignmentIncomplete = true,
    this.practiceComplete = false,
    this.streakAchievement = false,
    this.teacherMessage = true,
    this.lessonNoteUpdate = false,
    this.weeklyReport = true,
    this.monthlyReport = true,
  });

  factory ParentNotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$ParentNotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ParentNotificationSettingsToJson(this);
}
```

#### 알림 카테고리별 기본값

| 카테고리 | 필드 | 기본값 | 변경 가능 |
|----------|------|--------|----------|
| **결제** | paymentRequest | ON | ✗ (필수) |
| | paymentComplete | ON | ✗ (필수) |
| | paymentDueSoon | ON | ✓ |
| **레슨** | lessonChange | ON | ✓ |
| | lessonCancel | ON | ✓ |
| | lessonStart | OFF | ✓ |
| | lessonEnd | OFF | ✓ |
| **과제/연습** | newAssignment | ON | ✓ |
| | assignmentIncomplete | ON | ✓ |
| | practiceComplete | OFF | ✓ |
| | streakAchievement | OFF | ✓ |
| **소통** | teacherMessage | ON | ✓ |
| | lessonNoteUpdate | OFF | ✓ |
| **리포트** | weeklyReport | ON | ✓ |
| | monthlyReport | ON | ✓ |

---

## View Models (학부모 화면용)

> 읽기 전용 조합 모델 - 핵심 엔티티를 조합하여 UI 표시용으로 사용

### ChildSubscriptionView (자녀 수강권 뷰)

```dart
/// 학부모가 조회하는 자녀 수강권 정보 (읽기 전용 View Model)
/// - LessonClass, Subscription 엔티티를 조합
class ChildSubscriptionView {
  final String childId;
  final String childName;
  final String? academyName;           // 학원명 (null이면 개인레슨)
  final LessonClassType classType;     // academy, private
  final SubscriptionType subscriptionType;  // trial, monthly, package
  final int? remainingLessons;         // 잔여 횟수 (회차제)
  final DateTime? expiresAt;           // 만료일
  final SubscriptionStatus status;     // active, expiringSoon, expired

  /// 만료 임박 여부 (7일 이내)
  bool get isExpiringSoon =>
    expiresAt != null &&
    expiresAt!.difference(DateTime.now()).inDays <= 7;

  /// 잔여 횟수 부족 여부 (2회 이하)
  bool get isLowRemaining =>
    remainingLessons != null && remainingLessons! <= 2;
}
```

### ParentPaymentRequestView (결제 요청 뷰)

```dart
/// 학부모 결제 요청 뷰
class ParentPaymentRequestView {
  final String id;
  final String childId;
  final String childName;
  final String providerName;           // 학원명 또는 선생님명
  final LessonClassType classType;
  final int amount;
  final String description;            // "2월 수강권 (8회)"
  final DateTime requestedAt;
  final DateTime dueDate;
  final PaymentMethod? method;         // card, transfer, cash
  final PaymentStatus status;          // pending, confirmed, overdue
  final String? bankAccount;           // 계좌이체용 계좌 정보
}
```

---

## Hive TypeId (전체)

| 타입 | TypeId |
|------|--------|
| Parent | 63 |
| Child | 64 |
| ParentChildRelation | 65 |
| ConnectionStatus | 66 |
| ProfileType | 67 |
| ParentPermission | 68 |
| UserProfile | 69 |
| ParentTeacherConnection | 70 |
| ParentVisibilitySettings | 71 |
| ParentNotificationSettings | 72 |

---

## 관련 엔티티

- [Student](student.md) - 학생 (만 14세 이상 계정)
- [ClassMembership](class_membership.md) - 자녀의 소속 정보
- [Subscription](subscription.md) - 자녀의 수강권
