import 'package:flutter/material.dart';

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
    builder: (context) => AlertDialog(
      title: const Text('작성 취소'),
      content: const Text('입력한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('계속 작성'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onExit();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: const Text('나가기'),
        ),
      ],
    ),
  );
}
