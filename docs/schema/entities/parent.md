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

## 관련 엔티티

- [Student](student.md) - 학생 (만 14세 이상 계정)
- [ClassMembership](class_membership.md) - 자녀의 소속 정보
- [Subscription](subscription.md) - 자녀의 수강권
