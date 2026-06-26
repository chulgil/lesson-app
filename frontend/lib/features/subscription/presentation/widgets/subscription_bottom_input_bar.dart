import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/presentation/extensions/unified_lesson_request_visuals.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

typedef AcceptScheduleChoice =
    void Function(RequestEvent event, int slotIndex, String message);
typedef ScheduleEventAction = void Function(RequestEvent event);

/// Bottom input bar for the subscription detail screen.
///
/// Four exclusive states based on schedule change / cancellation events:
/// - **default**: schedule change button only (no free-form messaging)
/// - **isWaiting**: waiting notice + decision change button
/// - **canRespond**: slot selection + message + confirmation/counter buttons
/// - **cancellationConfirmed**: 취소 확정 후 선생님 [무료 처리] [확인]
///
/// Free-form messaging is intentionally excluded — this screen is dedicated
/// to schedule change negotiation only.
///
/// Hidden when the subscription is expired or depleted.
class SubscriptionBottomInputBar extends StatelessWidget {
  final Subscription subscription;
  final String viewerRole;
  final TextEditingController? messageController;
  final VoidCallback? onScheduleChange;
  final List<RequestEvent> events;
  final String? opponentName;
  final int selectedSession;
  final AcceptScheduleChoice? onAcceptScheduleChoice;
  final ScheduleEventAction? onCompareSchedule;
  final ScheduleEventAction? onWithdrawScheduleDecision;
  final void Function(RequestEvent event)? onCancellationFreeProcess;
  final void Function(RequestEvent event)? onCancellationAcknowledge;
  final VoidCallback? onCancelLesson;

