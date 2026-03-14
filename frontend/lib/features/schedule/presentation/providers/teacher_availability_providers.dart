import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/teacher.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../lessons/presentation/providers/lesson_repository_provider.dart';
import '../../../search/presentation/providers/teacher_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../data/repositories/mock_teacher_availability_repository.dart';
import '../../data/repositories/remote_teacher_availability_repository.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/repositories/teacher_availability_repository.dart';
import '../../domain/services/slot_recommendation_service.dart';
import '../services/booking_notification_service.dart';

part 'teacher_availability_providers.g.dart';

// ============================================================
// Repository Provider - switches between Mock and Remote.
// ============================================================

final teacherAvailabilityRepositoryProvider =
    Provider<TeacherAvailabilityRepository>((ref) {
      if (EnvironmentConfig.useMockData) {
        return MockTeacherAvailabilityRepository();
      }
      return RemoteTeacherAvailabilityRepository(ref.read(apiClientProvider));
    });

// ============================================================
// Teacher Availability Settings
// ============================================================

@riverpod
Future<TeacherAvailability?> teacherAvailability(
  TeacherAvailabilityRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);
  return repository.getAvailability(teacherId);
}

// ============================================================
// Available Slots for Date
// ============================================================

@riverpod
Future<List<AvailabilitySlot>> availableSlotsForDate(
  AvailableSlotsForDateRef ref, {
  required String teacherId,
  required DateTime date,
  String? currentStudentId,
}) async {
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);
  return repository.getAvailableSlotsForDate(
    teacherId,
    date,
    currentStudentId: currentStudentId,
  );
}

// ============================================================
// Available Slots for Date Range
// ============================================================

@riverpod
Future<List<AvailabilitySlot>> availableSlotsForDateRange(
  AvailableSlotsForDateRangeRef ref, {
  required String teacherId,
  required DateTime startDate,
  required DateTime endDate,
  String? currentStudentId,
}) async {
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);
  return repository.getAvailableSlotsForDateRange(
    teacherId,
    startDate,
    endDate,
    currentStudentId: currentStudentId,
  );
}

// ============================================================
// Next Available Dates (for empty state)
// ============================================================

@riverpod
Future<List<DateTime>> nextAvailableDates(
  NextAvailableDatesRef ref, {
  required String teacherId,
  required DateTime fromDate,
  int limit = 3,
}) async {
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);
  return repository.getNextAvailableDates(
    teacherId,
    fromDate: fromDate,
    limit: limit,
  );
}

// ============================================================
// Recommended Slots (for student) - Enhanced with lesson history
// ============================================================

/// Analyze student's lesson history to find recurring patterns
@riverpod
Future<List<LessonTimePattern>> lessonTimePatterns(
  LessonTimePatternsRef ref, {
  required String studentId,
  required String teacherId,
  int analysisWindowDays = SlotRecommendationService.defaultAnalysisWindowDays,
}) async {
  final lessonRepository = ref.watch(lessonRepositoryProvider);

  // Get student's lessons within analysis window
  final lessons = await lessonRepository.getLessonsByStudent(studentId);

  return SlotRecommendationService.analyzeLessonHistory(
    lessons: lessons,
    teacherId: teacherId,
    analysisWindowDays: analysisWindowDays,
  );
}

/// Get recommended slots based on lesson history patterns
@riverpod
Future<List<AvailabilitySlot>> recommendedSlots(
  RecommendedSlotsRef ref, {
  required String teacherId,
  required String studentId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  // Get available slots for the date range
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);
  final allSlots = await repository.getAvailableSlotsForDateRange(
    teacherId,
    startDate,
    endDate,
    currentStudentId: studentId,
  );

  // Get lesson patterns for the student
  final patterns = await ref.watch(
    lessonTimePatternsProvider(
      studentId: studentId,
      teacherId: teacherId,
    ).future,
  );

  // If no patterns found, return empty
  if (patterns.isEmpty) return [];

  // Mark and filter recommended slots
  return SlotRecommendationService.getRecommendedSlots(
    slots: allSlots,
    patterns: patterns,
    limit: 5,
  );
}

/// Get available slots with recommendations marked
@riverpod
Future<List<AvailabilitySlot>> availableSlotsWithRecommendations(
  AvailableSlotsWithRecommendationsRef ref, {
  required String teacherId,
  required DateTime date,
  required String studentId,
}) async {
  final repository = ref.watch(teacherAvailabilityRepositoryProvider);

  // Get available slots for the date
  final slots = await repository.getAvailableSlotsForDate(
    teacherId,
    date,
    currentStudentId: studentId,
  );

  // Get lesson patterns
  final patterns = await ref.watch(
    lessonTimePatternsProvider(
      studentId: studentId,
      teacherId: teacherId,
    ).future,
  );

  // Mark recommended slots
  return SlotRecommendationService.markRecommendedSlots(
    slots: slots,
    patterns: patterns,
  );
}

