// Group class booking providers
// Handles booking creation, cancellation, and waitlist management

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_group_class_booking_repository.dart';
import '../../domain/entities/group_class_booking.dart';
import '../../domain/repositories/group_class_booking_repository.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/domain/entities/notification.dart';

part 'group_class_booking_providers.g.dart';

// ============================================================
// Repository Provider
// ============================================================

@Riverpod(keepAlive: true)
GroupClassBookingRepository groupClassBookingRepository(
  GroupClassBookingRepositoryRef ref,
) {
  return MockGroupClassBookingRepository(
    onWaitlistPromotion: (promoted) {
      // Send notification when promoted from waitlist
      _sendWaitlistPromotionNotification(ref, promoted);
    },
  );
}

void _sendWaitlistPromotionNotification(
  GroupClassBookingRepositoryRef ref,
  GroupClassBooking promoted,
) {
  try {
    final notificationService = ref.read(notificationServiceProvider);
    final notification = AppNotification(
      id: 'waitlist_promoted_${DateTime.now().millisecondsSinceEpoch}',
      userId: promoted.studentId,
      type: NotificationType.lessonBooked,
      priority: NotificationPriority.high,
      title: '🎉 대기 → 예약 확정!',
      body: '취소로 인해 예약이 확정되었습니다.',
      createdAt: DateTime.now(),
      actionLabel: '확인하기',
      data: {
        'bookingId': promoted.id,
        'scheduleId': promoted.scheduleId,
        'type': 'waitlist_promotion',
      },
    );
    notificationService.showNotification(notification);
  } catch (e) {
    debugPrint('[GroupClassBooking] Failed to send promotion notification: $e');
  }
}

// ============================================================
// Query Providers
// ============================================================

/// Get all bookings for a schedule
@riverpod
Future<List<GroupClassBooking>> scheduleBookings(
  ScheduleBookingsRef ref,
  String scheduleId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getBookingsForSchedule(scheduleId);
}

/// Get waitlist for a schedule
@riverpod
Future<List<GroupClassBooking>> scheduleWaitlist(
  ScheduleWaitlistRef ref,
  String scheduleId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getWaitlist(scheduleId);
}

/// Get confirmed count for a schedule
@riverpod
Future<int> scheduleConfirmedCount(
  ScheduleConfirmedCountRef ref,
  String scheduleId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getConfirmedCount(scheduleId);
}

/// Get waitlist count for a schedule
@riverpod
Future<int> scheduleWaitlistCount(
  ScheduleWaitlistCountRef ref,
  String scheduleId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getWaitlistCount(scheduleId);
}

/// Get booking for a specific student and schedule
@riverpod
Future<GroupClassBooking?> studentScheduleBooking(
  StudentScheduleBookingRef ref,
  String scheduleId,
  String studentId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getBooking(scheduleId, studentId);
}

/// Get all active bookings for a student
@riverpod
Future<List<GroupClassBooking>> studentActiveBookings(
  StudentActiveBookingsRef ref,
  String studentId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getActiveBookingsForStudent(studentId);
}

/// Get waitlist position for a student
@riverpod
Future<int?> studentWaitlistPosition(
  StudentWaitlistPositionRef ref,
  String scheduleId,
  String studentId,
) async {
  final repository = ref.watch(groupClassBookingRepositoryProvider);
  return repository.getWaitlistPosition(scheduleId, studentId);
}

// ============================================================
// Notifier for mutations
// ============================================================

@riverpod
class GroupClassBookingNotifier extends _$GroupClassBookingNotifier {
  @override
  AsyncValue<GroupClassBooking?> build() => const AsyncValue.data(null);

  /// Create a booking (confirmed or waitlist based on availability)
  Future<GroupClassBooking> createBooking({
    required String scheduleId,
    required String studentId,
    String? subscriptionId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);
      final booking = await repository.createBooking(
        scheduleId: scheduleId,
        studentId: studentId,
        subscriptionId: subscriptionId,
      );

      state = AsyncValue.data(booking);

      // Invalidate related providers
      ref.invalidate(scheduleBookingsProvider(scheduleId));
      ref.invalidate(scheduleConfirmedCountProvider(scheduleId));
      ref.invalidate(scheduleWaitlistCountProvider(scheduleId));
      ref.invalidate(scheduleWaitlistProvider(scheduleId));
      ref.invalidate(studentActiveBookingsProvider(studentId));

      return booking;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cancel a booking
  Future<GroupClassBooking> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);

