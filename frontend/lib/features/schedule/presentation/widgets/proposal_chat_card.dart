import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/domain/entities/subscription_template.dart';

/// Compact proposal card rendered inside a chat bubble.
///
/// Shows template info (name, price, lesson count) in a compact format.
/// Read-only — action buttons are in [CurrentRequestBox].
class ProposalChatCard extends StatelessWidget {
  final List<SubscriptionTemplate> templates;
  final String? recommendedTemplateId;
  final String? bankInfo;

  const ProposalChatCard({
    super.key,
    required this.templates,
    this.recommendedTemplateId,
    this.bankInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space2),
        // Template list
        ...templates.map(_buildTemplateRow),
        // Bank info
        if (bankInfo != null && bankInfo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance,
                    size: 14, color: AppColors.textTertiaryLight),
                const SizedBox(width: AppSpacing.space1),
                Expanded(
                  child: Text(
                    bankInfo!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTemplateRow(SubscriptionTemplate template) {
    final isRecommended = template.id == recommendedTemplateId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: isRecommended
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isRecommended ? AppColors.primary : AppColors.borderLight,
            width: isRecommended ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isRecommended) ...[
              const Text('\u2B50', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                template.name,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isRecommended ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            Text(
              template.summaryText,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
