import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/fitness_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/language_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/practice_tool_registry.dart';

/// #979-A — the discipline-keyed practice-tool registry. Music is discipline 0
/// and the fallback; #979-B registers fitness as the second tool set.
void main() {
  group('PracticeToolRegistry', () {
    test('byId("music") returns the music tool set (identical instance)', () {
      expect(PracticeToolRegistry.byId('music'), same(musicPracticeTools));
    });

    test('byId("fitness") returns the fitness tool set (#979-B)', () {
      expect(PracticeToolRegistry.byId('fitness'), same(fitnessPracticeTools));
    });

    test('byId("language") returns the language tool set (#1102)', () {
      expect(PracticeToolRegistry.byId('language'), same(languagePracticeTools));
    });

    test('byId returns null for an unregistered discipline', () {
      expect(PracticeToolRegistry.byId('unknown_discipline'), isNull);
    });

    test('forDiscipline("music") returns the music tool set', () {
      expect(
        PracticeToolRegistry.forDiscipline('music'),
        same(musicPracticeTools),
      );
    });

    test('forDiscipline("fitness") returns the fitness tool set (#979-B)', () {
      expect(
        PracticeToolRegistry.forDiscipline('fitness'),
        same(fitnessPracticeTools),
      );
    });

    test('forDiscipline("language") returns the language tool set (#1102)', () {
      expect(
        PracticeToolRegistry.forDiscipline('language'),
        same(languagePracticeTools),
      );
    });

    test('forDiscipline falls back to music for unknown / legacy ids', () {
      expect(
        PracticeToolRegistry.forDiscipline('unknown_discipline'),
        same(musicPracticeTools),
      );
      expect(PracticeToolRegistry.forDiscipline(''), same(musicPracticeTools));
    });

    test('registers music + fitness + language (#979-B/#1102)', () {
      expect(PracticeToolRegistry.registeredDisciplineIds, [
        'music',
        'fitness',
        'language',
      ]);
    });
  });
}
