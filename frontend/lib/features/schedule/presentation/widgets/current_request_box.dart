import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart' show AppStrings;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// Current request action box — shows the latest state and available actions.
///
/// 3 modes:
/// - **My turn**: Show opponent's proposal + slot selection + [Counter-propose] [Accept]
/// - **Their turn**: "Waiting for response" + [Modify] [Cancel]
/// - **Terminal**: Final status message only
class CurrentRequestBox extends StatefulWidget {
  final UnifiedLessonRequest request;
  final List<RequestEvent> events;
  final String viewerRole; // 'teacher' or 'student'
  final String opponentName;
  final ValueChanged<int>? onAccept;
  final VoidCallback? onCounterPropose;
  final VoidCallback? onModify;
  final VoidCallback? onCancel;
  final VoidCallback? onWithdraw;

  const CurrentRequestBox({
    super.key,
    required this.request,
    required this.events,
    required this.viewerRole,
    required this.opponentName,
    this.onAccept,
    this.onCounterPropose,
    this.onModify,
    this.onCancel,
    this.onWithdraw,
  });

  @override
  State<CurrentRequestBox> createState() => _CurrentRequestBoxState();
}

class _CurrentRequestBoxState extends State<CurrentRequestBox> {
  int? _selectedSlotIndex;

  @override
  void initState() {
    super.initState();
    // Auto-select if only 1 slot
    final latestSlots = _latestProposedSlots;
    if (latestSlots.length == 1) {
      _selectedSlotIndex = 0;
    }
  }

  /// Get the latest proposed slots.
  /// For pending: use preferredSlots from request.
  /// For negotiating: use last event's suggestedSlots.
  List<TimeSlotOption> get _latestProposedSlots {
    // Pending state: show student's preferred slots as selectable options
    if (widget.request.status == UnifiedRequestStatus.pending &&
        widget.request.preferredSlots.isNotEmpty) {
      return widget.request.preferredSlots
          .map((ps) => TimeSlotOption(
                id: 'pref_${ps.priority}',
                dayOfWeek: ps.dayOfWeek ?? 0,
                startTime: ps.startTime,
                endTime: ps.endTime,
              ))
          .toList();
    }

    // Negotiating: find latest event with slots
    if (widget.events.isEmpty) return [];
    for (int i = widget.events.length - 1; i >= 0; i--) {
      if (widget.events[i].suggestedSlots.isNotEmpty) {
        return widget.events[i].suggestedSlots;
      }
    }
    return [];
  }

  /// Get the latest message from the opponent (request message or event message).
  String? get _latestMessage {
    // For pending: use request.message (student's initial message)
    if (widget.request.status == UnifiedRequestStatus.pending) {
      return widget.request.message;
    }
    // For negotiating: find last opponent event with message
    for (int i = widget.events.length - 1; i >= 0; i--) {
      final event = widget.events[i];
      final isOpponent = (event.actorType == ProposerRole.teacher &&
              widget.viewerRole == 'student') ||
          (event.actorType == ProposerRole.student &&
              widget.viewerRole == 'teacher');
      if (isOpponent && event.message != null && event.message!.isNotEmpty) {
        return event.message;
      }
    }
    return null;
  }

  /// Determine whose turn it is based on the latest event.
  _TurnState get _turnState {
    if (widget.request.isTerminal) return _TurnState.terminal;
    if (widget.events.isEmpty) return _TurnState.theirTurn;

    final lastEvent = widget.events.last;
    final lastActorIsViewer =
        (lastEvent.actorType == ProposerRole.teacher &&
                widget.viewerRole == 'teacher') ||
            (lastEvent.actorType == ProposerRole.student &&
                widget.viewerRole == 'student');

    // If I made the last move, it's their turn
    return lastActorIsViewer ? _TurnState.theirTurn : _TurnState.myTurn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: switch (_turnState) {
        _TurnState.myTurn => _buildMyTurn(),
        _TurnState.theirTurn => _buildTheirTurn(),
        _TurnState.terminal => _buildTerminal(),
      },
    );
  }

  /// My turn: show opponent's proposal + slot selection + action buttons
  Widget _buildMyTurn() {
    final slots = _latestProposedSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.notifications_active,
                color: AppColors.primary, size: AppSpacing.iconSM),
            const SizedBox(width: AppSpacing.space2),
            Text(
              AppStrings.lessonRequest,
              style: AppTypography.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Status message
        Text(
          AppStrings.opponentProposed(widget.opponentName),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Student message (from request or latest event)
        if (_latestMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: AppSpacing.iconXS,
                    color: AppColors.textSecondaryLight),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    _latestMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Slot selection (reuse approval_bottom_sheet pattern)
        if (slots.isNotEmpty) _buildSlotsSection(slots),
        const SizedBox(height: AppSpacing.space4),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCounterPropose,
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(AppSpacing.buttonHeightSmall),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: Text(
                  AppStrings.counterPropose,
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedSlotIndex != null
                    ? () {
                        widget.onAccept?.call(_selectedSlotIndex!);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(AppSpacing.buttonHeightSmall),
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.scheduleMutedAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: Text(
                  AppStrings.accept,
                  style: AppTypography.buttonSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Their turn: waiting message + contextual actions
  Widget _buildTheirTurn() {
    final isPending = widget.request.status == UnifiedRequestStatus.pending;
    final isApproved = widget.request.status == UnifiedRequestStatus.approved;
    final isTeacher = widget.viewerRole == 'teacher';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_top,
                color: AppColors.info, size: AppSpacing.iconSM),
            const SizedBox(width: AppSpacing.space2),
            Text(
              AppStrings.lessonRequest,
              style: AppTypography.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          AppStrings.waitingForResponse(widget.opponentName),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            // Teacher approved → show "결정 변경" instead of cancel
            if (isApproved && isTeacher) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onWithdraw,
                  icon: const Icon(Icons.undo, size: 16),
                  label: Text(
                    '결정 변경',
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.buttonHeightSmall),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (isPending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onModify,
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(AppSpacing.buttonHeightSmall),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                    ),
                    child: Text(
                      AppStrings.modify,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.buttonHeightSmall),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel,
                    style: AppTypography.buttonSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Terminal: show final status
  Widget _buildTerminal() {
    final status = widget.request.status;
    final (icon, color) = switch (status) {
      UnifiedRequestStatus.completed => (Icons.check_circle, AppColors.success),
      UnifiedRequestStatus.cancelled => (Icons.cancel, AppColors.error),
      UnifiedRequestStatus.rejected => (Icons.block, AppColors.error),
      UnifiedRequestStatus.expired => (Icons.timer_off, AppColors.warning),
      _ => (Icons.info, AppColors.info),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMD),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Text(
            status.label,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Slot selection cards (pattern from unified_approval_bottom_sheet)
  Widget _buildSlotsSection(List<TimeSlotOption> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: slots.asMap().entries.map((entry) {
        final index = entry.key;
        final slot = entry.value;
        final isSelected = _selectedSlotIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedSlotIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.scheduleMutedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      slot.displayLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum _TurnState { myTurn, theirTurn, terminal }
