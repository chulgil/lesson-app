import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/presentation/screens/vocab_review_page.dart';
import 'package:lessonaza/features/vocabulary/presentation/widgets/flashcard_widget.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late VocabHarness h;
  setUp(() async {
    h = VocabHarness();
    await h.start();
  });
  tearDown(() => h.stop());

  Future<void> seedTwoDueCards() async {
    await h.repo.saveSet(
      VocabSet(id: 's1', title: 'A', createdAt: DateTime(2026, 7, 1)),
    );
    await h.repo.saveCard(
      VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: 'one',
        back: '하나',
        createdAt: DateTime(2026, 7, 1, 9, 0),
      ),
    );
    await h.repo.saveCard(
      VocabCard.create(
        id: 'c2',
        setId: 's1',
        front: 'two',
        back: '둘',
        createdAt: DateTime(2026, 7, 1, 9, 1),
      ),
    );
  }

  for (final size in const [vocabMobile, vocabDesktop, vocabTall]) {
    final label = '@${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('no due cards → empty complete state $label', (tester) async {
      await pumpVocabAt(tester, size, h.wrap(const VocabReviewPage()));

      expect(find.text(AppStrings.vocabReviewEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reveal then grade advances through the due queue', (
    tester,
  ) async {
    await seedTwoDueCards();

    await pumpVocabAt(
      tester,
      vocabMobile,
      h.wrap(const VocabReviewPage(setId: 's1')),
    );

    // First card, answer hidden.
    expect(find.text(AppStrings.vocabReviewProgress(1, 2)), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('하나'), findsNothing);

    // Tap to reveal → answer + grade bar appear.
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    expect(find.text('하나'), findsOneWidget);
    expect(find.text(AppStrings.vocabGradeGood), findsOneWidget);

    // Grade "good" → advance to the second card, answer hidden again.
    await tester.tap(find.text(AppStrings.vocabGradeGood));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.vocabReviewProgress(2, 2)), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('둘'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grading every card reaches the done state', (tester) async {
    await seedTwoDueCards();
    await pumpVocabAt(
      tester,
      vocabMobile,
      h.wrap(const VocabReviewPage(setId: 's1')),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(FlashcardWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.vocabGradeGood));
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.vocabReviewDoneTitle), findsOneWidget);
    expect(find.text(AppStrings.vocabReviewClose), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
