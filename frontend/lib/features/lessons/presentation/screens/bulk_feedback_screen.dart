import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../providers/lesson_crud_provider.dart';
import '../../domain/entities/feedback_preset.dart';
import '../providers/feedback_preset_providers.dart';

/// Bulk feedback screen — send common feedback to multiple students at once.
///
/// 3-Step wizard:
/// 1. Select students (today's completed lessons auto-checked)
/// 2. Write common feedback + optional per-student comments
/// 3. Preview & send
class BulkFeedbackScreen extends ConsumerStatefulWidget {
  const BulkFeedbackScreen({super.key});

  @override
  ConsumerState<BulkFeedbackScreen> createState() => _BulkFeedbackScreenState();
}

class _BulkFeedbackScreenState extends ConsumerState<BulkFeedbackScreen> {
  int _currentStep = 0;
  final Set<String> _selectedLessonIds = {};
  final _feedbackController = TextEditingController();
  final Map<String, TextEditingController> _perStudentControllers = {};
  bool _isSending = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    for (final c in _perStudentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        centerTitle: true,
        leading: IconButton(
          onPressed:
              _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : () => context.pop(),
          icon: Icon(_currentStep > 0 ? Icons.arrow_back : Icons.close),
        ),
      ),
      body: lessonsAsync.when(
        data: (lessons) => _buildStep(lessons),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return '학생 선택';
      case 1:
        return '피드백 작성';
      case 2:
        return '미리보기';
      default:
        return '일괄 피드백';
    }
  }

  Widget _buildStep(List<Lesson> allLessons) {
    // Get today's lessons
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayLessons =
        allLessons.where((l) {
            final lessonDate = DateTime(l.date.year, l.date.month, l.date.day);
            return lessonDate == today;
          }).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    switch (_currentStep) {
      case 0:
        return _buildStudentSelection(todayLessons);
      case 1:
        return _buildFeedbackInput(allLessons);
      case 2:
        return _buildPreview(allLessons);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Student selection
  Widget _buildStudentSelection(List<Lesson> todayLessons) {
    // Auto-select completed lessons on first visit
    if (_selectedLessonIds.isEmpty && _currentStep == 0) {
      for (final l in todayLessons) {
        if (l.displayStatus == LessonStatus.completed) {
          _selectedLessonIds.add(l.id);
        }
      }
    }

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(AppSpacing.screenPadding),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '완료된 레슨 학생이 자동 선택됩니다. 변경하려면 탭하세요.',
                  style: AppTypography.caption.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),

        // Lesson list
        Expanded(
          child:
              todayLessons.isEmpty
                  ? Center(
                    child: Text(
                      '오늘 레슨이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: todayLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = todayLessons[index];
                      final isSelected = _selectedLessonIds.contains(lesson.id);
                      final isCompleted =
                          lesson.displayStatus == LessonStatus.completed;
                      final hasFeedback =
                          lesson.feedback != null &&
                          lesson.feedback!.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space2,
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedLessonIds.add(lesson.id);
                              } else {
                                _selectedLessonIds.remove(lesson.id);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLarge,
                            ),
                            side: BorderSide(color: AppColors.borderLight),
                          ),
                          tileColor: AppColors.surfaceLight,
                          title: Text(
                            '${NameUtils.givenName(lesson.studentName)} · ${lesson.instrument}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${lesson.startTime} (${isCompleted ? "완료" : "예정"})'
                            '${hasFeedback ? " · 피드백 있음" : ""}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          secondary: Icon(
                            isCompleted ? Icons.check_circle : Icons.schedule,
                            color:
                                isCompleted
                                    ? AppColors.practiceGood
                                    : AppColors.textTertiaryLight,
                          ),
                        ),
                      );
                    },
                  ),
        ),

        // Next button
        _buildBottomButton(
          label: '다음 (${_selectedLessonIds.length}명)',
          enabled: _selectedLessonIds.isNotEmpty,
          onPressed: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  // Step 2: Feedback input
  Widget _buildFeedbackInput(List<Lesson> allLessons) {
    final selectedLessons =
        allLessons.where((l) => _selectedLessonIds.contains(l.id)).toList();
    final presetsAsync = ref.watch(feedbackPresetNotifierProvider());

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Common feedback
                Text(
                  '공통 피드백',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),

                // Preset chips
                presetsAsync.when(
                  data: (presets) => _buildInlinePresets(presets),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.space2),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '모든 선택 학생에게 전달할 피드백을 작성하세요...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppSpacing.space4),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Per-student comments (optional)
                Text(
                  '개별 코멘트 (선택)',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '각 학생에게 추가할 개별 메시지',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),

                ...selectedLessons.map((lesson) {
                  _perStudentControllers.putIfAbsent(
                    lesson.id,
                    () => TextEditingController(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: _perStudentControllers[lesson.id],
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: NameUtils.givenName(lesson.studentName),
                          hintText: '추가 코멘트...',
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(
                            AppSpacing.space3,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        _buildBottomButton(
          label: '미리보기',
          enabled: _feedbackController.text.trim().isNotEmpty,
          onPressed: () => setState(() => _currentStep = 2),
        ),
      ],
    );
  }

  Widget _buildInlinePresets(List<FeedbackPreset> presets) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final preset = presets[index];
          return ActionChip(
            label: Text(
              preset.text,
              style: AppTypography.caption.copyWith(color: AppColors.primary),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () {
              final current = _feedbackController.text;
              final separator =
                  current.isNotEmpty && !current.endsWith('\n') ? '\n' : '';
              _feedbackController.text = '$current$separator${preset.text}';
              setState(() {});
            },
          );
        },
      ),
    );
  }

  // Step 3: Preview
  Widget _buildPreview(List<Lesson> allLessons) {
    final selectedLessons =
        allLessons.where((l) => _selectedLessonIds.contains(l.id)).toList();
    final commonFeedback = _feedbackController.text.trim();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: selectedLessons.length,
            itemBuilder: (context, index) {
              final lesson = selectedLessons[index];
              final perStudent =
                  _perStudentControllers[lesson.id]?.text.trim() ?? '';
              final fullFeedback =
                  perStudent.isNotEmpty
                      ? '$commonFeedback\n\n$perStudent'
                      : commonFeedback;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              lesson.studentName[0],
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            '${NameUtils.givenName(lesson.studentName)} · ${lesson.instrument}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Text(fullFeedback, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        _buildBottomButton(
          label: _isSending ? '전송 중...' : '${selectedLessons.length}명에게 전송',
          enabled: !_isSending,
          onPressed: () => _sendBulkFeedback(selectedLessons),
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Future<void> _sendBulkFeedback(List<Lesson> selectedLessons) async {
    setState(() => _isSending = true);
    final commonFeedback = _feedbackController.text.trim();

    try {
      final notifier = ref.read(lessonsNotifierProvider.notifier);

      for (final lesson in selectedLessons) {
        final perStudent = _perStudentControllers[lesson.id]?.text.trim() ?? '';
        final fullFeedback =
            perStudent.isNotEmpty
                ? '$commonFeedback\n\n$perStudent'
                : commonFeedback;

        final updated = lesson.copyWith(feedback: fullFeedback);
        await notifier.updateLesson(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedLessons.length}명에게 피드백을 전송했습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('전송 실패. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
