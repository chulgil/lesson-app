# 일정 변경 3계열 통합 스펙

> 상태: 승인됨 (2026-08-12 오너 결정 — §2.2 = **A-2** RequestDetailScreen canonical 승격, §2.3 = **C-1** 직접예약 현행 유지+중복 제거. 단 A-2 채택 시에도 무연계 수강권 폴백용 A-1 위젯 공유가 선행 단계로 유지된다는 §2.2 결론 그대로 적용)
> 작성일: 2026-08-12
> 성격: **통합 제안(proposal) 스펙** — 새 기능이 아니라 이미 배포된 3개 화면 계열의
> 구조 차이를 서술하고, 통합 방향을 제안한다. §2·§3 의 "결정 필요" 항목은 오너
> 승인 후에만 §4 마이그레이션에 착수한다.
> 근거 코드 스냅샷: `origin/main` `a34c542e`(2026-08-12) 기준. 병렬로 진행 중인
> 변경(§1.4 참고)이 있어 착수 시점에 파일:라인을 재확인해야 한다.
> 관련 스펙: [unified_lesson_request_spec.md](unified_lesson_request_spec.md)(§2~5,
> Phase1~4 라이프사이클 SSOT), [subscription_schedule_change_spec.md](subscription_schedule_change_spec.md),
> [subscription_schedule_management_spec.md](../subscription/subscription_schedule_management_spec.md),
> [student_direct_booking_spec.md](student_direct_booking_spec.md),
> [schedule_master.md](schedule_master.md), 용어: `.harness/knowledge/glossary.md` §3

---

## 1. 현황 — 학생이 "일정을 바꾼다"를 만나는 3가지 다른 길

같은 요청("이 레슨 시간을 바꾸고 싶다")이 **어느 화면에서 시작했는지에 따라** 완전히
다른 데이터 모델·UI 패턴·확정 방식을 탄다. 아래 표가 3계열의 현재 상태다.

| # | 계열 | 진입점 | 화면/컴포넌트 | 대상 엔티티 | 협상 스토어 | 슬롯 선택 컴포넌트 |
|---|------|--------|---------------|-------------|--------------|---------------------|
| A | 최초 신청 시간협의 (Phase 1) | 학생 레슨 신청 후 교사 미승인 구간 | `RequestDetailScreen` + `CurrentRequestBox` | `UnifiedLessonRequest` | `RequestEvent`(턴 기반, actor 기준) | `WeeklyCalendarPicker`(최초 3안) / `AlternativeTimeGrid`(역제안) |
| B | 수강권 회차 일정변경 (Phase 3) | 수강권 상세, 특정 회차 | `SubscriptionDetailScreen` + `SubscriptionBottomInputBar` | `UnifiedLessonRequest`(`_selectedSession`으로 회차 특정) | `RequestEvent`(A와 **동일 엔티티·동일 이벤트 타입**) | `AlternativeTimeGrid`(발의·역제안 모두) |
| C | 직접예약 변경/취소 | `MyBookings` 목록의 개별 예약 | `BookingRescheduleScreen` / `BookingCancelScreen` | `AvailabilitySlot`(→ `LessonBooking`) | 없음 — **협상이 아니라 단방향 즉시 확정** | 화면 전용 날짜-칩 리스트(그리드 아님) |

핵심 관찰: A 와 B 는 겉모습(진행바+챗+하단액션바)은 다르지만 **바닥의 데이터 모델은
이미 하나다** — 둘 다 `UnifiedLessonRequest`/`RequestEvent`를 쓰고, 이벤트 타입도
`scheduleChangeProposed`/`Accepted`/`Rejected`/`Countered`로 공유된다
(`unified_lesson_request_spec.md` §3.4, §5). 다른 것은 **화면 구현체와 그 안의
슬롯 선택 컴포넌트**뿐이다. 반면 C 는 데이터 모델 자체가 다르다 — `RequestEvent`를
전혀 만들지 않는 **단방향 즉시 확정** 시스템이다.

### 1.1 계열 A — 최초 시간협의 (`RequestDetailScreen`)

