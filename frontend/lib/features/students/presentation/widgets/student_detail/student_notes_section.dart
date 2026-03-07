import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/lesson.dart';
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
            Text('레슨 노트', style: AppTypography.headingSmall),
            notesAsync.whenOrNull(
                  data: (notes) => notes.length > 3
                      ? TextButton(
                          onPressed: () =>
                              context.push('/students/$studentId/notes'),
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
              children: notes
                  .take(3)
                  .map((lesson) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.space3),
                        child: _NotePreviewCard(lesson: lesson),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(
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
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.notes, color: AppColors.textTertiaryLight),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '레슨 노트가 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
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
      onTap: () => context.push('/lessons/${lesson.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Text(
              dateStr,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),

            // Feedback text
            if (lesson.feedback != null)
              Text(
                lesson.feedback!,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            // Key points as chips
            if (lesson.keyPoints?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: lesson.keyPoints!
                    .take(3)
                    .map((kp) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            kp,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
