import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_alert_dialog.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Reject-reason input dialog for a teacher rejecting a refund request
/// (#1271). Confirm stays disabled until a reason is entered — reason is
/// required (unlike [SkipReasonDialog], which allows an empty skip note).
class RefundRejectReasonDialog extends StatefulWidget {
  const RefundRejectReasonDialog({super.key});

  @override
  State<RefundRejectReasonDialog> createState() =>
      _RefundRejectReasonDialogState();
}

class _RefundRejectReasonDialogState extends State<RefundRejectReasonDialog> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      final empty = _controller.text.trim().isEmpty;
      if (empty != _isEmpty) setState(() => _isEmpty = empty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title: AppStrings.refundActionBoxRejectTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: AppStrings.refundActionBoxRejectReasonHint,
              border: OutlineInputBorder(),
            ),
          ),
          if (_isEmpty) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.refundActionBoxRejectReasonRequired,
              style: TextStyle(fontSize: 11, color: AppColors.paperAccent),
            ),
          ],
        ],
      ),
      isDestructive: true,
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context, null),
      confirmLabel: AppStrings.refundActionBoxReject,
      onConfirm:
          _isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
    );
  }
}
