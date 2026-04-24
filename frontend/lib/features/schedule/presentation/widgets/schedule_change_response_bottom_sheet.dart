import 'package:flutter/material.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/lesson_schedule_change.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../screens/suggest_alternative_screen.dart';

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
  return showModalBottomSheet<ScheduleChangeResponseResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    // Auto-select if only 1 slot proposed
    if (widget.proposedSlots.length == 1) {
      _selectedSlotIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
      ),
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
                Text(
                  AppStrings.scheduleChangeNewSchedule,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                ...widget.proposedSlots.asMap().entries.map(
                  (entry) => _buildSlotOption(entry.key, entry.value),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // CTA buttons: Accept | Reject | Counter-propose
              Row(
                children: [
                  // Reject
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSpacing.buttonHeightSmall,
                        ),
                        side: const BorderSide(color: AppColors.inkQuaternary),
                        shape: RoundedRectangleBorder(
                        ),
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
                  // Counter-propose
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _counterPropose,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSpacing.buttonHeightSmall,
                        ),
                        side: const BorderSide(color: AppColors.paperAccent),
                        shape: RoundedRectangleBorder(
                        ),
                      ),
                      child: Text(
                        AppStrings.scheduleChangeCounter,
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppColors.paperAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  // Accept
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSlotIndex != null ? _accept : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSpacing.buttonHeightSmall,
                        ),
                        backgroundColor: AppColors.paperAccent,
                        shape: RoundedRectangleBorder(
                        ),
                      ),
                      child: Text(
                        AppStrings.scheduleChangeAccept,
                        style: AppTypography.buttonSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotOption(int index, TimeSlotOption slot) {
    final isSelected = _selectedSlotIndex == index;
    return GestureDetector(
      onTap:
          () => setState(() {
            _selectedSlotIndex = isSelected ? null : index;
          }),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.paperAccent.withValues(alpha: 0.08)
                  : AppColors.paperDark,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '${index + 1}순위 ${slot.displayLabel}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.paperAccent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _accept() {
    Navigator.pop<ScheduleChangeResponseResult>(context, (
      action: ScheduleChangeResponseAction.accept,
      message: '',
      counterSlots: <TimeSlot>[],
      acceptedSlotIndex: _selectedSlotIndex,
    ));
  }

  void _reject() {
    Navigator.pop<ScheduleChangeResponseResult>(context, (
      action: ScheduleChangeResponseAction.reject,
      message: AppStrings.scheduleChangeReject,
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
