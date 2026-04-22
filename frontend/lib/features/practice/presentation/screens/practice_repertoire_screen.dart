import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../providers/repertoire_archive_provider.dart';

/// Main practice repertoire screen showing all repertoires and sections
class PracticeRepertoireScreen extends ConsumerWidget {
  final String studentId;

  const PracticeRepertoireScreen({super.key, required this.studentId});

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
            onPressed:
                () => context.push(
                  '${AppRoutes.practiceArchive}?studentId=$studentId',
                ),
            tooltip: '아카이브',
          ),
          // Add repertoire button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => context.push(
                  '${AppRoutes.addRepertoire}?studentId=$studentId',
                ),
            tooltip: '레퍼토리 추가',
          ),
        ],
      ),
      body: repertoiresAsync.when(
        data:
            (repertoires) =>
                repertoires.isEmpty
                    ? _buildEmptyState(context)
                    : _buildRepertoireList(context, ref, repertoires),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text('오류가 발생했습니다', style: AppTypography.bodyLarge),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          studentRepertoiresProvider(studentId),
                        ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.library_music_outlined,
      title: '아직 연습할 레퍼토리가 없습니다',
      subtitle: '레퍼토리를 추가하고\n섹션별로 연습을 시작해보세요',
      actionLabel: '레퍼토리 추가',
      actionIcon: Icons.add,
      onAction:
          () => context.push('${AppRoutes.addRepertoire}?studentId=$studentId'),
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
        return _RepertoireCard(repertoire: repertoire, studentId: studentId);
      },
    );
  }
}

class _RepertoireCard extends ConsumerWidget {
  final PracticeRepertoire repertoire;
  final String studentId;

  const _RepertoireCard({required this.repertoire, required this.studentId});

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
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMedium),
                topRight: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: AppColors.paperAccent),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repertoire.name, style: AppTypography.headingSmall),
                      if (repertoire.description != null)
                        Text(
                          repertoire.description!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Add section button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.paperAccent,
                  onPressed:
                      () => context.push(
                        '${AppRoutes.addSection}?repertoireId=${repertoire.id}&studentId=$studentId',
                      ),
                  tooltip: '섹션 추가',
                ),
                // More options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push(
                        '${AppRoutes.editRepertoire.replaceFirst(':id', repertoire.id)}'
                        '?studentId=$studentId',
                      );
                    } else if (value == 'archive') {
                      _showArchiveConfirmation(context, ref);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: AppSpacing.space2),
                              Text(AppStrings.modify),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 20),
                              SizedBox(width: AppSpacing.space2),
                              Text('아카이브'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 20,
                                color: AppColors.paperAccent,
                              ),
                              SizedBox(width: AppSpacing.space2),
                              Text(
                                '삭제',
                                style: TextStyle(color: AppColors.paperAccent),
                              ),
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
                      color: AppColors.inkTertiary,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '섹션을 추가해주세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TextButton.icon(
                      onPressed:
                          () => context.push(
                            '${AppRoutes.addSection}?repertoireId=${repertoire.id}&studentId=$studentId',
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
              color: AppColors.paperDark,
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
                    color: AppColors.inkSecondary,
                  ),
                ),
                Text(
                  '총 연습: ${repertoire.formattedTotalTime}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
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
      builder:
          (context) => AlertDialog(
            title: const Text('아카이브'),
            content: Text(
              '"${repertoire.name}"을(를) 아카이브로 이동할까요?\n\n아카이브된 레퍼토리는 목록에서 숨겨지며, 나중에 복원할 수 있습니다.',
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
      builder:
          (context) => AlertDialog(
            title: const Text('레퍼토리 삭제'),
            content: Text(
              '\'${repertoire.name}\'을(를) 삭제하시겠습니까?\n모든 섹션과 녹음이 함께 삭제됩니다.',
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
                      .read(repertoireCrudProvider.notifier)
                      .deleteRepertoire(repertoire.id, studentId);
                  ref.invalidate(studentRepertoiresProvider(studentId));
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
                child: const Text(AppStrings.delete),
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
    final today = DateTime.now();
    final completedCount = section.getRepeatCompletedCount(today);
    final hasRepeatCount = section.hasRepeatCount;

    return InkWell(
      onTap:
          () => context.push(
            '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}?repertoireId=$repertoireId&studentId=$studentId',
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            // Piece name and range (line or measure)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          section.pieceName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Repeat indicator
                      if (section.isRepeat) ...[
                        const SizedBox(width: AppSpacing.space1),
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: AppColors.inkSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.rangeText, // Uses rangeType to show line or measure
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
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
                    color: AppColors.paperAccent,
                  ),
                  onPressed: () {
                    context.push(
                      '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}?repertoireId=$repertoireId&studentId=$studentId',
                    );
                  },
                  tooltip: '녹음 재생',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.space2),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.space2),
                child: IconButton(
                  icon: const Icon(
                    Icons.mic_none,
                    color: AppColors.inkTertiary,
                  ),
                  onPressed: () {
                    context.push(
                      '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}?repertoireId=$repertoireId&studentId=$studentId',
                    );
                  },
                  tooltip: '녹음',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.space2),
                ),
              ),

            // Completion indicator: 🐾 paw stamps for N회 반복, checkbox otherwise
            if (hasRepeatCount)
              _PawStampRow(
                totalCount: section.repeatCount!,
                completedCount: completedCount,
                onTap: () async {
                  await ref
                      .read(sectionCrudProvider.notifier)
                      .toggleDailyCompletion(
                        section.id,
                        repertoireId,
                        studentId,
                        today,
                      );
                  ref.invalidate(studentRepertoiresProvider(studentId));
                },
              )
            else
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: section.isCompletedForDate(today),
                  onChanged: (value) async {
                    await ref
                        .read(sectionCrudProvider.notifier)
                        .toggleComplete(
                          section.id,
                          repertoireId,
                          studentId: studentId,
                          date: today,
                        );
                    ref.invalidate(studentRepertoiresProvider(studentId));
                  },
                  activeColor: AppColors.paperOk,
                ),
              ),

            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

/// 🐾 Paw stamp row for N회 반복 feature
class _PawStampRow extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final VoidCallback onTap;

  const _PawStampRow({
    required this.totalCount,
    required this.completedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalCount, (index) {
          final isCompleted = index < completedCount;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Opacity(
              opacity: isCompleted ? 1.0 : 0.3,
              child: Text(
                '🐾',
                style: TextStyle(fontSize: totalCount <= 5 ? 16 : 12),
              ),
            ),
          );
        }),
      ),
    );
  }
}
