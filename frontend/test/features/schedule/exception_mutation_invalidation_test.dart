import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';

/// M1 (0702 감사, #1074) 회귀: TimeExceptionScreen 본문은 read-only
/// `teacherAvailabilityProvider` 를 watch 하는데, 특수일정 추가/삭제는
/// `TeacherAvailabilityNotifier.addException/removeException` 경유이고
/// notifier 도 호출부도 read provider 를 invalidate 하지 않아 성공 후에도
/// 목록이 stale 했다 (#707 은 실패 피드백만 해결).
///
/// 이 테스트는 read provider 가 mutation 후 재요청(re-fetch)되는지를
/// 호출 카운트로 검증한다. (RED: invalidate 추가 전엔 카운트가 1 에 머문다.)
class _CountingAvailabilityRepo implements TeacherAvailabilityRepository {
  int availabilityFetchCount = 0;

  TeacherAvailability _availability() => TeacherAvailability(
    id: 'av1',
    teacherId: 't1',
    slotDurationMinutes: 60,
    slotStartInterval: 60,
    breakTimeBetweenLessons: 10,
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    availabilityFetchCount++;
    return _availability();
  }

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) async => _availability();

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) async => _availability();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TimeException _exception() => TimeException(
  id: 'ex1',
  type: ExceptionType.holiday,
  startDate: DateTime(2026, 7, 10),
  endDate: DateTime(2026, 7, 10),
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  late _CountingAvailabilityRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _CountingAvailabilityRepo();
    container = ProviderContainer(
      overrides: [
        teacherAvailabilityRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  /// read provider 를 alive 로 유지 + 초기 fetch 를 강제한다.
  Future<void> primeReadProvider() async {
    container.listen(teacherAvailabilityProvider('t1'), (_, _) {},
        fireImmediately: true);
    await container.pump();
  }

  test('addException 후 teacherAvailabilityProvider 가 재요청된다', () async {
    await primeReadProvider();
    expect(repo.availabilityFetchCount, 1);

    await container
        .read(teacherAvailabilityNotifierProvider('t1').notifier)
        .addException(_exception());
    await container.pump();

    expect(
      repo.availabilityFetchCount,
      2,
      reason: '특수일정 추가 후 read provider 가 refetch 되어야 목록이 갱신된다',
    );
  });

  test('removeException 후 teacherAvailabilityProvider 가 재요청된다', () async {
    await primeReadProvider();
    expect(repo.availabilityFetchCount, 1);

    await container
        .read(teacherAvailabilityNotifierProvider('t1').notifier)
        .removeException('ex1');
    await container.pump();

    expect(
      repo.availabilityFetchCount,
      2,
      reason: '특수일정 삭제 후 read provider 가 refetch 되어야 목록이 갱신된다',
    );
  });
}
