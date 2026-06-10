# 학생 선착순 직접 예약 스펙

> 작성일: 2026-06-06
> 도메인: schedule
> 상태: 스펙 작성 → 구현
> 관련 이슈: #580
> 관련 문서: [schedule_master.md §3](schedule_master.md), [teacher_availability_spec.md](teacher_availability_spec.md), [design/notebook/README.md](../design/notebook/README.md)

## 1. 문제 정의

선생님이 가용 시간을 설정(`teacher_availability_spec`)해도, **학생이 그 슬롯을 직접 골라 즉시 예약하는 화면이 없다.**

- 현재 슬롯-칩-예약 UX는 `BookingRescheduleScreen`(기존 예약 변경)에만 존재 — 라우트 미등록, MyBookings에서만 진입.
- `TeacherDetailScreen`의 "레슨 신청"은 `UnifiedLessonRequestScreen`(요청→선생님 승인, 구방식)으로만 연결.
- 결과: `schedule_master §3`의 "2단계 선착순 — 슬롯 등록 → 학생 예약 → 즉시 확정"이 학생 신규 예약 경로에서 끊겨 있음.

## 2. 목표

> **"빈 칸을 보고, 한 번 눌러, 바로 확정한다."** (schedule_master §3.2 — 최소 인지 부하)

선생님 가용 슬롯을 날짜별로 보여주고, 학생이 칩 하나를 탭 → 확인 → **즉시 확정**되는 단일 화면.

## 3. 범위

### 포함 (FE)
- 신규 `LessonBookingScreen` — 날짜 네비 + 가용 슬롯 칩 + 즉시 예약
- 라우트 `lessonDirectBooking` + 진입점 2곳 (선생님 상세 / 수강권 발급 완료)
- 빈 슬롯 시 다음 가용일 제안

### 제외 (후속)
- 수강권 잔여횟수 차감의 BE 권위 처리 (현 FE는 표시 + `bookSlot` 호출)
- 그룹 클래스 정원 예약 (1:1 = 정원 1 선착순만)
- 게스트(비회원) 예약 — 본 화면은 로그인 학생 전용

## 4. 사용자 플로우

```
선생님 상세 / 수강권 발급 완료
        │  [레슨 예약하기]
        ▼
┌─────────────────────────────────────┐
│  ← 레슨 예약            (선생님 이름) │   ← NotebookDetailAppBar
├─────────────────────────────────────┤
│  ‹  6/10 (화)  ›        [달력]        │   ← AvailabilityDateNavigator
├─────────────────────────────────────┤
│  오전                                │   ← 시스템 라벨 (산세리프)
│  ┌──────┐ ┌──────┐                   │
│  │10:00 │ │11:00 │                   │   ← 가용 슬롯 칩 (선택 시 Vermillion)
│  └──────┘ └──────┘                   │
│  오후                                │
│  ┌──────┐ ┌──────┐ ┌──────┐          │
│  │14:00 │ │15:00 │ │16:00 │          │
│  └──────┘ └──────┘ └──────┘          │
├─────────────────────────────────────┤
│  선생님 · 50분 · 잔여 3회             │   ← 미리보기 (시스템 데이터, 산세리프)
│  ┌─────────────────────────────────┐ │
│  │           예약하기              │ │   ← paperAccent 액션
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
        │  탭
        ▼
   확인 다이얼로그 (NotebookAlertDialog)
   "6/10(화) 15:00 레슨을 예약할까요?"
        │  확인
        ▼
   bookSlot() → 즉시 확정 → 성공 → MyBookings 이동
```

### 빈 슬롯
선택 날짜에 가용 슬롯 0개 → `EmptySlotsSuggestion`로 다음 가용일 제안(`nextAvailableDatesProvider`).

## 5. 인터랙션 규칙

| 항목 | 규칙 |
|------|------|
| 슬롯 선택 | 단일 선택. 탭 시 칩 강조(Vermillion 채움), 하단 [예약하기] 활성화 |
| 예약 버튼 | 슬롯 미선택 시 비활성. 선택 시 활성 |
| 확정 | 확인 다이얼로그 1회 → `bookSlot()` 즉시 확정 (승인 불필요) |
| 중복 방지 | `availableSlotsForDateProvider`가 `available` 상태만 반환. 점유된 슬롯은 목록에서 제외 |
| 동시성 | `bookSlot` 실패(이미 점유) 시 에러 스낵바 + 목록 invalidate(새로고침) |
| 최소 예약 시간 | `minBookingHours`(기본 24h) 이내 슬롯은 provider가 제외(기존 로직 재사용) |
| 성공 후 | 성공 스낵바 + `MyBookingsScreen`(또는 확정 화면)으로 이동 |

## 6. 데이터 계약

### 입력 (라우트 extra)
```dart
LessonBookingParams {
  String teacherId;
  String teacherName;
  String studentId;
  String studentName;
  String instrument;
  String? subscriptionId;   // 수강권 발급 직후 진입 시
}
```

