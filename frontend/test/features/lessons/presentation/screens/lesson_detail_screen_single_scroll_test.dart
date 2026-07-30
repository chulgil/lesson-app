// note-single-scroll — 레슨 노트/과제 2탭→단일 스크롤 통합 회귀 가드 (doc 41 §6.1).
//
// 탭바/TabBarView 가 사라지고, 노트 섹션과 과제 섹션이 하나의
// SingleChildScrollView 안에서 동시에 렌더되는지 확인한다. 두 섹션 헤더가
// 함께 발견되면 탭 전환 없이 스크롤만으로 둘 다 접근 가능하다는 증거다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_note_providers.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_widget_support_provider.dart';
import 'package:lessonaza/features/lessons/presentation/screens/lesson_detail_screen.dart';
import 'package:lessonaza/features/practice/practice_facade.dart'
    show PracticeItem;

const _lessonId = 'lesson_scroll_1';
const _studentId = 'student_scroll_1';

final _lesson = Lesson(
  id: _lessonId,
  studentId: _studentId,
  studentName: '학생 A',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: DateTime(2026, 7, 1),
  startTime: '15:00',
  status: LessonStatus.completed,
  feedback: '오늘은 스타카토 연습을 잘했어요.',
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pumpDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lessonProvider(_lessonId).overrideWith((ref) async => _lesson),
        studentLessonNotesProvider(
          _studentId,
        ).overrideWith((ref) async => <Lesson>[]),
        lessonWidgetPracticeItemsProvider(
          _lessonId,
        ).overrideWith((ref) => const AsyncValue.data(<PracticeItem>[])),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LessonDetailScreen(lessonId: _lessonId, isTeacher: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('노트+과제가 탭 없이 한 스크롤에 함께 렌더된다', (tester) async {
    await _pumpDetail(tester);

    expect(tester.takeException(), isNull);

    // 탭이 사라졌는지 확인 — 2탭→단일 스크롤 병합의 핵심 증거.
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);

    // 단일 스크롤 컨테이너 안에 두 섹션이 함께 존재.
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text(AppStrings.lessonNotesTab), findsOneWidget);
    expect(find.text(AppStrings.assignmentsTab), findsOneWidget);
  });
}
