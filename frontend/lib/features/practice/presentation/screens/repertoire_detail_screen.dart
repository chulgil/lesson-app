import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../domain/entities/section_sort_type.dart';
import '../providers/repertoire_archive_provider.dart';
import '../providers/section_sort_provider.dart';
import '../widgets/section_management/section_sort_dropdown.dart';

/// Repertoire detail screen with date settings and aggregated stats
class RepertoireDetailScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;
  final DateTime? selectedDate;

  const RepertoireDetailScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
    this.selectedDate,
  });

  @override
  ConsumerState<RepertoireDetailScreen> createState() =>
      _RepertoireDetailScreenState();
}

class _RepertoireDetailScreenState
    extends ConsumerState<RepertoireDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedDate != null
              ? '레퍼토리 · ${_formatDateForTitle(widget.selectedDate!)}'
              : '레퍼토리',
        ),
        actions: [
          // More menu with edit and archive options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: AppSpacing.space2),
                        Text('편집'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined),
                        SizedBox(width: AppSpacing.space2),
                        Text('아카이브로 이동'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: repertoireAsync.when(
        data: (repertoire) {
          if (repertoire == null) {
            return const Center(child: Text('레퍼토리를 찾을 수 없습니다'));
          }
          return _buildContent(repertoire);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
      ),
    );
  }

  Widget _buildContent(PracticeRepertoire repertoire) {
    // Calculate aggregated stats
    final stats = _calculateStats(repertoire);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repertoire header (same as list item)
          Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.paperAccent, size: 28),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repertoire.name, style: AppTypography.headingLarge),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      repertoire.dateRangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (repertoire.description != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              repertoire.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Stats Cards
          _buildStatsSection(stats),

          const SizedBox(height: AppSpacing.space6),

          // Sections List
          _buildSectionsSection(repertoire),
        ],
      ),
    );
  }

  Widget _buildStatsSection(_RepertoireStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('연습 통계', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.repeat,
                label: '총 연습 횟수',
                value: '${stats.totalPracticeCount}회',
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: '총 연습 시간',
                value: _formatDuration(stats.totalPracticeSeconds),
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.mic,
                label: '총 녹음',
                value: '${stats.totalRecordings}개',
                color: AppColors.paperOk,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.library_music,
                label: '섹션 수',
                value: '${stats.sectionCount}개',
                color: AppColors.paperAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.space1),
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

  Widget _buildSectionsSection(PracticeRepertoire repertoire) {
    // Watch sorted sections
    final sortedSections = ref.watch(
      sortedSectionsProvider(widget.repertoireId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('섹션 목록', style: AppTypography.headingSmall),
            TextButton.icon(
              onPressed: () {
                context.push(
                  '${AppRoutes.addSection}?repertoireId=${widget.repertoireId}&studentId=${widget.studentId}',
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        // Sort dropdown
        SectionSortDropdown(repertoireId: widget.repertoireId),
        const SizedBox(height: AppSpacing.space3),
        if (sortedSections.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 48,
                    color: AppColors.inkTertiary,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '섹션이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '연습할 구간을 추가해보세요',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildSectionList(sortedSections),
      ],
    );
  }

  Widget _buildSectionList(List<PracticeSection> sections) {
    final sortType = ref.watch(sectionSortTypeProvider);
    final isCustomSort = sortType == SectionSortType.custom;

    if (isCustomSort) {
      // Reorderable list for custom sort
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        buildDefaultDragHandles: false, // We'll add our own drag handle
        onReorder: (oldIndex, newIndex) {
          // Adjust newIndex for the remove-before-insert behavior
          if (newIndex > oldIndex) newIndex--;
          ref
              .read(sectionOrderNotifierProvider.notifier)
              .reorderSections(widget.repertoireId, oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final section = sections[index];
          return _ReorderableSectionTile(
            key: ValueKey(section.id),
            index: index,
            section: section,
            repertoireId: widget.repertoireId,
            studentId: widget.studentId,
          );
        },
      );
    } else {
      // Normal list for other sort types
      return Column(
        children:
            sections
                .map(
                  (section) => _SectionListTile(
                    section: section,
                    repertoireId: widget.repertoireId,
                    studentId: widget.studentId,
                  ),
                )
                .toList(),
      );
    }
  }

  String _formatDateForTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final difference = today.difference(selected).inDays;

    final dateStr = '${date.month}월 ${date.day}일';

    if (difference == 0) {
      return '$dateStr (오늘)';
    } else if (difference == 1) {
      return '$dateStr (어제)';
    } else if (difference == -1) {
      return '$dateStr (내일)';
    }
    return dateStr;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _openEditScreen();
        break;
      case 'archive':
        _showArchiveDialog();
        break;
    }
  }

  void _openEditScreen() {
    final editPath = AppRoutes.editRepertoire.replaceFirst(
      ':id',
      widget.repertoireId,
    );
    context.push('$editPath?studentId=${widget.studentId}').then((result) {
      if (result == true) {
        // Refresh the data after edit
        ref.invalidate(repertoireProvider(widget.repertoireId));
      }
    });
  }

  void _showArchiveDialog() {
    final repertoire =
        ref.read(repertoireProvider(widget.repertoireId)).valueOrNull;
    if (repertoire == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('아카이브'),
            content: Text(
              '"${repertoire.name}"을(를) 아카이브로 이동할까요?\n\n아카이브된 레퍼토리는 목록에서 숨겨지며, 아카이브 화면에서 복원할 수 있습니다.',
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
                      .archive(widget.repertoireId, widget.studentId);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${repertoire.name}" 아카이브됨')),
                  );
                  context.pop(); // Go back to repertoire list
                },
                child: const Text('아카이브'),
              ),
            ],
          ),
    );
  }

  _RepertoireStats _calculateStats(PracticeRepertoire repertoire) {
    int totalPracticeCount = 0;
    int totalPracticeSeconds = 0;
    int totalRecordings = 0;

    for (final section in repertoire.sections) {
      totalPracticeCount += section.practiceCount;
      totalPracticeSeconds += section.totalPracticeSeconds;
      totalRecordings += section.recordings.length;
    }

    return _RepertoireStats(
      totalPracticeCount: totalPracticeCount,
      totalPracticeSeconds: totalPracticeSeconds,
      totalRecordings: totalRecordings,
      sectionCount: repertoire.sections.length,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes분';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
  }
}

