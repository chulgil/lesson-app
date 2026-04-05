import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';

/// Renders a single schedule change event as a chat bubble.
///
/// Alignment: if event.actorType matches viewerRole, bubble is right (mine),
/// otherwise left (theirs). Color: right = primary light, left = grey light.
class ScheduleChangeEventBubble extends StatelessWidget {
  final RequestEvent event;
  final String viewerRole; // 'teacher' or 'student'
  final String? studentName;
  final String? teacherName;

  /// Session range for bulk change labels (e.g., 4~10).
  final int? bulkFromSession;
  final int? bulkToSession;

  /// Reschedule credits info for requested events.
  final int? rescheduleCreditsUsed;
  final int? rescheduleCreditsRemaining;

  const ScheduleChangeEventBubble({
    super.key,
    required this.event,
    required this.viewerRole,
    this.studentName,
    this.teacherName,
    this.bulkFromSession,
    this.bulkToSession,
    this.rescheduleCreditsUsed,
    this.rescheduleCreditsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = _isMyMessage();
    final actorName = _actorName();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: opponent avatar
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: AppSpacing.avatarSmall / 2,
              backgroundColor: AppColors.scheduleMutedBackground,
              child: Text(
                actorName.isNotEmpty ? actorName[0] : '?',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
          ],

          // Bubble content
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Actor name (only for opponent bubbles)
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.space1,
                      bottom: AppSpacing.space1,
                    ),
                    child: Text(
                      actorName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),

                // Bubble
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceSecondaryLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusLarge),
                      topRight: const Radius.circular(AppSpacing.radiusLarge),
                      bottomLeft: Radius.circular(
                          isMyMessage ? AppSpacing.radiusLarge : 4),
                      bottomRight: Radius.circular(
                          isMyMessage ? 4 : AppSpacing.radiusLarge),
                    ),
                  ),
                  child: _buildBubbleContent(),
                ),

                // Timestamp
                const SizedBox(height: AppSpacing.space1),
                _buildTimestamp(event.createdAt),
              ],
            ),
          ),

          // Right: spacing for my messages
          if (isMyMessage) const SizedBox(width: AppSpacing.space2),
        ],
      ),
    );
  }

  /// Whether this event's actor matches the viewer role.
  bool _isMyMessage() {
    final actorRole = event.actorType == ProposerRole.teacher
        ? 'teacher'
        : 'student';
    return actorRole == viewerRole;
  }

  /// Display name for the event actor.
  String _actorName() {
    if (event.actorType == ProposerRole.teacher) {
      return teacherName ?? AppStrings.teacher;
    }
    return studentName ?? '';
  }

  /// Main bubble content dispatched by event type.
  Widget _buildBubbleContent() {
    return switch (event.eventType) {
      RequestEventType.scheduleChangeProposed ||
      RequestEventType.scheduleChangeCountered =>
        _buildProposedContent(),
      RequestEventType.scheduleChangeAccepted => _buildAcceptedContent(),
      RequestEventType.scheduleChangeRejected => _buildRejectedContent(),
      // scheduleChanged is used as "requested" in this context
      RequestEventType.scheduleChanged => _buildRequestedContent(),
      _ => _buildGenericContent(),
    };
  }

  /// scheduleChangeRequested: student requests a schedule change.
  Widget _buildRequestedContent() {
    final sessionNum = event.sessionNumber ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          AppStrings.sessionChangeRequested(sessionNum),
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),

        // Reschedule credits info
        if (rescheduleCreditsUsed != null &&
            rescheduleCreditsRemaining != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.rescheduleCreditsUsed(
              rescheduleCreditsUsed!,
              rescheduleCreditsRemaining!,
            ),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],

        // Reason
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${AppStrings.reasonPrefix}${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  /// scheduleChangeProposed / scheduleChangeCountered:
  /// teacher proposes time slots (single or bulk).
  Widget _buildProposedContent() {
    final isCounter =
        event.eventType == RequestEventType.scheduleChangeCountered;
    final isBulk =
        event.scheduleChangeType == ScheduleChangeType.bulkChange;

    // Header text
    final String headerText;
    if (isCounter) {
      headerText = AppStrings.counterProposed;
    } else if (isBulk &&
        bulkFromSession != null &&
        bulkToSession != null) {
      headerText =
          AppStrings.bulkChangeProposed(bulkFromSession!, bulkToSession!);
    } else {
      headerText =
          AppStrings.sessionChangeProposed(event.sessionNumber ?? 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          headerText,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),

        // Slot cards
        if (isBulk &&
            event.proposedDayOfWeek != null &&
            event.proposedTime != null) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildBulkSlotCard(),
        ] else if (event.suggestedSlots.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildSlotCards(event.suggestedSlots),
        ],

        // Message
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            event.message!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  /// scheduleChangeAccepted: slot chosen + confirmation.
  Widget _buildAcceptedContent() {
    // Resolve the selected slot label
    final String? selectedSlotLabel = _resolveSelectedSlotLabel();
    final sessionNum = event.sessionNumber ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "[slot]을 선택했습니다"
        if (selectedSlotLabel != null)
          Text(
            AppStrings.slotAccepted(selectedSlotLabel),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),

        // Confirmation line
        if (selectedSlotLabel != null && sessionNum > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: Text(
                  AppStrings.sessionConfirmed(sessionNum, selectedSlotLabel),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// scheduleChangeRejected: rejection with reason.
  Widget _buildRejectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.changeRejected,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),

        // Reason
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${AppStrings.reasonPrefix}${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  /// Fallback for unhandled event types.
  Widget _buildGenericContent() {
    return Text(
      event.chatDisplayMessage,
      style: AppTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  /// Render 1~3 TimeSlotOption as priority-numbered chips.
  Widget _buildSlotCards(List<TimeSlotOption> slots) {
    final displaySlots = slots.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < displaySlots.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space1),
            Row(
              children: [
                // Priority chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.scheduleMutedBackground,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    AppStrings.slotPriority(i + 1),
                    style: AppTypography.caption.copyWith(
                      color: i == 0
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                // Slot label
                Expanded(
                  child: Text(
                    displaySlots[i].displayLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Render bulk change slot card: "매주 [day] [time]".
  Widget _buildBulkSlotCard() {
    final dayLabel =
        LessonScheduleChange.dayOfWeekLabel(event.proposedDayOfWeek!);
    final time = event.proposedTime!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Text(
        AppStrings.fixedScheduleLabel('$dayLabel $time'),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Resolve the selected slot label from suggestedSlots + selectedSlotIndex.
  String? _resolveSelectedSlotLabel() {
    final idx = event.selectedSlotIndex;
    if (idx == null) return null;

    if (event.suggestedSlots.isNotEmpty &&
        idx >= 0 &&
        idx < event.suggestedSlots.length) {
      return event.suggestedSlots[idx].displayLabel;
    }
    return null;
  }

  /// Timestamp widget: "오후 2:32".
  Widget _buildTimestamp(DateTime time) {
    return Text(
      formatTimeAMPM(time),
      style: AppTypography.caption.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    );
  }
}
