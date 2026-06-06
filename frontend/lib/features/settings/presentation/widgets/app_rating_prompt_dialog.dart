import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';

/// First-stage rating prompt — "도움이 되시나요?"
///
/// Returns:
/// - `true` — user is satisfied (네, 도움돼요!) → trigger store review
/// - `false` — user is dissatisfied (아쉬워요) → show feedback dialog
/// - `null` — barrier dismiss (treated as dismissed by caller)
///
/// Spec: `docs/specs/settings/app_rating_prompt_spec.md` §8.
class AppRatingPromptDialog extends StatelessWidget {
  const AppRatingPromptDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppRatingPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      titleWidget: const Text(AppStrings.ratingPromptTitle),
      content: const Text(
        AppStrings.ratingPromptBody,
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.ratingPromptNo),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeight),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.ratingPromptYes),
        ),
      ],
    );
  }
}
