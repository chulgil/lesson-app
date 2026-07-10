import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/data/repositories/sync_aware_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:mocktail/mocktail.dart';

/// Batch 1e (일원화): the SyncAware teacher-availability repository no longer
/// owns a Hive read-through cache. Reads delegate straight to remote (offline
/// fallback is the HTTP response cache — see teacher_availability_offline_read_test.dart);
/// writes keep the offline mutation queue. These tests cover both.

class MockRemoteTeacherAvailabilityRepository extends Mock
    implements RemoteTeacherAvailabilityRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

TeacherAvailability _testAvailability({String teacherId = 'teacher-1'}) {
  return TeacherAvailability(
    id: 'avail-$teacherId',
    teacherId: teacherId,
    slotDurationMinutes: 60,
    weeklySchedules: const [],
    exceptions: const [],
    autoGenerateWeeks: 4,
    createdAt: DateTime(2026, 5, 9),
    slotStartInterval: 60,
    breakTimeBetweenLessons: 0,
    minBookingHours: 24,
  );
}

WeeklySchedule _testSchedule({String id = 'sched-1'}) {
  return WeeklySchedule(
    id: id,
    dayOfWeek: 1,
    startTime: '10:00',
    endTime: '12:00',
    createdAt: DateTime(2026, 5, 9),
  );
}

TimeException _testException({String id = 'exc-1'}) {
  return TimeException(
    id: id,
    type: ExceptionType.holiday,
    startDate: DateTime(2026, 5, 9),
    endDate: DateTime(2026, 5, 9),
    createdAt: DateTime(2026, 5, 9),
  );
}

