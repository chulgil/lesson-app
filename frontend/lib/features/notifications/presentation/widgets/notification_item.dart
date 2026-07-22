import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/notification.dart';

/// 개별 알림 항목 — Notebook × Score.
///
/// §7.130 binary rule: 알림 title/body 는 시스템 생성 메시지이므로 sans-serif 유지.
/// 시각 정렬:
/// - 색상 ink/paper/paperAccent 3색 (이모지·alpha 변형 제거)
/// - 1px ThinRule 구분선 (0.5px BoxDecoration 금지)
/// - 사각형 인디케이터 + 모노톤 Material Icon
/// - 시간은 IBM Plex Mono (metaMono)
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  /// 행 단위 destructive 액션 (swipe-to-dismiss). null 이면 swipe 비활성.
  ///
  /// 호출자는 #629 DELETE /notifications/{id} 와 로컬 상태 invalidate 를
  /// 묶어서 전달한다 (notification_list_screen 참조).
  final Future<void> Function()? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDeleteNotificationConfirmTitle,
      content: const Text(AppStrings.swipeActionDeleteNotificationConfirmBody),
      confirmLabel: AppStrings.delete,
      onConfirm: () => Navigator.pop(context, true),
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context, false),
      isDestructive: true,
    );
    if (confirmed == true) {
      await onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    final row = Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            color: isUnread ? AppColors.paperAccentSoft : AppColors.paper,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon (square + ink stroke + paper bg)
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
                                    isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          // §7.131: 시간 → IBM Plex Mono (시스템 메타)
                          Text(
                            _formatTime(notification.createdAt),
                            style: NotebookTypography.metaMono.copyWith(
                              fontSize: 10,
                              color: AppColors.inkTertiary,
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

                      // Action label (uppercase eyebrow on paper)
                      if (notification.actionLabel != null) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space3,
                            vertical: AppSpacing.space1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            border: Border.all(color: AppColors.ink, width: 1),
                          ),
                          child: Text(
                            notification.actionLabel!.toUpperCase(),
                            style: NotebookTypography.sectionLabel.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Unread indicator — 사각 잉크 마크 (round dot 금지)
                if (isUnread) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Container(width: 6, height: 6, color: AppColors.paperAccent),
                ],
              ],
            ),
          ),
        ),
        // §7.131: 0.5px BoxDecoration → 1px ThinRule (separate component)
        const ThinRule(),
      ],
    );

    if (onDelete == null) {
      return row;
    }

    // swipe 3원칙: destructive 단일 [삭제] + 확인 다이얼로그.
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionDelete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmDelete(context),
        ),
      ],
      child: row,
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: _getIconStrokeColor(), width: 1),
      ),
      child: Center(
        child: Icon(_getIcon(), size: 18, color: _getIconStrokeColor()),
      ),
    );
  }

  /// §7.131: 우선순위는 ink 톤 차이로만 표현 (alpha 변형 금지).
  Color _getIconStrokeColor() {
    switch (notification.priority) {
      case NotificationPriority.urgent:
      case NotificationPriority.high:
        return AppColors.paperAccent;
      case NotificationPriority.normal:
        return AppColors.ink;
      case NotificationPriority.low:
        return AppColors.inkTertiary;
    }
  }

  /// §7.131: 이모지 → Material outlined Icon (모노톤).
  IconData _getIcon() {
    switch (notification.type) {
      // Lesson
      case NotificationType.lessonBooked:
      case NotificationType.lessonReminder:
      case NotificationType.lessonStarting:
        return Icons.event_note_outlined;
      case NotificationType.lessonCancelled:
        return Icons.event_busy_outlined;
      case NotificationType.lessonRescheduled:
        return Icons.update_outlined;
      case NotificationType.lessonCompleted:
        return Icons.check_circle_outline;
      case NotificationType.lessonNoteShared:
        return Icons.note_alt_outlined;

      // Practice
      case NotificationType.practiceReminder:
      case NotificationType.practiceAssigned:
        return Icons.assignment_outlined;
      case NotificationType.streakWarning:
        return Icons.warning_amber_outlined;
      case NotificationType.streakMilestone:
        return Icons.local_fire_department_outlined;
      case NotificationType.weeklyGoalAchieved:
        return Icons.emoji_events_outlined;
      case NotificationType.recordingFeedbackReceived:
        return Icons.rate_review_outlined;

      // Payment
      case NotificationType.paymentRequested:
      case NotificationType.paymentReminder:
      case NotificationType.paymentReceived:
      case NotificationType.paymentConfirmed:
      case NotificationType.lessonsRunningLow:
        return Icons.receipt_long_outlined;

      // No-show / cancellation
      case NotificationType.noshowWarning:
      case NotificationType.noshowConfirmed:
      case NotificationType.teacherNoshow:
        return Icons.report_outlined;
      case NotificationType.compensationApplied:
      case NotificationType.cancellationDeadline:
        return Icons.access_time_outlined;

      // Management
      case NotificationType.newStudentRegistered:
      case NotificationType.trialBookingRequest:
      case NotificationType.lessonRequestReceived:
        return Icons.person_add_outlined;
      case NotificationType.studentPracticeReport:
        return Icons.bar_chart_outlined;
      case NotificationType.reviewReceived:
        return Icons.star_border_outlined;

      // Connection
      case NotificationType.connectionRequestReceived:
        return Icons.link_outlined;
      case NotificationType.connectionRequestAccepted:
      case NotificationType.connectionEstablished:
        return Icons.handshake_outlined;
      case NotificationType.connectionRequestRejected:
      case NotificationType.connectionDisconnected:
        return Icons.link_off_outlined;

      // Makeup
      case NotificationType.makeupLessonCreated:
        return Icons.replay_outlined;
      case NotificationType.makeupLessonExpiring:
      case NotificationType.makeupLessonExpired:
        return Icons.hourglass_bottom_outlined;

      // Schedule change
      case NotificationType.scheduleChangeRequested:
      case NotificationType.scheduleChangeApproved:
      case NotificationType.scheduleChangeRejected:
      case NotificationType.scheduleChangeAlternative:
        return Icons.swap_horiz_outlined;

      // Subscription proposal
      case NotificationType.proposalReceived:
      case NotificationType.proposalAccepted:
        return Icons.confirmation_number_outlined;
      case NotificationType.proposalReminder24h:
      case NotificationType.proposalReminder48h:
        return Icons.notifications_active_outlined;
      case NotificationType.proposalReminder72h:
        return Icons.alarm_outlined;
      case NotificationType.proposalExpired:
        return Icons.hourglass_disabled_outlined;

      // Subscription expiry
      case NotificationType.subscriptionExpiringSoon:
        return Icons.timer_outlined;
      case NotificationType.subscriptionExpired:
        return Icons.block_outlined;

      // Reschedule allowance
      case NotificationType.rescheduleAllowanceUsed:
        return Icons.history_outlined;
      case NotificationType.rescheduleAllowanceDepleted:
        return Icons.error_outline;

      // Bulk teacher actions (§7.119)
      case NotificationType.generalAnnouncement:
        return Icons.campaign_outlined;

      // System auto-send notices (teacher-only)
      case NotificationType.paymentReminderSentNotice:
      case NotificationType.renewalReminderSentNotice:
        return Icons.send_outlined;

      // Payment pending reminder series (학생용 D-1/D-3/D-7)
      case NotificationType.paymentPendingD1:
      case NotificationType.paymentPendingD3:
      case NotificationType.paymentPendingD7Final:
        return Icons.receipt_long_outlined;

      // Schedule confirmation required (양측 확정)
      case NotificationType.scheduleConfirmationRequired:
        return Icons.event_available_outlined;

      // Profile reminder series (선생님용 24h/3d/7d)
      case NotificationType.profileReminder24h:
      case NotificationType.profileReminder3d:
      case NotificationType.profileReminder7d:
        return Icons.person_outline;
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
