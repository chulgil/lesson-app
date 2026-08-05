import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/lesson_action_sheet.dart';

/// #1237 — 액션 시트 '레슨 완료' 는 상태 전이 엔드포인트로 가야 한다.
///
/// 이전 구현은 `updateLesson(copyWith(status: completed))` 였고, 백엔드
/// `LessonUpdate` 에 status 가 없어 200 OK 와 함께 조용히 버려졌다 (완료도
/// 차감도 발생하지 않음). 이 경로는 주간 그리드/타임라인의 고트래픽 진입점이다.
class _SpyLessonRepository extends MockLessonRepository {
  final List<LessonStatus> statusTransitions = [];
  final List<Lesson> entityUpdates = [];

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusTransitions.add(status);
    return lesson.copyWith(status: status);
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    entityUpdates.add(lesson);
    return lesson;
  }

  @override
  Future<List<Lesson>> getLessons() async => const [];
}

Lesson _lesson() => Lesson(
  id: 'lesson-1237',
  studentId: 'stu-1',
  studentName: '김민지',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: DateTime(2026, 8, 5),
  startTime: '10:00',
  status: LessonStatus.scheduled,
  subscriptionId: 'sub-1',
  createdAt: DateTime(2026, 8, 1),
);

void main() {
  late _SpyLessonRepository repo;

  setUp(() => repo = _SpyLessonRepository());

  testWidgets('완료 액션은 상태 전이 엔드포인트 1회, 엔티티 PUT 0회', (tester) async {
    final lesson = _lesson();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder:
                (context, ref, _) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => completeLessonFromActionSheet(
                            context,
                            ref,
                            lesson,
                          ),
                      child: const Text('complete'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('complete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.statusTransitions, [LessonStatus.completed]);
    expect(
      repo.entityUpdates,
      isEmpty,
      reason: '엔티티 PUT 은 status 를 반영하지 못한다 (백엔드 화이트리스트)',
    );
  });
}
