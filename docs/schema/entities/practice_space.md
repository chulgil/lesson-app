# PracticeSpace 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [student_centered_architecture.md](../../specs/lesson/student_centered_architecture.md)

## 개요

학생 중심 아키텍처의 핵심 엔티티입니다. 학생이 소유하는 연습 공간과 코치(선생님) 연결을 관리합니다.

---

## Dart 엔티티

### PracticeSpace (연습 공간)

```dart
// lib/features/practice/domain/entities/practice_space.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'practice_space.g.dart';

/// 연습 공간 (학생 소유)
@HiveType(typeId: 81)
@JsonSerializable()
class PracticeSpace {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ownerId;           // 학생 User ID

  @HiveField(2)
  final String name;              // "내 바이올린 연습"

  @HiveField(3)
  final List<String> instruments;

  @HiveField(4)
  final bool allowCoachComments;

  @HiveField(5)
  final bool showStreakPublicly;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  const PracticeSpace({
    required this.id,
    required this.ownerId,
    required this.name,
    this.instruments = const [],
    this.allowCoachComments = true,
    this.showStreakPublicly = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeSpace.fromJson(Map<String, dynamic> json) =>
      _$PracticeSpaceFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeSpaceToJson(this);
}
```

### CoachConnection (코치 연결)

```dart
// lib/features/practice/domain/entities/coach_connection.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coach_connection.g.dart';

/// 연결 상태
@HiveType(typeId: 82)
enum ConnectionStatus {
  @HiveField(0)
  pending,    // 대기중

  @HiveField(1)
  active,     // 활성

  @HiveField(2)
  paused,     // 일시중지

  @HiveField(3)
  ended,      // 종료
}

/// 연결 출처
@HiveType(typeId: 83)
enum ConnectionSource {
  @HiveField(0)
  studentInvite,    // 학생이 초대

  @HiveField(1)
  teacherInvite,    // 선생님이 초대

  @HiveField(2)
  appSearch,        // 앱 검색
}

/// 코치 연결 (학생-선생님 관계)
@HiveType(typeId: 84)
@JsonSerializable()
class CoachConnection {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String practiceSpaceId;

  @HiveField(2)
  final String? coachUserId;      // null이면 외부 선생님

  @HiveField(3)
  final String studentUserId;

  @HiveField(4)
  final ExternalTeacher? externalTeacher;

  @HiveField(5)
  final ConnectionStatus status;

  @HiveField(6)
  final ConnectionSource source;

  @HiveField(7)
  final String instrument;

  // 권한
  @HiveField(8)
  final bool canViewPractice;

  @HiveField(9)
  final bool canComment;

  @HiveField(10)
  final bool canSuggestAssignments;

  @HiveField(11)
  final DateTime connectedAt;

  @HiveField(12)
  final DateTime? endedAt;

  const CoachConnection({
    required this.id,
    required this.practiceSpaceId,
    this.coachUserId,
    required this.studentUserId,
    this.externalTeacher,
    required this.status,
    required this.source,
    required this.instrument,
    this.canViewPractice = true,
    this.canComment = true,
    this.canSuggestAssignments = true,
    required this.connectedAt,
    this.endedAt,
  });

  factory CoachConnection.fromJson(Map<String, dynamic> json) =>
      _$CoachConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$CoachConnectionToJson(this);

  /// 앱 사용 선생님인지
  bool get isAppCoach => coachUserId != null;

  /// 외부 선생님인지
  bool get isExternalCoach => coachUserId == null && externalTeacher != null;
}

/// 외부 선생님 (앱 미사용)
@HiveType(typeId: 85)
@JsonSerializable()
class ExternalTeacher {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String instrument;

  @HiveField(2)
  final String? lessonDay;

  @HiveField(3)
  final String? notes;

  const ExternalTeacher({
    required this.name,
    required this.instrument,
    this.lessonDay,
    this.notes,
  });

  factory ExternalTeacher.fromJson(Map<String, dynamic> json) =>
      _$ExternalTeacherFromJson(json);

  Map<String, dynamic> toJson() => _$ExternalTeacherToJson(this);
}
```

### Assignment (과제)

```dart
// lib/features/practice/domain/entities/assignment.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assignment.g.dart';

/// 과제 상태
@HiveType(typeId: 86)
enum AssignmentStatus {
  @HiveField(0)
  suggested,    // 제안됨 (선생님 → 학생)

  @HiveField(1)
  accepted,     // 수락됨

  @HiveField(2)
  declined,     // 거절됨

  @HiveField(3)
  completed,    // 완료됨
}

/// 과제
@HiveType(typeId: 87)
@JsonSerializable()
class Assignment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String practiceSpaceId;

  @HiveField(2)
  final String? suggestedByCoachId;   // null이면 학생이 직접 생성

  @HiveField(3)
  final String studentUserId;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final AssignmentStatus status;

  @HiveField(8)
  final DateTime? acceptedAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  const Assignment({
    required this.id,
    required this.practiceSpaceId,
    this.suggestedByCoachId,
    required this.studentUserId,
    required this.title,
    this.description,
    this.dueDate,
    required this.status,
    this.acceptedAt,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentToJson(this);

  /// 선생님이 제안한 과제인지
  bool get isSuggestedByCoach => suggestedByCoachId != null;
}
```

