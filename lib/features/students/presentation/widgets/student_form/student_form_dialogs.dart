import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Show image picker options bottom sheet.
void showImagePickerOptions(
  BuildContext context, {
  VoidCallback? onCamera,
  VoidCallback? onGallery,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXLarge),
      ),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space2),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('카메라로 촬영'),
            onTap: () {
              Navigator.pop(context);
              onCamera?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리에서 선택'),
            onTap: () {
              Navigator.pop(context);
              onGallery?.call();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: Text('사진 삭제', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    ),
  );
}

/// Show exit confirmation dialog.
void showExitConfirmation(
  BuildContext context, {
  required bool hasChanges,
  required VoidCallback onExit,
}) {
  if (!hasChanges) {
    onExit();
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('변경사항 취소'),
      content: const Text('변경한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('계속 수정'),
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

/// Show delete confirmation dialog.
void showDeleteStudentConfirmation(
  BuildContext context, {
  required String studentName,
  required VoidCallback onDelete,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('학생 삭제'),
      content: Text(
        '$studentName 학생을 삭제하시겠습니까?\n\n'
        '관련된 모든 레슨 기록과 연습 기록이 함께 삭제됩니다.\n'
        '이 작업은 되돌릴 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
