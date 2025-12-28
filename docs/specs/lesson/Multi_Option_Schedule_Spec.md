# 다중 옵션 스케줄 제안 시스템 스펙

> 작성일: 2025-12-29

## 개요

학생이 레슨 신청 시 1~3개의 일정 옵션을 제안하고, 선생님이 그 중 하나를 선택하여 확정하는 시스템.
기존 단일 선택 → 거절 → 재신청 왕복을 줄여 스케줄 조정 효율성을 크게 향상.

---

## 배경

### 기존 시스템의 문제점

```
[기존 플로우 - 평균 2-3회 왕복]
학생: 12/30 14시 신청
  → 선생님: 거절 (다른 학생 예약됨)
  → 학생: 12/31 15시 재신청
  → 선생님: 거절 (개인 일정)
  → 학생: 1/2 16시 재신청
  → 선생님: 승인
```

### 개선된 시스템

```
[개선 플로우 - 1회로 완료]
학생: 1순위 12/30 14시, 2순위 12/31 15시, 3순위 1/2 16시
  → 선생님: 3순위 선택 (1/2 16시 확정)
```

---

## 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 적용 범위 | 모든 레슨 유형 (체험, 1회, 정규) |
| 옵션 개수 | 최소 1개, 최대 3개 |
| 우선순위 | 1순위, 2순위, 3순위 표시 |
| 정규레슨 | 요일+시간 조합으로 3개 제안 |
| 주2회 레슨 | 조합으로 3개 제안 (화+목, 수+토, 화+토) |
| 승인 UI | 카드 선택형 (탭하여 선택) |
| 전체 거절 시 | 메시지로 조율 |
| 수정 가능 | 승인 전까지 자유롭게 수정 |
| 리마인더 | 24시간 후 선생님에게 알림 |
| 충돌 처리 | 예약된 시간 선택 불가 |
| 상태 표시 | 간단 3단계 (대기중→확정/거절) |

---

## 레슨 유형별 적용

### 1. 체험레슨 / 1회 레슨

**학생 신청 화면:**
```
┌─────────────────────────────────────────┐
│  희망 일정 선택 (최대 3개)               │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⭐ 1순위                         │   │
│  │ 12월 30일 (월) 14:00-15:00      │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 2순위                            │   │
│  │ 12월 31일 (화) 15:00-16:00      │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐   │
│  │ + 3순위 추가 (선택)              │   │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   │
│                                         │
│  💡 여러 일정을 제안하면 빠르게          │
│     확정될 확률이 높아요                 │
│                                         │
└─────────────────────────────────────────┘
```

**선생님 승인 화면:**
```
┌─────────────────────────────────────────┐
│  체험레슨 신청                           │
│  김민수 학생                             │
├─────────────────────────────────────────┤
│                                         │
│  희망 일정 중 하나를 선택해주세요         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⭐ 1순위 (학생 최우선)           │   │
│  │ 12월 30일 (월) 14:00-15:00      │   │
│  │                        [선택] ○ │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 2순위                            │   │
│  │ 12월 31일 (화) 15:00-16:00      │   │
│  │                        [선택] ● │   │  ← 선택됨
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 3순위                            │   │
│  │ 1월 2일 (목) 16:00-17:00        │   │
│  │                        [선택] ○ │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌──────────────┐ ┌──────────────┐    │
│  │    거절하기   │ │   승인하기    │    │
│  └──────────────┘ └──────────────┘    │
│                                         │
│  ⚠️ 모든 일정이 불가능하면 거절 후       │
│     메시지로 대안을 제안해주세요          │
│                                         │
└─────────────────────────────────────────┘
```

### 2. 정규레슨 (주 1회)

**학생 신청 화면:**
```
┌─────────────────────────────────────────┐
│  정규레슨 희망 일정 (최대 3개)           │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⭐ 1순위                         │   │
│  │ 매주 화요일 16:00-17:00         │   │
│  │ 시작일: 1월 7일                  │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 2순위                            │   │
│  │ 매주 목요일 15:00-16:00         │   │
│  │ 시작일: 1월 9일                  │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐   │
│  │ + 3순위 추가 (선택)              │   │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   │
│                                         │
└─────────────────────────────────────────┘
```

### 3. 정규레슨 (주 2회)

