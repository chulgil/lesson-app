import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/subscription_visuals.dart';
import '../utils/subscription_status_colors.dart';

/// Card widget displaying subscription information.
///
/// When [compact] is true, renders a concert ticket-style layout
/// with instrument-colored header, dashed tear line, and compact stats.
/// When false (default), renders the full detail card with progress bar,
/// detail section, and warnings.
class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final String? className;
  final String? instrument;
  final VoidCallback? onTap;
  final bool showDetails;

  /// When true, renders a compact ticket-style card.
  final bool compact;

  /// Person name displayed in compact mode (student or teacher name).
  final String? personName;

  /// Threshold for renewal alert (remaining lessons).
  /// Default: 1 (alert when 1 or fewer lessons remain).
  final int renewalAlertThreshold;

  /// Threshold for renewal alert (days until expiration).
  /// Default: 7 (alert when 7 or fewer days remain).
  final int renewalAlertDays;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.className,
    this.instrument,
    this.onTap,
    this.showDetails = true,
    this.compact = false,
    this.personName,
    this.renewalAlertThreshold = 1,
    this.renewalAlertDays = 7,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  // ─── Compact (ticket-style) layout ────────────────────────────

  Widget _buildCompact() {
    final accentColor = _subscriptionTypeColor;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: SubscriptionStatusColors.getCardOpacity(subscription),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children: [
              _buildCompactHeader(accentColor),
              _buildCompactTearLine(accentColor),
              _buildCompactStats(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(_compactInstrumentIcon, size: 24, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _compactDisplayTitle,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                if (personName != null)
                  Text(
                    personName!,
                    style: AppTypography.bodySmall.copyWith(
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          _buildCompactStatusBadge(accentColor),
        ],
      ),
    );
  }

  Widget _buildCompactTearLine(Color accentColor) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: -10,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: const BoxDecoration(color: AppColors.paper),
            ),
          ),
          Positioned(
            right: -10,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: const BoxDecoration(color: AppColors.paper),
            ),
          ),
          Center(
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(
                color: accentColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(Color accentColor) {
    final remaining = subscription.remainingLessons ?? 0;
    final total = subscription.totalLessonsForDisplay ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subscription.typeLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              Text(
                '$remaining/$total${AppStrings.remainingCountSuffix}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SubscriptionStatusColors.getSummaryTextColor(
                    subscription,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            child: LinearProgressIndicator(
              value: total > 0 ? (total - remaining) / total : 0,
              minHeight: 6,
              backgroundColor: AppColors.inkQuaternary,
              valueColor: AlwaysStoppedAnimation<Color>(
                SubscriptionStatusColors.getProgressColor(subscription),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      subscription.canReschedule
                          ? accentColor.withValues(alpha: 0.1)
                          : AppColors.inkQuaternary.withValues(alpha: 0.5),
                ),
                child: Text(
                  '${AppStrings.rescheduleLabel} ${subscription.remainingReschedule}${AppStrings.countSuffix}',
                  style: AppTypography.caption.copyWith(
                    color:
                        subscription.canReschedule
                            ? accentColor
                            : AppColors.inkTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge(Color accentColor) {
    final isActive = subscription.status == SubscriptionStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color:
            isActive
                ? accentColor.withValues(alpha: 0.15)
                : SubscriptionStatusColors.getBadgeBackground(subscription),
      ),
      child: Text(
        SubscriptionStatusColors.getLabel(subscription),
        style: AppTypography.caption.copyWith(
          color:
              isActive
                  ? accentColor
                  : SubscriptionStatusColors.getColor(subscription),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData get _compactInstrumentIcon {
    switch (subscription.type) {
      case SubscriptionType.trial:
        return Icons.star_outline;
      case SubscriptionType.monthly:
        return Icons.calendar_month;
      case SubscriptionType.package:
        return Icons.confirmation_number_outlined;
    }
  }

  /// Subscription type color — 3색 잉크 체계:
  /// trial = paperTrial (세피아 앰버 — 호기심, 첫 만남)
  /// monthly = paperOk (녹색 펜 — 안정, 꾸준한 일상)
  /// package = paperAccent (버밀리온 — 매회 출석 체크)
  Color get _subscriptionTypeColor {
    switch (subscription.type) {
      case SubscriptionType.trial:
        return AppColors.paperTrial;
      case SubscriptionType.monthly:
        return AppColors.paperOk;
      case SubscriptionType.package:
        return AppColors.paperAccent;
    }
  }

  String get _compactDisplayTitle {
    if (instrument != null && className != null) {
      return '$instrument $className';
    }
    return className ?? instrument ?? subscription.typeLabel;
  }

  // ─── Full (detail) layout ─────────────────────────────────────

  Widget _buildFull() {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: SubscriptionStatusColors.getCardOpacity(subscription),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
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
              const ThinRule(),
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
                              subscription,
                            ),
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
        color = AppColors.paperTrial;
        break;
      case SubscriptionType.monthly:
        icon = Icons.calendar_month;
        color = AppColors.paperOk;
        break;
      case SubscriptionType.package:
        icon = Icons.confirmation_number_outlined;
        color = AppColors.paperAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
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
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Text(
        subscription.bonusText ?? '',
        style: AppTypography.caption.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final percentage = subscription.usagePercentage ?? 0;
    final progressColor = SubscriptionStatusColors.getProgressColor(
      subscription,
    );
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
              AppStrings.subscriptionRemainingPrefix(
                subscription.remainingLessons ?? 0,
                total,
              ),
              style: AppTypography.caption.copyWith(
                color: SubscriptionStatusColors.getSummaryTextColor(
                  subscription,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subscription.hasBonus)
              Text(
                AppStrings.subscriptionBonusBreakdown(
                  base,
                  subscription.bonusCount,
                ),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.subscriptionDetailHeader,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // 기본 횟수
          _buildDetailRow(
            AppStrings.subscriptionDetailRowBase,
            AppStrings.usageCountShort(subscription.baseLessons ?? 0),
          ),
          // 보너스 (있을 때만)
          if (subscription.hasBonus) ...[
            _buildDetailRow(
              AppStrings.subscriptionDetailRowBonus,
              AppStrings.issueFormSummaryBonusValue(
                subscription.bonusCount,
                subscription.bonusReason ??
                    AppStrings.subscriptionBonusReasonFallback,
              ),
              valueColor: AppColors.paperAccent,
            ),
          ],
          // 사용 횟수
          _buildDetailRow(
            AppStrings.subscriptionDetailRowUsed,
            AppStrings.usageCountShort(subscription.usedLessons),
          ),
          // 남은 횟수
          _buildDetailRow(
            AppStrings.subscriptionDetailRowRemaining,
            AppStrings.usageCountShort(subscription.remainingLessons ?? 0),
            valueColor:
                subscription.isExpiringSoon
                    ? AppColors.paperAccent
                    : AppColors.paperAccent,
            isBold: true,
          ),
          // 변경 횟수
          _buildDetailRow(
            AppStrings.subscriptionDetailRowChanges,
            AppStrings.rescheduleCount(
              subscription.remainingReschedule,
              subscription.totalRescheduleAllowance,
            ),
            valueColor:
                subscription.remainingReschedule <= 0
                    ? AppColors.inkTertiary
                    : subscription.remainingReschedule == 1
                    ? AppColors.paperAccent
                    : null,
          ),
          // 유효기간
          if (subscription.endDate != null) ...[
            const SizedBox(height: AppSpacing.space1),
            _buildDetailRow(
              AppStrings.subscriptionDetailRowExpiry,
              _formatDate(subscription.endDate!),
            ),
          ],
          // 입금 확인 방식 (선생님/학원용)
          if (subscription.billingTypeLabel != null) ...[
            _buildDetailRow(
              AppStrings.subscriptionDetailRowPayment,
              subscription.billingTypeLabel!,
            ),
          ],
          // 5주차 정책 (월정액만)
          if (subscription.type == SubscriptionType.monthly &&
              subscription.fifthWeekPolicyLabel != null) ...[
            _buildDetailRow(
              AppStrings.subscriptionDetailRowFifthWeek,
              subscription.fifthWeekPolicyLabel!,
            ),
          ],
          // 월정액 이월 경고 (만료되지 않은 경우만)
          if (subscription.type == SubscriptionType.monthly &&
              subscription.status != SubscriptionStatus.expired) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.subscriptionMonthlyCarryoverWarning,
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
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  AppStrings.subscriptionPackageFreeUseInfo,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
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
      ...warnings.map(
        (w) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space1),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(color: w.color.withValues(alpha: 0.1)),
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
        ),
      ),
    ];
  }
}

/// Custom painter for dashed line (tear effect) used in compact mode.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 20;

    while (startX < size.width - 20) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
