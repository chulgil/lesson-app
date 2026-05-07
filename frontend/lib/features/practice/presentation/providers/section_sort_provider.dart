import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/entities.dart' as entities;
import 'practice_repertoire_crud_provider.dart';
import 'practice_repertoire_repository_provider.dart';

part 'section_sort_provider.g.dart';

/// Current section sort type provider
@Riverpod(keepAlive: true)
class SectionSortTypeState extends _$SectionSortTypeState {
  @override
  entities.SectionSortType build() => entities.SectionSortType.createdDesc;

  void setSortType(entities.SectionSortType type) {
    state = type;
  }
}

/// Sorted sections provider for a repertoire
@Riverpod(keepAlive: true)
List<entities.PracticeSection> sortedSections(
  SortedSectionsRef ref,
  String repertoireId,
) {
  // Use the same repertoireProvider as the detail screen
  final repertoire = ref.watch(repertoireProvider(repertoireId)).valueOrNull;
  final sortType = ref.watch(sectionSortTypeStateProvider);

  if (repertoire == null) return [];
  return entities.SectionSorting(repertoire.sections).sortBy(sortType);
}

/// Section order notifier for drag and drop
@Riverpod(keepAlive: true)
class SectionOrderNotifier extends _$SectionOrderNotifier {
  @override
  Future<void> build() async {}

  /// Reorder sections via drag and drop
  Future<void> reorderSections(
    String repertoireId,
    int oldIndex,
    int newIndex,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final repertoire = await repository.getRepertoire(repertoireId);
      if (repertoire == null) throw Exception('Repertoire not found');

      // Get current sorted sections
      final sortType = ref.read(sectionSortTypeStateProvider);
      final sections = entities.SectionSorting(
        repertoire.sections,
      ).sortBy(sortType);

      // Create new order
      final sectionIds = sections.map((s) => s.id).toList();
      final movedId = sectionIds.removeAt(oldIndex);
      sectionIds.insert(newIndex, movedId);

      // Update order in repository
      await repository.updateSectionOrders(repertoireId, sectionIds);

      // Invalidate to refresh UI
      ref.invalidate(repertoireProvider(repertoireId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Apply sort order when sort type changes to custom
  Future<void> applySortOrder(
    String repertoireId,
    entities.SectionSortType type,
  ) async {
    if (type != entities.SectionSortType.custom) return;

    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final repertoire = await repository.getRepertoire(repertoireId);
      if (repertoire == null) throw Exception('Repertoire not found');

      // Get current order based on previous sort type
      final sectionIds = repertoire.sections.map((s) => s.id).toList();

      // Apply current order as sortOrder
      await repository.updateSectionOrders(repertoireId, sectionIds);

      // Invalidate to refresh UI
      ref.invalidate(repertoireProvider(repertoireId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
