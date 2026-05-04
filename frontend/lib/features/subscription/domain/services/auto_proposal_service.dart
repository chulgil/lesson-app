import '../../../../core/l10n/app_strings.dart';
import '../entities/proposal_settings.dart';
import '../entities/subscription_proposal.dart';
import '../entities/subscription_template.dart';

typedef LoadProposalSettings =
    Future<ProposalSettings> Function(String teacherId);
typedef LoadActiveProposal =
    Future<SubscriptionProposal?> Function(String teacherId, String studentId);
typedef LoadAutoProposalTemplates =
    Future<List<SubscriptionTemplate>> Function(String teacherId);
typedef CreateAutoProposal =
    Future<SubscriptionProposal> Function({
      required String teacherId,
      required String studentId,
      required List<String> templateIds,
      String? recommendedTemplateId,
      required String message,
      int? discountAmount,
      String? discountReason,
      required bool isAutoProposal,
    });

/// Service for automatically creating subscription proposals after trial lessons.
class AutoProposalService {
  final LoadProposalSettings _loadSettings;
  final LoadActiveProposal _loadActiveProposal;
  final LoadAutoProposalTemplates _loadAutoProposalTemplates;
  final CreateAutoProposal _createAutoProposal;

  const AutoProposalService({
    required LoadProposalSettings loadSettings,
    required LoadActiveProposal loadActiveProposal,
    required LoadAutoProposalTemplates loadAutoProposalTemplates,
    required CreateAutoProposal createAutoProposal,
  }) : _loadSettings = loadSettings,
       _loadActiveProposal = loadActiveProposal,
       _loadAutoProposalTemplates = loadAutoProposalTemplates,
       _createAutoProposal = createAutoProposal;

  /// Trigger auto-proposal after trial lesson completion.
  ///
  /// Returns the created proposal if successful, null if:
  /// - Auto-proposal is disabled
  /// - No active templates available
  /// - Already has an active proposal for this student
  Future<SubscriptionProposal?> triggerAfterTrialCompletion({
    required String teacherId,
    required String studentId,
    required DateTime trialCompletedAt,
  }) async {
    // 1. Check if auto-proposal is enabled
    final settings = await _loadSettings(teacherId);

    if (!settings.autoProposalEnabled) {
      return null;
    }

    // 2. Check if there's already an active proposal for this student
    final existingProposal = await _loadActiveProposal(teacherId, studentId);

    if (existingProposal != null) {
      // Already has an active proposal
      return null;
    }

    // 3. Get auto-proposal enabled templates only
    // 🆕 isAutoProposalEnabled = true인 템플릿만 가져옴
    final templates = await _loadAutoProposalTemplates(teacherId);

    if (templates.isEmpty) {
      // 자동 제안 대상 템플릿이 없음
      return null;
    }

    // 4. Determine which templates to include
    List<SubscriptionTemplate> proposalTemplates;
    if (settings.autoProposalTemplateIds.isNotEmpty) {
      // Use only specified templates (that are also auto-proposal enabled)
      proposalTemplates =
          templates
              .where((t) => settings.autoProposalTemplateIds.contains(t.id))
              .toList();
    } else {
      // Use all auto-proposal enabled templates
      proposalTemplates = templates;
    }

    if (proposalTemplates.isEmpty) {
      return null;
    }

    // 5. Calculate golden time discount (if enabled)
    int? discountAmount;
    String? discountReason;

    if (settings.hasGoldenTimeDiscount) {
      // Apply discount to the recommended or first template
      final baseTemplate = proposalTemplates.firstWhere(
        (t) => t.id == settings.recommendedTemplateId,
        orElse: () => proposalTemplates.first,
      );

      discountAmount =
          settings.applyGoldenTimeDiscount(baseTemplate.price) -
          baseTemplate.price;
      discountAmount = discountAmount.abs(); // Make positive

      if (discountAmount > 0) {
        discountReason = AppStrings.autoProposalGoldenTimeReason(
          settings.goldenTimeDiscountPercent,
          settings.goldenTimeHours,
        );
      }
    }

    // 6. Create the proposal
    final proposal = await _createAutoProposal(
      teacherId: teacherId,
      studentId: studentId,
      templateIds: proposalTemplates.map((t) => t.id).toList(),
      recommendedTemplateId: _getEffectiveRecommendedTemplateId(
        settings,
        proposalTemplates,
      ),
      message: _buildAutoProposalMessage(settings),
      discountAmount: discountAmount,
      discountReason: discountReason,
      isAutoProposal: true,
    );

    return proposal;
  }

  String? _getEffectiveRecommendedTemplateId(
    ProposalSettings settings,
    List<SubscriptionTemplate> templates,
  ) {
    if (templates.length <= 1) {
      return null; // No need for recommendation with single template
    }

    // Check if teacher's recommended template is in the list
    if (settings.recommendedTemplateId != null &&
        templates.any((t) => t.id == settings.recommendedTemplateId)) {
      return settings.recommendedTemplateId;
    }

    // Default to first template
    return templates.first.id;
  }

  String _buildAutoProposalMessage(ProposalSettings settings) {
    final buffer = StringBuffer();
    buffer.write(AppStrings.autoProposalGreeting);

    if (settings.hasGoldenTimeDiscount) {
      buffer.write(
        AppStrings.autoProposalGoldenTimeHours(settings.goldenTimeHours),
      );
      buffer.write(
        AppStrings.autoProposalGoldenTimePercent(
          settings.goldenTimeDiscountPercent,
        ),
      );
    }

    buffer.write(AppStrings.autoProposalSelectionPrompt);
    return buffer.toString();
  }
}