- 화면: `frontend/lib/features/schedule/presentation/screens/request_detail_screen.dart`(1229줄), 하단 액션은 `presentation/widgets/current_request_box.dart`(925줄, `_buildPhase1Request()` `current_request_box.dart:201`)가 담당.
- 턴 판정은 상태값이 아니라 **최근 `RequestEvent`의 actor**로 이뤄진다(`current_request_box.dart:148-166`, `unified_lesson_request_spec.md` §2.1 드리프트 관찰과 동일 근거).
- 최초 3안 제출(신청 폼)은 `WeeklyCalendarPicker`(`unified_lesson_request_screen.dart:498`) — 교사가 **선언한 가용시간**(`TeacherAvailability`) 위에 학생이 우선순위 1~3(❶❷❸)을 매기는 화면.
- 교사 역제안·학생 재역제안·"결정 변경"은 전부 `SuggestAlternativeScreen`(풀스크린 push)을 거친다 — 호출부 3곳: `_handleCounterPropose`(`request_detail_screen.dart:468-499`), `_handleWithdraw`(`request_detail_screen.dart:562-609` 부근), `decline_bottom_sheet.dart:177`. `SuggestAlternativeScreen`은 내부적으로 `AlternativeTimeGrid`를 렌더링한다(`suggest_alternative_screen.dart:242`, `weekLessonsWithPreviewProvider`로 **실제 예약된 레슨**을 조회해 충돌을 보여줌).

### 1.2 계열 B — 수강권 회차 일정변경 (`SubscriptionDetailScreen`)

- 화면: `frontend/lib/features/subscription/presentation/screens/subscription_detail_screen.dart`(1028줄) + `presentation/widgets/subscription_bottom_input_bar.dart`(597줄, 4-상태: Default/Waiting/CanRespond/CancellationConfirmed — `subscription_bottom_input_bar.dart:32-140`).
- 회차 특정은 `_selectedSession` 필드로 이뤄지며, 같은 `UnifiedLessonRequest`(`subscription.id`가 `requestId`로 재사용됨, `subscription_detail_screen.dart:608`)에 회차 번호가 실려 나간다.
- **발의(최초 제안)는 이미 바텀시트로 통일돼 있다**: `_handleScheduleChange()`(`subscription_detail_screen.dart:736-754`)가 `showScheduleChangeTypeBottomSheet` → `showScheduleChangeSlotBottomSheet`를 호출한다. 이 바텀시트는 코드 주석에 "P0-1 Phase B(b) — 부모가 BottomSheet 흐름이므로 sheet 로 통일"이라고 명시돼 있고(`schedule_change_slot_bottom_sheet.dart:43-46`), 내부적으로 `AlternativeTimeGrid`를 재사용한다(`schedule_change_slot_bottom_sheet.dart:18,62`, `weekLessonsWithPreviewProvider`로 동일하게 실제 충돌 조회).
- **역제안·"결정 변경"은 아직 풀스크린이다**: `_handleCompareSchedule()`(`subscription_detail_screen.dart:632-689`)와 `_handleWithdrawScheduleDecision()`(`:692-731`)이 여전히 `Navigator.push<SuggestAlternativeResult>(MaterialPageRoute(...SuggestAlternativeScreen...))`을 쓴다.
- **M-3 이후 — Waiting/CanRespond 는 조건부 in-place**: 위 4-상태 중 Waiting/CanRespond 는 더 이상 항상 `SubscriptionDetailScreen` 안에서 진행되지 않는다. `lessonRequestIdBySubscriptionProvider` 역조회가 non-null(연계된 수강권)이면 `RequestDetailScreen` 으로 라우팅해 그 화면이 협상을 이어받고(§2.2 A-2), null(갱신·교사 직접 제안 등 무연계)일 때만 이 화면의 `SubscriptionBottomInputBar`(A-1 공유 위젯 경유)가 in-place 로 계속 처리한다. Default·CancellationConfirmed 두 상태는 연계 여부와 무관하게 항상 이 화면 소관이다.

### 1.3 계열 C — 직접예약 변경/취소 (`MyBookings`)

