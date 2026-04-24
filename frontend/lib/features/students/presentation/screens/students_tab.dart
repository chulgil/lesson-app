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
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/presentation/providers/practice_crud_provider.dart';
import '../../domain/entities/grouped_students.dart';
import '../../domain/entities/roster_summary.dart';
import '../providers/student_crud_provider.dart';
import '../providers/student_roster_summary_provider.dart';
import '../../domain/entities/student_with_membership.dart';
import '../providers/grouped_students_provider.dart';
import '../../../subscription/presentation/widgets/unified_subscription_sheet.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/practice_sparkline.dart';
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
                  ),
                ),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterChips()),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedStudentIds.length}명 선택됨',
              style: AppTypography.headingLarge,
            ),
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
          // ── Masthead: "ENROLLMENTS" eyebrow + 수강 추가 아이콘 ──
          NotebookMasthead(
            eyebrow: 'ENROLLMENTS',
            meta: _volumeIssueString(DateTime.now()),
            trailing: IconButton(
              onPressed: () => setState(() => _isSelectionMode = true),
              icon: const Icon(
                Icons.check_box_outlined,
                color: AppColors.ink,
                size: 22,
              ),
              tooltip: '선택',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                Text('수강 관리', style: NotebookTypography.masthead),
                const SizedBox(height: AppSpacing.space3),
                const ThinRule(),
              ],
            ),
          ),
          // ── 액션 Row — 학생 추가 ──
          // 테마 FilledButton.minimumSize 가 Size(∞, 48) 이라 Row+end 단독 자식 배치시
          // BoxConstraints(w=Infinity) 크래시. 컴팩트 트레일링 버튼이므로 minWidth 0 으로 override.
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space2,
              bottom: AppSpacing.space2,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  context.push(AppRoutes.addStudentMethod);
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('학생 추가'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space2,
                  ),
                ),
              ),
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
          ref.read(studentSearchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: '학생 이름 또는 악기로 검색',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.inkTertiary),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(studentSearchQueryProvider.notifier).state = '';
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

  /// 1줄 세그먼트 (학원/개인/전체) + 필터 버튼 (바텀시트로 연습상태)
  /// ux_guidelines §2.6 (Progressive Disclosure) 적용
  Widget _buildFilterChips() {
    final classTypeFilter = ref.watch(classTypeFilterNotifierProvider);
    final hasActiveFilter = _currentFilter != StudentFilter.all;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Segmented button (학원 / 개인 / 전체)
          Expanded(
            child: SegmentedButton<ClassTypeFilter>(
              segments:
                  ClassTypeFilter.values
                      .map(
                        (filter) => ButtonSegment<ClassTypeFilter>(
                          value: filter,
                          label: Text(
                            filter.label,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
              selected: {classTypeFilter},
              onSelectionChanged: (selection) {
                ref
                    .read(classTypeFilterNotifierProvider.notifier)
                    .set(selection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),

          // 필터 버튼 (연습상태) → 바텀시트
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune,
                  color:
                      hasActiveFilter
                          ? AppColors.paperAccent
                          : AppColors.inkSecondary,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.paperAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showPracticeFilterSheet,
            tooltip: '연습상태 필터',
          ),
        ],
      ),
    );
  }

  /// 연습상태 필터 바텀시트 (전체/우수/보통/부족/휴강)
  Future<void> _showPracticeFilterSheet() async {
    final selected = await showModalBottomSheet<StudentFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLarge),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                  // (§7.27). '필터' 는 정적 명사 헤더 — 연습/수강 상태 통합.
                  Text('필터', style: NotebookTypography.appBarTitle),
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
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(filter),
                    );
                  }),
                ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '전체 $count명',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                  // (§7.27). '정렬 기준' 은 정적 명사 헤더.
                  child: Text('정렬 기준', style: NotebookTypography.appBarTitle),
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
    final teacherId = ref.watch(currentUserIdProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '${_selectedStudentIds.length}명 선택됨',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  UnifiedSubscriptionSheet.show(
                    context,
                    teacherId: teacherId,
                    studentIds: _selectedStudentIds.toList(),
                  );
                },
                child: const Text('수강권 발급'),
              ),
            ],
          ),
        ),
      ),
    );
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
  unpaid('미결제'),
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
                ? AppColors.paperAccent.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
        border:
            isSelected
                ? Border.all(
                  color: AppColors.paperAccent.withValues(alpha: 0.3),
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
        backgroundColor: AppColors.paperAccent.withValues(alpha: 0.1),
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
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent.withValues(alpha: 0.1),
                    ),
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
            // Row 3: Weekly practice dots
            _PracticeDots(studentId: swm.studentId),
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
        // Unpaid takes highest priority
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
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.paperAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '미수금',
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

        final hasExpiring = subscriptions.any((s) => s.isExpiringSoon);
        if (hasExpiring) {
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
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.paperAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '갱신',
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

/// Weekly practice dot pattern (●●●●●○○ style).
/// Practice trend sparkline for student list (ux_guidelines §2.7).
///
/// Replaces old _PracticeDots with 7-day bar sparkline.
class _PracticeDots extends ConsumerWidget {
  final String studentId;

  const _PracticeDots({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyPracticeProvider(studentId));

    return weeklyAsync.when(
      data: (days) {
        // Convert bool[] → double[] (1.0 if practiced, 0.0 otherwise)
        final values = days.map((d) => d ? 1.0 : 0.0).toList();
        if (values.length != 7) {
          // Pad or trim to 7 values
          while (values.length < 7) {
            values.insert(0, 0.0);
          }
          if (values.length > 7) {
            values.removeRange(0, values.length - 7);
          }
        }

        final practiced = days.where((d) => d).length;

        return Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              PracticeSparkline(values: values),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '$practiced/7일',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Student card 의 수강권 확장 영역 — 진행 bar + D-day + 인라인 CTA.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.3
///
/// 3가지 모드:
/// - normal  : 진행 bar + D-day + [갱신 제안][레슨 추가]
/// - expiring: D-day 강조 색상 + [갱신 제안][레슨 추가]
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 진행 bar (2px)
        if (total != null && total > 0) ...[
          Row(
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
          ),
          const SizedBox(height: AppSpacing.space1),
        ],
        // D-day chip + CTA row
        Row(
          children: [
            if (daysLeft != null) _DdayChip(daysLeft: daysLeft),
            const Spacer(),
            _InlineCta(
              label: '갱신 제안',
              onTap: () {
                UnifiedSubscriptionSheet.show(
                  context,
                  teacherId: '',
                  studentIds: [studentId],
                );
              },
            ),
            const SizedBox(width: AppSpacing.space2),
            _InlineCta(
              label: '레슨 추가',
              onTap: () {
                context.push('${AppRoutes.addLesson}?studentId=$studentId');
              },
            ),
          ],
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
    return Row(
      children: [
        Text(
          expiredDateText,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
        const Spacer(),
        _InlineCta(
          label: '재등록 제안',
          onTap: () {
            final teacherId = ref.read(currentUserIdProvider);
            UnifiedSubscriptionSheet.show(
              context,
              teacherId: teacherId,
              studentIds: [studentId],
            );
          },
        ),
      ],
    );
  }

  Subscription? _latestByEndDate(List<Subscription> subs) {
    final withDates =
        subs.where((s) => s.endDate != null).toList()
          ..sort((a, b) => b.endDate!.compareTo(a.endDate!));
    return withDates.isEmpty ? null : withDates.first;
  }
}

class _DdayChip extends StatelessWidget {
  final int daysLeft;

  const _DdayChip({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    if (daysLeft > 14) return const SizedBox.shrink();

    final Color color;
    if (daysLeft <= 0) {
      color = AppColors.paperAccent;
    } else if (daysLeft <= 7) {
      color = AppColors.paperAccent;
    } else {
      color = AppColors.inkSecondary;
    }

    final label = daysLeft <= 0 ? '만료' : 'D-$daysLeft 만료';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _InlineCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.ink,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
