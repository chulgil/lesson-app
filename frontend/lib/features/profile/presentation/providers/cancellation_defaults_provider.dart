import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_cancellation_defaults_repository.dart';
import '../../data/repositories/remote_cancellation_defaults_repository.dart';
import '../../domain/entities/cancellation_defaults.dart';
import '../../domain/repositories/cancellation_defaults_repository.dart';

part 'cancellation_defaults_provider.g.dart';

/// Repository provider for cancellation defaults.
///
/// Remote mode targets GET/PUT /settings/cancellation (#1178) — the server
/// row is what drives late-cancel compensation notifications.
@Riverpod(keepAlive: true)
CancellationDefaultsRepository cancellationDefaultsRepository(
  CancellationDefaultsRepositoryRef ref,
) => createRepository<CancellationDefaultsRepository>(
  ref: ref,
  mock: () => MockCancellationDefaultsRepository(),
  remote: (apiClient) => RemoteCancellationDefaultsRepository(apiClient),
);

/// Async notifier provider for cancellation defaults
@riverpod
class CancellationDefaultsNotifier extends _$CancellationDefaultsNotifier {
  @override
  Future<CancellationDefaults> build() async {
    final repo = ref.watch(cancellationDefaultsRepositoryProvider);
    return repo.getCancellationDefaults();
  }

  /// Update cancellation deadline hours
  Future<void> updateDeadlineHours(int hours) async {
    final current = await future;
    await _applyAndSave(
      current,
      current.copyWith(cancellationDeadlineHours: hours),
    );
  }

  /// Toggle student compensation extra minutes enabled
  Future<void> toggleCompensationEnabled(bool enabled) async {
    final current = await future;
    await _applyAndSave(
      current,
      current.copyWith(studentCompensationExtraMinutesEnabled: enabled),
    );
  }

  /// Toggle include extra minutes text on late cancel
  Future<void> toggleIncludeExtraMinutesText(bool include) async {
    final current = await future;
    await _applyAndSave(
      current,
      current.copyWith(includeExtraMinutesTextOnLateCancel: include),
    );
  }

  /// Update student compensation message
  Future<void> updateCompensationMessage(String message) async {
    final current = await future;
    await _applyAndSave(
      current,
      current.copyWith(
        studentCompensationExtraMinutesMessage:
            message.isEmpty ? null : message,
      ),
    );
  }

  /// Toggle notify owner on late cancel
  Future<void> toggleNotifyOwnerOnLateCancel(bool notify) async {
    final current = await future;
    await _applyAndSave(
      current,
      current.copyWith(notifyOwnerOnLateCancel: notify),
    );
  }

  /// Optimistically apply [updated], then persist. On failure the state is
  /// rolled back to [current] and the error rethrown so the screen can tell
  /// the user the save did not land (#1184 — remote PUT can fail).
  Future<void> _applyAndSave(
    CancellationDefaults current,
    CancellationDefaults updated,
  ) async {
    state = AsyncValue.data(updated);
    try {
      final repo = ref.read(cancellationDefaultsRepositoryProvider);
      await repo.updateCancellationDefaults(updated);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// Refresh from repository
  Future<void> refresh() async {
    final repo = ref.read(cancellationDefaultsRepositoryProvider);
    final data = await repo.getCancellationDefaults();
    state = AsyncValue.data(data);
  }
}
