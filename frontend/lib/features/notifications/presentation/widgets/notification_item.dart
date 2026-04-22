import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/notification.dart';

/// 개별 알림 항목 위젯
///
/// 재사용 가능한 단일 알림 표시 컴포넌트:
/// - 읽지 않은 알림 강조 (배경색)
/// - 아이콘 + 제목 + 본문 + 시간
/// - 액션 버튼 (있는 경우)
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationItem({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color:
              isUnread
                  ? AppColors.paperAccent.withValues(alpha: 0.05)
                  : Colors.white,
          border: const Border(
            bottom: BorderSide(color: AppColors.inkQuaternary, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _buildIcon(),
            const SizedBox(width: AppSpacing.space3),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.normal,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        _formatTime(notification.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space1),

                  // Body
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Action button (if present)
                  if (notification.actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: Text(
                        notification.actionLabel!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Unread indicator
            if (isUnread) ...[
              const SizedBox(width: AppSpacing.space2),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.paperAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Center(
        child: Text(_getIcon(), style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  String _getIcon() {
    switch (notification.type) {
      // Lesson
      case NotificationType.lessonBooked:
      case NotificationType.lessonReminder:
      case NotificationType.lessonStarting:
        return '🎻';
      case NotificationType.lessonCancelled:
      case NotificationType.lessonRescheduled:
        return '📅';
      case NotificationType.lessonCompleted:
      case NotificationType.lessonNoteShared:
        return '📝';

      // Practice
      case NotificationType.practiceReminder:
      case NotificationType.practiceAssigned:
        return '🎯';
      case NotificationType.streakWarning:
      case NotificationType.streakMilestone:
        return '🔥';
      case NotificationType.weeklyGoalAchieved:
        return '🏆';
      case NotificationType.recordingFeedbackReceived:
        return '📝';

      // Payment
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
      case NotificationType.paymentReceived:
      case NotificationType.paymentConfirmed:
      case NotificationType.lessonsRunningLow:
        return '💰';

      // No-show
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
      case NotificationType.teacherNoshow:
        return '⚠️';
      case NotificationType.compensationApplied:
      case NotificationType.cancellationDeadline:
        return '⏰';

      // Management
      case NotificationType.newStudentRegistered:
      case NotificationType.trialBookingRequest:
        return '👋';
      case NotificationType.studentPracticeReport:
        return '📊';
      case NotificationType.reviewReceived:
        return '⭐';

      // Connection
      case NotificationType.connectionRequestReceived:
        return '🔗';
      case NotificationType.connectionRequestAccepted:
      case NotificationType.connectionEstablished:
        return '✅';
      case NotificationType.connectionRequestRejected:
      case NotificationType.connectionDisconnected:
        return '❌';

      // Makeup
      case NotificationType.makeupLessonCreated:
        return '🔄';
      case NotificationType.makeupLessonExpiring:
      case NotificationType.makeupLessonExpired:
        return '⏳';

      // Schedule change
      case NotificationType.scheduleChangeRequested:
      case NotificationType.scheduleChangeApproved:
      case NotificationType.scheduleChangeRejected:
      case NotificationType.scheduleChangeAlternative:
        return '📆';

      // Subscription proposal
      case NotificationType.proposalReceived:
      case NotificationType.proposalAccepted:
        return '🎫';
      case NotificationType.proposalReminder24h:
      case NotificationType.proposalReminder48h:
        return '💬';
      case NotificationType.proposalReminder72h:
        return '⏰';
      case NotificationType.proposalExpired:
        return '⌛';

      // Subscription expiry
      case NotificationType.subscriptionExpiringSoon:
        return '⏳';
      case NotificationType.subscriptionExpired:
        return '🚫';

      // Reschedule allowance
      case NotificationType.rescheduleAllowanceUsed:
        return '🔄';
      case NotificationType.rescheduleAllowanceDepleted:
        return '⚠️';
    }
  }

  Color _getIconBackgroundColor() {
    switch (notification.priority) {
      case NotificationPriority.urgent:
        return AppColors.paperAccent.withValues(alpha: 0.1);
      case NotificationPriority.high:
        return AppColors.paperAccent.withValues(alpha: 0.2);
      case NotificationPriority.normal:
        return AppColors.paperAccent.withValues(alpha: 0.1);
      case NotificationPriority.low:
        return AppColors.inkSecondary.withValues(alpha: 0.1);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
