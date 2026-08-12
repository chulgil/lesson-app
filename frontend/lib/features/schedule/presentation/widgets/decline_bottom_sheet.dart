import 'package:flutter/material.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import 'suggest_alternative_bottom_sheet.dart';

/// Result from the decline bottom sheet.
typedef DeclineResult = ({String message, List<TimeSlot> suggestedSlots});

/// Shows the unified decline/schedule-negotiation bottom sheet.
///
/// Returns [DeclineResult] with the message and optional suggested time slots,
/// or null if cancelled. Callers handle their own API calls with the result.
Future<DeclineResult?> showDeclineBottomSheet(
  BuildContext context, {
  required int durationMinutes,
  String? teacherId,
}) {
  return showNotebookBottomSheet<DeclineResult>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder:
        (context) => _DeclineBottomSheet(
          durationMinutes: durationMinutes,
          teacherId: teacherId,
        ),
  );
}

class _DeclineBottomSheet extends StatefulWidget {
  final int durationMinutes;
  final String? teacherId;

  const _DeclineBottomSheet({required this.durationMinutes, this.teacherId});

  @override
  State<_DeclineBottomSheet> createState() => _DeclineBottomSheetState();
}

class _DeclineBottomSheetState extends State<_DeclineBottomSheet> {
  final _messageController = TextEditingController(
    text: AppStrings.declineDefaultMessage,
  );

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
                AppStrings.declineBottomSheetTitle,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Message input (free text, editable)
              TextField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: AppStrings.messageHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // CTA buttons (same design as CurrentRequestBox)
              Row(
                children: [
                  // Send message only (complete rejection)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sendMessageOnly,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSpacing.buttonHeightSmall,
                        ),
                        side: const BorderSide(color: AppColors.inkQuaternary),
                        shape: RoundedRectangleBorder(),
                      ),
                      child: Text(
                        AppStrings.messageOnly,
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  // Suggest alternative times
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _suggestAlternative,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSpacing.buttonHeightSmall,
                        ),
                        backgroundColor: AppColors.paperAccent,
                        shape: RoundedRectangleBorder(),
                      ),
                      child: Text(
                        AppStrings.counterPropose,
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppColors.paper,
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

  void _sendMessageOnly() {
    final message =
        _messageController.text.trim().isEmpty
            ? AppStrings.declineDefaultMessage
            : _messageController.text.trim();

    Navigator.pop<DeclineResult>(context, (
      message: message,
      suggestedSlots: <TimeSlot>[],
    ));
  }

  Future<void> _suggestAlternative() async {
    // Switch to propose default if user hasn't modified the decline default
    final currentText = _messageController.text.trim();
    final message =
        currentText.isEmpty || currentText == AppStrings.declineDefaultMessage
            ? AppStrings.proposeDefaultMessage
            : currentText;

    final result = await showSuggestAlternativeBottomSheet(
      context,
      message: message,
      durationMinutes: widget.durationMinutes,
      teacherId: widget.teacherId,
    );

    if (result != null && mounted) {
      Navigator.pop<DeclineResult>(context, (
        message: result.message,
        suggestedSlots: result.slots,
      ));
    }
  }
}
