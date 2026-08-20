import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription_template.dart';
import '../extensions/subscription_template_visuals.dart';

/// Maximum number of templates that can be selected.
const kMaxTemplateSelections = 3;

/// Selectable card for subscription templates.
///
/// Features:
/// - Selected: 2px paperAccent (vermillion) border + top-right check icon
/// - Recommended: ⭐ badge (paperAccent)
/// - Max 3 selections: remaining cards at 40% opacity
/// - AnimatedContainer 200ms transition
class SelectableTemplateCard extends StatelessWidget {
  final SubscriptionTemplate template;
  final bool isSelected;
  final bool isRecommended;
  final bool isDisabled;
  final VoidCallback? onTap;

  /// J15b — this template belongs to the 반 the request was pinned to. Badged
  /// so a 1:1 template is not proposed to a cohort applicant by accident.
  final bool isGroupClassMatch;

  const SelectableTemplateCard({
    super.key,
    required this.template,
    this.isSelected = false,
    this.isRecommended = false,
    this.isDisabled = false,
    this.onTap,
    this.isGroupClassMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          isDisabled && !isSelected
              ? null
              : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled && !isSelected ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + badges + check
              Row(
                children: [
                  if (isRecommended) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                      ),
                      child: Text(
                        AppStrings.templateRecommendedBadgeStar,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                  ],
                  if (isGroupClassMatch) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.paperAccentSoft,
                      ),
                      child: Text(
                        AppStrings.templateGroupClassBadge,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                  ],
                  Expanded(
                    child: Text(
                      template.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? AppColors.paperAccent : AppColors.ink,
                      ),
                    ),
                  ),
                  // Check icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.inkQuaternary,
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.paper,
                            )
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              // Summary: lessons, duration, validity
              Text(
                AppStrings.templateSummaryLine(
                  totalLessons: template.totalLessons,
                  durationMinutes: template.lessonDurationMinutes,
                  validityLabel: template.formattedValidity,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),

              // Price row
              Row(
                children: [
                  Text(
                    template.formattedPrice,
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.paperAccent : AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    AppStrings.templatePerLessonPrice(
                      template.formattedPricePerLesson,
                    ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),

              // Description if available
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  template.description!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
