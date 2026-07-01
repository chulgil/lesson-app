import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/domain/value_objects/expertise_catalog_registry.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';

/// #964 — ExpertiseCatalog SSOT + InstrumentList 별칭 계약.
void main() {
  group('ExpertiseCatalogRegistry', () {
    test('music 카탈로그 = id instruments, 22개 악기', () {
      expect(ExpertiseCatalogRegistry.music.id, 'instruments');
      expect(ExpertiseCatalogRegistry.music.items.length, 22);
      expect(
        ExpertiseCatalogRegistry.music.items,
        containsAll(<String>['색소폰', '드럼', '베이스기타', '우쿨렐레']),
      );
      expect(ExpertiseCatalogRegistry.music.items.first, '바이올린');
      expect(ExpertiseCatalogRegistry.music.items.last, '작곡/이론');
    });

    test('byId — 등록 카탈로그 조회 / 미등록 null', () {
      expect(
        ExpertiseCatalogRegistry.byId('instruments'),
        same(ExpertiseCatalogRegistry.music),
      );
      expect(
        ExpertiseCatalogRegistry.byId('specialties'),
        same(ExpertiseCatalogRegistry.fitness),
      );
      expect(ExpertiseCatalogRegistry.byId('unknown'), isNull);
    });

    test('fitness 카탈로그 = id specialties, 3종 (웨이트/필라테스/PT) (#979-B)', () {
      expect(ExpertiseCatalogRegistry.fitness.id, 'specialties');
      expect(ExpertiseCatalogRegistry.fitness.items, ['웨이트', '필라테스', 'PT']);
      expect(
        ExpertiseCatalogRegistry.forDiscipline(DisciplineRegistry.fitness),
        same(ExpertiseCatalogRegistry.fitness),
      );
    });

    test('forDiscipline(music) → music 카탈로그 (expertiseCatalogId 경유)', () {
      expect(
        ExpertiseCatalogRegistry.forDiscipline(DisciplineRegistry.music),
        same(ExpertiseCatalogRegistry.music),
      );
    });

    test('fallback = music (null/legacy/미등록 id 폴백)', () {
      expect(
        ExpertiseCatalogRegistry.fallback,
        same(ExpertiseCatalogRegistry.music),
      );
    });
  });

  group('InstrumentList 별칭 계약 (음악 악기 회귀 가드)', () {
    test('InstrumentList.all === music 카탈로그 items (동일 22개·동일 순서)', () {
      expect(InstrumentList.all, ExpertiseCatalogRegistry.music.items);
      expect(InstrumentList.all.length, 22);
    });

    test('common = all.take(10)', () {
      expect(
        InstrumentList.common,
        ExpertiseCatalogRegistry.music.items.take(10).toList(),
      );
    });
  });
}
