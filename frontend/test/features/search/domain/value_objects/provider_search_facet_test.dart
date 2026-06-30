import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
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

    test('unknown facet id resolves to null', () {
      expect(ProviderSearchFacetRegistry.byId('specialties'), isNull);
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

    test('availableInstruments provider stays byte-identical to the direct repo call',
        () async {
      final repo = MockTeacherSearchRepository();
      final container = ProviderContainer(
        overrides: [teacherSearchRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final viaProvider =
          await container.read(availableInstrumentsProvider.future);
      final direct = await repo.getAvailableInstruments();
      expect(viaProvider, direct);
    });
  });
}
