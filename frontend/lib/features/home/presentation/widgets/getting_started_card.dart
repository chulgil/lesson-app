import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/lesson.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/providers.dart';
import '../../../../providers/student/student_crud_provider.dart';

/// Getting Started checklist card for new teachers with 0 students.
/// Shows actionable steps to help them get started.
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    return studentsAsync.when(
      data: (students) {
        // Only show when teacher has 0 students
        if (students.isNotEmpty) return const SizedBox.shrink();

        final hasLessons =
            lessonsAsync.valueOrNull?.isNotEmpty ?? false;
        final hasCompletedLesson = lessonsAsync.valueOrNull?.any(
              (l) => l.status == LessonStatus.completed,
            ) ??
            false;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '시작 가이드',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '아래 단계를 따라 레슨 관리를 시작하세요',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Step 1: Add student
              _StepItem(
                step: 1,
                title: '학생 등록하기',
                subtitle: '첫 학생을 추가해보세요',
                isCompleted: false,
                onTap: () => context.push(AppRoutes.addStudent),
              ),

              const SizedBox(height: AppSpacing.space2),

              // Step 2: Create lesson
              _StepItem(
                step: 2,
                title: '레슨 일정 만들기',
                subtitle: '학생 등록 후 레슨을 추가하세요',
                isCompleted: hasLessons,
                onTap: students.isEmpty
                    ? null
                    : () => context.push('${AppRoutes.addLesson}?studentId=${students.first.id}'),
              ),

              const SizedBox(height: AppSpacing.space2),

              // Step 3: Complete first lesson
              _StepItem(
                step: 3,
                title: '첫 레슨 완료하기',
                subtitle: '레슨을 탭해 완료 처리하세요',
                isCompleted: hasCompletedLesson,
                onTap: hasLessons
                    ? () {
                        final firstLesson = lessonsAsync.valueOrNull!.first;
                        context.push(AppRoutes.lessonDetail.replaceFirst(':id', firstLesson.id));
                      }
                    : null,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Step number or check
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isEnabled
                        ? AppColors.primary
                        : AppColors.textTertiaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? AppColors.textTertiaryLight
                          : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled && !isCompleted)
              Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