  const SubscriptionBottomInputBar({
    super.key,
    required this.subscription,
    required this.viewerRole,
    this.messageController,
    this.onScheduleChange,
    this.events = const [],
    this.opponentName,
    this.selectedSession = 1,
    this.onAcceptScheduleChoice,
    this.onCompareSchedule,
    this.onWithdrawScheduleDecision,
    this.onCancellationFreeProcess,
    this.onCancellationAcknowledge,
    this.onCancelLesson,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpired || subscription.isDepleted) {
      return const SizedBox.shrink();
    }

    final scheduleEvent = _latestScheduleDecisionEvent();
    final cancellationEvent = _latestCancellationEvent();
    final isWaiting = scheduleEvent != null && _isMyEvent(scheduleEvent);
    final canRespond =
        scheduleEvent != null &&
        !_isMyEvent(scheduleEvent) &&
        scheduleEvent.suggestedSlots.isNotEmpty;

    // Cancellation confirmed: show teacher actions (free process / acknowledge)
    final isCancellationConfirmed =
        cancellationEvent != null &&
        cancellationEvent.eventType ==
            RequestEventType.lessonCancellationConfirmed;

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
          if (isCancellationConfirmed) ...[
            _CancellationConfirmedBar(
              event: cancellationEvent,
              subscription: subscription,
              viewerRole: viewerRole,
              selectedSession: selectedSession,
              onFreeProcess: onCancellationFreeProcess,
              onAcknowledge: onCancellationAcknowledge,
            ),
          ] else if (isWaiting) ...[
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
            if (viewerRole == 'student') ...[
              // Student: schedule change + cancel lesson buttons side-by-side
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppSpacing.buttonHeightSmall,
                      child: OutlinedButton(
                        onPressed: onCancelLesson,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.inkQuaternary,
                          ),
                          shape: RoundedRectangleBorder(),
                        ),
                        child: Text(
                          AppStrings.actionLessonCancel,
                          style: AppTypography.buttonSmall.copyWith(
                            color: AppColors.inkSecondary,
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
                  ),
                ],
              ),
            ] else ...[
              // Teacher: schedule change button only
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
        ],
      ),
    );
  }

  /// Returns the latest unresolved schedule decision event.
  ///
  /// The list is scanned newest-first: a terminal event resets the bar to
  /// Default, while the first source event found drives the bar state.
  /// Note: [RequestEventType.scheduleChangeAccepted] stays a SOURCE — the
  /// acceptor keeps seeing Waiting + "결정 변경" (withdraw) until the thread
  /// moves on (spec §3.3 결정 변경 흐름).
  RequestEvent? _latestScheduleDecisionEvent() {
    // Terminal events: once one appears after a proposal/counter, the thread
    // is resolved and the bar reverts to Default. Shares the SSOT terminal set
    // with the pending-badge provider so reject/expire agree across both (#543).
    const terminalTypes = scheduleChangeNegotiationTerminalTypes;
    const sourceTypes = {
      RequestEventType.scheduleChanged,
      RequestEventType.scheduleChangeProposed,
      RequestEventType.scheduleChangeCountered,
      RequestEventType.scheduleChangeAccepted,
    };

    final sorted =
        events.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final event in sorted) {
      if (terminalTypes.contains(event.eventType)) return null;
      if (sourceTypes.contains(event.eventType)) return event;
    }
    return null;
  }

  /// Latest cancellation-related event for the current session.
  RequestEvent? _latestCancellationEvent() {
    final candidates =
        events
            .where(
              (event) =>
                  event.eventType ==
                      RequestEventType.lessonCancellationConfirmed ||
                  event.eventType ==
                      RequestEventType.cancellationCreditRefunded,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (candidates.isEmpty) return null;
    // If credit was already refunded, no action needed
    if (candidates.first.eventType ==
        RequestEventType.cancellationCreditRefunded) {
      return null;
    }
    return candidates.first;
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
          AppStrings.waitingForResponse(opponentName ?? AppStrings.opponent),
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
              AppStrings.withdrawApproval,
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
    final choices =
        slots
            .asMap()
            .entries
            .map(
              (entry) => ScheduleSlotChoice(
                priority: entry.key + 1,
                label: entry.value.displayLabel,
              ),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ScheduleSlotChoiceList(
          choices: choices,
          selectedIndex: _selectedSlotIndex,
          onSelected: (index) => setState(() => _selectedSlotIndex = index),
        ),
        const SizedBox(height: AppSpacing.space2),
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
                    AppStrings.scheduleChangeCounter,
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
                    AppStrings.scheduleChangeAccept,
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

/// Fourth state: cancellation confirmed — teacher can free-process or acknowledge.
class _CancellationConfirmedBar extends StatelessWidget {
  const _CancellationConfirmedBar({
    required this.event,
    required this.subscription,
    required this.viewerRole,
    required this.selectedSession,
    this.onFreeProcess,
    this.onAcknowledge,
  });

  final RequestEvent event;
  final Subscription subscription;
  final String viewerRole;
  final int selectedSession;
  final void Function(RequestEvent event)? onFreeProcess;
  final void Function(RequestEvent event)? onAcknowledge;

  bool get _isTeacher => viewerRole == 'teacher';
  bool get _creditWasUsed => (event.changeCreditUsed ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.cancellationConfirmedTitle(selectedSession),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          _creditWasUsed
              ? AppStrings.cancellationCreditUsed(
                event.changeCreditUsed ?? 1,
                event.changeCreditRemainingAfter ??
                    subscription.remainingReschedule,
              )
              : AppStrings.cancellationNoCreditUsed,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (_isTeacher && _creditWasUsed) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: OutlinedButton(
                    onPressed:
                        onFreeProcess == null
                            ? null
                            : () => onFreeProcess!(event),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inkQuaternary),
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      AppStrings.cancellationFreeProcess,
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
                        onAcknowledge == null
                            ? null
                            : () => onAcknowledge!(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      AppStrings.cancellationAcknowledge,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (_isTeacher) ...[
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightSmall,
            child: ElevatedButton(
              onPressed:
                  onAcknowledge == null ? null : () => onAcknowledge!(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                shape: RoundedRectangleBorder(),
              ),
              child: Text(
                AppStrings.cancellationAcknowledge,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
