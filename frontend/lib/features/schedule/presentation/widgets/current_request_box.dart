import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart' show AppStrings;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_radio.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../../subscription/presentation/extensions/subscription_template_visuals.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../extensions/unified_lesson_request_visuals.dart';
import 'schedule_change_action_bar.dart';
import 'schedule_slot_choice_list.dart';

/// Current request action box — phase-aware actions.
///
/// Renders different UI based on [RequestPhase]:
/// - **Phase 1 (request)**: Slot selection + Counter-propose/Accept (existing)
/// - **Phase 2 (subscription)**: Payment guide / Payment confirm
/// - **Phase 3 (lessons)**: Lesson complete / Cancel / Schedule change / Note
/// - **Phase 4 (completed)**: Propose renewal / Request renewal
/// - **Terminal**: Final status message only
class CurrentRequestBox extends StatefulWidget {
  final UnifiedLessonRequest request;
  final List<RequestEvent> events;
  final String viewerRole; // 'teacher' or 'student'
  final String opponentName;

  // Phase 1 callbacks
  final void Function(int slotIndex, String message)? onAccept;
  final VoidCallback? onCounterPropose;
  final VoidCallback? onCancel;
  final VoidCallback? onWithdraw;
  final int? initialSelectedSlot;

  // Phase 2 callbacks
  final VoidCallback? onSendPaymentGuide; // 선불: 입금 안내 BottomSheet
  final VoidCallback? onIssuePostpaid; // 후불: 수강권 먼저 발급
  final VoidCallback? onIssueFree; // 무료: 체험 수강권 발급
  final VoidCallback? onConfirmPayment; // 학생: 입금 완료
  final VoidCallback? onVerifyPayment; // 선생님: 입금 확인
  final void Function(String? selectedTemplateId)? onAcceptProposal; // 학생: 수락
  final void Function(String? reason)? onRejectProposal; // 학생: 거절

  // Phase 2 data: proposal templates for student selection
  final List<SubscriptionTemplate> proposalTemplates;

  // Phase 3 callbacks
  final VoidCallback? onLessonComplete;
  final VoidCallback? onLessonCancel;
  final VoidCallback? onScheduleChange;
  final VoidCallback? onAddNote;
  final VoidCallback? onScheduleChangeResponse;

  // Phase 3/4 callbacks
  final VoidCallback? onViewSubscription; // 수강권 상세 보기
  final VoidCallback? onProposeRenewal;
  final VoidCallback? onRequestRenewal;

  const CurrentRequestBox({
    super.key,
    required this.request,
    required this.events,
    required this.viewerRole,
    required this.opponentName,
    this.onAccept,
    this.initialSelectedSlot,
    this.onCounterPropose,
    this.onCancel,
    this.onWithdraw,
    this.onSendPaymentGuide,
    this.onIssuePostpaid,
    this.onIssueFree,
    this.onConfirmPayment,
    this.onVerifyPayment,
    this.onAcceptProposal,
    this.onRejectProposal,
    this.proposalTemplates = const [],
    this.onLessonComplete,
    this.onLessonCancel,
    this.onScheduleChange,
    this.onAddNote,
    this.onScheduleChangeResponse,
    this.onViewSubscription,
    this.onProposeRenewal,
    this.onRequestRenewal,
  });

  @override
  State<CurrentRequestBox> createState() => _CurrentRequestBoxState();
}

class _CurrentRequestBoxState extends State<CurrentRequestBox> {
  int? _selectedSlotIndex;
  String? _selectedTemplateId;

  bool get _isTeacher => widget.viewerRole == 'teacher';

  @override
  void initState() {
    super.initState();
    // Auto-select if only 1 slot
    final latestSlots = _latestSlotLabels;
    if (latestSlots.length == 1) {
      _selectedSlotIndex = 0;
    }
  }

