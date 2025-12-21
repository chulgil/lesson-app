import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lesson_booking.dart';
import '../../models/time_slot.dart';
import '../../repositories/booking_repository.dart';
import 'booking_repository_provider.dart';

// Export repository provider
export 'booking_repository_provider.dart';

// =============================================================================
// Query Providers (FutureProvider)
// =============================================================================

/// All bookings provider
final allBookingsProvider = FutureProvider<List<LessonBooking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAllBookings();
});

/// Single booking provider
final bookingProvider =
    FutureProvider.family<LessonBooking?, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingById(bookingId);
});

/// Bookings by teacher provider
final teacherBookingsProvider =
    FutureProvider.family<List<LessonBooking>, String>((ref, teacherId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByTeacher(teacherId);
});

/// Bookings by student provider
final studentBookingsProvider =
    FutureProvider.family<List<LessonBooking>, String>((ref, studentId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByStudent(studentId);
});

/// Bookings by status provider
final bookingsByStatusProvider = FutureProvider.family<List<LessonBooking>,
    BookingStatus>((ref, status) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByStatus(status);
});

/// Pending bookings for teacher provider
final pendingBookingsProvider =
    FutureProvider.family<List<LessonBooking>, String>((ref, teacherId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getPendingBookings(teacherId);
});

/// Pending bookings count provider (for badge)
final pendingBookingsCountProvider =
    FutureProvider.family<int, String>((ref, teacherId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final bookings = await repository.getPendingBookings(teacherId);
  return bookings.length;
});

/// Upcoming bookings provider (confirmed, future dates)
final upcomingBookingsProvider =
    FutureProvider.family<List<LessonBooking>, String>((ref, teacherId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final bookings = await repository.getBookingsByTeacher(teacherId);
  return bookings
      .where((b) => b.isUpcoming && b.status == BookingStatus.confirmed)
      .toList()
    ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));
});

/// Teacher availability provider
final teacherAvailabilityProvider =
    FutureProvider.family<List<TimeSlot>, String>((ref, teacherId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getTeacherAvailability(teacherId);
});

/// Available dates provider
final availableDatesProvider = FutureProvider.family<List<DateTime>,
    ({String teacherId, DateTime from, DateTime to})>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableDates(
    params.teacherId,
    params.from,
    params.to,
  );
});

/// Available time slots for booking (by date)
final bookingAvailableTimeSlotsProvider = FutureProvider.family<List<TimeSlot>,
    ({String teacherId, DateTime date})>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableTimeSlotsForDate(
    params.teacherId,
    params.date,
  );
});

// =============================================================================
// Mutation Provider (AsyncNotifier)
// =============================================================================

/// Bookings notifier for CRUD operations
class BookingsNotifier extends AsyncNotifier<List<LessonBooking>> {
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
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.requestTrialLesson(
        teacherId: teacherId,
        teacherName: teacherName,
        request: request,
        fee: fee,
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
  Future<LessonBooking> approveTrialLesson(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.approveTrialLesson(bookingId);
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
    UnavailableReason reason, {
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
  Future<LessonBooking> completeLesson(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _repository.completeLesson(bookingId);
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
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

final bookingsNotifierProvider =
    AsyncNotifierProvider<BookingsNotifier, List<LessonBooking>>(
  BookingsNotifier.new,
);

// =============================================================================
// Selected State Providers
// =============================================================================

/// Selected date for booking
final selectedBookingDateProvider = StateProvider<DateTime?>((ref) => null);

/// Selected time slot for booking
final selectedBookingTimeSlotProvider = StateProvider<TimeSlot?>((ref) => null);

/// Selected schedule type for regular lesson
final selectedScheduleTypeProvider =
    StateProvider<ScheduleType>((ref) => ScheduleType.fixed);

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
      preferredStartTime: startTime,
      preferredEndTime: endTime,
    );
  }
}

final trialLessonFormProvider =
    StateProvider<TrialLessonFormState>((ref) => const TrialLessonFormState());
