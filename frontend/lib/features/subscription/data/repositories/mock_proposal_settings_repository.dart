import '../../domain/entities/proposal_settings.dart';
import '../../domain/repositories/proposal_settings_repository.dart';

/// Mock implementation of ProposalSettingsRepository.
class MockProposalSettingsRepository implements ProposalSettingsRepository {
  final Map<String, ProposalSettings> _settings = {};

  MockProposalSettingsRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Default settings for teacher_1 with auto-proposal enabled
    _settings['teacher_1'] = ProposalSettings(
      teacherId: 'teacher_1',
      autoProposalEnabled: true,
      autoProposalTemplateIds: const [],  // Empty = use all active templates
      recommendedTemplateId: 'template_t1_2',  // 8회권 추천
      goldenTimeDiscountPercent: 10,
      goldenTimeHours: 24,
      autoReminderEnabled: true,
      reminderHours: const [24, 48, 72],
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    );

    // Settings for teacher_2 with auto-proposal disabled
    _settings['teacher_2'] = ProposalSettings(
      teacherId: 'teacher_2',
      autoProposalEnabled: false,
      autoProposalTemplateIds: const [],
      goldenTimeDiscountPercent: 0,  // No discount
      goldenTimeHours: 24,
      autoReminderEnabled: false,
      reminderHours: const [],
      updatedAt: DateTime.now().subtract(const Duration(days: 14)),
    );
  }

  @override
  Future<ProposalSettings> getSettings(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Return existing settings or create defaults
    return _settings[teacherId] ?? ProposalSettings.defaults(teacherId);
  }

  @override
  Future<ProposalSettings> saveSettings(ProposalSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _settings[settings.teacherId] = settings;
    return settings;
  }

  @override
  Future<bool> isAutoProposalEnabled(String teacherId) async {
    final settings = await getSettings(teacherId);
    return settings.autoProposalEnabled;
  }
}
