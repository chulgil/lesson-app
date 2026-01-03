import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../providers/repertoire_archive_provider.dart';

/// Main practice repertoire screen showing all repertoires and sections
class PracticeRepertoireScreen extends ConsumerWidget {
  final String studentId;

  const PracticeRepertoireScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repertoiresAsync = ref.watch(studentRepertoiresProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('연습'),
        actions: [
          // Archive button
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () =>
                context.push('${AppRoutes.practiceArchive}?studentId=$studentId'),
            tooltip: '아카이브',
          ),
          // Add repertoire button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                context.push('/practice/repertoire/add?studentId=$studentId'),
            tooltip: '레퍼토리 추가',
          ),
        ],
      ),
      body: repertoiresAsync.when(
        data: (repertoires) => repertoires.isEmpty
            ? _buildEmptyState(context)
            : _buildRepertoireList(context, ref, repertoires),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('오류가 발생했습니다', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(studentRepertoiresProvider(studentId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 80,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '아직 연습할 레퍼토리가 없습니다',
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '레퍼토리를 추가하고\n섹션별로 연습을 시작해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => context.push('/practice/repertoire/add?studentId=$studentId'),
              icon: const Icon(Icons.add),
              label: const Text('레퍼토리 추가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepertoireList(
    BuildContext context,
    WidgetRef ref,
    List<PracticeRepertoire> repertoires,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: repertoires.length,
      itemBuilder: (context, index) {
        final repertoire = repertoires[index];
        return _RepertoireCard(
          repertoire: repertoire,
          studentId: studentId,
        );
      },
    );
  }
}

class _RepertoireCard extends ConsumerWidget {
  final PracticeRepertoire repertoire;
  final String studentId;

  const _RepertoireCard({
    required this.repertoire,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMedium),
                topRight: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repertoire.name,
                        style: AppTypography.headingSmall,
                      ),
                      if (repertoire.description != null)
                        Text(
                          repertoire.description!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                // Add section button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  onPressed: () => context.push(
                    '/practice/section/add?repertoireId=${repertoire.id}&studentId=$studentId',
                  ),
                  tooltip: '섹션 추가',
                ),
                // More options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      // TODO: Edit repertoire
                    } else if (value == 'archive') {
                      _showArchiveConfirmation(context, ref);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('아카이브'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sections
          if (repertoire.sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.queue_music,
                      size: 40,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '섹션을 추가해주세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/practice/section/add?repertoireId=${repertoire.id}&studentId=$studentId',
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('섹션 추가'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: repertoire.sections.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final section = repertoire.sections[index];
                return _SectionListItem(
                  section: section,
                  repertoireId: repertoire.id,
                  studentId: studentId,
                );
              },
            ),

          // Footer with stats
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusMedium),
                bottomRight: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '완료: ${repertoire.completedSectionCount}/${repertoire.sections.length}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '총 연습: ${repertoire.formattedTotalTime}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아카이브'),
        content: Text(
            '"${repertoire.name}"을(를) 아카이브로 이동할까요?\n\n아카이브된 레퍼토리는 목록에서 숨겨지며, 나중에 복원할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(repertoireArchiveNotifierProvider.notifier)
                  .archive(repertoire.id, studentId);
              ref.invalidate(studentRepertoiresProvider(studentId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${repertoire.name}" 아카이브됨')),
                );
              }
            },
            child: const Text('아카이브'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레퍼토리 삭제'),
        content: Text('\'${repertoire.name}\'을(를) 삭제하시겠습니까?\n모든 섹션과 녹음이 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(repertoireCrudProvider.notifier).deleteRepertoire(
                    repertoire.id,
                    studentId,
                  );
              ref.invalidate(studentRepertoiresProvider(studentId));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _SectionListItem extends ConsumerWidget {
  final PracticeSection section;
  final String repertoireId;
  final String studentId;

  const _SectionListItem({
    required this.section,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push(
        '/practice/section/${section.id}?repertoireId=$repertoireId&studentId=$studentId',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            // Piece name and measure range
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.pieceName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.measureRangeText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Recording indicator
            if (section.recordings.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.space2),
                child: IconButton(
                  icon: Icon(
                    section.representativeRecording != null
                        ? Icons.play_circle_filled
                        : Icons.play_circle_outline,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    // TODO: Play representative recording
                  },
                  tooltip: '녹음 재생',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.space2),
                child: IconButton(
                  icon: const Icon(
                    Icons.mic_none,
                    color: AppColors.textTertiaryLight,
                  ),
                  onPressed: () {
                    // TODO: Start recording
                  },
                  tooltip: '녹음',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),

            // Completion checkbox
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: section.isCompleted,
                onChanged: (value) async {
                  await ref.read(sectionCrudProvider.notifier).toggleComplete(
                        section.id,
                        repertoireId,
                      );
                  ref.invalidate(studentRepertoiresProvider(studentId));
                },
                activeColor: AppColors.success,
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
