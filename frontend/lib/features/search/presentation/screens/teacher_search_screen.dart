import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../models/teacher_search.dart';
import '../../../../providers/search/teacher_search_provider.dart';
import '../../../profile/presentation/providers/invite_provider.dart';

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
      final type = _tabController.index == 0
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
    ref.read(teacherSearchFilterStateProvider.notifier).updateKeyword(
          query.isEmpty ? null : query,
        );
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
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.school_outlined),
              text: '학원',
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: '개인 선생님',
            ),
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
                hintText: currentTab == TeacherSearchType.academy
                    ? '학원 이름, 악기, 지역으로 검색'
                    : '선생님 이름, 악기, 지역으로 검색',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceSecondaryLight,
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
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.textTertiaryLight),
                    const SizedBox(height: AppSpacing.space2),
                    Text('검색 중 오류가 발생했습니다',
                        style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.space2),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(teacherSearchResultsProvider.notifier).refresh(),
                      child: const Text('다시 시도'),
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
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getSortLabel(option)),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(teacherSearchSortStateProvider.notifier)
                    .updateSort(option);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
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
        chips.add(_buildFilterChip(inst, () {
          final newList = List<String>.from(filter.instruments!)..remove(inst);
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateInstruments(newList.isEmpty ? null : newList);
        }));
      }
    }

    if (filter.areas != null && filter.areas!.isNotEmpty) {
      for (final area in filter.areas!) {
        chips.add(_buildFilterChip(area, () {
          final newList = List<String>.from(filter.areas!)..remove(area);
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateAreas(newList.isEmpty ? null : newList);
        }));
      }
    }

    if (filter.lessonTypes != null && filter.lessonTypes!.isNotEmpty) {
      for (final type in filter.lessonTypes!) {
        chips.add(_buildFilterChip(_getLessonTypeOptionLabel(type), () {
          final newList = List<LessonTypeOption>.from(filter.lessonTypes!)..remove(type);
          ref
              .read(teacherSearchFilterStateProvider.notifier)
              .updateLessonTypes(newList.isEmpty ? null : newList);
        }));
      }
    }

    if (filter.hasVerifiedCertificate == true) {
      chips.add(_buildFilterChip('자격증 인증', () {
        ref
            .read(teacherSearchFilterStateProvider.notifier)
            .updateHasVerifiedCertificate(null);
      }));
    }

    if (filter.minExperience != null) {
      chips.add(_buildFilterChip('${filter.minExperience}년 이상', () {
        ref
            .read(teacherSearchFilterStateProvider.notifier)
            .updateMinExperience(null);
      }));
    }

    chips.add(
      TextButton(
        onPressed: () {
          ref.read(teacherSearchFilterStateProvider.notifier).clearFilter();
        },
        child: Text(
          '전체 해제',
          style: AppTypography.caption.copyWith(color: AppColors.primary),
        ),
      ),
    );

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: AppTypography.caption),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.info.withValues(alpha: 0.1),
        deleteIconColor: AppColors.info,
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
              isAcademyTab ? Icons.school_outlined : Icons.person_search_outlined,
              size: 64,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              isAcademyTab ? '검색된 학원이 없습니다' : '검색된 선생님이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
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
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final teacher = result.teachers[index];
        final isPreviousTeacher = previousTeacherIds.contains(teacher.id);
        return _buildTeacherCard(teacher, isPreviousTeacher: isPreviousTeacher);
      },
    );
  }

  Widget _buildTeacherCard(TeacherProfile teacher, {bool isPreviousTeacher = false}) {
    final publicProfile = TeacherPublicProfile.fromProfile(teacher);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        // Highlight previous teacher with a subtle border
        side: isPreviousTeacher
            ? BorderSide(color: AppColors.info.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.push('/teachers/${teacher.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.surfaceSecondaryLight,
                backgroundImage: publicProfile.profileImage != null
                    ? NetworkImage(publicProfile.profileImage!)
                    : null,
                child: publicProfile.profileImage == null
                    ? Icon(Icons.person,
                        size: 35, color: AppColors.textSecondaryLight)
                    : null,
              ),
              const SizedBox(width: AppSpacing.space3),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Previous teacher badge
                    if (isPreviousTeacher) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 12,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '이전에 레슨했어요',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Academy badge (if applicable)
                    if (publicProfile.isAcademy &&
                        publicProfile.organizationName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              publicProfile.organizationName!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Name and badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            publicProfile.name ?? '선생님',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...publicProfile.badges.take(2).map((badge) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              _getBadgeIcon(badge),
                              size: 18,
                              color: AppColors.primary,
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Instruments
                    Text(
                      publicProfile.instruments.join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Experience and fee
                    Row(
                      children: [
                        if (publicProfile.experienceYears != null) ...[
                          Icon(Icons.work_outline,
                              size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${publicProfile.experienceYears}년',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (publicProfile.feeRange != null) ...[
                          Icon(Icons.payments_outlined,
                              size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            publicProfile.feeRange!.formatted,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Introduction
                    Text(
                      publicProfile.introduction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),

                    const SizedBox(height: 8),

                    // Lesson areas
                    if (publicProfile.lessonAreas != null &&
                        publicProfile.lessonAreas!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            publicProfile.lessonAreas!.take(3).map((area) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              area,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          );
                        }).toList(),
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterSheet(),
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

  IconData _getBadgeIcon(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return Icons.phone_android;
      case VerificationBadge.certified:
        return Icons.verified;
      case VerificationBadge.premium:
        return Icons.star;
    }
  }
}

/// Filter bottom sheet
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TeacherSearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = ref.read(teacherSearchFilterStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final instrumentsAsync = ref.watch(availableInstrumentsProvider);
    final areasAsync = ref.watch(availableAreasProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('필터', style: AppTypography.headingSmall),
                  TextButton(
                    onPressed: () {
                      setState(() => _filter = TeacherSearchFilter.empty);
                    },
                    child: const Text('초기화'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Filter options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Instruments
                  _buildSectionTitle('악기'),
                  const SizedBox(height: 8),
                  instrumentsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('오류: $e'),
                    data: (instruments) => _buildChipSelection(
                      instruments,
                      _filter.instruments ?? [],
                      (selected) {
                        setState(() {
                          _filter = _filter.copyWith(
                            instruments: selected.isEmpty ? null : selected,
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Areas
                  _buildSectionTitle('지역'),
                  const SizedBox(height: 8),
                  areasAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('오류: $e'),
                    data: (areas) => _buildChipSelection(
                      areas,
                      _filter.areas ?? [],
                      (selected) {
                        setState(() {
                          _filter = _filter.copyWith(
                            areas: selected.isEmpty ? null : selected,
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lesson types
                  _buildSectionTitle('레슨 방식'),
                  const SizedBox(height: 8),
                  _buildLessonTypeOptionSelection(),

                  const SizedBox(height: 24),

                  // Experience
                  _buildSectionTitle('최소 경력'),
                  const SizedBox(height: 8),
                  _buildExperienceSelection(),

                  const SizedBox(height: 24),

                  // Certificate
                  SwitchListTile(
                    title: const Text('자격증 인증 선생님만'),
                    subtitle: const Text('검증된 자격증을 보유한 선생님'),
                    value: _filter.hasVerifiedCertificate ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(
                          hasVerifiedCertificate: value ? true : null,
                        );
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            // Apply button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      final notifier =
                          ref.read(teacherSearchFilterStateProvider.notifier);
                      notifier.updateInstruments(_filter.instruments);
                      notifier.updateAreas(_filter.areas);
                      notifier.updateLessonTypes(_filter.lessonTypes);
                      notifier.updateMinExperience(_filter.minExperience);
                      notifier
                          .updateHasVerifiedCertificate(_filter.hasVerifiedCertificate);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLarge),
                      ),
                    ),
                    child: const Text('필터 적용'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChipSelection(
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            final newList = List<String>.from(selected);
            if (value) {
              newList.add(option);
            } else {
              newList.remove(option);
            }
            onChanged(newList);
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildLessonTypeOptionSelection() {
    final selected = _filter.lessonTypes ?? [];
    final types = [
      (LessonTypeOption.inPerson, '대면 레슨'),
      (LessonTypeOption.online, '온라인 레슨'),
      (LessonTypeOption.visit, '방문 레슨'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((tuple) {
        final (type, label) = tuple;
        final isSelected = selected.contains(type);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (value) {
            final newList = List<LessonTypeOption>.from(selected);
            if (value) {
              newList.add(type);
            } else {
              newList.remove(type);
            }
            setState(() {
              _filter = _filter.copyWith(
                lessonTypes: newList.isEmpty ? null : newList,
              );
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildExperienceSelection() {
    final options = [null, 3, 5, 10];
    final labels = ['상관없음', '3년 이상', '5년 이상', '10년 이상'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = _filter.minExperience == options[index];
        return ChoiceChip(
          label: Text(labels[index]),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              _filter = _filter.copyWith(minExperience: options[index]);
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
        );
      }),
    );
  }
}
