import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/initial_pull_service.dart';
import 'package:lessonaza/features/lessons/data/repositories/remote_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/students/data/repositories/remote_student_repository.dart';
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
// Helpers
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

// ---------------------------------------------------------------------------
// Tests
//
// The service warms the HTTP response cache by calling the remote repository
// methods (ApiClient's ResponseCacheInterceptor persists the responses — see
// test/features/*/data/repositories/*_offline_read_test.dart for that path).
// These tests cover the service's own semantics: the user-scoped flag and
// the offline guard.
// ---------------------------------------------------------------------------

void main() {
  late MockRemoteLessonRepository remote;
  late MockRemoteStudentRepository remoteStudents;
  late MockRemoteTeacherAvailabilityRepository remoteAvailability;
  late MockConnectivityService connectivity;
  late InitialPullService service;
  const userId = 'teacher_test_001';

  setUp(() async {
    // Hive is still required for the user-scoped initial-pull flag box.
    await setUpTestHive();

    remote = MockRemoteLessonRepository();
    remoteStudents = MockRemoteStudentRepository();
    remoteAvailability = MockRemoteTeacherAvailabilityRepository();
    connectivity = MockConnectivityService();

    service = InitialPullService(
      remoteLessons: remote,
      remoteStudents: remoteStudents,
      remoteAvailability: remoteAvailability,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('InitialPullService', () {
    test('첫 로그인 시 lessons를 pull하여 응답 캐시를 웜업한다', () async {
      // Arrange — first login: no flag, online
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.getLessons(),
      ).thenAnswer((_) async => [_testLesson(id: 'l1'), _testLesson(id: 'l2')]);
      when(() => remoteStudents.getStudents()).thenAnswer((_) async => []);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      // Act
      await service.runIfNeeded(userId);

      // Assert — the repository call went out (interceptor caches it)
      verify(() => remote.getLessons()).called(1);
    });

    test('플래그가 세팅된 경우 두 번째 호출에서 pull을 건너뛴다', () async {
      // Arrange — set flag by running once successfully
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.getLessons()).thenAnswer((_) async => [_testLesson()]);
      when(() => remoteStudents.getStudents()).thenAnswer((_) async => []);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded(userId);
      verify(() => remote.getLessons()).called(1);

      // Act — second call, same user
      await service.runIfNeeded(userId);

      // Assert — remote NOT called a second time
      verifyNever(() => remote.getLessons());
    });

    test('오프라인 상태이면 pull을 건너뛰고 플래그를 세팅하지 않는다', () async {
      // Arrange — offline
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      // Act
      await service.runIfNeeded(userId);

      // Assert — remote never called
      verifyNever(() => remote.getLessons());
      verifyNever(() => remoteStudents.getStudents());
      verifyNever(() => remoteAvailability.getAvailability(any()));
    });

    test('오프라인 skip 후 다음 온라인 로그인에서 pull이 실행된다', () async {
      // Phase 1: offline
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      await service.runIfNeeded(userId);
      verifyNever(() => remote.getLessons());

      // Phase 2: online — same user, flag was NOT set during offline skip
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => remote.getLessons(),
      ).thenAnswer((_) async => [_testLesson(id: 'l-retry')]);
      when(() => remoteStudents.getStudents()).thenAnswer((_) async => []);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded(userId);

      verify(() => remote.getLessons()).called(1);
    });

    test('서로 다른 userId는 각자 독립된 플래그를 가진다', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.getLessons()).thenAnswer((_) async => [_testLesson()]);
      when(() => remoteStudents.getStudents()).thenAnswer((_) async => []);
      // Each userId uses its own flag key in getAvailability(userId)
      when(
        () => remoteAvailability.getAvailability(any()),
      ).thenAnswer((_) async => null);

      await service.runIfNeeded('user_A');
      await service.runIfNeeded('user_B');

      // Both users trigger a pull (each has their own flag)
      verify(() => remote.getLessons()).called(2);
    });

    test('remote 에러 발생 시 예외를 삼키고 플래그를 세팅하지 않는다', () async {
      // Arrange
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.getLessons()).thenThrow(Exception('network error'));
      when(() => remoteStudents.getStudents()).thenAnswer((_) async => []);
      when(
        () => remoteAvailability.getAvailability(userId),
      ).thenAnswer((_) async => null);

      // Act — should not throw
      await expectLater(service.runIfNeeded(userId), completes);

      // Assert — flag not set (lessons failed), so retry happens on next call
      when(
        () => remote.getLessons(),
      ).thenAnswer((_) async => [_testLesson(id: 'l-recovered')]);

      await service.runIfNeeded(userId);

      // First (failed) attempt + retry = 2 calls in total
      verify(() => remote.getLessons()).called(2);
    });
  });
}
