# AvailabilitySlot 엔티티

> 작성일: 2026-01-27
> 상태: ✅ 구현 완료
> 구현 파일: `lib/features/schedule/domain/entities/availability_slot.dart`
> 관련 스펙: [teacher_availability_spec.md](../../specs/schedule/teacher_availability_spec.md)

---

## 개요

UI에서 사용하는 계산된 가용 슬롯 모델.

**중요**: Hive에 저장되지 않고, `TeacherAvailability`로부터 동적으로 계산됨.

---

## AvailabilitySlot

```dart
/// Computed availability slot for UI display
///
/// This is a UI-focused model computed from TeacherAvailability.
/// Not persisted to Hive - computed on demand.
class AvailabilitySlot {
  final String id;
  final String teacherId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final AvailabilitySlotStatus status;

  /// Student ID if booked
  final String? bookedByStudentId;

  /// Student name if booked
  final String? bookedByStudentName;

  /// Lesson ID if linked
  final String? lessonId;

  /// Whether this is a recommended time (student's usual time)
  final bool isRecommended;
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 기본값 |
|------|------|------|--------|
| id | String | 고유 식별자 | - |
| teacherId | String | 선생님 ID | - |
| date | DateTime | 날짜 | - |
| startTime | TimeOfDay | 시작 시간 | - |
| endTime | TimeOfDay | 종료 시간 | - |
| durationMinutes | int | 레슨 시간 (분) | - |
| status | AvailabilitySlotStatus | 슬롯 상태 | available |
| bookedByStudentId | String? | 예약한 학생 ID | null |
| bookedByStudentName | String? | 예약한 학생 이름 | null |
| lessonId | String? | 연결된 레슨 ID | null |
| isRecommended | bool | 추천 여부 (평소 레슨 시간) | false |

---

## AvailabilitySlotStatus (슬롯 상태)

```dart
enum AvailabilitySlotStatus {
  /// Slot is available for booking
  available,

  /// Slot is booked by a student
  booked,

  /// Slot is booked by the current user
  myBooking,

  /// Slot is cancelled (holiday, etc.)
  cancelled,

  /// Slot has passed
  past,
}
```

| 값 | 설명 | UI 표시 |
|------|------|--------|
| available | 예약 가능 | 🟢 녹색 |
| booked | 타인 예약 | ⛔ 회색 |
| myBooking | 내 예약 | 🔵 파랑 |
| cancelled | 취소됨 (휴무) | ⛔ 회색 |
| past | 지난 시간 | ⛔ 회색 |

---

## 헬퍼 메서드/프로퍼티

### 시간 포맷팅

```dart
/// Get formatted start time string (e.g., "14:00")
String get formattedStartTime;

/// Get formatted end time string
String get formattedEndTime;

/// Get formatted date string (e.g., "2/18(화)")
String get formattedDate;
```

### 시간대 확인

```dart
/// Check if this slot is in the morning (before 12:00)
bool get isMorning => startTime.hour < 12;

/// Check if this slot is in the afternoon (12:00 or later)
bool get isAfternoon => startTime.hour >= 12;
```

### DateTime 변환

```dart
/// Get DateTime for the start of this slot
DateTime get startDateTime;

/// Get DateTime for the end of this slot
DateTime get endDateTime;
```

---

## 사용 예시

### 가용 슬롯 목록 조회

```dart
final slotsAsync = ref.watch(
  availableSlotsForDateProvider(
    teacherId: teacherId,
    date: selectedDate,
  ),
);
```

### 칩 선택기에서 사용

```dart
AvailabilityChipSelector(
  availableSlots: slots,
  selectedSlot: selectedSlot,
  onSlotSelected: (slot) => setState(() => selectedSlot = slot),
)
```

### 예약 미리보기에서 사용

```dart
AvailabilityBookingPreview(
  selectedSlot: slot,
  teacherName: '김선생님',
  instrument: '바이올린',
  remainingLessons: 5,
  totalLessons: 8,
  onBook: () => _handleBook(),
)
```

---

## 계산 로직

`AvailabilitySlot`은 다음 로직으로 계산됨:

1. **주간 스케줄 적용**: `WeeklySchedule`에서 해당 요일 시간대 추출
2. **예외 적용**: `TimeException`에서 휴무/추가 오픈 반영
3. **예약 상태 확인**: 기존 예약과 비교하여 상태 결정
4. **추천 표시**: 최근 3개월 레슨 이력에서 동일 시간대 확인

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [teacher_availability.md](./teacher_availability.md) | TeacherAvailability 엔티티 |
| [teacher_availability_spec.md](../../specs/schedule/teacher_availability_spec.md) | 가용 시간 시스템 스펙 |
