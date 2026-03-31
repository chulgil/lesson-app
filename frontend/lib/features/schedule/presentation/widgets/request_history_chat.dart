import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../domain/entities/lesson_schedule_change.dart';
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

  const RequestHistoryChat({
    super.key,
    required this.events,
    required this.viewerId,
    required this.studentName,
    this.studentProfileUrl,
    this.request,
    this.onOpponentAvatarTap,
    this.proposalTemplates = const [],
    this.recommendedTemplateId,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyWithGuide();
    }

    // Chronological: oldest first, newest at bottom (chat style)
    final chronological = [...events]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Detect withdraw+re-approve(same slot) pairs to hide redundant withdraws
    final (hiddenWithdrawIds, messageOnlyApproveIds) =
        _findSameSlotPairs(chronological);

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space4,
      ),
      itemCount: chronological.length + 1, // +1 for guide message
      itemBuilder: (context, index) {
        // First item: system guide message
        if (index == 0) {
          return _buildSystemGuide();
        }

        final event = chronological[index - 1];

        // Skip withdraw events where the same slot was re-approved
        if (hiddenWithdrawIds.contains(event.id)) {
          return const SizedBox.shrink();
        }

        final isMyMessage = event.actorId == viewerId;
        final isMessageOnly = messageOnlyApproveIds.contains(event.id);

        // Date separator (show if first event or different day from previous)
        final eventIndex = index - 1;
        Widget? dateSeparator;
        if (eventIndex == 0 ||
            !_isSameDay(chronological[eventIndex - 1].createdAt, event.createdAt)) {
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
    final actorName = event.actorType == ProposerRole.student
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
              backgroundImage: studentProfileUrl != null &&
                      event.actorType == ProposerRole.student
                  ? NetworkImage(studentProfileUrl!)
                  : null,
              child: studentProfileUrl == null ||
                      event.actorType == ProposerRole.teacher
                  ? Text(
                      actorName.isNotEmpty ? actorName[0] : '?',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
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
              crossAxisAlignment: isMyMessage
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
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    // Color by role (not viewer): teacher=primary, student=secondary
                    color: event.actorType == ProposerRole.teacher
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
                  child: _buildBubbleContent(event, isMessageOnly: isMessageOnly),
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
      labels = event.suggestedSlots
          .take(3)
          .map((s) => s.displayLabel)
          .toList();
    } else {
      return [];
    }

    return [
      const SizedBox(height: AppSpacing.space2),
      ...labels.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space1 / 2),
            child: Text(
              '${entry.key + 1}순위 ${entry.value}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          )),
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
  Widget _buildBubbleContent(
    RequestEvent event, {
    bool isMessageOnly = false,
  }) {
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
        event.eventType == RequestEventType.proposalSent && proposalTemplates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event type label
        Text(
          displayLabel,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
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
              color: AppColors.textSecondaryLight,
              decoration: isWithdrawEvent
                  ? TextDecoration.lineThrough
                  : null,
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
            '${LessonScheduleChange.dayOfWeekLabel(event.proposedDayOfWeek!)} ${event.proposedTime}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // User message (skip for proposal events — template info replaces it)
        if (event.message != null && event.message!.isNotEmpty && !isProposalEvent) ...[
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

  /// System guide message at the top of chat
  Widget _buildSystemGuide() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline,
                size: 18, color: AppColors.info),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.requestGuideMessage,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
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
          const Expanded(child: Divider(color: AppColors.borderLight)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            child: Text(
              '${date.month}월 ${date.day}일 $dayLabel요일',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.borderLight)),
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
      style: AppTypography.caption.copyWith(
        color: AppColors.textTertiaryLight,
      ),
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

  /// Empty state with phase-specific guide + dashed separator + "no history"
  Widget _buildEmptyWithGuide() {
    final guide = _getPhaseGuide();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space4,
      ),
      child: Column(
        children: [
          // Phase guide notice
          if (guide != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    guide.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Dashed separator
          if (guide != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: _DashedLine(color: AppColors.borderLight),
            ),

          // Empty history message (centered)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: Text(
                AppStrings.noHistory,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get phase-specific guide based on request status
  _PhaseGuide? _getPhaseGuide() {
    if (request == null) return null;

    final isTeacher = viewerId == request!.teacherId;

    return switch (request!.status) {
      // Phase 1: 신청
      UnifiedRequestStatus.pending => isTeacher
          ? const _PhaseGuide(
              title: '신청 단계',
              description:
                  '학생이 레슨을 신청했습니다.\n'
                  '희망 시간을 확인하고 수락하거나, 다른 시간을 제안해주세요.',
            )
          : const _PhaseGuide(
              title: '신청 단계',
              description:
                  '레슨 신청이 완료되었습니다.\n'
                  '선생님이 시간을 확인하면 알림을 보내드립니다.',
            ),

      // Phase 1: 협상 중
      UnifiedRequestStatus.approved ||
      UnifiedRequestStatus.negotiating => isTeacher
          ? const _PhaseGuide(
              title: '시간 확정 단계',
              description:
                  '학생과 시간을 조율하고 있습니다.\n'
                  '시간이 맞지 않으면 다른 시간을 제안할 수 있습니다.',
            )
          : const _PhaseGuide(
              title: '시간 확정 단계',
              description:
                  '선생님과 시간을 조율하고 있습니다.\n'
                  '제안된 시간을 확인해주세요.',
            ),

      // Phase 2: 시간 확정 → 결제/수강권
      UnifiedRequestStatus.timeConfirmed => isTeacher
          ? const _PhaseGuide(
              title: '결제 단계',
              description:
                  '시간이 확정되었습니다.\n'
                  '아래에서 수강권 발급 방법을 선택해주세요.\n'
                  '선불: 결제 안내 후 입금 확인 → 후불: 바로 발급',
            )
          : const _PhaseGuide(
              title: '결제 단계',
              description:
                  '시간이 확정되었습니다.\n'
                  '선생님이 수강권 안내를 보내면 알림을 드립니다.',
            ),

      // Phase 2: 제안 발송됨
      UnifiedRequestStatus.proposalSent ||
      UnifiedRequestStatus.proposalAccepted => isTeacher
          ? const _PhaseGuide(
              title: '결제 대기 단계',
              description:
                  '수강권 안내를 보냈습니다.\n'
                  '학생이 결제를 완료하면 알림을 드립니다.',
            )
          : const _PhaseGuide(
              title: '결제 단계',
              description:
                  '선생님이 보낸 수강권 안내를 확인하고,\n'
                  '결제를 완료해주세요.',
            ),

      // Phase 2: 입금 완료 알림
      UnifiedRequestStatus.paymentNotified => isTeacher
          ? const _PhaseGuide(
              title: '입금 확인 단계',
              description:
                  '학생이 입금 완료를 알렸습니다.\n'
                  '입금을 확인하고 수강권을 발급해주세요.',
            )
          : const _PhaseGuide(
              title: '입금 확인 대기',
              description:
                  '입금 완료를 알렸습니다.\n'
                  '선생님이 확인하면 수강권이 발급됩니다.',
            ),

      // Phase 3: 수강권 발급 → 레슨 진행
      UnifiedRequestStatus.subscriptionIssued ||
      UnifiedRequestStatus.inProgress => isTeacher
          ? const _PhaseGuide(
              title: '레슨 진행 단계',
              description:
                  '수강권이 발급되었습니다.\n'
                  '레슨을 진행하고, 완료 후 기록을 남겨주세요.',
            )
          : const _PhaseGuide(
              title: '레슨 진행 단계',
              description:
                  '수강권이 발급되었습니다.\n'
                  '레슨 일정에 맞춰 참석해주세요.',
            ),

      // Phase 4: 완료
      UnifiedRequestStatus.completed => const _PhaseGuide(
              title: '레슨 완료',
              description: '모든 레슨이 완료되었습니다.',
            ),

      // 종료 상태
      _ => null,
    };
  }
}

/// Phase guide data
class _PhaseGuide {
  final String title;
  final String description;

  const _PhaseGuide({required this.title, required this.description});
}

/// Dashed horizontal line
class _DashedLine extends StatelessWidget {
  final Color color;

  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          })
              .expand((w) => [w, const SizedBox(width: dashSpace)])
              .toList()
            ..removeLast(),
        );
      },
    );
  }
}
