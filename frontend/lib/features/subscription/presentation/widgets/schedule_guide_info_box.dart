import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Guide info box displayed between progress bar and chat area
/// in the subscription detail screen.
///
/// Matches [RequestHistoryChat._buildSystemGuide] style:
/// - Icon: lightbulb_outline (18px)
/// - Color: AppColors.ink
/// - Background: info.withValues(alpha: 0.06)
/// - Structure: [title chip] + [situation text]
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: guide.color.withValues(alpha: 0.06),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: guide.color),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title chip — matches RequestHistoryChat guide style
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: guide.color.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      guide.title,
                      style: AppTypography.caption.copyWith(
                        color: guide.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  // Situation text
                  Text(
                    guide.message,
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

  _GuideContent _resolveGuide() {
    // Priority 1: Reschedule credits exhausted (student only)
    if (subscription.remainingReschedule <= 0 && viewerRole == 'student') {
      return const _GuideContent(
        title: AppStrings.scheduleChangeTitle,
        color: AppColors.paperAccent,
        message: AppStrings.rescheduleCreditsExhausted,
      );
    }

    // Priority 2: Bulk mode active
    if (isBulkMode) {
      return const _GuideContent(
        title: AppStrings.scheduleChangeTitle,
        color: AppColors.paperAccent,
        message: AppStrings.guideBulkModeMessage,
      );
    }

    // Priority 3: Package type with unbooked sessions
    if (subscription.type == SubscriptionType.package &&
        _hasUnbookedSessions) {
      return const _GuideContent(
        title: AppStrings.scheduleChangeTitle,
        color: AppColors.ink,
        message: AppStrings.packageGuideMessage,
      );
    }

    // Priority 4: Default
    return const _GuideContent(
      title: AppStrings.scheduleChangeTitle,
      color: AppColors.ink,
      message: AppStrings.guideDefaultMessage,
    );
  }

  bool get _hasUnbookedSessions {
    final remaining = subscription.remainingLessons;
    return remaining != null && remaining > 0;
  }
}

class _GuideContent {
  final String title;
  final Color color;
  final String message;

  const _GuideContent({
    required this.title,
    required this.color,
    required this.message,
  });
}
