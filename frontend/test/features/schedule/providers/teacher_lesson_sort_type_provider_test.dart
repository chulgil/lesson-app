import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_tab_state_provider.dart';
import 'package:lessonaza/features/student_home/student_home_ui_facade.dart';

/// Waits until [provider]'s value satisfies [predicate], or times out.
///
/// [TeacherLessonSortType.build] persists via a fire-and-forget Hive load,
/// so the synchronous initial read is always the default; this drains that
/// microtask gap deterministically instead of relying on a fixed delay.
Future<T> _waitForState<T>(
  ProviderContainer container,
  ProviderListenable<T> provider,
  bool Function(T) predicate,
) async {
  final current = container.read(provider);
  if (predicate(current)) return current;
  final completer = Completer<T>();
  late final ProviderSubscription<T> sub;
  sub = container.listen<T>(provider, (previous, next) {
    if (predicate(next)) {
      completer.complete(next);
      sub.close();
    }
  });
  return completer.future.timeout(const Duration(seconds: 2));
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'teacher_lesson_sort_type_test',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ProviderContainer container({String userId = 'teacher_1'}) {
    final c = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => userId)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('첫 실행(persist 이력 없음)에는 시간순 기본값을 유지한다', () async {
    final c = container();
    expect(c.read(teacherLessonSortTypeProvider), LessonSortType.timeAsc);
    // Drain the fire-and-forget Hive load before the temp dir is torn down,
    // otherwise it fails writing to disk after this test has completed.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('선택한 정렬이 컨테이너 재생성(앱 재시작 시뮬레이션) 후에도 복원된다', () async {
    final c1 = container();
    await c1
        .read(teacherLessonSortTypeProvider.notifier)
        .setSortType(LessonSortType.nameAsc);

    final c2 = container();
    final restored = await _waitForState(
      c2,
      teacherLessonSortTypeProvider,
      (type) => type == LessonSortType.nameAsc,
    );
    expect(restored, LessonSortType.nameAsc);
  });

  test('다른 teacherId 는 저장된 선택과 독립적으로 기본값을 유지한다', () async {
    final teacherA = container(userId: 'teacher_a');
    await teacherA
        .read(teacherLessonSortTypeProvider.notifier)
        .setSortType(LessonSortType.nameAsc);

    final teacherB = container(userId: 'teacher_b');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      teacherB.read(teacherLessonSortTypeProvider),
      LessonSortType.timeAsc,
    );
  });
}
