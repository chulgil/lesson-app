// Student lessons sections widgets

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../lessons/presentation/providers/lesson_crud_provider.dart';
import 'student_lesson_card.dart';

/// Upcoming lessons section for student detail screen
class StudentUpcomingLessonsSection extends ConsumerWidget {
  final String studentId;

  const StudentUpcomingLessonsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('다가오는 레슨', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {
                context.push(
                  AppRoutes.studentNotes.replaceFirst(':id', studentId),
                );
              },
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        lessonsAsync.when(
          data: (lessons) {
            final upcomingLessons = lessons
                .where((l) => l.isUpcoming)
                .take(3)
                .toList();

            if (upcomingLessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.inkTertiary),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      '예정된 레슨이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: upcomingLessons
                  .map((lesson) => StudentLessonCard(lesson: lesson, isUpcoming: true))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: const Text('레슨 정보를 불러올 수 없습니다'),
          ),
        ),
      ],
    );
  }
}

/// Recent lessons section for student detail screen
class StudentRecentLessonsSection extends ConsumerWidget {
  final String studentId;

  const StudentRecentLessonsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 레슨', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {
                context.push(
                  AppRoutes.studentNotes.replaceFirst(':id', studentId),
                );
              },
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        lessonsAsync.when(
          data: (lessons) {
            final recentLessons = lessons
                .where((l) => l.status == LessonStatus.completed)
                .take(3)
                .toList();

            if (recentLessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.inkTertiary),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      '완료된 레슨이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: recentLessons
                  .map((lesson) => StudentLessonCard(lesson: lesson, isUpcoming: false))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: const Text('레슨 기록을 불러올 수 없습니다'),
          ),
        ),
      ],
    );
  }
}
