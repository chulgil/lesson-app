import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/presentation/screens/vocab_sets_page.dart';

import '../../vocab_widget_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late VocabHarness h;
  setUp(() async {
    h = VocabHarness();
    await h.start();
  });
  tearDown(() => h.stop());

  for (final size in const [vocabMobile, vocabDesktop, vocabTall]) {
    final label = '@${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('empty state shows the create CTA $label', (tester) async {
      await pumpVocabAt(tester, size, h.wrap(const VocabSetsPage()));

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text(AppStrings.vocabSetsEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.vocabCreateSetCta), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lists sets as swipe rows', (tester) async {
    await h.repo.saveSet(
      VocabSet(id: 's1', title: '중국어', createdAt: DateTime(2026, 7, 1)),
    );
    await h.repo.saveSet(
      VocabSet(id: 's2', title: '영어', createdAt: DateTime(2026, 7, 2)),
    );

    await pumpVocabAt(tester, vocabMobile, h.wrap(const VocabSetsPage()));

    expect(find.text('중국어'), findsOneWidget);
    expect(find.text('영어'), findsOneWidget);
    expect(find.byType(SwipeActionTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
