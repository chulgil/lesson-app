import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_repository_provider.dart';
import 'package:lessonaza/features/vocabulary/presentation/widgets/vocab_book_panel.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late VocabHarness h;
  setUp(() async {
    h = VocabHarness();
    await h.start();
  });
  tearDown(() => h.stop());

  for (final size in const [vocabMobile, vocabDesktop]) {
    final label = '@${size.width.toInt()}';

    testWidgets('empty: nothing-due summary + both nav buttons $label', (
      tester,
    ) async {
      await pumpVocabAt(tester, size, h.wrap(const VocabBookPanel()));

      expect(find.text(AppStrings.vocabNoDue), findsOneWidget);
      expect(find.text(AppStrings.vocabReviewCta), findsOneWidget);
      expect(find.text(AppStrings.vocabManageCta), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the due-waiting count when cards are due', (tester) async {
    await h.repo.saveSet(
      VocabSet(id: 's1', title: 'A', createdAt: DateTime(2026, 7, 1)),
    );
    await h.repo.saveCard(
      VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: 'x',
        back: 'y',
        createdAt: DateTime(2026, 7, 1),
      ),
    );

    await pumpVocabAt(tester, vocabMobile, h.wrap(const VocabBookPanel()));

    expect(find.text(AppStrings.vocabDueWaiting(1)), findsOneWidget);
    expect(find.text(AppStrings.vocabSetCount(1)), findsOneWidget);
  });

  testWidgets('resilient when the store errors', (tester) async {
    // The summary provider errors → the panel must fall back to "nothing due",
    // never crash.
    await pumpVocabAt(
      tester,
      vocabMobile,
      ProviderScope(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(ThrowingVocabRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: VocabBookPanel())),
      ),
    );

    expect(find.text(AppStrings.vocabNoDue), findsOneWidget);
    expect(find.text(AppStrings.vocabReviewCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
