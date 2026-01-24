# LessonSchedule 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [lesson_schedule.md](../../specs/lesson/lesson_schedule.md), [Lesson_Schedule_Design.md](../../specs/lesson/Lesson_Schedule_Design.md)

## 개요

레슨 스케줄 관리 시스템의 엔티티입니다. 선생님 가용시간, 정책 설정, 5주차 정책 등을 관리합니다.

---

## Dart 엔티티

### FifthWeekPolicy (5주차 정책)

```dart
// lib/features/schedule/domain/entities/fifth_week_policy.dart

import 'package:hive/hive.dart';

part 'fifth_week_policy.g.dart';

/// 5주차 정책 (월 4회 기준 정기레슨)
@HiveType(typeId: 94)
enum FifthWeekPolicy {
  @HiveField(0)
  skip,      // 5주차 자동 휴강 (기본값)

  @HiveField(1)
  optional,  // 학생 선택

  @HiveField(2)
  credit,    // 다음달 이월

  @HiveField(3)
  always,    // 항상 진행
}
```

### RegularLessonSettings (정규레슨 설정)

```dart
// lib/features/schedule/domain/entities/regular_lesson_settings.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'regular_lesson_settings.g.dart';

/// 정규레슨 설정
@HiveType(typeId: 95)
@JsonSerializable()
class RegularLessonSettings {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final int sessionsPerMonth;        // 월 레슨 횟수 (기본 4)

  @HiveField(3)
  final FifthWeekPolicy fifthWeekPolicy;  // 5주차 정책

  @HiveField(4)
  final String? customNotice;        // 선택적 안내 문구

  @HiveField(5)
  final int lessonDay;               // 레슨 요일 (1: 월 ~ 7: 일)

  @HiveField(6)
  final String lessonTime;           // 레슨 시간 (HH:mm)

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  const RegularLessonSettings({
    required this.id,
    required this.teacherId,
    this.sessionsPerMonth = 4,
    this.fifthWeekPolicy = FifthWeekPolicy.skip,
    this.customNotice,
    required this.lessonDay,
    required this.lessonTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory RegularLessonSettings.fromJson(Map<String, dynamic> json) =>
      _$RegularLessonSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$RegularLessonSettingsToJson(this);
}
```

### TeacherAvailability (선생님 가용시간)

```dart
// lib/features/schedule/domain/entities/teacher_availability.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_availability.g.dart';

/// 주간 가용시간 항목
@HiveType(typeId: 96)
@JsonSerializable()
class WeeklyTimeSlot {
  @HiveField(0)
  final int dayOfWeek;     // 0: 일, 1: 월, ... 6: 토

  @HiveField(1)
  final String startTime;  // HH:mm

  @HiveField(2)
  final String endTime;    // HH:mm

  @HiveField(3)
  final bool isActive;

  const WeeklyTimeSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory WeeklyTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$WeeklyTimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyTimeSlotToJson(this);
}

/// 날짜별 예외 유형
@HiveType(typeId: 97)
enum DateOverrideType {
  @HiveField(0)
  add,      // 추가 가용시간

  @HiveField(1)
  blocked,  // 휴무/불가
}

/// 날짜별 예외
@HiveType(typeId: 98)
@JsonSerializable()
class DateOverride {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final DateOverrideType type;

  @HiveField(2)
  final String? startTime;  // add인 경우

  @HiveField(3)
  final String? endTime;    // add인 경우

  const DateOverride({
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
  });

  factory DateOverride.fromJson(Map<String, dynamic> json) =>
      _$DateOverrideFromJson(json);

  Map<String, dynamic> toJson() => _$DateOverrideToJson(this);
}

/// 선생님 가용시간
@HiveType(typeId: 99)
@JsonSerializable()
class TeacherAvailability {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  @HiveField(2)
  final List<WeeklyTimeSlot> weeklyPattern;  // 주간 패턴

  @HiveField(3)
  final List<DateOverride> dateOverrides;    // 날짜별 예외

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  const TeacherAvailability({
    required this.id,
    required this.teacherId,
    required this.weeklyPattern,
    this.dateOverrides = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory TeacherAvailability.fromJson(Map<String, dynamic> json) =>
      _$TeacherAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherAvailabilityToJson(this);
}
```

### TeacherPolicy (선생님 정책)

