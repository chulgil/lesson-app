import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../../domain/constants/feedback_constants.dart';

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
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 섹션 제목을 Playfair 17 로 통일 (매스트헤드·AppBar 위계와 맞춤).
        Text(title, style: NotebookTypography.sectionTitle),
        const Spacer(),
        if (showAddButton && onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 22,
            color: AppColors.paperAccent,
            tooltip: AppStrings.add,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

/// Note editor widget for lesson feedback with save status indicator
/// and preset phrase chips for quick input.
class LessonNoteEditor extends StatefulWidget {
  final String? initialText;
  final ValueChanged<String>? onChanged;

  const LessonNoteEditor({super.key, this.initialText, this.onChanged});

  @override
  State<LessonNoteEditor> createState() => _LessonNoteEditorState();
}

class _LessonNoteEditorState extends State<LessonNoteEditor> {
  late TextEditingController _controller;
  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _statusResetTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _statusResetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() => _saveStatus = _SaveStatus.saving);
    widget.onChanged?.call(text);

    // Show "saved" after debounce delay (800ms) + small buffer
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _saveStatus = _SaveStatus.saved);
        // Reset to idle after 2 seconds
        _statusResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
        });
      }
    });
  }

  void _insertPreset(String preset) {
    final currentText = _controller.text;
    final selection = _controller.selection;

    String newText;
    int newCursorPos;

    if (currentText.isEmpty) {
      newText = preset;
      newCursorPos = preset.length;
    } else if (selection.isValid &&
        selection.baseOffset == selection.extentOffset) {
      // Insert at cursor position
      final before = currentText.substring(0, selection.baseOffset);
      final after = currentText.substring(selection.baseOffset);
      final separator = before.isNotEmpty && !before.endsWith('\n') ? '\n' : '';
      newText = '$before$separator$preset$after';
      newCursorPos = before.length + separator.length + preset.length;
    } else {
      // Append at end
      newText = '$currentText\n$preset';
      newCursorPos = newText.length;
    }

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _onChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feedbackPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              return ActionChip(
                label: Text(
                  feedbackPresets[index],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
                backgroundColor: AppColors.paperAccentSoft,
                side: BorderSide(color: AppColors.paperAccentSoft),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => _insertPreset(feedbackPresets[index]),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Text editor
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: TextField(
            maxLines: 6,
            controller: _controller,
            onChanged: _onChanged,
            // 선생님 피드백 = 자필 본문 → Tier 1 Gaegu hand
            // (README §1.1.1, §7.129 사용자 입력 정렬).
            style: NotebookTypography.hand,
            decoration: InputDecoration(
              hintText: AppStrings.feedbackEditorHint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.space4),
            ),
          ),
        ),

        // Save status
        if (_saveStatus != _SaveStatus.idle)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    _saveStatus == _SaveStatus.saving
                        ? Row(
                          key: const ValueKey('saving'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.inkTertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              AppStrings.savingLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          key: const ValueKey('saved'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.paperOk,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              AppStrings.savedLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperOk,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _SaveStatus { idle, saving, saved }

/// Card displaying teacher feedback
class TeacherFeedbackCard extends StatelessWidget {
  final Lesson lesson;

  const TeacherFeedbackCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    if (lesson.feedback == null || lesson.feedback!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Text(
              AppStrings.feedbackEmpty,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Notebook × Score: 레슨 상세 피드백 본문도 선생님 손글씨 주석(Gaegu)으로 렌더.
            lesson.feedback!,
            style: NotebookTypography.hand,
          ),
          if (lesson.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.feedbackWrittenAt(formatDateYMD(lesson.updatedAt!)),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
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
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? AppStrings.keyPointsEmptyTeacher
                    : AppStrings.keyPointsEmptyStudent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          lesson.keyPoints!.asMap().entries.map((entry) {
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
                      color: AppColors.paperAccent,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(child: Text(point, style: AppTypography.bodyMedium)),
                  if (isTeacher && onRemove != null)
                    IconButton(
                      onPressed: () => onRemove!(index),
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: AppColors.inkTertiary,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: AppStrings.delete,
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
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_outlined, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? AppStrings.practiceTipsEmptyTeacher
                    : AppStrings.practiceTipsEmptyStudent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            // Notebook × Score: 연습 팁은 선생님이 여백에 손글씨로 적어준 메모.
            child: Text(
              lesson.practiceTips ?? '',
              style: NotebookTypography.hand.copyWith(color: AppColors.ink),
            ),
          ),
          if (isTeacher && onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 18,
              color: AppColors.ink,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: AppStrings.modify,
            ),
        ],
      ),
    );
  }
}

/// Recording status indicator
class RecordingStatusIndicator extends StatelessWidget {
  final int recordingSeconds;

  const RecordingStatusIndicator({super.key, required this.recordingSeconds});

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
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.paperAccent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.recordingInProgress,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(recordingSeconds),
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.paperAccent,
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
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          Icon(Icons.mic_off, color: AppColors.inkTertiary),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.recordingsEmpty,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
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
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.actionLessonCancel),
          content: const Text(AppStrings.cancelLessonConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.cancelRequestAction),
            ),
          ],
        ),
  );
}

/// Show delete lesson confirmation dialog
Future<bool?> showDeleteLessonConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.deleteLessonTitle),
          content: const Text(AppStrings.deleteLessonConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.delete),
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
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.editPracticeTipTitle),
          content: TextField(
            controller: controller,
            maxLines: 4,
            // 연습 팁 = 선생님 자필 → Tier 1 Gaegu hand
            // (README §1.1.1, §7.129).
            style: NotebookTypography.hand,
            decoration: const InputDecoration(
              hintText: AppStrings.editPracticeTipHint,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(AppStrings.cancel),
            ),
            if (hasTip)
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text(
                  AppStrings.delete,
                  style: TextStyle(color: AppColors.paperAccent),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
  );
}

/// Student memo card - allows students to write their own notes about a lesson
class StudentMemoCard extends StatefulWidget {
  final String? initialMemo;
  final ValueChanged<String> onSave;

  const StudentMemoCard({super.key, this.initialMemo, required this.onSave});

  @override
  State<StudentMemoCard> createState() => _StudentMemoCardState();
}

class _StudentMemoCardState extends State<StudentMemoCard> {
  late final TextEditingController _controller;
  Timer? _debounce;
  _SaveStatus _status = _SaveStatus.idle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemo);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _status = _SaveStatus.saving);
    _debounce = Timer(const Duration(milliseconds: 800), () {
      try {
        widget.onSave(value.trim());
        if (mounted) {
          setState(() => _status = _SaveStatus.saved);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _status = _SaveStatus.idle);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonDetailSectionHeader(
          title: AppStrings.studentMemoTitle,
          icon: Icons.sticky_note_2_outlined,
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            border: Border.all(color: AppColors.paperAccentSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppStrings.studentMemoHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                // 학생 메모 = 자필 본문 → Tier 1 Gaegu hand
                // (README §1.1.1, §7.129 사용자 입력 정렬).
                style: NotebookTypography.hand,
              ),
              const SizedBox(height: AppSpacing.space2),
              if (_status == _SaveStatus.saving)
                Text(
                  AppStrings.savingLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                )
              else if (_status == _SaveStatus.saved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: AppColors.paperOk),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      AppStrings.savedLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperOk,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Format recording duration
String formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
