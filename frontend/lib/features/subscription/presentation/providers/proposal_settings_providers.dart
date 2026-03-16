import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_proposal_settings_repository.dart';
import '../../domain/entities/proposal_settings.dart';
import '../../domain/repositories/proposal_settings_repository.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/remote_proposal_settings_repository.dart';

part 'proposal_settings_providers.g.dart';

// ============================================================
// Repository Provider
// ============================================================

@Riverpod(keepAlive: true)
ProposalSettingsRepository proposalSettingsRepository(
  ProposalSettingsRepositoryRef ref,
) {
  if (EnvironmentConfig.useMockData) {
    return MockProposalSettingsRepository();
  }
  return RemoteProposalSettingsRepository(ref.read(apiClientProvider));
}

// ============================================================
// Settings Provider
// ============================================================

@riverpod
Future<ProposalSettings> teacherProposalSettings(
  TeacherProposalSettingsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(proposalSettingsRepositoryProvider);
  return repository.getSettings(teacherId);
}

// ============================================================
// Settings Notifier (for updates)
// ============================================================

@riverpod
class ProposalSettingsNotifier extends _$ProposalSettingsNotifier {
  @override
  AsyncValue<ProposalSettings?> build() => const AsyncValue.data(null);

  /// Update auto-proposal enabled setting
  Future<ProposalSettings> toggleAutoProposal(
    String teacherId,
    bool enabled,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(proposalSettingsRepositoryProvider);
      final current = await repository.getSettings(teacherId);
      final updated = current.copyWith(
        autoProposalEnabled: enabled,
        updatedAt: DateTime.now(),
      );
      final saved = await repository.saveSettings(updated);
      state = AsyncValue.data(saved);

      // Invalidate related providers
      ref.invalidate(teacherProposalSettingsProvider(teacherId));

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update auto-proposal template IDs
  Future<ProposalSettings> updateAutoProposalTemplates(
    String teacherId,
    List<String> templateIds,
    String? recommendedTemplateId,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(proposalSettingsRepositoryProvider);
      final current = await repository.getSettings(teacherId);
      final updated = current.copyWith(
        autoProposalTemplateIds: templateIds,
        recommendedTemplateId: recommendedTemplateId,
        updatedAt: DateTime.now(),
      );
      final saved = await repository.saveSettings(updated);
      state = AsyncValue.data(saved);

      ref.invalidate(teacherProposalSettingsProvider(teacherId));

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update golden time discount settings
  Future<ProposalSettings> updateGoldenTimeDiscount(
    String teacherId, {
    required int discountPercent,
    required int validityHours,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(proposalSettingsRepositoryProvider);
      final current = await repository.getSettings(teacherId);
      final updated = current.copyWith(
        goldenTimeDiscountPercent: discountPercent,
        goldenTimeHours: validityHours,
        updatedAt: DateTime.now(),
      );
      final saved = await repository.saveSettings(updated);
      state = AsyncValue.data(saved);

      ref.invalidate(teacherProposalSettingsProvider(teacherId));

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update auto-reminder settings
  Future<ProposalSettings> updateAutoReminder(
    String teacherId, {
    required bool enabled,
    required List<int> reminderHours,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(proposalSettingsRepositoryProvider);
      final current = await repository.getSettings(teacherId);
      final updated = current.copyWith(
        autoReminderEnabled: enabled,
        reminderHours: reminderHours,
        updatedAt: DateTime.now(),
      );
      final saved = await repository.saveSettings(updated);
      state = AsyncValue.data(saved);

      ref.invalidate(teacherProposalSettingsProvider(teacherId));

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update all settings at once
  Future<ProposalSettings> updateSettings(ProposalSettings settings) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(proposalSettingsRepositoryProvider);
      final updated = settings.copyWith(updatedAt: DateTime.now());
      final saved = await repository.saveSettings(updated);
      state = AsyncValue.data(saved);

      ref.invalidate(teacherProposalSettingsProvider(settings.teacherId));

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
