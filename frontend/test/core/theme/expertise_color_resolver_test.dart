import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/expertise_color_resolver.dart';
import 'package:lessonaza/core/utils/instrument_colors.dart';

// #967 회귀 0 가드: InstrumentColors 의 음악 색상 매핑을 discipline-scoped
// ExpertiseColorResolver 로 옮긴 뒤에도 음악 악기 색상이 기존과 동일한지 고정한다.
void main() {
  final music = ExpertiseColorResolverRegistry.music;

  void expectPair(ExpertiseColorPair pair, Color bg, Color accent) {
    expect(pair.background, bg);
    expect(pair.accent, accent);
  }

  group('music resolver — instrument colors (regression 0)', () {
    test('all 9 mapped instruments keep their legacy color pair', () {
      expectPair(music.resolve('바이올린'), AppColors.paper, AppColors.paperAccent);
      expectPair(
        music.resolve('피아노'),
        const Color(0xFFE3F2FD),
        const Color(0xFF1976D2),
      );
      expectPair(
        music.resolve('첼로'),
        const Color(0xFFFFF3E0),
        const Color(0xFFF57C00),
      );
      expectPair(
        music.resolve('플루트'),
        const Color(0xFFE8F5E9),
        const Color(0xFF388E3C),
      );
      expectPair(
        music.resolve('기타'),
        const Color(0xFFFCE4EC),
        const Color(0xFFC2185B),
      );
      expectPair(
        music.resolve('성악'),
        const Color(0xFFFFF8E1),
        const Color(0xFFFFA000),
      );
      expectPair(
        music.resolve('클라리넷'),
        const Color(0xFFE0F7FA),
        const Color(0xFF00838F),
      );
      expectPair(
        music.resolve('드럼'),
        const Color(0xFFEFEBE9),
        const Color(0xFF5D4037),
      );
      expectPair(
        music.resolve('타악기'),
        const Color(0xFFEFEBE9),
        const Color(0xFF5D4037),
      );
    });

    test('partial (substring) match preserved — "드럼/타악기" → 드럼', () {
      expectPair(
        music.resolve('드럼/타악기'),
        const Color(0xFFEFEBE9),
        const Color(0xFF5D4037),
      );
    });

    test(
      'unknown instrument hash-cycles the fallback palette (deterministic)',
      () {
        // Same input -> same fallback pair (hash-based), stable across calls.
        final a = music.resolve('해금');
        final b = music.resolve('해금');
        expect(a.background, b.background);
        expect(a.accent, b.accent);
      },
    );

    test(
      'empty string keeps legacy quirk (partial match → first entry 바이올린)',
      () {
        expectPair(music.resolve(''), AppColors.paper, AppColors.paperAccent);
      },
    );
  });

  group(
    'InstrumentColors alias delegates to music resolver (regression 0)',
    () {
      test('getColor == music.resolve for every mapped instrument', () {
        for (final name in const [
          '바이올린',
          '피아노',
          '첼로',
          '플루트',
          '기타',
          '성악',
          '클라리넷',
          '드럼',
          '타악기',
        ]) {
          final viaAlias = InstrumentColors.getColor(name);
          final viaResolver = music.resolve(name);
          expect(viaAlias.background, viaResolver.background, reason: name);
          expect(viaAlias.accent, viaResolver.accent, reason: name);
        }
      });
    },
  );

  group('discipline-scoped lookup + fallback palette', () {
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

    test('forDiscipline(music) returns the music resolver', () {
      expect(
        ExpertiseColorResolverRegistry.forDiscipline(musicDiscipline).catalogId,
        'instruments',
      );
    });

    test('forDiscipline(unmapped) returns the palette-only fallback', () {
      final resolver = ExpertiseColorResolverRegistry.forDiscipline(
        unmappedDiscipline,
      );
      expect(resolver.catalogId, '_fallback');
      // Even an instrument name resolves via palette (no music map) — every
      // tag is hash-cycled, never the music-specific colors.
      final pair = resolver.resolve('바이올린');
      expect(pair.background, isNot(AppColors.paper));
    });

    test('byId resolves registered, null for unknown', () {
      expect(ExpertiseColorResolverRegistry.byId('instruments'), isNotNull);
      expect(ExpertiseColorResolverRegistry.byId('subjects'), isNull);
    });

    test(
      'forDiscipline(fitness) returns the palette-only fallback (#979-B)',
      () {
        // Fitness registers no bespoke resolver, so its specialty tags
        // (웨이트/필라테스/PT) resolve via the shared palette (#980 "폴백").
        final resolver = ExpertiseColorResolverRegistry.forDiscipline(
          DisciplineRegistry.fitness,
        );
        expect(resolver.catalogId, '_fallback');
      },
    );

    test(
      'forDiscipline(language) returns the palette-only fallback (#1102)',
      () {
        // Language registers no bespoke resolver either — its subject tags
        // (영어/중국어/일본어) resolve via the shared palette (#980 "폴백").
        final resolver = ExpertiseColorResolverRegistry.forDiscipline(
          DisciplineRegistry.language,
        );
        expect(resolver.catalogId, '_fallback');
        final a = resolver.resolve('영어');
        final b = resolver.resolve('영어');
        expect(a.background, b.background);
        expect(a.accent, b.accent);
      },
    );
  });
}
