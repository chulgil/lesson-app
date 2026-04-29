import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Exit confirmation dialog
void showLessonExitConfirmation({
  required BuildContext context,
  required bool hasData,
  required VoidCallback onExit,
}) {
  if (!hasData) {
    onExit();
    return;
  }

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.cancelWritingTitle),
          content: const Text(AppStrings.exitWithoutSavingConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.continueWriting),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onExit();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.exitAction),
            ),
          ],
        ),
  );
}
