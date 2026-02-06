import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../entities/proposal_settings.dart';
import '../entities/subscription_proposal.dart';
import '../entities/subscription_template.dart';
import '../../presentation/providers/proposal_settings_providers.dart';
import '../../presentation/providers/subscription_proposal_providers.dart';
import '../../presentation/providers/subscription_template_providers.dart';

part 'auto_proposal_service.g.dart';

/// Service for automatically creating subscription proposals after trial lessons.
@riverpod
AutoProposalService autoProposalService(AutoProposalServiceRef ref) {
  return AutoProposalService(ref);
}

class AutoProposalService {
  final Ref _ref;

  AutoProposalService(this._ref);

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
    final settings =
        await _ref.read(teacherProposalSettingsProvider(teacherId).future);

    if (!settings.autoProposalEnabled) {
      return null;
    }

    // 2. Check if there's already an active proposal for this student
    final existingProposal = await _ref.read(
      activeProposalBetweenProvider(teacherId, studentId).future,
    );

    if (existingProposal != null) {
      // Already has an active proposal
      return null;
    }

    // 3. Get auto-proposal enabled templates only
    // 🆕 isAutoProposalEnabled = true인 템플릿만 가져옴
    final templates =
        await _ref.read(autoProposalTemplatesProvider(teacherId).future);

    if (templates.isEmpty) {
      // 자동 제안 대상 템플릿이 없음
      return null;
    }

    // 4. Determine which templates to include
    List<SubscriptionTemplate> proposalTemplates;
    if (settings.autoProposalTemplateIds.isNotEmpty) {
      // Use only specified templates (that are also auto-proposal enabled)
      proposalTemplates = templates
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
        discountReason =
            '골든타임 할인 (${settings.goldenTimeDiscountPercent}%, ${settings.goldenTimeHours}시간 이내)';
      }
    }

    // 6. Create the proposal
    final notifier =
        _ref.read(subscriptionProposalNotifierProvider.notifier);

    final proposal = await notifier.createMultiChoiceProposal(
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
    buffer.write('체험레슨 수고하셨습니다! ');

    if (settings.hasGoldenTimeDiscount) {
      buffer.write('${settings.goldenTimeHours}시간 이내 결제 시 ');
      buffer.write('${settings.goldenTimeDiscountPercent}% 할인이 적용됩니다. ');
    }

    buffer.write('원하시는 수강권을 선택해주세요.');
    return buffer.toString();
  }
}
