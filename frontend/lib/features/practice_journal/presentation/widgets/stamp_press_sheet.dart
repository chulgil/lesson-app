import 'package:flutter/material.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_bottom_sheet.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';

/// Shows the "도장 꾹!" reward bottom sheet after practice completion.
///
/// The sheet presents a single warm CTA. Tapping it calls [onPressed]
/// and dismisses the sheet. Routed through [showNotebookBottomSheet]
/// (paper surface, square corners, drag handle — 각진 원칙).
Future<void> showStampPressSheet(
  BuildContext context, {
  required VoidCallback onPressed,
}) {
  return showNotebookBottomSheet<void>(
    context: context,
    builder: (ctx) => _StampPressContent(onPressed: onPressed),
  );
}

class _StampPressContent extends StatelessWidget {
  final VoidCallback onPressed;

  const _StampPressContent({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // SafeArea/padding/handle are provided by NotebookBottomSheet.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stamp glyph — signature area: NotebookGlyph, no Material Icons
        NotebookGlyph(
          NotebookGlyph.starFilled,
          size: 48,
          color: AppColors.paperAccent,
          semanticLabel: AppStrings.journalMarkStandard,
        ),
        const SizedBox(height: AppSpacing.space4),
        // Full-width primary CTA (avoids BoxConstraints(w=Infinity) trap)
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              minimumSize: const Size(0, AppSpacing.buttonHeight),
            ),
            onPressed: () {
              Navigator.pop(context);
              onPressed();
            },
            child: Text(AppStrings.journalStampPressCta),
          ),
        ),
      ],
    );
  }
}
