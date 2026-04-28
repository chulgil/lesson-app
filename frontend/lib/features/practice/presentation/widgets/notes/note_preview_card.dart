import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/practice_note_provider.dart';

/// Preview card showing the latest note for a section
class NotePreviewCard extends ConsumerWidget {
  final String sectionId;
  final VoidCallback onTap;

  const NotePreviewCard({
    super.key,
    required this.sectionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sectionNotesProvider(sectionId));

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: notesAsync.when(
          data: (notes) => _buildContent(notes),
          loading: () => _buildLoading(),
          error: (_, __) => _buildEmpty(),
        ),
      ),
    );
  }

  Widget _buildContent(List<PracticeNote> notes) {
    if (notes.isEmpty) {
      return _buildEmpty();
    }

    final latestNote = notes.first;

    return Row(
      children: [
        Icon(Icons.edit_note, color: AppColors.paperAccent, size: 20),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '최근 연습노트',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    latestNote.timeText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // 연습노트 미리보기 = 학생 자필 → Tier 1 Gaegu hand
              // (README §1.1.1, §7.129 사용자 입력 정렬).
              Text(
                latestNote.content,
                style: NotebookTypography.hand.copyWith(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.inkTertiary, size: 20),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: [
        Icon(Icons.edit_note, color: AppColors.inkTertiary, size: 20),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            '연습노트가 없습니다. 터치하여 추가하세요.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.inkTertiary, size: 20),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        Icon(Icons.edit_note, color: AppColors.inkTertiary, size: 20),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(color: AppColors.inkQuaternary),
          ),
        ),
      ],
    );
  }
}