      // Get booking first to know scheduleId and studentId for invalidation
      final booking = await repository.getBookingById(bookingId);
      if (booking == null) {
        throw Exception('예약을 찾을 수 없습니다');
      }

      final cancelled = await repository.cancelBooking(
        bookingId,
        reason: reason,
      );

      state = AsyncValue.data(cancelled);

      // Invalidate related providers
      ref.invalidate(scheduleBookingsProvider(booking.scheduleId));
      ref.invalidate(scheduleConfirmedCountProvider(booking.scheduleId));
      ref.invalidate(scheduleWaitlistCountProvider(booking.scheduleId));
      ref.invalidate(scheduleWaitlistProvider(booking.scheduleId));
      ref.invalidate(studentActiveBookingsProvider(booking.studentId));

      return cancelled;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Mark attendance
  Future<GroupClassBooking> markAttendance(
    String bookingId, {
    required bool attended,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);
      final updated = await repository.markAttendance(
        bookingId,
        attended: attended,
      );

      state = AsyncValue.data(updated);

      // Invalidate schedule bookings
      ref.invalidate(scheduleBookingsProvider(updated.scheduleId));

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Mark batch attendance
  Future<List<GroupClassBooking>> markBatchAttendance(
    Map<String, bool> bookingAttendance,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);
      final updated = await repository.markBatchAttendance(bookingAttendance);

      if (updated.isNotEmpty) {
        state = AsyncValue.data(updated.first);

        // Invalidate schedule bookings for all affected schedules
        final scheduleIds = updated.map((b) => b.scheduleId).toSet();
        for (final scheduleId in scheduleIds) {
          ref.invalidate(scheduleBookingsProvider(scheduleId));
        }
      } else {
        state = const AsyncValue.data(null);
      }

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deduct subscription for a booking
  Future<GroupClassBooking> deductSubscription(String bookingId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);
      final updated = await repository.deductSubscription(bookingId);

      state = AsyncValue.data(updated);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Auto-cancel all waitlist entries for a schedule (when class starts)
  Future<List<GroupClassBooking>> autoCancelWaitlist(String scheduleId) async {
    try {
      final repository = ref.read(groupClassBookingRepositoryProvider);
      final cancelled = await repository.autoCancelWaitlist(scheduleId);

      // Invalidate related providers
      ref.invalidate(scheduleBookingsProvider(scheduleId));
      ref.invalidate(scheduleWaitlistProvider(scheduleId));
      ref.invalidate(scheduleWaitlistCountProvider(scheduleId));

      // Send notifications to cancelled students
      for (final booking in cancelled) {
        _sendAutoCancelNotification(booking);
      }

      return cancelled;
    } catch (e) {
      debugPrint('[GroupClassBookingNotifier] Failed to auto-cancel waitlist: $e');
      rethrow;
    }
  }

  void _sendAutoCancelNotification(GroupClassBooking booking) {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final notification = AppNotification(
        id: 'waitlist_autocancelled_${DateTime.now().millisecondsSinceEpoch}',
        userId: booking.studentId,
        type: NotificationType.lessonCancelled,
        priority: NotificationPriority.normal,
        title: '⏳ 대기 자동 취소',
        body: '수업이 시작되어 대기가 자동 취소되었습니다. 다음 기회를 기다려주세요.',
        createdAt: DateTime.now(),
        data: {
          'bookingId': booking.id,
          'scheduleId': booking.scheduleId,
          'type': 'waitlist_auto_cancel',
        },
      );
      notificationService.showNotification(notification);
    } catch (e) {
      debugPrint('[GroupClassBookingNotifier] Failed to send auto-cancel notification: $e');
    }
  }
}
