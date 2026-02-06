// Mock implementation of GroupClassBookingRepository

import 'package:uuid/uuid.dart';

import '../../domain/entities/group_class_booking.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../../domain/repositories/group_class_booking_repository.dart';

class MockGroupClassBookingRepository implements GroupClassBookingRepository {
  final _uuid = const Uuid();

  // In-memory storage
  final Map<String, GroupClassBooking> _bookings = {};

  // Reference to schedule repository for capacity checks
  final Map<String, GroupClassSchedule> _schedules;

  // Callback for waitlist promotion notification
  final void Function(GroupClassBooking promoted)? onWaitlistPromotion;

  MockGroupClassBookingRepository({
    Map<String, GroupClassSchedule>? schedules,
    this.onWaitlistPromotion,
  }) : _schedules = schedules ?? {};

  /// Update schedule reference
  void updateSchedules(Map<String, GroupClassSchedule> schedules) {
    _schedules.clear();
    _schedules.addAll(schedules);
  }

  @override
  Future<List<GroupClassBooking>> getBookingsForSchedule(
      String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookings.values
        .where((b) => b.scheduleId == scheduleId && b.isActive)
        .toList();
  }

  @override
  Future<List<GroupClassBooking>> getBookingsForStudent(
      String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookings.values.where((b) => b.studentId == studentId).toList();
  }

  @override
  Future<GroupClassBooking?> getBookingById(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _bookings[bookingId];
  }

