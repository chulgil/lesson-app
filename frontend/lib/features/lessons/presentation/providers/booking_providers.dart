import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/booking/entities/lesson_booking.dart';
import '../../../../../core/booking/entities/time_slot.dart';
import '../../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/booking/repositories/booking_repository.dart';
import '../../../subscription/subscription_facade.dart';
import 'booking_repository_provider.dart';

// Export repository provider
export 'booking_repository_provider.dart';

part 'booking_providers.g.dart';

// =============================================================================
// Query Providers (FutureProvider)
// =============================================================================

/// All bookings provider
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> allBookings(AllBookingsRef ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAllBookings();
}

/// Single booking provider
@Riverpod(keepAlive: true)
Future<LessonBooking?> booking(BookingRef ref, String bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingById(bookingId);
}

/// Bookings by teacher provider
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> teacherBookings(
  TeacherBookingsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByTeacher(teacherId);
}

/// Bookings by student provider
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> studentBookings(
  StudentBookingsRef ref,
  String studentId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByStudent(studentId);
}

/// Bookings by status provider
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> bookingsByStatus(
  BookingsByStatusRef ref,
  BookingStatus status,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByStatus(status);
}

/// Pending bookings for teacher provider
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> pendingBookings(
  PendingBookingsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getPendingBookings(teacherId);
}

/// Pending bookings count provider (for badge)
@Riverpod(keepAlive: true)
Future<int> pendingBookingsCount(
  PendingBookingsCountRef ref,
  String teacherId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final bookings = await repository.getPendingBookings(teacherId);
  return bookings.length;
}

/// Upcoming bookings provider (confirmed, future dates)
@Riverpod(keepAlive: true)
Future<List<LessonBooking>> upcomingBookings(
  UpcomingBookingsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final bookings = await repository.getBookingsByTeacher(teacherId);
  return bookings
      .where((b) => b.isUpcoming && b.status == BookingStatus.confirmed)
      .toList()
    ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));
}

/// Teacher availability provider
@Riverpod(keepAlive: true)
Future<List<TimeSlot>> teacherAvailability(
  TeacherAvailabilityRef ref,
  String teacherId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getTeacherAvailability(teacherId);
}

/// Available dates provider
@Riverpod(keepAlive: true)
Future<List<DateTime>> availableDates(
  AvailableDatesRef ref,
  ({String teacherId, DateTime from, DateTime to}) params,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableDates(params.teacherId, params.from, params.to);
}

/// Available time slots for booking (by date)
@Riverpod(keepAlive: true)
Future<List<TimeSlot>> bookingAvailableTimeSlots(
  BookingAvailableTimeSlotsRef ref,
  ({String teacherId, DateTime date}) params,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableTimeSlotsForDate(params.teacherId, params.date);
}

// =============================================================================
// Mutation Provider (AsyncNotifier)
// =============================================================================

/// Bookings notifier for CRUD operations
@Riverpod(keepAlive: true)
class BookingsNotifier extends _$BookingsNotifier {
  BookingRepository get _repository => ref.read(bookingRepositoryProvider);

  @override
  Future<List<LessonBooking>> build() async {
    return _repository.getAllBookings();
  }

