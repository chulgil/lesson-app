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

  /// Threshold for renewal alert (remaining lessons).
  /// Default: 1 (alert when 1 or fewer lessons remain).
  final int renewalAlertThreshold;

  /// Threshold for renewal alert (days until expiration).
  /// Default: 7 (alert when 7 or fewer days remain).
  final int renewalAlertDays;

  /// Callback when renewal button is tapped.
  final VoidCallback? onRenewalTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.className,
    this.instrument,
    this.onTap,
    this.showDetails = true,
    this.renewalAlertThreshold = 1,
    this.renewalAlertDays = 7,
    this.onRenewalTap,
  });

  @override
  Widget build(BuildContext context) {
    // Expired cards have lower opacity to de-emphasize
    final cardOpacity = subscription.isExpired ? 0.7 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: cardOpacity,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: _getBorderColor(),
              width: _getBorderWidth(),
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
                          color: _getSummaryTextColor(),
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
      ),
    );
  }

  double _getBorderWidth() {
    if (subscription.isDepleted || subscription.isExpiringSoon) {
      return 2;
    }
    return 1;
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
    String label;

    // Priority: Depleted > Expired > ExpiringSoon > Paused > Active
    if (subscription.isDepleted) {
      // 사용 완료: Primary (보라) - 긍정적 성취
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
      label = '사용 완료';
    } else if (subscription.isExpired) {
      // 기간 만료: Gray - 중립적 (빨강 X)
      backgroundColor = AppColors.textTertiaryLight.withValues(alpha: 0.1);
      textColor = AppColors.textTertiaryLight;
      label = '만료됨';
    } else if (subscription.isExpiringSoon) {
      // 만료 임박: Warning (주황) - 행동 유도
      backgroundColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      label = '갱신 필요';
    } else if (subscription.status == SubscriptionStatus.paused) {
      // 일시정지: Gray
      backgroundColor = AppColors.textTertiaryLight.withValues(alpha: 0.1);
      textColor = AppColors.textTertiaryLight;
      label = '일시정지';
    } else {
      // 이용중: Success (녹색)
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      label = '이용중';
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
        label,
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
              _getProgressColor(),
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: _getProgressColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (subscription.isDepleted) {
      return AppColors.primary;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.warning;
    }
    if (subscription.isExpired) {
      return AppColors.textTertiaryLight;
    }
    return AppColors.primary;
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
              _getProgressColor(),
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
          // 월정액 이월 경고 (만료되지 않은 경우만)
          if (subscription.type == SubscriptionType.monthly &&
              subscription.status != SubscriptionStatus.expired) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '⚠️ 미사용분 소멸 (이월 불가)',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
          // 회차권 안내 (만료되지 않은 경우만)
          if (subscription.type == SubscriptionType.package &&
              subscription.status != SubscriptionStatus.expired) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '✅ 유효기간 내 자유롭게 사용',
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
        subscription.remainingLessons! <= renewalAlertThreshold) {
      message = '⚠️ 잔여 ${subscription.remainingLessons}회 - 갱신 권장';
    } else if (subscription.daysUntilExpiration != null &&
        subscription.daysUntilExpiration! <= renewalAlertDays) {
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
    if (subscription.isDepleted) {
      return AppColors.primary.withValues(alpha: 0.3);
    }
    if (subscription.isExpiringSoon) {
      return AppColors.warning;
    }
    if (subscription.isExpired) {
      return AppColors.textTertiaryLight.withValues(alpha: 0.3);
    }
    return AppColors.borderLight;
  }

  Color _getSummaryTextColor() {
    if (subscription.isDepleted) {
      return AppColors.primary;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.warning;
    }
    if (subscription.isExpired) {
      return AppColors.textTertiaryLight;
    }
    return AppColors.textPrimaryLight;
  }
}
