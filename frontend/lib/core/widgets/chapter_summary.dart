import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Collapsible chapter header for the lesson lifecycle chat view.
///
/// Shows an icon + title + date + summary when collapsed (one line).
/// Expands to show full content (child widget) when tapped.
class ChapterSummary extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? completedDate;
  final String? summary;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? child;

  const ChapterSummary({
    super.key,
    required this.icon,
    required this.title,
    this.completedDate,
    this.summary,
    this.isExpanded = false,
    this.isActive = false,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter divider
        Container(
          width: double.infinity,
          height: 1,
          color: AppColors.borderLight,
        ),

        // Chapter header (always visible)
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                // Phase icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.scheduleMutedBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.textPrimaryLight
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (completedDate != null) ...[
                            const SizedBox(width: AppSpacing.space2),
                            Text(
                              completedDate!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Summary line (only when collapsed and has summary)
                      if (!isExpanded && summary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          summary!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Expand/collapse chevron
                if (onTap != null)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textTertiaryLight,
                  ),
              ],
            ),
          ),
        ),

        // Expanded content
        if (isExpanded && child != null) child!,
      ],
    );
  }
}
