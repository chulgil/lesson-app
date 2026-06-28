import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/widgets/section_detail/section_recordings_section.dart';

void main() {
  // C1: empty placeholder uses EmptyStateWidget (greedy Center). It is rendered
  // inside section_detail_screen's SingleChildScrollView (unbounded height), so
  // it must be height-bounded or it throws "RenderBox was given infinite size".
  testWidgets(
    'SectionRecordingsSection empty placeholder renders in unbounded scroll (C1)',
    (tester) async {
      final section = PracticeSection(
        id: 'section_1',
        repertoireId: 'repertoire_1',
        pieceName: 'Canon',
        startMeasure: 1,
        endMeasure: 8,
        recordings: const [],
        createdAt: DateTime(2026, 5, 7),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SectionRecordingsSection(
                section: section,
                repertoireId: 'repertoire_1',
                recordings: const [],
                onSetRepresentative: (_) {},
                onDelete: (_) {},
                onPlay: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.sectionRecordingEmptyTitle), findsOneWidget);
    },
  );
}
