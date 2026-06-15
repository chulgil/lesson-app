import 'package:flutter/material.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';

/// Shows the "도장 꾹!" reward bottom sheet after practice completion.
///
/// The sheet presents a single warm CTA. Tapping it calls [onPressed]
/// and dismisses the sheet.
Future<void> showStampPressSheet(
  BuildContext context, {
  required VoidCallback onPressed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _StampPressSheet(onPressed: onPressed),
  );
}

class _StampPressSheet extends StatelessWidget {
  final VoidCallback onPressed;

  const _StampPressSheet({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space6,
          AppSpacing.space4,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stamp glyph — signature area: NotebookGlyph, no Material Icons
            NotebookGlyph(
              NotebookGlyph.starFilled,
              size: 48,
              color: AppColors.paperAccent,
              semanticLabel: '도장',
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
        ),
      ),
    );
  }
}
