import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/features/auth/auth_facade.dart' show activeDisciplineProvider;
import 'package:lessonaza/features/search/data/repositories/mock_teacher_search_repository.dart';
import 'package:lessonaza/features/search/domain/value_objects/provider_search_facet.dart';
import 'package:lessonaza/features/search/presentation/providers/teacher_search_provider.dart';

void main() {
  group('ProviderSearchFacetRegistry (#976)', () {
    test('music instruments facet resolves to the repo teacher-scan source', () async {
      final repo = MockTeacherSearchRepository();
      final resolver = ProviderSearchFacetRegistry.byId('instruments');
      expect(resolver, isNotNull);
      final viaFacet = await resolver!(repo);
      final direct = await repo.getAvailableInstruments();
      expect(viaFacet, direct); // byte-identical source — no catalog substitution
    });

    test('subjects/specialties facets are no longer registered (#1278)', () {
      // 음악 단일 포커스 — 제거된 분야의 facet 은 등록되지 않으며, 조회는 null
      // 이므로 availableInstruments 가 빈 필터로 degrade 한다 (아래 테스트).
      expect(ProviderSearchFacetRegistry.byId('subjects'), isNull);
      expect(ProviderSearchFacetRegistry.byId('specialties'), isNull);
      expect(ProviderSearchFacetRegistry.registeredFacetIds, ['instruments']);
    });

    test('unknown facet id resolves to null', () {
      expect(ProviderSearchFacetRegistry.byId('unknown_facet'), isNull);
      expect(ProviderSearchFacetRegistry.byId(''), isNull);
    });

    test('music discipline facetId is registered (literal linkage guard)', () {
      // Guards the 'instruments' literal == DisciplineRegistry.music.expertiseCatalogId.
      expect(
        ProviderSearchFacetRegistry.byId(
          DisciplineRegistry.music.expertiseCatalogId,
        ),
        isNotNull,
      );
      expect(
        ProviderSearchFacetRegistry.registeredFacetIds,
        contains('instruments'),
      );
    });

    test('availableInstruments (music active) stays byte-identical to the direct repo call',
        () async {
      final repo = MockTeacherSearchRepository();
      final container = ProviderContainer(
        overrides: [
          teacherSearchRepositoryProvider.overrideWithValue(repo),
          // Every real user's active discipline is music today; pin it so the
          // routing (#1108) is byte-identical to the pre-#1108 teacher-scan.
          activeDisciplineProvider.overrideWithValue(DisciplineRegistry.music),
        ],
      );
      addTearDown(container.dispose);
      final viaProvider =
          await container.read(availableInstrumentsProvider.future);
      final direct = await repo.getAvailableInstruments();
      expect(viaProvider, direct);
    });

    test('availableInstruments degrades to an empty filter for an unregistered facet (#1278)',
        () async {
      final repo = MockTeacherSearchRepository();

      Future<List<String>> forDiscipline(Discipline d) async {
        final c = ProviderContainer(
          overrides: [
            teacherSearchRepositoryProvider.overrideWithValue(repo),
            activeDisciplineProvider.overrideWithValue(d),
          ],
        );
        addTearDown(c.dispose);
        return c.read(availableInstrumentsProvider.future);
      }

      const unregistered = Discipline(
        id: 'unregistered',
        displayKey: 'discipline.unregistered',
        themeColorSeed: 0xFF000000,
        expertiseCatalogId: 'specialties',
      );
      // 미등록 facet → 빈 필터 (크래시 없이 필터 차원만 사라진다).
      expect(await forDiscipline(unregistered), isEmpty);
    });
  });
}
