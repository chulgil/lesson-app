import 'package:flutter/material.dart';

import '../entities/availability_slot.dart';
import '../entities/teacher_availability.dart';

/// Repository interface for managing teacher availability
abstract class TeacherAvailabilityRepository {
  // ============================================================
  // Teacher Availability Settings
  // ============================================================

  /// Get teacher's availability settings
  Future<TeacherAvailability?> getAvailability(String teacherId);

  /// Create or update teacher's availability settings
  Future<TeacherAvailability> saveAvailability(TeacherAvailability availability);

  /// Delete teacher's availability settings
  Future<void> deleteAvailability(String teacherId);

  // ============================================================
  // Weekly Schedules
  // ============================================================

  /// Add a weekly schedule
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  );

  /// Update a weekly schedule
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  );

  /// Remove a weekly schedule
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  );

  // ============================================================
  // Time Exceptions (Holidays, Vacations)
  // ============================================================

  /// Add a time exception (holiday, vacation, etc.)
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  );

  /// Update a time exception
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  );

  /// Remove a time exception
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  );

  // ============================================================
  // Computed Slots
  // ============================================================

  /// Get available slots for a specific date
  ///
  /// Returns computed [AvailabilitySlot] list for the given date,
  /// taking into account weekly schedules, exceptions, and bookings.
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  });

  /// Get available slots for a date range
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  });

  /// Get next available dates (for empty state suggestions)
  ///
  /// Returns up to [limit] dates after [fromDate] that have available slots.
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  });

  /// Get recommended slots for a student
  ///
  /// Returns slots that match the student's usual lesson times
  /// (same day of week and time from recent lessons).
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );

  // ============================================================
  // Booking Operations
  // ============================================================

  /// Book a slot for a student
  ///
  /// Returns the updated slot with booked status.
  /// Throws if slot is no longer available.
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  );

  /// Cancel a booking
  Future<AvailabilitySlot> cancelBooking(String slotId);

  // ============================================================
  // Block Grid Operations (Teacher Management)
  // ============================================================

  /// Toggle availability for a specific time block
  ///
  /// Used by teacher's block grid UI to toggle individual time slots.
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    TimeOfDay time,
    bool isAvailable,
  );

  /// Set availability for multiple time blocks at once
  ///
  /// Used for drag selection in block grid UI.
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<TimeOfDay> times,
    bool isAvailable,
  );
}
