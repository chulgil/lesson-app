import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'practice_repertoire_repository_provider.dart';

/// Current section sort type provider
final sectionSortTypeProvider = StateProvider<SectionSortType>((ref) {
  return SectionSortType.createdDesc;
});

/// Sorted sections provider for a repertoire
final sortedSectionsProvider =
    Provider.family<List<PracticeSection>, String>((ref, repertoireId) {
  final repertoire =
      ref.watch(singleRepertoireProvider(repertoireId)).valueOrNull;
  final sortType = ref.watch(sectionSortTypeProvider);

  if (repertoire == null) return [];
  return repertoire.sections.sortBy(sortType);
});

/// Single repertoire provider for section sorting
final singleRepertoireProvider =
    FutureProvider.family<PracticeRepertoire?, String>((ref, id) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getRepertoire(id);
});

/// Section order notifier for drag and drop
class SectionOrderNotifier extends AsyncNotifier<void> {
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
      final sortType = ref.read(sectionSortTypeProvider);
      final sections = repertoire.sections.sortBy(sortType);

      // Create new order
      final sectionIds = sections.map((s) => s.id).toList();
      final movedId = sectionIds.removeAt(oldIndex);
      sectionIds.insert(newIndex, movedId);

      // Update order in repository
      await repository.updateSectionOrders(repertoireId, sectionIds);

      // Invalidate to refresh
      ref.invalidate(singleRepertoireProvider(repertoireId));
      ref.invalidate(sortedSectionsProvider(repertoireId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Apply sort order when sort type changes to custom
  Future<void> applySortOrder(
    String repertoireId,
    SectionSortType type,
  ) async {
    if (type != SectionSortType.custom) return;

    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final repertoire = await repository.getRepertoire(repertoireId);
      if (repertoire == null) throw Exception('Repertoire not found');

      // Get current order based on previous sort type
      final sectionIds = repertoire.sections.map((s) => s.id).toList();

      // Apply current order as sortOrder
      await repository.updateSectionOrders(repertoireId, sectionIds);

      ref.invalidate(singleRepertoireProvider(repertoireId));
      ref.invalidate(sortedSectionsProvider(repertoireId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final sectionOrderNotifierProvider =
    AsyncNotifierProvider<SectionOrderNotifier, void>(
  SectionOrderNotifier.new,
);
