import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Week navigation row (prev/next) for the counter-propose weekly grid.
///
/// Extracted from `_SuggestAlternativeBottomSheetState._buildWeekNav`
/// (P1-4 file-size split) — no logic changes.
Widget buildSuggestAlternativeWeekNav({
  required DateTime weekStart,
  required VoidCallback onPrevWeek,
  required VoidCallback onNextWeek,
}) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final label =
      '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}';

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenPadding,
      vertical: AppSpacing.space2,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevWeek,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
        ),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: onNextWeek,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
        ),
      ],
    ),
  );
}
