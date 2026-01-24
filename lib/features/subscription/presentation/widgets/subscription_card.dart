import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Card widget displaying subscription information.
class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final String? className;
  final String? instrument;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.className,
    this.instrument,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: _getBorderColor(),
            width: subscription.isExpiringSoon ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (className != null)
                        Text(
                          className!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (instrument != null)
                        Text(
                          instrument!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),

            // Subscription info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.typeLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        subscription.summaryText,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: subscription.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subscription.type == SubscriptionType.package) ...[
                  _buildProgressIndicator(),
                ],
              ],
            ),

            // Progress bar for package type
            if (subscription.type == SubscriptionType.package) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildProgressBar(),
            ],

            // Expiration warning
            if (subscription.isExpiringSoon) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildExpirationWarning(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (subscription.type) {
      case SubscriptionType.trial:
        icon = Icons.star_outline;
        color = AppColors.info;
        break;
      case SubscriptionType.monthly:
        icon = Icons.calendar_month;
        color = AppColors.primary;
        break;
      case SubscriptionType.package:
        icon = Icons.confirmation_number_outlined;
        color = AppColors.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;

    switch (subscription.status) {
      case SubscriptionStatus.active:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case SubscriptionStatus.expiringSoon:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case SubscriptionStatus.expired:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case SubscriptionStatus.paused:
        backgroundColor = AppColors.textTertiaryLight.withValues(alpha: 0.1);
        textColor = AppColors.textTertiaryLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        subscription.statusLabel,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final percentage = subscription.usagePercentage ?? 0;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              subscription.isExpiringSoon ? AppColors.warning : AppColors.primary,
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percentage = subscription.usagePercentage ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              subscription.isExpiringSoon ? AppColors.warning : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '사용: ${subscription.usedLessons}회',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '전체: ${subscription.totalLessons}회',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpirationWarning() {
    String message;
    if (subscription.type == SubscriptionType.package) {
      message = '⚠️ 잔여 ${subscription.remainingLessons}회 - 수강권 갱신을 권장합니다';
    } else if (subscription.daysUntilExpiration != null) {
      message = '⚠️ D-${subscription.daysUntilExpiration} - 만료 임박';
    } else {
      message = '⚠️ 수강권 만료 임박';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (subscription.status == SubscriptionStatus.expiringSoon) {
      return AppColors.warning;
    }
    if (subscription.status == SubscriptionStatus.expired) {
      return AppColors.error.withValues(alpha: 0.3);
    }
    return AppColors.borderLight;
  }
}
