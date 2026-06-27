import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Info banner shown when the same session has 3 consecutive
/// schedule-change expiries (spec §8.1).
///
/// Uses info tone (profileBlue) — not the warning/error paperAccent.
/// Does NOT block re-requests; it is advisory only.
class ExpiryStreakBanner extends StatelessWidget {
  const ExpiryStreakBanner({super.key});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.profileBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.profileBlue.withValues(alpha: 0.10), // profileBlue 10% alpha
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: color),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.profileBlue.withValues(alpha: 0.15), // profileBlue 15% alpha
                    ),
                    child: Text(
                      AppStrings.scheduleChangeExpiredBannerTitle,
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    AppStrings.scheduleChangeExpiredBannerBody,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
