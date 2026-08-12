import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../lessons/domain/entities/lesson.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/entities/unified_lesson_request.dart';
import 'suggest_alternative_conflict.dart';

/// Bottom section with message input and action buttons (accept mode or
/// propose/reject mode). Rendered above the keyboard by the caller.
///
/// Extracted from `_SuggestAlternativeBottomSheetState._buildBottomSection`
/// + `_buildAcceptButton` + `_buildProposeButtons` (P1-4 file-size split) —
/// no logic changes.
Widget buildSuggestAlternativeBottomSection({
  required TextEditingController messageController,
  required bool isAcceptMode,
  required List<Lesson> lessons,
  required TeacherAvailability? availability,
  required List<PreferredTimeSlot> preferredSlots,
  required int? selectedPreferredIndex,
  required DateTime weekStart,
  required int suggestedSlotsCount,
  required VoidCallback onSubmitAccept,
  required VoidCallback onReject,
  required VoidCallback? onSubmitPropose,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.space3,
      AppSpacing.screenPadding,
      AppSpacing.space3,
    ),
    decoration: const BoxDecoration(
      color: AppColors.paperDark,
      border: Border(
        top: BorderSide(color: AppColors.inkQuaternary, width: 0.5),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message input (same style as chat input)
        TextField(
          controller: messageController,
          maxLines: isAcceptMode ? 2 : 3,
          minLines: 1,
          maxLength: 200,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            hintText:
                isAcceptMode
                    ? AppStrings.acceptMessageHint
                    : AppStrings.messageHint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Action buttons
        isAcceptMode
            ? _buildAcceptButton(
              lessons: lessons,
              availability: availability,
              preferredSlots: preferredSlots,
              selectedPreferredIndex: selectedPreferredIndex,
              weekStart: weekStart,
              onSubmitAccept: onSubmitAccept,
            )
            : _buildProposeButtons(
              suggestedSlotsCount: suggestedSlotsCount,
              onReject: onReject,
              onSubmitPropose: onSubmitPropose,
            ),
      ],
    ),
  );
}

/// Accept mode: confirm button — states:
/// - null conflict: green "이 일정으로 확정"
/// - 'preview' conflict: warning "프리뷰 겹침 — 확정" (enabled)
/// - 'confirmed' conflict: disabled "일정 겹침"
/// - 'vacation'/'hours' conflict (#526): disabled with the matching reason —
///   the teacher cannot accept a slot inside their own vacation or outside
///   operating hours.
Widget _buildAcceptButton({
  required List<Lesson> lessons,
  required TeacherAvailability? availability,
  required List<PreferredTimeSlot> preferredSlots,
  required int? selectedPreferredIndex,
  required DateTime weekStart,
  required VoidCallback onSubmitAccept,
}) {
  final selectedSlot = preferredSlots.firstWhere(
    (s) => s.priority == selectedPreferredIndex,
    orElse: () => preferredSlots.first,
  );
  final conflict = checkSlotConflict(
    selectedSlot,
    lessons,
    availability,
    weekStart: weekStart,
  );
  final hasPreviewConflict = conflict == 'preview';
  // Lesson overlap, vacation, and outside-operating-hours all hard-block.
  final hasHardConflict =
      conflict == 'confirmed' || conflict == 'vacation' || conflict == 'hours';

  final Color bgColor;
  final IconData icon;
  final String label;

  if (hasHardConflict) {
    bgColor = AppColors.paperAccent;
    icon = Icons.block;
    label = conflictLabelFor(conflict) ?? AppStrings.slotConflict;
  } else if (hasPreviewConflict) {
    bgColor = AppColors.paperAccent;
    icon = Icons.warning_amber_rounded;
    label = AppStrings.previewConflictConfirm;
  } else {
    bgColor = AppColors.paperOk;
    icon = Icons.check_circle;
    label = AppStrings.confirmThisSchedule;
  }

  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: hasHardConflict ? null : onSubmitAccept,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
        backgroundColor: bgColor,
        disabledBackgroundColor: AppColors.scheduleMutedAccent,
        shape: RoundedRectangleBorder(),
      ),
    ),
  );
}

/// Propose mode: [거절하기] [시간을 선택하세요/제안하기]
Widget _buildProposeButtons({
  required int suggestedSlotsCount,
  required VoidCallback onReject,
  required VoidCallback? onSubmitPropose,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
            side: const BorderSide(color: AppColors.inkQuaternary),
            shape: RoundedRectangleBorder(),
          ),
          child: Text(
            AppStrings.rejectAction,
            style: AppTypography.buttonSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.space3),
      Expanded(
        child: ElevatedButton(
          onPressed: onSubmitPropose,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeightSmall),
            backgroundColor: AppColors.paperAccent,
            disabledBackgroundColor: AppColors.scheduleMutedAccent,
            shape: RoundedRectangleBorder(),
          ),
          child: Text(
            AppStrings.proposeAction(suggestedSlotsCount),
            style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
          ),
        ),
      ),
    ],
  );
}
