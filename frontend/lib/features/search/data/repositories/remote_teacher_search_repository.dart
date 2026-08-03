import '../../../../core/network/api_client.dart';
import '../../domain/repositories/teacher_search_repository.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/domain/entities/teacher_search.dart';

/// Remote implementation of [TeacherSearchRepository] using FastAPI backend.
///
/// Maps backend TeacherResponse to frontend TeacherProfile/TeacherPublicProfile.
/// Core endpoints:
/// - GET /teachers → searchTeachers, getFeaturedTeachers
/// - GET /teachers/{id} → getTeacherPublicProfile, getTeacherFullProfile
class RemoteTeacherSearchRepository implements TeacherSearchRepository {
  final ApiClient _apiClient;

  RemoteTeacherSearchRepository(this._apiClient);

  @override
  Future<TeacherSearchResult> searchTeachers({
    TeacherSearchFilter filter = TeacherSearchFilter.empty,
    TeacherSortOption sort = TeacherSortOption.relevance,
    int page = 0,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page + 1, // Backend uses 1-based pagination
      'per_page': pageSize,
    };

    if (filter.keyword != null && filter.keyword!.isNotEmpty) {
      queryParams['q'] = filter.keyword;
    }
    if (filter.instruments != null && filter.instruments!.isNotEmpty) {
      queryParams['instrument'] = filter.instruments!.first;
    }
    if (filter.areas != null && filter.areas!.isNotEmpty) {
      queryParams['area'] = filter.areas!.first;
    }

    final response = await _apiClient.get(
      '/teachers',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final total = data['total'] as int? ?? 0;

    var profiles = items
        .map((json) => _profileFromJson(json as Map<String, dynamic>))
        .toList();

    // Apply client-side filters not supported by backend
    if (filter.teacherType != null) {
      profiles = profiles.where((p) {
        return filter.teacherType == TeacherSearchType.academy
            ? p.isAcademy
            : p.isIndividual;
      }).toList();
    }

    if (filter.minExperience != null) {
      profiles = profiles
          .where((p) => (p.experienceYears ?? 0) >= filter.minExperience!)
          .toList();
    }

    if (filter.hasVerifiedCertificate == true) {
      profiles = profiles
          .where((p) => p.verification.hasVerifiedCertificate)
          .toList();
    }

    // Apply sorting
    switch (sort) {
      case TeacherSortOption.experienceDesc:
        profiles.sort((a, b) =>
            (b.experienceYears ?? 0).compareTo(a.experienceYears ?? 0));
        break;
      case TeacherSortOption.experienceAsc:
        profiles.sort((a, b) =>
            (a.experienceYears ?? 0).compareTo(b.experienceYears ?? 0));
        break;
      case TeacherSortOption.feeAsc:
        profiles.sort((a, b) =>
            (a.feeRange?.minFee ?? 0).compareTo(b.feeRange?.minFee ?? 0));
        break;
      case TeacherSortOption.feeDesc:
        profiles.sort((a, b) =>
            (b.feeRange?.minFee ?? 0).compareTo(a.feeRange?.minFee ?? 0));
        break;
      case TeacherSortOption.completionLevel:
        profiles.sort((a, b) =>
            b.completionPercentage.compareTo(a.completionPercentage));
        break;
      case TeacherSortOption.relevance:
      case TeacherSortOption.rating:
        break;
    }

    return TeacherSearchResult(
      teachers: profiles,
      totalCount: total,
      page: page,
      pageSize: pageSize,
      hasMore: (page + 1) * pageSize < total,
    );
  }

  @override
  Future<TeacherPublicProfile?> getTeacherPublicProfile(
    String teacherId,
  ) async {
    try {
      final response = await _apiClient.get('/teachers/$teacherId');
      final profile = _profileFromJson(
        response.data as Map<String, dynamic>,
      );
      return TeacherPublicProfile.fromProfile(profile);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeacherProfile?> getTeacherFullProfile(String teacherId) async {
    try {
      final response = await _apiClient.get('/teachers/$teacherId');
      return _profileFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TeacherPublicProfile>> getFeaturedTeachers({
    int limit = 10,
  }) async {
    final response = await _apiClient.get('/teachers');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .take(limit)
        .map((json) => _profileFromJson(json as Map<String, dynamic>))
        .map((p) => TeacherPublicProfile.fromProfile(p))
        .toList();
  }

  @override
  Future<List<String>> getAvailableInstruments() async {
    // Derive from teacher list
    final response = await _apiClient.get('/teachers');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final instruments = <String>{};
    for (final json in items) {
      final list = (json as Map<String, dynamic>)['instruments'] as List<dynamic>?;
      if (list != null) {
        instruments.addAll(list.cast<String>());
      }
    }
    return instruments.toList()..sort();
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    // Backend doesn't have areas in TeacherResponse — return empty
    return [];
  }

  @override
  Future<AcademyInfo?> getAcademyInfo(String organizationId) async {
    // Academy concept not in backend yet
    return null;
  }

  @override
  Future<List<TeacherPublicProfile>> getTeachersByOrganization(
    String organizationId,
  ) async {
    // Academy concept not in backend yet
    return [];
  }

  @override
  Future<List<AcademyInfo>> getAllAcademies() async {
    // Academy concept not in backend yet
    return [];
  }

  /// Map backend TeacherResponse to frontend TeacherProfile.
  TeacherProfile _profileFromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? '선생님';
    final profileImage = user?['profile_image_url'] as String?;
    final userId = json['user_id'] as String? ?? '';
    final instruments = (json['instruments'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final lessonTypes = (json['lesson_types'] as List<dynamic>?)
            ?.map((e) {
              switch (e as String) {
                case 'in_person':
                  return LessonTypeOption.inPerson;
                case 'online':
                  return LessonTypeOption.online;
                case 'visit':
                  return LessonTypeOption.visit;
                default:
                  return LessonTypeOption.inPerson;
              }
            })
            .toList() ??
        [];
    final feeMin = json['fee_min'] as int?;
    final feeMax = json['fee_max'] as int?;
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;

    return TeacherProfile(
      id: json['id'] as String,
      userId: userId,
      name: name,
      nickname: json['nickname'] as String?,
      profileImage: profileImage,
      instruments: instruments,
      introduction: json['introduction'] as String? ?? '',
      experienceYears: json['experience_years'] as int?,
      lessonTypes: lessonTypes,
      feeRange: (feeMin != null || feeMax != null)
          ? FeeRange(minFee: feeMin ?? 0, maxFee: feeMax ?? 0)
          : null,
      teachingStyle: json['teaching_style'] as String?,
      verification: const TeacherVerification(),
      visibilitySettings: const ProfileVisibilitySettings(),
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr)
          : null,
    );
  }
}
