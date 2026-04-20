import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Compact badge widget for showing subscription status in lists.
class SubscriptionBadge extends StatelessWidget {
  final Subscription subscription;
  final bool showIcon;

  const SubscriptionBadge({
    super.key,
    required this.subscription,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_getIcon(), size: 12, color: _getTextColor()),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            _getLabel(),
            style: AppTypography.caption.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
    if (subscription.type == SubscriptionType.package) {
      // Use totalLessonsForDisplay to include bonus lessons
      return '${subscription.remainingLessons}/${subscription.totalLessonsForDisplay}회';
    } else if (subscription.type == SubscriptionType.monthly) {
      final days = subscription.daysUntilExpiration ?? 0;
      return days > 0 ? 'D-$days' : '만료';
    } else {
      return '체험';
    }
  }

  IconData _getIcon() {
    switch (subscription.type) {
      case SubscriptionType.trial:
        return Icons.star;
      case SubscriptionType.monthly:
        return Icons.calendar_month;
      case SubscriptionType.package:
        return Icons.confirmation_number;
    }
  }

  Color _getBackgroundColor() {
    if (subscription.status == SubscriptionStatus.expired) {
      return AppColors.error.withValues(alpha: 0.1);
    }
    if (subscription.isExpiringSoon) {
      return AppColors.warning.withValues(alpha: 0.1);
    }
    return AppColors.primary.withValues(alpha: 0.1);
  }

  Color _getTextColor() {
    if (subscription.status == SubscriptionStatus.expired) {
      return AppColors.error;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }
}

/// Mini progress indicator for subscription usage.
class SubscriptionProgressMini extends StatelessWidget {
  final Subscription subscription;
  final double size;

  const SubscriptionProgressMini({
    super.key,
    required this.subscription,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.type != SubscriptionType.package) {
      return const SizedBox.shrink();
    }

    final percentage = subscription.usagePercentage ?? 0;
    final color =
        subscription.isExpiringSoon ? AppColors.warning : AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 3,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${subscription.remainingLessons}',
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary text widget for subscription.
class SubscriptionSummaryText extends StatelessWidget {
  final Subscription subscription;
  final TextStyle? style;

  const SubscriptionSummaryText({
    super.key,
    required this.subscription,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = AppTypography.bodySmall.copyWith(
      color:
          subscription.isExpiringSoon
              ? AppColors.warning
              : AppColors.textSecondaryLight,
    );

    String text;
    if (subscription.type == SubscriptionType.package) {
      // Use totalLessonsForDisplay to include bonus lessons
      text =
          '🎟️ ${subscription.remainingLessons}/${subscription.totalLessonsForDisplay}회 남음';
    } else if (subscription.type == SubscriptionType.monthly) {
      final days = subscription.daysUntilExpiration ?? 0;
      text = days > 0 ? '📅 D-$days 남음' : '📅 만료됨';
    } else {
      text = '🆓 체험중';
    }

    return Text(text, style: style ?? defaultStyle);
  }
}
