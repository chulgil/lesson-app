import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/pencil_primitives.dart';
import '../../../../features/gamification/gamification_facade.dart'
    show growthHeatmapProvider;
import '../../../../features/practice/practice_facade.dart';
import '../../../../features/practice/practice_ui_facade.dart';
import '../../../../features/practice/presentation/extensions/repertoire_sort_type_visuals.dart';
import '../../../students/students_facade.dart';
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
    // Resolve the real Student.id (GET /students/me/profile). The auth userId
    // is not a Student.id — using it 404s on remote (mock matched by luck).
    return ref
        .watch(currentStudentProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(AppStrings.cannotLoadData)),
          data: (student) => _buildBody(context, student.id),
        );
  }

  Widget _buildBody(BuildContext context, String studentId) {
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

    return Column(
      children: [
        // Header — Notebook × Score masthead pattern
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              NotebookMasthead(
                eyebrow: 'PRACTICE',
                meta:
                    'VOL. ${romanOf(DateTime.now().month - 1)} · NO. ${DateTime.now().day}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // #405 수동 연습 기록 진입점 — 오프라인 연습을 직접 기록.
                    IconButton(
                      onPressed: () async {
                        final saved = await ManualPracticeEntrySheet.show(
                          context,
                          studentId: studentId,
                        );
                        if (saved == true && context.mounted) {
                          // 수동 연습 기록 후 heatmap/streak provider 무효화 —
                          // 대시보드가 stale 되지 않게 (A4, practice_start_section 동일).
                          ref.invalidate(growthHeatmapProvider(studentId));
                          ref.invalidate(practiceStreakProvider(studentId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.manualPracticeSaved),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.more_time,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      tooltip: AppStrings.practiceRecordTodayLabel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => context.push(
                            '${AppRoutes.repertoireHistory}?studentId=$studentId',
                          ),
                      icon: const Icon(
                        Icons.history,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      tooltip: AppStrings.repertoireHistory,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                    ),
                    // #492 §2.4 노트 작성 진입점 (헤더 액션).
                    IconButton(
                      onPressed: () => _onAddNotePressed(repertoiresAsync),
                      icon: const Icon(
                        Icons.edit_note,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      tooltip: AppStrings.practiceNoteAddTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => context.push(
                            '${AppRoutes.quickAddRepertoire}?studentId=$studentId',
                          ),
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      tooltip: AppStrings.repertoireAdd,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Goal progress widget (§2.2) — daily/weekly progress bars +
        // achievement dialog on first achievement of the day/week.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: GoalProgressWidget(studentId: studentId),
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
                  // 좌: 날짜 + '오늘' 배지. 좁은 폭(375px)에서 우측 그룹(섹션 수 +
                  // 정렬)을 밀어내며 날짜가 말줄임되도록 Expanded — Spacer 는 고정폭
                  // 내용을 못 줄여 375px 에서 60px 가로 overflow 를 냈다.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatDate(_selectedDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
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
                            ),
                            // "오늘" = 시스템 자동 인디케이터 → Tier 4 Pretendard
                            // italic (README §1.1 4계층, §7.127 Gaegu 회피).
                            child: Text(
                              '오늘',
                              style: NotebookTypography.indicatorLabel,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
              final sortType = ref.watch(repertoireSortTypeStateProvider);
              final sortedRepertoires = repertoires.sortBy(sortType);
              return _buildRepertoireList(sortedRepertoires, studentId);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                // #75 practice 컨텍스트에 맞는 일반 에러 문자열 (profile 전용 재사용 제거)
                (_, __) => Center(child: Text(AppStrings.errorOccurred)),
          ),
        ),
      ],
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
    final sortType = ref.watch(repertoireSortTypeStateProvider);

    return PopupMenuButton<RepertoireSortType>(
      initialValue: sortType,
      onSelected: (type) {
        ref.read(repertoireSortTypeStateProvider.notifier).setSortType(type);
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
    return EmptyStateWidget(
      icon: Icons.library_music_outlined,
      title:
          _isToday()
              ? AppStrings.studentPracticeTodayEmpty
              : AppStrings.studentPracticeDateEmpty,
      scrollable: true,
    );
  }

  Widget _buildRepertoireList(
    List<PracticeRepertoire> repertoires,
    String studentId,
  ) {
    // §2.4 학생 홈 통합: 선택한 날짜의 표시 가능한 섹션을 모아
    // 노트 카드 섹션을 레퍼토리 리스트 하단에 노출한다.
    final visibleSections = _collectVisibleSections(repertoires);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        AppSpacing.space6,
      ),
      itemCount: repertoires.length + (visibleSections.isEmpty ? 0 : 1),
      itemBuilder: (context, index) {
        if (index < repertoires.length) {
          final repertoire = repertoires[index];
          return _RepertoireCard(
            repertoire: repertoire,
            selectedDate: _selectedDate,
            studentId: studentId,
            isToday: _isToday(),
          );
        }
        return _PracticeNoteSection(sections: visibleSections);
      },
    );
  }

  List<_SectionLink> _collectVisibleSections(
    List<PracticeRepertoire> repertoires,
  ) {
    final result = <_SectionLink>[];
    for (final repertoire in repertoires) {
      final sections = repertoire.getSectionsForDate(_selectedDate);
      for (final section in sections) {
        result.add(
          _SectionLink(
            sectionId: section.id,
            pieceName: section.pieceName,
            rangeText: section.rangeText,
          ),
        );
      }
    }
    return result;
  }

  /// 헤더 노트 추가 버튼 핸들러.
  /// 표시 가능한 섹션이 1개면 즉시 다이얼로그, 여러 개면 섹션 선택 시트.
  Future<void> _onAddNotePressed(
    AsyncValue<List<PracticeRepertoire>> repertoiresAsync,
  ) async {
    final repertoires = repertoiresAsync.valueOrNull ?? const [];
    final sections = _collectVisibleSections(repertoires);

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceNoteNoSectionsHint)),
      );
      return;
    }

    final picked =
        sections.length == 1 ? sections.first : await _pickSection(sections);
    if (picked == null) return;
    if (!mounted) return;

    final content = await NoteEditDialog.show(context);
    if (content == null) return;

    await ref
        .read(practiceNoteCrudProvider.notifier)
        .createNote(sectionId: picked.sectionId, content: content);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceNoteAddedSnack)),
      );
    }
  }

  Future<_SectionLink?> _pickSection(List<_SectionLink> sections) {
    return showNotebookModalBottomSheet<_SectionLink>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space4,
                  AppSpacing.space4,
                  AppSpacing.space2,
                ),
                child: Text(
                  AppStrings.practiceNotePickSection,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final section in sections)
                ListTile(
                  leading: Icon(
                    Icons.library_music,
                    color: AppColors.paperAccent,
                    size: 20,
                  ),
                  title: Text(section.pieceName),
                  subtitle: Text(section.rangeText),
                  onTap: () => Navigator.of(sheetContext).pop(section),
                ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        );
      },
    );
  }
}

