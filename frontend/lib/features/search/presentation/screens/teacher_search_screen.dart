import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/profile_facade.dart';
import '../../search_facade.dart';
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
  Timer? _debounce;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = _tabController.index == 0
          ? TeacherSearchType.academy
          : TeacherSearchType.individual;
      ref.read(teacherSearchTabStateProvider.notifier).setTab(type);
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      ref
          .read(teacherSearchResultsProvider.notifier)
          .loadMore()
          .whenComplete(() => _isLoadingMore = false);
    }
  }

  void _onSearch(String query) {
    // Debounce: wait 400ms after the last keystroke before querying the API.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(teacherSearchFilterStateProvider.notifier)
          .updateKeyword(query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(teacherSearchResultsProvider);
    final filter = ref.watch(teacherSearchFilterStateProvider);
    final currentTab = ref.watch(teacherSearchTabStateProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.searchFindTeacher,
        customActions: [
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
            Tab(
              icon: Icon(Icons.school_outlined),
              text: AppStrings.searchTabAcademy,
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: AppStrings.searchTabIndividual,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Context hint
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.screenPadding,
              bottom: AppSpacing.space2,
            ),
            child: Text(
              AppStrings.searchContextHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: currentTab == TeacherSearchType.academy
                    ? AppStrings.searchHintAcademy
                    : AppStrings.searchHintTeacher,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
              error: (e, _) => Center(
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
                      AppStrings.searchErrorOccurred,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(teacherSearchResultsProvider.notifier)
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
        children: TeacherSortOption.values.map((option) {
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
              selectedColor: AppColors.paperAccentSoft,
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
        _buildFilterChip(AppStrings.verificationBadgeCertifiedLabel, () {
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateHasVerifiedCertificate(null);
        }),
      );
    }

    if (filter.minExperience != null) {
      chips.add(
        _buildFilterChip(
          AppStrings.searchExperienceYears(filter.minExperience!),
          () {
            ref
                .read(teacherSearchFilterStateProvider.notifier)
                .updateMinExperience(null);
          },
        ),
      );
    }

    chips.add(
      TextButton(
        onPressed: () {
          ref.read(teacherSearchFilterStateProvider.notifier).clearFilter();
        },
        child: Text(
          AppStrings.searchClearAllFilters,
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
    final filter = ref.watch(teacherSearchFilterStateProvider);

    if (result.teachers.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active filters in empty state
                if (!filter.isEmpty) _buildActiveFilters(filter),
                // Empty state message
                Center(
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
                        isAcademyTab
                            ? AppStrings.searchNoAcademiesFound
                            : AppStrings.searchNoTeachersFound,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        AppStrings.searchTrySuggestion,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TeacherSearchFilterSheet(),
    );
  }

  String _getSortLabel(TeacherSortOption option) {
    switch (option) {
      case TeacherSortOption.relevance:
        return AppStrings.sortRelevance;
      case TeacherSortOption.experienceDesc:
        return AppStrings.sortExperienceDesc;
      case TeacherSortOption.experienceAsc:
        return AppStrings.sortExperienceAsc;
      case TeacherSortOption.feeAsc:
        return AppStrings.sortFeeAsc;
      case TeacherSortOption.feeDesc:
        return AppStrings.sortFeeDesc;
      case TeacherSortOption.rating:
        return AppStrings.sortRating;
      case TeacherSortOption.completionLevel:
        return AppStrings.sortCompletionLevel;
    }
  }

  String _getLessonTypeOptionLabel(LessonTypeOption type) {
    switch (type) {
      case LessonTypeOption.inPerson:
        return AppStrings.lessonTypeInPerson;
      case LessonTypeOption.online:
        return AppStrings.lessonTypeOnline;
      case LessonTypeOption.visit:
        return AppStrings.lessonTypeVisit;
    }
  }
}
