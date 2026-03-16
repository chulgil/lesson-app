import '../../../../core/network/api_client.dart';
import '../../../../repositories/teacher_profile_repository.dart';
import '../../../profile/domain/entities/teacher_profile.dart';

/// Remote implementation of [TeacherProfileRepository] using FastAPI backend.
///
/// Maps backend TeacherResponse to frontend TeacherProfile.
/// Endpoints:
/// - GET /teachers/{id} → getProfileById
/// - PUT /teachers/me/profile → updateProfile
/// - GET /teachers → searchProfiles, getFeaturedProfiles
class RemoteTeacherProfileRepository implements TeacherProfileRepository {
  final ApiClient _apiClient;

  RemoteTeacherProfileRepository(this._apiClient);

  @override
  Future<TeacherProfile?> getProfileById(String id) async {
    try {
      final response = await _apiClient.get('/teachers/$id');
      return _profileFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeacherProfile?> getProfileByUserId(String userId) async {
    try {
      final response = await _apiClient.get('/teachers/me/profile');
      return _profileFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeacherProfile> createProfile(TeacherProfile profile) async {
    final response = await _apiClient.put(
      '/teachers/me/profile',
      data: _profileToJson(profile),
    );
    return _profileFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TeacherProfile> updateProfile(TeacherProfile profile) async {
    final response = await _apiClient.put(
      '/teachers/me/profile',
      data: _profileToJson(profile),
    );
    return _profileFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TeacherProfile> updatePhoneVerification(
    String profileId,
    TeacherVerification verification,
  ) async {
    // Phone verification is handled separately — update profile
    final profile = await getProfileById(profileId);
    if (profile == null) throw Exception('Profile not found');
    return updateProfile(profile.copyWith(verification: verification));
  }

  @override
  Future<TeacherProfile> updateVisibilitySettings(
    String profileId,
    ProfileVisibilitySettings settings,
  ) async {
    final profile = await getProfileById(profileId);
    if (profile == null) throw Exception('Profile not found');
    return updateProfile(profile.copyWith(visibilitySettings: settings));
  }

  @override
  Future<TeacherProfile> addCertificate(
    String profileId,
    Certificate cert,
  ) async {
    final profile = await getProfileById(profileId);
    if (profile == null) throw Exception('Profile not found');
    final newCerts = [...profile.verification.certificates, cert];
    return updateProfile(profile.copyWith(
      verification: profile.verification.copyWith(certificates: newCerts),
    ));
  }

  @override
  Future<Certificate> updateCertificateStatus(
    String certificateId,
    CertificateStatus status,
    String? rejectionReason,
  ) async {
    // Admin-only operation — not available through standard API
    throw UnimplementedError(
      'Certificate status updates require admin API access',
    );
  }

  @override
  Future<List<TeacherProfile>> searchProfiles(
    TeacherProfileFilter filter,
  ) async {
    final queryParams = <String, dynamic>{};
    if (filter.instruments != null && filter.instruments!.isNotEmpty) {
      queryParams['instrument'] = filter.instruments!.first;
    }
    if (filter.area != null) {
      queryParams['area'] = filter.area;
    }

    final response = await _apiClient.get(
      '/teachers',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final profiles = items
        .map((json) => _profileFromJson(json as Map<String, dynamic>))
        .where((p) => filter.matches(p))
        .toList();

    return profiles;
  }

  @override
  Future<List<TeacherProfile>> getFeaturedProfiles() async {
    final response = await _apiClient.get('/teachers');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .take(5)
        .map((json) => _profileFromJson(json as Map<String, dynamic>))
        .toList();
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

  /// Convert TeacherProfile to backend-compatible JSON.
  Map<String, dynamic> _profileToJson(TeacherProfile profile) {
    return {
      'instruments': profile.instruments,
      'introduction': profile.introduction,
      'experience_years': profile.experienceYears,
      'lesson_types': profile.lessonTypes
          ?.map((t) {
            switch (t) {
              case LessonTypeOption.inPerson:
                return 'in_person';
              case LessonTypeOption.online:
                return 'online';
              case LessonTypeOption.visit:
                return 'visit';
            }
          })
          .toList(),
      if (profile.feeRange != null) 'fee_min': profile.feeRange!.minFee,
      if (profile.feeRange != null) 'fee_max': profile.feeRange!.maxFee,
      'teaching_style': profile.teachingStyle,
    };
  }
}