### InviteCode (초대 코드)

```dart
// lib/features/profile/domain/entities/invite_code.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_code.g.dart';

/// 초대 유형
@HiveType(typeId: 88)
enum InviteType {
  @HiveField(0)
  studentToTeacher,   // 학생 → 선생님

  @HiveField(1)
  teacherToStudent,   // 선생님 → 학생
}

/// 초대 코드
@HiveType(typeId: 89)
@JsonSerializable()
class InviteCode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code;              // 6자리 코드 또는 UUID

  @HiveField(2)
  final String creatorUserId;

  @HiveField(3)
  final InviteType type;

  @HiveField(4)
  final String? practiceSpaceId;  // 학생 초대 시

  @HiveField(5)
  final String? instrument;

  @HiveField(6)
  final DateTime expiresAt;       // 24시간 후 만료

  @HiveField(7)
  final bool used;

  @HiveField(8)
  final DateTime createdAt;

  const InviteCode({
    required this.id,
    required this.code,
    required this.creatorUserId,
    required this.type,
    this.practiceSpaceId,
    this.instrument,
    required this.expiresAt,
    this.used = false,
    required this.createdAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) =>
      _$InviteCodeFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCodeToJson(this);

  /// 만료되었는지
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 사용 가능한지
  bool get isValid => !used && !isExpired;
}
```

---

## 필드 설명

### PracticeSpace

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `ownerId` | String | ✅ | 소유자 (학생) User ID |
| `name` | String | ✅ | 공간 이름 |
| `instruments` | List<String> | ✅ | 악기 목록 |
| `allowCoachComments` | bool | ✅ | 코치 댓글 허용 |
| `showStreakPublicly` | bool | ✅ | 스트릭 공개 여부 |

### CoachConnection

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `practiceSpaceId` | String | ✅ | 연습 공간 ID |
| `coachUserId` | String? | - | 코치 User ID (null = 외부 선생님) |
| `studentUserId` | String | ✅ | 학생 User ID |
| `externalTeacher` | ExternalTeacher? | - | 외부 선생님 정보 |
| `status` | ConnectionStatus | ✅ | 연결 상태 |
| `source` | ConnectionSource | ✅ | 연결 출처 |
| `instrument` | String | ✅ | 담당 악기 |
| `canViewPractice` | bool | ✅ | 연습 기록 조회 권한 |
| `canComment` | bool | ✅ | 댓글 권한 |
| `canSuggestAssignments` | bool | ✅ | 과제 제안 권한 |

### Assignment

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `practiceSpaceId` | String | ✅ | 연습 공간 ID |
| `suggestedByCoachId` | String? | - | 제안한 코치 ID (null = 학생 생성) |
| `studentUserId` | String | ✅ | 학생 User ID |
| `title` | String | ✅ | 과제 제목 |
| `status` | AssignmentStatus | ✅ | 과제 상태 |
| `dueDate` | DateTime? | - | 마감일 |

---

## JSON 예시

### PracticeSpace

```json
{
  "id": "ps_001",
  "ownerId": "user_student_001",
  "name": "내 바이올린 연습",
  "instruments": ["바이올린"],
  "allowCoachComments": true,
  "showStreakPublicly": false,
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

### CoachConnection

```json
{
  "id": "cc_001",
  "practiceSpaceId": "ps_001",
  "coachUserId": "user_teacher_001",
  "studentUserId": "user_student_001",
  "externalTeacher": null,
  "status": "active",
  "source": "studentInvite",
  "instrument": "바이올린",
  "canViewPractice": true,
  "canComment": true,
  "canSuggestAssignments": true,
  "connectedAt": "2026-01-01T00:00:00.000Z"
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| PracticeSpace | 81 |
| ConnectionStatus | 82 |
| ConnectionSource | 83 |
| CoachConnection | 84 |
| ExternalTeacher | 85 |
| AssignmentStatus | 86 |
| Assignment | 87 |
| InviteType | 88 |
| InviteCode | 89 |

---

## 권한 모델

| 데이터 | 학생 | 앱 사용 선생님 | 외부 선생님 |
|--------|:----:|:--------------:|:-----------:|
| 연습 기록 | 읽기/쓰기 | 읽기 | - |
| 연습 통계 | 읽기/쓰기 | 읽기 | - |
| 과제 | 읽기/쓰기/삭제 | 제안/읽기 | - |
| 코치 피드백 | 읽기 | 읽기/쓰기 | - |
| 연결 관리 | 추가/해제 | 해제만 | - |

---

## 초대 URL 형식

```
학생 → 선생님: lessonapp://invite/coach/{code}
선생님 → 학생: lessonapp://invite/student/{code}
웹 딥링크:     https://lessonapp.kr/invite/{type}/{code}
```

---

## 관련 엔티티

- [Student](student.md) - 학생
- [Subscription](subscription.md) - 수강권
- [LessonClass](lesson_class.md) - 클래스 (학원 컨텍스트)
