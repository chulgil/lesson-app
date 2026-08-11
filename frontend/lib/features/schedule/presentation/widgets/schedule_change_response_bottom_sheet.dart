import 'package:flutter/material.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../extensions/unified_lesson_request_visuals.dart';
import '../screens/suggest_alternative_screen.dart';
import 'schedule_slot_choice_list.dart';

/// Action chosen in the schedule change response bottom sheet.
enum ScheduleChangeResponseAction { accept, reject, counter }

/// Result from the schedule change response bottom sheet.
typedef ScheduleChangeResponseResult =
    ({
      ScheduleChangeResponseAction action,
      String message,
      List<TimeSlot> counterSlots,
      int? acceptedSlotIndex,
    });

/// Shows the schedule change response bottom sheet.
///
/// Returns [ScheduleChangeResponseResult] or null if cancelled.
Future<ScheduleChangeResponseResult?> showScheduleChangeResponseBottomSheet(
  BuildContext context, {
  required List<TimeSlotOption> proposedSlots,
  required ScheduleChangeType changeType,
  required int durationMinutes,
  String? teacherId,
}) {
  return showNotebookBottomSheet<ScheduleChangeResponseResult>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder:
        (context) => _ScheduleChangeResponseBottomSheet(
          proposedSlots: proposedSlots,
          changeType: changeType,
          durationMinutes: durationMinutes,
          teacherId: teacherId,
        ),
  );
}

class _ScheduleChangeResponseBottomSheet extends StatefulWidget {
  final List<TimeSlotOption> proposedSlots;
  final ScheduleChangeType changeType;
  final int durationMinutes;
  final String? teacherId;

  const _ScheduleChangeResponseBottomSheet({
    required this.proposedSlots,
    required this.changeType,
    required this.durationMinutes,
    this.teacherId,
  });

  @override
  State<_ScheduleChangeResponseBottomSheet> createState() =>
      _ScheduleChangeResponseBottomSheetState();
}

class _ScheduleChangeResponseBottomSheetState
    extends State<_ScheduleChangeResponseBottomSheet> {
  int? _selectedSlotIndex;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-select if only 1 slot proposed
    if (widget.proposedSlots.length == 1) {
      _selectedSlotIndex = 0;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paperDark),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
              Text(
                AppStrings.scheduleChangeRequestArrived,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Proposed slots
              if (widget.proposedSlots.isNotEmpty) ...[
                ScheduleSlotChoiceList(
                  choices:
                      widget.proposedSlots
                          .asMap()
                          .entries
                          .map(
                            (entry) => ScheduleSlotChoice(
                              priority: entry.key + 1,
                              label: entry.value.displayLabel,
                            ),
                          )
                          .toList(),
                  selectedIndex: _selectedSlotIndex,
                  onSelected:
                      (index) => setState(() {
                        // #749: single slot stays selected — toggling it off
                        // would disable Accept with no other slot (dead-end).
                        if (widget.proposedSlots.length == 1) {
                          _selectedSlotIndex = 0;
                        } else {
                          _selectedSlotIndex =
                              _selectedSlotIndex == index ? null : index;
                        }
                      }),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Optional reason / memo — captured into the reject/accept
              // event message so the bubble shows the real text, not a label
              // placeholder (#544 거절 사유 / #545 수락 메모).
              TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: AppStrings.scheduleChangeResponseMessageHint,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // CTA buttons: Accept | Reject | Counter-propose
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _selectedSlotIndex != null ? _accept : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSpacing.buttonHeightSmall,
                      ),
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
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reject,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSpacing.buttonHeightSmall,
                            ),
                            side: const BorderSide(
                              color: AppColors.inkQuaternary,
                            ),
                            shape: RoundedRectangleBorder(),
                          ),
                          child: Text(
                            AppStrings.scheduleChangeReject,
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _counterPropose,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSpacing.buttonHeightSmall,
                            ),
                            side: const BorderSide(
                              color: AppColors.paperAccent,
                            ),
                            shape: RoundedRectangleBorder(),
                          ),
                          child: Text(
                            AppStrings.scheduleChangeCounter,
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppColors.paperAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _accept() {
    Navigator.pop<ScheduleChangeResponseResult>(context, (
      action: ScheduleChangeResponseAction.accept,
      message: _messageController.text.trim(),
      counterSlots: <TimeSlot>[],
      acceptedSlotIndex: _selectedSlotIndex,
    ));
  }

  /// Reject is destructive (ends the schedule change negotiation) — confirm
  /// before closing the sheet with a reject result.
  Future<void> _reject() async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.scheduleChangeRejectConfirmTitle,
      message: AppStrings.scheduleChangeRejectConfirmBody,
      confirmLabel: AppStrings.scheduleChangeReject,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true || !mounted) return;

    Navigator.pop<ScheduleChangeResponseResult>(context, (
      action: ScheduleChangeResponseAction.reject,
      message: _messageController.text.trim(),
      counterSlots: <TimeSlot>[],
      acceptedSlotIndex: null,
    ));
  }

  Future<void> _counterPropose() async {
    final result =
        await Navigator.push<({String message, List<TimeSlot> slots})>(
          context,
          MaterialPageRoute(
            builder:
                (context) => SuggestAlternativeScreen(
                  message: AppStrings.scheduleChangeCounter,
                  durationMinutes: widget.durationMinutes,
                  teacherId: widget.teacherId,
                ),
          ),
        );

    if (result != null && mounted) {
      Navigator.pop<ScheduleChangeResponseResult>(context, (
        action: ScheduleChangeResponseAction.counter,
        message: result.message,
        counterSlots: result.slots,
        acceptedSlotIndex: null,
      ));
    }
  }
}
