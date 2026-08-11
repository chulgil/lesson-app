import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Renders the "more actions" bottom sheet for [RequestDetailScreen]'s
/// AppBar. The caller decides which [items] are available (business rules
/// live in the screen) — this only lays out the list.
void showRequestDetailMoreMenu({
  required BuildContext context,
  required List<(IconData icon, String label, VoidCallback onTap)> items,
}) {
  if (items.isEmpty) return;

  showNotebookBottomSheet(
    context: context,
    builder:
        (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.space2),
              const BottomSheetHandle(margin: EdgeInsets.zero),
              const SizedBox(height: AppSpacing.space3),
              for (final (icon, label, onTap) in items)
                ListTile(
                  leading: Icon(
                    icon,
                    color:
                        label == AppStrings.cancelRequestAction
                            ? AppColors.paperAccent
                            : AppColors.ink,
                  ),
                  title: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          label == AppStrings.cancelRequestAction
                              ? AppColors.paperAccent
                              : AppColors.ink,
                    ),
                  ),
                  onTap: onTap,
                ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
  );
}
