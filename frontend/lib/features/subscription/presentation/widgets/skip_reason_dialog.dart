import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';

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
    return AlertDialog(
      title: const Text(AppStrings.skipProposalTitle),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text(AppStrings.skipProposalAction),
        ),
      ],
    );
  }
}