- 목록: `my_bookings_screen.dart`(529줄). 표시 항목은 `AvailabilitySlot`(status=booked, `availableSlotsForDateRangeProvider`), 대상 수강권은 `activeSubscriptionBetweenProvider`로 특정(`my_bookings_screen.dart:60-73`) — `UnifiedLessonRequest`나 `RequestEvent`는 이 화면 어디에도 등장하지 않는다.
- 변경: `BookingRescheduleScreen`(730줄)이 새 슬롯 예약(`bookSlotSimple`) → 구 예약 취소(`cancelBooking`) → 실패 시 롤백을 **즉시** 수행한다(`booking_reschedule_screen.dart:600-663`). 상대방(교사) 승인 단계가 없다 — `student_direct_booking_spec.md`가 정의한 "선착순 즉시 확정" 철학이 예약 생성뿐 아니라 예약 **변경**에도 그대로 적용된 결과다.
- 슬롯 선택 UI는 그리드가 아니라 `AvailabilityDateNavigator`(날짜 네비) + 화면 전용 칩 리스트다: `BookingRescheduleScreen._buildSlotChips()`(`booking_reschedule_screen.dart:309`)와 `LessonBookingScreen._buildSlots()`/`_SlotChips`(`lesson_booking_screen.dart:115,395`)는 **거의 동일한 UI를 각자 재구현**했다 — 둘 다 같은 `availableSlotsForDateProvider`를 쓰지만 위젯은 공유하지 않는다.
- 취소: `BookingCancelScreen`(757줄)도 동일하게 `cancelBooking()`(`booking_cancel_screen.dart:573`) 단방향 확정. `RequestEvent` 미사용.
- 변경/취소권(잔여 횟수) 자체는 A/B/C 전체가 이미 하나의 SSOT를 공유한다 — `reschedule_credit_spec.md`의 `remainingReschedule`은 A/B의 `scheduleChangeProposed`(마감 후)와 C의 `useReschedule()`(`booking_reschedule_screen.dart:638-643`)가 같은 카운터를 차감한다. **차감 규칙은 이미 통일돼 있고, UI/데이터 모델만 갈라져 있다.**

### 1.4 선행 변경 사항과 진행 중인 변경 (착수 전 재확인 대상)

- **역조회 연결 (2026-08-12 병합, `a34c542e`)**: `subscriptionId → lessonRequestId` 역조회가 `lessonRequestIdBySubscriptionProvider`(`schedule_confirmation_card_providers.dart:49`)로 이미 존재한다. `ScheduleConfirmationCard.lessonRequestId`가 원천이며, 홈 화면의 두 응답 카드(교사 `ScheduleChangeRequestSection`, 학생 `studentLessonProgressProvider`)가 이미 이 역조회로 원 요청 스레드(계열 A/B의 `RequestDetailScreen`)로 라우팅한다. 카드가 없는 무연계 수강권(갱신·교사 직접 제안)은 `null`을 반환하고 `subscriptionDetail` 폴백을 유지한다 — 이 폴백 정책은 §4 마이그레이션에서도 그대로 존속한다.
- **P0-1 (계열 B 발의만 바텀시트화, 이미 병합)**: §1.2 참조. 역제안/철회는 아직 미반영.
- **진행 중 (이 스펙 작성과 동시에 다른 에이전트가 작업)**: 계열 A/B의 역제안·철회 풀스크린 push(`SuggestAlternativeScreen`)를 바텀시트로 옮기는 작업이 별도로 진행 중이다. 이 스펙의 §3·§4는 그 작업이 이미 끝났다는 전제로 설계하지 않는다 — 착수 시점에 `rg "SuggestAlternativeScreen\("` 재실행으로 실제 호출부를 다시 확인해야 한다.

---

## 2. 목표 상태 제안 — "일정을 바꾼다" 단일 문법

### 2.1 사용자 정신모델

사용자에게는 "레슨 시간을 바꾼다"가 하나의 동사다. 그런데 지금은 **어느 화면에서
시작했는지**가 그 동사의 의미를 바꾼다 — A/B는 "상대에게 제안하고 기다린다"이고,
C는 "내가 정하면 끝난다". 이 차이 자체는 사용자에게 숨길 수 없는 실제 정책
차이(승인 필요 vs 선착순 즉시 확정, `schedule_master.md` §3)이므로 **완전히
하나의 화면으로 합치는 것이 목표가 아니다.** 목표는 다음 2가지로 좁힌다.

