import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';

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
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Center(
          child: Text(
            AppStrings.noHistory,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
      );
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
    // For approve/acceptAlternative: resolve the confirmed slot
    final isAcceptEvent =
        event.eventType == RequestEventType.approve ||
        event.eventType == RequestEventType.acceptAlternative;
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

        // User message
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
}
