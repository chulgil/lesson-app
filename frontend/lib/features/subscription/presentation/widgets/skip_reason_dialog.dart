import 'package:flutter/material.dart';

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
      title: const Text('이번엔 스킵'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이번 제안을 스킵하시겠습니까?\n나중에 다시 제안받을 수 있어요.'),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '사유 (선택)',
              hintText: '선생님께 전달할 메시지',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('스킵하기'),
        ),
      ],
    );
  }
}
