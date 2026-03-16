import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../../profile/domain/entities/teacher.dart';
import '../../../../repositories/teacher_repository.dart';

/// Remote implementation of [TeacherRepository] using FastAPI backend.
///
/// Maps backend TeacherResponse (with nested UserResponse) to frontend Teacher entity.
/// Endpoints:
/// - GET /teachers → PaginatedResponse[TeacherResponse]
/// - GET /teachers/{id} → TeacherResponse
class RemoteTeacherRepository implements TeacherRepository {
  final ApiClient _apiClient;

  RemoteTeacherRepository(this._apiClient);

  @override
  Future<List<Teacher>> getAllTeachers() async {
    final response = await _apiClient.get('/teachers');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _teacherFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    try {
      final response = await _apiClient.get('/teachers/$id');
      return _teacherFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Teacher>> searchTeachers(TeacherFilter filter) async {
    final queryParams = <String, dynamic>{};
    if (filter.instrument != null) {
      queryParams['instrument'] = filter.instrument;
    }
    if (filter.location != null) {
      queryParams['area'] = filter.location;
    }

    final response = await _apiClient.get(
      '/teachers',
      queryParameters: queryParams,
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _teacherFromJson(json),
    );

    var results = paginated.items;

    // Apply client-side filters not supported by backend
    if (filter.onlyAvailable) {
      results = results.where((t) => t.isAvailable).toList();
    }
    if (filter.maxTrialFee != null) {
      results = results
          .where((t) => t.trialLessonFee <= filter.maxTrialFee!)
          .toList();
    }
    if (filter.minRating != null) {
      results = results
          .where((t) => t.rating != null && t.rating! >= filter.minRating!)
          .toList();
    }

    return results;
  }

  @override
  Future<List<Teacher>> getTeachersByInstrument(String instrument) async {
    final response = await _apiClient.get(
      '/teachers',
      queryParameters: {'instrument': instrument},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _teacherFromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Teacher>> getFeaturedTeachers() async {
    // Backend doesn't have a dedicated featured endpoint — use default listing
    final response = await _apiClient.get('/teachers');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _teacherFromJson(json),
    );
    return paginated.items.take(5).toList();
  }

  /// Map backend TeacherResponse (with nested UserResponse) to frontend Teacher.
  ///
  /// Backend TeacherResponse:
  ///   id, user_id, user: {id, name, profile_image_url, ...},
  ///   instruments, introduction, experience_years, fee_min, fee_max,
  ///   created_at, updated_at
  ///
  /// Frontend Teacher:
  ///   id, name, profileImageUrl, instruments, bio, experienceYears,
  ///   trialLessonFee, regularLessonFee, isAvailable, createdAt
  Teacher _teacherFromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? '선생님';
    final profileImageUrl = user?['profile_image_url'] as String?;
    final instruments = (json['instruments'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final createdAtStr = json['created_at'] as String?;

    return Teacher(
      id: json['id'] as String,
      name: name,
      profileImageUrl: profileImageUrl,
      instruments: instruments,
      bio: json['introduction'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      trialLessonFee: json['fee_min'] as int? ?? 30000,
      regularLessonFee: json['fee_max'] as int? ?? 60000,
      isAvailable: true,
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
