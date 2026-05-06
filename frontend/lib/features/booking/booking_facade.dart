/// Booking Facade — single entry point for all booking operations.
///
/// AI: Read this file to understand the full booking API.
/// All booking entity types, query providers, and mutation methods
/// are accessible through this single import.
///
/// Usage:
///   import 'package:lesson_app/features/booking/booking_facade.dart';
///
///   // Query (reactive)
///   ref.watch(studentBookingListProvider(studentId))
///   ref.watch(pendingBookingListProvider(teacherId))
///
///   // Mutate (imperative)
///   ref.read(bookingFacadeProvider.notifier).requestTrial(...)
///   ref.read(bookingFacadeProvider.notifier).cancel(id, reason)
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/booking/entities/lesson_booking.dart';
import '../../core/booking/entities/time_slot.dart';
import '../lessons/lessons_facade.dart';

// Re-export entities so consumers only need this one import
export '../../core/booking/entities/lesson_booking.dart'; // LessonBooking, enums, request types
export '../../core/booking/entities/time_slot.dart'; // TimeSlot

part 'booking_facade.g.dart';

// =============================================================================
// QUERY PROVIDERS — use-case named wrappers over raw providers
// =============================================================================

/// Single booking by ID.
@riverpod
Future<LessonBooking?> bookingById(BookingByIdRef ref, String id) {
  return ref.watch(bookingProvider(id).future);
}

/// All bookings for a student (student home, trial cards).
@riverpod
Future<List<LessonBooking>> studentBookingList(
  StudentBookingListRef ref,
  String studentId,
) {
  return ref.watch(studentBookingsProvider(studentId).future);
}

/// All bookings for a teacher (teacher schedule).
@riverpod
Future<List<LessonBooking>> teacherBookingList(
  TeacherBookingListRef ref,
  String teacherId,
) {
  return ref.watch(teacherBookingsProvider(teacherId).future);
}

/// Pending bookings awaiting teacher approval.
@riverpod
Future<List<LessonBooking>> pendingBookingList(
  PendingBookingListRef ref,
  String teacherId,
) {
  return ref.watch(pendingBookingsProvider(teacherId).future);
}

/// Badge count for pending bookings.
@riverpod
Future<int> pendingCount(PendingCountRef ref, String teacherId) {
  return ref.watch(pendingBookingsCountProvider(teacherId).future);
}

/// Confirmed upcoming bookings.
@riverpod
Future<List<LessonBooking>> upcomingConfirmed(
  UpcomingConfirmedRef ref,
  String teacherId,
) {
  return ref.watch(upcomingBookingsProvider(teacherId).future);
}

/// Teacher's available time slots.
@riverpod
Future<List<TimeSlot>> teacherSlots(TeacherSlotsRef ref, String teacherId) {
  return ref.watch(teacherAvailabilityProvider(teacherId).future);
}

// =============================================================================
// MUTATION NOTIFIER — single class for all write operations
// =============================================================================

/// Unified mutation API for all booking operations.
///
/// Methods:
/// - [requestTrial] — student requests trial lesson
/// - [approveTrial] — teacher approves trial
/// - [requestRegular] — student requests regular lessons
/// - [registerRegular] — teacher directly registers regular
/// - [markUnavailable] — teacher declines with reason
/// - [cancel] — either party cancels
/// - [complete] — teacher marks lesson done
/// - [update] — generic update
/// - [delete] — hard delete
@Riverpod(keepAlive: true)
class BookingFacade extends _$BookingFacade {
  BookingsNotifier get _inner => ref.read(bookingsNotifierProvider.notifier);

  @override
  Future<List<LessonBooking>> build() async {
    return ref.watch(bookingsNotifierProvider.future);
  }

  Future<LessonBooking> requestTrial({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    int fee = 30000,
  }) => _inner.requestTrialLesson(
    teacherId: teacherId,
    teacherName: teacherName,
    request: request,
    fee: fee,
  );

  Future<LessonBooking> approveTrial(
    String bookingId, {
    String? selectedOptionId,
  }) =>
      _inner.approveTrialLesson(bookingId, selectedOptionId: selectedOptionId);

  Future<LessonBooking> requestRegular({
    required String teacherId,
    required String teacherName,
    required RegularLessonRequest request,
    int monthlyFee = 200000,
  }) => _inner.requestRegularLesson(
    teacherId: teacherId,
    teacherName: teacherName,
    request: request,
    monthlyFee: monthlyFee,
  );

  Future<LessonBooking> registerRegular({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required RegularLessonRegistration registration,
  }) => _inner.registerRegularLesson(
    teacherId: teacherId,
    teacherName: teacherName,
    studentId: studentId,
    studentName: studentName,
    registration: registration,
  );

  Future<LessonBooking> markUnavailable(
    String bookingId,
    String reason, {
    List<TimeSlot>? suggestedTimeSlots,
  }) => _inner.markUnavailable(
    bookingId,
    reason,
    suggestedTimeSlots: suggestedTimeSlots,
  );

  Future<LessonBooking> cancel(String bookingId, String? reason) =>
      _inner.cancelBooking(bookingId, reason);

  Future<LessonBooking> complete(String bookingId) =>
      _inner.completeLesson(bookingId);

  Future<LessonBooking> updateBooking(LessonBooking booking) =>
      _inner.updateBooking(booking);

  Future<void> delete(String bookingId) => _inner.deleteBooking(bookingId);

  Future<void> refresh() => _inner.refresh();
}

// =============================================================================
// FORM STATE — re-exported from existing providers for booking flow screens
// =============================================================================

/// Selected date during booking flow.
final selectedDateProvider = selectedBookingDateProvider;

/// Selected time slot during booking flow.
final selectedTimeSlotProvider = selectedBookingTimeSlotProvider;

/// Schedule type selection (fixed/flexible).
final scheduleTypeProvider = selectedScheduleTypeProvider;

/// Trial lesson form state.
final trialFormProvider = trialLessonFormProvider;
