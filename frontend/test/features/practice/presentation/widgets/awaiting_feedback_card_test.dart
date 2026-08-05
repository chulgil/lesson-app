import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_item.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_item_providers.dart';
import 'package:lessonaza/features/practice/presentation/widgets/awaiting_feedback_card.dart';

PracticeItem _item(String id) => PracticeItem(
  id: id,
  lessonId: 'l',
  studentId: 's1',
  teacherId: 'teacher_1',
  type: PracticeType.repertoire,
  title: 'item $id',
  isCompleted: true,
  practiceCount: 1,
  completedAt: DateTime.now().subtract(const Duration(hours: 1)),
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
);

Widget _harness(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(home: Scaffold(body: AwaitingFeedbackCard())),
);

void main() {
  group('AwaitingFeedbackCard', () {
    testWidgets('shows badge with count when awaiting items exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith(
            (ref) async => [_item('a'), _item('b'), _item('c')],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.awaitingFeedbackTitle), findsOneWidget);
      expect(find.text(AppStrings.awaitingFeedbackBadge(3)), findsOneWidget);
    });

    testWidgets('hidden (SizedBox.shrink) when count is 0', (tester) async {
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith(
            (ref) async => <PracticeItem>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.awaitingFeedbackTitle), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('hidden while loading', (tester) async {
      // Never-completing future (no pending timer) keeps provider in loading.
      final never = Completer<List<PracticeItem>>();
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith((ref) => never.future),
        ]),
      );
      await tester.pump();

      expect(find.text(AppStrings.awaitingFeedbackTitle), findsNothing);
    });
  });
}
