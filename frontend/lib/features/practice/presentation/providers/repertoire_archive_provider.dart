import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'practice_repertoire_repository_provider.dart';

/// Active (non-archived) repertoires provider
final activeRepertoiresProvider =
    FutureProvider.family<List<PracticeRepertoire>, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepertoireRepositoryProvider);
    return repository.getActiveRepertoires(studentId);
  },
);

/// Archived repertoires provider
final archivedRepertoiresProvider =
    FutureProvider.family<List<PracticeRepertoire>, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepertoireRepositoryProvider);
    return repository.getArchivedRepertoires(studentId);
  },
);

/// Repertoire archive notifier
class RepertoireArchiveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Archive a repertoire
  Future<void> archive(String id, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.archiveRepertoire(id);

      // Invalidate related providers
      ref.invalidate(activeRepertoiresProvider(studentId));
      ref.invalidate(archivedRepertoiresProvider(studentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Restore a repertoire from archive
  Future<void> restore(String id, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.restoreRepertoire(id);

      // Invalidate related providers
      ref.invalidate(activeRepertoiresProvider(studentId));
      ref.invalidate(archivedRepertoiresProvider(studentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Permanently delete a repertoire
  Future<void> permanentlyDelete(String id, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.permanentlyDeleteRepertoire(id);

      // Invalidate related providers
      ref.invalidate(archivedRepertoiresProvider(studentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final repertoireArchiveNotifierProvider =
    AsyncNotifierProvider<RepertoireArchiveNotifier, void>(
  RepertoireArchiveNotifier.new,
);
