import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/chapter_guide_box.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import 'proposal_chat_card.dart';

/// Chat-style history of all events in a lesson request.
///
/// Layout: KakaoTalk style — student bubbles left, teacher bubbles right.
/// Events are displayed chronologically (oldest first, newest at bottom).
class RequestHistoryChat extends StatelessWidget {
  final List<RequestEvent> events;
  final String viewerId;
  final String viewerRole;
  final String studentName;
  final String? studentProfileUrl;
  final UnifiedLessonRequest? request;
  final VoidCallback? onOpponentAvatarTap;

  /// Proposal template data for rendering proposal cards in chat.
  final List<SubscriptionTemplate> proposalTemplates;
  final String? recommendedTemplateId;

  /// When true, uses shrinkWrap + NeverScrollableScrollPhysics
  /// so this widget can be placed inside another scrollable.
  final bool shrinkWrap;

  /// When false, hides the top guide box (for collapsed chapter history).
  final bool showGuide;

  const RequestHistoryChat({
    super.key,
    required this.events,
    required this.viewerId,
    this.viewerRole = 'teacher',
    required this.studentName,
    this.studentProfileUrl,
    this.request,
    this.onOpponentAvatarTap,
    this.proposalTemplates = const [],
    this.recommendedTemplateId,
    this.shrinkWrap = false,
    this.showGuide = true,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyWithGuide(context);
    }

    // Chronological: oldest first, newest at bottom (chat style)
    final chronological = [...events]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Detect withdraw+re-approve(same slot) pairs to hide redundant withdraws
    final (hiddenWithdrawIds, messageOnlyApproveIds) = _findSameSlotPairs(
      chronological,
    );

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space4,
      ),
      itemCount: showGuide ? chronological.length + 1 : chronological.length,
      itemBuilder: (context, index) {
        // First item: system guide message (only when showGuide is true)
        if (showGuide && index == 0) {
          return _buildSystemGuide();
        }

        final eventIndex = showGuide ? index - 1 : index;
        final event = chronological[eventIndex];

        // Skip withdraw events where the same slot was re-approved
        if (hiddenWithdrawIds.contains(event.id)) {
          return const SizedBox.shrink();
        }

        final isMyMessage = event.actorId == viewerId;
        final isMessageOnly = messageOnlyApproveIds.contains(event.id);
        Widget? dateSeparator;
        if (eventIndex == 0 ||
            !_isSameDay(
              chronological[eventIndex - 1].createdAt,
              event.createdAt,
            )) {
          dateSeparator = _buildDateSeparator(event.createdAt);
        }

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            _buildChatBubble(event, isMyMessage, isMessageOnly: isMessageOnly),
          ],
        );
      },
    );
  }

  /// Chat bubble: left (opponent) or right (me)
  Widget _buildChatBubble(
    RequestEvent event,
    bool isMyMessage, {
    bool isMessageOnly = false,
  }) {
    final actorName =
        event.actorType == ProposerRole.student
            ? studentName
            : AppStrings.teacher;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: opponent avatar + name
          if (!isMyMessage) ...[
            GestureDetector(
              onTap: onOpponentAvatarTap,
              child: CircleAvatar(
                radius: AppSpacing.avatarSmall / 2,
                backgroundColor: AppColors.scheduleMutedBackground,
                backgroundImage:
                    studentProfileUrl != null &&
                            event.actorType == ProposerRole.student
                        ? NetworkImage(studentProfileUrl!)
                        : null,
                child:
                    studentProfileUrl == null ||
                            event.actorType == ProposerRole.teacher
                        ? Text(
                          actorName.isNotEmpty ? actorName[0] : '?',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSecondary,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
          ],

          // Bubble content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.space1,
                      bottom: AppSpacing.space1,
                    ),
                    child: Text(
                      actorName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    // Color by role (not viewer): teacher=primary, student=secondary
                    color:
                        event.actorType == ProposerRole.teacher
                            ? AppColors.paperAccent.withValues(alpha: 0.08)
                            : AppColors.paperDark,
                  ),
                  child: _buildBubbleContent(
                    event,
                    isMessageOnly: isMessageOnly,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                _buildTimestamp(event.createdAt),
              ],
            ),
          ),

          // Right: spacing for my messages (no avatar)
          if (isMyMessage) const SizedBox(width: AppSpacing.space2),
        ],
      ),
    );
  }

  /// Build slot label widgets for an event.
  /// For initialRequest: uses request.preferredSlots (date-aware).
  /// For other events with suggestedSlots: uses TimeSlotOption.displayLabel.
  List<Widget> _buildSlotLabels(RequestEvent event) {
    List<String> labels;

    if (event.eventType == RequestEventType.initialRequest &&
        request != null &&
        request!.preferredSlots.isNotEmpty) {
      // Use PreferredTimeSlot.displayLabel (includes date)
      final sorted = [...request!.preferredSlots]
        ..sort((a, b) => a.priority.compareTo(b.priority));
      labels = sorted.map((ps) => ps.displayLabel).toList();
    } else if (event.suggestedSlots.isNotEmpty) {
      labels = event.suggestedSlots.take(3).map((s) => s.displayLabel).toList();
    } else {
      return [];
    }

    return [
      const SizedBox(height: AppSpacing.space2),
      ...labels.asMap().entries.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space1 / 2),
          child: Text(
            '${entry.key + 1}순위 ${entry.value}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
    ];
  }

  /// Check if event is a bulk schedule change (proposed/countered with bulkChange type).
  bool _isBulkScheduleChangeEvent(RequestEvent event) {
    return (event.eventType == RequestEventType.scheduleChangeProposed ||
            event.eventType == RequestEventType.scheduleChangeCountered) &&
        event.scheduleChangeType == ScheduleChangeType.bulkChange;
  }

  /// Find the confirmed slot label for approve/acceptAlternative/withdraw events.
  /// Uses request.preferredSlots (date-aware) when available.
  String? _resolveConfirmedSlotLabel(RequestEvent event) {
    if (event.selectedSlotIndex == null) return null;
    final idx = event.selectedSlotIndex!;

    // First try: use request's preferredSlots (date-aware)
    if (request != null && request!.preferredSlots.isNotEmpty) {
      final sorted = [...request!.preferredSlots]
        ..sort((a, b) => a.priority.compareTo(b.priority));
      if (idx >= 0 && idx < sorted.length) {
        return sorted[idx].displayLabel;
      }
    }

    // Fallback: search backwards through events for suggestedSlots
    final eventIndex = events.indexOf(event);
    for (int i = eventIndex - 1; i >= 0; i--) {
      final prev = events[i];
      if (prev.suggestedSlots.isNotEmpty) {
        if (idx >= 0 && idx < prev.suggestedSlots.length) {
          return prev.suggestedSlots[idx].displayLabel;
        }
      }
    }
    return null;
  }

  /// Bubble inner content: status text + optional slots + optional message
  Widget _buildBubbleContent(RequestEvent event, {bool isMessageOnly = false}) {
    // For approve/acceptAlternative/scheduleChangeAccepted: resolve the confirmed slot
    final isAcceptEvent =
        event.eventType == RequestEventType.approve ||
        event.eventType == RequestEventType.acceptAlternative ||
        event.eventType == RequestEventType.scheduleChangeAccepted;
    final isWithdrawEvent =
        event.eventType == RequestEventType.withdrawApproval;
    final confirmedSlotLabel =
        (isAcceptEvent || isWithdrawEvent) && !isMessageOnly
            ? _resolveConfirmedSlotLabel(event)
            : null;

    // Determine display label
    final String displayLabel;
    if (isMessageOnly) {
      displayLabel = AppStrings.chatMessageAdded;
    } else if (event.eventType == RequestEventType.initialRequest &&
        request != null) {
      displayLabel =
          '${request!.instrument} ${request!.typeDisplayLabel}${AppStrings.lessonRequestSuffix}';
    } else {
      displayLabel = event.chatDisplayMessage;
    }

    // Proposal card for proposalSent events
    final isProposalEvent =
        event.eventType == RequestEventType.proposalSent &&
        proposalTemplates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event type label
        Text(
          displayLabel,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),

        // Proposal card with template info
        if (isProposalEvent)
          ProposalChatCard(
            templates: proposalTemplates,
            recommendedTemplateId: recommendedTemplateId,
          ),

        // Confirmed/withdrawn slot (same style as initial request slots)
        if (confirmedSlotLabel != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            confirmedSlotLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              decoration: isWithdrawEvent ? TextDecoration.lineThrough : null,
            ),
          ),
        ],

        // Time slots — use preferredSlots for initialRequest (date-aware),
        // suggestedSlots for other events
        ..._buildSlotLabels(event),

        // Bulk schedule change: show proposed day/time
        if (_isBulkScheduleChangeEvent(event) &&
            event.proposedDayOfWeek != null &&
            event.proposedTime != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${dayOfWeekLabel(event.proposedDayOfWeek!)} ${event.proposedTime}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // User message (skip for proposal events — template info replaces it)
        if (event.message != null &&
            event.message!.isNotEmpty &&
            !isProposalEvent) ...[
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

  /// Status-specific guide at the top of chat history.
  /// Delegates rendering to shared [ChapterGuideBox] (core/widgets/).
  Widget _buildSystemGuide() {
    final guide = _getPhaseGuide();
    if (guide == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: ChapterGuideBox(title: guide.title, situation: guide.situation),
    );
  }

  /// Date separator: "3월 25일 화요일"
  Widget _buildDateSeparator(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dayLabel = weekdays[date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.inkQuaternary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            child: Text(
              '${date.month}월 ${date.day}일 $dayLabel요일',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.inkQuaternary)),
        ],
      ),
    );
  }

  /// Timestamp: "오후 2:32"
  Widget _buildTimestamp(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');

    return Text(
      '$period $displayHour:$minuteStr',
      style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
    );
  }

  /// Find withdraw → re-approve pairs where the slot didn't change.
  /// Hide the withdraw and show the re-approve as "메시지 추가".
  ///
  /// Matching rules (from most to least specific):
  /// 1. Both have selectedSlotIndex and they match → same slot
  /// 2. Both have selectedSlotIndex but differ → different slot (don't hide)
  /// 3. Either has null selectedSlotIndex → treat as same slot (fallback)
  ///    (null usually means the index wasn't recorded, not that it changed)
  (Set<String> hiddenWithdraws, Set<String> messageOnlyApproves)
  _findSameSlotPairs(List<RequestEvent> sorted) {
    final hiddenWithdraws = <String>{};
    final messageOnlyApproves = <String>{};

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].eventType != RequestEventType.withdrawApproval) continue;
      final withdraw = sorted[i];

      // Find the next approve/acceptAlternative after this withdraw
      for (int j = i + 1; j < sorted.length; j++) {
        final candidate = sorted[j];
        if (candidate.eventType == RequestEventType.approve ||
            candidate.eventType == RequestEventType.acceptAlternative) {
          // Determine if slot changed
          final withdrawSlot = withdraw.selectedSlotIndex;
          final approveSlot = candidate.selectedSlotIndex;

          final bool isSameSlot;
          if (withdrawSlot != null && approveSlot != null) {
            isSameSlot = withdrawSlot == approveSlot;
          } else {
            // If either is null, default to same-slot (message-only)
            isSameSlot = true;
          }

          if (isSameSlot) {
            hiddenWithdraws.add(withdraw.id);
            messageOnlyApproves.add(candidate.id);
          }
          break;
        }
        if (candidate.eventType == RequestEventType.withdrawApproval) break;
      }
    }

    return (hiddenWithdraws, messageOnlyApproves);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Empty state: same guide box as chat top + "no history" text.
  Widget _buildEmptyWithGuide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        children: [
          // Same guide box as _buildSystemGuide
          _buildSystemGuide(),

          // Empty history message
          Center(
            child: Text(
              AppStrings.noHistory,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  /// Get phase-specific guide based on request status.
  /// Each guide has a title (chip label) and messages (chat bubble lines).
  _PhaseGuide? _getPhaseGuide() {
    if (request == null) return null;
    final isTeacher = viewerId == request!.teacherId;
    final title =
        isTeacher ? request!.teacherActionLabel : request!.studentActionLabel;

    return switch (request!.status) {
      UnifiedRequestStatus.pending =>
        isTeacher
            ? _PhaseGuide(
              title: title,
              situation: '희망 시간을 확인하고 수락 또는 다른 시간을 제안해주세요',
            )
            : _PhaseGuide(title: title, situation: '선생님의 응답을 기다리고 있습니다'),

      UnifiedRequestStatus.approved || UnifiedRequestStatus.negotiating =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '시간을 수락하거나 다른 시간을 역제안해주세요')
            : _PhaseGuide(title: title, situation: '제안된 시간을 확인하고 수락해주세요'),

      UnifiedRequestStatus.timeConfirmed =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '수강권 종류와 결제 방법을 선택해 발급해주세요')
            : _PhaseGuide(title: title, situation: '선생님이 수강권 안내를 보내면 알림을 드립니다'),

      UnifiedRequestStatus.proposalSent =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '학생이 수락하면 알림을 드립니다')
            : _PhaseGuide(title: title, situation: '수강권 안내를 확인하고 수락 또는 거절해주세요'),

      UnifiedRequestStatus.proposalAccepted =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '학생이 입금하면 알림을 드립니다')
            : _PhaseGuide(title: title, situation: '결제를 완료해주세요'),

      UnifiedRequestStatus.paymentNotified =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '입금을 확인하고 수강권을 발급해주세요')
            : _PhaseGuide(title: title, situation: '선생님이 확인하면 수강권이 발급됩니다'),

      UnifiedRequestStatus.subscriptionIssued => _PhaseGuide(
        title: title,
        situation: '레슨을 시작할 준비가 완료되었습니다',
      ),

      UnifiedRequestStatus.inProgress =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '레슨 후 출석 처리와 기록을 남겨주세요')
            : _PhaseGuide(title: title, situation: '레슨 일정에 맞춰 참석해주세요'),

      UnifiedRequestStatus.completed => _PhaseGuide(
        title: title,
        situation: '모든 레슨 수강이 완료되었습니다',
      ),

      UnifiedRequestStatus.rejected =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '이 레슨 요청을 거절했습니다')
            : _PhaseGuide(
              title: title,
              situation: '다른 선생님이나 시간을 변경해 다시 신청할 수 있습니다',
            ),

      UnifiedRequestStatus.cancelled => _PhaseGuide(
        title: title,
        situation: '이 레슨 요청이 취소되었습니다',
      ),

      UnifiedRequestStatus.expired =>
        isTeacher
            ? _PhaseGuide(title: title, situation: '응답 기간이 지나 자동 종료되었습니다')
            : _PhaseGuide(title: title, situation: '다시 신청하시면 선생님에게 알림이 전송됩니다'),
    };
  }
}

/// Phase guide: [title chip] + [situation text] in a single info box.
/// title = actionLabel (리스트와 동일), situation = 한 줄 안내.
class _PhaseGuide {
  final String title;
  final String situation;

  const _PhaseGuide({required this.title, required this.situation});
}
