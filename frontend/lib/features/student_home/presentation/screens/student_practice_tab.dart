import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/pencil_primitives.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/domain/entities/repertoire_sort_type.dart';
import '../../../practice/presentation/providers/repertoire_sort_provider.dart';
import '../../../../core/widgets/compact_week_strip.dart';

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
    final allRepertoiresAsync = ref.watch(
      studentRepertoiresProvider(studentId),
    );
    final practicedDates = allRepertoiresAsync.whenOrNull(
      data: (repertoires) => _getPracticedDates(repertoires),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space2,
                AppSpacing.screenPadding,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('내 연습', style: AppTypography.headingLarge),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed:
                            () => context.push(
                              '${AppRoutes.repertoireHistory}?studentId=$studentId',
                            ),
                        icon: const Icon(Icons.history),
                        tooltip: '레퍼토리 히스토리',
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          context.push(
                            '${AppRoutes.quickAddRepertoire}?studentId=$studentId',
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('레퍼토리 추가'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space4,
                            vertical: AppSpacing.space2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Compact week strip (unified with teacher schedule)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space2,
                AppSpacing.screenPadding,
                0,
              ),
              child: CompactWeekStrip(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                markerDates: practicedDates,
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Date header with count and sort option
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: repertoiresAsync.when(
                data: (repertoires) {
                  // Calculate total section count for selected date
                  final sectionCount = repertoires.fold<int>(
                    0,
                    (sum, rep) =>
                        sum + rep.getSectionsForDate(_selectedDate).length,
                  );
                  return Row(
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      if (_isToday()) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccentSoft,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSmall,
                            ),
                          ),
                          child: Text(
                            '오늘',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Section count
                      Text(
                        '$sectionCount개 섹션',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      // Sort dropdown
                      _buildSortDropdown(),
                    ],
                  );
                },
                loading:
                    () => Row(
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildSortDropdown(),
                      ],
                    ),
                error:
                    (_, __) => Row(
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildSortDropdown(),
                      ],
                    ),
              ),
            ),

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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDateMDWithDayLong(date);
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
      itemBuilder:
          (context) =>
              RepertoireSortType.values
                  .where((type) => type != RepertoireSortType.custom)
                  .map((type) {
                    return PopupMenuItem<RepertoireSortType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getSortIcon(type),
                            size: 18,
                            color:
                                type == sortType
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              color:
                                  type == sortType
                                      ? AppColors.paperAccent
                                      : AppColors.ink,
                              fontWeight:
                                  type == sortType
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSortIcon(sortType),
              size: 16,
              color: AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              sortType.displayName,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.inkSecondary,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: AppColors.inkSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              _isToday() ? '오늘 연습할 레퍼토리가 없습니다' : '이 날짜에 연습 기록이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepertoireList(
    List<PracticeRepertoire> repertoires,
    String studentId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        0,
      ),
      itemCount: repertoires.length,
      itemBuilder: (context, index) {
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
    final visibleSections = widget.repertoire.getSectionsForDate(
      widget.selectedDate,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
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
                        Icon(Icons.menu_book, color: AppColors.ink, size: 24),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Notebook × Score: 레퍼토리/곡 이름은 Playfair pieceTitle 로 통일 (§7.30 pieceTitle 패턴).
                              Text(
                                widget.repertoire.name,
                                style: NotebookTypography.pieceTitle,
                              ),
                              Text(
                                widget.repertoire.dateRangeText,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add section button — ink square (Notebook × Score)
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
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.paper,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
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
                    color: AppColors.inkSecondary,
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
              children:
                  visibleSections.map((section) {
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
                  color: AppColors.inkSecondary,
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
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
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
              // Notebook × Score: 연습 완료를 연필 사각 체크박스로 통일. 오늘은 탭 가능, 과거/미래는 읽기 전용.
              if (isToday)
                GestureDetector(
                  onTap: () async {
                    await ref
                        .read(sectionCrudProvider.notifier)
                        .toggleDailyCompletion(
                          section.id,
                          repertoireId,
                          studentId,
                          selectedDate,
                        );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(
                      child: PencilBox(
                        checked: isCompletedForDate,
                        size: 22,
                        checkColor: AppColors.paperOk,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(
                    child: PencilBox(
                      checked: isCompletedForDate,
                      size: 22,
                      borderColor: AppColors.inkSecondary,
                      checkColor: AppColors.paperOk,
                    ),
                  ),
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
                        decoration:
                            isCompletedForDate
                                ? TextDecoration.lineThrough
                                : null,
                        color:
                            isCompletedForDate ? AppColors.inkSecondary : null,
                      ),
                    ),
                    Text(
                      section.rangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Repeat toggle (only for today)
              if (isToday)
                IconButton(
                  onPressed: () async {
                    await ref
                        .read(sectionCrudProvider.notifier)
                        .toggleRepeat(section.id, repertoireId, studentId);
                  },
                  icon: Icon(
                    Icons.repeat,
                    color:
                        section.isRepeat
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary.withValues(alpha: 0.5),
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
                color: AppColors.inkSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
