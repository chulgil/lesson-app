import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/utils/instrument_colors.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/timeline_lesson_block.dart';

/// H7 (Hyen UX 표준) — 일간 타임라인의 완료 블록 뮤트 회귀 가드.
///
/// 리스트 뷰(LessonCard)는 완료·취소 행의 글자를 inkQuaternary 로 물리고
/// 좌측 상태 바는 그대로 둔다. 같은 레슨이 뷰마다 다른 상태로 보이면 안 되므로
/// (ux-rules #17 멀티 뷰 색상 일관성) 타임라인도 같은 규칙을 따라야 한다.
void main() {
  const instrument = '바이올린';

  Lesson buildLesson({required LessonStatus status, required DateTime date}) {
    return Lesson(
      id: 'lesson-1',
      studentId: 'student-1',
      studentName: '박지호',
      instrument: instrument,
      date: date,
      startTime: '10:00',
      duration: 60,
      status: status,
      assignments: const ['크로이처 2번'],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Future<void> pumpBlock(WidgetTester tester, Lesson lesson) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(children: [TimelineLessonBlock(lesson: lesson)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 본문 1행 "이름  악기  N분" 의 잉크 색. 악기명으로 이 줄을 특정한다
  /// (이름은 NameUtils.givenName 으로 축약되므로 finder 앵커로 부적합).
  Color? bodyInk(WidgetTester tester) {
    final text = tester.widget<Text>(find.textContaining(instrument));
    return text.style?.color;
  }

  /// 좌측 3px 세로선(_AccentBar) 의 색.
  Color? accentBarColor(WidgetTester tester) {
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.constraints?.maxWidth == 3);
    expect(bars, hasLength(1), reason: '좌측 3px accent bar 를 찾지 못했다');
    return bars.single.color;
  }

  final pastDate = DateTime.now().subtract(const Duration(days: 1));
  // displayStatus 는 종료 시각이 지난 scheduled 레슨을 completed 로 투영한다.
  // "예정" 을 보장하려면 종료 시각이 미래여야 한다.
  final futureDate = DateTime.now().add(const Duration(days: 7));

  testWidgets('완료 레슨 — 본문 잉크가 inkQuaternary 로 물러난다', (tester) async {
    await pumpBlock(
      tester,
      buildLesson(status: LessonStatus.completed, date: pastDate),
    );

    expect(bodyInk(tester), AppColors.inkQuaternary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('취소 레슨 — 완료와 같은 규칙으로 물러난다', (tester) async {
    await pumpBlock(
      tester,
      buildLesson(status: LessonStatus.cancelledByTeacher, date: pastDate),
    );

    expect(bodyInk(tester), AppColors.inkQuaternary);
  });

  testWidgets('예정 레슨 — 뮤트되지 않고 악기 잉크를 유지한다', (tester) async {
    await pumpBlock(
      tester,
      buildLesson(status: LessonStatus.scheduled, date: futureDate),
    );

    expect(bodyInk(tester), InstrumentColors.getColor(instrument).accent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('완료 레슨 — 좌측 상태 바는 악기 잉크를 유지한다 (채워진 게이지)', (tester) async {
    await pumpBlock(
      tester,
      buildLesson(status: LessonStatus.completed, date: pastDate),
    );

    expect(
      accentBarColor(tester),
      InstrumentColors.getColor(instrument).accent,
    );
  });
}
