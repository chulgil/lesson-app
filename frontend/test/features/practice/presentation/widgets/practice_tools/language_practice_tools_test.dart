import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/language_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';

/// #1102 — language (어학) skeleton practice tools. Data-only registration: the
/// tools render their identity but carry no speech-recognition / scoring / SRS
/// logic. None collides with the music tool ids the modal gates on.
void main() {
  // Skeleton panels render EmptyStateWidget (Playfair via google_fonts); keep
  // tests offline so the async font fetch never reaches the network (#980 fix).
  GoogleFonts.config.allowRuntimeFetching = false;

  group('languagePracticeTools', () {
    test('registers 4 skeleton tools in order (vocab/dictation/pron/conv)', () {
      expect(languagePracticeTools.map((t) => t.id).toList(), [
        LanguagePracticeToolIds.vocabBook,
        LanguagePracticeToolIds.dictation,
        LanguagePracticeToolIds.pronunciation,
        LanguagePracticeToolIds.conversation,
      ]);
    });

    test('tab labels come from AppStrings', () {
      expect(
        languagePracticeTools[0].displayLabel,
        AppStrings.practiceToolVocabBook,
      );
      expect(
        languagePracticeTools[1].displayLabel,
        AppStrings.practiceToolDictation,
      );
      expect(
        languagePracticeTools[2].displayLabel,
        AppStrings.practiceToolPronunciation,
      );
      expect(
        languagePracticeTools[3].displayLabel,
        AppStrings.practiceToolConversation,
      );
    });

    test('no tool exposes a tuner or metronome (mic + engine gates hold)', () {
      final ids = languagePracticeTools.map((t) => t.id).toSet();
      // Must not collide with the music tool ids the modal lifecycle gates on.
      expect(ids.contains(PracticeToolIds.tuner), isFalse);
      expect(ids.contains(PracticeToolIds.metronome), isFalse);
    });

    test('skeleton tools carry no settings affordance', () {
      for (final tool in languagePracticeTools) {
        expect(tool.onShowSettings, isNull, reason: tool.id);
      }
    });

    test('each panel title matches its own tool label (no copy-paste)', () {
      final expected = <String, String>{
        LanguagePracticeToolIds.vocabBook: AppStrings.practiceToolVocabBook,
        LanguagePracticeToolIds.dictation: AppStrings.practiceToolDictation,
        LanguagePracticeToolIds.pronunciation:
            AppStrings.practiceToolPronunciation,
        LanguagePracticeToolIds.conversation:
            AppStrings.practiceToolConversation,
      };
      final ctx = _StubContext();
      for (final tool in languagePracticeTools) {
        final panel = tool.panelBuilder(ctx, null) as EmptyStateWidget;
        expect(panel.title, expected[tool.id], reason: tool.id);
      }
    });
  });

  testWidgets('each skeleton panel renders an EmptyStateWidget placeholder', (
    tester,
  ) async {
    for (final tool in languagePracticeTools) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (c) => tool.panelBuilder(c, null)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(
        find.text(AppStrings.practiceToolSkeletonSubtitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

/// Minimal BuildContext for building a stateless panel off-tree (title check).
/// panelBuilder returns a const EmptyStateWidget and never reads context.
class _StubContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
