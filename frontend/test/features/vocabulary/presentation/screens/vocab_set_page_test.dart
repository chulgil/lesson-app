import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/presentation/screens/vocab_set_page.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final set = VocabSet(
    id: 's1',
    title: 'HSK4',
    createdAt: DateTime(2026, 7, 1),
  );

  late VocabHarness h;
  setUp(() async {
    h = VocabHarness();
    await h.start();
    await h.repo.saveSet(set);
  });
  tearDown(() => h.stop());

  for (final size in const [vocabMobile, vocabDesktop, vocabTall]) {
    final label = '@${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('empty card bank shows the add CTA $label', (tester) async {
      await pumpVocabAt(tester, size, h.wrap(VocabSetPage(set: set)));

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text(AppStrings.vocabCardsEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.vocabAddCardCta), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lists cards and surfaces the review CTA when due', (
    tester,
  ) async {
    await h.repo.saveCard(
      VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: '苹果',
        back: '사과',
        createdAt: DateTime(2026, 7, 1),
      ),
    );

    await pumpVocabAt(tester, vocabMobile, h.wrap(VocabSetPage(set: set)));

    expect(find.text('苹果'), findsOneWidget);
    expect(find.text('사과'), findsOneWidget);
    expect(find.textContaining(AppStrings.vocabReviewCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
