// Minimal in-memory TeacherAvailabilityRepository for boot-migration tests.
//
// Only `getAvailability` and `saveAvailability` are exercised by the boot
// migration path; other methods throw to surface accidental usage.
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';

class FakeTeacherAvailabilityRepository
    implements TeacherAvailabilityRepository {
  FakeTeacherAvailabilityRepository({required TeacherAvailability initial})
    : _value = initial;

  TeacherAvailability _value;
  int readCount = 0;
  int writeCount = 0;

  TeacherAvailability get last => _value;

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    readCount++;
    return _value;
  }

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) async {
    writeCount++;
    _value = availability;
    return _value;
  }

  // ---- Unused by boot-migration ----

  @override
  Future<void> deleteAvailability(String teacherId) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) => throw UnimplementedError('not used by boot migration');

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) => throw UnimplementedError('not used by boot migration');

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) => throw UnimplementedError('not used by boot migration');

  @override
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) =>
      throw UnimplementedError('not used by boot migration');

  @override
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    ClockTime time,
    bool isAvailable,
  ) => throw UnimplementedError('not used by boot migration');

  @override
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<ClockTime> times,
    bool isAvailable,
  ) => throw UnimplementedError('not used by boot migration');
}
