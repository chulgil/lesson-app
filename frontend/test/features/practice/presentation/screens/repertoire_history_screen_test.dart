import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/repertoire_timeline.dart';
import 'package:lessonaza/features/practice/presentation/providers/repertoire_history_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/repertoire_history_screen.dart';

void main() {
  const studentId = 'student-1';

  PracticeRepertoire repertoire({
    required String id,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    bool isArchived = false,
  }) {
    return PracticeRepertoire(
      id: id,
      studentId: studentId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isArchived: isArchived,
      createdAt: startDate,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Override override,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [override],
        child: const MaterialApp(
          home: RepertoireHistoryScreen(studentId: studentId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders timeline when data is available', (tester) async {
    final timeline = RepertoireTimeline(
      repertoires: [
        repertoire(
          id: 'r1',
          name: 'Mock Sonata',
          startDate: DateTime(2026, 3, 1),
        ),
      ],
    );

    await pumpScreen(
      tester,
      override: repertoireTimelineProvider(
        studentId,
      ).overrideWith((ref) async => timeline),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.practiceRepertoireHistoryTitle),
      findsOneWidget,
    );
    expect(find.text('Mock Sonata'), findsOneWidget);
  });

  testWidgets('renders empty state when totalCount is zero', (tester) async {
    final emptyTimeline = RepertoireTimeline(repertoires: const []);

    await pumpScreen(
      tester,
      override: repertoireTimelineProvider(
        studentId,
      ).overrideWith((ref) async => emptyTimeline),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.practiceRepertoireHistoryEmptyTitle),
      findsOneWidget,
    );
  });

  testWidgets('renders error state with retry button on failure', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      override: repertoireTimelineProvider(
        studentId,
      ).overrideWith((ref) async => throw Exception('boom')),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.errorOccurred), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
