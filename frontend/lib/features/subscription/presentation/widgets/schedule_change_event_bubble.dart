import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/presentation/extensions/request_event_visuals.dart';
import '../../../schedule/presentation/extensions/unified_lesson_request_visuals.dart';

/// Renders a single schedule change event as a chat bubble.
///
/// Alignment: if event.actorType matches viewerRole, bubble is right (mine),
/// otherwise left (theirs). Color: right = primary light, left = grey light.
class ScheduleChangeEventBubble extends StatelessWidget {
  final RequestEvent event;
  final String viewerRole; // 'teacher' or 'student'
  final String? studentName;
  final String? teacherName;
  final List<RequestEvent> previousEvents;

  /// Session range for bulk change labels (e.g., 4~10).
  final int? bulkFromSession;
  final int? bulkToSession;

  /// Reschedule credits info for requested events.
  final int? rescheduleCreditsUsed;
  final int? rescheduleCreditsRemaining;

  /// Callback when the opponent's avatar is tapped.
  final VoidCallback? onOpponentAvatarTap;

  const ScheduleChangeEventBubble({
    super.key,
    required this.event,
    required this.viewerRole,
    this.studentName,
    this.teacherName,
    this.previousEvents = const [],
    this.bulkFromSession,
    this.bulkToSession,
    this.rescheduleCreditsUsed,
    this.rescheduleCreditsRemaining,
    this.onOpponentAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = _isMyMessage();
    final actorName = _actorName();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        mainAxisAlignment: isMyMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: opponent avatar
          if (!isMyMessage) ...[
            GestureDetector(
              onTap: onOpponentAvatarTap,
              child: CircleAvatar(
                radius: AppSpacing.avatarSmall / 2,
                backgroundColor: AppColors.scheduleMutedBackground,
                child: Text(
                  actorName.isNotEmpty ? actorName[0] : '?',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSecondary,
                  ),
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
                Padding(
                  padding: EdgeInsets.only(
                    left: isMyMessage ? 0 : AppSpacing.space1,
                    right: isMyMessage ? AppSpacing.space1 : 0,
                    bottom: AppSpacing.space1,
                  ),
                  child: Text(
                    actorName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),

                // Bubble
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppColors.paperAccentSoft
                        : AppColors.paperDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusLarge),
                      topRight: const Radius.circular(AppSpacing.radiusLarge),
                      bottomLeft: Radius.circular(
                        isMyMessage ? AppSpacing.radiusLarge : 4,
                      ),
                      bottomRight: Radius.circular(
                        isMyMessage ? 4 : AppSpacing.radiusLarge,
                      ),
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
      final name = teacherName;
      return name == null ? AppStrings.teacher : '$name ${AppStrings.teacher}';
    }
    final name = studentName;
    return name == null ? AppStrings.student : '$name ${AppStrings.student}';
  }

  /// Main bubble content dispatched by event type.
  Widget _buildBubbleContent() {
    return switch (event.eventType) {
      RequestEventType.scheduleChangeProposed ||
      RequestEventType.scheduleChangeCountered => _buildProposedContent(),
      RequestEventType.scheduleChangeAccepted => _buildAcceptedContent(),
      RequestEventType.scheduleChangeRejected => _buildRejectedContent(),
      RequestEventType.scheduleChangeExpired => _buildExpiredContent(),
      // scheduleChanged is used as "requested" in this context
      RequestEventType.scheduleChanged => _buildRequestedContent(),
      RequestEventType.lessonCancelled => _buildCancelledContent(),
      RequestEventType.lessonCancelledByTeacher =>
        _buildTeacherCancelledContent(),
      RequestEventType.teacherAnnouncement => _buildAnnouncementContent(),
      RequestEventType.withdrawApproval => _buildWithdrawContent(),
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
            color: AppColors.ink,
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
              color: AppColors.inkSecondary,
            ),
          ),
        ],

        // Reason
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${AppStrings.reasonPrefix}${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],

        if (event.suggestedSlots.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildSlotCards(event.suggestedSlots),
        ],
      ],
    );
  }

  Widget _buildCancelledContent() {
    final sessionNum = event.sessionNumber ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$sessionNum회차 레슨 취소를 요청했어요',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (rescheduleCreditsUsed != null &&
            rescheduleCreditsRemaining != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.cancelCreditWillBeUsed(rescheduleCreditsRemaining!),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.cancelKeepsSessionAfterRequest(sessionNum),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${AppStrings.reasonPrefix}${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// §7.119 v2: 선생님 사유 휴강 버블
  Widget _buildTeacherCancelledContent() {
    final session = event.sessionNumber;
    final remaining = event.changeCreditRemainingAfter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session != null
              ? AppStrings.bulkCancelSessionLabel(session)
              : AppStrings.eventLessonCancelledByTeacher,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const ThinRule(),
        Text(
          AppStrings.chatLessonCancelledByTeacher,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            '사유: ${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space2),
        Text(
          remaining != null
              ? AppStrings.bulkCancelCreditRemaining(remaining)
              : AppStrings.bulkCancelNoCreditDeduction,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
        if (event.keepsSessionNumber == true)
          Text(
            AppStrings.bulkCancelKeepsSession,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.bulkCancelRescheduleCta,
          style: AppTypography.bodySmall.copyWith(color: AppColors.paperAccent),
        ),
      ],
    );
  }

  /// §7.119 v2: 선생님 공지 메시지 버블
  Widget _buildAnnouncementContent() {
    final fullMessage = event.message ?? '';
    final newlineIndex = fullMessage.indexOf('\n');
    final title = newlineIndex > 0
        ? fullMessage.substring(0, newlineIndex)
        : fullMessage;
    final body = newlineIndex > 0
        ? fullMessage.substring(newlineIndex + 1).trim()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.eventTeacherAnnouncement,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const ThinRule(),
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWithdrawContent() {
    final selectedSlotLabel = _resolveSelectedSlotLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결정을 변경했습니다',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (selectedSlotLabel != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            selectedSlotLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              decoration: TextDecoration.lineThrough,
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
    final isBulk = event.scheduleChangeType == ScheduleChangeType.bulkChange;

    // Header text
    final String headerText;
    if (isCounter) {
      headerText = AppStrings.counterProposed;
    } else if (isBulk && bulkFromSession != null && bulkToSession != null) {
      headerText = AppStrings.bulkChangeProposed(
        bulkFromSession!,
        bulkToSession!,
      );
    } else {
      headerText = AppStrings.sessionChangeProposed(event.sessionNumber ?? 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          headerText,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
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
              color: AppColors.inkSecondary,
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
        Text(
          sessionNum > 0
              ? AppStrings.sessionScheduleConfirmed(sessionNum)
              : AppStrings.scheduleConfirmed,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),

        if (selectedSlotLabel != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            selectedSlotLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],

        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            event.message!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
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
            color: AppColors.ink,
          ),
        ),

        // Reason
        if (event.message != null && event.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${AppStrings.reasonPrefix}${event.message}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// scheduleChangeExpired: 72h 무응답 자동 만료 — #692.
  ///
  /// 요청자(viewerRole 이 proposer 와 일치) 에게는 "다시 요청하기" action 버튼,
  /// 응답자에게는 wait(grey) 상태 텍스트만 표시.
  Widget _buildExpiredContent() {
    final isRequester = event.actorType == ProposerRole.system
        ? false // 시스템 이벤트 — 발신자 불명 → 기본 wait
        : (event.actorType == ProposerRole.teacher) ==
              (viewerRole == 'teacher');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.chatScheduleChangeExpired,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
        if (isRequester) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.scheduleChangeExpiredRequesterAction,
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
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
        color: AppColors.ink,
      ),
    );
  }

  /// Render 1~3 TimeSlotOption as priority-numbered chips.
  Widget _buildSlotCards(List<TimeSlotOption> slots) {
    final displaySlots = slots.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary, width: 1),
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
                        ? AppColors.paperAccentSoft
                        : AppColors.scheduleMutedBackground,
                  ),
                  child: Text(
                    AppStrings.slotPriority(i + 1),
                    style: AppTypography.caption.copyWith(
                      color: i == 0
                          ? AppColors.paperAccent
                          : AppColors.inkSecondary,
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
                      color: AppColors.ink,
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
    final dayLabel = dayOfWeekLabel(event.proposedDayOfWeek!);
    final time = event.proposedTime!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary, width: 1),
      ),
      child: Text(
        AppStrings.fixedScheduleLabel('$dayLabel $time'),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.ink,
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
    for (final previousEvent in previousEvents.reversed) {
      if (previousEvent.suggestedSlots.isEmpty) continue;
      if (idx >= 0 && idx < previousEvent.suggestedSlots.length) {
        return previousEvent.suggestedSlots[idx].displayLabel;
      }
    }
    return null;
  }

  /// Timestamp widget: "오후 2:32".
  Widget _buildTimestamp(DateTime time) {
    return Text(
      formatTimeAMPM(time),
      style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
    );
  }
}
