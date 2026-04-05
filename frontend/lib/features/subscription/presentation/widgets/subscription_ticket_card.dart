import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../domain/entities/subscription.dart';
import '../utils/subscription_status_colors.dart';

/// Concert ticket-style card for subscription display.
///
/// Inspired by classical concert ticket design with:
/// - Top section: instrument icon + class name + person name
/// - Dashed tear line separator
/// - Bottom section: remaining count + progress + status
class SubscriptionTicketCard extends StatelessWidget {
  final Subscription subscription;
  final String? className;
  final String? instrument;
  final String? personName;
  final VoidCallback? onTap;

  const SubscriptionTicketCard({
    super.key,
    required this.subscription,
    this.className,
    this.instrument,
    this.personName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = InstrumentColors.getColor(instrument ?? '');
    final accentColor = colors.accent;
    final bgColor = colors.background;

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
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // === Top section: Concert header ===
              _buildHeaderSection(accentColor, bgColor),

              // === Dashed tear line ===
              _buildTearLine(accentColor),

              // === Bottom section: Stats ===
              _buildStatsSection(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Color accentColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLarge),
          topRight: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          // Instrument icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              _instrumentIcon,
              size: 24,
              color: accentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Class name + person
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayTitle,
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

          // Status badge
          _buildStatusBadge(accentColor),
        ],
      ),
    );
  }

  Widget _buildTearLine(Color accentColor) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          // Left notch
          Positioned(
            left: -10,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right notch
          Positioned(
            right: -10,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Dashed line
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

  Widget _buildStatsSection(Color accentColor) {
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
          // Type + remaining count row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Type label
              Text(
                subscription.typeLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              // Remaining count
              Text(
                '$remaining/$total${AppStrings.remainingCountSuffix}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SubscriptionStatusColors.getSummaryTextColor(
                      subscription),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space2),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? (total - remaining) / total : 0,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                SubscriptionStatusColors.getProgressColor(subscription),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Bottom row: period + reschedule credits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Period
              if (subscription.startDate != null &&
                  subscription.endDate != null)
                Text(
                  _formatPeriod(
                      subscription.startDate!, subscription.endDate!),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),

              // Reschedule credits
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: subscription.canReschedule
                      ? accentColor.withValues(alpha: 0.1)
                      : AppColors.borderLight.withValues(alpha: 0.5),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  '${AppStrings.rescheduleLabel} ${subscription.remainingReschedule}${AppStrings.countSuffix}',
                  style: AppTypography.caption.copyWith(
                    color: subscription.canReschedule
                        ? accentColor
                        : AppColors.textTertiaryLight,
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

  Widget _buildStatusBadge(Color accentColor) {
    final isActive = subscription.status == SubscriptionStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? accentColor.withValues(alpha: 0.15)
            : SubscriptionStatusColors.getBadgeBackground(subscription),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        SubscriptionStatusColors.getLabel(subscription),
        style: AppTypography.caption.copyWith(
          color: isActive
              ? accentColor
              : SubscriptionStatusColors.getColor(subscription),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData get _instrumentIcon {
    switch (subscription.type) {
      case SubscriptionType.trial:
        return Icons.star_outline;
      case SubscriptionType.monthly:
        return Icons.calendar_month;
      case SubscriptionType.package:
        return Icons.confirmation_number_outlined;
    }
  }

  String get _displayTitle {
    if (instrument != null && className != null) {
      return '$instrument $className';
    }
    return className ?? instrument ?? subscription.typeLabel;
  }

  String _formatPeriod(DateTime start, DateTime end) {
    return '${start.year}.${start.month.toString().padLeft(2, '0')}~${end.month.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for dashed line (tear effect).
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
