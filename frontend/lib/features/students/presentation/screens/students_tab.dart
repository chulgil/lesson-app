import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/student.dart';
import '../../../../providers/providers.dart';
import '../widgets/student_subscription_badge.dart';

/// Students management tab with Riverpod state management
class StudentsTab extends ConsumerStatefulWidget {
  const StudentsTab({super.key});

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  final _searchController = TextEditingController();
  StudentFilter _currentFilter = StudentFilter.all;
  ClassTypeFilter _classTypeFilter = ClassTypeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsNotifierProvider);

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
        _buildCountAndSort(studentsAsync),

        const SizedBox(height: AppSpacing.space2),

        // Student list
        Expanded(
          child: studentsAsync.when(
            data: (students) => _buildStudentList(students),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  List<Student> _filterStudents(List<Student> students) {
    final query = ref.watch(studentSearchQueryProvider).toLowerCase();
    var filtered = students;

    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(query) ||
              s.instrument.toLowerCase().contains(query))
          .toList();
    }

    // Apply status filter
    if (_currentFilter != StudentFilter.all) {
      filtered = filtered.where((s) {
        switch (_currentFilter) {
          case StudentFilter.all:
            return true;
          case StudentFilter.good:
            return s.practiceStatus == PracticeStatus.good;
          case StudentFilter.normal:
            return s.practiceStatus == PracticeStatus.normal;
          case StudentFilter.poor:
            return s.practiceStatus == PracticeStatus.poor;
          case StudentFilter.paused:
            return s.practiceStatus == PracticeStatus.paused;
        }
      }).toList();
    }

    return filtered;
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
              context.push('/students/add-method');
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textTertiaryLight),
          suffixIcon: _searchController.text.isNotEmpty
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Class type filters (학원/개인)
          ...ClassTypeFilter.values.map((filter) {
            final isSelected = _classTypeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: FilterChip(
                avatar: filter == ClassTypeFilter.academy
                    ? const Text('🏫', style: TextStyle(fontSize: 12))
                    : filter == ClassTypeFilter.private
                        ? const Text('👤', style: TextStyle(fontSize: 12))
                        : null,
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _classTypeFilter = filter),
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.info.withValues(alpha: 0.15),
                checkmarkColor: AppColors.info,
                side: BorderSide(
                  color: isSelected ? AppColors.info : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected
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
                  color: isSelected
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

  Widget _buildCountAndSort(AsyncValue<List<Student>> studentsAsync) {
    final count = studentsAsync.when(
      data: (students) => _filterStudents(students).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
            onPressed: () {
              // TODO: Sort options
            },
            icon: const Icon(Icons.sort, size: 18),
            label: const Text('정렬'),
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

  Widget _buildStudentList(List<Student> students) {
    final filtered = _filterStudents(students);

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentsNotifierProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
        itemBuilder: (context, index) {
          return _StudentCard(student: filtered[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(studentSearchQueryProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            query.isNotEmpty ? '검색 결과가 없습니다' : '아직 등록된 학생이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
              child: Text(
                '학생을 초대하면 정보가 자동으로\n등록되어 편리하게 관리할 수 있어요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
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
              ref.invalidate(studentsNotifierProvider);
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

class _StudentCard extends ConsumerWidget {
  final Student student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          context.push('/students/${student.id}');
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Avatar (fixed width, 같은 위치에 정렬)
              SizedBox(
                width: 52,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    student.initial,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Info section (flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name · Instrument (레슨 카드와 동일 패턴)
                    Text(
                      '${student.name} · ${student.instrument}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Row 2: Schedule (레슨 카드의 곡명 위치와 동일)
                    Text(
                      student.lessonSchedule ?? '스케줄 미등록',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status section (fixed width, 레슨 카드와 동일)
              SizedBox(
                width: 56,
                child: StudentSubscriptionMiniBadge(studentId: student.id),
              ),

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
}
