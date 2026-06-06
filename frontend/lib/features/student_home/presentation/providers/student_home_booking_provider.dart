// 학생 홈에서 필요한 예약 데이터를 화면 용도별로 조합하는 provider입니다.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../lessons/lessons_facade.dart';

part 'student_home_booking_provider.g.dart';

@riverpod
Future<LessonBooking?> studentHomeNextLesson(
  StudentHomeNextLessonRef ref,
  String studentId,
) async {
  final bookings = await ref.watch(studentBookingsProvider(studentId).future);
  final now = DateTime.now();
  final upcomingBookings =
      bookings
          .where((booking) => booking.status.isActive)
          .where((booking) => booking.lessonDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

  return upcomingBookings.isEmpty ? null : upcomingBookings.first;
}

@riverpod
Future<List<LessonBooking>> studentHomeTrialBookings(
  StudentHomeTrialBookingsRef ref,
  String studentId,
) async {
  final bookings = await ref.watch(studentBookingsProvider(studentId).future);
  return bookings
      .where((booking) => booking.lessonType == LessonType.trial)
      .where((booking) => booking.status.isActive || booking.status.canRetry)
      .toList()
    ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));
}

@riverpod
Future<bool> studentHomeHasAnyBooking(
  StudentHomeHasAnyBookingRef ref,
  String studentId,
) async {
  final bookings = await ref.watch(studentBookingsProvider(studentId).future);
  return bookings.isNotEmpty;
}

@riverpod
Future<StudentHomeLessonsSchedule> studentHomeLessonsSchedule(
  StudentHomeLessonsScheduleRef ref,
  String studentId,
) async {
  final lessons = await ref.watch(lessonsByStudentProvider(studentId).future);
  final bookings = await ref.watch(studentBookingsProvider(studentId).future);
  final trialBookings =
      bookings
          .where((booking) => booking.lessonType == LessonType.trial)
          .where(
            (booking) => booking.status.isActive || booking.status.canRetry,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final markerDates =
      lessons
          .map(
            (lesson) =>
                DateTime(lesson.date.year, lesson.date.month, lesson.date.day),
          )
          .toSet();
  markerDates.addAll(
    bookings
        .where((booking) => booking.status.isActive)
        .map(
          (booking) => DateTime(
            booking.lessonDate.year,
            booking.lessonDate.month,
            booking.lessonDate.day,
          ),
        ),
  );

  return StudentHomeLessonsSchedule(
    lessons: lessons,
    trialBookings: trialBookings,
    markerDates: markerDates,
  );
}

class StudentHomeLessonsSchedule {
  final List<Lesson> lessons;
  final List<LessonBooking> trialBookings;
  final Set<DateTime> markerDates;

  const StudentHomeLessonsSchedule({
    required this.lessons,
    required this.trialBookings,
    required this.markerDates,
  });
}

@riverpod
StudentHomeBookingActions studentHomeBookingActions(
  StudentHomeBookingActionsRef ref,
) {
  return StudentHomeBookingActions(ref);
}

class StudentHomeBookingActions {
  final StudentHomeBookingActionsRef _ref;

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
      // Also refresh the weekly schedule grid so cancelled lesson markers
      // disappear from the lessons tab calendar immediately.
      _ref.invalidate(studentHomeLessonsScheduleProvider(studentId));
    }
    return booking;
  }
}
