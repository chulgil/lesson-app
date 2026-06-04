import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/repertoire_timeline.dart';
import 'package:lessonaza/features/practice/presentation/widgets/history/repertoire_history_timeline.dart';

void main() {
  PracticeRecording recording(String id) => PracticeRecording(
    id: id,
    sectionId: 's',
    filePath: '/tmp/$id.wav',
    durationSeconds: 30,
    createdAt: DateTime(2026, 3, 1),
  );

  PracticeSection section({
    String id = 's',
    bool isCompleted = false,
    List<PracticeRecording> recordings = const [],
  }) {
    return PracticeSection(
      id: id,
      repertoireId: 'rep',
      pieceName: 'piece',
      startMeasure: 1,
      endMeasure: 4,
      isCompleted: isCompleted,
      recordings: recordings,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  PracticeRepertoire repertoire({
    required String id,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    bool isArchived = false,
    List<PracticeSection> sections = const [],
  }) {
    return PracticeRepertoire(
      id: id,
      studentId: 'student-1',
      name: name,
      startDate: startDate,
      endDate: endDate,
      isArchived: isArchived,
      sections: sections,
      createdAt: startDate,
    );
  }

  Future<void> pumpTimeline(
    WidgetTester tester,
    RepertoireTimeline timeline,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: RepertoireHistoryTimeline(timeline: timeline)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders summary card with totals', (tester) async {
    final timeline = RepertoireTimeline(
      repertoires: [
        repertoire(id: 'r1', name: 'Sonatina', startDate: DateTime(2026, 3, 1)),
        repertoire(
          id: 'r2',
          name: 'Etude No. 1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 28),
        ),
      ],
    );

    await pumpTimeline(tester, timeline);

    expect(tester.takeException(), isNull);
    // 1 ongoing, 1 completed
    expect(find.text(AppStrings.practiceTotalLabel), findsOneWidget);
    expect(find.text('2곡'), findsOneWidget);
    expect(find.text('Sonatina'), findsOneWidget);
    expect(find.text('Etude No. 1'), findsOneWidget);
  });

  testWidgets('groups entries by start month, newest first', (tester) async {
    final timeline = RepertoireTimeline(
      repertoires: [
        repertoire(
          id: 'old',
          name: 'Old Piece',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 1),
        ),
        repertoire(
          id: 'new',
          name: 'New Piece',
          startDate: DateTime(2026, 5, 1),
        ),
      ],
    );

    await pumpTimeline(tester, timeline);

    expect(tester.takeException(), isNull);
    expect(find.text('2026년 5월'), findsOneWidget);
    expect(find.text('2026년 1월'), findsOneWidget);

    final newTopOffset = tester.getTopLeft(find.text('New Piece')).dy;
    final oldTopOffset = tester.getTopLeft(find.text('Old Piece')).dy;
    expect(newTopOffset, lessThan(oldTopOffset));
  });

  testWidgets('renders status badges for each lifecycle state', (tester) async {
    final timeline = RepertoireTimeline(
      repertoires: [
        repertoire(
          id: 'ongoing',
          name: 'Ongoing',
          startDate: DateTime(2026, 5, 1),
        ),
        repertoire(
          id: 'done',
          name: 'Done',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 20),
        ),
        repertoire(
          id: 'arch',
          name: 'Archived',
          startDate: DateTime(2026, 5, 1),
          isArchived: true,
        ),
      ],
    );

    await pumpTimeline(tester, timeline);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.practiceInProgress), findsWidgets);
    expect(find.text(AppStrings.practiceCompletedLabel), findsWidgets);
    expect(find.text(AppStrings.archiveButton), findsOneWidget);
  });

  testWidgets('survives in narrow viewport without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final timeline = RepertoireTimeline(
      repertoires: [
        repertoire(
          id: 'a',
          name:
              'A very long repertoire title that should not overflow horizontally',
          startDate: DateTime(2026, 4, 1),
          sections: [
            section(id: 's1', recordings: [recording('rec1')]),
          ],
        ),
      ],
    );

    await pumpTimeline(tester, timeline);

    expect(tester.takeException(), isNull);
  });
}
