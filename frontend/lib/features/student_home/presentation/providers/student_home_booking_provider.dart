// 학생 홈에서 필요한 예약 데이터를 화면 용도별로 조합하는 provider입니다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../lessons/lessons_facade.dart';

final studentHomeNextLessonProvider = FutureProvider.autoDispose
    .family<LessonBooking?, String>((ref, studentId) async {
      final bookings = await ref.watch(
        studentBookingsProvider(studentId).future,
      );
      final now = DateTime.now();
      final upcomingBookings =
          bookings
              .where((booking) => booking.status.isActive)
              .where((booking) => booking.lessonDate.isAfter(now))
              .toList()
            ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

      return upcomingBookings.isEmpty ? null : upcomingBookings.first;
    });

final studentHomeTrialBookingsProvider = FutureProvider.autoDispose.family<
  List<LessonBooking>,
  String
>((ref, studentId) async {
  final bookings = await ref.watch(studentBookingsProvider(studentId).future);
  return bookings
      .where((booking) => booking.lessonType == LessonType.trial)
      .where((booking) => booking.status.isActive || booking.status.canRetry)
      .toList()
    ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));
});

final studentHomeBookingActionsProvider = Provider<StudentHomeBookingActions>((
  ref,
) {
  return StudentHomeBookingActions(ref);
});

class StudentHomeBookingActions {
  final Ref _ref;

  const StudentHomeBookingActions(this._ref);

  Future<LessonBooking> cancelTrialBooking({
    required String? studentId,
    required String bookingId,
    String? reason,
  }) async {
    final booking = await _ref
        .read(bookingsNotifierProvider.notifier)
        .cancelBooking(bookingId, reason);
    if (studentId != null) {
      _ref.invalidate(studentHomeNextLessonProvider(studentId));
      _ref.invalidate(studentHomeTrialBookingsProvider(studentId));
    }
    return booking;
  }
}
