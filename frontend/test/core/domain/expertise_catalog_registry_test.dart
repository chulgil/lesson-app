import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
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
      // #1278 로 제거된 분야의 카탈로그는 더 이상 등록되지 않는다.
      expect(ExpertiseCatalogRegistry.byId('specialties'), isNull);
      expect(ExpertiseCatalogRegistry.byId('subjects'), isNull);
      expect(ExpertiseCatalogRegistry.byId('unknown'), isNull);
    });

    test('미등록 분야는 music 카탈로그로 degrade (#1278)', () {
      const unregistered = Discipline(
        id: 'unregistered',
        displayKey: 'discipline.unregistered',
        themeColorSeed: 0xFF000000,
        expertiseCatalogId: 'specialties',
      );
      expect(
        ExpertiseCatalogRegistry.forDiscipline(unregistered),
        same(ExpertiseCatalogRegistry.music),
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
