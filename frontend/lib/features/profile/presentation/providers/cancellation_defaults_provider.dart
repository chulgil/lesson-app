import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../data/repositories/local_cancellation_defaults_repository.dart';
import '../../data/repositories/mock_cancellation_defaults_repository.dart';
import '../../domain/entities/cancellation_defaults.dart';
import '../../domain/repositories/cancellation_defaults_repository.dart';

part 'cancellation_defaults_provider.g.dart';

/// Repository provider for cancellation defaults.
///
/// No backend endpoint exists yet, so remote mode persists locally
/// (user-scoped) instead of returning seeded mock data (#5 D-G3).
@Riverpod(keepAlive: true)
CancellationDefaultsRepository cancellationDefaultsRepository(
  CancellationDefaultsRepositoryRef ref,
) => createLocalFallbackRepository<CancellationDefaultsRepository>(
  ref: ref,
  mock: () => MockCancellationDefaultsRepository(),
  fallback:
      () => LocalCancellationDefaultsRepository(
        teacherId: ref.watch(currentUserIdProvider),
      ),
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
    final updated = current.copyWith(cancellationDeadlineHours: hours);
    state = AsyncValue.data(updated);
    await _saveToRepository(updated);
  }

  /// Toggle student compensation extra minutes enabled
  Future<void> toggleCompensationEnabled(bool enabled) async {
    final current = await future;
    final updated = current.copyWith(
      studentCompensationExtraMinutesEnabled: enabled,
    );
    state = AsyncValue.data(updated);
    await _saveToRepository(updated);
  }

  /// Toggle include extra minutes text on late cancel
  Future<void> toggleIncludeExtraMinutesText(bool include) async {
    final current = await future;
    final updated = current.copyWith(
      includeExtraMinutesTextOnLateCancel: include,
    );
    state = AsyncValue.data(updated);
    await _saveToRepository(updated);
  }

  /// Update student compensation message
  Future<void> updateCompensationMessage(String message) async {
    final current = await future;
    final updated = current.copyWith(
      studentCompensationExtraMinutesMessage: message.isEmpty ? null : message,
    );
    state = AsyncValue.data(updated);
    await _saveToRepository(updated);
  }

  /// Toggle notify owner on late cancel
  Future<void> toggleNotifyOwnerOnLateCancel(bool notify) async {
    final current = await future;
    final updated = current.copyWith(notifyOwnerOnLateCancel: notify);
    state = AsyncValue.data(updated);
    await _saveToRepository(updated);
  }

  /// Save to repository
  Future<void> _saveToRepository(CancellationDefaults defaults) async {
    final repo = ref.read(cancellationDefaultsRepositoryProvider);
    await repo.updateCancellationDefaults(defaults);
  }

  /// Refresh from repository
  Future<void> refresh() async {
    final repo = ref.read(cancellationDefaultsRepositoryProvider);
    final data = await repo.getCancellationDefaults();
    state = AsyncValue.data(data);
  }
}
