import 'package:flutter/material.dart';

import '../../../../../core/booking/entities/time_slot.dart';
import '../../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// List of the caller's suggested alternative slots (up to 3), each
/// editable/removable — hidden while accepting a preferred slot directly.
///
/// Extracted from `_SuggestAlternativeBottomSheetState._buildSuggestedSlotsList`
/// (P1-4 file-size split) — no logic changes.
Widget buildSuggestAlternativeSuggestedSlotsList({
  required List<TimeSlot> suggestedSlots,
  required void Function(int index) onEdit,
  required void Function(int index) onRemove,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenPadding,
      vertical: AppSpacing.space2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.suggestedSlotsCount(suggestedSlots.length),
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        ...suggestedSlots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.05),
                border: Border.all(
                  color: AppColors.paperAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    ['❶', '❷', '❸'][index.clamp(0, 2)],
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      slot.displayLabel,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEdit(index),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.inkSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => onRemove(index),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.paperAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}
