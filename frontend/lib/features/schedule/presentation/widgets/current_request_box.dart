import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart' show AppStrings;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';

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
  final VoidCallback? onModify;
  final VoidCallback? onCancel;
  final VoidCallback? onWithdraw;
  final int? initialSelectedSlot;

  // Phase 2 callbacks
  final VoidCallback? onSendPaymentGuide;  // 선불: 결제 안내 BottomSheet
  final VoidCallback? onIssuePostpaid;      // 후불: 수강권 먼저 발급
  final VoidCallback? onIssueFree;          // 무료: 체험 수강권 발급
  final VoidCallback? onConfirmPayment;     // 학생: 입금 완료
  final VoidCallback? onVerifyPayment;      // 선생님: 입금 확인
  final void Function(String? selectedTemplateId)? onAcceptProposal; // 학생: 수락
  final void Function(String? reason)? onRejectProposal;             // 학생: 거절

  // Phase 2 data: proposal templates for student selection
  final List<SubscriptionTemplate> proposalTemplates;

  // Phase 3 callbacks
  final VoidCallback? onLessonComplete;
  final VoidCallback? onLessonCancel;
  final VoidCallback? onScheduleChange;
  final VoidCallback? onAddNote;
  final VoidCallback? onScheduleChangeResponse;

  // Phase 4 (completed) callbacks
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
    this.onModify,
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
    this.onProposeRenewal,
    this.onRequestRenewal,
  });

  @override
  State<CurrentRequestBox> createState() => _CurrentRequestBoxState();
}

class _CurrentRequestBoxState extends State<CurrentRequestBox> {
  int? _selectedSlotIndex;
  String? _selectedTemplateId;
  late TextEditingController _messageController;

