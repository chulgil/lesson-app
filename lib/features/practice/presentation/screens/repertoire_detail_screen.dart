import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../domain/entities/section_sort_type.dart';
import '../providers/repertoire_archive_provider.dart';
import '../providers/section_sort_provider.dart';
import '../widgets/section_form/date_range_section.dart';
import '../widgets/section_management/section_sort_dropdown.dart';

/// Repertoire detail screen with date settings and aggregated stats
class RepertoireDetailScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;

  const RepertoireDetailScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<RepertoireDetailScreen> createState() =>
      _RepertoireDetailScreenState();
}

class _RepertoireDetailScreenState
    extends ConsumerState<RepertoireDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasChanges = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('레퍼토리 상세'),
        actions: [
          // Recording button
          IconButton(
            onPressed: () => _openRecordingScreen(context),
            icon: const Icon(Icons.mic),
            tooltip: '녹음',
          ),
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('저장'),
            ),
          // More menu with edit and archive options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('편집'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined),
                    SizedBox(width: 8),
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
          // Initialize only once to preserve user edits
          if (!_initialized) {
            _startDate = repertoire.startDate;
            _endDate = repertoire.endDate;
            _initialized = true;
          }
          return _buildContent(repertoire);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
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
          // Repertoire Name
          Text(
            repertoire.name,
            style: AppTypography.headingLarge,
          ),
          if (repertoire.description != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              repertoire.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Date Range Section (공통 위젯 사용)
          DateRangeSection(
            startDate: _startDate,
            endDate: _endDate,
            onStartDateTap: () => _showDatePicker(isStart: true),
            onEndDateTap: () => _showDatePicker(isStart: false),
            onEndDateClear: () {
              setState(() {
                _endDate = null;
                _hasChanges = true;
              });
            },
            endDatePlaceholder: '설정 안함 (계속 진행)',
            showHintMessage: true,
            endDateNullHint: '종료일 미설정 시 매일 반복됩니다',
            endDateSetHint: '종료일까지만 연습 목록에 표시됩니다',
          ),

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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: '총 연습 시간',
                value: _formatDuration(stats.totalPracticeSeconds),
                color: AppColors.info,
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
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.library_music,
                label: '섹션 수',
                value: '${stats.sectionCount}개',
                color: AppColors.secondary,
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
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsSection(PracticeRepertoire repertoire) {
    // Watch sorted sections
    final sortedSections =
        ref.watch(sortedSectionsProvider(widget.repertoireId));

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
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 48,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '섹션이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '연습할 구간을 추가해보세요',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
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
          ref.read(sectionOrderNotifierProvider.notifier).reorderSections(
                widget.repertoireId,
                oldIndex,
                newIndex,
              );
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
        children: sections.map((section) => _SectionListTile(
              section: section,
              repertoireId: widget.repertoireId,
              studentId: widget.studentId,
            )).toList(),
      );
    }
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365 * 2));

    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto-adjust end date if needed
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
        _hasChanges = true;
      });
    }
  }

  void _openRecordingScreen(BuildContext context) {
    final repertoire =
        ref.read(repertoireProvider(widget.repertoireId)).valueOrNull;
    final repertoireName = repertoire?.name ?? '';
    context.push(
      '${AppRoutes.practiceRecording.replaceFirst(':repertoireId', widget.repertoireId)}'
      '?studentId=${widget.studentId}&name=${Uri.encodeComponent(repertoireName)}',
    );
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
    final editPath = AppRoutes.editRepertoire.replaceFirst(':id', widget.repertoireId);
    context.push('$editPath?studentId=${widget.studentId}').then((result) {
      if (result == true) {
        // Refresh the data after edit
        ref.invalidate(repertoireProvider(widget.repertoireId));
        setState(() {
          _initialized = false; // Reset to reload dates from updated repertoire
        });
      }
    });
  }

  void _showArchiveDialog() {
    final repertoire =
        ref.read(repertoireProvider(widget.repertoireId)).valueOrNull;
    if (repertoire == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아카이브'),
        content: Text(
            '"${repertoire.name}"을(를) 아카이브로 이동할까요?\n\n아카이브된 레퍼토리는 목록에서 숨겨지며, 아카이브 화면에서 복원할 수 있습니다.'),
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

  Future<void> _saveChanges() async {
    final repertoire =
        ref.read(repertoireProvider(widget.repertoireId)).valueOrNull;
    if (repertoire == null) return;

    final updatedRepertoire = PracticeRepertoire(
      id: repertoire.id,
      studentId: repertoire.studentId,
      name: repertoire.name,
      description: repertoire.description,
      startDate: _startDate ?? DateTime.now(),
      endDate: _endDate,
      createdAt: repertoire.createdAt,
      sections: repertoire.sections,
    );

    await ref
        .read(repertoireCrudProvider.notifier)
        .updateRepertoire(updatedRepertoire);

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
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
                      section.measureRangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
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
                color: AppColors.textTertiaryLight,
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
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondaryLight),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
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
                color: AppColors.textTertiaryLight,
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
                            section.measureRangeText,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
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
                      color: AppColors.textTertiaryLight,
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
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondaryLight),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