**학생 신청 화면:**
```
┌─────────────────────────────────────────┐
│  정규레슨 희망 일정 (주 2회)             │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⭐ 1순위                         │   │
│  │ 화요일 16:00 + 목요일 16:00     │   │
│  │ 시작일: 1월 7일                  │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 2순위                            │   │
│  │ 수요일 15:00 + 토요일 10:00     │   │
│  │ 시작일: 1월 8일                  │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 3순위                            │   │
│  │ 화요일 17:00 + 토요일 11:00     │   │
│  │ 시작일: 1월 7일                  │   │
│  │                          [변경]  │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 상태 관리

### 신청 상태 (BookingStatus)

```dart
enum BookingStatus {
  pending,    // 대기중 - 선생님 응답 대기
  confirmed,  // 확정됨 - 선생님이 옵션 선택하여 승인
  rejected,   // 거절됨 - 선생님이 모든 옵션 거절
}
```

### 상태 흐름

```
┌─────────┐     선생님 선택      ┌──────────┐
│ 대기중   │ ─────────────────→ │  확정됨   │
│ pending │                     │ confirmed│
└────┬────┘                     └──────────┘
     │
     │ 전체 거절 + 메시지
     ↓
┌──────────┐
│  거절됨   │ → 메시지로 조율 → 학생 재신청
│ rejected │
└──────────┘
```

---

## 데이터 모델

### ScheduleOption (신규)

```dart
class ScheduleOption {
  final String id;
  final int priority;           // 1, 2, 3 (우선순위)
  final DateTime date;          // 희망 날짜 (체험/1회)
  final TimeOfDay startTime;    // 시작 시간
  final TimeOfDay endTime;      // 종료 시간

  // 정규레슨용
  final int? dayOfWeek;         // 요일 (1=월, 7=일)
  final DateTime? startDate;    // 시작일

  // 주2회용
  final int? secondDayOfWeek;   // 두번째 요일
  final TimeOfDay? secondStartTime;
  final TimeOfDay? secondEndTime;
}
```

### LessonBooking (수정)

```dart
class LessonBooking {
  final String id;
  final String teacherId;
  final String studentId;
  final LessonType type;
  final BookingStatus status;
  final DateTime createdAt;

  // 다중 옵션 (신규)
  final List<ScheduleOption> scheduleOptions;  // 1~3개 옵션
  final String? selectedOptionId;               // 선생님이 선택한 옵션 ID

  // 기존 필드 유지 (확정 후 사용)
  final DateTime? confirmedDate;
  final TimeOfDay? confirmedStartTime;
  final TimeOfDay? confirmedEndTime;

  // 메시지
  final String? studentMessage;
  final String? teacherMessage;

