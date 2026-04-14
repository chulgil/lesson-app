import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Bottom input bar for the subscription detail screen.
///
/// Matches [CurrentRequestBox] layout pattern:
/// - Message input (multi-line, border radius medium)
/// - Action buttons row (outlined + filled, button height small)
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space3,
        AppSpacing.space3,
        MediaQuery.of(context).padding.bottom + AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message input (matches CurrentRequestBox style)
          _buildMessageInput(),
          const SizedBox(height: AppSpacing.space2),

          // Action buttons row
          _isTeacher ? _buildTeacherActions() : _buildStudentActions(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return TextField(
      controller: messageController,
      maxLines: 4,
      minLines: 1,
      maxLength: 200,
      style: AppTypography.bodySmall,
      decoration: InputDecoration(
        hintText: AppStrings.subscriptionMessageHint,
        hintStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTeacherActions() {
    return Row(
      children: [
        // Schedule change button (outlined)
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeightSmall,
            child: OutlinedButton.icon(
              onPressed: onScheduleChange,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(
                AppStrings.scheduleChangeButton,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),

        // Lesson complete button (filled primary)
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeightSmall,
            child: ElevatedButton.icon(
              onPressed: onLessonComplete,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: Text(
                AppStrings.lessonComplete,
                style: AppTypography.buttonSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentActions() {
    return Row(
      children: [
        // Schedule change button (outlined)
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeightSmall,
            child: OutlinedButton.icon(
              onPressed: onScheduleChange,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(
                AppStrings.scheduleChangeButton,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),

        // Cancel request button (outlined error)
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeightSmall,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: Text(
                AppStrings.cancelRequest,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