  @override
  Future<GroupClassBooking?> getBooking(
      String scheduleId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _bookings.values.firstWhere(
        (b) =>
            b.scheduleId == scheduleId &&
            b.studentId == studentId &&
            b.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GroupClassBooking> createBooking({
    required String scheduleId,
    required String studentId,
    String? subscriptionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Check if already has a booking
    final existing = await getBooking(scheduleId, studentId);
    if (existing != null) {
      throw Exception('이미 예약이 있습니다');
    }

    // Get schedule to check capacity
    final schedule = _schedules[scheduleId];
    if (schedule == null) {
      throw Exception('스케줄을 찾을 수 없습니다');
    }

    // Count current confirmed bookings
    final confirmedCount = await getConfirmedCount(scheduleId);
    final waitlistCount = await getWaitlistCount(scheduleId);

    GroupBookingStatus status;
    int? waitlistPosition;

    if (confirmedCount < schedule.maxCapacity) {
      // Can book directly
      status = GroupBookingStatus.confirmed;
    } else if (schedule.waitlistCapacity == null ||
        waitlistCount < schedule.waitlistCapacity!) {
      // Add to waitlist
      status = GroupBookingStatus.waitlist;
      waitlistPosition = waitlistCount + 1;
    } else {
      throw Exception('예약 및 대기자 명단이 가득 찼습니다');
    }

    final booking = GroupClassBooking(
      id: _uuid.v4(),
      scheduleId: scheduleId,
      studentId: studentId,
      subscriptionId: subscriptionId,
      status: status,
      waitlistPosition: waitlistPosition,
      createdAt: DateTime.now(),
    );

    _bookings[booking.id] = booking;
    return booking;
  }

  @override
  Future<GroupClassBooking> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final booking = _bookings[bookingId];
    if (booking == null) {
      throw Exception('예약을 찾을 수 없습니다');
    }

    final wasConfirmed = booking.status == GroupBookingStatus.confirmed;
    final scheduleId = booking.scheduleId;

    // Update booking status
    final cancelledBooking = booking.copyWith(
      status: GroupBookingStatus.cancelled,
      cancelReason: reason,
      cancelledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = cancelledBooking;

    // If was confirmed, promote from waitlist
    if (wasConfirmed) {
      final promoted = await promoteFromWaitlist(scheduleId);
      if (promoted != null && onWaitlistPromotion != null) {
        onWaitlistPromotion!(promoted);
      }
    } else if (booking.isOnWaitlist) {
      // Reorder waitlist positions
      await _reorderWaitlist(scheduleId);
    }

    return cancelledBooking;
  }

  @override
  Future<List<GroupClassBooking>> getWaitlist(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final waitlist = _bookings.values
        .where((b) =>
            b.scheduleId == scheduleId &&
            b.status == GroupBookingStatus.waitlist)
        .toList();

    // Sort by waitlist position
    waitlist.sort((a, b) =>
        (a.waitlistPosition ?? 999).compareTo(b.waitlistPosition ?? 999));

    return waitlist;
  }

  @override
  Future<int?> getWaitlistPosition(String scheduleId, String studentId) async {
    final booking = await getBooking(scheduleId, studentId);
    return booking?.waitlistPosition;
  }

  @override
  Future<GroupClassBooking?> promoteFromWaitlist(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final waitlist = await getWaitlist(scheduleId);
    if (waitlist.isEmpty) {
      return null;
    }

    // Get first in waitlist
    final toPromote = waitlist.first;

    // Promote to confirmed
    final promoted = toPromote.copyWith(
      status: GroupBookingStatus.confirmed,
      waitlistPosition: null,
      promotedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _bookings[promoted.id] = promoted;

    // Reorder remaining waitlist
    await _reorderWaitlist(scheduleId);

    return promoted;
  }

  @override
  Future<List<GroupClassBooking>> autoCancelWaitlist(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final waitlist = await getWaitlist(scheduleId);
    final cancelled = <GroupClassBooking>[];

    for (final booking in waitlist) {
      final autoCancelled = booking.copyWith(
        status: GroupBookingStatus.autoCancelled,
        cancelReason: '수업 시작으로 인한 자동 취소',
        cancelledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _bookings[autoCancelled.id] = autoCancelled;
      cancelled.add(autoCancelled);
    }

    return cancelled;
  }

  @override
  Future<GroupClassBooking> markAttendance(
    String bookingId, {
    required bool attended,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final booking = _bookings[bookingId];
    if (booking == null) {
      throw Exception('예약을 찾을 수 없습니다');
    }

    final updated = booking.copyWith(
      status: attended ? GroupBookingStatus.attended : GroupBookingStatus.noShow,
      attendedAt: attended ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = updated;

    return updated;
  }

  @override
  Future<List<GroupClassBooking>> markBatchAttendance(
    Map<String, bool> bookingAttendance,
  ) async {
    final results = <GroupClassBooking>[];

    for (final entry in bookingAttendance.entries) {
      final updated =
          await markAttendance(entry.key, attended: entry.value);
      results.add(updated);
    }

    return results;
  }

  @override
  Future<GroupClassBooking> deductSubscription(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final booking = _bookings[bookingId];
    if (booking == null) {
      throw Exception('예약을 찾을 수 없습니다');
    }

    final updated = booking.copyWith(
      subscriptionDeducted: true,
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = updated;

    return updated;
  }

  @override
  Future<int> getConfirmedCount(String scheduleId) async {
    return _bookings.values
        .where((b) =>
            b.scheduleId == scheduleId &&
            (b.status == GroupBookingStatus.confirmed ||
                b.status == GroupBookingStatus.attended))
        .length;
  }

  @override
  Future<int> getWaitlistCount(String scheduleId) async {
    return _bookings.values
        .where((b) =>
            b.scheduleId == scheduleId &&
            b.status == GroupBookingStatus.waitlist)
        .length;
  }

  @override
  Future<bool> hasBooking(String scheduleId, String studentId) async {
    final booking = await getBooking(scheduleId, studentId);
    return booking != null;
  }

  @override
  Future<List<GroupClassBooking>> getActiveBookingsForStudent(
      String studentId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _bookings.values
        .where((b) => b.studentId == studentId && b.isActive)
        .toList();
  }

  @override
  Future<List<GroupClassBooking>> getUpcomingBookingsForStudent(
    String studentId,
  ) async {
    // This would need to check against schedule start times
    // For now, just return active bookings
    return getActiveBookingsForStudent(studentId);
  }

  /// Reorder waitlist positions after a change
  Future<void> _reorderWaitlist(String scheduleId) async {
    final waitlist = _bookings.values
        .where((b) =>
            b.scheduleId == scheduleId &&
            b.status == GroupBookingStatus.waitlist)
        .toList();

    // Sort by creation time
    waitlist.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Update positions
    for (int i = 0; i < waitlist.length; i++) {
      final updated = waitlist[i].copyWith(
        waitlistPosition: i + 1,
        updatedAt: DateTime.now(),
      );
      _bookings[updated.id] = updated;
    }
  }

  // ============================================================
  // Test helpers
  // ============================================================

  /// Clear all bookings (for testing)
  void clearAll() {
    _bookings.clear();
  }

  /// Add mock booking directly (for testing)
  void addMockBooking(GroupClassBooking booking) {
    _bookings[booking.id] = booking;
  }
}
