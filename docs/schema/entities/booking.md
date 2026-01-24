# Booking 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [Unified_Lesson_Booking_Spec.md](../../specs/lesson/Unified_Lesson_Booking_Spec.md)

## 개요

통합 레슨 신청 시스템의 엔티티입니다. 체험/정기/1회 레슨 신청을 하나의 플로우로 처리합니다.

---

## Dart 엔티티

### TeacherStudentRelation (선생님-학생 관계)

```dart
// lib/features/lessons/domain/entities/teacher_student_relation.dart

import 'package:hive/hive.dart';

part 'teacher_student_relation.g.dart';

/// 선생님-학생 관계 상태
@HiveType(typeId: 90)
enum TeacherStudentRelation {
  @HiveField(0)
  none,       // 처음 만남 (이력 없음)

  @HiveField(1)
  active,     // 현재 정규레슨 진행 중

  @HiveField(2)
  inactive,   // 과거 레슨 이력 있으나 현재 중단
}
```

### LessonType (레슨 유형)

```dart
// lib/features/lessons/domain/entities/lesson_type.dart

import 'package:hive/hive.dart';

part 'lesson_type.g.dart';

/// 레슨 유형
@HiveType(typeId: 91)
enum LessonType {
  @HiveField(0)
  trial,      // 체험레슨

  @HiveField(1)
  regular,    // 정기레슨

  @HiveField(2)
  oneTime,    // 1회 레슨
}
```

### Booking (레슨 예약)

```dart
// lib/features/schedule/domain/entities/booking.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

/// 예약 상태
@HiveType(typeId: 92)
enum BookingStatus {
  @HiveField(0)
  pending,      // 승인 대기

  @HiveField(1)
  approved,     // 승인됨

  @HiveField(2)
  rejected,     // 거절됨

  @HiveField(3)
  cancelled,    // 취소됨

  @HiveField(4)
  completed,    // 완료됨

  @HiveField(5)
  noShow,       // 노쇼
}

/// 레슨 예약
@HiveType(typeId: 93)
@JsonSerializable()
class Booking {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final LessonType lessonType;

  @HiveField(4)
  final BookingStatus status;

  // 일정 정보
  @HiveField(5)
  final DateTime? scheduledDate;      // 체험/1회: 예약 날짜

  @HiveField(6)
  final String? scheduledTime;        // 시간 (HH:mm)

  @HiveField(7)
  final int durationMinutes;          // 레슨 시간 (분)

  // 정기 레슨 정보
  @HiveField(8)
  final String? regularDay;           // 정기: 요일

  @HiveField(9)
  final DateTime? regularStartDate;   // 정기: 시작일

  @HiveField(10)
  final int? regularWeeks;            // 정기: 주 수

  // 레슨 정보
  @HiveField(11)
  final String? instrument;

  @HiveField(12)
  final String? locationId;

  @HiveField(13)
  final String? notes;                // 요청사항

  // 체험 레슨 추가 정보
  @HiveField(14)
  final String? lessonGoal;           // 레슨 목표

  @HiveField(15)
  final String? currentLevel;         // 현재 수준

  // 메타
  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime? updatedAt;

  @HiveField(18)
  final DateTime? approvedAt;

  @HiveField(19)
  final DateTime? rejectedAt;

  @HiveField(20)
  final String? rejectionReason;

  const Booking({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.lessonType,
    required this.status,
    this.scheduledDate,
    this.scheduledTime,
    this.durationMinutes = 60,
    this.regularDay,
    this.regularStartDate,
    this.regularWeeks,
    this.instrument,
    this.locationId,
    this.notes,
    this.lessonGoal,
    this.currentLevel,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);

  /// 체험 레슨인지
  bool get isTrial => lessonType == LessonType.trial;

  /// 정기 레슨인지
  bool get isRegular => lessonType == LessonType.regular;

  /// 1회 레슨인지
  bool get isOneTime => lessonType == LessonType.oneTime;

  /// 승인 대기 중인지
  bool get isPending => status == BookingStatus.pending;
}
```

---

## 필드 설명

### Booking

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `teacherId` | String | ✅ | 선생님 ID |
| `studentId` | String | ✅ | 학생 ID |
| `lessonType` | LessonType | ✅ | 레슨 유형 |
| `status` | BookingStatus | ✅ | 예약 상태 |
| `scheduledDate` | DateTime? | - | 예약 날짜 (체험/1회) |
| `scheduledTime` | String? | - | 예약 시간 |
| `durationMinutes` | int | ✅ | 레슨 시간 (기본 60분) |
| `regularDay` | String? | - | 정기 레슨 요일 |
| `regularStartDate` | DateTime? | - | 정기 레슨 시작일 |
| `regularWeeks` | int? | - | 정기 레슨 주 수 |
| `instrument` | String? | - | 악기 |
| `locationId` | String? | - | 장소 ID |
| `notes` | String? | - | 요청사항 |
| `lessonGoal` | String? | - | 레슨 목표 (체험) |
| `currentLevel` | String? | - | 현재 수준 (체험) |

---

## JSON 예시

### 체험 레슨 예약

```json
{
  "id": "booking_001",
  "teacherId": "teacher_001",
  "studentId": "student_001",
  "lessonType": "trial",
  "status": "pending",
  "scheduledDate": "2026-02-01T00:00:00.000Z",
  "scheduledTime": "14:00",
  "durationMinutes": 60,
  "instrument": "바이올린",
  "lessonGoal": "바이올린 기초를 배우고 싶습니다",
  "currentLevel": "완전 초보",
  "createdAt": "2026-01-25T10:00:00.000Z"
}
```

### 정기 레슨 예약

```json
{
  "id": "booking_002",
  "teacherId": "teacher_001",
  "studentId": "student_002",
  "lessonType": "regular",
  "status": "approved",
  "regularDay": "화",
  "scheduledTime": "15:00",
  "regularStartDate": "2026-02-01T00:00:00.000Z",
  "regularWeeks": 12,
  "durationMinutes": 60,
  "instrument": "피아노",
  "locationId": "loc_001",
  "createdAt": "2026-01-20T10:00:00.000Z",
  "approvedAt": "2026-01-21T09:00:00.000Z"
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| TeacherStudentRelation | 90 |
| LessonType | 91 |
| BookingStatus | 92 |
| Booking | 93 |

---

## 관계별 가능한 레슨 유형

| 관계 | 체험 | 정기 | 1회 | 설명 |
|------|:----:|:----:|:----:|------|
| `none` | ✅ | ❌ | ❌ | 첫 만남은 체험부터 |
| `active` | ❌ | ❌ | ✅ | 이미 정기 진행중, 추가만 가능 |
| `inactive` | ❌ | ✅ | ✅ | 재개 또는 1회 가능 |

---

## 예약 상태 흐름

```
[신청 제출]
      │
      ▼
  pending (대기)
      │
      ├──[선생님 승인]──► approved (승인)
      │                       │
      │                       ├──[레슨 완료]──► completed
      │                       │
      │                       ├──[노쇼]──► noShow
      │                       │
      │                       └──[취소]──► cancelled
      │
      └──[선생님 거절]──► rejected (거절)
```

---

## 관련 엔티티

- [LessonClass](lesson_class.md) - 클래스
- [LessonLocation](lesson_location.md) - 레슨 장소
- [Subscription](subscription.md) - 수강권
- [Payment](payment.md) - 결제
