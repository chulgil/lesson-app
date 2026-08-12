import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'schedule_slot_choice_list.dart';

/// Shared negotiation UI extracted from `CurrentRequestBox` (계열 A) and
/// `SubscriptionBottomInputBar` (계열 B) — M-3 (schedule_change_unification_spec
/// §4). Both hosts inject their own `RequestEvent` handling via callbacks;
/// this file owns only the visual/interaction contract for "waiting on the
/// other party" and "respond to a proposal" — the two states that were
/// duplicated pixel-for-pixel (with minor drift) across both screens.
///
/// Host-specific states (Phase 2 payment, Phase 4 completed, terminal,
/// subscription Default/CancellationConfirmed) stay in their own widgets —
/// see schedule_change_unification_spec.md §4 M-3 row for the scope note.

/// Waiting state: the opponent must respond next. Message + full-width
/// "결정 변경" (withdraw) button. Canonical style per
/// `detail_screen_template.md`'s CurrentRequestBox reference (#26).
class ScheduleChangeWaitingBar extends StatelessWidget {
  const ScheduleChangeWaitingBar({
    super.key,
    required this.opponentName,
    required this.onWithdraw,
    this.withdrawLabel = AppStrings.withdrawApproval,
  });

  final String opponentName;
  final VoidCallback? onWithdraw;
  final String withdrawLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.hourglass_top, color: AppColors.ink, size: 18),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.waitingForResponse(opponentName),
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
          child: OutlinedButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.undo, size: 16),
            label: Text(
              withdrawLabel,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inkQuaternary),
              shape: RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Respond state: slot choice list + message input + response buttons.
///
/// [onReject] is the discriminator for the two button layouts that already
/// existed independently in each host:
/// - null (계열 A Phase 1 "my turn"): 2-button row — counter-propose + accept.
/// - non-null (계열 B canRespond): reject + counter-propose row, then a
///   full-width accept button below (N8, 0702 감사 — 3종 응답 대칭).
///
/// Both layouts are reproduced as they were (colors, padding) rather than
/// forced into one shape — the button-count difference is a real, existing
/// UX difference (Phase 1 negotiation has no reject; per-session schedule
/// change does), not accidental drift.
class ScheduleChangeResponseBar extends StatefulWidget {
  const ScheduleChangeResponseBar({
    super.key,
    required this.choices,
    this.initialSelectedIndex,
    this.messageController,
    required this.messageHint,
    this.messageMinLines = 1,
    this.messageMaxLines = 8,
    this.messageMaxLength = 200,
    required this.onAccept,
    this.onReject,
    this.onCounterPropose,
    this.acceptLabel = AppStrings.scheduleChangeAccept,
    this.counterLabel = AppStrings.scheduleChangeCounter,
    this.rejectLabel = AppStrings.scheduleChangeReject,
  });

  final List<ScheduleSlotChoice> choices;
  final int? initialSelectedIndex;
  final TextEditingController? messageController;
  final String messageHint;
  final int messageMinLines;
  final int messageMaxLines;
  final int messageMaxLength;
  final void Function(int slotIndex, String message) onAccept;
  final void Function(String message)? onReject;
  final VoidCallback? onCounterPropose;
  final String acceptLabel;
  final String counterLabel;
  final String rejectLabel;

  @override
  State<ScheduleChangeResponseBar> createState() =>
      _ScheduleChangeResponseBarState();
}

class _ScheduleChangeResponseBarState extends State<ScheduleChangeResponseBar> {
  int? _selectedIndex;
  TextEditingController? _ownController;

  TextEditingController get _messageController =>
      widget.messageController ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  void didUpdateWidget(covariant ScheduleChangeResponseBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedIndex != oldWidget.initialSelectedIndex &&
        widget.initialSelectedIndex != null) {
      _selectedIndex = widget.initialSelectedIndex;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  void _handleAccept() {
    if (_selectedIndex == null) return;
    widget.onAccept(_selectedIndex!, _messageController.text.trim());
    if (widget.messageController == null) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReject = widget.onReject != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.choices.isNotEmpty)
          ScheduleSlotChoiceList(
            choices: widget.choices,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _messageController,
          minLines: widget.messageMinLines,
          maxLines: widget.messageMaxLines,
          maxLength: widget.messageMaxLength,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            hintText: widget.messageHint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        if (hasReject) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: OutlinedButton(
                    onPressed:
                        () => widget.onReject!(_messageController.text.trim()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.paperAccent),
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      widget.rejectLabel,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: OutlinedButton(
                    onPressed: widget.onCounterPropose,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inkQuaternary),
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      widget.counterLabel,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightSmall,
            child: ElevatedButton(
              onPressed: _selectedIndex == null ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                shape: RoundedRectangleBorder(),
              ),
              child: Text(
                widget.acceptLabel,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: OutlinedButton(
                    onPressed: widget.onCounterPropose,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inkQuaternary),
                      shape: RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                    child: Text(
                      widget.counterLabel,
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
                    onPressed: _selectedIndex == null ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      disabledBackgroundColor: AppColors.scheduleMutedAccent,
                      shape: RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                    child: Text(
                      widget.acceptLabel,
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
      ],
    );
  }
}