// ============================================================
// Slot Selection State (for UI)
// ============================================================

@riverpod
class SelectedSlot extends _$SelectedSlot {
  @override
  AvailabilitySlot? build() => null;

  void select(AvailabilitySlot slot) {
    state = slot;
  }

  void clear() {
    state = null;
  }
}

// ============================================================
// Selected Date State (for date navigation)
// ============================================================

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime date) {
    state = date;
  }

  void nextDay() {
    state = state.add(const Duration(days: 1));
  }

  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }
}

// ============================================================
// Teacher Fee Info (get teacher's lesson fees)
// ============================================================

@riverpod
Future<Teacher?> bookingTeacherInfo(
  BookingTeacherInfoRef ref, {
  required String teacherId,
}) async {
  return ref.watch(teacherProvider(teacherId).future);
}

// ============================================================
// Subscription for Booking (get active subscription for student-teacher pair)
// ============================================================

@riverpod
Future<Subscription?> bookingSubscription(
  BookingSubscriptionRef ref, {
  required String studentId,
  required String teacherId,
}) async {
  // Get active subscriptions for the student
  final subscriptions = await ref.watch(
    activeStudentSubscriptionsProvider(studentId).future,
  );

  // For now, return the first active subscription
  // In production, this would filter by teacher/membership
  if (subscriptions.isEmpty) return null;

  // Return the first active subscription
  // TODO: Filter by teacher's class membership when backend is ready
  return subscriptions.first;
}

// ============================================================
// Booking Actions
// ============================================================

@riverpod
class SlotBookingNotifier extends _$SlotBookingNotifier {
  @override
  AsyncValue<AvailabilitySlot?> build() => const AsyncValue.data(null);