1. **엔티티가 이미 같은 A/B는 화면 구현도 하나로 합친다.** 같은 `UnifiedLessonRequest`/`RequestEvent`, 같은 이벤트 타입을 쓰면서 `RequestDetailScreen`과 `SubscriptionDetailScreen`이 각자 하단 액션바·역제안 진입 경로를 따로 구현할 이유가 없다.
2. **C는 A/B와 다른 정책이라는 것을 화면이 아니라 코드 중복으로 표현하지 않는다.** 지금 C가 A/B와 다른 이유는 "정책이 달라서"가 아니라 "따로 만들어져서" 발생한 중복(§1.3의 슬롯 칩 2벌)도 섞여 있다 — 정책 차이와 구현 중복을 분리한다.

### 2.2 결정 필요 1 — A/B 화면 통합 범위

두 옵션 모두 §1의 "엔티티는 이미 하나"라는 전제를 공유한다. 차이는 **어디까지
화면을 합치는가**다.

**옵션 A-1: 하단 액션바 위젯만 공유, 화면은 유지**
`CurrentRequestBox`(A)와 `SubscriptionBottomInputBar`(B)를 하나의 위젯으로
합치고(`ScheduleChangeActionBar` 가칭), `RequestDetailScreen`과
`SubscriptionDetailScreen`은 각자 화면으로 남아 이 위젯에 `RequestEvent` 목록과
콜백만 주입한다.
- 장점: 리스크가 작다 — 화면 골격(AppBar, 진행바, 상단 요약)은 두 도메인이 실제로 다르므로(레슨 요청 전체 vs 수강권 상세) 억지로 합칠 필요가 없다. 이미 `detail_screen_template.md`가 공통 패턴(프로그레스바+챗+하단액션바)을 강제하고 있어 이 옵션이 그 계약과 가장 잘 맞는다.
- 단점: 역제안 진입(`SuggestAlternativeScreen`/바텀시트 전환) 로직이 두 화면에 중복 구현된 상태(§1.4 진행 중 작업)가 완전히 없어지지는 않는다 — 액션바는 콜백을 위임할 뿐 네비게이션 소유자는 여전히 각 화면.

**옵션 A-2: `RequestDetailScreen` 을 canonical 화면으로 승격, `SubscriptionDetailScreen` 의 Phase 3 UI 는 그 화면으로 딥링크**
`SubscriptionDetailScreen`은 Ch.1/Ch.2(수강권 정보·결제)만 소유하고, 회차별 일정
변경 협상(Ch.3)은 `RequestDetailScreen`으로 이동해 처리한다 — §1.4의 역조회가
이미 `subscriptionId → lessonRequestId`를 제공하므로 기술적으로는 가능하다.
- 장점: 협상 로직·역제안 네비게이션이 물리적으로 한 곳에만 존재한다. §1.4의 역조회를 "링크 표시"가 아니라 "실제 라우팅 대상"으로 승격시키는 것이므로 이미 있는 인프라를 최대로 재사용한다.
- 단점: 사용자가 "수강권 상세"에서 회차를 탭했는데 다른 화면(레슨 요청 상세)으로 이동하는 것이 맥락 전환처럼 느껴질 수 있다. 갱신·교사 직접 제안처럼 `lessonRequestId`가 없는 무연계 수강권(§1.4)은 이 경로 자체가 성립하지 않아 옵션 A-1의 위젯 방식이 결국 필요 — 즉 이 옵션을 택해도 A-1이 폴백으로 남는다.

> **결정 필요**: 옵션 A-1(위젯 공유, 두 화면 유지) 또는 A-2(화면 자체를 canonical 로 승격). 무연계 수강권이 존재하는 한 A-1의 위젯 공유 작업은 어느 쪽을 택해도 선행돼야 하므로, §4 마이그레이션은 A-1을 1단계로 배치하고 A-2 여부는 그 이후에 결정해도 순서상 문제가 없다.

### 2.3 결정 필요 2 — 계열 C(MyBookings)의 위치

