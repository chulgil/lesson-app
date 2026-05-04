import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';

/// Confirmation dialog shown when applying a template would overwrite the
/// teacher's current feedback body.
class ReplaceFeedbackConfirmDialog {
  ReplaceFeedbackConfirmDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.feedbackTemplateReplaceConfirmTitle,
      content: const Text(AppStrings.feedbackTemplateReplaceConfirmContent),
      confirmLabel: AppStrings.feedbackTemplateReplaceConfirmCta,
      cancelLabel: AppStrings.cancel,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    return result ?? false;
  }
}