  /// Book a slot and create actual lesson booking
  Future<LessonBooking> bookSlot(
    String slotId,
    String studentId,
    String studentName, {
    required String teacherId,
    required String teacherName,
    required DateTime slotDate,
    required TimeOfDay slotStartTime,
    required TimeOfDay slotEndTime,
    String? instrument,
    LessonType lessonType = LessonType.oneTime,
    int fee = 50000,
  }) async {
    debugPrint('[SlotBookingNotifier] bookSlot called');
    debugPrint('[SlotBookingNotifier] slotId: $slotId');
    debugPrint(
      '[SlotBookingNotifier] studentId: $studentId, studentName: $studentName',
    );
    state = const AsyncValue.loading();

    try {
      // 1. Update availability slot status
      debugPrint('[SlotBookingNotifier] Step 1: Updating availability slot...');
      final availabilityRepository = ref.read(
        teacherAvailabilityRepositoryProvider,
      );
      final bookedSlot = await availabilityRepository.bookSlot(
        slotId,
        studentId,
        studentName,
      );
      debugPrint('[SlotBookingNotifier] Step 1 completed');

      // 2. Create actual lesson booking
      debugPrint('[SlotBookingNotifier] Step 2: Creating lesson booking...');
      final bookingsNotifier = ref.read(bookingsNotifierProvider.notifier);

      final request = TrialLessonRequest(
        studentId: studentId,
        studentName: studentName,
        goal: LessonGoal.hobby,
        experience: ExperienceLevel.none,
        preferredDate: slotDate,
        preferredStartTime: slotStartTime,
        preferredEndTime: slotEndTime,
      );

      final booking = await bookingsNotifier.requestTrialLesson(
        teacherId: teacherId,
        teacherName: teacherName,
        request: request,
        fee: fee,
      );
      debugPrint(
        '[SlotBookingNotifier] Step 2 completed, booking id: ${booking.id}',
      );

      state = AsyncValue.data(bookedSlot);

      // Invalidate related providers to refresh data
      ref.invalidateSelf();

      return booking;
    } catch (e, st) {
      debugPrint('[SlotBookingNotifier] ERROR: $e');
      debugPrint('[SlotBookingNotifier] StackTrace: $st');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Simple booking (legacy - without creating LessonBooking)
  Future<void> bookSlotSimple(
    String slotId,
    String studentId,
    String studentName,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final bookedSlot = await repository.bookSlot(
        slotId,
        studentId,
        studentName,
      );
      state = AsyncValue.data(bookedSlot);

      // Invalidate related providers to refresh data
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelBooking(
    String slotId, {
    String? teacherName,
    String? studentId,
    bool isTeacherInitiated = false,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final cancelledSlot = await repository.cancelBooking(slotId);
      state = AsyncValue.data(cancelledSlot);

      // Send cancellation notification if we have the necessary info
      if (studentId != null && teacherName != null) {
        final notification =
            BookingNotificationService.createCancellationNotification(
              userId: studentId,
              teacherName: teacherName,
              lessonDate: cancelledSlot.date,
              startTime: cancelledSlot.startTime,
              isTeacherInitiated: isTeacherInitiated,
              reason: reason,
            );
        // TODO: Send notification via notification service
        debugPrint('Cancellation notification created: ${notification.title}');
      }

      // Invalidate related providers to refresh data
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reschedule a booking to a new slot
  Future<AvailabilitySlot?> rescheduleBooking({
    required String oldSlotId,
    required String newSlotId,
    required String studentId,
    required String studentName,
    String? teacherId,
    String? teacherName,
    bool isTeacherInitiated = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);

      // Get old slot info before cancelling
      AvailabilitySlot? oldSlot;
      try {
        // Try to get the old slot info for notification
        final slots = await repository.getAvailableSlotsForDateRange(
          teacherId ?? '',
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now().add(const Duration(days: 60)),
          currentStudentId: studentId,
        );
        oldSlot = slots.firstWhere(
          (s) => s.id == oldSlotId,
          orElse: () => slots.first,
        );
      } catch (_) {
        // Ignore if we can't find the old slot
      }

      // Cancel old booking
      await repository.cancelBooking(oldSlotId);

      // Create new booking
      final newSlot = await repository.bookSlot(
        newSlotId,
        studentId,
        studentName,
      );

      state = AsyncValue.data(newSlot);

      // Send reschedule notification
      if (teacherName != null && oldSlot != null) {
        final notification =
            BookingNotificationService.createRescheduleNotification(
              userId: studentId,
              teacherName: teacherName,
              oldDate: oldSlot.date,
              oldTime: oldSlot.startTime,
              newDate: newSlot.date,
              newTime: newSlot.startTime,
              isTeacherInitiated: isTeacherInitiated,
            );
        // TODO: Send notification via notification service
        debugPrint('Reschedule notification created: ${notification.title}');
      }

      // Invalidate related providers to refresh data
      ref.invalidateSelf();

      return newSlot;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// ============================================================
// Teacher Management Actions
// ============================================================

@riverpod
class TeacherAvailabilityNotifier extends _$TeacherAvailabilityNotifier {
  @override
  AsyncValue<TeacherAvailability?> build(String teacherId) =>
      const AsyncValue.data(null);

  Future<void> addWeeklySchedule(WeeklySchedule schedule) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final updated = await repository.addWeeklySchedule(teacherId, schedule);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWeeklySchedule(WeeklySchedule schedule) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final updated = await repository.updateWeeklySchedule(teacherId, schedule);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeWeeklySchedule(String scheduleId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final updated = await repository.removeWeeklySchedule(
        teacherId,
        scheduleId,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addException(TimeException exception) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final updated = await repository.addException(teacherId, exception);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeException(String exceptionId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      final updated = await repository.removeException(teacherId, exceptionId);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTimeBlock(
    DateTime date,
    TimeOfDay time,
    bool isAvailable,
  ) async {
    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);
      await repository.toggleTimeBlock(teacherId, date, time, isAvailable);

      // Reload availability
      final updated = await repository.getAvailability(teacherId);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update lesson time settings
  Future<void> updateLessonSettings({
    required int slotDurationMinutes,
    required int slotStartInterval,
    required int breakTimeBetweenLessons,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(teacherAvailabilityRepositoryProvider);

      // Get current availability
      var availability = await repository.getAvailability(teacherId);

      if (availability == null) {
        // Create new availability if not exists
        availability = TeacherAvailability(
          id: teacherId,
          teacherId: teacherId,
          slotDurationMinutes: slotDurationMinutes,
          slotStartInterval: slotStartInterval,
          breakTimeBetweenLessons: breakTimeBetweenLessons,
          createdAt: DateTime.now(),
        );
      } else {
        // Update existing
        availability = availability.copyWith(
          slotDurationMinutes: slotDurationMinutes,
          slotStartInterval: slotStartInterval,
          breakTimeBetweenLessons: breakTimeBetweenLessons,
          updatedAt: DateTime.now(),
        );
      }

      final updated = await repository.saveAvailability(availability);
      state = AsyncValue.data(updated);

      // Invalidate slot providers to reflect new settings
      ref.invalidate(teacherAvailabilityProvider(teacherId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
