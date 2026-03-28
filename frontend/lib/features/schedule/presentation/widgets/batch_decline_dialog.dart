import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';

/// Shows a dialog for batch-declining multiple lesson requests.
///
/// Teacher can enter a shared reason message for all selected students.
Future<void> showBatchDeclineDialog(
  BuildContext context,
  WidgetRef ref,
  List<LessonRequest> requests, {
  required VoidCallback onComplete,
}) async {
  final reasonController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${requests.length}명 레슨 요청 보류'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('선택한 ${requests.length}명의 학생에게 동일한 안내 메시지를 전달합니다.'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '예: 현재 가능한 시간이 없어 이번에는 어렵습니다.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.textSecondaryLight,
          ),
          child: const Text('모두 보류'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      final reason = reasonController.text.isEmpty
          ? '현재 스케줄 조정이 어려워요. 다음에 꼭 연락드릴게요!'
          : reasonController.text;

      for (final request in requests) {
        await ref
            .read(lessonRequestActionsProvider.notifier)
            .declineRequest(requestId: request.id, reason: reason);
      }

      onComplete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${requests.length}명에게 안내 메시지를 전달했습니다'),
            backgroundColor: AppColors.textSecondaryLight,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  reasonController.dispose();
}
