import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import 'package:hive/hive.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../features/profile/domain/entities/teacher.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../search/search_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../data/local/teacher_availability_cache_store.dart';
import '../../data/repositories/mock_teacher_availability_repository.dart';
import '../../data/repositories/remote_teacher_availability_repository.dart';
import '../../data/repositories/sync_aware_teacher_availability_repository.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/repositories/teacher_availability_repository.dart';
import '../../domain/services/booking_lead_time_service.dart';
import '../../domain/services/slot_recommendation_service.dart';
import '../services/booking_notification_service.dart';

part 'teacher_availability_providers.g.dart';

// ============================================================
// Repository Provider - switches between Mock and Remote.
// ============================================================

@Riverpod(keepAlive: true)
TeacherAvailabilityRepository teacherAvailabilityRepository(Ref ref) =>
    createSyncAwareRepository<TeacherAvailabilityRepository>(
      ref: ref,
      mock: () => MockTeacherAvailabilityRepository(),
      syncAware: (api, queue) => SyncAwareTeacherAvailabilityRepository(
        remote: RemoteTeacherAvailabilityRepository(api),
        queue: queue,
        cache: TeacherAvailabilityCacheStore(
          box: Hive.box<String>(TeacherAvailabilityCacheStore.boxName),
        ),
      ),
    );

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
// Affected bookings for a weekly schedule (#C3)
// ============================================================
//
// Spec: docs/specs/_audits/2026-06-10-teacher-flow-ux-audit.md §4.9.
// Returns the count of upcoming active bookings (pending/confirmed) whose
// (dayOfWeek, startTime, endTime) overlap with the weekly recurring slot
// the teacher is about to delete.
//
// LessonBooking.dayOfWeek uses 1=Mon..7=Sun, while WeeklySchedule.dayOfWeek
// uses 0=Mon..6=Sun — we normalize before comparing.
@riverpod
Future<int> affectedBookingsForWeeklySchedule(
  AffectedBookingsForWeeklyScheduleRef ref, {
  required String teacherId,
  required int weeklyDayOfWeek,
  required String weeklyStartTime,
  required String weeklyEndTime,
}) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final bookings = await repository.getBookingsByTeacher(teacherId);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = _parseHHmm(weeklyStartTime);
  final end = _parseHHmm(weeklyEndTime);
  return bookings.where((b) {
    if (!b.status.isActive) return false;
    if (b.lessonDate.isBefore(today)) return false;
    // LessonBooking.dayOfWeek is 1..7 (Mon=1). WeeklySchedule is 0..6 (Mon=0).
    final bookingDow0 = ((b.lessonDate.weekday) - 1) % 7;
    if (bookingDow0 != weeklyDayOfWeek) return false;
    final bookingStart = b.startTime.hour * 60 + b.startTime.minute;
    final bookingEnd = b.endTime.hour * 60 + b.endTime.minute;
    // Overlap when [bookingStart, bookingEnd) intersects [start, end).
    return bookingStart < end && bookingEnd > start;
  }).length;
}

int _parseHHmm(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
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
  final slots = await repository.getAvailableSlotsForDate(
    teacherId,
    date,
    currentStudentId: currentStudentId,
  );
  // #850 — exclude slots inside the teacher's minimum booking lead time.
  final availability = await ref.watch(
    teacherAvailabilityProvider(teacherId).future,
  );
  return BookingLeadTimeService.filterByLeadTime(
    slots: slots,
    minBookingHours: availability?.minBookingHours ?? 0,
    now: DateTime.now(),
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
  final slots = await repository.getAvailableSlotsForDateRange(
    teacherId,
    startDate,
    endDate,
    currentStudentId: currentStudentId,
  );
  // #850 — exclude slots inside the teacher's minimum booking lead time.
  final availability = await ref.watch(
    teacherAvailabilityProvider(teacherId).future,
  );
  return BookingLeadTimeService.filterByLeadTime(
    slots: slots,
    minBookingHours: availability?.minBookingHours ?? 0,
    now: DateTime.now(),
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
        preferredStartTime: slotStartTime.toClockTime(),
        preferredEndTime: slotEndTime.toClockTime(),
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

      // Invalidate related providers to refresh data.
      // #528 — invalidateSelf() alone only refreshes this notifier's last-slot
      // state, leaving the bookings list (availableSlotsForDateRangeProvider) and
      // the student home next-lesson card (studentBookingsProvider →
      // studentHomeNextLessonProvider) stale after a successful (re)booking.
      // Whole-family invalidate: the date-range family is keyed by DateTime args
      // computed at the call site, so a specific-instance match is impossible.
      ref.invalidateSelf();
      ref.invalidate(availableSlotsForDateRangeProvider);
      ref.invalidate(studentBookingsProvider);
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
              startTime: cancelledSlot.startTime.toFlutterTimeOfDay(),
              isTeacherInitiated: isTeacherInitiated,
              reason: reason,
            );
        // TODO: Send notification via notification service
        debugPrint('Cancellation notification created: ${notification.title}');
      }

      // Invalidate related providers to refresh data.
      // #528 — same rationale as bookSlotSimple: refresh the bookings list and
      // the student home next-lesson card so a successful cancel is reflected
      // immediately instead of only showing a success toast over a stale list.
      ref.invalidateSelf();
      ref.invalidate(availableSlotsForDateRangeProvider);
      ref.invalidate(studentBookingsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // NOTE: A non-atomic rescheduleBooking() (cancel-old-then-book-new) used to
  // live here. It was removed (#483 Lore-rejected: that order can lose the
  // original booking if the new booking fails). Reschedule is now orchestrated
  // by BookingRescheduleScreen._performReschedule (book-new-then-cancel-old
  // with rollback). No call sites remained.
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
      final updated = await repository.updateWeeklySchedule(
        teacherId,
        schedule,
      );
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
      await repository.toggleTimeBlock(
        teacherId,
        date,
        time.toClockTime(),
        isAvailable,
      );

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
