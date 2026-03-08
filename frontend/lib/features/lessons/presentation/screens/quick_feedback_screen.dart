import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/providers.dart';

/// Quick feedback writing screen for a specific lesson
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
  Timer? _debounce;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _feedbackController.dispose();
    super.dispose();
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

        // Initialize controller text on first build
        if (!_hasChanges && _feedbackController.text.isEmpty) {
          _feedbackController.text = lesson.feedback ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${lesson.studentName} 피드백'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson info header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondaryLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note,
                          color: AppColors.primary, size: 20),
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
                ),

                const SizedBox(height: AppSpacing.space6),

                // Feedback text field
                Text(
                  '피드백',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 8,
                    onChanged: (_) => setState(() => _hasChanges = true),
                    decoration: InputDecoration(
                      hintText: '피드백을 작성하세요...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.all(AppSpacing.space4),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _hasChanges ? () => _saveFeedback() : null,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppSpacing.space3),
                      child: Text('저장하기'),
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

  Future<void> _saveFeedback() async {
    final lessonAsync = ref.read(lessonProvider(widget.lessonId));
    final lesson = lessonAsync.valueOrNull;
    if (lesson == null) return;

    final text = _feedbackController.text.trim();
    final updatedLesson = lesson.copyWith(
      feedback: text.isEmpty ? null : text,
    );

    await ref
        .read(lessonsNotifierProvider.notifier)
        .updateLesson(updatedLesson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드백이 저장되었습니다')),
      );
      context.pop();
    }
  }
}
