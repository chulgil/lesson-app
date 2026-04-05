import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Guide info box displayed between progress bar and chat area
/// in the subscription detail screen.
///
/// Shows contextual guidance based on subscription state:
/// 1. Reschedule credits exhausted (student only)
/// 2. Bulk mode active
/// 3. Package type with unbooked sessions
/// 4. Default touch guide
class ScheduleGuideInfoBox extends StatelessWidget {
  final Subscription subscription;
  final bool isBulkMode;
  final String viewerRole;

  const ScheduleGuideInfoBox({
    super.key,
    required this.subscription,
    required this.isBulkMode,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context) {
    final guide = _resolveGuide();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: guide.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(guide.icon, size: 18, color: guide.color),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              guide.message,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _GuideContent _resolveGuide() {
    // Priority 1: Reschedule credits exhausted (student only)
    if (subscription.remainingReschedule <= 0 && viewerRole == 'student') {
      return const _GuideContent(
        icon: Icons.warning_amber,
        color: AppColors.error,
        message: AppStrings.rescheduleCreditsExhausted,
      );
    }

    // Priority 2: Bulk mode active
    if (isBulkMode) {
      return const _GuideContent(
        icon: Icons.date_range,
        color: AppColors.primary,
        message: AppStrings.guideBulkModeMessage,
      );
    }

    // Priority 3: Package type with unbooked sessions
    if (subscription.type == SubscriptionType.package &&
        _hasUnbookedSessions) {
      return const _GuideContent(
        icon: Icons.event_available,
        color: AppColors.info,
        message: AppStrings.packageGuideMessage,
      );
    }

    // Priority 4: Default
    return const _GuideContent(
      icon: Icons.touch_app,
      color: AppColors.textSecondaryLight,
      message: AppStrings.guideDefaultMessage,
    );
  }

  /// Package subscription has unbooked sessions when remaining lessons > 0.
  bool get _hasUnbookedSessions {
    final remaining = subscription.remainingLessons;
    return remaining != null && remaining > 0;
  }
}

/// Internal data class for guide content resolution.
class _GuideContent {
  final IconData icon;
  final Color color;
  final String message;

  const _GuideContent({
    required this.icon,
    required this.color,
    required this.message,
  });
}
