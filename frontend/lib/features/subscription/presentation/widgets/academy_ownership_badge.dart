import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academy/domain/entities/academy_enums.dart';
import '../../domain/entities/subscription.dart';

/// Badge indicating subscription is issued by academy (not individual teacher).
///
/// Applied to subscription cards when ownership=academy.
/// Visual: soft background + border-bottom style (Notebook accent bar).
class AcademyOwnershipBadge extends StatelessWidget {
  final Subscription subscription;

  const AcademyOwnershipBadge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    // Only show if academy-issued
    if (subscription.ownership != SubscriptionOwnership.academy) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.profileBlue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.profileBlue, width: 2),
        ),
      ),
      child: Text(
        AppStrings.academyIssuedBadge,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.profileBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
