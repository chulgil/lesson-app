import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/widgets/section_detail/completion_toggle.dart';

void main() {
  testWidgets('shows explicit teacher share hint', (tester) async {
    final section = PracticeSection(
      id: 'section_1',
      repertoireId: 'repertoire_1',
      pieceName: 'Canon',
      startMeasure: 1,
      endMeasure: 8,
      recordings: [
        PracticeRecording(
          id: 'recording_1',
          sectionId: 'section_1',
          filePath: '/tmp/recording.wav',
          durationSeconds: 42,
          isRepresentative: true,
          createdAt: DateTime(2026, 5, 7),
        ),
      ],
      createdAt: DateTime(2026, 5, 7),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletionToggle(section: section, onToggle: () {}),
        ),
      ),
    );

    expect(find.text(AppStrings.practiceJournalShareHint), findsOneWidget);
    expect(find.textContaining('공유됩니다'), findsNothing);
  });
}