```dart
// lib/features/schedule/domain/entities/teacher_policy.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_policy.g.dart';

/// 취소 패널티 유형
@HiveType(typeId: 100)
enum CancelPenaltyType {
  @HiveField(0)
  none,           // 패널티 없음

  @HiveField(1)
  deductOne,      // 1회 차감

  @HiveField(2)
  deductPercent,  // 비율 차감
}

/// 선생님 변경/취소 정책
@HiveType(typeId: 101)
@JsonSerializable()
class TeacherPolicy {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  // 변경 정책
  @HiveField(2)
  final int changeDeadlineHours;  // 변경 가능 기한 (기본 24시간)

  // 취소 정책
  @HiveField(3)
  final CancelPenaltyType cancelPenaltyType;

  @HiveField(4)
  final int? cancelPenaltyPercent;  // deductPercent인 경우

  // 당일 취소
  @HiveField(5)
  final bool sameDayCancelAllowed;

  @HiveField(6)
  final CancelPenaltyType? sameDayPenaltyType;

  // 학생에게 표시할 메시지
  @HiveField(7)
  final String? policyMessage;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  const TeacherPolicy({
    required this.id,
    required this.teacherId,
    this.changeDeadlineHours = 24,
    this.cancelPenaltyType = CancelPenaltyType.none,
    this.cancelPenaltyPercent,
    this.sameDayCancelAllowed = true,
    this.sameDayPenaltyType,
    this.policyMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory TeacherPolicy.fromJson(Map<String, dynamic> json) =>
      _$TeacherPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherPolicyToJson(this);
}
```

---

## 필드 설명

### FifthWeekPolicy

| 값 | 설명 | 결제 |
|----|------|------|
| `skip` | 5주차 자동 휴강 (기본값) | 4회 고정 |
| `optional` | 학생 선택 (진행/휴강) | 4회 + 선택시 추가 |
| `credit` | 진행 후 다음달 크레딧 적립 | 4회 고정, 크레딧 차감 |
| `always` | 5주차도 항상 진행 | 5회 결제 |

### DateOverrideType

| 값 | 설명 |
|----|------|
| `add` | 추가 가용시간 |
| `blocked` | 휴무/불가 |

### CancelPenaltyType

| 값 | 설명 |
|----|------|
| `none` | 패널티 없음 |
| `deductOne` | 1회 차감 |
| `deductPercent` | 비율 차감 |

---

## JSON 예시

### RegularLessonSettings

```json
{
  "id": "rls_001",
  "teacherId": "teacher_001",
  "sessionsPerMonth": 4,
  "fifthWeekPolicy": "skip",
  "customNotice": "5주차는 휴강입니다.",
  "lessonDay": 2,
  "lessonTime": "15:00",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

### TeacherAvailability

```json
{
  "id": "ta_001",
  "teacherId": "teacher_001",
  "weeklyPattern": [
    { "dayOfWeek": 1, "startTime": "14:00", "endTime": "18:00", "isActive": true },
    { "dayOfWeek": 3, "startTime": "14:00", "endTime": "18:00", "isActive": true },
    { "dayOfWeek": 6, "startTime": "10:00", "endTime": "16:00", "isActive": true }
  ],
  "dateOverrides": [
    { "date": "2026-01-25T00:00:00.000Z", "type": "blocked" },
    { "date": "2026-01-28T00:00:00.000Z", "type": "add", "startTime": "09:00", "endTime": "12:00" }
  ],
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

### TeacherPolicy

```json
{
  "id": "tp_001",
  "teacherId": "teacher_001",
  "changeDeadlineHours": 48,
  "cancelPenaltyType": "deductOne",
  "cancelPenaltyPercent": null,
  "sameDayCancelAllowed": true,
  "sameDayPenaltyType": "deductOne",
  "policyMessage": "48시간 전까지 변경/취소가 가능합니다. 당일 취소 시 1회가 차감됩니다.",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| FifthWeekPolicy | 94 |
| RegularLessonSettings | 95 |
| WeeklyTimeSlot | 96 |
| DateOverrideType | 97 |
| DateOverride | 98 |
| TeacherAvailability | 99 |
| CancelPenaltyType | 100 |
| TeacherPolicy | 101 |

---

## 관련 엔티티

- [Booking](booking.md) - 레슨 예약
- [Subscription](subscription.md) - 수강권
- [Payment](payment.md) - 결제
