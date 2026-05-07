import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../domain/entities/grouped_students.dart';
import '../../domain/entities/roster_summary.dart';
import '../extensions/student_domain_visuals.dart';
import '../providers/student_crud_provider.dart';
import '../providers/student_roster_summary_provider.dart';
import '../../domain/entities/student_with_membership.dart';
import '../providers/grouped_students_provider.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/announcement_sheet.dart';
import '../widgets/bulk_message_sheet.dart';
import '../widgets/roster_triage_banner.dart';
import '../widgets/student_subscription_badge.dart';

/// Students management tab with Riverpod state management
class StudentsTab extends ConsumerStatefulWidget {
  const StudentsTab({super.key});

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

enum StudentSortOption {
  name('이름순'),
  instrument('악기순'),
  practiceStatus('연습상태별');

  final String label;
  const StudentSortOption(this.label);
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  final _searchController = TextEditingController();
  StudentFilter _currentFilter = StudentFilter.all;
  StudentSortOption _sortOption = StudentSortOption.name;
  bool _isSelectionMode = false;
  final Set<String> _selectedStudentIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final groupedAsync = ref.watch(filteredGroupedStudentsProvider(teacherId));
    final summaryAsync = ref.watch(studentRosterSummaryProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            final teacherId = ref.read(currentUserIdProvider);
            ref.invalidate(groupedStudentsProvider(teacherId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (!_isSelectionMode)
                SliverToBoxAdapter(
                  child: RosterTriageBanner(
                    onFilterSelected: _onTriageFilterSelected,
                    selectedCategory: _selectedTriageCategory,
                  ),
                ),
              SliverToBoxAdapter(child: _buildSearchBar()),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space2),
              ),
              SliverToBoxAdapter(
                child: _buildCountAndSort(groupedAsync, summaryAsync.value),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space2),
              ),
              groupedAsync.when(
                data:
                    (groups) =>
                        _buildGroupedStudentSliver(groups, summaryAsync.value),
                loading:
                    () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, stack) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(error),
                    ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _selectedStudentIds.isNotEmpty ? 72 : 0,
                ),
              ),
            ],
          ),
        ),

        // Bottom action bar
        if (_selectedStudentIds.isNotEmpty) _buildBottomActionBar(),
      ],
    );
  }

  List<StudentGroup> _applyPracticeFilter(
    List<StudentGroup> groups,
    RosterSummary? summary,
  ) {
    if (_currentFilter == StudentFilter.all) return groups;

    // Enrollment 필터는 RosterSummary ID set 기반 — summary 미도달 시 빈 결과.
    final enrollmentIds = _enrollmentFilterIds(summary);

    return groups
        .map((group) {
          final filtered =
              group.students.where((swm) {
                switch (_currentFilter) {
                  case StudentFilter.all:
                    return true;
                  case StudentFilter.good:
                    return swm.practiceStatus == PracticeStatus.good;
                  case StudentFilter.normal:
                    return swm.practiceStatus == PracticeStatus.normal;
                  case StudentFilter.poor:
                    return swm.practiceStatus == PracticeStatus.poor;
                  case StudentFilter.paused:
                    return swm.practiceStatus == PracticeStatus.paused;
                  case StudentFilter.expiring:
                  case StudentFilter.unpaid:
                  case StudentFilter.trial:
                  case StudentFilter.archive:
                    return enrollmentIds?.contains(swm.studentId) ?? false;
                }
              }).toList();
          return StudentGroup(
            lessonClass: group.lessonClass,
            students: filtered,
          );
        })
        .where((group) => group.students.isNotEmpty)
        .toList();
  }

  /// Enrollment 계열 필터(expiring/unpaid/trial/archive)에 해당하는 학생 ID set 반환.
  /// 기타 필터(all/good/normal/poor/paused) 또는 summary 미도달 시 null.
  Set<String>? _enrollmentFilterIds(RosterSummary? summary) {
    if (summary == null) return null;
    return switch (_currentFilter) {
      StudentFilter.expiring => summary.expiringStudentIds,
      StudentFilter.unpaid => summary.unpaidStudentIds,
      StudentFilter.trial => summary.trialStudentIds,
      StudentFilter.archive => summary.archivedStudentIds,
      _ => null,
    };
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });
  }

  /// 전체 학생 ID set (현재 필터 적용된 그룹 기준).
  Set<String> get _allStudentIds {
    final teacherId = ref.read(currentUserIdProvider);
    final groupedAsync = ref.read(filteredGroupedStudentsProvider(teacherId));
    final summaryAsync = ref.read(studentRosterSummaryProvider);
    final groups = groupedAsync.valueOrNull ?? const [];
    final filtered = _applyPracticeFilter(groups, summaryAsync.value);
    return {
      for (final group in filtered)
        for (final swm in group.students) swm.studentId,
    };
  }

  bool get _isAllSelected {
    final all = _allStudentIds;
    return all.isNotEmpty && _selectedStudentIds.containsAll(all);
  }

  void _selectAllStudents() {
    setState(() {
      final all = _allStudentIds;
      if (_selectedStudentIds.containsAll(all)) {
        _selectedStudentIds.clear();
      } else {
        _selectedStudentIds.addAll(all);
      }
    });
  }

  /// Maps current StudentFilter to RosterTriageCategory for banner highlight.
  RosterTriageCategory? get _selectedTriageCategory {
    return switch (_currentFilter) {
      StudentFilter.expiring => RosterTriageCategory.expiring,
      StudentFilter.unpaid => RosterTriageCategory.unpaid,
      StudentFilter.trial => RosterTriageCategory.trial,
      _ => null,
    };
  }

  /// Triage 배너 칸 탭 → 동일 필터가 이미 선택돼 있으면 해제, 아니면 적용.
  /// Phase 3 에서 ID set 기반 실제 필터 로직이 연결되기 전까지는 enum 전환만 수행.
  void _onTriageFilterSelected(
    RosterTriageCategory category,
    Set<String> studentIds,
  ) {
    final target = switch (category) {
      RosterTriageCategory.expiring => StudentFilter.expiring,
      RosterTriageCategory.unpaid => StudentFilter.unpaid,
      RosterTriageCategory.trial => StudentFilter.trial,
    };
    setState(() {
      _currentFilter = _currentFilter == target ? StudentFilter.all : target;
    });
  }

  Widget _buildHeader() {
    // 선택 모드: 홈 masthead 대신 단순 카운트 + 취소 Row (홈 전환 느낌 보존)
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Row(
          children: [
            Text(
              '${_selectedStudentIds.length}명 선택됨',
              style: AppTypography.headingLarge,
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectAllStudents,
              child: Text(
                _isAllSelected
                    ? AppStrings.deselectAll
                    : AppStrings.selectAll,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            TextButton(
              onPressed: _exitSelectionMode,
              child: Text(
                '취소',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 일반 모드: Notebook × Score masthead 승격 (선생님 홈/학부모 홈과 일관)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          // ── Masthead: "ENROLLMENTS" eyebrow + 선택모드 + 추가 아이콘 ──
          NotebookMasthead(
            eyebrow: 'ENROLLMENTS',
            meta: _volumeIssueString(DateTime.now()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📢 공지 아이콘 (v3)
                IconButton(
                  onPressed: () => _showAnnouncementSheet(context),
                  icon: const Icon(
                    Icons.campaign,
                    color: AppColors.ink,
                    size: 22,
                  ),
                  tooltip: AppStrings.announcementTitle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                // ☑ 선택 모드
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedStudentIds.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                  tooltip: AppStrings.studentBulkSelectLabel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                // + 학생 추가
                IconButton(
                  onPressed: () => context.push(AppRoutes.addStudentMethod),
                  icon: const Icon(Icons.add, color: AppColors.ink, size: 22),
                  tooltip: AppStrings.studentAddLabel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          // ── Programme Title — "수강 관리" Playfair ──
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Programme of Enrollments',
                  style: NotebookTypography.mastheadLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.studentRosterMasthead,
                  style: NotebookTypography.masthead,
                ),
                const SizedBox(height: AppSpacing.space3),
                const ThinRule(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Notebook meta: "VOL. IV · NO. 23" 형식.
  /// 알림/액션이 trailing 을 대신하므로 실 렌더에는 사용되지 않지만 API 요구.
  String _volumeIssueString(DateTime now) {
    return 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}';
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(studentSearchQueryProvider.notifier).setQuery(value);
        },
        decoration: InputDecoration(
          hintText: AppStrings.studentSearchByNameOrInstrument,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.inkTertiary),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(studentSearchQueryProvider.notifier).clear();
                    },
                    icon: const Icon(Icons.clear, size: 20),
                  )
                  : null,
          filled: true,
          fillColor: AppColors.paperDark,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
      ),
    );
  }

  /// 연습상태 필터 바텀시트 (전체/우수/보통/부족/휴강)
  Future<void> _showPracticeFilterSheet() async {
    final selected = await showNotebookModalBottomSheet<StudentFilter>(
      context: context,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                    // (§7.27). '필터' 는 정적 명사 헤더 — 연습/수강 상태 통합.
                    Text(
                      AppStrings.studentFilterTitle,
                      style: NotebookTypography.appBarTitle,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    ...StudentFilter.values.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkTertiary,
                        ),
                        title: Text(
                          filter.label,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(filter),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
    );

    if (selected != null) {
      setState(() => _currentFilter = selected);
    }
  }

  Widget _buildCountAndSort(
    AsyncValue<List<StudentGroup>> groupedAsync,
    RosterSummary? summary,
  ) {
    final count = groupedAsync.when(
      data: (groups) {
        final filtered = _applyPracticeFilter(groups, summary);
        return filtered.fold<int>(0, (sum, g) => sum + g.count);
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    final hasActiveFilter = _currentFilter != StudentFilter.all;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            '전체 $count명',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.tune,
              size: 20,
              color:
                  hasActiveFilter
                      ? AppColors.paperAccent
                      : AppColors.inkSecondary,
            ),
            onPressed: _showPracticeFilterSheet,
            tooltip: AppStrings.studentFilterTitle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort, size: 18),
            label: Text(_sortOption.label),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                  // (§7.27). '정렬 기준' 은 정적 명사 헤더.
                  child: Text(
                    AppStrings.studentSortTitle,
                    style: NotebookTypography.appBarTitle,
                  ),
                ),
                ...StudentSortOption.values.map((option) {
                  final isSelected = _sortOption == option;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                    title: Text(option.label),
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.space2),
              ],
            ),
          ),
    );
  }

  List<StudentGroup> _applySortToGroups(List<StudentGroup> groups) {
    return groups.map((group) {
      final sorted = List<StudentWithMembership>.from(group.students);
      switch (_sortOption) {
        case StudentSortOption.name:
          sorted.sort((a, b) => a.name.compareTo(b.name));
        case StudentSortOption.instrument:
          sorted.sort((a, b) => a.instrument.compareTo(b.instrument));
        case StudentSortOption.practiceStatus:
          // 부족한 학생이 위로 (선생님이 우선 챙겨야 할 순)
          sorted.sort(
            (a, b) => a.student.practiceRate.compareTo(b.student.practiceRate),
          );
      }
      return StudentGroup(lessonClass: group.lessonClass, students: sorted);
    }).toList();
  }

  Widget _buildGroupedStudentSliver(
    List<StudentGroup> groups,
    RosterSummary? summary,
  ) {
    final filtered = _applySortToGroups(_applyPracticeFilter(groups, summary));

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    // Count subjects (memberships) per student across all groups.
    // Used for `N과목` badge when student has multiple subjects.
    final subjectCounts = <String, int>{};
    for (final group in filtered) {
      for (final swm in group.students) {
        subjectCounts[swm.studentId] = (subjectCounts[swm.studentId] ?? 0) + 1;
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      sliver: SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _ClassGroupSection(
            group: filtered[index],
            isSelectionMode: _isSelectionMode,
            selectedStudentIds: _selectedStudentIds,
            studentSubjectCounts: subjectCounts,
            onSelectionChanged: (studentId, isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedStudentIds.add(studentId);
                } else {
                  _selectedStudentIds.remove(studentId);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(studentSearchQueryProvider);

    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: query.isNotEmpty ? '검색 결과가 없습니다' : '아직 등록된 학생이 없습니다',
      subtitle: query.isEmpty ? '학생을 초대하면 정보가 자동으로\n등록되어 편리하게 관리할 수 있어요' : null,
      actionLabel: query.isEmpty ? '학생 추가' : null,
      actionIcon: query.isEmpty ? Icons.person_add : null,
      onAction:
          query.isEmpty ? () => context.push(AppRoutes.addStudentMethod) : null,
    );
  }

  Widget _buildBottomActionBar() {
    // v3: 선택 모드는 일괄 메시지만. 휴강 공지는 Masthead 공지 아이콘으로 이동.
    final hasSelection = _selectedStudentIds.isNotEmpty;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedStudentIds.length}명 선택됨',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              FilledButton.icon(
                onPressed: hasSelection ? _onBulkMessage : null,
                icon: const Icon(Icons.send, size: 18),
                label: const Text(AppStrings.studentSendMessage),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// v3: Masthead 📢 → 공지 작성 시트
  void _showAnnouncementSheet(BuildContext context) {
    AnnouncementSheet.show(context, ref: ref);
  }

  void _onBulkMessage() async {
    final result = await BulkMessageSheet.show(
      context,
      studentIds: _selectedStudentIds.toList(),
    );
    if (result == true && mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedStudentIds.clear();
      });
    }
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          OutlinedButton.icon(
            onPressed: () {
              final teacherId = ref.read(currentUserIdProvider);
              ref.invalidate(groupedStudentsProvider(teacherId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

enum StudentFilter {
  all('전체'),
  good('우수'),
  normal('보통'),
  poor('부족'),
  paused('휴강'),
  expiring('만료임박'),
  unpaid('입금대기(후불)'),
  trial('체험'),
  archive('보관');

  final String label;
  const StudentFilter(this.label);

  /// True if this filter uses subscription/membership state (not practice status).
  bool get isEnrollmentFilter =>
      this == StudentFilter.expiring ||
      this == StudentFilter.unpaid ||
      this == StudentFilter.trial ||
      this == StudentFilter.archive;
}

/// Section header + student cards for a single class group.
/// Supports collapse/expand.
class _ClassGroupSection extends StatefulWidget {
  final StudentGroup group;
  final bool isSelectionMode;
  final Set<String> selectedStudentIds;
  final void Function(String studentId, bool isSelected) onSelectionChanged;

  /// Map of studentId → subject count across all groups.
  /// Used to show `N과목` badge next to name.
  final Map<String, int> studentSubjectCounts;

  const _ClassGroupSection({
    required this.group,
    required this.isSelectionMode,
    required this.selectedStudentIds,
    required this.onSelectionChanged,
    this.studentSubjectCounts = const {},
  });

  @override
  State<_ClassGroupSection> createState() => _ClassGroupSectionState();
}

class _ClassGroupSectionState extends State<_ClassGroupSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (tappable)
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space4,
              bottom: AppSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.group.icon} ${widget.group.title} (${widget.group.count})',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.inkTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Student cards (collapsible)
        if (_isExpanded)
          ...widget.group.students.map(
            (swm) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: _StudentCard(
                studentWithMembership: swm,
                isSelectionMode: widget.isSelectionMode,
                isSelected: widget.selectedStudentIds.contains(swm.studentId),
                onSelectionChanged: (isSelected) {
                  widget.onSelectionChanged(swm.studentId, isSelected);
                },
                subjectCount: widget.studentSubjectCounts[swm.studentId] ?? 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final StudentWithMembership studentWithMembership;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  /// Number of subjects (memberships) this student has across all groups.
  /// Shows `[N]` badge next to name when subjectCount > 1.
  final int subjectCount;

  const _StudentCard({
    required this.studentWithMembership,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    this.subjectCount = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swm = studentWithMembership;

    return Container(
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppColors.paperAccentSoft
                : Theme.of(context).colorScheme.surface,
        border: isSelected ? Border.all(color: AppColors.paperAccent) : null,
      ),
      child: InkWell(
        onTap:
            isSelectionMode
                ? () => onSelectionChanged(!isSelected)
                : () {
                  context.push(
                    AppRoutes.studentDetail.replaceFirst(':id', swm.studentId),
                    extra: {'membershipId': swm.membership?.id},
                  );
                },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: _buildHeaderRow(context, ref, swm)),
              if (!isSelectionMode) _EnrollmentExtras(studentId: swm.studentId),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeaderRow(
    BuildContext context,
    WidgetRef ref,
    StudentWithMembership swm,
  ) {
    return [
      // Checkbox (selection mode only)
      if (isSelectionMode) ...[
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isSelected,
            onChanged: (value) => onSelectionChanged(value ?? false),
            activeColor: AppColors.paperAccent,
            shape: const RoundedRectangleBorder(),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
      ],

      // Avatar
      CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.paperAccentSoft,
        child: Text(
          swm.initial,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.paperAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      const SizedBox(width: AppSpacing.space3),

      // Info section (flexible)
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name · Instrument + connection badge + [N] badge
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${swm.name} · ${swm.instrument}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Subject count badge (복수 과목 힌트)
                if (subjectCount > 1) ...[
                  const SizedBox(width: AppSpacing.space1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                    child: Text(
                      '$subjectCount과목',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.space1),
                Icon(
                  swm.isAppConnected ? Icons.link : Icons.edit_note,
                  size: 14,
                  color:
                      swm.isAppConnected
                          ? AppColors.paperOk
                          : AppColors.inkTertiary,
                ),
              ],
            ),
            // Row 2: Schedule
            Text(
              swm.lessonSchedule ?? '스케줄 미등록',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      // Status section
      if (!isSelectionMode) ...[
        _buildSubscriptionStatus(context, ref, swm.studentId),
        const SizedBox(width: AppSpacing.space1),
        // Arrow
        const Icon(Icons.chevron_right, color: AppColors.inkTertiary, size: 20),
      ],
    ];
  }

  Widget _buildSubscriptionStatus(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final subscriptionsAsync = ref.watch(
      activeStudentSubscriptionsProvider(studentId),
    );

    return subscriptionsAsync.when(
      data: (subscriptions) {
        // Deposit confirmation pending takes highest priority.
        final hasUnpaid = subscriptions.any((s) => s.isUnpaid);
        if (hasUnpaid) {
          return SizedBox(
            width: 56,
            child: GestureDetector(
              onTap:
                  () => context.push(
                    '${AppRoutes.issueSubscription}?studentId=$studentId',
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paperAccentSoft,
                  border: Border.all(color: AppColors.paperAccent),
                ),
                child: Text(
                  '입금대기(후불)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: 56,
          child: StudentSubscriptionMiniBadge(studentId: studentId),
        );
      },
      loading: () => const SizedBox(width: 56),
      error: (_, __) => const SizedBox(width: 56),
    );
  }
}

/// Student card 의 수강권 확장 영역 — 진행 bar + D-day + 인라인 CTA.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.3
///
/// 3가지 모드:
/// - normal  : 진행 bar + D-day + [레슨 추가]
/// - expiring: D-day 강조 색상 + [레슨 추가]
/// - archive : 진행 bar 숨김 + "YYYY-MM-DD 만료" 메타 + [재등록 제안]
class _EnrollmentExtras extends ConsumerWidget {
  final String studentId;

  const _EnrollmentExtras({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(studentSubscriptionsProvider(studentId));

    return subsAsync.when(
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();

        final active =
            subs
                .where(
                  (s) =>
                      s.status == SubscriptionStatus.active ||
                      s.status == SubscriptionStatus.expiringSoon,
                )
                .toList();
        final isArchive = active.isEmpty;

        if (isArchive) {
          // Archive 모드: 가장 최근 만료된 수강권 메타 + 재등록 CTA
          final latestExpired = _latestByEndDate(subs);
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: _buildArchiveFooter(context, ref, latestExpired),
          );
        }

        // Normal / expiring 모드
        final primary = active.first;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: _buildActiveFooter(context, ref, primary),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFooter(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) {
    final total = sub.totalLessonsForDisplay;
    final used = sub.usedLessons;
    final progress =
        (total != null && total > 0) ? (used / total).clamp(0.0, 1.0) : 0.0;
    final daysLeft = sub.daysUntilExpiration;
    final barColor =
        progress >= 0.8 || (daysLeft != null && daysLeft <= 7)
            ? AppColors.paperAccent
            : AppColors.inkSecondary;

    // 진행 bar만 표시 (D-day, 레슨추가는 상세 화면에서 확인)
    if (total == null || total <= 0) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2,
            color: AppColors.inkQuaternary,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: barColor),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '$used/$total회',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveFooter(
    BuildContext context,
    WidgetRef ref,
    Subscription? latest,
  ) {
    final expiredDateText =
        latest?.endDate != null
            ? '${latest!.endDate!.year}-${latest.endDate!.month.toString().padLeft(2, '0')}-${latest.endDate!.day.toString().padLeft(2, '0')} 만료'
            : '만료됨';
    return Text(
      expiredDateText,
      style: AppTypography.captionSmall.copyWith(color: AppColors.inkTertiary),
    );
  }

  Subscription? _latestByEndDate(List<Subscription> subs) {
    final withDates =
        subs.where((s) => s.endDate != null).toList()
          ..sort((a, b) => b.endDate!.compareTo(a.endDate!));
    return withDates.isEmpty ? null : withDates.first;
  }
}