SyncQueueEntry _fakeEntry() {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'entry-1',
    domain: 'schedule',
    operation: SyncOperationType.create,
    httpMethod: 'PUT',
    path: '/schedule/availability',
    payload: const {},
    queryParameters: const {},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockRemoteTeacherAvailabilityRepository remote;
  late MockConnectivityService connectivity;
  late MockSyncService syncService;
  late SyncAwareTeacherAvailabilityRepository repo;

  setUpAll(() {
    registerFallbackValue(_fakeEntry());
    registerFallbackValue(_testAvailability());
  });

  setUp(() {
    remote = MockRemoteTeacherAvailabilityRepository();
    connectivity = MockConnectivityService();
    syncService = MockSyncService();

    repo = SyncAwareTeacherAvailabilityRepository(
      remote: remote,
      queue: MutationQueueHelper(
        connectivity: connectivity,
        syncService: syncService,
      ),
    );
  });

  void stubQueue() {
    when(
      () => syncService.queueMutation(
        idempotencyKey: any(named: 'idempotencyKey'),
        domain: any(named: 'domain'),
        httpMethod: any(named: 'httpMethod'),
        path: any(named: 'path'),
        payload: any(named: 'payload'),
        clientUpdatedAt: any(named: 'clientUpdatedAt'),
      ),
    ).thenAnswer((_) async => _fakeEntry());
  }

  // --------------------------------------------------------------------------
  // Read methods delegate to remote (no own cache)
  // --------------------------------------------------------------------------

  group('read methods delegate to remote', () {
    test('getAvailability', () async {
      final availability = _testAvailability();
      when(
        () => remote.getAvailability('teacher-1'),
      ).thenAnswer((_) async => availability);

      final result = await repo.getAvailability('teacher-1');
      expect(result, same(availability));
      verify(() => remote.getAvailability('teacher-1')).called(1);
    });

    test('getAvailability returns null straight from remote', () async {
      when(
        () => remote.getAvailability('teacher-new'),
      ).thenAnswer((_) async => null);

      final result = await repo.getAvailability('teacher-new');
      expect(result, isNull);
    });

    test(
      'getAvailability rethrows remote network error (no fallback)',
      () async {
        when(
          () => remote.getAvailability('teacher-x'),
        ).thenThrow(const NetworkException(message: 'timeout'));

        expect(
          () => repo.getAvailability('teacher-x'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('getAvailableSlotsForDate', () async {
      final date = DateTime(2026, 5, 9);
      when(
        () => remote.getAvailableSlotsForDate(
          'teacher-1',
          date,
          currentStudentId: null,
        ),
      ).thenAnswer((_) async => []);

      final result = await repo.getAvailableSlotsForDate('teacher-1', date);
      expect(result, isEmpty);
      verify(
        () => remote.getAvailableSlotsForDate(
          'teacher-1',
          date,
          currentStudentId: null,
        ),
      ).called(1);
    });

    test('getAvailableSlotsForDateRange', () async {
      final start = DateTime(2026, 5, 9);
      final end = DateTime(2026, 5, 16);
      when(
        () => remote.getAvailableSlotsForDateRange(
          'teacher-1',
          start,
          end,
          currentStudentId: 's1',
        ),
      ).thenAnswer((_) async => []);

      final result = await repo.getAvailableSlotsForDateRange(
        'teacher-1',
        start,
        end,
        currentStudentId: 's1',
      );
      expect(result, isEmpty);
    });

    test('getNextAvailableDates', () async {
      final from = DateTime(2026, 5, 9);
      when(
        () =>
            remote.getNextAvailableDates('teacher-1', fromDate: from, limit: 3),
      ).thenAnswer((_) async => [DateTime(2026, 5, 10)]);

      final result = await repo.getNextAvailableDates(
        'teacher-1',
        fromDate: from,
      );
      expect(result, hasLength(1));
    });

    test('getRecommendedSlots', () async {
      final start = DateTime(2026, 5, 9);
      final end = DateTime(2026, 5, 16);
      when(
        () => remote.getRecommendedSlots('teacher-1', 's1', start, end),
      ).thenAnswer((_) async => []);

      final result = await repo.getRecommendedSlots(
        'teacher-1',
        's1',
        start,
        end,
      );
      expect(result, isEmpty);
    });
  });

  // --------------------------------------------------------------------------
  // saveAvailability — write-queue
  // --------------------------------------------------------------------------

  group('saveAvailability', () {
    test('online: returns server entity', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      final availability = _testAvailability();
      final server = _testAvailability(teacherId: 'server');
      when(
        () => remote.saveAvailability(availability),
      ).thenAnswer((_) async => server);

      final result = await repo.saveAvailability(availability);
      expect(result.teacherId, equals('server'));
    });

    test('offline: queues PUT and returns optimistic input', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      stubQueue();

      final availability = _testAvailability();
      final result = await repo.saveAvailability(availability);
      expect(result.teacherId, equals('teacher-1'));
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'PUT',
          path: '/schedule/availability',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('NetworkException: falls back to queue', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.saveAvailability(any()),
      ).thenThrow(const NetworkException(message: 'timeout'));
      stubQueue();

      final result = await repo.saveAvailability(_testAvailability());
      expect(result.teacherId, equals('teacher-1'));
    });
  });

  // --------------------------------------------------------------------------
  // deleteAvailability — void write-queue
  // --------------------------------------------------------------------------

  group('deleteAvailability', () {
    test('online: delegates to remote', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.deleteAvailability('teacher-1'),
      ).thenAnswer((_) async {});

      await repo.deleteAvailability('teacher-1');
      verify(() => remote.deleteAvailability('teacher-1')).called(1);
    });

    test('offline: queues DELETE without throw', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      stubQueue();

      await repo.deleteAvailability('teacher-1');
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/availability',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  // --------------------------------------------------------------------------
  // Weekly schedule CRUD — write-queue paths
  // --------------------------------------------------------------------------

  group('weekly schedule writes queue correct paths offline', () {
    setUp(() {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      stubQueue();
    });

    test('addWeeklySchedule queues POST /schedule/weekly', () async {
      // Optimistic result is unsupported offline → the queue helper throws.
      await expectLater(
        repo.addWeeklySchedule('teacher-1', _testSchedule()),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'POST',
          path: '/schedule/weekly',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('updateWeeklySchedule queues PUT /schedule/weekly/{id}', () async {
      await expectLater(
        repo.updateWeeklySchedule('teacher-1', _testSchedule(id: 's9')),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'PUT',
          path: '/schedule/weekly/s9',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('removeWeeklySchedule queues DELETE /schedule/weekly/{id}', () async {
      await expectLater(
        repo.removeWeeklySchedule('teacher-1', 's9'),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/weekly/s9',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  // --------------------------------------------------------------------------
  // Exception CRUD — write-queue paths
  // --------------------------------------------------------------------------

  group('exception writes queue correct paths offline', () {
    setUp(() {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      stubQueue();
    });

    test('addException queues POST /schedule/exceptions', () async {
      await expectLater(
        repo.addException('teacher-1', _testException()),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'POST',
          path: '/schedule/exceptions',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('updateException queues PUT /schedule/exceptions/{id}', () async {
      await expectLater(
        repo.updateException('teacher-1', _testException(id: 'e9')),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'PUT',
          path: '/schedule/exceptions/e9',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('removeException queues DELETE /schedule/exceptions/{id}', () async {
      await expectLater(
        repo.removeException('teacher-1', 'e9'),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/exceptions/e9',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });

  // --------------------------------------------------------------------------
  // Booking + block grid — write-queue paths
  // --------------------------------------------------------------------------

  group('booking + block writes queue correct paths offline', () {
    setUp(() {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      stubQueue();
    });

    test('bookSlot queues POST /schedule/slots/{id}/book', () async {
      await expectLater(
        repo.bookSlot('slot-1', 's1', 'Alice'),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'POST',
          path: '/schedule/slots/slot-1/book',
          payload: {'student_id': 's1', 'student_name': 'Alice'},
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('cancelBooking queues DELETE /schedule/slots/{id}/booking', () async {
      await expectLater(
        repo.cancelBooking('slot-1'),
        throwsA(isA<UnimplementedError>()),
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'DELETE',
          path: '/schedule/slots/slot-1/booking',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('toggleTimeBlock queues PATCH /schedule/blocks/toggle', () async {
      await repo.toggleTimeBlock(
        'teacher-1',
        DateTime.utc(2026, 5, 9),
        const ClockTime(hour: 10, minute: 0),
        false,
      );
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'PATCH',
          path: '/schedule/blocks/toggle',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });

    test('setTimeBlocks queues PATCH /schedule/blocks/set', () async {
      await repo.setTimeBlocks('teacher-1', DateTime.utc(2026, 5, 9), const [
        ClockTime(hour: 10, minute: 0),
      ], false);
      verify(
        () => syncService.queueMutation(
          idempotencyKey: any(named: 'idempotencyKey'),
          domain: 'schedule',
          httpMethod: 'PATCH',
          path: '/schedule/blocks/set',
          payload: any(named: 'payload'),
          clientUpdatedAt: any(named: 'clientUpdatedAt'),
        ),
      ).called(1);
    });
  });
}
