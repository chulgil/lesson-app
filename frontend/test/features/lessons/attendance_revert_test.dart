import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/attendance_section.dart';

/// #1240 — 완료 오탭 복구 진입점.
///
/// 이전에는 처리된 레슨에 차감 결과 칩만 보여 복구 수단이 전혀 없었고, 백엔드도
/// 차감 반전 로직이 없어 학생 회차가 영구히 소모됐다.
class _SpyLessonRepository extends MockLessonRepository {
  final List<LessonStatus> statusTransitions = [];

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusTransitions.add(status);
    return lesson.copyWith(status: status);
  }

  @override
  Future<List<Lesson>> getLessons() async => const [];
}

Lesson _lesson(LessonStatus status) => Lesson(
  id: 'lesson-1240',
  studentId: 'stu-1',
  studentName: '김민지',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: DateTime(2026, 8, 4),
  startTime: '10:00',
  status: status,
  subscriptionId: 'sub-1',
  createdAt: DateTime(2026, 8, 1),
);

void main() {
  late _SpyLessonRepository repo;

  setUp(() => repo = _SpyLessonRepository());

  Future<void> pumpSection(WidgetTester tester, LessonStatus status) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AttendanceSection(lesson: _lesson(status), isTeacher: true),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('완료된 레슨에 되돌리기 진입점이 보인다', (tester) async {
    await pumpSection(tester, LessonStatus.completed);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.attendanceRevertAction), findsOneWidget);
  });

  testWidgets('되돌리기 확인 → 예정 상태 전이 1회', (tester) async {
    await pumpSection(tester, LessonStatus.completed);

    await tester.tap(find.text(AppStrings.attendanceRevertAction));
    await tester.pumpAndSettle();

    // 확인 다이얼로그는 차감 복구를 고지한다.
    expect(find.text(AppStrings.attendanceRevertDialogMessage), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, AppStrings.attendanceRevertAction).last,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.statusTransitions, [LessonStatus.scheduled]);
  });

  testWidgets('되돌리기 취소 시 아무 전이도 일어나지 않는다', (tester) async {
    await pumpSection(tester, LessonStatus.completed);

    await tester.tap(find.text(AppStrings.attendanceRevertAction));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.cancel));
    await tester.pumpAndSettle();

    expect(repo.statusTransitions, isEmpty);
  });

  testWidgets('예정 상태 레슨에는 되돌리기가 없다 (회귀)', (tester) async {
    await pumpSection(tester, LessonStatus.scheduled);

    expect(find.text(AppStrings.attendanceRevertAction), findsNothing);
  });
}