  // 리마인더
  final DateTime? reminderSentAt;
}
```

---

## 비즈니스 로직

### 1. 충돌 검사

```dart
/// 시간 슬롯 선택 시 이미 예약된 시간 필터링
List<TimeOfDay> getAvailableSlots({
  required String teacherId,
  required DateTime date,
  required int lessonDuration,
}) {
  // 1. 선생님 가용시간 조회
  // 2. 해당 날짜의 확정된 예약 조회
  // 3. 대기중인 다른 학생의 옵션도 조회 (옵션)
  // 4. 충돌 시간 제외하고 반환
}
```

### 2. 리마인더 발송

```dart
/// 24시간 후 미응답 시 리마인더
void scheduleReminder(LessonBooking booking) {
  final reminderTime = booking.createdAt.add(Duration(hours: 24));

  // 리마인더 시점에 아직 pending 상태면 알림 발송
  if (booking.status == BookingStatus.pending) {
    sendPushNotification(
      userId: booking.teacherId,
      title: '레슨 신청 대기중',
      body: '${booking.studentName}님의 레슨 신청이 대기중입니다',
    );
  }
}
```

### 3. 승인 처리

```dart
Future<void> approveBooking({
  required String bookingId,
  required String selectedOptionId,
}) async {
  final booking = await getBooking(bookingId);
  final selectedOption = booking.scheduleOptions
      .firstWhere((o) => o.id == selectedOptionId);

  // 1. 상태 업데이트
  await updateBooking(
    bookingId,
    status: BookingStatus.confirmed,
    selectedOptionId: selectedOptionId,
    confirmedDate: selectedOption.date,
    confirmedStartTime: selectedOption.startTime,
    confirmedEndTime: selectedOption.endTime,
  );

  // 2. 학생에게 알림
  sendPushNotification(
    userId: booking.studentId,
    title: '레슨 확정',
    body: '${formatDate(selectedOption.date)} 레슨이 확정되었습니다',
  );
}
```

### 4. 거절 처리

```dart
Future<void> rejectBooking({
  required String bookingId,
  required String teacherMessage,
}) async {
  // 1. 상태 업데이트
  await updateBooking(
    bookingId,
    status: BookingStatus.rejected,
    teacherMessage: teacherMessage,
  );

  // 2. 학생에게 알림 (메시지 포함)
  sendPushNotification(
    userId: booking.studentId,
    title: '일정 조율 필요',
    body: '선생님이 메시지를 보냈습니다',
  );
}
```

---

## 화면 변경 사항

### 변경 대상

| 화면 | 변경 내용 |
|------|----------|
| `TrialLessonRequestScreen` | 다중 옵션 선택 UI 추가 |
| `RegisterRegularLessonScreen` | 다중 옵션 선택 UI 추가 |
| `PendingBookingsScreen` | 카드 선택형 승인 UI |
| `BookingDetailScreen` | 선택된 옵션 표시, 수정 기능 |

### 신규 위젯

| 위젯 | 용도 |
|------|------|
| `ScheduleOptionCard` | 옵션 카드 (우선순위 표시) |
| `ScheduleOptionSelector` | 1~3개 옵션 선택 UI |
| `ScheduleOptionPicker` | 날짜/시간 선택 모달 |
| `TeacherApprovalCard` | 선생님용 옵션 선택 카드 |

---

## 마이그레이션 계획

### Phase 1: 데이터 모델 확장
1. `ScheduleOption` 모델 추가
2. `LessonBooking`에 `scheduleOptions`, `selectedOptionId` 필드 추가
3. 기존 데이터 호환성 유지 (단일 옵션 = 1개 옵션 리스트)

### Phase 2: UI 컴포넌트 개발
1. `ScheduleOptionCard` 위젯 구현
2. `ScheduleOptionSelector` 위젯 구현
3. `TeacherApprovalCard` 위젯 구현

### Phase 3: 화면 수정
1. `TrialLessonRequestScreen` 다중 옵션 적용
2. `RegisterRegularLessonScreen` 다중 옵션 적용
3. `PendingBookingsScreen` 승인 UI 수정

### Phase 4: 알림 시스템
1. 24시간 리마인더 로직 구현
2. 승인/거절 알림 연동

---

## 엣지 케이스

### 1. 옵션 충돌 발생 시

**시나리오**: 학생 A가 1순위로 12/30 14시 신청, 학생 B도 같은 시간 신청

**처리**:
- 먼저 신청한 학생의 옵션이 우선
- 나중에 신청하는 학생에게는 해당 시간 선택 불가
- 대기중인 다른 신청의 옵션과도 충돌 검사 (선택적)

### 2. 승인 전 옵션 수정 시

**시나리오**: 학생이 옵션 수정 중에 선생님이 승인 시도

**처리**:
- 낙관적 잠금 사용
- 수정 중이면 승인 실패 → 새로고침 후 재시도 안내

### 3. 정규레슨 주2회 조합

**시나리오**: 요일 조합별로 시간대가 다를 수 있음

**처리**:
- 각 조합별로 두 요일의 시간을 함께 저장
- 예: 1안(화16시+목16시), 2안(수15시+토10시)

---

## Q&A 기록

| 질문 | 답변 |
|------|------|
| 적용 범위 | 모든 레슨 유형 |
| 옵션 개수 | 최소 1개, 최대 3개 |
| 전체 거절 시 | 메시지로 조율 |
| 우선순위 표시 | 1순위, 2순위, 3순위 |
| 수정 가능 여부 | 승인 전까지 가능 |
| 주2회 레슨 | 조합으로 3개 제안 |
| 승인 UI | 카드 선택형 |
| 리마인더 | 24시간 후 알림 |
| 충돌 처리 | 예약된 시간 선택 불가 |
| 상태 표시 | 간단 3단계 |

---

## 참고

- 기존 예약 스펙: [Unified_Lesson_Booking_Spec.md](./Unified_Lesson_Booking_Spec.md)
- 레슨 스케줄 설계: [Lesson_Schedule_Design.md](./Lesson_Schedule_Design.md)
