import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_alert_dialog.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Skip reason input dialog for proposal rejection.
/// Manages its own TextEditingController lifecycle to prevent
/// "controller disposed" errors from parent widget rebuilds.
class SkipReasonDialog extends StatefulWidget {
  const SkipReasonDialog({super.key});

  @override
  State<SkipReasonDialog> createState() => _SkipReasonDialogState();
}

class _SkipReasonDialogState extends State<SkipReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title: AppStrings.skipProposalTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.skipProposalContent),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: AppStrings.skipReasonLabel,
              hintText: AppStrings.skipReasonHint,
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context, null),
      confirmLabel: AppStrings.skipProposalAction,
      onConfirm: () => Navigator.pop(context, _controller.text),
    );
  }
}
