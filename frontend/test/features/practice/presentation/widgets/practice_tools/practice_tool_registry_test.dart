import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/practice_tool_registry.dart';

/// #979-A — the discipline-keyed practice-tool registry. #1278 (music-only
/// focus) leaves music as the sole registered tool set and the fallback.
void main() {
  group('PracticeToolRegistry', () {
    test('byId("music") returns the music tool set (identical instance)', () {
      expect(PracticeToolRegistry.byId('music'), same(musicPracticeTools));
    });

    test('byId returns null for an unregistered discipline', () {
      expect(PracticeToolRegistry.byId('unknown_discipline'), isNull);
      // #1278 로 제거된 분야도 더 이상 도구셋을 등록하지 않는다.
      expect(PracticeToolRegistry.byId('fitness'), isNull);
      expect(PracticeToolRegistry.byId('language'), isNull);
    });

    test('forDiscipline("music") returns the music tool set', () {
      expect(
        PracticeToolRegistry.forDiscipline('music'),
        same(musicPracticeTools),
      );
    });

    test('forDiscipline falls back to music for unknown / legacy ids', () {
      expect(
        PracticeToolRegistry.forDiscipline('unknown_discipline'),
        same(musicPracticeTools),
      );
      expect(PracticeToolRegistry.forDiscipline(''), same(musicPracticeTools));
      // #1278 로 제거된 분야가 저장돼 있어도 music 도구셋으로 안전 degrade.
      expect(
        PracticeToolRegistry.forDiscipline('fitness'),
        same(musicPracticeTools),
      );
      expect(
        PracticeToolRegistry.forDiscipline('language'),
        same(musicPracticeTools),
      );
    });

    test('registers music only (#1278)', () {
      expect(PracticeToolRegistry.registeredDisciplineIds, ['music']);
    });
  });
}
