import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/l10n/string_overlay.dart';

// #968 회귀 0 가드: 메트로놈 분야-의존 문구를 StringOverlay 로 분리한 뒤에도
// (a) music overlay 값이 기존과 동일하고, (b) AppStrings 위임이 같은 값을 내는지 고정.
void main() {
  final music = StringOverlayRegistry.music;

  group('music overlay — metronome strings (regression 0)', () {
    test('values match the legacy AppStrings constants', () {
      expect(music.metronome.timeSignaturePickerTitle, '박자표 선택');
      expect(music.metronome.simpleTimeTitle, '단순 박자');
      expect(music.metronome.compoundTimeTitle, '복합 박자');
      expect(music.metronome.subdivisionPickerTitle, '서브디비전 선택');
      expect(music.metronome.basicPatternTitle, '기본 패턴');
      expect(music.metronome.variationTitle, '베리에이션 (쉼표 포함)');
      expect(music.metronome.optionsTitle, '옵션');
      expect(music.metronome.visualFlashLabel, '시각 플래시');
      expect(music.metronome.vibrationLabel, '진동');
    });
  });

  group('AppStrings delegates to the music overlay (regression 0)', () {
    test('every metronome getter equals the overlay value', () {
      expect(
        AppStrings.metronomeTimeSignaturePickerTitle,
        music.metronome.timeSignaturePickerTitle,
      );
      expect(AppStrings.metronomeSimpleTimeTitle, '단순 박자');
      expect(AppStrings.metronomeCompoundTimeTitle, '복합 박자');
      expect(AppStrings.metronomeSubdivisionPickerTitle, '서브디비전 선택');
      expect(AppStrings.metronomeBasicPatternTitle, '기본 패턴');
      expect(AppStrings.metronomeVariationTitle, '베리에이션 (쉼표 포함)');
      expect(AppStrings.metronomeOptionsTitle, '옵션');
      expect(AppStrings.metronomeVisualFlashLabel, '시각 플래시');
      expect(AppStrings.metronomeVibrationLabel, '진동');
    });
  });

  group('discipline-scoped lookup + fallback', () {
    const musicDiscipline = Discipline(
      id: 'music',
      displayKey: 'discipline.music',
      themeColorSeed: 0xFFB7410E,
      expertiseCatalogId: 'instruments',
    );
    const unmappedDiscipline = Discipline(
      id: 'language',
      displayKey: 'discipline.language',
      themeColorSeed: 0xFF1976D2,
      expertiseCatalogId: 'subjects',
    );

    test('forDiscipline(music) returns the music overlay', () {
      expect(
        StringOverlayRegistry.forDiscipline(musicDiscipline).disciplineId,
        'music',
      );
    });

    test('forDiscipline(unmapped) falls back to music', () {
      expect(
        StringOverlayRegistry.forDiscipline(unmappedDiscipline).disciplineId,
        'music',
      );
    });

    test('byId resolves registered, null for unknown', () {
      expect(StringOverlayRegistry.byId('music'), isNotNull);
      expect(StringOverlayRegistry.byId('language'), isNull);
    });
  });
}