  @override
  void didUpdateWidget(covariant CurrentRequestBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedSlot != null &&
        widget.initialSelectedSlot != oldWidget.initialSelectedSlot) {
      _selectedSlotIndex = widget.initialSelectedSlot;
    }
  }

  /// Get display labels for the latest proposed slots (Phase 1 only).
  List<String> get _latestSlotLabels {
    if (widget.request.status == UnifiedRequestStatus.pending &&
        widget.request.preferredSlots.isNotEmpty) {
      final sorted = [...widget.request.preferredSlots]
        ..sort((a, b) => a.priority.compareTo(b.priority));
      return sorted.map((ps) => ps.displayLabel).toList();
    }

    if (widget.events.isEmpty) return [];
    for (int i = widget.events.length - 1; i >= 0; i--) {
      if (widget.events[i].suggestedSlots.isNotEmpty) {
        return widget.events[i].suggestedSlots
            .map((s) => s.displayLabel)
            .toList();
      }
    }
    return [];
  }

  /// Determine whose turn it is based on the latest event (Phase 1).
  _TurnState get _turnState {
    if (widget.request.isTerminal) return _TurnState.terminal;
    if (widget.events.isEmpty) return _TurnState.theirTurn;

    final lastEvent = widget.events.last;

    // withdrawApproval: whoever withdrew gets myTurn back
    if (lastEvent.eventType == RequestEventType.withdrawApproval) {
      final withdrawerIsViewer =
          (lastEvent.actorType == ProposerRole.teacher && _isTeacher) ||
          (lastEvent.actorType == ProposerRole.student && !_isTeacher);
      return withdrawerIsViewer ? _TurnState.myTurn : _TurnState.theirTurn;
    }

    final lastActorIsViewer =
        (lastEvent.actorType == ProposerRole.teacher && _isTeacher) ||
        (lastEvent.actorType == ProposerRole.student && !_isTeacher);

    return lastActorIsViewer ? _TurnState.theirTurn : _TurnState.myTurn;
  }

  @override
  Widget build(BuildContext context) {
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
      child: _buildPhaseContent(),
    );
  }

  /// Route to the correct phase UI.
  Widget _buildPhaseContent() {
    final phase = widget.request.currentPhase;

    return switch (phase) {
      RequestPhase.request => _buildPhase1Request(),
      RequestPhase.subscription => _buildPhase2Subscription(),
      RequestPhase.lessons => _buildPhase3Lessons(),
      RequestPhase.completed => _buildPhase4Completed(),
      RequestPhase.terminal => _buildTerminal(),
    };
  }

  // ── Phase 1: Request (existing logic) ──────────────────────

  Widget _buildPhase1Request() {
    return switch (_turnState) {
      _TurnState.myTurn => _buildMyTurn(),
      _TurnState.theirTurn => _buildTheirTurn(),
      _TurnState.terminal => _buildTerminal(),
    };
  }

  /// My turn: compact chat-input style — slot chips + message input + buttons
  Widget _buildMyTurn() {
    final slotLabels = _latestSlotLabels;
    final slotChoices =
        slotLabels
            .asMap()
            .entries
            .map(
              (entry) => ScheduleSlotChoice(
                priority: entry.key + 1,
                label: entry.value,
              ),
            )
            .toList();

    return ScheduleChangeResponseBar(
      choices: slotChoices,
      initialSelectedIndex: _selectedSlotIndex,
      messageHint: AppStrings.messageHint,
      onAccept:
          (slotIndex, message) => widget.onAccept?.call(slotIndex, message),
      onCounterPropose: widget.onCounterPropose,
    );
  }

  /// Their turn: waiting message + withdraw button
  Widget _buildTheirTurn() {
    return ScheduleChangeWaitingBar(
      opponentName: widget.opponentName,
      onWithdraw: widget.onWithdraw,
    );
  }

  // ── Phase 2: Subscription & Payment ────────────────────────

  Widget _buildPhase2Subscription() {
    final request = widget.request;
    final status = request.status;

    if (status == UnifiedRequestStatus.timeConfirmed &&
        _turnState == _TurnState.theirTurn) {
      return _buildTheirTurn();
    }

    if (_isTeacher) {
      return _buildTeacherPhase2(request, status);
    }

    return _buildStudentPhase2(request, status);
  }

  Widget _buildTeacherPhase2(
    UnifiedLessonRequest request,
    UnifiedRequestStatus status,
  ) {
    // 1. 수강권 안내 전 (proposalSent 이전) → 발급 방법 선택
    if (status == UnifiedRequestStatus.timeConfirmed) {
      return _buildPhase2PaymentChoice();
    }

    // 2. 수강권 안내 발송됨 → 학생 수락 대기
    if (status == UnifiedRequestStatus.proposalSent) {
      return _buildMessageOnly(
        icon: Icons.hourglass_top,
        iconColor: AppColors.ink,
        message: AppStrings.actionBoxWaitingAccept,
      );
    }

    // 3. 학생이 수강권 수락 → 입금 완료 알림 대기
    if (status == UnifiedRequestStatus.proposalAccepted) {
      return _buildMessageOnly(
        icon: Icons.hourglass_top,
        iconColor: AppColors.ink,
        message: AppStrings.actionBoxWaitingPayment,
      );
    }

    // 4. 입금 확인 필요 (학생이 입금 완료 알림)
    if (status == UnifiedRequestStatus.paymentNotified) {
      return _buildActionRow(
        icon: Icons.account_balance,
        iconColor: AppColors.paperOk,
        message: AppStrings.phase2PaymentReceivedTeacher,
        primaryLabel: AppStrings.actionVerifyPayment,
        primaryIcon: Icons.check_circle,
        onPrimary: widget.onVerifyPayment,
      );
    }

    // 5. 수강권 발행 완료 → 레슨 시작 대기
    if (status == UnifiedRequestStatus.subscriptionIssued) {
      return _buildMessageOnly(
        icon: Icons.card_membership,
        iconColor: AppColors.paperOk,
        message: AppStrings.actionBoxSubscriptionReady,
      );
    }

    // fallback — 발급 방법 선택
    return _buildPhase2PaymentChoice();
  }

  /// Single button → opens unified proposal BottomSheet
  Widget _buildPhase2PaymentChoice() {
    return _buildActionRow(
      icon: Icons.card_membership,
      iconColor: AppColors.paperAccent,
      message: AppStrings.phase2SelectMethod,
      primaryLabel: AppStrings.proposalTitle,
      primaryIcon: Icons.arrow_forward,
      onPrimary: widget.onSendPaymentGuide,
    );
  }

  Widget _buildStudentPhase2(
    UnifiedLessonRequest request,
    UnifiedRequestStatus status,
  ) {
    // 1. 제안 수신 (proposalSent) — 템플릿 선택 + 수락/거절
    if (status == UnifiedRequestStatus.proposalSent) {
      return _buildStudentProposalResponse();
    }

    // 2. 수락 후 (proposalAccepted) — 입금 완료 버튼
    if (status == UnifiedRequestStatus.proposalAccepted) {
      return _buildActionRow(
        icon: Icons.receipt_long,
        iconColor: AppColors.ink,
        message: AppStrings.phase2WaitingPaymentStudent,
        primaryLabel: AppStrings.actionConfirmPayment,
        primaryIcon: Icons.check_circle_outline,
        onPrimary: widget.onConfirmPayment,
      );
    }

    // 3. 입금 알림 후 (paymentNotified) — 대기 메시지
    if (status == UnifiedRequestStatus.paymentNotified) {
      return _buildMessageOnly(
        icon: Icons.hourglass_top,
        iconColor: AppColors.ink,
        message: AppStrings.actionBoxWaitingVerify,
      );
    }

    // 수강권 발행 완료
    return _buildMessageOnly(
      icon: Icons.card_membership,
      iconColor: AppColors.paperOk,
      message: AppStrings.chatSubscriptionIssued,
    );
  }

  /// Student proposal response: template radio selection + accept/reject
  Widget _buildStudentProposalResponse() {
    final templates = widget.proposalTemplates;
    final isMultiChoice = templates.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Guide message
        Row(
          children: [
            Icon(Icons.card_giftcard, color: AppColors.paperAccent, size: 18),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.chatProposalSent,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        // Template radio selection (multi-choice only)
        if (isMultiChoice) ...templates.map((t) => _buildTemplateRadio(t)),

        const SizedBox(height: AppSpacing.space2),

        // Accept / Reject buttons
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                label: AppStrings.eventReject,
                icon: Icons.close,
                onPressed: () => _confirmRejectProposal(context),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _buildPrimaryButton(
                label: AppStrings.eventProposalAccepted,
                icon: Icons.check,
                onPressed:
                    isMultiChoice && _selectedTemplateId == null
                        ? null
                        : () => widget.onAcceptProposal?.call(
                          isMultiChoice
                              ? _selectedTemplateId
                              : templates.firstOrNull?.id,
                        ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Reject is destructive (ends the payment proposal) — confirm before firing.
  Future<void> _confirmRejectProposal(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.proposalRejectConfirmTitle,
      message: AppStrings.proposalRejectConfirmBody,
      confirmLabel: AppStrings.eventReject,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed == true) {
      widget.onRejectProposal?.call(null);
    }
  }

  Widget _buildTemplateRadio(SubscriptionTemplate template) {
    final isSelected = _selectedTemplateId == template.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedTemplateId = template.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            NotebookRadio<String>(
              value: template.id,
              groupValue: _selectedTemplateId,
              onChanged: (v) => setState(() => _selectedTemplateId = v),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Flexible(
              child: Text(
                template.summaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase 3: Lesson Progress ───────────────────────────────

  Widget _buildPhase3Lessons() {
    // Check for a pending schedule change proposal that the viewer must respond to.
    final pendingScheduleChange = _pendingScheduleChangeEvent();
    if (pendingScheduleChange != null) {
      return _buildScheduleChangeResponseBanner();
    }
    // No pending negotiation: subscription summary + schedule change entry.
    return _buildActiveLessonsActions();
  }

  /// Subscription summary card + schedule change entry point — shown in
  /// Phase 3 when there is no pending schedule change negotiation.
  Widget _buildActiveLessonsActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubscriptionSummary(),
        if (widget.onScheduleChange != null) ...[
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            height: AppSpacing.buttonHeightSmall,
            child: OutlinedButton.icon(
              onPressed: widget.onScheduleChange,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(
                AppStrings.scheduleChangeButton,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.inkQuaternary),
                shape: RoundedRectangleBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Returns the latest unresolved scheduleChangeProposed or
  /// scheduleChangeCountered event that was sent by the *opponent* (i.e. the
  /// viewer needs to respond).
  RequestEvent? _pendingScheduleChangeEvent() {
    if (widget.events.isEmpty) return null;

    // Walk from most recent to oldest.
    for (int i = widget.events.length - 1; i >= 0; i--) {
      final event = widget.events[i];
      final type = event.eventType;

      // A resolution event means there is no longer a pending proposal.
      if (type == RequestEventType.scheduleChangeAccepted ||
          type == RequestEventType.scheduleChanged) {
        return null;
      }

      // Pending proposal/counter from the opponent.
      if (type == RequestEventType.scheduleChangeProposed ||
          type == RequestEventType.scheduleChangeCountered) {
        final sentByTeacher = event.actorType == ProposerRole.teacher;
        final viewerIsTeacher = _isTeacher;
        // If opponent sent it, the viewer must respond.
        if (sentByTeacher != viewerIsTeacher) {
          return event;
        }
        // Viewer sent it — they are waiting, no banner needed.
        return null;
      }
    }
    return null;
  }

  /// Banner shown when the viewer must respond to a schedule change proposal.
  Widget _buildScheduleChangeResponseBanner() {
    return Row(
      children: [
        Icon(Icons.swap_horiz_rounded, color: AppColors.paperAccent, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            AppStrings.scheduleChangeResponseNeeded,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        TextButton(
          onPressed:
              widget.onScheduleChangeResponse ?? widget.onViewSubscription,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.scheduleChangeResponseAction,
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase 4: Completed ─────────────────────────────────────

  Widget _buildPhase4Completed() {
    return _buildSubscriptionSummary();
  }

  /// Subscription summary card — shown in Phase 3 and Phase 4.
  /// Minimal info: subscription name + progress + link to detail.
  Widget _buildSubscriptionSummary() {
    return Row(
      children: [
        Icon(Icons.card_membership, size: 18, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            AppStrings.subscriptionSummaryMessage,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        TextButton(
          onPressed: widget.onViewSubscription,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.subscriptionDetailLink,
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Terminal ───────────────────────────────────────────────

  Widget _buildTerminal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.inkTertiary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          AppStrings.requestClosed,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.inkTertiary,
          ),
        ),
      ],
    );
  }

  // ── Shared Builders ────────────────────────────────────────

  /// Standard layout: status icon + message + primary action button.
  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String message,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback? onPrimary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeightSmall,
          child: ElevatedButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon, size: 18),
            label: Text(
              primaryLabel,
              style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              shape: RoundedRectangleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  /// Message-only row (no button).
  Widget _buildMessageOnly({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Primary filled button with icon.
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: AppSpacing.buttonHeightSmall,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paperAccent,
          shape: RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        ),
      ),
    );
  }

  /// Outlined button with icon.
  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: AppSpacing.buttonHeightSmall,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: AppTypography.buttonSmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.inkQuaternary),
          shape: RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        ),
      ),
    );
  }
}

enum _TurnState { myTurn, theirTurn, terminal }
