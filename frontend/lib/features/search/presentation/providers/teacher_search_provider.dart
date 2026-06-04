import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../data/repositories/mock_teacher_search_repository.dart';
import '../../data/repositories/remote_teacher_search_repository.dart';
import '../../domain/repositories/teacher_search_repository.dart';

part 'teacher_search_provider.g.dart';

/// Provider for teacher search repository - switches between Mock and Remote.
@Riverpod(keepAlive: true)
TeacherSearchRepository teacherSearchRepository(Ref ref) =>
    createRepository<TeacherSearchRepository>(
      ref: ref,
      mock: () => MockTeacherSearchRepository(),
      remote: (api) => RemoteTeacherSearchRepository(api),
    );

/// Current search tab state (academy vs individual)
@riverpod
class TeacherSearchTabState extends _$TeacherSearchTabState {
  @override
  TeacherSearchType build() {
    return TeacherSearchType.academy; // Default to academy tab
  }

  void setTab(TeacherSearchType type) {
    state = type;
  }
}

/// Current search filter state
@riverpod
class TeacherSearchFilterState extends _$TeacherSearchFilterState {
  @override
  TeacherSearchFilter build() {
    // Watch tab state and apply teacherType to filter
    final tabType = ref.watch(teacherSearchTabStateProvider);
    return TeacherSearchFilter(teacherType: tabType);
  }

  void updateKeyword(String? keyword) {
    state = state.copyWith(keyword: keyword);
  }

  void updateInstruments(List<String>? instruments) {
    state = state.copyWith(instruments: instruments);
  }

  void updateAreas(List<String>? areas) {
    state = state.copyWith(areas: areas);
  }

  void updateLessonTypes(List<LessonType>? types) {
    state = state.copyWith(lessonTypes: types);
  }

  void updateFeeRange({int? minFee, int? maxFee}) {
    state = state.copyWith(minFee: minFee, maxFee: maxFee);
  }

  void updateMinExperience(int? years) {
    state = state.copyWith(minExperience: years);
  }

  void updateHasVerifiedCertificate(bool? value) {
    state = state.copyWith(hasVerifiedCertificate: value);
  }

  /// 최소 프로필 완성도 (`TeacherProfile.completionLevel` 비교용).
  /// search_master.md §39-42 — 2026-06-04 wiring.
  void updateMinCompletionLevel(ProfileCompletionLevel? level) {
    state = state.copyWith(minCompletionLevel: level);
  }

  void clearFilter() {
    // Preserve teacherType when clearing filter
    final tabType = ref.read(teacherSearchTabStateProvider);
    state = TeacherSearchFilter(teacherType: tabType);
  }

  void clearKeyword() {
    state = state.clearKeyword();
  }
}

/// Current sort option
@riverpod
class TeacherSearchSortState extends _$TeacherSearchSortState {
  @override
  TeacherSortOption build() {
    return TeacherSortOption.relevance;
  }

  void updateSort(TeacherSortOption sort) {
    state = sort;
  }
}

/// Search results provider
@riverpod
class TeacherSearchResults extends _$TeacherSearchResults {
  @override
  Future<TeacherSearchResult> build() async {
    final filter = ref.watch(teacherSearchFilterStateProvider);
    final sort = ref.watch(teacherSearchSortStateProvider);
    final repo = ref.watch(teacherSearchRepositoryProvider);

    return repo.searchTeachers(
      filter: filter,
      sort: sort,
      page: 0,
      pageSize: 20,
    );
  }

  Future<void> loadMore() async {
    final currentResult = state.valueOrNull;
    if (currentResult == null || !currentResult.hasMore) return;

    final filter = ref.read(teacherSearchFilterStateProvider);
    final sort = ref.read(teacherSearchSortStateProvider);
    final repo = ref.read(teacherSearchRepositoryProvider);

    final nextResult = await repo.searchTeachers(
      filter: filter,
      sort: sort,
      page: currentResult.page + 1,
      pageSize: currentResult.pageSize,
    );

    state = AsyncValue.data(
      TeacherSearchResult(
        teachers: [...currentResult.teachers, ...nextResult.teachers],
        totalCount: nextResult.totalCount,
        page: nextResult.page,
        pageSize: nextResult.pageSize,
        hasMore: nextResult.hasMore,
      ),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Teacher public profile provider
@riverpod
Future<TeacherPublicProfile?> teacherPublicProfile(
  Ref ref,
  String teacherId,
) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getTeacherPublicProfile(teacherId);
}

/// Teacher full profile provider (for connected students - includes bank account)
@riverpod
Future<TeacherProfile?> teacherFullProfile(Ref ref, String teacherId) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getTeacherFullProfile(teacherId);
}

/// Featured teachers provider
@riverpod
Future<List<TeacherPublicProfile>> featuredTeachers(Ref ref) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getFeaturedTeachers(limit: 5);
}

/// Available instruments for filter
@riverpod
Future<List<String>> availableInstruments(Ref ref) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getAvailableInstruments();
}

/// Available areas for filter
@riverpod
Future<List<String>> availableAreas(Ref ref) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getAvailableAreas();
}

/// Academy info provider - get academy details by organization ID
@riverpod
Future<AcademyInfo?> academyInfo(Ref ref, String organizationId) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getAcademyInfo(organizationId);
}

/// Academy teachers provider - get all teachers in an academy
@riverpod
Future<List<TeacherPublicProfile>> academyTeachers(
  Ref ref,
  String organizationId,
) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getTeachersByOrganization(organizationId);
}

/// All academies provider - get list of all academies
@riverpod
Future<List<AcademyInfo>> allAcademies(Ref ref) async {
  final repo = ref.watch(teacherSearchRepositoryProvider);
  return repo.getAllAcademies();
}
