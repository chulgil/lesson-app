// Regression test for #1255 — LessonCard's status label must come from the
// LessonStatusVisualX SSOT (lesson_visuals.dart), not a local duplicate that
// collapses distinct cancellation reasons into one generic "취소" label.
// The dashboard card previously showed AppStrings.statusCancelled for every
// cancellation, while the lesson/schedule screens showed the reason-specific
// label — a home↔detail drift.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/lesson_card.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/extensions/lesson_visuals.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

// LessonCard renders lesson.displayStatus, which auto-completes a raw
// `scheduled` status once its end time is in the past (lesson.dart). Cancelled
// statuses are returned as-is regardless of date, but the "scheduled" case
// needs a future date to stay scheduled rather than roll over to "completed".
Lesson _lesson({required LessonStatus status, DateTime? date}) {
  final lessonDate = date ?? DateTime(2026, 3, 1);
  return Lesson(
    id: 'lesson-1',
    studentId: 'student-1',
    studentName: '민지',
    instrument: '피아노',
    date: lessonDate,
    startTime: '14:00',
    status: status,
    createdAt: DateTime(2026, 3, 1),
  );
}

Future<void> _pumpCard(WidgetTester tester, Lesson lesson) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeActiveStudentMembershipsProvider(
          lesson.studentId,
        ).overrideWith((ref) async => const <ClassMembership>[]),
        homeActiveStudentSubscriptionsProvider(
          lesson.studentId,
        ).overrideWith((ref) async => const <Subscription>[]),
      ],
      child: MaterialApp(
        home: Scaffold(body: LessonCard(lesson: lesson, onTap: () {})),
      ),
    ),
  );
}

void main() {
  testWidgets('학생 사전취소 레슨은 SSOT 사유별 라벨을 보여준다 (일괄 "취소" 아님)', (tester) async {
    final lesson = _lesson(status: LessonStatus.cancelledByStudentAdvance);

    await _pumpCard(tester, lesson);
    await tester.pumpAndSettle();

    expect(
      find.text(LessonStatus.cancelledByStudentAdvance.label),
      findsOneWidget,
      reason: 'LessonCard 는 lesson_visuals.dart 의 SSOT label 을 사용해야 함',
    );
    // 예전 로컬 _getStatusLabel() 은 모든 취소 사유를 이 일반 라벨로 뭉갰다.
    expect(find.text(AppStrings.statusCancelled), findsNothing);
  });

  testWidgets('예정 레슨은 예정 라벨을 보여준다', (tester) async {
    final lesson = _lesson(
      status: LessonStatus.scheduled,
      date: DateTime.now().add(const Duration(days: 7)),
    );

    await _pumpCard(tester, lesson);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.statusUpcoming), findsOneWidget);
  });
}
