import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/notebook_typography.dart';

/// Header row for the counter-propose bottom sheet — title + close button.
///
/// Extracted from `_SuggestAlternativeBottomSheetState._buildHeader`
/// (P1-4 file-size split) — no logic changes.
Widget buildSuggestAlternativeHeader({required VoidCallback onClose}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
    child: Row(
      children: [
        Text(AppStrings.counterPropose, style: NotebookTypography.sectionTitle),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          iconSize: 20,
        ),
      ],
    ),
  );
}
