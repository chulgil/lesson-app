// Group class booking repository interface
// Handles bookings, waitlist, and automatic promotion

import '../entities/group_class_booking.dart';

/// Repository for managing group class bookings and waitlist
abstract class GroupClassBookingRepository {
  // ============================================================
  // CRUD Operations
  // ============================================================

  /// Get all bookings for a schedule
  Future<List<GroupClassBooking>> getBookingsForSchedule(String scheduleId);

  /// Get all bookings for a student
  Future<List<GroupClassBooking>> getBookingsForStudent(String studentId);

  /// Get a specific booking by ID
  Future<GroupClassBooking?> getBookingById(String bookingId);

  /// Get booking for a specific student and schedule
  Future<GroupClassBooking?> getBooking(String scheduleId, String studentId);

  // ============================================================
  // Booking Operations
  // ============================================================

  /// Create a new booking (confirmed or waitlist based on availability)
  /// Returns the created booking with appropriate status
  Future<GroupClassBooking> createBooking({
    required String scheduleId,
    required String studentId,
    String? subscriptionId,
  });

  /// Cancel a booking
  /// If the cancelled booking was confirmed, automatically promotes waitlist
  Future<GroupClassBooking> cancelBooking(
    String bookingId, {
    String? reason,
  });

  // ============================================================
  // Waitlist Operations
  // ============================================================

  /// Get waitlist for a schedule (ordered by position)
  Future<List<GroupClassBooking>> getWaitlist(String scheduleId);

  /// Get waitlist position for a student
  Future<int?> getWaitlistPosition(String scheduleId, String studentId);

  /// Promote the first waitlist member to confirmed
  /// Called automatically when a confirmed booking is cancelled
  Future<GroupClassBooking?> promoteFromWaitlist(String scheduleId);

  /// Auto-cancel all waitlist entries for a schedule
  /// Called when class starts
  Future<List<GroupClassBooking>> autoCancelWaitlist(String scheduleId);

  // ============================================================
  // Attendance Operations
  // ============================================================

  /// Mark attendance for a booking
  Future<GroupClassBooking> markAttendance(
    String bookingId, {
    required bool attended,
  });

  /// Mark attendance for multiple bookings (batch)
  Future<List<GroupClassBooking>> markBatchAttendance(
    Map<String, bool> bookingAttendance, // bookingId -> attended
  );

  /// Deduct subscription for attended bookings
  Future<GroupClassBooking> deductSubscription(String bookingId);

  // ============================================================
  // Query Operations
  // ============================================================

  /// Get confirmed bookings count for a schedule
  Future<int> getConfirmedCount(String scheduleId);

  /// Get waitlist count for a schedule
  Future<int> getWaitlistCount(String scheduleId);

  /// Check if a student has a booking (any status) for a schedule
  Future<bool> hasBooking(String scheduleId, String studentId);

  /// Get active bookings for a student (confirmed or waitlist)
  Future<List<GroupClassBooking>> getActiveBookingsForStudent(String studentId);

  /// Get upcoming bookings for a student
  Future<List<GroupClassBooking>> getUpcomingBookingsForStudent(
    String studentId,
  );
}