**옵션 C-1: 현행 유지, 중복만 제거**
`BookingRescheduleScreen`/`BookingCancelScreen`은 계속 `AvailabilitySlot` 기반
단방향 즉시 확정으로 남긴다. `LessonBookingScreen`과 `BookingRescheduleScreen`의
중복된 슬롯 칩 UI(§1.3, §3.4)만 하나의 공유 위젯으로 뽑는다.
- 장점: "선착순 즉시 확정"이라는 실제 제품 정책(`schedule_master.md` §3.2, "최소 인지 부하")을 유지한다. 협상 UI를 붙이면 오히려 이 정책과 모순된다 — 즉시 확정이 강점인 흐름에 "상대 응답 대기"를 넣는 것은 퇴행이다.
- 단점: A/B와 C가 데이터 모델 차원에서 계속 분리돼 있어, "이 예약이 어느 신청에서 시작됐는지" 같은 이력 추적이 C에서는 여전히 안 된다(§1.4 역조회가 `subscriptionId`는 있지만 C 화면에는 배선돼 있지 않음).

**옵션 C-2: C의 변경/취소 이력을 RequestEvent 로도 기록(협상 UI는 추가하지 않음)**
확정 자체는 여전히 즉시 이뤄지지만, 확정된 결과를 `scheduleChanged`(요약 이벤트,
`unified_lesson_request_spec.md` §3.3) 타입으로 원 요청 스레드에도 1건 기록한다.
- 장점: 사용자가 나중에 "레슨 요청" 히스토리를 봤을 때 직접예약으로 바뀐 일정도 타임라인에 보인다. §1.4 역조회를 C에도 연결하면 기술적으로 큰 추가 작업 없이 가능하다(이미 존재하는 `lessonRequestIdBySubscriptionProvider`를 C 화면에서도 호출하면 됨).
- 단점: "협상 없는 즉시 확정"과 "협상 스토어에 이벤트 기록"을 섞는 것이 코드 읽는 사람에게 혼란을 줄 수 있다 — 왜 어떤 `scheduleChanged` 이벤트는 앞에 `Proposed`/`Accepted` 짝이 있고 어떤 것은 없는지 문서화가 추가로 필요하다.

> **결정 필요**: C-1(정책 그대로, 중복만 제거 — 리스크 낮음) 또는 C-2(이력만 통합 — 추적성 향상, 설계 복잡도 소폭 증가). 이 스펙은 C-1을 기본값으로 추천한다 — "즉시 확정"이라는 제품 결정을 스펙이 임의로 뒤집지 않기 위해서다. C-2는 사용자 리서치(직접예약 이력 조회 니즈)가 확인되면 별도 스펙으로 승격.

---

## 3. 슬롯 선택 통일

### 3.1 현재는 "2개"가 아니라 "4개"다

브리핑 시점에는 슬롯 선택이 `WeeklyCalendarPicker`(초기 신청) vs
`AlternativeTimeGrid`(재제안·일정변경) 2개로 알려져 있었으나, 코드를 전수
확인한 결과 **실제로는 4개의 구현체**가 있다.

| 컴포넌트 | 파일 | 사용처 | UI 형태 | 데이터 소스 | 출력 타입 |
|---|---|---|---|---|---|
| `WeeklyCalendarPicker` | `weekly_calendar_picker.dart`(571줄) | 계열 A 최초 신청(`unified_lesson_request_screen.dart:498`) | 주간 그리드 + 우선순위 1~3 | `TeacherAvailability`(교사가 **선언한** 가용시간) | `PreferredTimeSlot`(0-idx dayOfWeek, `priority` 필드 포함) |
| `AlternativeTimeGrid` | `alternative_time_grid.dart`(582줄) | 계열 A 역제안(`SuggestAlternativeScreen` 내부), 계열 B 발의+역제안(`ScheduleChangeSlotBottomSheet` 내부) | 주간 그리드, 빈 셀 탭 | `List<Lesson>`(`weekLessonsWithPreviewProvider`, **실제 예약된 레슨**) | `TimeSlot`(1-idx dayOfWeek, `priority` 없음, 순서=리스트 인덱스) |
| `LessonBookingScreen._SlotChips` | `lesson_booking_screen.dart:395` | 계열 C 신규 직접예약 | 날짜 네비 + 당일 시간 칩 리스트 | `availableSlotsForDateProvider`(이미 계산된 가용 슬롯) | `AvailabilitySlot` 단일 선택 |
| `BookingRescheduleScreen._buildSlotChips` | `booking_reschedule_screen.dart:309` | 계열 C 예약 변경 | 날짜 네비 + 당일 시간 칩 리스트 (위와 동일 UI를 별도 구현) | 동일 `availableSlotsForDateProvider` | `AvailabilitySlot` 단일 선택 |