### 조회
- 날짜별 가용 슬롯: `availableSlotsForDateProvider(teacherId, date, currentStudentId)` → `List<AvailabilitySlot>` (status=available)
- 다음 가용일: `nextAvailableDatesProvider(teacherId, fromDate, limit)`

### 예약 실행
`slotBookingNotifierProvider.bookSlot(slotId, studentId, studentName, teacherId, teacherName, slotDate, slotStartTime, slotEndTime, instrument, lessonType, fee)` → `LessonBooking` (즉시 확정).
- 에러는 `AsyncValue.error`로 삼켜지므로 `ref.read(slotBookingNotifierProvider).hasError` 확인 필수.

## 7. Notebook × 악보 디자인 적용

> 출처: [design/notebook/README.md](../design/notebook/README.md) §7.130 Gaegu 이항 룰.

| 요소 | 처리 |
|------|------|
| 스캐폴드 | `NotebookScreenScaffold` + `NotebookDetailAppBar(title: 레슨 예약)` |
| 슬롯 칩 (선택) | `paperAccent`(#9B1B12) 채움 + 흰 텍스트 |
| 슬롯 칩 (비선택) | `paperDark` 배경 + `inkQuaternary` 보더, 직각(`RoundedRectangleBorder`) |
| 슬롯 시간 텍스트 | **시스템 데이터 → 산세리프(`AppTypography`)** (자필 아님) |
| 오전/오후 구분 라벨 | 시스템 라벨 → 산세리프 |
| 미리보기 (선생님·시간·잔여) | 시스템 데이터 → 산세리프 |
| 예약하기 버튼 | `paperAccent` FilledButton, `minimumSize(0, buttonHeight)` |
| 날짜 네비 | 기존 `AvailabilityDateNavigator` 재사용 |
| 빈 상태 | `EmptySlotsSuggestion` 재사용 |
| 아이콘 | navigation/utility(chevron 등)는 Material 허용 (§9 A2) |
| 색상 | `AppColors`만 — `Color(0x...)` 금지 |
| 문구 | `AppStrings` 상수만 — 하드코딩 금지 |

## 8. 진입점

| 진입 | 위치 | 비고 |
|------|------|------|
| 선생님 상세 | `TeacherDetailScreen` 하단 CTA | 기존 "레슨 신청"과 별개 또는 통합 — 수강권 보유 시 직접 예약 우선 |
| 수강권 발급 완료 | `ProposalDetailScreen` 의 `ProposalStatus.confirmed` 상태 하단 액션바 | audit C2-F02. `ProposalIssuedActionBar` 가 "내 수강권 보고 첫 레슨 잡기" CTA 노출 → `/subscriptions/:id` (SubscriptionDetail) 로 이동. 거기서 학생이 선생님과 일정 협의 |
| (옵션) 학생 GettingStarted Step3 | 첫 레슨 예약 퀘스트 | subscription 보유 학생 한정 |

라우트: `AppRoutes.lessonDirectBooking = '/schedule/booking/direct'`, extra=`LessonBookingParams`.

## 9. 성공 기준

- [ ] 학생이 선생님 상세에서 [레슨 예약하기] → 슬롯 화면 진입
- [ ] 날짜 네비로 가용일 이동, 슬롯 칩 표시 (오전/오후 구분)
- [ ] 슬롯 탭 → 강조 → [예약하기] 활성
- [ ] 확인 다이얼로그 → `bookSlot` 즉시 확정 → 성공 스낵바 → MyBookings 이동
- [ ] 가용 슬롯 0개 → 다음 가용일 제안
- [ ] 동시 예약(점유) 실패 시 에러 스낵바 + 목록 새로고침
- [ ] Notebook 디자인 계약 통과 (scaffold/색상/타이포)
- [ ] widget smoke test 통과

## 10. 관련 파일

| 파일 | 역할 |
|------|------|
| `presentation/screens/lesson_booking_screen.dart` | 신규 — 직접 예약 화면 |
| `presentation/widgets/availability/availability_date_navigator.dart` | 재사용 — 날짜 네비 |
| `presentation/widgets/availability/empty_slots_suggestion.dart` | 재사용 — 빈 슬롯 제안 |
| `presentation/providers/teacher_availability_providers.dart` | 조회/예약 provider |
| `core/router/routes/schedule_routes.dart` | 라우트 등록 |
| `features/subscription/presentation/widgets/proposal_issued_action_bar.dart` | audit C2-F02 — 발급 완료 CTA (진입점 §8) |
| `features/subscription/presentation/screens/proposal_detail_screen.dart` | `_buildIssuedActionBar` 가 confirmed 상태에서 위 위젯 렌더 |
| `features/search/.../teacher_detail_screen.dart` | 진입 CTA |
