import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/initial_pull_service.dart';
import 'package:lessonaza/features/lessons/data/local/lesson_cache_store.dart';
import 'package:lessonaza/features/lessons/data/repositories/remote_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/schedule/data/local/teacher_availability_cache_store.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/students/data/local/student_cache_store.dart';
import 'package:lessonaza/features/students/data/repositories/remote_student_repository.dart';
import 'package:lessonaza/features/students/domain/entities/entities.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockRemoteLessonRepository extends Mock
    implements RemoteLessonRepository {}

class MockRemoteStudentRepository extends Mock
    implements RemoteStudentRepository {}

class MockRemoteTeacherAvailabilityRepository extends Mock
    implements RemoteTeacherAvailabilityRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Lesson _testLesson({String id = 'lesson-1'}) {
  return Lesson(
    id: id,
    studentId: 'student-1',
    studentName: 'Test Student',
    teacherId: 'teacher-1',
    instrument: 'piano',
    date: DateTime(2026, 6, 1),
    startTime: '10:00',
    status: LessonStatus.scheduled,
    createdAt: DateTime(2026, 6, 1),
  );
}

Student _testStudent({String id = 'student-1'}) {
  return Student(
    id: id,
    name: 'Test Student',
    instrument: 'piano',
    status: StudentStatus.active,
    createdAt: DateTime(2026, 6, 1),
  );
}

TeacherAvailability _testAvailability({String teacherId = 'teacher-1'}) {
  return TeacherAvailability(
    id: 'avail-1',
    teacherId: teacherId,
    createdAt: DateTime(2026, 6, 1),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockRemoteLessonRepository remoteLessons;
  late MockRemoteStudentRepository remoteStudents;
  late MockRemoteTeacherAvailabilityRepository remoteAvailability;
  late MockConnectivityService connectivity;
  late LessonCacheStore lessonCache;
  late StudentCacheStore studentCache;
  late TeacherAvailabilityCacheStore availabilityCache;
  late InitialPullService service;
  const userId = 'teacher_test_001';

  setUp(() async {
    await setUpTestHive();

    final lessonBox = await Hive.openBox<String>(LessonCacheStore.boxName);
    final studentBox = await Hive.openBox<String>(StudentCacheStore.boxName);
    final availabilityBox = await Hive.openBox<String>(
      TeacherAvailabilityCacheStore.boxName,
    );

    remoteLessons = MockRemoteLessonRepository();
    remoteStudents = MockRemoteStudentRepository();
    remoteAvailability = MockRemoteTeacherAvailabilityRepository();
    connectivity = MockConnectivityService();

    lessonCache = LessonCacheStore(box: lessonBox);
    studentCache = StudentCacheStore(box: studentBox);
    availabilityCache = TeacherAvailabilityCacheStore(box: availabilityBox);

    service = InitialPullService(
      remoteLessons: remoteLessons,
      lessonCache: lessonCache,
      remoteStudents: remoteStudents,
      studentCache: studentCache,
      remoteAvailability: remoteAvailability,
      availabilityCache: availabilityCache,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('InitialPullService — multi-domain', () {
    test(
      '첫 로그인 시 lessons/students/availability 세 도메인을 pull하여 캐시에 시드한다',
      () async {
        // Arrange
        when(() => connectivity.isOnline).thenAnswer((_) async => true);
        when(
          () => remoteLessons.getLessons(),
        ).thenAnswer((_) async => [_testLesson(id: 'l1')]);
        when(
          () => remoteStudents.getStudents(),
        ).thenAnswer((_) async => [_testStudent(id: 's1')]);
        when(
          () => remoteAvailability.getAvailability(userId),
        ).thenAnswer((_) async => _testAvailability(teacherId: userId));

        // Pre-condition: all caches empty
        expect(lessonCache.getLessons(LessonCacheStore.keyAll()), isNull);
        expect(studentCache.getStudents(StudentCacheStore.keyAll()), isNull);
        expect(
          availabilityCache.getAvailability(
            TeacherAvailabilityCacheStore.keyAvailability(userId),
          ),
          isNull,
        );

        // Act
        await service.runIfNeeded(userId);

        // Assert — all three caches seeded
        expect(lessonCache.getLessons(LessonCacheStore.keyAll()), isNotNull);
        expect(
          lessonCache.getLessons(LessonCacheStore.keyAll())!.first.id,
          'l1',
        );

        expect(studentCache.getStudents(StudentCacheStore.keyAll()), isNotNull);
        expect(
          studentCache.getStudents(StudentCacheStore.keyAll())!.first.id,
          's1',
        );

        final av = availabilityCache.getAvailability(
          TeacherAvailabilityCacheStore.keyAvailability(userId),
        );
        expect(av, isNotNull);
        expect(av!.teacherId, userId);
      },
    );

    test('한 도메인(students) 실패해도 나머지 도메인 pull이 완료된다', () async {
      // Arrange — students throws, lessons and availability succeed
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remoteLessons.getLessons(),
      ).thenAnswer((_) async => [_testLesson(id: 'l-isolated')]);
      when(
        () => remoteStudents.getStudents(),
      ).thenThrow(Exception('students network error'));
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => _testAvailability(teacherId: userId));

      // Act — must not throw
      await expectLater(service.runIfNeeded(userId), completes);

      // Assert — lessons and availability are seeded despite students failure
      expect(
        lessonCache.getLessons(LessonCacheStore.keyAll()),
        isNotNull,
        reason: 'lessons cache should be seeded even when students fails',
      );
      final av = availabilityCache.getAvailability(
        TeacherAvailabilityCacheStore.keyAvailability(userId),
      );
      expect(av, isNotNull, reason: 'availability cache should be seeded');
    });

    test('부분 실패 시 플래그가 세팅되지 않아 다음 로그인에서 재시도한다', () async {
      // Arrange — students fails
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remoteLessons.getLessons(),
      ).thenAnswer((_) async => [_testLesson()]);
      when(
        () => remoteStudents.getStudents(),
      ).thenThrow(Exception('transient error'));
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded(userId);

      // Flag NOT set, so second call should re-attempt all domains
      when(
        () => remoteStudents.getStudents(),
      ).thenAnswer((_) async => [_testStudent(id: 's-retry')]);

      await service.runIfNeeded(userId);

      // Second call should have re-fetched students
      verify(() => remoteStudents.getStudents()).called(2);
    });

    test('전 도메인 성공 시 플래그가 세팅되어 재로그인 시 pull을 건너뛴다', () async {
      // Arrange
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remoteLessons.getLessons(),
      ).thenAnswer((_) async => [_testLesson()]);
      when(
        () => remoteStudents.getStudents(),
      ).thenAnswer((_) async => [_testStudent()]);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded(userId);

      // Second call — flag is set, no remote calls
      await service.runIfNeeded(userId);

      verify(() => remoteLessons.getLessons()).called(1);
      verify(() => remoteStudents.getStudents()).called(1);
      verify(() => remoteAvailability.getAvailability(userId)).called(1);
    });

    test('availability가 null(신규 선생님)이어도 성공으로 처리한다', () async {
      // Arrange — teacher has no availability set yet (404 → null)
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remoteLessons.getLessons(),
      ).thenAnswer((_) async => [_testLesson()]);
      when(
        () => remoteStudents.getStudents(),
      ).thenAnswer((_) async => [_testStudent()]);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded(userId);

      // Flag should be set (null availability is valid)
      // Verified by: second call makes no remote calls
      await service.runIfNeeded(userId);
      verify(() => remoteLessons.getLessons()).called(1);
    });
  });
}
