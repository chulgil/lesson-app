# ClassMembership 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [student_class_system.md](../../specs/student/student_class_system.md)

## 개요

학생이 특정 클래스(LessonClass)에 소속된 관계와 해당 클래스에서의 레슨 정보입니다.
학생은 여러 클래스에 소속될 수 있습니다 (예: 학원 레슨 + 개인 레슨).

---

## Dart 엔티티

```dart
// lib/features/students/domain/entities/class_membership.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_membership.g.dart';

/// 소속 상태
@HiveType(typeId: 53)
enum MembershipStatus {
  @HiveField(0)
  trial,      // 체험 중

  @HiveField(1)
  active,     // 정규 수강 중

  @HiveField(2)
  paused,     // 휴강

  @HiveField(3)
  terminated, // 종료
}

/// 학생의 클래스 소속 정보
@HiveType(typeId: 54)
@JsonSerializable()
class ClassMembership {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lessonClassId;    // 소속 클래스 ID

  @HiveField(2)
  final String studentId;        // 학생 ID

  // 이 클래스에서의 레슨 정보
  @HiveField(3)
  final String instrument;       // 악기 (피아노, 바이올린 등)

  @HiveField(4)
  final MembershipStatus status; // 체험/정규/휴강/종료

  @HiveField(5)
  final String? level;           // 레벨 (입문/초급/중급/고급)

  // 수강료 정보
  @HiveField(6)
  final int monthlyFee;          // 월 수강료

  @HiveField(7)
  final int lessonsPerWeek;      // 주당 레슨 횟수 (1 or 2)

  // 레슨 스케줄
  @HiveField(8)
  final String? lessonDay;       // 레슨 요일 (월, 화, ...)

  @HiveField(9)
  final String? lessonTime;      // 레슨 시간 (14:00)

  @HiveField(10)
  final int lessonDuration;      // 레슨 시간(분) (기본 60)

  // 메모
  @HiveField(11)
  final String? notes;           // 특이사항

  // 메타
  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime? updatedAt;

  const ClassMembership({
    required this.id,
    required this.lessonClassId,
    required this.studentId,
    required this.instrument,
    required this.status,
    this.level,
    required this.monthlyFee,
    this.lessonsPerWeek = 1,
    this.lessonDay,
    this.lessonTime,
    this.lessonDuration = 60,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClassMembership.fromJson(Map<String, dynamic> json) =>
      _$ClassMembershipFromJson(json);

  Map<String, dynamic> toJson() => _$ClassMembershipToJson(this);

  // 계산 필드
  int get monthlyLessonCount => lessonsPerWeek * 4;
  int get lessonFee => (monthlyFee / monthlyLessonCount).round();

  ClassMembership copyWith({
    String? id,
    String? lessonClassId,
    String? studentId,
    String? instrument,
    MembershipStatus? status,
    String? level,
    int? monthlyFee,
    int? lessonsPerWeek,
    String? lessonDay,
    String? lessonTime,
    int? lessonDuration,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassMembership(
      id: id ?? this.id,
      lessonClassId: lessonClassId ?? this.lessonClassId,
      studentId: studentId ?? this.studentId,
      instrument: instrument ?? this.instrument,
      status: status ?? this.status,
      level: level ?? this.level,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      lessonsPerWeek: lessonsPerWeek ?? this.lessonsPerWeek,
      lessonDay: lessonDay ?? this.lessonDay,
      lessonTime: lessonTime ?? this.lessonTime,
      lessonDuration: lessonDuration ?? this.lessonDuration,
      notes: notes ?? this.notes,
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
| `lessonClassId` | String | ✅ | 소속 클래스 ID (FK → LessonClass) |
| `studentId` | String | ✅ | 학생 ID (FK → Student) |
| `instrument` | String | ✅ | 악기명 |
| `status` | MembershipStatus | ✅ | trial, active, paused, terminated |
| `level` | String? | - | 레벨 (입문/초급/중급/고급) |
| `monthlyFee` | int | ✅ | 월 수강료 (원) |
| `lessonsPerWeek` | int | ✅ | 주당 레슨 횟수 (기본값: 1) |
| `lessonDay` | String? | - | 레슨 요일 |
| `lessonTime` | String? | - | 레슨 시간 (HH:mm) |
| `lessonDuration` | int | ✅ | 레슨 시간(분) (기본값: 60) |
| `notes` | String? | - | 특이사항 메모 |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

```json
{
  "id": "cm_001",
  "lessonClassId": "lc_001",
  "studentId": "student_001",
  "instrument": "피아노",
  "status": "active",
  "level": "중급",
  "monthlyFee": 200000,
  "lessonsPerWeek": 1,
  "lessonDay": "화",
  "lessonTime": "15:00",
  "lessonDuration": 60,
  "notes": null,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Repository 인터페이스

```dart
// lib/features/students/domain/repositories/membership_repository.dart

abstract class MembershipRepository {
  /// 클래스의 모든 멤버십 조회
  Future<List<ClassMembership>> getByClassId(String classId);

  /// 학생의 모든 멤버십 조회
  Future<List<ClassMembership>> getByStudentId(String studentId);

  /// 멤버십 생성
  Future<ClassMembership> create(ClassMembership membership);

  /// 멤버십 수정
  Future<ClassMembership> update(ClassMembership membership);

  /// 상태 변경
  Future<void> updateStatus(String id, MembershipStatus status);
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| MembershipStatus | 53 |
| ClassMembership | 54 |

---

## 관련 엔티티

- [LessonClass](lesson_class.md) - 소속 클래스
- [Student](student.md) - 학생
- [Subscription](subscription.md) - 수강권 (멤버십에 연결)
