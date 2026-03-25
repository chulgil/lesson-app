import 'package:flutter/material.dart';
import '../features/schedule/domain/entities/lesson_booking.dart';
import '../features/schedule/domain/entities/time_slot.dart';

/// Repository interface for lesson booking management
abstract class BookingRepository {
  // Booking queries
  Future<List<LessonBooking>> getAllBookings();
  Future<List<LessonBooking>> getBookingsByTeacher(String teacherId);
  Future<List<LessonBooking>> getBookingsByStudent(String studentId);
  Future<List<LessonBooking>> getBookingsByStatus(BookingStatus status);
  Future<List<LessonBooking>> getPendingBookings(String teacherId);
  Future<LessonBooking?> getBookingById(String id);

  // Trial lesson operations
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    required int fee,
  });
  Future<LessonBooking> approveTrialLesson(String id, {String? selectedOptionId});

  // Regular lesson request (student-initiated, pending approval)
  Future<LessonBooking> requestRegularLesson({
    required String teacherId,
    required String teacherName,
    required RegularLessonRequest request,
    int monthlyFee = 200000,
  });

  Future<LessonBooking> markUnavailable(
    String id,
    UnavailableReason reason, {
    List<TimeSlot>? suggestedTimeSlots,
  });

  // Regular lesson operations
  Future<LessonBooking> registerRegularLesson({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required RegularLessonRegistration registration,
  });

  // Booking management
  Future<LessonBooking> updateBooking(LessonBooking booking);
  Future<LessonBooking> cancelBooking(String id, String? reason);
  Future<LessonBooking> completeLesson(String id);
  Future<void> deleteBooking(String id);

  // Availability
  Future<List<TimeSlot>> getTeacherAvailability(String teacherId);
  Future<List<DateTime>> getAvailableDates(
      String teacherId, DateTime from, DateTime to);
  Future<List<TimeSlot>> getAvailableTimeSlotsForDate(
      String teacherId, DateTime date);
}

/// Mock implementation of BookingRepository
class MockBookingRepository implements BookingRepository {
  List<LessonBooking> _bookings = [];

