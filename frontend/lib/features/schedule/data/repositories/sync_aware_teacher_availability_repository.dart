import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/repositories/teacher_availability_repository.dart';
import 'remote_teacher_availability_repository.dart';

/// Decorator that wraps [RemoteTeacherAvailabilityRepository] with offline
/// **write-queue** support ([MutationQueueHelper]).
///
/// Reads delegate straight to the remote repository — offline read fallback is
/// provided transparently at the HTTP layer by `ResponseCacheInterceptor`
/// (offline-first plan §3 option A; batch 1e 일원화 — the previous Hive
/// read-through cache layer was removed in favour of the single HTTP response
/// cache). Writes are queued when offline and replayed on reconnect.
class SyncAwareTeacherAvailabilityRepository
    implements TeacherAvailabilityRepository {
  SyncAwareTeacherAvailabilityRepository({
    required RemoteTeacherAvailabilityRepository remote,
    required MutationQueueHelper queue,
  }) : _remote = remote,
       _queue = queue;

  final RemoteTeacherAvailabilityRepository _remote;
  final MutationQueueHelper _queue;

  // --------------------------------------------------------------------------
  // Read methods — delegate to remote; HTTP response cache handles offline.
  // --------------------------------------------------------------------------

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) =>
      _remote.getAvailability(teacherId);

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) => _remote.getAvailableSlotsForDate(
    teacherId,
    date,
    currentStudentId: currentStudentId,
  );

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) => _remote.getAvailableSlotsForDateRange(
    teacherId,
    startDate,
    endDate,
    currentStudentId: currentStudentId,
  );

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) => _remote.getNextAvailableDates(
    teacherId,
    fromDate: fromDate,
    limit: limit,
  );

  @override
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) => _remote.getRecommendedSlots(teacherId, studentId, startDate, endDate);

  // --------------------------------------------------------------------------
  // Mutation methods — use MutationQueueHelper for offline support
  // --------------------------------------------------------------------------

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.saveAvailability(availability),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'PUT',
      path: '/schedule/availability',
      payload: availability.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => availability,
  );

  @override
  Future<void> deleteAvailability(String teacherId) =>
      _queue.executeVoidMutation(
        remoteCall: () => _remote.deleteAvailability(teacherId),
        queueCall: (syncService) => syncService.queueMutation(
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/availability',
          payload: {},
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.addWeeklySchedule(teacherId, schedule),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'POST',
      path: '/schedule/weekly',
      payload: schedule.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'addWeeklySchedule optimistic result not supported offline',
    ),
  );

  @override
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.updateWeeklySchedule(teacherId, schedule),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'PUT',
      path: '/schedule/weekly/${schedule.id}',
      payload: schedule.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'updateWeeklySchedule optimistic result not supported offline',
    ),
  );

  @override
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.removeWeeklySchedule(teacherId, scheduleId),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'DELETE',
      path: '/schedule/weekly/$scheduleId',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'removeWeeklySchedule optimistic result not supported offline',
    ),
  );

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.addException(teacherId, exception),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'POST',
      path: '/schedule/exceptions',
      payload: exception.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'addException optimistic result not supported offline',
    ),
  );

  @override
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.updateException(teacherId, exception),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'PUT',
      path: '/schedule/exceptions/${exception.id}',
      payload: exception.toJson(),
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'updateException optimistic result not supported offline',
    ),
  );

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.removeException(teacherId, exceptionId),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'DELETE',
      path: '/schedule/exceptions/$exceptionId',
      payload: {},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'removeException optimistic result not supported offline',
    ),
  );

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) => _queue.executeMutation(
    remoteCall: () => _remote.bookSlot(slotId, studentId, studentName),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'POST',
      path: '/schedule/slots/$slotId/book',
      payload: {'student_id': studentId, 'student_name': studentName},
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
    optimisticResult: () => throw UnimplementedError(
      'bookSlot optimistic result not supported offline',
    ),
  );

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) =>
      _queue.executeMutation(
        remoteCall: () => _remote.cancelBooking(slotId),
        queueCall: (syncService) => syncService.queueMutation(
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/slots/$slotId/booking',
          payload: {},
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
        optimisticResult: () => throw UnimplementedError(
          'cancelBooking optimistic result not supported offline',
        ),
      );

  @override
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    ClockTime time,
    bool isAvailable,
  ) => _queue.executeVoidMutation(
    remoteCall: () =>
        _remote.toggleTimeBlock(teacherId, date, time, isAvailable),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'PATCH',
      path: '/schedule/blocks/toggle',
      payload: {
        'teacher_id': teacherId,
        'date': date.toUtc().toIso8601String(),
        'time': time.toString(),
        'is_available': isAvailable,
      },
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<ClockTime> times,
    bool isAvailable,
  ) => _queue.executeVoidMutation(
    remoteCall: () =>
        _remote.setTimeBlocks(teacherId, date, times, isAvailable),
    queueCall: (syncService) => syncService.queueMutation(
      domain: 'schedule',
      httpMethod: 'PATCH',
      path: '/schedule/blocks/set',
      payload: {
        'teacher_id': teacherId,
        'date': date.toUtc().toIso8601String(),
        'times': times.map((t) => t.toString()).toList(),
        'is_available': isAvailable,
      },
      clientUpdatedAt: DateTime.now().toUtc(),
    ),
  );
}
