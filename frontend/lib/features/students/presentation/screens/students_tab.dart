import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/student.dart';
import '../../../../providers/providers.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../domain/entities/grouped_students.dart';
import '../../domain/entities/student_with_membership.dart';
import '../providers/grouped_students_provider.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/student_subscription_badge.dart';

/// Students management tab with Riverpod state management
class StudentsTab extends ConsumerStatefulWidget {
  const StudentsTab({super.key});

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

enum StudentSortOption {
  name('이름순'),
  instrument('악기순');

  final String label;
  const StudentSortOption(this.label);
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  final _searchController = TextEditingController();
  StudentFilter _currentFilter = StudentFilter.all;
  StudentSortOption _sortOption = StudentSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final groupedAsync = ref.watch(filteredGroupedStudentsProvider(teacherId));

    return Column(
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('학생 관리', style: AppTypography.headingLarge),
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

  Widget _buildFilterChips() {
    final classTypeFilter = ref.watch(classTypeFilterNotifierProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Class type filters
          ...ClassTypeFilter.values.map((filter) {
            final isSelected = classTypeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: FilterChip(
                avatar:
                    filter == ClassTypeFilter.academy
                        ? const Text('🏫', style: TextStyle(fontSize: 12))
                        : filter == ClassTypeFilter.private
                        ? const Text('👤', style: TextStyle(fontSize: 12))
                        : null,
                label: Text(filter.label),
                selected: isSelected,
                onSelected:
                    (_) => ref
                        .read(classTypeFilterNotifierProvider.notifier)
                        .set(filter),
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.info.withValues(alpha: 0.15),
                checkmarkColor: AppColors.info,
                side: BorderSide(
                  color: isSelected ? AppColors.info : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected
                          ? AppColors.info
                          : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),

          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            color: AppColors.borderLight,
          ),

          // Practice status filters
          ...StudentFilter.values.map((filter) {
            final isSelected = _currentFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _currentFilter = filter),
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
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
      builder: (context) => SafeArea(
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
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textTertiaryLight,
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
      }
      return StudentGroup(
        lessonClass: group.lessonClass,
        students: sorted,
      );
    }).toList();
  }

  Widget _buildGroupedStudentList(List<StudentGroup> groups) {
    final filtered = _applySortToGroups(_applyPracticeFilter(groups));

    if (filtered.isEmpty) {
      return _buildEmptyState();
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
          return _ClassGroupSection(group: filtered[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(studentSearchQueryProvider);

    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: query.isNotEmpty ? '검색 결과가 없습니다' : '아직 등록된 학생이 없습니다',
      subtitle: query.isEmpty
          ? '학생을 초대하면 정보가 자동으로\n등록되어 편리하게 관리할 수 있어요'
          : null,
      actionLabel: query.isEmpty ? '학생 추가' : null,
      actionIcon: query.isEmpty ? Icons.person_add : null,
      onAction: query.isEmpty ? () => context.push(AppRoutes.addStudentMethod) : null,
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

  const _ClassGroupSection({required this.group});

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
              child: _StudentCard(studentWithMembership: swm),
            ),
          ),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final StudentWithMembership studentWithMembership;

  const _StudentCard({required this.studentWithMembership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swm = studentWithMembership;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.studentDetail.replaceFirst(':id', swm.studentId));
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
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
                    // Row 1: Name · Instrument + connection badge
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
                        const SizedBox(width: 4),
                        Icon(
                          swm.isAppConnected ? Icons.link : Icons.edit_note,
                          size: 14,
                          color: swm.isAppConnected
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
              _buildSubscriptionStatus(context, ref, swm.studentId),

              const SizedBox(width: AppSpacing.space1),

              // Arrow
              const Icon(
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

  Widget _buildSubscriptionStatus(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final subscriptionsAsync =
        ref.watch(activeStudentSubscriptionsProvider(studentId));

    return subscriptionsAsync.when(
      data: (subscriptions) {
        // Unpaid takes highest priority
        final hasUnpaid = subscriptions.any((s) => s.isUnpaid);
        if (hasUnpaid) {
          return SizedBox(
            width: 56,
            child: GestureDetector(
              onTap: () => context.push(
                '${AppRoutes.issueSubscription}?studentId=$studentId',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '미수금',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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
              onTap: () => context.push(
                '${AppRoutes.issueSubscription}?studentId=$studentId',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '갱신',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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
class _PracticeDots extends ConsumerWidget {
  final String studentId;

  const _PracticeDots({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyPracticeProvider(studentId));

    return weeklyAsync.when(
      data: (days) {
        final practiced = days.where((d) => d).length;
        return Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              ...days.map((done) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: done
                          ? AppColors.practiceGood
                          : AppColors.borderLight,
                    ),
                  )),
              const SizedBox(width: 4),
              Text(
                '$practiced/${days.length}일',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 10,
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
