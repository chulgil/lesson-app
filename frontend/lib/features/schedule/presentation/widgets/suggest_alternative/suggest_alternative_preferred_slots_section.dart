import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../lessons/domain/entities/lesson.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/entities/unified_lesson_request.dart';
import '../../extensions/unified_lesson_request_visuals.dart';
import 'suggest_alternative_conflict.dart';

/// Student's preferred time slots as selectable cards. Tapping one hands
/// off to [onSlotTap], which switches the sheet to accept mode.
///
/// Extracted from
/// `_SuggestAlternativeBottomSheetState._buildPreferredSlotsSection` (P1-4
/// file-size split) — no logic changes, `setState` now lives in the caller's
/// [onSlotTap] callback.
Widget buildSuggestAlternativePreferredSlotsSection({
  required List<PreferredTimeSlot> preferredSlots,
  required List<Lesson> currentWeekLessons,
  required TeacherAvailability? availability,
  required DateTime weekStart,
  required int? selectedPreferredIndex,
  required void Function(PreferredTimeSlot slot) onSlotTap,
}) {
  final sorted = [...preferredSlots]
    ..sort((a, b) => a.priority.compareTo(b.priority));

  return Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.space3,
      AppSpacing.screenPadding,
      AppSpacing.space2,
    ),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: AppSpacing.iconSM,
              color: AppColors.ink,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              AppStrings.studentPreferredSlots,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        ...sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          final isSelected = selectedPreferredIndex == slot.priority;
          final conflict = checkSlotConflict(
            slot,
            currentWeekLessons,
            availability,
            weekStart: weekStart,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GestureDetector(
              onTap: () => onSlotTap(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.paperOk.withValues(alpha: 0.08)
                          : AppColors.paper,
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.paperOk
                            : AppColors.inkQuaternary,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.paperOk
                                : AppColors.ink.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.paper,
                                )
                                : Text(
                                  '${index + 1}',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        slot.displayLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.paperOk : AppColors.ink,
                        ),
                      ),
                    ),
                    // Conflict hint (lesson / vacation / operating hours)
                    ..._conflictHint(conflict),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

/// Inline warning icon + label for a conflict code (empty when no conflict).
List<Widget> _conflictHint(String? conflict) {
  final label = conflictLabelFor(conflict);
  if (label == null) return const [];
  return [
    const SizedBox(width: AppSpacing.space1),
    Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.paperAccent),
    const SizedBox(width: 2),
    Text(
      label,
      style: AppTypography.captionSmall.copyWith(color: AppColors.paperAccent),
    ),
  ];
}
