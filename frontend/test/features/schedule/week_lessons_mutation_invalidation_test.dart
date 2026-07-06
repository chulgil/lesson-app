import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';

/// #1141 회귀: 선생님 "레슨 추가"가 주간 그리드(weekLessonsProvider, keepAlive)에
/// 반영되지 않던 버그. add_lesson_screen 은 lessonsProvider 만 invalidate 했고,
/// weekLessonsProvider / weekLessonsWithPreviewProvider 는 lib 전체에서 한 번도
/// invalidate 되지 않아 그리드가 세션 내내 stale 했다. (read/write provider 분리)
///
/// 수정: weekLessonsProvider 가 중앙 CRUD 인 lessonsNotifierProvider 를 watch 하여
/// 모든 레슨 mutation(add/update/delete) 후 재요청되게 한다.
/// (RED: 수정 전엔 getLessonsByDateRange 호출 카운트가 1 에 머문다.)
class _CountingLessonRepo implements LessonRepository {
  final List<Lesson> _lessons = [];
  int rangeFetchCount = 0;

  @override
  Future<List<Lesson>> getLessons() async => List.unmodifiable(_lessons);

  @override
  Future<List<Lesson>> getLessonsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    rangeFetchCount++;
    return _lessons
        .where(
          (l) =>
              l.date.isAfter(start.subtract(const Duration(days: 1))) &&
              l.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    final saved = lesson.copyWith(id: 'srv_${_lessons.length}');
    _lessons.add(saved);
    return saved;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CountingLessonRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _CountingLessonRepo();
    container = ProviderContainer(
      overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Lesson makeLesson(DateTime date) => Lesson(
    id: '',
    studentId: 's1',
    studentName: '김민수',
    instrument: '바이올린',
    date: date,
    startTime: '14:00',
    duration: 60,
    status: LessonStatus.scheduled,
    createdAt: DateTime(2026, 1, 1),
  );

  test('레슨 추가 후 weekLessonsProvider 가 재요청되어 새 레슨이 그리드에 노출된다', () async {
    final weekStart = DateTime(2026, 4, 6); // 주 시작
    container.listen(
      weekLessonsProvider(weekStart),
      (_, _) {},
      fireImmediately: true,
    );
    await container.pump();
    final before = repo.rangeFetchCount;
    expect(before, 1);

    // 중앙 CRUD notifier 경유로 해당 주에 레슨 추가
    await container
        .read(lessonsNotifierProvider.notifier)
        .addLesson(makeLesson(DateTime(2026, 4, 8)));
    await container.pump();

    expect(
      repo.rangeFetchCount,
      greaterThan(before),
      reason:
          'weekLessonsProvider 가 lessonsNotifierProvider 를 watch 하여 재요청돼야 한다',
    );

    final week = await container.read(weekLessonsProvider(weekStart).future);
    expect(
      week.any((l) => l.date == DateTime(2026, 4, 8)),
      isTrue,
      reason: '추가한 레슨이 주간 그리드 데이터에 포함돼야 한다',
    );
  });
}
