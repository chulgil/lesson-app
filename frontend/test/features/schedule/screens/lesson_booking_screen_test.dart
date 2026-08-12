// #580 — LessonBookingScreen widget smoke + 핵심 인터랙션.
// #928 — 보강 크레딧 출처 selector 노출 + 선택값 캡처.
// ux-rules HARD-GATE: top-level 위젯 smoke test 필수.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/repositories/booking_repository.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/providers/booking_repository_provider.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/lesson_booking_screen.dart';
import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';
import 'package:lessonaza/features/subscription/presentation/providers/makeup_credit_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/makeup_credit_use_selector.dart';

class _StubRepo extends MockTeacherAvailabilityRepository {
  final List<AvailabilitySlot> slots;
  _StubRepo(this.slots);

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => slots;
}

/// #580 Gap B — real `MockTeacherAvailabilityRepository.bookSlot` parses the
/// slot id as `<teacherId>-<date>-<time>`; the plain-id fixtures in this file
/// (`_slot('a', 10)`) don't match that format, so tests that complete the
/// full confirm flow need a stub that skips the parser.
class _BookableStubRepo extends _StubRepo {
  _BookableStubRepo(super.slots);

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async => slots.first.copyWith(status: AvailabilitySlotStatus.myBooking);
}

/// #580 Gap B — captures subscriptionId reaching the repository boundary via
/// the real screen interaction (slot tap → confirm dialog → bookSlot).
class _CapturingBookingRepo implements BookingRepository {
  String? capturedSubscriptionId;

  @override
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    required int fee,
    String? subscriptionId,
  }) async {
    capturedSubscriptionId = subscriptionId;
    return LessonBooking(
      id: 'booking_test',
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: request.studentId,
      studentName: request.studentName,
      lessonType: LessonType.trial,
      status: BookingStatus.pending,
      lessonDate: request.effectiveDate,
      startTime: request.effectiveStartTime,
      endTime: request.effectiveEndTime,
      fee: fee,
      subscriptionId: subscriptionId,
      createdAt: DateTime(2026, 6, 10),
    );
  }

  @override
  Future<List<LessonBooking>> getAllBookings() async => const <LessonBooking>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AvailabilitySlot _slot(String id, int hour) => AvailabilitySlot(
  id: id,
  teacherId: 't1',
  date: DateTime(2026, 6, 10),
  startTime: ClockTime(hour: hour, minute: 0),
  endTime: ClockTime(hour: hour + 1, minute: 0),
  durationMinutes: 50,
  status: AvailabilitySlotStatus.available,
);

MakeupCredit _credit(String id) => MakeupCredit(
  id: id,
  studentId: 's1',
  teacherId: 't1',
  reason: MakeupCreditReason.teacherVacation,
  createdAt: DateTime(2026, 6, 1),
  expiresAt: DateTime(2026, 7, 1),
);

Widget _harness(_StubRepo repo, {List<MakeupCredit> credits = const []}) {
  return ProviderScope(
    overrides: [
      teacherAvailabilityRepositoryProvider.overrideWithValue(repo),
      // #928: decouple the booking screen from the makeup repo — drive the
      // spendable balance directly so selector exposure is deterministic.
      studentMakeupCreditBalanceProvider.overrideWith(
        (ref) async => MakeupCreditBalance(available: credits),
      ),
    ],
    child: const MaterialApp(
      home: LessonBookingScreen(
        params: LessonBookingParams(
          teacherId: 't1',
          teacherName: '김선생',
          studentId: 's1',
          studentName: '학생',
          instrument: '바이올린',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('가용 슬롯이 있으면 예외 없이 렌더하고 오전/오후 칩을 표시', (tester) async {
    await tester.pumpWidget(
      _harness(_StubRepo([_slot('a', 10), _slot('b', 14)])),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('10:00'), findsOneWidget); // 오전
    expect(find.text('14:00'), findsOneWidget); // 오후
  });

  testWidgets('슬롯 미선택 시 예약 바(예약하기)가 보이지 않음', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo([_slot('a', 10)])));
    await tester.pumpAndSettle();

    // 예약하기 버튼은 슬롯 선택 후에만 노출.
    expect(find.text('예약하기'), findsNothing);
  });

  testWidgets('슬롯 탭 → 예약하기 바 노출', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo([_slot('a', 10)])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('예약하기'), findsOneWidget);
  });

  testWidgets('가용 슬롯 0개여도 예외 없이 렌더 (빈 상태)', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo(const [])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // #928 — 보강 크레딧 출처 선택 UI.
  testWidgets('크레딧 보유 + 슬롯 선택 → 보강 크레딧 selector 노출', (tester) async {
    await tester.pumpWidget(
      _harness(
        _StubRepo([_slot('a', 10)]),
        credits: [_credit('c1'), _credit('c2')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MakeupCreditUseSelector), findsOneWidget);
  });

  testWidgets('크레딧 미보유 → selector 미노출 (정규 전용)', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo([_slot('a', 10)])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(find.byType(MakeupCreditUseSelector), findsNothing);
  });

  testWidgets('보강 크레딧 옵션 탭 → 선택값이 makeupCredit 으로 캡처됨', (tester) async {
    await tester.pumpWidget(
      _harness(_StubRepo([_slot('a', 10)]), credits: [_credit('c1')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    // 기본값은 정규 수강권.
    var selector = tester.widget<MakeupCreditUseSelector>(
      find.byType(MakeupCreditUseSelector),
    );
    expect(selector.selected, BookingPaymentSource.regularSubscription);

    await tester.tap(find.text('보강 크레딧 사용'));
    await tester.pumpAndSettle();

    selector = tester.widget<MakeupCreditUseSelector>(
      find.byType(MakeupCreditUseSelector),
    );
    expect(selector.selected, BookingPaymentSource.makeupCredit);
  });

  // #580 Gap B — student_direct_booking_spec.md §6.
  testWidgets('슬롯 선택 → 확인 → LessonBookingParams.subscriptionId 가 저장소까지 전달됨', (
    tester,
  ) async {
    final bookingRepo = _CapturingBookingRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _BookableStubRepo([_slot('a', 10)]),
          ),
          bookingRepositoryProvider.overrideWithValue(bookingRepo),
        ],
        child: const MaterialApp(
          home: LessonBookingScreen(
            params: LessonBookingParams(
              teacherId: 't1',
              teacherName: '김선생',
              studentId: 's1',
              studentName: '학생',
              instrument: '바이올린',
              subscriptionId: 'sub-active-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.bookAction));
    // Mirrors lesson_booking_double_tap_test.dart — the confirm dialog stays
    // open without reaching a steady state, so pumpAndSettle() hangs here.
    await tester.pump();
    await tester.pump();

    // Confirm dialog button (TextButton) — distinct from the bottom bar's
    // FilledButton, both labelled AppStrings.bookAction.
    await tester.tap(find.widgetWithText(TextButton, AppStrings.bookAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(bookingRepo.capturedSubscriptionId, 'sub-active-1');
  });
}