  MockBookingRepository() {
    final now = DateTime.now();

    _bookings = [
      // Pending trial lesson request for student_1 (current user)
      LessonBooking(
        id: 'booking_1',
        teacherId: 'teacher_1',
        teacherName: '김선생',
        studentId: 'student_1',
        studentName: '홍길동',
        instrument: '바이올린',
        lessonType: LessonType.trial,
        status: BookingStatus.pending,
        lessonDate: now.add(const Duration(days: 3)),
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        fee: 30000,
        studentPhone: '010-1234-5678',
        studentEmail: 'hong@example.com',
        lessonGoal: LessonGoal.hobby,
        experienceLevel: ExperienceLevel.none,
        studentMessage: '바이올린을 처음 배워보고 싶습니다.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      // Confirmed trial lesson for student_1 (different teacher)
      LessonBooking(
        id: 'booking_2',
        teacherId: 'teacher_2',
        teacherName: '박선생',
        studentId: 'student_1',
        studentName: '홍길동',
        instrument: '피아노',
        lessonType: LessonType.trial,
        status: BookingStatus.confirmed,
        lessonDate: now.add(const Duration(days: 1)),
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        fee: 30000,
        studentPhone: '010-2345-6789',
        lessonGoal: LessonGoal.hobby,
        experienceLevel: ExperienceLevel.beginner,
        createdAt: now.subtract(const Duration(days: 3)),
        confirmedAt: now.subtract(const Duration(days: 2)),
      ),
      // Completed trial lesson
      LessonBooking(
        id: 'booking_3',
        teacherId: 'teacher_1',
        teacherName: '김선생',
        studentId: 'student_2',
        studentName: '이준호',
        lessonType: LessonType.trial,
        status: BookingStatus.completed,
        lessonDate: now.subtract(const Duration(days: 5)),
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        fee: 30000,
        lessonGoal: LessonGoal.exam,
        experienceLevel: ExperienceLevel.some,
        createdAt: now.subtract(const Duration(days: 10)),
        confirmedAt: now.subtract(const Duration(days: 8)),
        completedAt: now.subtract(const Duration(days: 5)),
      ),
      // Regular lesson - fixed schedule
      LessonBooking(
        id: 'booking_4',
        teacherId: 'teacher_1',
        teacherName: '김선생',
        studentId: 'student_2',
        studentName: '이준호',
        lessonType: LessonType.regular,
        status: BookingStatus.confirmed,
        lessonDate: _getNextDayOfWeek(now, DateTime.wednesday),
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        fee: 200000,
        scheduleType: ScheduleType.fixed,
        fixedTimeSlot: TimeSlot(
          id: 'slot_1',
          dayOfWeek: DateTime.wednesday,
          startTime: const TimeOfDay(hour: 18, minute: 0),
          endTime: const TimeOfDay(hour: 19, minute: 0),
        ),
        createdAt: now.subtract(const Duration(days: 4)),
        confirmedAt: now.subtract(const Duration(days: 3)),
      ),
      // Pending trial - another student
      LessonBooking(
        id: 'booking_5',
        teacherId: 'teacher_1',
        teacherName: '김선생',
        studentName: '박민수',
        lessonType: LessonType.trial,
        status: BookingStatus.pending,
        lessonDate: now.add(const Duration(days: 5)),
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        fee: 30000,
        studentPhone: '010-9876-5432',
        lessonGoal: LessonGoal.major,
        experienceLevel: ExperienceLevel.experienced,
        studentMessage: '전공 준비를 위해 레슨 받고 싶습니다.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      // Change requested trial lesson for student_1
      LessonBooking(
        id: 'booking_6',
        teacherId: 'teacher_3',
        teacherName: '이선생',
        studentId: 'student_1',
        studentName: '홍길동',
        instrument: '첼로',
        lessonType: LessonType.trial,
        status: BookingStatus.changeRequested,
        lessonDate: now.add(const Duration(days: 4)),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        fee: 35000,
        studentPhone: '010-1234-5678',
        lessonGoal: LessonGoal.hobby,
        experienceLevel: ExperienceLevel.none,
        createdAt: now.subtract(const Duration(days: 2)),
        confirmedAt: now.subtract(const Duration(days: 1)),
        // Change request details
        requestedDate: now.add(const Duration(days: 7)),
        requestedStartTime: const TimeOfDay(hour: 14, minute: 0),
        requestedEndTime: const TimeOfDay(hour: 15, minute: 0),
        changeRequestedAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  // Helper to get next day of week
  static DateTime _getNextDayOfWeek(DateTime from, int dayOfWeek) {
    int daysUntil = (dayOfWeek - from.weekday) % 7;
    if (daysUntil == 0) daysUntil = 7;
    return from.add(Duration(days: daysUntil));
  }

  @override
  Future<List<LessonBooking>> getAllBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_bookings)
      ..sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
  }

  @override
  Future<List<LessonBooking>> getBookingsByTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings
        .where((b) => b.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
  }

  @override
  Future<List<LessonBooking>> getBookingsByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings
        .where((b) => b.studentId == studentId)
        .toList()
      ..sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
  }

  @override
  Future<List<LessonBooking>> getBookingsByStatus(BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings.where((b) => b.status == status).toList();
  }

  @override
  Future<List<LessonBooking>> getPendingBookings(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings
        .where((b) =>
            b.teacherId == teacherId && b.status == BookingStatus.pending)
        .toList()
      ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));
  }

