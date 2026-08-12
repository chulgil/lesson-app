import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../../../core/booking/repositories/booking_repository.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../core/booking/entities/time_slot.dart';

/// Remote implementation of [BookingRepository] using FastAPI backend.
class RemoteBookingRepository implements BookingRepository {
  final ApiClient _apiClient;

  RemoteBookingRepository(this._apiClient);

  // --- Query methods ---

  @override
  Future<List<LessonBooking>> getAllBookings() async {
    final response = await _apiClient.get('/bookings');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _bookingFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonBooking>> getBookingsByTeacher(String teacherId) async {
    final response = await _apiClient.get(
      '/bookings',
      queryParameters: {'teacher_id': teacherId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _bookingFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonBooking>> getBookingsByStudent(String studentId) async {
    final response = await _apiClient.get(
      '/bookings',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _bookingFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonBooking>> getBookingsByStatus(BookingStatus status) async {
    final response = await _apiClient.get(
      '/bookings',
      queryParameters: {'status': status.name},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _bookingFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonBooking>> getPendingBookings(String teacherId) async {
    final response = await _apiClient.get(
      '/bookings',
      queryParameters: {'teacher_id': teacherId, 'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _bookingFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<LessonBooking?> getBookingById(String id) async {
    final response = await _apiClient.get('/bookings/$id');
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  // --- Trial lesson operations ---

  @override
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    required int fee,
    String? subscriptionId,
  }) async {
    final response = await _apiClient.post(
      '/bookings',
      data: {
        'teacher_id': teacherId,
        'lesson_type': 'trial',
        'student_id': request.studentId,
        'student_name': request.studentName,
        'student_phone': request.studentPhone,
        'student_email': request.studentEmail,
        'lesson_goal': request.goal.name,
        'experience_level': request.experience.name,
        'message': request.message,
        'lesson_date': request.effectiveDate.toIso8601String(),
        'start_time': _clockTimeToString(request.effectiveStartTime),
        'end_time': _clockTimeToString(request.effectiveEndTime),
        'fee': fee,
        'subscription_id': subscriptionId,
      },
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonBooking> approveTrialLesson(
    String id, {
    String? selectedOptionId,
  }) async {
    final response = await _apiClient.patch(
      '/bookings/$id/approve',
      data: selectedOptionId != null
          ? {'selected_option_id': selectedOptionId}
          : null,
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  // --- Regular lesson operations ---

  @override
  Future<LessonBooking> requestRegularLesson({
    required String teacherId,
    required String teacherName,
    required RegularLessonRequest request,
    int monthlyFee = 200000,
  }) async {
    final response = await _apiClient.post(
      '/bookings',
      data: {
        'teacher_id': teacherId,
        'lesson_type': 'regular',
        'student_id': request.studentId,
        'student_name': request.studentName,
        'student_phone': request.studentPhone,
        'student_email': request.studentEmail,
        'lessons_per_week': request.lessonsPerWeek,
        'preferred_start_date': request.preferredStartDate.toIso8601String(),
        'message': request.message,
        'fee': monthlyFee,
      },
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonBooking> markUnavailable(
    String id,
    String reason, {
    List<TimeSlot>? suggestedTimeSlots,
  }) async {
    final response = await _apiClient.patch(
      '/bookings/$id/reject',
      data: {'reason': reason},
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonBooking> registerRegularLesson({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required RegularLessonRegistration registration,
  }) async {
    final response = await _apiClient.post(
      '/bookings',
      data: {
        'teacher_id': teacherId,
        'lesson_type': 'regular',
        'student_id': studentId,
        'student_name': studentName,
        'schedule_type': registration.scheduleType.name,
        'lessons_per_week': registration.lessonsPerWeek,
        'start_date': registration.startDate.toIso8601String().split('T').first,
        'fixed_time_slots': registration.fixedTimeSlots
            .map(
              (slot) => {
                'day_of_week':
                    slot.dayOfWeek - 1, // FE 1=Mon..7=Sun -> BE 0=Mon..6=Sun
                'start_time': slot.startTime.format24Hour(),
                'duration_minutes': slot.durationMinutes,
              },
            )
            .toList(),
        'fee': registration.monthlyFee,
      },
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  // --- Booking management ---

  @override
  Future<LessonBooking> updateBooking(LessonBooking booking) async {
    final response = await _apiClient.put(
      '/bookings/${booking.id}',
      data: _bookingToJson(booking),
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonBooking> cancelBooking(String id, String? reason) async {
    final response = await _apiClient.patch(
      '/bookings/$id/cancel',
      data: {'reason': reason},
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonBooking> completeLesson(String id) async {
    final response = await _apiClient.patch(
      '/bookings/$id/approve',
      data: {'status': 'completed'},
    );
    return _bookingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBooking(String id) async {
    await _apiClient.delete('/bookings/$id');
  }

  // --- Availability ---

  @override
  Future<List<TimeSlot>> getTeacherAvailability(String teacherId) async {
    final response = await _apiClient.get(
      '/schedule/slots',
      queryParameters: {'teacher_id': teacherId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => _timeSlotFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DateTime>> getAvailableDates(
    String teacherId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _apiClient.get(
      '/schedule/slots',
      queryParameters: {
        'teacher_id': teacherId,
        'date_from': from.toIso8601String().split('T')[0],
        'date_to': to.toIso8601String().split('T')[0],
      },
    );
    final items = response.data['dates'] as List<dynamic>? ?? [];
    return items.map((e) => DateTime.parse(e as String)).toList();
  }

  @override
  Future<List<TimeSlot>> getAvailableTimeSlotsForDate(
    String teacherId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _apiClient.get(
      '/schedule/slots',
      queryParameters: {'teacher_id': teacherId, 'date': dateStr},
    );
    final data = response.data;
    final items =
        (data is Map
            ? data['slots'] as List<dynamic>?
            : data as List<dynamic>?) ??
        [];
    return items
        .map((e) => _timeSlotFromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Manual JSON helpers (LessonBooking has no @JsonSerializable) ---

  static String _clockTimeToString(ClockTime time) => time.format24Hour();

  static ClockTime _clockTimeFromString(String time) => ClockTime.parse(time);

  static LessonBooking _bookingFromJson(Map<String, dynamic> json) {
    return LessonBooking(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String? ?? '',
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String? ?? '',
      instrument: json['instrument'] as String?,
      lessonType: LessonType.values.byName(
        json['lesson_type'] as String? ?? 'trial',
      ),
      status: BookingStatus.values.byName(
        json['status'] as String? ?? 'pending',
      ),
      lessonDate: DateTime.parse(json['lesson_date'] as String),
      startTime: _clockTimeFromString(json['start_time'] as String? ?? '14:00'),
      endTime: _clockTimeFromString(json['end_time'] as String? ?? '15:00'),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      fee: json['fee'] as int? ?? 0,
      scheduleType: json['schedule_type'] != null
          ? ScheduleType.values.byName(json['schedule_type'] as String)
          : null,
      lessonsPerWeek: json['lessons_per_week'] as int?,
      recurringSkippedCount: json['recurring_skipped_count'] as int? ?? 0,
      studentPhone: json['student_phone'] as String?,
      studentEmail: json['student_email'] as String?,
      lessonGoal: json['lesson_goal'] != null
          ? LessonGoal.values.byName(json['lesson_goal'] as String)
          : null,
      experienceLevel: json['experience_level'] != null
          ? ExperienceLevel.values.byName(json['experience_level'] as String)
          : null,
      studentMessage: json['student_message'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      unavailableMessage: json['unavailable_reason'] as String?,
      unavailableAt: json['unavailable_at'] != null
          ? DateTime.parse(json['unavailable_at'] as String)
          : null,
      expiredAt: json['expired_at'] != null
          ? DateTime.parse(json['expired_at'] as String)
          : null,
      subscriptionId: json['subscription_id'] as String?,
    );
  }

  static Map<String, dynamic> _bookingToJson(LessonBooking booking) {
    return {
      'id': booking.id,
      'teacher_id': booking.teacherId,
      'teacher_name': booking.teacherName,
      'student_id': booking.studentId,
      'student_name': booking.studentName,
      'instrument': booking.instrument,
      'lesson_type': booking.lessonType.name,
      'status': booking.status.name,
      'lesson_date': booking.lessonDate.toIso8601String(),
      'start_time': _clockTimeToString(booking.startTime),
      'end_time': _clockTimeToString(booking.endTime),
      'duration_minutes': booking.durationMinutes,
      'fee': booking.fee,
      'schedule_type': booking.scheduleType?.name,
      'lessons_per_week': booking.lessonsPerWeek,
      'student_phone': booking.studentPhone,
      'student_email': booking.studentEmail,
      'lesson_goal': booking.lessonGoal?.name,
      'experience_level': booking.experienceLevel?.name,
      'student_message': booking.studentMessage,
      'subscription_id': booking.subscriptionId,
    };
  }

  static TimeSlot _timeSlotFromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      startTime: ClockTime.parse(json['start_time'] as String? ?? '09:00'),
      endTime: ClockTime.parse(json['end_time'] as String? ?? '18:00'),
    );
  }
}
