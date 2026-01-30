import '../entities/proposal_settings.dart';

/// Repository interface for proposal settings.
abstract class ProposalSettingsRepository {
  /// Get settings for a teacher (returns defaults if not exists)
  Future<ProposalSettings> getSettings(String teacherId);

  /// Save settings for a teacher
  Future<ProposalSettings> saveSettings(ProposalSettings settings);

  /// Check if auto-proposal is enabled for a teacher
  Future<bool> isAutoProposalEnabled(String teacherId);
}