  /// Request a trial lesson
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    int fee = 30000, // Default trial fee
    String? subscriptionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.requestTrialLesson(
        teacherId: teacherId,
        teacherName: teacherName,
        request: request,
        fee: fee,
        subscriptionId: subscriptionId,
      );
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Approve a trial lesson request
  /// If [selectedOptionId] is provided, use that schedule option for the lesson
  Future<LessonBooking> approveTrialLesson(
    String bookingId, {
    String? selectedOptionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.approveTrialLesson(
        bookingId,
        selectedOptionId: selectedOptionId,
      );
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Request a regular lesson (student-initiated, pending teacher approval)
  Future<LessonBooking> requestRegularLesson({
    required String teacherId,
    required String teacherName,
    required RegularLessonRequest request,
    int monthlyFee = 200000,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.requestRegularLesson(
        teacherId: teacherId,
        teacherName: teacherName,
        request: request,
        monthlyFee: monthlyFee,
      );
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Mark booking as unavailable (teacher cannot do this time)
  Future<LessonBooking> markUnavailable(
    String bookingId,
    String reason, {
    List<TimeSlot>? suggestedTimeSlots,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.markUnavailable(
        bookingId,
        reason,
        suggestedTimeSlots: suggestedTimeSlots,
      );
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Register a regular lesson
  Future<LessonBooking> registerRegularLesson({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required RegularLessonRegistration registration,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.registerRegularLesson(
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: studentId,
        studentName: studentName,
        registration: registration,
      );
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cancel a booking
  Future<LessonBooking> cancelBooking(String bookingId, String? reason) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.cancelBooking(bookingId, reason);
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Complete a lesson
  /// For trial lessons, triggers auto-proposal if enabled
  Future<LessonBooking> completeLesson(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.completeLesson(bookingId);

      // Trigger auto-proposal for completed trial lessons
      if (booking.isTrial && booking.status == BookingStatus.completed) {
        await _triggerAutoProposalForTrialLesson(booking);
      }

      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Trigger auto-proposal after trial lesson completion
  Future<void> _triggerAutoProposalForTrialLesson(LessonBooking booking) async {
    // Skip if no student ID (shouldn't happen for trial lessons)
    if (booking.studentId == null) return;

    try {
      final autoProposalService = ref.read(autoProposalServiceProvider);
      await autoProposalService.triggerAfterTrialCompletion(
        teacherId: booking.teacherId,
        studentId: booking.studentId!,
        trialCompletedAt: DateTime.now(),
      );
    } catch (e) {
      // Log error but don't fail the main operation
      // Auto-proposal failure should not block lesson completion
      debugPrint('Auto-proposal trigger failed: $e');
    }
  }

  /// Update a booking
  Future<LessonBooking> updateBooking(LessonBooking booking) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateBooking(booking);
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a booking
  Future<void> deleteBooking(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBooking(bookingId);
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh bookings
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllBookings());
  }
}

// =============================================================================
// Selected State Providers
// =============================================================================

/// Selected date for booking
@Riverpod(keepAlive: true)
class SelectedBookingDate extends _$SelectedBookingDate {
  @override
  DateTime? build() => null;

  @override
  DateTime? get state => super.state;

  @override
  set state(DateTime? value) => super.state = value;
}

/// Selected time slot for booking
@Riverpod(keepAlive: true)
class SelectedBookingTimeSlot extends _$SelectedBookingTimeSlot {
  @override
  TimeSlot? build() => null;

  @override
  TimeSlot? get state => super.state;

  @override
  set state(TimeSlot? value) => super.state = value;

  void select(TimeSlot timeSlot) {
    state = timeSlot;
  }

  void clear() {
    state = null;
  }
}

typedef SelectedBookingTimeSlotNotifier = SelectedBookingTimeSlot;

/// Selected schedule type for regular lesson
@Riverpod(keepAlive: true)
class SelectedScheduleType extends _$SelectedScheduleType {
  @override
  ScheduleType build() => ScheduleType.fixed;

  @override
  ScheduleType get state => super.state;

  @override
  set state(ScheduleType value) => super.state = value;
}

/// Trial lesson request form state
class TrialLessonFormState {
  final String name;
  final String? phone;
  final String? email;
  final LessonGoal goal;
  final ExperienceLevel experience;
  final String? message;

  const TrialLessonFormState({
    this.name = '',
    this.phone,
    this.email,
    this.goal = LessonGoal.hobby,
    this.experience = ExperienceLevel.none,
    this.message,
  });

  TrialLessonFormState copyWith({
    String? name,
    String? phone,
    String? email,
    LessonGoal? goal,
    ExperienceLevel? experience,
    String? message,
  }) {
    return TrialLessonFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      message: message ?? this.message,
    );
  }

  bool get isValid => name.isNotEmpty;

  TrialLessonRequest toRequest({
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    return TrialLessonRequest(
      studentName: name,
      studentPhone: phone,
      studentEmail: email,
      goal: goal,
      experience: experience,
      message: message,
      preferredDate: date,
      preferredStartTime: startTime.toClockTime(),
      preferredEndTime: endTime.toClockTime(),
    );
  }
}

@Riverpod(keepAlive: true)
class TrialLessonForm extends _$TrialLessonForm {
  @override
  TrialLessonFormState build() => const TrialLessonFormState();

  @override
  TrialLessonFormState get state => super.state;

  @override
  set state(TrialLessonFormState value) => super.state = value;

  void update(TrialLessonFormState formState) {
    state = formState;
  }

  void reset() {
    state = const TrialLessonFormState();
  }
}

typedef TrialLessonFormNotifier = TrialLessonForm;
