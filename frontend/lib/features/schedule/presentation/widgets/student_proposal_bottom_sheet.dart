import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';

/// Shows teacher's counter-proposed time slots for student to select one.
///
/// The student picks exactly one slot and taps "수락" to confirm the schedule.
/// Calls [acceptAlternative] with the selected slot index.
Future<void> showStudentProposalBottomSheet(
  BuildContext context, {
  required UnifiedLessonRequest request,
  required TimeProposal teacherProposal,
  required VoidCallback onComplete,
}) {
  return showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          expand: false,
          builder:
              (context, scrollController) => _StudentProposalBottomSheet(
                request: request,
                teacherProposal: teacherProposal,
                scrollController: scrollController,
                onComplete: onComplete,
              ),
        ),
  );
}

class _StudentProposalBottomSheet extends ConsumerStatefulWidget {
  final UnifiedLessonRequest request;
  final TimeProposal teacherProposal;
  final ScrollController scrollController;
  final VoidCallback onComplete;

  const _StudentProposalBottomSheet({
    required this.request,
    required this.teacherProposal,
    required this.scrollController,
    required this.onComplete,
  });

  @override
  ConsumerState<_StudentProposalBottomSheet> createState() =>
      _StudentProposalBottomSheetState();
}

class _StudentProposalBottomSheetState
    extends ConsumerState<_StudentProposalBottomSheet> {
  int? _selectedIndex;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: BottomSheetHandle()),
              const SizedBox(height: AppSpacing.space4),

              // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
              Text(
                AppStrings.scheduleTeacherProposal,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space3),

              // Teacher message
              if (widget.teacherProposal.message != null &&
                  widget.teacherProposal.message!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.paperAccent,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          widget.teacherProposal.message!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Instruction
              Text(
                '원하는 시간을 선택해주세요',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Slot options
              ...List.generate(widget.teacherProposal.slots.length, (index) {
                final slot = widget.teacherProposal.slots[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.paperAccentSoft
                                : AppColors.paperDark,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                isSelected
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Text(
                              slot.displayLabel,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.space4),

              // Action buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSecondary,
                        side: BorderSide(color: AppColors.inkQuaternary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  // Accept selected
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed:
                          _selectedIndex != null && !_isProcessing
                              ? _handleAccept
                              : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.paper,
                                ),
                              )
                              : Text(AppStrings.accept),
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

  Future<void> _handleAccept() async {
    if (_selectedIndex == null) return;

    setState(() => _isProcessing = true);

    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.acceptAlternative(
        widget.request.id,
        widget.request.teacherId,
        widget.request.studentId,
        selectedSlotIndex: _selectedIndex!,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
