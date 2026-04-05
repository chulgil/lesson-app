import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/subscription.dart';

/// Action box for subscription detail screen — bottom action buttons.
///
/// Shows context-aware actions based on subscription status and viewer role:
/// - Student: [시간 변경] [취소 요청]
/// - Teacher: [레슨 완료] [시간 변경]
/// - Expired/Depleted: no actions
class SubscriptionActionBox extends StatelessWidget {
  final Subscription subscription;
  final String viewerRole;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onLessonComplete;

  const SubscriptionActionBox({
    super.key,
    required this.subscription,
    this.viewerRole = 'student',
    this.onReschedule,
    this.onCancel,
    this.onLessonComplete,
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
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _isTeacher ? _buildTeacherActions() : _buildStudentActions(),
      ),
    );
  }

  Widget _buildStudentActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: subscription.canReschedule ? onReschedule : null,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(
              subscription.canReschedule
                  ? AppStrings.rescheduleAction
                  : AppStrings.rescheduleDisabled,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: subscription.canReschedule
                    ? AppColors.primary
                    : AppColors.borderLight,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(AppStrings.cancelRequest),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
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
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReschedule,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(AppStrings.rescheduleAction),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
