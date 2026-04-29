import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/subscription_template.dart';

/// A card displaying a single template option with accept button.
///
/// Used in [StudentProposalAcceptScreen] to show each template choice
/// with price, validity, duration estimate, and a selection button.
class TemplateChoiceCard extends StatelessWidget {
  final SubscriptionTemplate template;
  final bool isRecommended;
  final bool isProcessing;
  final VoidCallback onAccept;

  const TemplateChoiceCard({
    super.key,
    required this.template,
    required this.isRecommended,
    required this.isProcessing,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final unitPrice = template.pricePerLesson;
    final months = (template.validityDays / 30).round();
    final monthsLabel = months > 0 ? '$months' : '1';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color:
              isRecommended ? AppColors.paperAccent : AppColors.inkQuaternary,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with recommended badge
          Row(
            children: [
              if (isRecommended) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(color: AppColors.paperAccent),
                  child: Text(
                    AppStrings.templateRecommendedBadge,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              Text(
                template.name,
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space2),

          // Price and validity
          Text(
            AppStrings.templatePriceValidity(
              price: formatWonWithComma(template.price),
              days: template.validityDays,
            ),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),

          const SizedBox(height: AppSpacing.space1),

          // Duration estimate
          Text(
            AppStrings.templateMonthlyEstimate(monthsLabel),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),

          // Unit price (only for multi-lesson packages)
          if (template.totalLessons > 1) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.templateUnitPriceLabel(formatWonWithComma(unitPrice)),
              style: AppTypography.bodySmall.copyWith(
                color:
                    isRecommended
                        ? AppColors.paperAccent
                        : AppColors.inkTertiary,
                fontWeight: isRecommended ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space3),

          // Accept button (aligned right)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: AppSpacing.buttonHeightSmall,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  backgroundColor:
                      isRecommended
                          ? AppColors.paperAccent
                          : AppColors.paperDark,
                  foregroundColor:
                      isRecommended ? AppColors.paper : AppColors.ink,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.templateChooseButton,
                  style: AppTypography.buttonSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
