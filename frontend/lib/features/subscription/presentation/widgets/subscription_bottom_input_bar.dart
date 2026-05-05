import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../domain/entities/subscription.dart';

typedef AcceptScheduleChoice =
    void Function(RequestEvent event, int slotIndex, String message);
typedef ScheduleEventAction = void Function(RequestEvent event);

/// Bottom input bar for the subscription detail screen.
///
/// Three exclusive states based on schedule change events:
/// - **default**: "일정 변경 요청하기" button only (no free-form messaging)
/// - **isWaiting**: "OOO님의 응답을 기다리고 있습니다" + "결정 변경" button
/// - **canRespond**: Slot selection + message + "수락"/"일정 비교" buttons
///
/// Free-form messaging is intentionally excluded — this screen is dedicated
/// to schedule change negotiation only. General communication uses the
/// teacher announcement feature.
///
/// Hidden when the subscription is expired or depleted.
class SubscriptionBottomInputBar extends StatelessWidget {
  final Subscription subscription;
  final String viewerRole;
  final TextEditingController? messageController;
  final VoidCallback? onScheduleChange;
  final List<RequestEvent> events;
  final String? opponentName;
  final AcceptScheduleChoice? onAcceptScheduleChoice;
  final ScheduleEventAction? onCompareSchedule;
  final ScheduleEventAction? onWithdrawScheduleDecision;

  const SubscriptionBottomInputBar({
    super.key,
    required this.subscription,
    required this.viewerRole,
    this.messageController,
    this.onScheduleChange,
    this.events = const [],
    this.opponentName,
    this.onAcceptScheduleChoice,
    this.onCompareSchedule,
    this.onWithdrawScheduleDecision,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpired || subscription.isDepleted) {
      return const SizedBox.shrink();
    }

    final scheduleEvent = _latestScheduleDecisionEvent();
    final isWaiting = scheduleEvent != null && _isMyEvent(scheduleEvent);
    final canRespond =
        scheduleEvent != null &&
        !_isMyEvent(scheduleEvent) &&
        scheduleEvent.suggestedSlots.isNotEmpty;

    // Matches CurrentRequestBox.build() container exactly
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space3,
        AppSpacing.space3,
        MediaQuery.of(context).padding.bottom + AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWaiting) ...[
            _WaitingDecisionBar(
              event: scheduleEvent,
              opponentName: opponentName,
              onWithdraw: onWithdrawScheduleDecision,
            ),
          ] else if (canRespond) ...[
            _ScheduleChoiceBar(
              event: scheduleEvent,
              messageController: messageController,
              onAccept: onAcceptScheduleChoice,
              onCompare: onCompareSchedule,
            ),
          ] else ...[
            // Default: schedule change button only (no free-form messaging)
            Text(
              AppStrings.scheduleChangeGuideDefault,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightSmall,
              child: ElevatedButton(
                onPressed: onScheduleChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  shape: RoundedRectangleBorder(),
                ),
                child: Text(
                  AppStrings.scheduleChangeButton,
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  RequestEvent? _latestScheduleDecisionEvent() {
    final candidates =
        events
            .where(
              (event) =>
                  event.eventType == RequestEventType.scheduleChanged ||
                  event.eventType == RequestEventType.scheduleChangeProposed ||
                  event.eventType == RequestEventType.scheduleChangeCountered ||
                  event.eventType == RequestEventType.scheduleChangeAccepted,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  bool _isMyEvent(RequestEvent event) {
    final actorRole =
        event.actorType == ProposerRole.teacher ? 'teacher' : 'student';
    return actorRole == viewerRole;
  }
}

class _WaitingDecisionBar extends StatelessWidget {
  const _WaitingDecisionBar({
    required this.event,
    required this.opponentName,
    required this.onWithdraw,
  });

  final RequestEvent event;
  final String? opponentName;
  final ScheduleEventAction? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${opponentName ?? '상대'}님의 응답을 기다리고 있습니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        SizedBox(
          height: AppSpacing.buttonHeightSmall,
          child: OutlinedButton(
            onPressed: onWithdraw == null ? null : () => onWithdraw!(event),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inkQuaternary),
              shape: RoundedRectangleBorder(),
            ),
            child: Text(
              '결정 변경',
              style: AppTypography.buttonSmall.copyWith(color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleChoiceBar extends StatefulWidget {
  const _ScheduleChoiceBar({
    required this.event,
    this.messageController,
    required this.onAccept,
    required this.onCompare,
  });

  final RequestEvent event;
  final TextEditingController? messageController;
  final AcceptScheduleChoice? onAccept;
  final ScheduleEventAction? onCompare;

  @override
  State<_ScheduleChoiceBar> createState() => _ScheduleChoiceBarState();
}

class _ScheduleChoiceBarState extends State<_ScheduleChoiceBar> {
  int? _selectedSlotIndex;
  late final TextEditingController _ownController;

  TextEditingController get _messageController =>
      widget.messageController ?? _ownController;

  @override
  void initState() {
    super.initState();
    _ownController = TextEditingController();
  }

  @override
  void dispose() {
    _ownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.event.suggestedSlots.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '일정을 탭하여 선택하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        for (int i = 0; i < slots.length; i++) ...[
          InkWell(
            onTap: () => setState(() => _selectedSlotIndex = i),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color:
                    _selectedSlotIndex == i
                        ? AppColors.paperAccentSoft
                        : AppColors.paper,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: Text(
                '${i + 1}. ${slots[i].displayLabel}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
        ],
        const SizedBox(height: AppSpacing.space1),
        TextField(
          controller: _messageController,
          minLines: 1,
          maxLines: 3,
          maxLength: 200,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            hintText: AppStrings.subscriptionMessageHint,
            counterText: '',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeightSmall,
                child: OutlinedButton(
                  onPressed:
                      widget.onCompare == null
                          ? null
                          : () => widget.onCompare!(widget.event),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.inkQuaternary),
                    shape: RoundedRectangleBorder(),
                  ),
                  child: Text(
                    '일정 비교',
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeightSmall,
                child: ElevatedButton(
                  onPressed:
                      _selectedSlotIndex == null || widget.onAccept == null
                          ? null
                          : () => widget.onAccept!(
                            widget.event,
                            _selectedSlotIndex!,
                            _messageController.text,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    shape: RoundedRectangleBorder(),
                  ),
                  child: Text(
                    '수락',
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
