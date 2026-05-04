import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/alternative_time_grid.dart';

void main() {
  testWidgets('centers and doubles lesson and preferred labels in grid cells', (
    tester,
  ) async {
    final weekStart = DateTime(2026, 5, 4);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 360,
            child: AlternativeTimeGrid(
              weekStart: weekStart,
              lessons: [
                Lesson(
                  id: 'lesson_1',
                  studentId: 'student_1',
                  studentName: '김민수',
                  instrument: '피아노',
                  date: weekStart,
                  startTime: '09:00',
                  duration: 60,
                  createdAt: DateTime(2026, 5, 1),
                ),
              ],
              suggestedSlots: const <TimeSlot>[],
              highlightedSlot: PreferredTimeSlotHighlight(
                date: weekStart.add(const Duration(days: 1)),
                startMinutes: 9 * 60,
                endMinutes: 10 * 60,
              ),
              onEmptyCellTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expectedFontSize = (AppTypography.captionXSmall.fontSize ?? 10) * 2;

    final studentText = tester.widget<Text>(find.text('민수'));
    expect(studentText.textAlign, TextAlign.center);
    expect(studentText.style?.fontSize, expectedFontSize);
    expect(studentText.style?.fontFamily, NotebookTypography.hand.fontFamily);
    expect(studentText.strutStyle?.forceStrutHeight, isTrue);
    expect(studentText.textHeightBehavior?.applyHeightToFirstAscent, isFalse);
    expect(studentText.textHeightBehavior?.applyHeightToLastDescent, isFalse);
    expect(
      find.ancestor(of: find.text('민수'), matching: find.byType(Center)),
      findsOneWidget,
    );

    final preferredText = tester.widget<Text>(
      find.text(AppStrings.preferredSlotLabel),
    );
    expect(preferredText.textAlign, TextAlign.center);
    expect(preferredText.style?.fontSize, expectedFontSize);
    expect(
      find.ancestor(
        of: find.text(AppStrings.preferredSlotLabel),
        matching: find.byType(Center),
      ),
      findsOneWidget,
    );
  });

  testWidgets('scrolls to selected preferred slot when highlight changes', (
    tester,
  ) async {
    final weekStart = DateTime(2026, 5, 4);

    Widget buildGrid({PreferredTimeSlotHighlight? highlightedSlot}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: AlternativeTimeGrid(
              weekStart: weekStart,
              lessons: const <Lesson>[],
              suggestedSlots: const <TimeSlot>[],
              highlightedSlot: highlightedSlot,
              onEmptyCellTap: (_) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildGrid());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);

    await tester.pumpWidget(
      buildGrid(
        highlightedSlot: PreferredTimeSlotHighlight(
          date: weekStart.add(const Duration(days: 2)),
          startMinutes: 18 * 60,
          endMinutes: 19 * 60,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );
    expect(find.text(AppStrings.preferredSlotLabel), findsOneWidget);
  });

  testWidgets(
    'shows preferred label over lesson name when selected slot overlaps lesson',
    (tester) async {
      final weekStart = DateTime(2026, 5, 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 360,
              child: AlternativeTimeGrid(
                weekStart: weekStart,
                lessons: [
                  Lesson(
                    id: 'lesson_1',
                    studentId: 'student_1',
                    studentName: '김민수',
                    instrument: '피아노',
                    date: weekStart,
                    startTime: '09:00',
                    duration: 60,
                    createdAt: DateTime(2026, 5, 1),
                  ),
                ],
                suggestedSlots: const <TimeSlot>[],
                highlightedSlot: PreferredTimeSlotHighlight(
                  date: weekStart,
                  startMinutes: 9 * 60,
                  endMinutes: 10 * 60,
                ),
                onEmptyCellTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.preferredSlotLabel), findsOneWidget);
      expect(find.text('민수'), findsNothing);
    },
  );
}
