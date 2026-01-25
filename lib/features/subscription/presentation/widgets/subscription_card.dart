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
  final bool showDetails;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.className,
    this.instrument,
    this.onTap,
    this.showDetails = true,
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

            // Subscription info with progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label (기본 횟수만)
                      Text(
                        subscription.typeLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      // Summary text (실제 남은 횟수)
                      Text(
                        subscription.summaryText,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: subscription.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      // Bonus badge (보너스 있을 때)
                      if (subscription.hasBonus) ...[
                        const SizedBox(height: AppSpacing.space1),
                        _buildBonusBadge(),
                      ],
                    ],
                  ),
                ),
                // Progress indicator for all types except trial
                if (subscription.type != SubscriptionType.trial) ...[
                  _buildProgressIndicator(),
                ],
              ],
            ),

            // Progress bar (all types except trial)
            if (subscription.type != SubscriptionType.trial) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildProgressBar(),
            ],

            // Detail section (상세 정보)
            if (showDetails &&
                subscription.type != SubscriptionType.trial) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildDetailSection(),
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

  Widget _buildBonusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        subscription.bonusText ?? '',
        style: AppTypography.caption.copyWith(
          color: AppColors.info,
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
    final total = subscription.totalLessonsForDisplay ?? 0;
    final base = subscription.baseLessons ?? 0;

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
              subscription.hasBonus
                  ? '전체: $total회 (기본 $base + 보너스 ${subscription.bonusCount})'
                  : '전체: $total회',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 상세',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // 기본 횟수
          _buildDetailRow(
            '• 기본',
            '${subscription.baseLessons ?? 0}회',
          ),
          // 보너스 (있을 때만)
          if (subscription.hasBonus) ...[
            _buildDetailRow(
              '• 보너스',
              '+${subscription.bonusCount}회 (${subscription.bonusReason ?? "보너스"})',
              valueColor: AppColors.info,
            ),
          ],
          // 사용 횟수
          _buildDetailRow(
            '• 사용',
            '${subscription.usedLessons}회',
          ),
          // 남은 횟수
          _buildDetailRow(
            '• 잔여',
            '${subscription.remainingLessons ?? 0}회',
            valueColor: subscription.isExpiringSoon
                ? AppColors.warning
                : AppColors.success,
            isBold: true,
          ),
          // 유효기간
          if (subscription.endDate != null) ...[
            const SizedBox(height: AppSpacing.space1),
            _buildDetailRow(
              '• 유효기간',
              _formatDate(subscription.endDate!),
            ),
          ],
          // 결제 방식 (선생님/학원용)
          if (subscription.billingTypeLabel != null) ...[
            _buildDetailRow(
              '• 결제',
              subscription.billingTypeLabel!,
            ),
          ],
          // 5주차 정책 (월정액만)
          if (subscription.type == SubscriptionType.monthly &&
              subscription.fifthWeekPolicyLabel != null) ...[
            _buildDetailRow(
              '• 5주차',
              subscription.fifthWeekPolicyLabel!,
            ),
          ],
          // 월정액 이월 경고
          if (subscription.type == SubscriptionType.monthly) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '⚠️ 미사용분 소멸 (이월 불가)',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
          // 회차권 이월 안내
          if (subscription.type == SubscriptionType.package) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '✅ 유효기간 내 이월 가능',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: valueColor ?? AppColors.textPrimaryLight,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Widget _buildExpirationWarning() {
    String message;
    if (subscription.remainingLessons != null &&
        subscription.remainingLessons! <= 2) {
      message = '⚠️ 잔여 ${subscription.remainingLessons}회 - 수강권 갱신을 권장합니다';
    } else if (subscription.daysUntilExpiration != null &&
        subscription.daysUntilExpiration! <= 7) {
      message = '⚠️ D-${subscription.daysUntilExpiration} - 유효기간 만료 임박';
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
