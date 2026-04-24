import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../lessons/presentation/providers/lesson_note_providers.dart';

/// Lesson notes preview section for student detail screen.
class StudentNotesSection extends ConsumerWidget {
  final String studentId;

  const StudentNotesSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(studentLessonNotesProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
            Text('레슨 노트', style: NotebookTypography.sectionTitle),
            notesAsync.whenOrNull(
                  data:
                      (notes) =>
                          notes.length > 3
                              ? TextButton(
                                onPressed:
                                    () => context.push(
                                      AppRoutes.studentNotes.replaceFirst(
                                        ':id',
                                        studentId,
                                      ),
                                    ),
                                child: const Text('전체 보기'),
                              )
                              : null,
                ) ??
                const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children:
                  notes
                      .take(3)
                      .map(
                        (lesson) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.space3,
                          ),
                          child: _NotePreviewCard(lesson: lesson),
                        ),
                      )
                      .toList(),
            );
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
              ),
          error: (_, __) => _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          Icon(Icons.notes, color: AppColors.inkTertiary),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '레슨 노트가 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single note preview card.
class _NotePreviewCard extends StatelessWidget {
  final Lesson lesson;

  const _NotePreviewCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[lesson.date.weekday];
    final dateStr =
        '${lesson.date.month}.${lesson.date.day.toString().padLeft(2, '0')} ($dayName)';

    return InkWell(
      onTap:
          () => context.push(
            AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
          ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Text(
              dateStr,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),

            // Feedback text — Notebook × Score: 선생님 손글씨 주석으로 Gaegu 렌더.
            if (lesson.feedback != null)
              Text(
                lesson.feedback!,
                style: NotebookTypography.hand.copyWith(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.paperPencil,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            // Key points as chips
            if (lesson.keyPoints?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    lesson.keyPoints!
                        .take(3)
                        .map(
                          (kp) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paperAccent.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            child: Text(
                              kp,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperAccent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
