import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';
import '../utils/subscription_status_colors.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: SubscriptionStatusColors.getCardOpacity(subscription),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: SubscriptionStatusColors.getBorderColor(subscription),
              width: SubscriptionStatusColors.getBorderWidth(subscription),
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
                            color: AppColors.inkSecondary,
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
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      // Summary text (실제 남은 횟수)
                      Text(
                        subscription.summaryText,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SubscriptionStatusColors.getSummaryTextColor(
                              subscription),
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

            // Warnings (multiple possible)
            ..._buildWarnings(),
          ],
        ),
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
        color = AppColors.primary;
        break;
      case SubscriptionType.monthly:
        icon = Icons.calendar_month;
        color = AppColors.primary;
        break;
      case SubscriptionType.package:
        icon = Icons.confirmation_number_outlined;
        color = AppColors.primary;
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: SubscriptionStatusColors.getBadgeBackground(subscription),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        SubscriptionStatusColors.getLabel(subscription),
        style: AppTypography.caption.copyWith(
          color: SubscriptionStatusColors.getColor(subscription),
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
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        subscription.bonusText ?? '',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final percentage = subscription.usagePercentage ?? 0;
    final progressColor =
        SubscriptionStatusColors.getProgressColor(subscription);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: AppColors.inkQuaternary,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          Text(
            '${percentage.toInt()}%',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: progressColor,
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
            backgroundColor: AppColors.inkQuaternary,
            valueColor: AlwaysStoppedAnimation<Color>(
              SubscriptionStatusColors.getProgressColor(subscription),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '남음: ${subscription.remainingLessons ?? 0}/$total회',
              style: AppTypography.caption.copyWith(
                color: SubscriptionStatusColors.getSummaryTextColor(
                    subscription),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subscription.hasBonus)
              Text(
                '(기본 $base + 보너스 ${subscription.bonusCount})',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
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
        color: AppColors.paperDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 상세',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
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
              valueColor: AppColors.primary,
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
                ? AppColors.paperAccent
                : AppColors.primary,
            isBold: true,
          ),
          // 변경 횟수
          _buildDetailRow(
            '• 변경',
            AppStrings.rescheduleCount(
              subscription.remainingReschedule,
              subscription.totalRescheduleAllowance,
            ),
            valueColor: subscription.remainingReschedule <= 0
                ? AppColors.inkTertiary
                : subscription.remainingReschedule == 1
                    ? AppColors.paperAccent
                    : null,
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
                color: AppColors.paperAccent,
              ),
            ),
          ],
          // 회차권 안내 (만료되지 않은 경우만)
          if (subscription.type == SubscriptionType.package &&
              subscription.status != SubscriptionStatus.expired) ...[
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '유효기간 내 자유롭게 사용',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
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
              color: AppColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: valueColor ?? AppColors.ink,
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

  List<Widget> _buildWarnings() {
    final warnings = <({String text, Color color})>[];

    // Remaining lessons warning
    final remaining = subscription.remainingLessons;
    if (remaining != null && remaining <= renewalAlertThreshold) {
      if (remaining <= 1) {
        warnings.add((
          text: AppStrings.lastLessonWarning,
          color: AppColors.paperAccent,
        ));
      } else {
        warnings.add((
          text: AppStrings.remainingLessonsWarning(remaining),
          color: AppColors.paperAccent,
        ));
      }
    }

    // Expiration warning
    final days = subscription.daysUntilExpiration;
    if (days != null && days <= renewalAlertDays) {
      if (days <= 3) {
        warnings.add((
          text: AppStrings.expirationUrgent(days),
          color: AppColors.paperAccent,
        ));
      } else {
        warnings.add((
          text: AppStrings.expirationDday(days),
          color: AppColors.paperAccent,
        ));
      }
    }

    // Reschedule warning
    if (subscription.remainingReschedule <= 0) {
      warnings.add((
        text: AppStrings.rescheduleUnavailable,
        color: AppColors.inkTertiary,
      ));
    } else if (subscription.remainingReschedule == 1) {
      warnings.add((
        text: AppStrings.rescheduleLastOne,
        color: AppColors.paperAccent,
      ));
    }

    if (warnings.isEmpty) return [];

    return [
      const SizedBox(height: AppSpacing.space3),
      ...warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space1),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: w.color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      w.text,
                      style: AppTypography.caption.copyWith(
                        color: w.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
    ];
  }

}
