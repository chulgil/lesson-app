import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/practice_repertoire.dart' as practice;
import '../../domain/entities/repertoire_sort_type.dart' as domain;
import 'practice_repertoire_crud_provider.dart';
import 'practice_repertoire_repository_provider.dart';

part 'repertoire_sort_provider.g.dart';

/// Current repertoire sort type provider
@Riverpod(keepAlive: true)
class RepertoireSortTypeState extends _$RepertoireSortTypeState {
  @override
  domain.RepertoireSortType build() => domain.RepertoireSortType.createdDesc;

  void setSortType(domain.RepertoireSortType type) {
    state = type;
  }
}

final repertoireSortTypeProvider = repertoireSortTypeStateProvider;

/// Sorted repertoires provider for a date
@Riverpod(keepAlive: true)
List<practice.PracticeRepertoire> sortedRepertoiresForDate(
  SortedRepertoiresForDateRef ref,
  RepertoiresForDateParams params,
) {
  final repertoiresAsync = ref.watch(repertoiresForDateProvider(params));
  final sortType = ref.watch(repertoireSortTypeProvider);

  return repertoiresAsync.when(
    data:
        (repertoires) => domain.RepertoireSorting(repertoires).sortBy(sortType),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// Repertoire order notifier for drag and drop
@Riverpod(keepAlive: true)
class RepertoireOrderNotifier extends _$RepertoireOrderNotifier {
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
          await repository.updateRepertoire(repertoire.copyWith(sortOrder: i));
        }
      }

      // Invalidate to refresh UI
      ref.invalidate(studentRepertoiresProvider(studentId));
      final today = DateTime.now();
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(studentId: studentId, date: today),
        ),
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
