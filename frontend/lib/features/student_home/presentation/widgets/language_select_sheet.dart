// Language selection bottom sheet.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Bottom sheet for language selection.
///
/// MVP supports Korean only. EN/JP are not offered until a real locale
/// provider exists, so no NO-OP "coming soon" rows are shown (#506).
class LanguageSelectSheet extends StatelessWidget {
  const LanguageSelectSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showNotebookBottomSheet<void>(
      context: context,
      padding: EdgeInsets.zero,
      showHandle: false,
      builder: (_) => const LanguageSelectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

              const SizedBox(height: AppSpacing.space5),

              // Notebook × Score: 시트 헤더는 Playfair sectionTitle (§7.87-f / §7.27).
              Text(
                AppStrings.studentHomeLanguageSettings,
                style: NotebookTypography.sectionTitle,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Korean — the only supported language (selected).
              _buildLanguageItem(
                context,
                name: AppStrings.studentHomeLanguageKorean,
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccentSoft,
          border: Border.all(color: AppColors.paperAccent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.check_circle, color: AppColors.paperAccent, size: 22),
          ],
        ),
      ),
    );
  }
}