  @override
  Future<LessonBooking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    required int fee,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final booking = request.toBooking(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      teacherName: teacherName,
      fee: fee,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<LessonBooking> approveTrialLesson(String id, {String? selectedOptionId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw Exception('Booking not found');
    }

    var booking = _bookings[index];

    // If selectedOptionId is provided and the booking has schedule options,
    // update the lesson date/time from the selected option
    if (selectedOptionId != null && booking.hasScheduleOptions) {
      final selectedOption = booking.scheduleOptions?.firstWhere(
        (o) => o.id == selectedOptionId,
        orElse: () => booking.scheduleOptions!.first,
      );
      if (selectedOption != null && selectedOption.date != null) {
        booking = booking.copyWith(
          lessonDate: selectedOption.date,
          startTime: selectedOption.startTime,
          endTime: selectedOption.endTime,
          selectedOptionId: selectedOptionId,
        );
      }
    }

    final updated = booking.copyWith(
      status: BookingStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<LessonBooking> requestRegularLesson({
    required String teacherId,
    required String teacherName,
    required RegularLessonRequest request,
    int monthlyFee = 200000,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final booking = request.toBooking(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      teacherName: teacherName,
      monthlyFee: monthlyFee,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<LessonBooking> markUnavailable(
    String id,
    UnavailableReason reason, {
    List<TimeSlot>? suggestedTimeSlots,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw Exception('Booking not found');
    }
    final updated = _bookings[index].copyWith(
      status: BookingStatus.unavailable,
      unavailableReason: reason,
      suggestedTimeSlots: suggestedTimeSlots,
      unavailableAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<LessonBooking> registerRegularLesson({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required RegularLessonRegistration registration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final startTime = registration.fixedTimeSlot?.startTime ??
        const TimeOfDay(hour: 14, minute: 0);
    final endTime = registration.fixedTimeSlot?.endTime ??
        const TimeOfDay(hour: 15, minute: 0);

    final booking = LessonBooking(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: studentId,
      studentName: studentName,
      lessonType: LessonType.regular,
      status: BookingStatus.confirmed,
      lessonDate: registration.startDate,
      startTime: startTime,
      endTime: endTime,
      fee: registration.monthlyFee,
      scheduleType: registration.scheduleType,
      fixedTimeSlot: registration.fixedTimeSlot,
      createdAt: DateTime.now(),
      confirmedAt: DateTime.now(),
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<LessonBooking> updateBooking(LessonBooking booking) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) {
      throw Exception('Booking not found');
    }
    _bookings[index] = booking;
    return booking;
  }

  @override
  Future<LessonBooking> cancelBooking(String id, String? reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw Exception('Booking not found');
    }
    final updated = _bookings[index].copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<LessonBooking> completeLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw Exception('Booking not found');
    }
    final updated = _bookings[index].copyWith(
      status: BookingStatus.completed,
      completedAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteBooking(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _bookings.removeWhere((b) => b.id == id);
  }

  @override
  Future<List<TimeSlot>> getTeacherAvailability(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Return default time slots for now
    return getDefaultTimeSlots();
  }

  @override
  Future<List<DateTime>> getAvailableDates(
    String teacherId,
    DateTime from,
    DateTime to,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Return available dates (exclude weekends and already booked)
    final dates = <DateTime>[];
    var current = from;
    while (current.isBefore(to) || current.isAtSameMomentAs(to)) {
      // Exclude Sundays
      if (current.weekday != DateTime.sunday) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  @override
  Future<List<TimeSlot>> getAvailableTimeSlotsForDate(
    String teacherId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Get default time slots for the day of week
    final allSlots = getDefaultTimeSlots();
    final daySlot = allSlots.where((s) => s.dayOfWeek == date.weekday).toList();

    // Filter out already booked times
    final bookedTimes = _bookings
        .where((b) =>
            b.teacherId == teacherId &&
            b.lessonDate.year == date.year &&
            b.lessonDate.month == date.month &&
            b.lessonDate.day == date.day &&
            b.status.isActive)
        .map((b) => b.startTime)
        .toList();

    // Generate 1-hour time slots
    final availableSlots = <TimeSlot>[];
    for (final slot in daySlot) {
      var hour = slot.startTime.hour;
      while (hour < slot.endTime.hour) {
        final slotStart = TimeOfDay(hour: hour, minute: 0);
        if (!bookedTimes.any((t) => t.hour == hour)) {
          availableSlots.add(TimeSlot(
            id: 'slot_${date.toIso8601String()}_$hour',
            dayOfWeek: date.weekday,
            startTime: slotStart,
            endTime: TimeOfDay(hour: hour + 1, minute: 0),
          ));
        }
        hour++;
      }
    }
    return availableSlots;
  }
}
