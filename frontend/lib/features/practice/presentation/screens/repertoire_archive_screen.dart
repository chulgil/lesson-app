import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('아카이브')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.space4),
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.inkSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          '아카이브된 레퍼토리가 없습니다',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
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
