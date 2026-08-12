import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/repositories/booking_repository.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/approval_bottom_sheet.dart';

/// #F2 (teacher-journey audit) — 직접예약 승인 UI 를 신청(RequestDetailScreen)
/// 상세 화면 하우스 패턴에 정렬한다. 이 테스트는 그 정렬의 두 축을 지킨다:
/// - 거절은 destructive 이므로 NotebookAlertDialog 확인을 거친 뒤에만 API 를 호출한다.
/// - 승인/거절 버튼 라벨은 공유 AppStrings 상수와 동일하다 (동의어 재발 방지 가드).
class _SpyBookingRepository implements BookingRepository {
  final LessonBooking booking;
  int markUnavailableCallCount = 0;
  int approveTrialLessonCallCount = 0;

  _SpyBookingRepository(this.booking);

  @override
  Future<List<LessonBooking>> getAllBookings() async => [booking];

  @override
  Future<LessonBooking> markUnavailable(
    String id,
    String reason, {
    List<TimeSlot>? suggestedTimeSlots,
  }) async {
    markUnavailableCallCount++;
    return booking.copyWith(status: BookingStatus.unavailable);
  }

  @override
  Future<LessonBooking> approveTrialLesson(
    String id, {
    String? selectedOptionId,
  }) async {
    approveTrialLessonCallCount++;
    return booking.copyWith(status: BookingStatus.confirmed);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LessonBooking _buildBooking() {
  final now = DateTime.now();
  return LessonBooking(
    id: 'booking_test_1',
    teacherId: 'teacher_1',
    teacherName: '선생님',
    studentName: '학생',
    lessonType: LessonType.trial,
    status: BookingStatus.pending,
    lessonDate: now.add(const Duration(days: 3)),
    startTime: const ClockTime(hour: 10, minute: 0),
    endTime: const ClockTime(hour: 11, minute: 0),
    fee: 30000,
    createdAt: now,
  );
}

Future<void> _pumpApprovalSheet(
  WidgetTester tester,
  _SpyBookingRepository repo,
  LessonBooking booking,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: ApprovalBottomSheet(
            booking: booking,
            teacherId: booking.teacherId,
            scrollController: ScrollController(),
            onApproved: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ApprovalBottomSheet CTA labels', () {
    testWidgets('승인/거절 버튼은 공유 AppStrings 상수와 동일한 라벨을 사용한다', (tester) async {
      final booking = _buildBooking();
      final repo = _SpyBookingRepository(booking);

      await _pumpApprovalSheet(tester, repo, booking);

      expect(find.text(AppStrings.approveAction), findsOneWidget);
      expect(find.text(AppStrings.rejectAction), findsOneWidget);
    });
  });

  group('ApprovalBottomSheet reject confirmation', () {
    testWidgets('거절은 확인 다이얼로그를 거친 뒤에만 markUnavailable 을 호출한다', (tester) async {
      final booking = _buildBooking();
      final repo = _SpyBookingRepository(booking);

      await _pumpApprovalSheet(tester, repo, booking);

      await tester.tap(find.text(AppStrings.rejectAction));
      await tester.pumpAndSettle();

      // Decline bottom sheet opens — "메시지만 전달" completes the pure
      // rejection path without suggesting alternative times.
      expect(find.text(AppStrings.messageOnly), findsOneWidget);
      await tester.tap(find.text(AppStrings.messageOnly));
      await tester.pumpAndSettle();

      // Confirm dialog blocks the API call until confirmed.
      expect(find.text(AppStrings.bookingRejectConfirmTitle), findsOneWidget);
      expect(repo.markUnavailableCallCount, 0);

      // Cancel keeps the sheet open with no API call.
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(repo.markUnavailableCallCount, 0);

      // Re-open and confirm this time.
      await tester.tap(find.text(AppStrings.rejectAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.messageOnly));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.eventReject));
      await tester.pumpAndSettle();

      expect(repo.markUnavailableCallCount, 1);
    });
  });
}