  bool get _isTeacher => widget.viewerRole == 'teacher';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slot selection hint (shown only when nothing selected)
        if (slotLabels.isNotEmpty && _selectedSlotIndex == null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space1),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 14,
                    color: AppColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(
                  AppStrings.slotSelectionHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        // Compact slot selection (horizontal chips)
        if (slotLabels.isNotEmpty) _buildCompactSlots(slotLabels),
        const SizedBox(height: AppSpacing.space2),

        // Message input
        TextField(
          controller: _messageController,
          maxLines: 8,
          minLines: 1,
          maxLength: 200,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            hintText: AppStrings.messageHint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Action buttons
        Row(
          children: [
            // Counter-propose button
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeightSmall,
                child: OutlinedButton(
                  onPressed: widget.onCounterPropose,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3),
                  ),
                  child: Text(
                    AppStrings.counterPropose,
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            // Accept button
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeightSmall,
                child: ElevatedButton(
                  onPressed: _selectedSlotIndex != null
                      ? () {
                          widget.onAccept?.call(
                            _selectedSlotIndex!,
                            _messageController.text.trim(),
                          );
                          _messageController.clear();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.scheduleMutedAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3),
                  ),
                  child: Text(
                    AppStrings.accept,
                    style: AppTypography.buttonSmall.copyWith(
                      color: Colors.white,
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

  /// Compact horizontal slot chips (tap to select)
  Widget _buildCompactSlots(List<String> slotLabels) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space1,
      children: slotLabels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = _selectedSlotIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedSlotIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1 + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${index + 1}. $label',
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Their turn: waiting message + withdraw button
  Widget _buildTheirTurn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waiting message row
        Row(
          children: [
            Icon(Icons.hourglass_top,
                color: AppColors.info, size: 18),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.waitingForResponse(widget.opponentName),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Withdraw button (full width)
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed: widget.onWithdraw,
            icon: const Icon(Icons.undo, size: 16),
            label: Text(
              AppStrings.withdrawApproval,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase 2: Subscription & Payment ────────────────────────

  Widget _buildPhase2Subscription() {
    final request = widget.request;
    final status = request.status;

    if (_isTeacher) {
      return _buildTeacherPhase2(request, status);
    }

    return _buildStudentPhase2(request, status);
  }

  Widget _buildTeacherPhase2(
    UnifiedLessonRequest request,
    UnifiedRequestStatus status,
  ) {
    // 입금 확인 대기 (학생이 입금 완료 알림)
    if (status == UnifiedRequestStatus.paymentNotified) {
      return _buildActionRow(
        icon: Icons.account_balance,
        iconColor: AppColors.success,
        message: AppStrings.phase2PaymentReceivedTeacher,
        primaryLabel: AppStrings.actionVerifyPayment,
        primaryIcon: Icons.check_circle,
        onPrimary: widget.onVerifyPayment,
      );
    }

    // 수강권 발행 후 (Phase 2 완료 상태) — 레슨 시작 대기
    // 실제 레슨이 진행되기 전이므로 "레슨 완료" 버튼을 표시하지 않음
    if (status == UnifiedRequestStatus.subscriptionIssued) {
      return Row(
        children: [
          Icon(Icons.card_membership, color: AppColors.success, size: 18),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '${AppStrings.chatSubscriptionIssued}\n레슨을 시작할 준비가 완료되었습니다.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      );
    }

    // 체험레슨 무료 — 단일 버튼
    final isTrial = request.type == LessonRequestType.trial;
    final isFree = isTrial && (request.suggestedPrice == null || request.suggestedPrice == 0);

    if (isFree) {
      return _buildActionRow(
        icon: Icons.card_giftcard,
        iconColor: AppColors.success,
        message: AppStrings.phase2TimeConfirmedTrial,
        primaryLabel: AppStrings.actionIssueFree,
        primaryIcon: Icons.check_circle,
        onPrimary: widget.onIssueFree,
      );
    }

    // 일반/유료 — 선불 + 후불 선택지
    return _buildPhase2PaymentChoice();
  }

  /// 선불/후불 선택 UI — 설명 카드형 (시간 확정 후)
  Widget _buildPhase2PaymentChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.phase2SelectMethod,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // 선불 카드: 결제 후 발급
        _PaymentMethodCard(
          title: AppStrings.methodPrepaidTitle,
          description: AppStrings.methodPrepaidDesc,
          onTap: widget.onSendPaymentGuide,
          isPrimary: true,
        ),
        const SizedBox(height: AppSpacing.space2),
        // 후불 카드: 먼저 발급
        _PaymentMethodCard(
          title: AppStrings.methodPostpaidTitle,
          description: AppStrings.methodPostpaidDesc,
          onTap: widget.onIssuePostpaid,
          isPrimary: false,
        ),
      ],
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
        iconColor: AppColors.info,
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
        iconColor: AppColors.info,
        message: AppStrings.phase2PaymentReceivedTeacher,
      );
    }

    // 수강권 발행 완료
    return _buildMessageOnly(
      icon: Icons.card_membership,
      iconColor: AppColors.success,
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
            Icon(Icons.card_giftcard, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.chatProposalSent,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        // Template radio selection (multi-choice only)
        if (isMultiChoice)
          ...templates.map((t) => _buildTemplateRadio(t)),

        const SizedBox(height: AppSpacing.space2),

        // Accept / Reject buttons
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                label: AppStrings.eventReject,
                icon: Icons.close,
                onPressed: () => widget.onRejectProposal?.call(null),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _buildPrimaryButton(
                label: AppStrings.eventProposalAccepted,
                icon: Icons.check,
                onPressed: isMultiChoice && _selectedTemplateId == null
                    ? null
                    : () => widget.onAcceptProposal?.call(
                          isMultiChoice ? _selectedTemplateId : templates.firstOrNull?.id,
                        ),
              ),
            ),
          ],
        ),
      ],
    );
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
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textTertiaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                template.name,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              template.summaryText,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase 3: Lesson Progress ───────────────────────────────

  /// Scan schedule change state: returns who owns the pending proposal.
  /// null = no pending, 'self' = viewer proposed, 'opponent' = opponent proposed.
  String? get _pendingScheduleChangeOwner {
    final viewerId = _isTeacher
        ? widget.request.teacherId
        : widget.request.studentId;

    for (int i = widget.events.length - 1; i >= 0; i--) {
      final event = widget.events[i];
      final type = event.eventType;

      // Found a resolution — no pending proposal
      if (type == RequestEventType.scheduleChangeAccepted ||
          type == RequestEventType.scheduleChangeRejected) {
        return null;
      }

      // Found a proposal/counter
      if (type == RequestEventType.scheduleChangeProposed ||
          type == RequestEventType.scheduleChangeCountered) {
        return event.actorId == viewerId ? 'self' : 'opponent';
      }
    }
    return null;
  }

  bool get _hasPendingScheduleChange =>
      _pendingScheduleChangeOwner == 'opponent';

  bool get _hasOwnPendingScheduleChange =>
      _pendingScheduleChangeOwner == 'self';

  Widget _buildPhase3Lessons() {
    // Show response UI if there's a pending schedule change for this viewer
    if (_hasPendingScheduleChange) {
      return _buildActionRow(
        icon: Icons.schedule,
        iconColor: AppColors.warning,
        message: AppStrings.scheduleChangeRequestArrived,
        primaryLabel: AppStrings.scheduleChangeAccept,
        primaryIcon: Icons.reply,
        onPrimary: widget.onScheduleChangeResponse,
      );
    }

    // Show "in progress" if viewer's own proposal is pending
    if (_hasOwnPendingScheduleChange) {
      return _buildActionRow(
        icon: Icons.schedule,
        iconColor: AppColors.info,
        message: AppStrings.scheduleChangeInProgress,
        primaryLabel: AppStrings.actionScheduleChange,
        primaryIcon: Icons.schedule,
        onPrimary: null, // Disabled — waiting for opponent response
      );
    }

    if (_isTeacher) {
      return _buildTeacherLessonActions();
    }

    // Student: only schedule change
    return _buildActionRow(
      icon: Icons.music_note,
      iconColor: AppColors.primary,
      message: AppStrings.chapterLessons,
      primaryLabel: AppStrings.actionRequestScheduleChange,
      primaryIcon: Icons.schedule,
      onPrimary: widget.onScheduleChange,
    );
  }

  /// Teacher gets multiple action buttons for lesson management.
  Widget _buildTeacherLessonActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary row: Lesson Complete + Lesson Cancel
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                label: AppStrings.actionLessonComplete,
                icon: Icons.check_circle,
                onPressed: widget.onLessonComplete,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _buildOutlinedButton(
                label: AppStrings.actionLessonCancel,
                icon: Icons.cancel_outlined,
                onPressed: widget.onLessonCancel,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Secondary row: Schedule Change + Add Note
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                label: AppStrings.actionScheduleChange,
                icon: Icons.schedule,
                onPressed: widget.onScheduleChange,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _buildOutlinedButton(
                label: AppStrings.actionAddNote,
                icon: Icons.note_add,
                onPressed: widget.onAddNote,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Phase 4: Completed ─────────────────────────────────────

  Widget _buildPhase4Completed() {
    if (_isTeacher) {
      return _buildActionRow(
        icon: Icons.check_circle,
        iconColor: AppColors.success,
        message: AppStrings.eventSubscriptionCompleted,
        primaryLabel: AppStrings.actionProposeRenewal,
        primaryIcon: Icons.autorenew,
        onPrimary: widget.onProposeRenewal,
      );
    }

    // Student
    return _buildActionRow(
      icon: Icons.check_circle,
      iconColor: AppColors.success,
      message: AppStrings.eventSubscriptionCompleted,
      primaryLabel: AppStrings.actionRequestRenewal,
      primaryIcon: Icons.replay,
      onPrimary: widget.onRequestRenewal,
    );
  }

  // ── Terminal ───────────────────────────────────────────────

  Widget _buildTerminal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline,
            color: AppColors.textTertiaryLight, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Text(
          AppStrings.requestClosed,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiaryLight,
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
                  color: AppColors.textSecondaryLight,
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
              style: AppTypography.buttonSmall.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Section with icon header + custom children (for multi-button layouts).
  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String message,
    required List<Widget> children,
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
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
        ...children,
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
              color: AppColors.textSecondaryLight,
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
          style: AppTypography.buttonSmall.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
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
            color: AppColors.textSecondaryLight,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        ),
      ),
    );
  }
}

enum _TurnState { myTurn, theirTurn, terminal }

/// Selectable card for payment method (prepaid / postpaid).
class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _PaymentMethodCard({
    required this.title,
    required this.description,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? AppColors.primary.withValues(alpha: 0.04)
          : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isPrimary
                      ? AppColors.primary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