class _RepertoireStats {
  final int totalPracticeCount;
  final int totalPracticeSeconds;
  final int totalRecordings;
  final int sectionCount;

  _RepertoireStats({
    required this.totalPracticeCount,
    required this.totalPracticeSeconds,
    required this.totalRecordings,
    required this.sectionCount,
  });
}

/// Section list tile for repertoire detail
class _SectionListTile extends StatelessWidget {
  final PracticeSection section;
  final String repertoireId;
  final String studentId;

  const _SectionListTile({
    required this.section,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}'
            '?repertoireId=$repertoireId&studentId=$studentId',
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              // Section info
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
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      section.rangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Practice count
                  _buildMiniStat(
                    icon: Icons.repeat,
                    value: '${section.practiceCount}',
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  // Recordings
                  _buildMiniStat(
                    icon: Icons.mic,
                    value: '${section.recordings.length}',
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right,
                color: AppColors.inkTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkSecondary),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reorderable section tile with drag handle
class _ReorderableSectionTile extends StatelessWidget {
  final int index;
  final PracticeSection section;
  final String repertoireId;
  final String studentId;

  const _ReorderableSectionTile({
    super.key,
    required this.index,
    required this.section,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space3,
              ),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.inkTertiary,
              ),
            ),
          ),

          // Section content
          Expanded(
            child: InkWell(
              onTap: () {
                context.push(
                  '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}'
                  '?repertoireId=$repertoireId&studentId=$studentId',
                );
              },
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppSpacing.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.space3,
                  right: AppSpacing.space3,
                  bottom: AppSpacing.space3,
                ),
                child: Row(
                  children: [
                    // Section info
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
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            section.rangeText,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniStat(
                          icon: Icons.repeat,
                          value: '${section.practiceCount}',
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _buildMiniStat(
                          icon: Icons.mic,
                          value: '${section.recordings.length}',
                        ),
                      ],
                    ),

                    const SizedBox(width: AppSpacing.space2),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.inkTertiary,
                      size: 20,
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

  Widget _buildMiniStat({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkSecondary),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
