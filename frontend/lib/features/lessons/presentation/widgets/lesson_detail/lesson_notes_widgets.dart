import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/lesson.dart';

/// Section header widget for lesson detail screen
class LessonDetailSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const LessonDetailSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.space2),
        Text(title, style: AppTypography.headingSmall),
        const Spacer(),
        if (showAddButton && onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 22,
            color: AppColors.primary,
            tooltip: '추가',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

/// Note editor widget for lesson feedback
class LessonNoteEditor extends StatelessWidget {
  final String? initialText;
  final ValueChanged<String>? onChanged;

  const LessonNoteEditor({
    super.key,
    this.initialText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        maxLines: 6,
        controller: TextEditingController(text: initialText ?? ''),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '레슨 피드백을 작성하세요...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.space4),
        ),
      ),
    );
  }
}

/// Card displaying teacher feedback
class TeacherFeedbackCard extends StatelessWidget {
  final Lesson lesson;

  const TeacherFeedbackCard({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.feedback == null || lesson.feedback!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '아직 피드백이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.feedback!,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
          if (lesson.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              '작성: ${lesson.updatedAt!.month}월 ${lesson.updatedAt!.day}일',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// List of key points for a lesson
class KeyPointsList extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;
  final void Function(int index)? onRemove;

  const KeyPointsList({
    super.key,
    required this.lesson,
    required this.isTeacher,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.keyPoints == null || lesson.keyPoints!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? '+ 버튼을 눌러 주요 포인트를 추가하세요'
                    : '주요 포인트가 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lesson.keyPoints!.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(point, style: AppTypography.bodyMedium),
              ),
              if (isTeacher && onRemove != null)
                IconButton(
                  onPressed: () => onRemove!(index),
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  color: AppColors.textTertiaryLight,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: '삭제',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Practice tips card
class PracticeTipsCard extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;
  final VoidCallback? onEdit;

  const PracticeTipsCard({
    super.key,
    required this.lesson,
    required this.isTeacher,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasTips =
        lesson.practiceTips != null && lesson.practiceTips!.isNotEmpty;

    if (!hasTips) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_outlined,
                color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? '+ 버튼을 눌러 연습 팁을 추가하세요'
                    : '연습 팁이 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              lesson.practiceTips ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
          if (isTeacher && onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 18,
              color: AppColors.info,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: '수정',
            ),
        ],
      ),
    );
  }
}

/// Recording status indicator
class RecordingStatusIndicator extends StatelessWidget {
  final int recordingSeconds;

  const RecordingStatusIndicator({
    super.key,
    required this.recordingSeconds,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '녹음 중',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(recordingSeconds),
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.error,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for recordings
class RecordingsEmptyState extends StatelessWidget {
  const RecordingsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_off, color: AppColors.textTertiaryLight),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '녹음 파일이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show cancel lesson confirmation dialog
Future<bool?> showCancelLessonConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('레슨 취소'),
      content: const Text('이 레슨을 취소하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('아니오'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('취소하기'),
        ),
      ],
    ),
  );
}

/// Show delete lesson confirmation dialog
Future<bool?> showDeleteLessonConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('레슨 삭제'),
      content: const Text(
        '이 레슨을 삭제하시겠습니까?\n녹음 파일과 노트도 함께 삭제됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}

/// Show edit practice tip dialog
Future<String?> showEditPracticeTipDialog({
  required BuildContext context,
  required String? currentTip,
  required bool hasTip,
}) async {
  final controller = TextEditingController(text: currentTip ?? '');

  return showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('연습 팁 수정'),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: '연습 팁을 입력하세요',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        if (hasTip)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    ),
  );
}

/// Format recording duration
String formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
