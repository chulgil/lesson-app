import 'package:dio/dio.dart';
import '../../../../core/domain/value_objects/clock_time.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
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
      final response = await _apiClient.get(
        '/schedule/availability/${Uri.encodeComponent(teacherId)}',
      );
      if (response.data == null) return null;
      return _availabilityFromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      // ApiClient converts DioException → ApiException, so the 404→null
      // branch must match ApiException (2026-06-12 — the previous
      // `on DioException` catch was dead code; first-time teachers got an
      // error instead of the empty-state defaults).
      if (e.statusCode == 404 || e.statusCode == 405) {
        return null;
      }
      rethrow;
    } on DioException catch (e) {
      // Defensive: raw Dio paths that bypass ApiClient's conversion.
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
    // 2026-06-12 — BE 응답은 GET 과 동일한 요약 포맷 (id 등 일부 필드
    // 없음) 일 수 있으므로 strict fromJson 대신 GET 과 같은 관대 파서를
    // 사용한다. strict 파싱 throw → notifier silent fail → "저장했는데
    // 적용 안 됨" 으로 보이는 회귀의 한 축.
    return _availabilityFromJson(response.data as Map<String, dynamic>);
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
    // Update availability with new schedule added.
    //
    // 2026-06-12 — 첫 설정 사용자 (BE 레코드 없음 → null) 는 throw 대신
    // 기본값 (50/10/60 — TeacherAvailability constructor defaults) 으로 새
    // availability 를 구성해 저장한다. BE PUT /schedule/availability 가
    // replace/upsert 이므로 신규 생성이 안전하다. split page 의
    // _ensureDefaults 가 기본값 화면을 보여주므로 첫 "시간대 추가" 가 곧
    // 첫 저장이 된다.
    final current =
        await getAvailability(teacherId) ??
        TeacherAvailability(
          id: '',
          teacherId: teacherId,
          createdAt: DateTime.now(),
        );
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
    ClockTime time,
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
    List<ClockTime> times,
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

  static TeacherAvailability _availabilityFromJson(Map<String, dynamic> json) {
    if (json['id'] != null && json['created_at'] != null) {
      return TeacherAvailability.fromJson(json);
    }

    final teacherId = json['teacher_id'] as String? ?? '';
    final createdAt =
        json['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(json['created_at'] as String);
    final schedules = <WeeklySchedule>[];

    final weeklySchedules = json['weekly_schedules'] as List<dynamic>?;
    if (weeklySchedules != null) {
      for (var index = 0; index < weeklySchedules.length; index++) {
        final schedule = weeklySchedules[index] as Map<String, dynamic>;
        schedules.add(
          WeeklySchedule(
            id:
                schedule['id'] as String? ??
                '${teacherId}_${schedule['day_of_week']}_$index',
            dayOfWeek: (schedule['day_of_week'] as num).toInt(),
            startTime: schedule['start_time'] as String,
            endTime: schedule['end_time'] as String,
            createdAt:
                schedule['created_at'] == null
                    ? createdAt
                    : DateTime.parse(schedule['created_at'] as String),
          ),
        );
      }
    } else {
      final availabilities = json['availabilities'] as List<dynamic>? ?? [];
      for (final dayAvailability in availabilities) {
        final day = dayAvailability as Map<String, dynamic>;
        final dayOfWeek = (day['day_of_week'] as num).toInt();
        final timeSlots = day['time_slots'] as List<dynamic>? ?? [];

        for (var index = 0; index < timeSlots.length; index++) {
          final slot = timeSlots[index] as Map<String, dynamic>;
          schedules.add(
            WeeklySchedule(
              id: '${teacherId}_${dayOfWeek}_$index',
              dayOfWeek: dayOfWeek,
              startTime: slot['start_time'] as String,
              endTime: slot['end_time'] as String,
              createdAt: createdAt,
            ),
          );
        }
      }
    }

    return TeacherAvailability(
      id: json['id'] as String? ?? 'availability_$teacherId',
      teacherId: teacherId,
      slotDurationMinutes:
          (json['slot_duration_minutes'] as num?)?.toInt() ?? 60,
      weeklySchedules: schedules,
      exceptions: const [],
      autoGenerateWeeks: (json['auto_generate_weeks'] as num?)?.toInt() ?? 4,
      createdAt: createdAt,
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
      slotStartInterval: (json['slot_start_interval'] as num?)?.toInt() ?? 30,
      breakTimeBetweenLessons:
          (json['break_time_between_lessons'] as num?)?.toInt() ?? 0,
      minBookingHours: (json['min_booking_hours'] as num?)?.toInt() ?? 24,
    );
  }

  static ClockTime _timeOfDayFromString(String time) {
    final parts = time.split(':');
    return ClockTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
