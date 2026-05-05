import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../providers/home_lesson_summary_provider.dart';

/// Getting Started checklist — **Notebook × Score 스타일**.
///
/// 종이 위의 "할 일 목록" 메타포:
/// - 섹션 헤더: uppercase + 1px ink rule
/// - 각 스텝: 로마숫자 인덱스 + Gaegu 손글씨 제목 + 완료 시 취소선
/// - 완료: `paperOk` 녹색 펜 색 체크
/// - 대기: `inkQuaternary` 테두리의 원형 플레이스홀더
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(homeStudentsProvider);
    final hasLessons = ref.watch(homeHasLessonsProvider);
    final hasCompletedLesson = ref.watch(homeHasCompletedLessonProvider);
    final firstLessonId = ref.watch(homeFirstLessonIdProvider);

    return studentsAsync.when(
      data: (students) {
        // Only show when teacher has 0 students
        if (students.isNotEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NotebookSectionHeader(label: 'Getting Started'),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.gettingStartedIntro,
                style: NotebookTypography.hand.copyWith(
                  fontSize: 14,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _StepItem(
                step: 1,
                title: AppStrings.gettingStartedStep1Title,
                subtitle: AppStrings.gettingStartedStep1Subtitle,
                isCompleted: false,
                onTap: () => context.push(AppRoutes.addStudentMethod),
              ),
              const SizedBox(height: AppSpacing.space2),
              _StepItem(
                step: 2,
                title: AppStrings.gettingStartedStep2Title,
                subtitle: AppStrings.gettingStartedStep2Subtitle,
                isCompleted: hasLessons,
                onTap:
                    students.isEmpty
                        ? null
                        : () => context.push(
                          '${AppRoutes.addLesson}?studentId=${students.first.id}',
                        ),
              ),
              const SizedBox(height: AppSpacing.space2),
              _StepItem(
                step: 3,
                title: AppStrings.gettingStartedStep3Title,
                subtitle: AppStrings.gettingStartedStep3Subtitle,
                isCompleted: hasCompletedLesson,
                onTap:
                    hasLessons && firstLessonId != null
                        ? () {
                          context.push(
                            AppRoutes.lessonDetail.replaceFirst(
                              ':id',
                              firstLessonId,
                            ),
                          );
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
    final accentColor =
        isCompleted
            ? AppColors.paperOk
            : isEnabled
            ? AppColors.ink
            : AppColors.inkTertiary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 로마숫자 or 체크 — Notebook × Score 시그니처
            SizedBox(
              width: 28,
              child:
                  isCompleted
                      ? const NotebookGlyph(
                        NotebookGlyph.check,
                        size: 18,
                        color: AppColors.paperOk,
                      )
                      : Text(
                        romanOf(step - 1),
                        style: NotebookTypography.roman.copyWith(
                          color: accentColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NotebookTypography.pieceTitle.copyWith(
                      fontSize: 15,
                      color:
                          isCompleted ? AppColors.inkTertiary : AppColors.ink,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled && !isCompleted)
              const Icon(Icons.chevron_right, color: AppColors.ink, size: 18),
          ],
        ),
      ),
    );
  }
}
