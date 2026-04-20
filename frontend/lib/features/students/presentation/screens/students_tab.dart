import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/presentation/providers/practice_crud_provider.dart';
import '../../domain/entities/grouped_students.dart';
import '../providers/student_crud_provider.dart';
import '../../domain/entities/student_with_membership.dart';
import '../providers/grouped_students_provider.dart';
import '../../../subscription/presentation/widgets/unified_subscription_sheet.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/practice_sparkline.dart';
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

    return Stack(
      children: [
        Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Filter chips
            _buildFilterChips(),

            const SizedBox(height: AppSpacing.space2),

            // Student count and sort
            _buildCountAndSort(groupedAsync),

            const SizedBox(height: AppSpacing.space2),

            // Grouped student list
            Expanded(
              child: groupedAsync.when(
                data: (groups) => _buildGroupedStudentList(groups),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),

            // Reserve space for bottom bar when selections exist
            if (_selectedStudentIds.isNotEmpty) const SizedBox(height: 72),
          ],
        ),

        // Bottom action bar
        if (_selectedStudentIds.isNotEmpty) _buildBottomActionBar(),
      ],
    );
  }

  List<StudentGroup> _applyPracticeFilter(List<StudentGroup> groups) {
    if (_currentFilter == StudentFilter.all) return groups;

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

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_isSelectionMode) ...[
            Text(
              '${_selectedStudentIds.length}명 선택됨',
              style: AppTypography.headingLarge,
            ),
            TextButton(
              onPressed: _exitSelectionMode,
              child: Text(
                '취소',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ] else ...[
            Text('학생 관리', style: AppTypography.headingLarge),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _isSelectionMode = true),
                  child: Text(
                    '선택',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                FilledButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.addStudentMethod);
                  },
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('학생 추가'),
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
        ],
      ),
    );
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
            color: AppColors.textTertiaryLight,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textTertiaryLight,
          ),
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
          fillColor: AppColors.surfaceSecondaryLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            borderSide: BorderSide.none,
          ),
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
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
              color: AppColors.surfaceLight,
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
                  Text('연습상태로 필터', style: AppTypography.headingSmall),
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
                                ? AppColors.primary
                                : AppColors.textTertiaryLight,
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

  Widget _buildCountAndSort(AsyncValue<List<StudentGroup>> groupedAsync) {
    final count = groupedAsync.when(
      data: (groups) {
        final filtered = _applyPracticeFilter(groups);
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
              color: AppColors.textSecondaryLight,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Text('정렬 기준', style: AppTypography.headingSmall),
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
                              ? AppColors.primary
                              : AppColors.textTertiaryLight,
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

  Widget _buildGroupedStudentList(List<StudentGroup> groups) {
    final filtered = _applySortToGroups(_applyPracticeFilter(groups));

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    // Count subjects (memberships) per student across all groups.
    // Used for `N과목` badge when student has multiple subjects.
    final subjectCounts = <String, int>{};
    for (final group in filtered) {
      for (final swm in group.students) {
        subjectCounts[swm.studentId] = (subjectCounts[swm.studentId] ?? 0) + 1;
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        final teacherId = ref.read(currentUserIdProvider);
        ref.invalidate(groupedStudentsProvider(teacherId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
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
              color: Colors.black.withValues(alpha: 0.1),
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
                  color: AppColors.textSecondaryLight,
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
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          OutlinedButton.icon(
            onPressed: () {
              final teacherId = ref.read(currentUserIdProvider);
              ref.invalidate(groupedStudentsProvider(teacherId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
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
  paused('휴강');

  final String label;
  const StudentFilter(this.label);
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
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiaryLight,
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
                ? AppColors.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border:
            isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Checkbox (selection mode only)
              if (isSelectionMode) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged(value ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],

              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  swm.initial,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
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
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                            ),
                            child: Text(
                              '$subjectCount과목',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Icon(
                          swm.isAppConnected ? Icons.link : Icons.edit_note,
                          size: 14,
                          color:
                              swm.isAppConnected
                                  ? AppColors.success
                                  : AppColors.textTertiaryLight,
                        ),
                      ],
                    ),
                    // Row 2: Schedule
                    Text(
                      swm.lessonSchedule ?? '스케줄 미등록',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
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
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiaryLight,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '미수금',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '갱신',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
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
                  color: AppColors.textTertiaryLight,
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
