import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';

/// Confirmation dialog shown when applying a template would overwrite the
/// teacher's current feedback body.
class ReplaceFeedbackConfirmDialog {
  ReplaceFeedbackConfirmDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text(AppStrings.feedbackTemplateReplaceConfirmTitle),
            content: const Text(
              AppStrings.feedbackTemplateReplaceConfirmContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(AppStrings.feedbackTemplateReplaceConfirmCta),
              ),
            ],
          ),
    );
    return result ?? false;
  }
}
