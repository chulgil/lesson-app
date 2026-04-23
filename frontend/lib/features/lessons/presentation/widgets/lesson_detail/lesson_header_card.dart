// Lesson header card widget

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';

/// Lesson header with student/teacher info and status
class LessonHeaderCard extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;

  const LessonHeaderCard({
    super.key,
    required this.lesson,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student/Teacher info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  isTeacher
                      ? (lesson.studentName.isNotEmpty
                          ? lesson.studentName[0]
                          : '?')
                      : (lesson.teacherName?.isNotEmpty == true
                          ? lesson.teacherName![0]
                          : '?'),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Notebook × Score: 학생/선생님 이름은 상세 카드의 주인공 —
                        // Playfair sectionTitle 로 승격 (§7.17 헤더 일관성).
                        Text(
                          isTeacher
                              ? lesson.studentName
                              : (lesson.teacherName ?? '선생님'),
                          style: NotebookTypography.sectionTitle,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccentSoft.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSmall,
                            ),
                          ),
                          child: Text(
                            lesson.instrument,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Status badge
                        _StatusBadge(status: lesson.displayStatus),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${lesson.date.month}월 ${lesson.date.day}일 ${lesson.startTime} · ${lesson.duration}분',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Pieces
          if (lesson.pieces.isNotEmpty)
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children:
                  lesson.pieces.map((piece) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperDark,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                      child: Text(
                        piece.displayName,
                        style: AppTypography.bodySmall,
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final LessonStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        color = AppColors.paperAccent;
      case LessonStatus.completed:
        color = AppColors.paperOk;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        color = AppColors.inkTertiary;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        color = AppColors.paperAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
