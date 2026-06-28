import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/repertoire_archive_provider.dart';
import '../widgets/section_management/archive_repertoire_tile.dart';

/// Screen for viewing and managing archived repertoires
class RepertoireArchiveScreen extends ConsumerWidget {
  final String studentId;

  const RepertoireArchiveScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedRepertoiresProvider(studentId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.practiceArchiveTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.space4),
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.ink, size: 20),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '아카이브된 레퍼토리를 복원하거나 영구 삭제할 수 있습니다.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: archivedAsync.when(
              data: (repertoires) {
                if (repertoires.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: AppStrings.repertoireArchiveEmpty,
                  );
                }

                return ListView.builder(
                  itemCount: repertoires.length,
                  itemBuilder: (context, index) {
                    final repertoire = repertoires[index];
                    return ArchiveRepertoireTile(repertoire: repertoire);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.paperAccent,
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          '오류가 발생했습니다',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        TextButton(
                          onPressed:
                              () => ref.invalidate(
                                archivedRepertoiresProvider(studentId),
                              ),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
