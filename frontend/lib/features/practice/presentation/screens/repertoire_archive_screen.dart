import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/repertoire_archive_provider.dart';
import '../widgets/section_management/archive_repertoire_tile.dart';

/// Screen for viewing and managing archived repertoires
class RepertoireArchiveScreen extends ConsumerWidget {
  final String studentId;

  const RepertoireArchiveScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedRepertoiresProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('아카이브'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '아카이브된 레퍼토리를 복원하거나 영구 삭제할 수 있습니다.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
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
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아카이브된 레퍼토리가 없습니다',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondaryLight,
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
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '오류가 발생했습니다',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(archivedRepertoiresProvider(studentId)),
                      child: const Text('다시 시도'),
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
