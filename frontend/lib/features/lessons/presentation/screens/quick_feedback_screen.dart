import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';

/// Preset phrases for quick feedback input.
const _feedbackPresets = [
  '음정 주의',
  '리듬 좋음',
  '활 주법 연습',
  '자세 교정',
  '진도 우수',
  '많이 향상됨',
  '복습 필요',
  '천천히 연습',
  '메트로놈 사용',
];

/// Quick feedback writing screen for a specific lesson.
/// Supports feedback text, key points, and practice tips.
class QuickFeedbackScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const QuickFeedbackScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<QuickFeedbackScreen> createState() =>
      _QuickFeedbackScreenState();
}

class _QuickFeedbackScreenState extends ConsumerState<QuickFeedbackScreen> {
  late TextEditingController _feedbackController;
  late TextEditingController _tipController;
  final List<String> _keyPoints = [];
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _showKeyPoints = false;
  bool _showTips = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _tipController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _initFromLesson(Lesson lesson) {
    if (!_hasChanges && _feedbackController.text.isEmpty) {
      _feedbackController.text = lesson.feedback ?? '';
    }
    if (!_hasChanges && _keyPoints.isEmpty && lesson.keyPoints != null) {
      _keyPoints.addAll(lesson.keyPoints!);
    }
    if (!_hasChanges && _tipController.text.isEmpty) {
      _tipController.text = lesson.practiceTips ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('피드백')),
            body: const Center(child: Text('레슨을 찾을 수 없습니다')),
          );
        }

        _initFromLesson(lesson);

        return Scaffold(
          appBar: AppBar(
            title: Text('${lesson.studentName} 피드백'),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _hasChanges ? () => _saveFeedback(lesson) : null,
                  child: const Text('저장'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson info header
                _buildLessonHeader(lesson),

                const SizedBox(height: AppSpacing.space6),

                // Feedback text field
                _buildSectionHeader(
                  icon: Icons.edit_note,
                  title: '레슨 피드백',
                ),
                const SizedBox(height: AppSpacing.space3),
                _buildFeedbackField(),

                const SizedBox(height: AppSpacing.space5),

                // Key Points (collapsible)
                _buildExpandableSection(
                  icon: Icons.lightbulb_outline,
                  title: '주요 포인트',
                  count: _keyPoints.length,
                  isExpanded: _showKeyPoints,
                  onToggle: () =>
                      setState(() => _showKeyPoints = !_showKeyPoints),
                  child: _buildKeyPointsSection(),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Practice Tips (collapsible)
                _buildExpandableSection(
                  icon: Icons.tips_and_updates_outlined,
                  title: '연습 팁',
                  count: _tipController.text.isNotEmpty ? 1 : 0,
                  isExpanded: _showTips,
                  onToggle: () => setState(() => _showTips = !_showTips),
                  child: _buildTipsField(),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _hasChanges && !_isSaving
                            ? () => _saveFeedback(lesson)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('저장하기'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('피드백')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('피드백')),
        body: Center(
          child: Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonHeader(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lesson.date.month}월 ${lesson.date.day}일 ${lesson.startTime} 레슨',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${lesson.instrument} · ${lesson.duration}분',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.space2),
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _insertPreset(String preset) {
    final currentText = _feedbackController.text;
    final selection = _feedbackController.selection;

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
      final separator =
          before.isNotEmpty && !before.endsWith('\n') ? '\n' : '';
      newText = '$before$separator$preset$after';
      newCursorPos = before.length + separator.length + preset.length;
    } else {
      // Append at end
      newText = '$currentText\n$preset';
      newCursorPos = newText.length;
    }

    _feedbackController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    setState(() => _hasChanges = true);
  }

  Widget _buildPresetChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _feedbackPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              _feedbackPresets[index],
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () => _insertPreset(_feedbackPresets[index]),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPresetChips(),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 6,
            onChanged: (_) => setState(() => _hasChanges = true),
            decoration: InputDecoration(
              hintText: '레슨 피드백을 작성하세요...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.space4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.space2),
          child,
        ],
      ],
    );
  }

  Widget _buildKeyPointsSection() {
    return Column(
      children: [
        // Existing points
        ..._keyPoints.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _keyPoints.removeAt(entry.key);
                        _hasChanges = true;
                      });
                    },
                    icon: Icon(Icons.close,
                        size: 18, color: AppColors.textTertiaryLight),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
        }),

        // Add new point
        _KeyPointInput(
          onAdd: (text) {
            setState(() {
              _keyPoints.add(text);
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTipsField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _tipController,
        maxLines: 3,
        onChanged: (_) => setState(() => _hasChanges = true),
        decoration: InputDecoration(
          hintText: '연습할 때 주의할 점을 적어주세요...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.space4),
        ),
      ),
    );
  }

  Future<void> _saveFeedback(Lesson lesson) async {
    setState(() => _isSaving = true);

    try {
      final feedbackText = _feedbackController.text.trim();
      final tipText = _tipController.text.trim();
      final updatedLesson = lesson.copyWith(
        feedback: feedbackText.isEmpty ? null : feedbackText,
        keyPoints: _keyPoints.isEmpty ? null : _keyPoints,
        practiceTips: tipText.isEmpty ? null : tipText,
      );

      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ 피드백이 저장되었습니다'),
            backgroundColor: AppColors.practiceGood,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('피드백 저장 실패'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Inline input for adding key points
class _KeyPointInput extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _KeyPointInput({required this.onAdd});

  @override
  State<_KeyPointInput> createState() => _KeyPointInputState();
}

class _KeyPointInputState extends State<_KeyPointInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: '포인트 추가...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        IconButton(
          onPressed: _submit,
          icon: const Icon(Icons.add_circle),
          color: AppColors.primary,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
