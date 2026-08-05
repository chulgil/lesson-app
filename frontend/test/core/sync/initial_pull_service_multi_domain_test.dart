import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/initial_pull_service.dart';
import 'package:lessonaza/features/lessons/data/repositories/remote_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
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
//
// Warming = calling the same remote repository methods the read path uses;
// the ResponseCacheInterceptor persists the responses (covered by
// test/features/*/data/repositories/*_offline_read_test.dart). These tests
// cover multi-domain orchestration: per-domain failure isolation and the
// all-domains-succeeded flag semantics.
// ---------------------------------------------------------------------------

void main() {
  late MockRemoteLessonRepository remoteLessons;
  late MockRemoteStudentRepository remoteStudents;
  late MockRemoteTeacherAvailabilityRepository remoteAvailability;
  late MockConnectivityService connectivity;
  late InitialPullService service;
  const userId = 'teacher_test_001';

  setUp(() async {
    // Hive is still required for the user-scoped initial-pull flag box.
    await setUpTestHive();

    remoteLessons = MockRemoteLessonRepository();
    remoteStudents = MockRemoteStudentRepository();
    remoteAvailability = MockRemoteTeacherAvailabilityRepository();
    connectivity = MockConnectivityService();

    service = InitialPullService(
      remoteLessons: remoteLessons,
      remoteStudents: remoteStudents,
      remoteAvailability: remoteAvailability,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('InitialPullService — multi-domain', () {
    test('첫 로그인 시 lessons/students/availability 세 도메인을 pull한다', () async {
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

      // Act
      await service.runIfNeeded(userId);

      // Assert — all three domains were pulled (interceptor caches each)
      verify(() => remoteLessons.getLessons()).called(1);
      verify(() => remoteStudents.getStudents()).called(1);
      verify(() => remoteAvailability.getAvailability(userId)).called(1);
    });

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

      // Assert — the other domains still completed their pull
      verify(() => remoteLessons.getLessons()).called(1);
      verify(() => remoteAvailability.getAvailability(userId)).called(1);
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
