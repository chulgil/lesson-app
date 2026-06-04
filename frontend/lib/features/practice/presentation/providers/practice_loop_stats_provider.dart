import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../data/repositories/mock_practice_loop_stats_repository.dart';
import '../../data/repositories/remote_practice_loop_stats_repository.dart';
import '../../data/services/loop_stats_sync_service.dart';
import '../../domain/entities/practice_loop_stats.dart';
import '../../domain/repositories/practice_loop_stats_repository.dart';

part 'practice_loop_stats_provider.g.dart';

/// Repository provider — switches Mock ↔ Remote (#512).
@Riverpod(keepAlive: true)
PracticeLoopStatsRepository practiceLoopStatsRepository(Ref ref) =>
    createRepository<PracticeLoopStatsRepository>(
      ref: ref,
      mock: () => MockPracticeLoopStatsRepository(),
      remote: (api) => RemotePracticeLoopStatsRepository(api),
    );

/// Offline-aware sync queue service (#512).
@Riverpod(keepAlive: true)
LoopStatsSyncService loopStatsSyncService(Ref ref) {
  final repo = ref.watch(practiceLoopStatsRepositoryProvider);
  return LoopStatsSyncService(repo);
}

/// Teacher: per-student rows scoped by [window].
@riverpod
Future<({int totalRepeats, List<PracticeLoopStats> rows})>
practiceLoopStatsForStudent(
  Ref ref, {
  required String studentId,
  required PracticeLoopStatsWindow window,
}) {
  final repo = ref.watch(practiceLoopStatsRepositoryProvider);
  return repo.listForStudent(studentId: studentId, window: window);
}

/// Teacher: dashboard roll-up across all linked students.
@riverpod
Future<List<StudentRepeatStats>> practiceLoopStatsSummary(
  Ref ref, {
  required PracticeLoopStatsWindow window,
}) {
  final repo = ref.watch(practiceLoopStatsRepositoryProvider);
  return repo.summary(window: window);
}

/// Student-side: thin actions API for the loop screen / lifecycle hooks.
///
/// Used by [PracticeLoopOverrideNotifier] at session end + by the queue
/// flush trigger when connectivity returns.
@riverpod
LoopStatsSyncActions loopStatsSyncActions(Ref ref) => LoopStatsSyncActions(ref);

class LoopStatsSyncActions {
  LoopStatsSyncActions(this._ref);
  final Ref _ref;

  /// Queue a delta for later batch upload at session end.
  Future<void> queueDelta({
    required String sectionId,
    required int repeatCount,
    required DateTime lastPlayedAt,
  }) async {
    final studentUserId = _ref.read(currentUserIdProvider);
    if (studentUserId.isEmpty) return;
    final svc = _ref.read(loopStatsSyncServiceProvider);
    await svc.enqueue(
      studentUserId: studentUserId,
      entry: PendingLoopStatsSync(
        sectionId: sectionId,
        repeatCount: repeatCount,
        lastPlayedAt: lastPlayedAt,
      ),
    );
  }

  /// Flush the offline queue at session end.
  ///
  /// Returns the server result (best-effort) — caller is allowed to swallow
  /// errors silently, the queue persists for retry.
  Future<PracticeLoopStatsSyncResult> flush() async {
    final studentUserId = _ref.read(currentUserIdProvider);
    if (studentUserId.isEmpty) return const PracticeLoopStatsSyncResult();
    final svc = _ref.read(loopStatsSyncServiceProvider);
    try {
      return await svc.flush(studentUserId);
    } catch (_) {
      return const PracticeLoopStatsSyncResult();
    }
  }
}