`AlternativeTimeGrid`는 이미 A(풀스크린)와 B(바텀시트)에서 재사용되고 있으므로
그리드 계열은 "재제안 그리드는 1개, 최초 신청 그리드는 1개"로 이미 절반쯤
정리돼 있다. **중복이 실제로 방치돼 있는 곳은 칩 리스트 계열(C)**이다 —
`LessonBookingScreen`과 `BookingRescheduleScreen`은 같은 provider를 호출하고
같은 모양의 UI를 각자 새로 작성했다.

### 3.2 그리드 계열(WeeklyCalendarPicker vs AlternativeTimeGrid) — 병합 가능성

두 그리드는 데이터 계약이 근본적으로 다르다.

- **데이터 소스가 다르다**: `WeeklyCalendarPicker`는 `TeacherAvailability`(교사가 설정에서 선언한 "이 시간대는 열려 있다")를 보여준다. 실제 예약과 충돌하는지는 별도로 걸러진 값을 받는다. `AlternativeTimeGrid`는 반대로 `List<Lesson>`(실제 예약)을 직접 그려서 "이 시간은 이미 차 있다"를 보여준다 — 가용성이 아니라 충돌을 보여주는 화면이다.
- **선택 결과 타입이 다르고, 변환에는 실제 버그 소지가 있는 인덱싱 불일치가 있다**: `PreferredTimeSlot.dayOfWeek`는 0=월요일, `TimeSlot.dayOfWeek`는 1=월요일이다. `request_detail_screen.dart:529`가 `dayOfWeek: s.dayOfWeek - 1`로 수동 변환하는 코드가 실제로 존재한다 — 두 타입은 오늘도 어댑터 없이는 호환되지 않는다.
- **선택 모델이 다르다**: `WeeklyCalendarPicker`는 `SlotSelectionLogic`(`slot_selection_logic.dart`)으로 최대 3개 슬롯에 명시적 순위(❶❷❸)를 매긴다. `AlternativeTimeGrid`는 순위 개념이 없다 — 선택 순서=리스트 append 순서일 뿐 우선순위로 노출되지 않는다.

**제안**: 완전한 컴포넌트 병합(단일 `ScheduleGrid`)은 추천하지 않는다 — 데이터
소스(선언된 가용성 vs 실제 충돌)와 선택 모델(순위 있음 vs 없음)이 실제 다른
사용자 시나리오를 반영하므로, 하나로 합치면 두 시나리오 중 하나가 불필요한
분기를 떠안는다. 대신 **"2 컴포넌트, 1 인터랙션 문법"** 계약으로 명문화한다.

| 항목 | 공통 규칙 |
|---|---|
| 탭 동작 | 빈 셀 탭 = 슬롯 추가/제거 토글. 두 컴포넌트 모두 이미 이 규칙을 따른다 |
| 최대 개수 | 3개 고정 (`maxSlots`, 두 컴포넌트 모두 기본값 3) |
| 우선순위 표기 | **`WeeklyCalendarPicker`만** 순위 라벨을 표시한다(§3.3에서 유니코드를 `AppStrings` 상수로 교체). `AlternativeTimeGrid`는 순위를 표시하지 않는 것이 의도된 차이 — 역제안은 "이 중 아무거나 골라달라"이지 "1지망/2지망"이 아니기 때문. 이 차이를 문서로 명문화해 향후 "왜 안 맞추냐"는 재작업 시도를 차단한다 |
| 색 의미 | 선택됨=`paperAccent`, 충돌/불가=회색조 — 두 컴포넌트가 이미 같은 `AppColors` 토큰을 쓰는지 §4 1단계에서 검증 |
| 출력 타입 경계 | `PreferredTimeSlot` ↔ `TimeSlot` 변환은 화면 코드에 흩어놓지 않고 단일 mapper 함수(`toTimeSlot()`/`fromTimeSlot()`)로 뽑는다 — dayOfWeek 인덱싱 변환 버그를 한 곳에서만 책임지게 한다 |

