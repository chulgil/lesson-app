import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/review_grade.dart';
import 'package:lessonaza/features/vocabulary/presentation/widgets/review_grade_bar.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final size in const [vocabMobile, vocabDesktop]) {
    final label = '@${size.width.toInt()}';

    testWidgets('renders four grade buttons without overflow $label', (
      tester,
    ) async {
      await pumpVocabAt(
        tester,
        size,
        MaterialApp(home: Scaffold(body: ReviewGradeBar(onGrade: (_) {}))),
      );

      expect(find.text(AppStrings.vocabGradeAgain), findsOneWidget);
      expect(find.text(AppStrings.vocabGradeHard), findsOneWidget);
      expect(find.text(AppStrings.vocabGradeGood), findsOneWidget);
      expect(find.text(AppStrings.vocabGradeEasy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('each button reports its grade', (tester) async {
    final graded = <ReviewGrade>[];
    await pumpVocabAt(
      tester,
      vocabMobile,
      MaterialApp(home: Scaffold(body: ReviewGradeBar(onGrade: graded.add))),
    );

    await tester.tap(find.text(AppStrings.vocabGradeAgain));
    await tester.tap(find.text(AppStrings.vocabGradeHard));
    await tester.tap(find.text(AppStrings.vocabGradeGood));
    await tester.tap(find.text(AppStrings.vocabGradeEasy));

    expect(graded, [
      ReviewGrade.again,
      ReviewGrade.hard,
      ReviewGrade.good,
      ReviewGrade.easy,
    ]);
  });
}
