import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../lessons/domain/entities/lesson.dart';
import '../../providers/student_home_teacher_feedback_provider.dart';

/// Section showing the most recent teacher feedback.
class TeacherFeedbackSection extends ConsumerWidget {
  final String studentId;

  const TeacherFeedbackSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(
      studentHomeLatestTeacherFeedbackProvider(studentId),
    );

    // C7 — secondary 섹션: 피드백 없음/로딩/에러 시 헤더 포함 전체 숨김 (가시성 일치).
    return feedbackAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (feedbackLesson) {
        if (feedbackLesson == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Notebook × Score: 섹션 헤더는 Playfair sectionTitle (§7.87-f).
                Text(
                  AppStrings.studentHomeRecentFeedback,
                  style: NotebookTypography.sectionTitle,
                ),
                TextButton(
                  onPressed: () => context.push(
                    AppRoutes.lessonDetail
                        .replaceFirst(':id', feedbackLesson.id),
                  ),
                  child: const Text(AppStrings.showMore),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildTeacherFeedback(feedbackLesson),
          ],
        );
      },
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.paperDark,
                child: Text(
                  teacherInitial,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink,
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
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          // Notebook × Score: 선생님 피드백은 손글씨 주석처럼 Gaegu로 렌더.
          Text(
            lesson.feedback ?? '',
            style: NotebookTypography.hand.copyWith(
              color: AppColors.paperPencil,
            ),
          ),
        ],
      ),
    );
  }
}