### 3.3 하드코딩 유니코드 — 수정 대상으로 확정

`weekly_calendar_picker.dart:487`:

```dart
String _priorityLabel(int priority) {
  const labels = ['', '❶', '❷', '❸'];
  return labels[priority.clamp(0, 3)];
}
```

원과 숫자 결합 유니코드 픽토그램(`❶❷❸`)이 `AppStrings` 경유 없이 하드코딩돼
있다 — `ux-rules.md`의 UI 이모지 금지 HARD-GATE(NotebookGlyph 예외 대상 아님,
이 위젯은 시그니처 영역이 아니라 일반 스케줄링 화면) 위반이다. §4 마이그레이션
1단계에서 `AppStrings`(또는 순위 표시를 텍스트 라벨 "1순위"/"2순위"로 대체)로
교체한다. 이 항목은 결정 필요 사항이 아니라 확정된 버그 픽스 — 이미
`subscription_schedule_management_spec.md` 안의 예시 텍스트("1순위 일
10:00~11:00")가 텍스트 라벨 방식을 쓰고 있어 대체안이 이미 존재한다.

### 3.4 칩 리스트 계열(C) — 즉시 병합 권장

`LessonBookingScreen._SlotChips`와 `BookingRescheduleScreen._buildSlotChips`는
같은 provider(`availableSlotsForDateProvider`), 같은 상위 위젯
(`AvailabilityDateNavigator`, `EmptySlotsSuggestion`)을 쓰면서 칩 렌더링만
독립적으로 작성돼 있다. 이 둘은 §3.2와 달리 **데이터 계약이 이미 동일**하므로
(`AvailabilitySlot` 단일 선택, 오전/오후 그룹핑) 병합에 결정이 필요한 트레이드오프가
없다 — `student_direct_booking_spec.md` §7이 이미 정의한 시각 계약(`paperAccent`
선택 칩, `paperDark`+`inkQuaternary` 비선택 칩)을 공유 위젯 `AvailabilitySlotChipList`
(가칭)로 추출해 두 화면이 재사용하도록 한다. §4 1단계에 포함.

---

## 4. 마이그레이션 순서

각 단계는 독립적으로 출시 가능해야 하고, 이전 단계의 회귀 여부를 테스트로
확인한 뒤에만 다음 단계로 진행한다. §1.4의 역조회 인프라를 전제로 순서를
잡았다.

| 단계 | 내용 | 선행 | 테스트 게이트 |
|---|---|---|---|
| **M-1** | §3.4 칩 리스트 위젯 통합(`LessonBookingScreen`↔`BookingRescheduleScreen`) + §3.3 유니코드 순위 라벨 `AppStrings` 교체 | 없음 — 리스크 최저, 결정 필요 항목과 무관 | 기존 `teacher_detail_direct_booking_entry_test.dart` 류 위젯 스모크 테스트 통과 + 두 화면 스크린샷 회귀(`frontend-verify.md`) |
| **M-2** | §2.3 결정 대기 중이어도 진행 가능: A/B의 역제안·철회 풀스크린→바텀시트 전환(§1.4 "진행 중" 작업과 조율, 중복 착수 금지) | M-1과 독립, 단 진행 중인 병렬 작업과 파일 충돌 여부 착수 직전 재확인 | 계열 A/B 각각의 회귀 테스트 + 바텀시트 전환 후 `flutter test test/architecture` |
| **M-3 (완료)** | §2.2 결정(A-1/A-2) 확정 후: 하단 액션바 위젯 공유(`ScheduleChangeActionBar`) — A-2 채택 시 화면 자체 라우팅 통합까지. **구현**: Part 1 — Waiting/CanRespond 두 상태를 `frontend/lib/features/schedule/presentation/widgets/schedule_change_action_bar.dart`의 `ScheduleChangeWaitingBar`/`ScheduleChangeResponseBar`로 추출(스케줄 feature facade 경유로 subscription feature 가 재사용). 호스트 고유 상태(Phase 2 결제·Phase 4 완료·terminal, 구독 Default·CancellationConfirmed)는 각 화면에 그대로 남음 — `ScheduleChangeResponseBar` 의 reject 버튼 유무로 계열 A(2버튼)/B(3버튼, N8) 레이아웃 차이를 표현. Part 2 — `SubscriptionDetailScreen` 이 회차별 Waiting/CanRespond 진입 시 `lessonRequestIdBySubscriptionProvider` 를 조회해, 연계된 수강권은 `RequestDetailScreen` 으로 라우팅(`highlightScheduleResponse` 의도 시 자동 전환, 그 외엔 CTA 탭)하고 무연계 수강권은 A-1 위젯 경로로 in-place 협상을 유지한다(데드엔드 없음). | M-2 완료(풀스크린 잔재가 없어야 위젯 공유 시 네비게이션 분기가 단순해짐), §2.2 결정 완료 | A/B 각 Phase 상태별(Default/Waiting/CanRespond/CancellationConfirmed) 스냅샷 테스트 — `test/features/schedule/widgets/schedule_change_action_bar_test.dart`(공유 위젯 6종) + `test/features/subscription/screens/subscription_detail_a2_routing_test.dart`(연계/무연계/Default/자동전환 4종) |
| **M-4** | §3.2 그리드 인터랙션 문법 계약을 코드 주석/architecture test로 고정(`PreferredTimeSlot`↔`TimeSlot` 단일 mapper 도입) | M-2 (두 그리드 호출부가 안정된 뒤 mapper 위치를 정하는 것이 안전) | `dayOfWeek` 인덱싱 회귀를 잡는 단위 테스트 신규 추가(§3.2에서 지적한 `-1` 변환 지점) |
| **M-5** | §2.3 결정(C-1/C-2) 확정 후 적용 — C-1이면 종료, C-2면 §1.4 역조회를 `MyBookings` 계열에도 배선 | M-1, §2.3 결정 완료 | C-2 채택 시: `scheduleChanged` 이벤트가 원 요청 스레드에 정확히 1건만 생성되는지 시나리오 테스트 |

각 단계는 `worktree-parallel-workflow.md`에 따라 별도 worktree에서 진행하고,
merge 전 `frontend-verify.md`의 2-뷰포트 스크린샷 회귀를 통과해야 한다.

---

## 5. 비범위 / 보류

- **정규권 5주차·보강 재계산 로직**: `subscription_schedule_change_spec.md`
  상단이 이미 별도 문서(`makeup_credit_spec.md`)로 분리해 뒀다 — 이 스펙은
  건드리지 않는다.
- **일정 변경 만료 정책(72h/24h/60h 배치)**: `unified_lesson_request_spec.md`
  §5.2, `subscription_schedule_change_spec.md` §8이 이미 SSOT — 계열 A/B
  통합과 무관하게 그대로 유지.
- **레슨 취소 흐름**: `lesson_cancellation_flow_spec.md`가 별도 스펙으로 분리돼
  있고, 일정 변경과 "본질적으로 다른 단방향 흐름"이라고 이미 명시돼 있다
  (`subscription_schedule_change_spec.md` §7). 계열 C의 `BookingCancelScreen`도
  이 스펙의 §2.3(C-1/C-2)과는 별개로 취소 자체의 정책 변경은 다루지 않는다.
- **그룹 클래스 정원 예약**: `student_direct_booking_spec.md` §3이 이미 제외.
  본 스펙도 1:1 레슨만 다룬다.
- **상대방 통지 갭(`scheduleChangeRejected` 전용 알림 타입 부재)**:
  `unified_lesson_request_spec.md` §5.3이 이미 "코드 주석상 잔여 갭"으로 기록—
  화면 통합과 독립적인 별도 이슈.
- **`RequestPhase` 상태 전이표의 드리프트(§2.1의 `canTransitionTo()` 미경유
  전이들)**: `unified_lesson_request_spec.md`가 이미 doc-sync repair로 기술
  완료. 본 스펙은 화면/컴포넌트 계층만 다루고 상태 머신 자체는 재설계하지
  않는다.
