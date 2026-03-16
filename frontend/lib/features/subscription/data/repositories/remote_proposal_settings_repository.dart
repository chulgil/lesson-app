import '../../../../core/network/api_client.dart';
import '../../domain/entities/proposal_settings.dart';
import '../../domain/repositories/proposal_settings_repository.dart';

/// Remote implementation of [ProposalSettingsRepository] using FastAPI backend.
class RemoteProposalSettingsRepository implements ProposalSettingsRepository {
  final ApiClient _apiClient;

  RemoteProposalSettingsRepository(this._apiClient);

  @override
  Future<ProposalSettings> getSettings(String teacherId) async {
    final response = await _apiClient.get('/settings/proposal');
    return ProposalSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<ProposalSettings> saveSettings(ProposalSettings settings) async {
    final response = await _apiClient.put(
      '/settings/proposal',
      data: settings.toJson()
        ..remove('teacherId')
        ..remove('teacher_id'),
    );
    return ProposalSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<bool> isAutoProposalEnabled(String teacherId) async {
    final settings = await getSettings(teacherId);
    return settings.autoProposalEnabled;
  }
}
