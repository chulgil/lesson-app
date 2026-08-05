import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';

/// Regression guard (2026-07-08 FE audit A2).
///
/// LessonsNotifier 의 update/delete/archive/cancel 이 notifier state 만 갱신하고
/// keepAlive lessonsProvider / lessonProvider(id) 를 무효화하지 않아, 이들을 watch
/// 하는 화면(레슨 상세 · 홈 대시보드)이 stale 되던 버그의 가드. #1141 은
/// weekLessonsProvider 만 patch 했다. fix(각 메서드의 ref.invalidate)를 되돌리면 RED.
Lesson _lesson({required String id, List<String> keyPoints = const []}) =>
    Lesson(
      id: id,
      studentId: 's1',
      studentName: '학생',
      instrument: '피아노',
      date: DateTime(2026),
      startTime: '14:00',
      createdAt: DateTime(2026),
      keyPoints: keyPoints,
    );

void main() {
  test('updateLesson 후 keepAlive lessonProvider(id) 가 갱신된다 (A2)', () async {
    final repo =
        _FakeLessonRepository()..seed(_lesson(id: 'l1', keyPoints: const ['원래']));
    final container = ProviderContainer(
      overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // 레슨 상세 화면이 lessonProvider(id) 를 watch 하는 상황 재현 (keepAlive 유지).
    final sub = container.listen(lessonProvider('l1'), (_, __) {});
    addTearDown(sub.close);
    expect(
      (await container.read(lessonProvider('l1').future))?.keyPoints,
      ['원래'],
    );

    await container
        .read(lessonsNotifierProvider.notifier)
        .updateLesson(_lesson(id: 'l1', keyPoints: const ['수정됨']));

    expect(
      (await container.read(lessonProvider('l1').future))?.keyPoints,
      ['수정됨'],
    );
  });

  test('addLesson 이 overflowMode 를 repository 까지 전달한다 (§2.6.2 배선)', () async {
    final repo = _FakeLessonRepository();
    final container = ProviderContainer(
      overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container
        .read(lessonsNotifierProvider.notifier)
        .addLesson(_lesson(id: 'l1'), overflowMode: 'makeup_credit');
    expect(repo.lastOverflowMode, 'makeup_credit');

    // 레거시 호출(파라미터 없음) → null 유지 (무언 보너스 하위 호환)
    await container.read(lessonsNotifierProvider.notifier).addLesson(_lesson(id: 'l2'));
    expect(repo.lastOverflowMode, isNull);
  });

  test('deleteLesson 후 keepAlive lessonsProvider 가 갱신된다 (A2)', () async {
    final repo = _FakeLessonRepository()..seed(_lesson(id: 'l1'));
    final container = ProviderContainer(
      overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(lessonsProvider, (_, __) {});
    addTearDown(sub.close);
    expect(await container.read(lessonsProvider.future), hasLength(1));

    await container.read(lessonsNotifierProvider.notifier).deleteLesson('l1');

    expect(await container.read(lessonsProvider.future), isEmpty);
  });
}

class _FakeLessonRepository implements LessonRepository {
  final List<Lesson> _lessons = [];
  String? lastOverflowMode;
  void seed(Lesson l) => _lessons.add(l);

  @override
  Future<List<Lesson>> getLessons() async => List.unmodifiable(_lessons);

  @override
  Future<Lesson?> getLesson(String id) async {
    for (final l in _lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async {
    lastOverflowMode = overflowMode;
    _lessons.add(lesson);
    return lesson;
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    final i = _lessons.indexWhere((l) => l.id == lesson.id);
    if (i != -1) _lessons[i] = lesson;
    return lesson;
  }

  @override
  Future<void> deleteLesson(String id) async {
    _lessons.removeWhere((l) => l.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
