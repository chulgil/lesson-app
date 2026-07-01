import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/practice_tool_registry.dart';

/// #979-A — the discipline-keyed practice-tool registry. Music is discipline 0
/// and the fallback, so lookups stay byte-identical to [musicPracticeTools].
void main() {
  group('PracticeToolRegistry', () {
    test('byId("music") returns the music tool set (identical instance)', () {
      expect(PracticeToolRegistry.byId('music'), same(musicPracticeTools));
    });

    test('byId returns null for an unregistered discipline', () {
      expect(PracticeToolRegistry.byId('fitness'), isNull);
    });

    test('forDiscipline("music") returns the music tool set', () {
      expect(
        PracticeToolRegistry.forDiscipline('music'),
        same(musicPracticeTools),
      );
    });

    test('forDiscipline falls back to music for unknown / legacy ids', () {
      expect(
        PracticeToolRegistry.forDiscipline('fitness'),
        same(musicPracticeTools),
      );
      expect(PracticeToolRegistry.forDiscipline(''), same(musicPracticeTools));
    });

    test('registers exactly the music discipline today', () {
      expect(PracticeToolRegistry.registeredDisciplineIds, ['music']);
    });
  });
}
