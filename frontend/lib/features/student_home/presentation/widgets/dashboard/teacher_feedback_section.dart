import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../lessons/domain/entities/lesson.dart';
import '../../../../lessons/presentation/providers/lesson_crud_provider.dart';

/// Section showing the most recent teacher feedback.
class TeacherFeedbackSection extends ConsumerWidget {
  final String studentId;

  const TeacherFeedbackSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 피드백', style: AppTypography.headingMedium),
            TextButton(
              onPressed: () {
                context.push(
                    '${AppRoutes.repertoireHistory}?studentId=$studentId');
              },
              child: const Text('더보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        lessonsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (lessons) {
            final feedbackLessons = lessons
                .where((l) =>
                    l.status == LessonStatus.completed && l.hasFeedback)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (feedbackLessons.isEmpty) {
              return _buildEmptyState();
            }

            return _buildTeacherFeedback(feedbackLessons.first);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          '아직 피드백이 없습니다',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherFeedback(Lesson lesson) {
    final teacherName = lesson.teacherName ?? '선생님';
    final teacherInitial = teacherName.isNotEmpty ? teacherName[0] : '?';
    final dateStr =
        '${lesson.date.year}.${lesson.date.month.toString().padLeft(2, '0')}.${lesson.date.day.toString().padLeft(2, '0')}';

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
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  teacherInitial,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                teacherName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            lesson.feedback ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
