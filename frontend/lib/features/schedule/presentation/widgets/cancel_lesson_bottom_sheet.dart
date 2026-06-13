// ignore: widget-smoke-test
// Internal bottom sheet (private class) — covered by request_detail widget test.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/cancel_reason.dart';
import '../extensions/cancel_reason_visuals.dart';

/// Shows a bottom sheet to select a cancellation reason before confirming.
/// Returns the selected [CancelReason], or null if the user dismissed.
Future<CancelReason?> showCancelLessonBottomSheet(BuildContext context) {
  return showNotebookBottomSheet<CancelReason>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder: (context) => const _CancelLessonBottomSheet(),
  );
}

class _CancelLessonBottomSheet extends StatefulWidget {
  const _CancelLessonBottomSheet();

  @override
  State<_CancelLessonBottomSheet> createState() =>
      _CancelLessonBottomSheetState();
}

class _CancelLessonBottomSheetState extends State<_CancelLessonBottomSheet> {
  CancelReason? _selected;

  static const _reasons = CancelReason.values;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: BottomSheetHandle(
                margin: EdgeInsets.only(bottom: AppSpacing.space4),
              ),
            ),
            Text(
              AppStrings.cancelReasonPrompt,
              style: NotebookTypography.appBarTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            // Credit deduction notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: const BoxDecoration(
                color: AppColors.bubbleWarningBackground,
              ),
              child: Text(
                AppStrings.studentCancelDeductNotice,
                style: AppTypography.caption.copyWith(
                  color: AppColors.bubbleWarningText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            for (final reason in _reasons) ...[
              _ReasonTile(
                label: reason.label,
                isSelected: _selected == reason,
                onTap: () => setState(() => _selected = reason),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            const SizedBox(height: AppSpacing.space4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  backgroundColor: AppColors.paperAccent,
                ),
                child: Text(
                  AppStrings.cancelRequestAction,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.paperAccentSoft
              : AppColors.inkQuaternary,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.paperAccent : AppColors.inkTertiary,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.paperAccent : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
