# TeacherAvailability 엔티티

> 작성일: 2026-01-24
> 최종 수정: 2026-01-27
> 상태: ✅ 구현 완료
> 구현 파일: `lib/features/schedule/domain/entities/teacher_availability.dart`
> 관련 스펙: [teacher_availability_spec.md](../../specs/schedule/teacher_availability_spec.md)

---

## 개요

선생님의 레슨 가능 시간을 관리하는 시스템.

```
TeacherAvailability (루트)
├── WeeklySchedule[] (주간 반복 스케줄)
└── TimeException[] (예외: 휴무, 휴가, 추가 오픈)
```

---

## Hive TypeId 할당

| TypeId | 엔티티 |
|:------:|--------|
| 70 | AvailabilityType |
| 71 | SlotStatus |
| 72 | TeacherAvailability |
| 73 | WeeklySchedule |
| 74 | ExceptionType |
| 75 | TimeException |
| 76 | AvailabilitySlot |

---

## TeacherAvailability (선생님 가용 설정)

```dart
@HiveType(typeId: 72)
@JsonSerializable()
class TeacherAvailability extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;

  /// Default lesson duration in minutes (30, 45, 60)
  @HiveField(2)
  final int slotDurationMinutes;

  /// Weekly recurring schedules
  @HiveField(3)
  final List<WeeklySchedule> weeklySchedules;

  /// Exceptions (holidays, special closures)
  @HiveField(4)
  final List<TimeException> exceptions;

  /// Number of weeks to auto-generate slots
  @HiveField(5)
  final int autoGenerateWeeks;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| id | String | 고유 식별자 | - |
| teacherId | String | 선생님 ID | - |
| slotDurationMinutes | int | 레슨 시간 단위 (분) | 60 |
| weeklySchedules | List | 주간 스케줄 목록 | [] |
| exceptions | List | 예외 목록 | [] |
| autoGenerateWeeks | int | 자동 생성 주 수 | 4 |
| createdAt | DateTime | 생성일 | - |
| updatedAt | DateTime? | 수정일 | null |

---

## WeeklySchedule (주간 스케줄)

```dart
@HiveType(typeId: 73)
@JsonSerializable()
class WeeklySchedule extends HiveObject {
  @HiveField(0)
  final String id;

  /// Day of week (0=Monday, 6=Sunday)
  @HiveField(1)
  final int dayOfWeek;

  /// Start time in "HH:mm" format (e.g., "14:00")
  @HiveField(2)
  final String startTime;

  /// End time in "HH:mm" format (e.g., "18:00")
  @HiveField(3)
  final String endTime;

  /// Whether this schedule is active
  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final DateTime createdAt;
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| id | String | 고유 식별자 | - |
| dayOfWeek | int | 요일 (0=월 ~ 6=일) | - |
| startTime | String | 시작 시간 ("HH:mm") | - |
| endTime | String | 종료 시간 ("HH:mm") | - |
| isActive | bool | 활성 여부 | true |
| createdAt | DateTime | 생성일 | - |

### 헬퍼 메서드

```dart
/// Get day name in Korean
String get dayName {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  return days[dayOfWeek];
}
```

---

## TimeException (시간 예외)

```dart
@HiveType(typeId: 75)
@JsonSerializable()
class TimeException extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExceptionType type;

  /// Start date of exception
  @HiveField(2)
  final DateTime startDate;

  /// End date (same as startDate for single day)
  @HiveField(3)
  final DateTime endDate;

  /// Optional specific time for additionalSlot type
  @HiveField(4)
  final String? startTime;

  @HiveField(5)
  final String? endTime;

  /// Reason for the exception
  @HiveField(6)
  final String? reason;

  @HiveField(7)
  final DateTime createdAt;
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| type | ExceptionType | 예외 유형 |
| startDate | DateTime | 시작일 |
| endDate | DateTime | 종료일 (단일 날짜면 startDate와 동일) |
| startTime | String? | 시작 시간 (추가 오픈용) |
| endTime | String? | 종료 시간 (추가 오픈용) |
| reason | String? | 사유 |
| createdAt | DateTime | 생성일 |

### 헬퍼 메서드

```dart
/// Check if a date falls within this exception
bool containsDate(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
  final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
  return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
}
```

---

## ExceptionType (예외 유형)

```dart
@HiveType(typeId: 74)
enum ExceptionType {
  @HiveField(0)
  holiday,          // 휴무 (단일 날짜)

  @HiveField(1)
  vacation,         // 휴가 (기간)

  @HiveField(2)
  additionalSlot,   // 추가 오픈 (일회성)
}
```

| 값 | 한글명 | 설명 | 예시 |
|------|--------|------|------|
| holiday | 휴무 | 단일 날짜 휴무 | 12/25 휴무 |
| vacation | 휴가 | 기간 휴무 | 1/1~1/3 연휴 |
| additionalSlot | 추가 오픈 | 임시 가용시간 추가 | 평소 불가 시간에 일회성 추가 |

### Extension

```dart
extension ExceptionTypeExtension on ExceptionType {
  String get displayName {
    switch (this) {
      case ExceptionType.holiday:
        return '휴무';
      case ExceptionType.vacation:
        return '휴가';
      case ExceptionType.additionalSlot:
        return '추가 오픈';
    }
  }
}
```

---

## AvailabilityType (가용 유형)

```dart
@HiveType(typeId: 70)
enum AvailabilityType {
  @HiveField(0)
  regular,    // 주간 반복

  @HiveField(1)
  oneTime,    // 일회성
}
```

---

## SlotStatus (슬롯 상태)

```dart
@HiveType(typeId: 71)
enum SlotStatus {
  @HiveField(0)
  available,  // 예약 가능

  @HiveField(1)
  booked,     // 예약됨

  @HiveField(2)
  cancelled,  // 취소됨 (휴무 등)
}
```

---

## 파일 위치

```
lib/features/schedule/
├── domain/
│   └── entities/
│       ├── teacher_availability.dart  # TeacherAvailability, WeeklySchedule, TimeException
│       └── availability_slot.dart     # AvailabilitySlot (계산된 슬롯)
└── data/
    └── repositories/
        └── mock_teacher_availability_repository.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [teacher_availability_spec.md](../../specs/schedule/teacher_availability_spec.md) | 가용 시간 시스템 스펙 |
| [availability_slot.md](./availability_slot.md) | 계산된 가용 슬롯 엔티티 |
| [subscription.md](./subscription.md) | 수강권 엔티티 |
