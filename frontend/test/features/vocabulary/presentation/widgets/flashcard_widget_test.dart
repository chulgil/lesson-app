import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/presentation/widgets/flashcard_widget.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final card = VocabCard.create(
    id: 'c1',
    setId: 's1',
    front: 'apple',
    back: '사과',
    example: 'I ate an apple.',
    memo: '과일',
    createdAt: DateTime(2026, 1, 1),
  );

  Widget host(bool showAnswer) => MaterialApp(
    home: Scaffold(
      body: FlashcardWidget(card: card, showAnswer: showAnswer, onTap: () {}),
    ),
  );

  for (final size in const [vocabMobile, vocabDesktop, vocabTall]) {
    final label = '@${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('front + reveal hint before the answer $label', (tester) async {
      await pumpVocabAt(tester, size, host(false));

      expect(find.text('apple'), findsOneWidget);
      expect(find.text(AppStrings.vocabTapToReveal), findsOneWidget);
      expect(find.text('사과'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('front + back + example + memo once revealed $label', (
      tester,
    ) async {
      await pumpVocabAt(tester, size, host(true));

      expect(find.text('apple'), findsOneWidget);
      expect(find.text('사과'), findsOneWidget);
      expect(find.text('I ate an apple.'), findsOneWidget);
      expect(find.text('과일'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tapping the card fires onTap', (tester) async {
    var taps = 0;
    await pumpVocabAt(
      tester,
      vocabMobile,
      MaterialApp(
        home: Scaffold(
          body: FlashcardWidget(
            card: card,
            showAnswer: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('apple'));
    expect(taps, 1);
  });
}
