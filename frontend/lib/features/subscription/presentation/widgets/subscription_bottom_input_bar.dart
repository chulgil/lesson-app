import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Bottom input bar for the subscription detail screen.
///
/// Shows message input, schedule change button, and role-specific actions.
/// Hidden when the subscription is expired or depleted.
class SubscriptionBottomInputBar extends StatelessWidget {
  final Subscription subscription;
  final String viewerRole;
  final TextEditingController messageController;
  final VoidCallback? onSendMessage;
  final VoidCallback? onScheduleChange;
  final VoidCallback? onLessonComplete;
  final VoidCallback? onCancel;
  final bool isBulkMode;

  const SubscriptionBottomInputBar({
    super.key,
    required this.subscription,
    required this.viewerRole,
    required this.messageController,
    this.onSendMessage,
    this.onScheduleChange,
    this.onLessonComplete,
    this.onCancel,
    this.isBulkMode = false,
  });

  bool get _isTeacher => viewerRole == 'teacher';

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpired || subscription.isDepleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMessageInputRow(),
            const SizedBox(height: AppSpacing.space2),
            _isTeacher
                ? _buildTeacherActions()
                : _buildStudentActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: messageController,
            decoration: InputDecoration(
              hintText: AppStrings.subscriptionMessageHint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusRound),
                borderSide:
                    BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusRound),
                borderSide:
                    BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusRound),
                borderSide:
                    const BorderSide(color: AppColors.primary),
              ),
            ),
            style: AppTypography.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        OutlinedButton.icon(
          onPressed: onScheduleChange,
          icon: const Icon(Icons.schedule, size: 16),
          label: Text(AppStrings.scheduleChangeButton),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            textStyle: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onLessonComplete,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(AppStrings.lessonComplete),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(AppStrings.cancelRequest),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
