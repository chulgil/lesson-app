import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/repositories/teacher_availability_repository.dart';

/// Remote implementation of [TeacherAvailabilityRepository] using FastAPI backend.
class RemoteTeacherAvailabilityRepository
    implements TeacherAvailabilityRepository {
  final ApiClient _apiClient;

  RemoteTeacherAvailabilityRepository(this._apiClient);

  // ============================================================
  // Teacher Availability Settings
  // ============================================================

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    try {
      final response = await _apiClient.get('/schedule/availability');
      if (response.data == null) return null;
      return TeacherAvailability.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // Return null (empty state) for 404 or unimplemented endpoints
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) async {
    final response = await _apiClient.put(
      '/schedule/availability',
      data: availability.toJson(),
    );
    return TeacherAvailability.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAvailability(String teacherId) async {
    await _apiClient.delete('/schedule/availability');
  }

  // ============================================================
  // Weekly Schedules
  // ============================================================

  @override
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) async {
    // Update availability with new schedule added
    final current = await getAvailability(teacherId);
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }
    final updated = current.copyWith(
      weeklySchedules: [...current.weeklySchedules, schedule],
      updatedAt: DateTime.now(),
    );
    return saveAvailability(updated);
  }

  @override
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) async {
    final current = await getAvailability(teacherId);
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }
    final schedules =
        current.weeklySchedules.map((s) {
          return s.id == schedule.id ? schedule : s;
        }).toList();
    final updated = current.copyWith(
      weeklySchedules: schedules,
      updatedAt: DateTime.now(),
    );
    return saveAvailability(updated);
  }

  @override
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  ) async {
    final current = await getAvailability(teacherId);
    if (current == null) {
      throw Exception('Availability not found for teacher: $teacherId');
    }
    final schedules =
        current.weeklySchedules.where((s) => s.id != scheduleId).toList();
    final updated = current.copyWith(
      weeklySchedules: schedules,
      updatedAt: DateTime.now(),
    );
    return saveAvailability(updated);
  }

  // ============================================================
  // Time Exceptions
  // ============================================================

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) async {
    await _apiClient.post('/schedule/exceptions', data: exception.toJson());
    // Re-fetch full availability after mutation
    final updated = await getAvailability(teacherId);
    return updated!;
  }

  @override
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  ) async {
    await _apiClient.put(
      '/schedule/exceptions/${exception.id}',
      data: exception.toJson(),
    );
    final updated = await getAvailability(teacherId);
    return updated!;
  }

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) async {
    await _apiClient.delete('/schedule/exceptions/$exceptionId');
    final updated = await getAvailability(teacherId);
    return updated!;
  }

  // ============================================================
  // Computed Slots
  // ============================================================

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.get(
        '/schedule/slots',
        queryParameters: {
          'teacher_id': teacherId,
          'date': dateStr,
          if (currentStudentId != null) 'student_id': currentStudentId,
        },
      );
      final data = response.data;
      final items =
          (data is Map
              ? data['slots'] as List<dynamic>?
              : data as List<dynamic>?) ??
          [];
      return items
          .map((e) => _slotFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async {
    final startStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    final response = await _apiClient.get(
      '/schedule/slots',
      queryParameters: {
        'teacher_id': teacherId,
        'date_from': startStr,
        'date_to': endStr,
        if (currentStudentId != null) 'student_id': currentStudentId,
      },
    );
    final data = response.data;
    final items =
        (data is Map
            ? data['slots'] as List<dynamic>?
            : data as List<dynamic>?) ??
        [];
    return items.map((e) => _slotFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) async {
    final dateStr =
        '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
    final response = await _apiClient.get(
      '/schedule/slots',
      queryParameters: {
        'teacher_id': teacherId,
        'date_from': dateStr,
        'limit': limit,
        'available_only': 'true',
      },
    );
    final data = response.data;
    final dates = (data is Map ? data['dates'] as List<dynamic>? : null) ?? [];
    return dates.map((e) => DateTime.parse(e as String)).toList();
  }

  @override
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final slots = await getAvailableSlotsForDateRange(
      teacherId,
      startDate,
      endDate,
      currentStudentId: studentId,
    );
    return slots.where((s) => s.isRecommended).toList();
  }

  // ============================================================
  // Booking Operations
  // ============================================================

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async {
    final response = await _apiClient.post(
      '/bookings',
      data: {
        'slot_id': slotId,
        'student_id': studentId,
        'student_name': studentName,
      },
    );
    return _slotFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) async {
    final response = await _apiClient.patch(
      '/bookings/$slotId/cancel',
      data: {'reason': 'slot_cancellation'},
    );
    return _slotFromJson(response.data as Map<String, dynamic>);
  }

  // ============================================================
  // Block Grid Operations
  // ============================================================

  @override
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    TimeOfDay time,
    bool isAvailable,
  ) async {
    if (isAvailable) {
      // Remove block exception
      final availability = await getAvailability(teacherId);
      if (availability != null) {
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        final exceptionsToRemove = availability.exceptions.where(
          (e) => e.containsDate(date) && e.startTime == timeStr,
        );
        for (final e in exceptionsToRemove) {
          await removeException(teacherId, e.id);
        }
      }
    } else {
      // Add block exception
      final exception = TimeException(
        id: '', // Server generates ID
        type: ExceptionType.holiday,
        startDate: date,
        endDate: date,
        startTime:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        reason: 'Manual block',
        createdAt: DateTime.now(),
      );
      await addException(teacherId, exception);
    }
  }

  @override
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<TimeOfDay> times,
    bool isAvailable,
  ) async {
    for (final time in times) {
      await toggleTimeBlock(teacherId, date, time, isAvailable);
    }
  }

  // --- JSON helpers for AvailabilitySlot (no @JsonSerializable) ---

  static AvailabilitySlot _slotFromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      startTime: _timeOfDayFromString(json['start_time'] as String? ?? '09:00'),
      endTime: _timeOfDayFromString(json['end_time'] as String? ?? '10:00'),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: _slotStatusFromString(json['status'] as String? ?? 'available'),
      bookedByStudentId: json['booked_by_student_id'] as String?,
      bookedByStudentName: json['booked_by_student_name'] as String?,
      lessonId: json['lesson_id'] as String?,
      isRecommended: json['is_recommended'] as bool? ?? false,
    );
  }

  static TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static AvailabilitySlotStatus _slotStatusFromString(String status) {
    switch (status) {
      case 'available':
        return AvailabilitySlotStatus.available;
      case 'booked':
        return AvailabilitySlotStatus.booked;
      case 'myBooking':
      case 'my_booking':
        return AvailabilitySlotStatus.myBooking;
      case 'cancelled':
        return AvailabilitySlotStatus.cancelled;
      case 'past':
        return AvailabilitySlotStatus.past;
      default:
        return AvailabilitySlotStatus.available;
    }
  }
}
