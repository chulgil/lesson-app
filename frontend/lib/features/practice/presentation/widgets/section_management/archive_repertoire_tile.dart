import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../core/widgets/swipe_action_tile.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/repertoire_archive_provider.dart';

/// Tile for displaying archived repertoire with restore/delete options
class ArchiveRepertoireTile extends ConsumerWidget {
  final PracticeRepertoire repertoire;

  const ArchiveRepertoireTile({super.key, required this.repertoire});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Swipe consistency (audit 2026-06-10 §2 — practice v2 D3):
    // - 원칙 1: swipe = destructive 단일 ([영구 삭제])
    // - 원칙 2: 행 탭 = [복원] 단일 액션 (다이얼로그 confirm)
    // - 원칙 3: 영구 삭제는 강화 확인 다이얼로그 (복구 불가 강조)
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionPermanentDelete,
          icon: Icons.delete_forever,
          tone: SwipeActionTone.destructive,
          onPressed: () => _showPermanentDeleteDialog(context, ref),
        ),
      ],
      startActions: [
        SwipeAction(
          label: AppStrings.swipeActionRestore,
          icon: Icons.unarchive_outlined,
          tone: SwipeActionTone.convenience,
          onPressed: () => _showRestoreDialog(context, ref),
        ),
      ],
      child: NotebookCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: InkWell(
          onTap: () => _showRestoreDialog(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.inkSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    // Notebook × Score: 레퍼토리/곡 이름은 Playfair pieceTitle 로 통일 (§7.30 pieceTitle 패턴).
                    Expanded(
                      child: Text(
                        repertoire.name,
                        style: NotebookTypography.pieceTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '아카이브: ${repertoire.archivedAt != null ? formatDateDashPadded(repertoire.archivedAt!) : '-'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                if (repertoire.description != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    repertoire.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.library_music,
                      label: '${repertoire.sections.length}개 섹션',
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: repertoire.formattedTotalTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.practiceRepertoireRestoreTitle),
      content: Text(
        '"${repertoire.name}"을(를) 복원할까요?\n\n복원된 레퍼토리는 활성 목록에 다시 표시됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await ref
                .read(repertoireArchiveNotifierProvider.notifier)
                .restore(repertoire.id, repertoire.studentId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${repertoire.name}" 복원됨')),
              );
            }
          },
          child: const Text(AppStrings.practiceRestore),
        ),
      ],
    );
  }

  void _showPermanentDeleteDialog(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Icons.warning, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          const Text(AppStrings.swipeActionPermanentDeleteConfirmTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${repertoire.name}"을(를) 영구 삭제할까요?'),
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: AppColors.paperAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '${AppStrings.swipeActionPermanentDeleteConfirmBody}\n모든 섹션, 녹음, 연습 기록이 함께 삭제됩니다.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
          onPressed: () async {
            Navigator.of(context).pop();
            await ref
                .read(repertoireArchiveNotifierProvider.notifier)
                .permanentlyDelete(repertoire.id, repertoire.studentId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${repertoire.name}" 영구 삭제됨')),
              );
            }
          },
          child: const Text(AppStrings.practicePermanentDelete),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkSecondary),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
