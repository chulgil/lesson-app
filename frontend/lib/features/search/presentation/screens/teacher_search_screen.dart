import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../../features/search/presentation/providers/teacher_search_provider.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/presentation/providers/invite_provider.dart';
import '../widgets/teacher_search_card.dart';
import '../widgets/teacher_search_filter_sheet.dart';

/// Screen for searching teachers
class TeacherSearchScreen extends ConsumerStatefulWidget {
  const TeacherSearchScreen({super.key});

  @override
  ConsumerState<TeacherSearchScreen> createState() =>
      _TeacherSearchScreenState();
}

class _TeacherSearchScreenState extends ConsumerState<TeacherSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type =
          _tabController.index == 0
              ? TeacherSearchType.academy
              : TeacherSearchType.individual;
      ref.read(teacherSearchTabStateProvider.notifier).setTab(type);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(teacherSearchResultsProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref
        .read(teacherSearchFilterStateProvider.notifier)
        .updateKeyword(query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(teacherSearchResultsProvider);
    final filter = ref.watch(teacherSearchFilterStateProvider);
    final currentTab = ref.watch(teacherSearchTabStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('선생님 찾기'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !filter.isEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.paperAccent,
          labelColor: AppColors.paperAccent,
          unselectedLabelColor: AppColors.inkSecondary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: '학원'),
            Tab(icon: Icon(Icons.person_outline), text: '개인 선생님'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    currentTab == TeacherSearchType.academy
                        ? '학원 이름, 악기, 지역으로 검색'
                        : '선생님 이름, 악기, 지역으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.paperAccent,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.paperDark,
              ),
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Sort options
          _buildSortBar(),

          // Active filters
          if (!filter.isEmpty) _buildActiveFilters(filter),

          // Search results
          Expanded(
            child: searchResult.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.inkTertiary,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          '검색 중 오류가 발생했습니다',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        teacherSearchResultsProvider.notifier,
                                      )
                                      .refresh(),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
              data: (result) => _buildResults(result),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    final sort = ref.watch(teacherSearchSortStateProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            TeacherSortOption.values.map((option) {
              final isSelected = sort == option;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: FilterChip(
                  label: Text(_getSortLabel(option)),
                  selected: isSelected,
                  onSelected: (_) {
                    ref
                        .read(teacherSearchSortStateProvider.notifier)
                        .updateSort(option);
                  },
                  selectedColor: AppColors.paperAccent.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.paperAccent,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildActiveFilters(TeacherSearchFilter filter) {
    final chips = <Widget>[];

    if (filter.instruments != null && filter.instruments!.isNotEmpty) {
      for (final inst in filter.instruments!) {
        chips.add(
          _buildFilterChip(inst, () {
            final newList = List<String>.from(filter.instruments!)
              ..remove(inst);
            ref
                .read(teacherSearchFilterStateProvider.notifier)
                .updateInstruments(newList.isEmpty ? null : newList);
          }),
        );
      }
    }

    if (filter.areas != null && filter.areas!.isNotEmpty) {
      for (final area in filter.areas!) {
        chips.add(
          _buildFilterChip(area, () {
            final newList = List<String>.from(filter.areas!)..remove(area);
            ref
                .read(teacherSearchFilterStateProvider.notifier)
                .updateAreas(newList.isEmpty ? null : newList);
          }),
        );
      }
    }

    if (filter.lessonTypes != null && filter.lessonTypes!.isNotEmpty) {
      for (final type in filter.lessonTypes!) {
        chips.add(
          _buildFilterChip(_getLessonTypeOptionLabel(type), () {
            final newList = List<LessonTypeOption>.from(filter.lessonTypes!)
              ..remove(type);
            ref
                .read(teacherSearchFilterStateProvider.notifier)
                .updateLessonTypes(newList.isEmpty ? null : newList);
          }),
        );
      }
    }

    if (filter.hasVerifiedCertificate == true) {
      chips.add(
        _buildFilterChip('자격증 인증', () {
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateHasVerifiedCertificate(null);
        }),
      );
    }

    if (filter.minExperience != null) {
      chips.add(
        _buildFilterChip('${filter.minExperience}년 이상', () {
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateMinExperience(null);
        }),
      );
    }

    chips.add(
      TextButton(
        onPressed: () {
          ref.read(teacherSearchFilterStateProvider.notifier).clearFilter();
        },
        child: Text(
          '전체 해제',
          style: AppTypography.caption.copyWith(color: AppColors.paperAccent),
        ),
      ),
    );

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.space2),
      child: Chip(
        label: Text(label, style: AppTypography.caption),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.ink.withValues(alpha: 0.1),
        deleteIconColor: AppColors.ink,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildResults(TeacherSearchResult result) {
    final currentTab = ref.watch(teacherSearchTabStateProvider);
    final isAcademyTab = currentTab == TeacherSearchType.academy;
    final previousTeacherIdsAsync = ref.watch(previousTeacherIdsProvider);

    if (result.teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAcademyTab
                  ? Icons.school_outlined
                  : Icons.person_search_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              isAcademyTab ? '검색된 학원이 없습니다' : '검색된 선생님이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Get previous teacher IDs for marking
    final previousTeacherIds = previousTeacherIdsAsync.valueOrNull ?? {};

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: result.teachers.length + (result.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == result.teachers.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final teacher = result.teachers[index];
        final isPreviousTeacher = previousTeacherIds.contains(teacher.id);
        return TeacherSearchCard(
          teacher: teacher,
          isPreviousTeacher: isPreviousTeacher,
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TeacherSearchFilterSheet(),
    );
  }

  String _getSortLabel(TeacherSortOption option) {
    switch (option) {
      case TeacherSortOption.relevance:
        return '관련도순';
      case TeacherSortOption.experienceDesc:
        return '경력 높은순';
      case TeacherSortOption.experienceAsc:
        return '경력 낮은순';
      case TeacherSortOption.feeAsc:
        return '레슨료 낮은순';
      case TeacherSortOption.feeDesc:
        return '레슨료 높은순';
      case TeacherSortOption.rating:
        return '평점순';
      case TeacherSortOption.completionLevel:
        return '프로필 완성도순';
    }
  }

  String _getLessonTypeOptionLabel(LessonTypeOption type) {
    switch (type) {
      case LessonTypeOption.inPerson:
        return '대면';
      case LessonTypeOption.online:
        return '온라인';
      case LessonTypeOption.visit:
        return '방문';
    }
  }
}
