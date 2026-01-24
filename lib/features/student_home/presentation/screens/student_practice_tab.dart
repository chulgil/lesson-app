import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/domain/entities/repertoire_sort_type.dart';
import '../../../practice/presentation/providers/repertoire_sort_provider.dart';
import '../widgets/week_calendar_widget.dart';

/// Student practice tab with calendar-based repertoire management
class StudentPracticeTab extends ConsumerStatefulWidget {
  const StudentPracticeTab({super.key});

  @override
  ConsumerState<StudentPracticeTab> createState() => _StudentPracticeTabState();
}

class _StudentPracticeTabState extends ConsumerState<StudentPracticeTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentId = ref.watch(currentUserIdProvider);
    final params = RepertoiresForDateParams(
      studentId: studentId,
      date: _selectedDate,
    );
    final repertoiresAsync = ref.watch(repertoiresForDateProvider(params));

    // Get all repertoires to find practiced dates
    final allRepertoiresAsync =
        ref.watch(studentRepertoiresProvider(studentId));
    final practicedDates = allRepertoiresAsync.whenOrNull(
      data: (repertoires) => _getPracticedDates(repertoires),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Calendar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: WeekCalendarWidget(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                practicedDates: practicedDates,
              ),
            ),

            // Date header with count and sort option
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: repertoiresAsync.when(
                data: (repertoires) => Row(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    if (_isToday()) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Text(
                          '오늘',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Repertoire count
                    Text(
                      '${repertoires.length}개 레퍼토리',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort dropdown
                    _buildSortDropdown(),
                  ],
                ),
                loading: () => Row(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    _buildSortDropdown(),
                  ],
                ),
                error: (_, __) => Row(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    _buildSortDropdown(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Repertoire list
            Expanded(
              child: repertoiresAsync.when(
                data: (repertoires) {
                  if (repertoires.isEmpty) {
                    return _buildEmptyState(studentId);
                  }
                  // Apply sorting
                  final sortType = ref.watch(repertoireSortTypeProvider);
                  final sortedRepertoires = repertoires.sortBy(sortType);
                  return _buildRepertoireList(sortedRepertoires, studentId);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('오류가 발생했습니다: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    return dateFormat.format(date);
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Widget _buildSortDropdown() {
    final sortType = ref.watch(repertoireSortTypeProvider);

    return PopupMenuButton<RepertoireSortType>(
      initialValue: sortType,
      onSelected: (type) {
        ref.read(repertoireSortTypeProvider.notifier).state = type;
      },
      itemBuilder: (context) => RepertoireSortType.values
          .where((type) => type != RepertoireSortType.custom)
          .map((type) {
        return PopupMenuItem<RepertoireSortType>(
          value: type,
          child: Row(
            children: [
              Icon(
                _getSortIcon(type),
                size: 18,
                color: type == sortType
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: TextStyle(
                  color: type == sortType
                      ? AppColors.primary
                      : AppColors.textPrimaryLight,
                  fontWeight:
                      type == sortType ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSortIcon(sortType),
              size: 16,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              sortType.displayName,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSortIcon(RepertoireSortType type) {
    switch (type) {
      case RepertoireSortType.createdDesc:
        return Icons.arrow_downward;
      case RepertoireSortType.createdAsc:
        return Icons.arrow_upward;
      case RepertoireSortType.nameAsc:
        return Icons.sort_by_alpha;
      case RepertoireSortType.custom:
        return Icons.drag_handle;
    }
  }

  Set<DateTime> _getPracticedDates(List<PracticeRepertoire> repertoires) {
    final dates = <DateTime>{};
    for (final rep in repertoires) {
      for (final section in rep.sections) {
        for (final status in section.dailyStatuses) {
          if (status.isCompleted) {
            dates.add(status.dateOnly);
          }
        }
      }
    }
    return dates;
  }

  Widget _buildEmptyState(String studentId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              _isToday() ? '오늘 연습할 레퍼토리가 없습니다' : '이 날짜에 연습 기록이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            if (_isToday())
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '${AppRoutes.quickAddRepertoire}?studentId=$studentId',
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('레퍼토리 추가'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepertoireList(List<PracticeRepertoire> repertoires, String studentId) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      itemCount: repertoires.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        // Last item is add button
        if (index == repertoires.length) {
          return Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space2,
              bottom: AppSpacing.space4,
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '${AppRoutes.quickAddRepertoire}?studentId=$studentId',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('레퍼토리 추가'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          );
        }
        final repertoire = repertoires[index];
        return _RepertoireCard(
          repertoire: repertoire,
          selectedDate: _selectedDate,
          studentId: studentId,
          isToday: _isToday(),
        );
      },
    );
  }
}

/// Repertoire card with expandable sections
class _RepertoireCard extends ConsumerStatefulWidget {
  final PracticeRepertoire repertoire;
  final DateTime selectedDate;
  final String studentId;
  final bool isToday;

  const _RepertoireCard({
    required this.repertoire,
    required this.selectedDate,
    required this.studentId,
    required this.isToday,
  });

  @override
  ConsumerState<_RepertoireCard> createState() => _RepertoireCardState();
}

class _RepertoireCardState extends ConsumerState<_RepertoireCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final visibleSections =
        widget.repertoire.getSectionsForDate(widget.selectedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              children: [
                // Repertoire name - tap to navigate to detail
                Expanded(
                  child: InkWell(
                    onTap: () {
                      context.push(
                        '${AppRoutes.repertoireDetail.replaceFirst(':id', widget.repertoire.id)}'
                        '?studentId=${widget.studentId}'
                        '&date=${widget.selectedDate.toIso8601String()}',
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.repertoire.name,
                                style: AppTypography.headingSmall,
                              ),
                              Text(
                                widget.repertoire.dateRangeText,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add section button - square with purple background
                GestureDetector(
                  onTap: () {
                    context.push(
                      '${AppRoutes.addSection}?repertoireId=${widget.repertoire.id}&studentId=${widget.studentId}',
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Expand/collapse button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondaryLight,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),

          // Sections list
          if (_isExpanded && visibleSections.isNotEmpty)
            Column(
              children: visibleSections.map((section) {
                return _SectionTile(
                  section: section,
                  repertoireId: widget.repertoire.id,
                  studentId: widget.studentId,
                  selectedDate: widget.selectedDate,
                  isToday: widget.isToday,
                );
              }).toList(),
            ),

          if (_isExpanded && visibleSections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Text(
                '이 날짜에 표시할 섹션이 없습니다',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section tile with checkbox and repeat toggle
class _SectionTile extends ConsumerWidget {
  final PracticeSection section;
  final String repertoireId;
  final String studentId;
  final DateTime selectedDate;
  final bool isToday;

  const _SectionTile({
    required this.section,
    required this.repertoireId,
    required this.studentId,
    required this.selectedDate,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompletedForDate = section.isCompletedForDate(selectedDate);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}'
            '?repertoireId=$repertoireId&studentId=$studentId'
            '&date=${selectedDate.toIso8601String()}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            children: [
              // Checkbox
              if (isToday)
                Checkbox(
                  value: isCompletedForDate,
                  onChanged: (value) async {
                    await ref
                        .read(sectionCrudProvider.notifier)
                        .toggleDailyCompletion(
                          section.id,
                          repertoireId,
                          studentId,
                          selectedDate,
                        );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                Icon(
                  isCompletedForDate
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompletedForDate
                      ? AppColors.success
                      : AppColors.textSecondaryLight,
                  size: 22,
                ),
              const SizedBox(width: AppSpacing.space2),

              // Section info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.pieceName,
                      style: AppTypography.bodyMedium.copyWith(
                        decoration: isCompletedForDate
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompletedForDate
                            ? AppColors.textSecondaryLight
                            : null,
                      ),
                    ),
                    Text(
                      section.rangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Repeat toggle (only for today)
              if (isToday)
                IconButton(
                  onPressed: () async {
                    await ref.read(sectionCrudProvider.notifier).toggleRepeat(
                          section.id,
                          repertoireId,
                          studentId,
                        );
                  },
                  icon: Icon(
                    Icons.repeat,
                    color: section.isRepeat
                        ? AppColors.primary
                        : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  tooltip: section.isRepeat ? '매일 반복' : '반복 안함',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
