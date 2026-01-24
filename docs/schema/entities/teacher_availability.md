# TeacherAvailability 엔티티

> 작성일: 2026-01-24
> 상태: 📋 설계 완료 (미구현)
> 관련 스펙: [trial_lesson_system.md](../../specs/trial/trial_lesson_system.md#가용시간-관리-시스템-상세)

---

## 개요

선생님의 레슨 가능 시간을 관리하는 3계층 구조 시스템.

```
Layer 1: 주간 템플릿 (기본 스케줄)
    ↓
Layer 2: 예외 (오버라이드)
    ↓
Layer 3: 구글 캘린더 연동 (수동 블로킹)
```

---

## Hive TypeId 할당 (예정)

> ⚠️ 구현 시 할당 필요

| TypeId | 엔티티 |
|:------:|--------|
| TBD | TeacherAvailability |
| TBD | WeeklySchedule |
| TBD | TimeException |
| TBD | ExceptionType |
| TBD | GoogleCalendarSync |

---

## TeacherAvailability (선생님 가용시간)

```dart
/// 선생님 가용시간 설정
class TeacherAvailability {
  final String teacherId;
  final int slotDurationMinutes;        // 30, 45, 60 (개인별 설정)
  final List<WeeklySchedule> weeklySchedules;
  final List<TimeException> exceptions;
  final GoogleCalendarSync? googleSync;
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| teacherId | String | 선생님 ID |
| slotDurationMinutes | int | 슬롯 단위 (30/45/60분) |
| weeklySchedules | List | 주간 스케줄 목록 |
| exceptions | List | 예외 목록 |
| googleSync | GoogleCalendarSync? | 구글 캘린더 연동 |

---

## WeeklySchedule (주간 스케줄 - Layer 1)

```dart
/// 주간 스케줄 (Layer 1)
class WeeklySchedule {
  final int dayOfWeek;                  // 1(월) ~ 7(일)
  final bool isAvailable;               // 해당 요일 가용 여부
  final TimeOfDay? startTime;           // 시작 시간
  final TimeOfDay? endTime;             // 종료 시간
  final List<TimeRange> excludedRanges; // 제외 시간대 (점심 등)
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| dayOfWeek | int | 요일 (1=월 ~ 7=일) |
| isAvailable | bool | 해당 요일 레슨 가능 여부 |
| startTime | TimeOfDay? | 시작 시간 |
| endTime | TimeOfDay? | 종료 시간 |
| excludedRanges | List | 제외 시간대 (점심, 휴식) |

---

## TimeException (시간 예외 - Layer 2)

```dart
/// 시간 예외 (Layer 2)
class TimeException {
  final String id;
  final ExceptionType type;
  final DateTime? startDate;            // 시작일 (periodOff, temporaryAddition)
  final DateTime? endDate;              // 종료일 (시작일=종료일이면 하루)
  final int? dayOfWeek;                 // 요일 (recurringOff)
  final TimeRange? timeRange;           // 시간대 (timeBlocking, temporaryAddition)
  final String? reason;                 // 사유 (선택)
  final bool isAddition;                // true=추가, false=제외
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| type | ExceptionType | 예외 유형 |
| startDate | DateTime? | 시작일 |
| endDate | DateTime? | 종료일 |
| dayOfWeek | int? | 요일 (반복 휴무용) |
| timeRange | TimeRange? | 시간대 |
| reason | String? | 사유 |
| isAddition | bool | 추가/제외 여부 |

---

## ExceptionType (예외 유형)

```dart
/// 예외 유형
enum ExceptionType {
  periodOff,          // 기간 휴무 (하루~여러 날)
  timeBlocking,       // 특정 시간대 블로킹
  recurringOff,       // 반복 휴무 (매주 특정 요일)
  temporaryAddition,  // 임시 가용시간 추가
}
```

| 값 | 설명 | 예시 |
|------|------|------|
| periodOff | 기간 휴무 | 12/25 휴무, 1/1~1/3 연휴 |
| timeBlocking | 특정 시간대 블로킹 | 12/28 16:00-17:00 병원 |
| recurringOff | 반복 휴무 | 매주 수요일 불가 |
| temporaryAddition | 임시 가용시간 추가 | 평소 불가 시간에 일회성 추가 |

---

## GoogleCalendarSync (구글 캘린더 연동 - Layer 3)

```dart
/// 구글 캘린더 연동 (Layer 3)
class GoogleCalendarSync {
  final bool isConnected;
  final String? calendarId;
  final DateTime? lastSyncTime;
  final List<GoogleEvent> pendingEvents;  // 블로킹 대기 이벤트
  final List<GoogleEvent> blockedEvents;  // 블로킹 완료 이벤트
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| isConnected | bool | 연결 여부 |
| calendarId | String? | 캘린더 ID |
| lastSyncTime | DateTime? | 마지막 동기화 시간 |
| pendingEvents | List | 블로킹 대기 이벤트 |
| blockedEvents | List | 블로킹 완료 이벤트 |

---

## 충돌 로직 우선순위

```
1. 예외 (Layer 2) - 최우선
   - 휴무/블로킹 → 해당 시간 불가
   - 임시 가용 → 해당 시간 가능
2. 구글 블로킹 (Layer 3)
   - 블로킹된 이벤트 시간 불가
3. 주간 템플릿 (Layer 1)
   - 기본 가용 시간
```

---

## 파일 위치 (예정)

```
lib/features/schedule/domain/entities/teacher_availability.dart
lib/features/schedule/domain/entities/weekly_schedule.dart
lib/features/schedule/domain/entities/time_exception.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [trial_lesson_system.md](../../specs/trial/trial_lesson_system.md) | 체험 레슨 시스템 스펙 |
| [lesson_schedule.md](../../specs/lesson/lesson_schedule.md) | 레슨 스케줄 시스템 |
