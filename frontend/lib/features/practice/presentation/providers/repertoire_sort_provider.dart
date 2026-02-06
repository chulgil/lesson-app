import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/practice_repertoire.dart';
import '../../domain/entities/repertoire_sort_type.dart';
import 'practice_repertoire_crud_provider.dart';
import 'practice_repertoire_repository_provider.dart';

/// Current repertoire sort type provider
final repertoireSortTypeProvider = StateProvider<RepertoireSortType>((ref) {
  return RepertoireSortType.createdDesc;
});

/// Sorted repertoires provider for a date
final sortedRepertoiresForDateProvider =
    Provider.family<List<PracticeRepertoire>, RepertoiresForDateParams>(
        (ref, params) {
  final repertoiresAsync = ref.watch(repertoiresForDateProvider(params));
  final sortType = ref.watch(repertoireSortTypeProvider);

  return repertoiresAsync.when(
    data: (repertoires) => repertoires.sortBy(sortType),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Repertoire order notifier for drag and drop
class RepertoireOrderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Reorder repertoires via drag and drop
  Future<void> reorderRepertoires(
    String studentId,
    List<String> repertoireIds,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);

      // Update sort order for each repertoire
      for (int i = 0; i < repertoireIds.length; i++) {
        final repertoire = await repository.getRepertoire(repertoireIds[i]);
        if (repertoire != null) {
          await repository.updateRepertoire(
            repertoire.copyWith(sortOrder: i),
          );
        }
      }

      // Invalidate to refresh UI
      ref.invalidate(studentRepertoiresProvider(studentId));
      final today = DateTime.now();
      ref.invalidate(repertoiresForDateProvider(
        RepertoiresForDateParams(studentId: studentId, date: today),
      ));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final repertoireOrderNotifierProvider =
    AsyncNotifierProvider<RepertoireOrderNotifier, void>(
  RepertoireOrderNotifier.new,
);
