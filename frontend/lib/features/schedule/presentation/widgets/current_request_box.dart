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
    final latestSlots = _latestSlotLabels;
    if (latestSlots.length == 1) {
      _selectedSlotIndex = 0;
    }
  }

  /// Get display labels for the latest proposed slots.
  /// Uses PreferredTimeSlot.displayLabel directly (preserves date info).
  List<String> get _latestSlotLabels {
    // Pending state: use PreferredTimeSlot.displayLabel (includes date)
    if (widget.request.status == UnifiedRequestStatus.pending &&
        widget.request.preferredSlots.isNotEmpty) {
      final sorted = [...widget.request.preferredSlots]
        ..sort((a, b) => a.priority.compareTo(b.priority));
      return sorted.map((ps) => ps.displayLabel).toList();
    }

    // Negotiating: find latest event with suggestedSlots
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

    // withdrawApproval: whoever withdrew gets myTurn back to re-decide
    if (lastEvent.eventType == RequestEventType.withdrawApproval) {
      final withdrawerIsViewer =
          (lastEvent.actorType == ProposerRole.teacher &&
                  widget.viewerRole == 'teacher') ||
              (lastEvent.actorType == ProposerRole.student &&
                  widget.viewerRole == 'student');
      return withdrawerIsViewer ? _TurnState.myTurn : _TurnState.theirTurn;
    }

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
      child: switch (_turnState) {
        _TurnState.myTurn => _buildMyTurn(),
        _TurnState.theirTurn => _buildTheirTurn(),
        _TurnState.terminal => _buildTerminal(),
      },
    );
  }

  /// My turn: compact chat-input style — slot chips + message input + buttons
  Widget _buildMyTurn() {
    final slotLabels = _latestSlotLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact slot selection (horizontal chips)
        if (slotLabels.isNotEmpty) _buildCompactSlots(slotLabels),
        const SizedBox(height: AppSpacing.space2),

        // Action buttons
        Row(
          children: [
            // Schedule comparison button
            IconButton(
              onPressed: widget.onCounterPropose,
              icon: const Icon(Icons.calendar_month, size: 22),
              color: AppColors.textSecondaryLight,
              tooltip: AppStrings.counterPropose,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.space1),
            // Accept button
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _selectedSlotIndex != null
                      ? () {
                          widget.onAccept?.call(_selectedSlotIndex!);
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

  /// Their turn: compact waiting + withdraw button
  Widget _buildTheirTurn() {
    return Row(
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
        SizedBox(
          height: 32,
          child: OutlinedButton.icon(
            onPressed: widget.onWithdraw,
            icon: const Icon(Icons.undo, size: 14),
            label: Text(
              AppStrings.withdrawApproval,
              style: AppTypography.caption.copyWith(
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

  /// Terminal: compact final status
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Text(
          status.label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Slot selection cards — uses pre-computed display labels
  Widget _buildSlotsSection(List<String> slotLabels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: slotLabels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
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
                      label,
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
