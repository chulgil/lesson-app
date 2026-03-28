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

  const RequestHistoryChat({
    super.key,
    required this.events,
    required this.viewerId,
    required this.studentName,
    this.studentProfileUrl,
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

    // Reverse: newest at top
    final reversed = events.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final event = reversed[index];
        final isMyMessage = event.actorId == viewerId;

        // Date separator (show if first in group or different day from next)
        Widget? dateSeparator;
        if (index == reversed.length - 1 ||
            !_isSameDay(reversed[index + 1].createdAt, event.createdAt)) {
          dateSeparator = _buildDateSeparator(event.createdAt);
        }

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            _buildChatBubble(event, isMyMessage),
          ],
        );
      },
    );
  }

  /// Chat bubble: left (opponent) or right (me)
  Widget _buildChatBubble(RequestEvent event, bool isMyMessage) {
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
            CircleAvatar(
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
                  child: _buildBubbleContent(event),
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

  /// Bubble inner content: status text + optional slots + optional message
  Widget _buildBubbleContent(RequestEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event type label
        Text(
          event.chatDisplayMessage,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: event.eventType.isTerminal
                ? AppColors.error
                : AppColors.textPrimaryLight,
          ),
        ),

        // Time slots (compact cards)
        if (event.suggestedSlots.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          ...event.suggestedSlots.take(3).map((slot) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    slot.displayLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              )),
        ],

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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
