import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/domain/value_objects/expertise_catalog_registry.dart';
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

    test('subjects/specialties facets resolve to the discipline catalog (#1108)',
        () async {
      final repo = MockTeacherSearchRepository();
      final subjects = ProviderSearchFacetRegistry.byId('subjects');
      final specialties = ProviderSearchFacetRegistry.byId('specialties');
      expect(subjects, isNotNull);
      expect(specialties, isNotNull);
      // Catalog-backed (repo ignored): skeleton verticals have no teachers to scan.
      expect(await subjects!(repo), ExpertiseCatalogRegistry.language.items);
      expect(await specialties!(repo), ExpertiseCatalogRegistry.fitness.items);
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

    test('availableInstruments routes to the active discipline catalog (#1108)',
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

      expect(
        await forDiscipline(DisciplineRegistry.language),
        ExpertiseCatalogRegistry.language.items,
      );
      expect(
        await forDiscipline(DisciplineRegistry.fitness),
        ExpertiseCatalogRegistry.fitness.items,
      );
    });
  });
}