/// 선택된 날짜의 가시 섹션을 가벼운 값 객체로 캡쳐. (#492 노트 카드 라우팅에만 사용)
class _SectionLink {
  const _SectionLink({
    required this.sectionId,
    required this.pieceName,
    required this.rangeText,
  });

  final String sectionId;
  final String pieceName;
  final String rangeText;
}

/// §2.4 학생 홈 노트 섹션. 가시 섹션 각각에 [PracticeNoteCard] 를 노출.
class _PracticeNoteSection extends StatelessWidget {
  const _PracticeNoteSection({required this.sections});

  final List<_SectionLink> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            0,
            AppSpacing.space4,
            0,
            AppSpacing.space2,
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.inkSecondary, size: 20),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.practiceNoteSectionTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final section in sections)
          PracticeNoteCard(
            sectionId: section.sectionId,
            sectionTitle: section.pieceName,
            sectionSubtitle: section.rangeText,
          ),
      ],
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
                    decoration: BoxDecoration(color: AppColors.ink),
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
                    // #412 연습(섹션 일일완료) → 연결된 과제 진척 누적.
                    // 완료(isCompleted)는 자동 변경하지 않음 — 학생 확인 유지.
                    final itemId = section.practiceItemId;
                    if (itemId != null) {
                      final nowCompleted = !isCompletedForDate;
                      final notifier = ref.read(
                        studentPracticeNotifierProvider(studentId).notifier,
                      );
                      try {
                        if (nowCompleted) {
                          await notifier.incrementCount(itemId);
                        } else {
                          await notifier.decrementCount(itemId);
                        }
                      } catch (_) {
                        // 진척 반영 실패는 비치명적 — 섹션 완료 UX 유지.
                      }
                    }
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

              // §3.5 YouTube loop entry-point affordance — only when video exists.
              if (section.youtubeUrl != null) ...[
                const SizedBox(width: AppSpacing.space2),
                SectionVideoAffordance(
                  startSeconds: section.youtubeStartSeconds,
                  endSeconds: section.youtubeEndSeconds,
                  stacked: true,
                ),
              ],

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
