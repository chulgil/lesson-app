import 'dart:developer' as developer;

import '../../../../core/network/api_client.dart';
import '../../../profile/domain/repositories/teacher_profile_repository.dart';
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
    } catch (e) {
      developer.log('[TeacherProfile] getProfileById failed: $e');
      return null;
    }
  }

  @override
  Future<TeacherProfile?> getProfileByUserId(String userId) async {
    try {
      final response = await _apiClient.get('/teachers/me/profile');
      return _profileFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      developer.log('[TeacherProfile] getProfileByUserId failed: $e');
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
    return updateProfile(
      profile.copyWith(
        verification: profile.verification.copyWith(certificates: newCerts),
      ),
    );
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

  ProfileVisibility _parseVisibility(dynamic value) {
    if (value is String) {
      return ProfileVisibility.values.firstWhere(
        (v) => v.name == value,
        orElse: () => ProfileVisibility.public,
      );
    }
    return ProfileVisibility.public;
  }

  /// Map backend TeacherResponse to frontend TeacherProfile.
  TeacherProfile _profileFromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? '선생님';
    final profileImage = user?['profile_image_url'] as String?;
    final userId = json['user_id'] as String? ?? '';

    final instruments =
        (json['instruments'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final specialties =
        (json['specialties'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final lessonAreas =
        (json['lesson_areas'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final lessonTypes =
        (json['lesson_types'] as List<dynamic>?)?.map((e) {
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
        }).toList() ??
        [];

    final feeMin = json['fee_min'] as int?;
    final feeMax = json['fee_max'] as int?;
    final feeDuration = json['fee_duration'] as int? ?? 60;
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;

    // Parse education list
    final educationList =
        (json['education'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return Education(
            school: m['school'] as String? ?? '',
            major: m['major'] as String? ?? '',
            degree: m['degree'] as String? ?? '',
            graduationYear: m['graduation_year'] as int?,
          );
        }).toList() ??
        [];

    // Parse career list
    final careerList =
        (json['career'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return Career(
            organization: m['organization'] as String? ?? '',
            position: m['position'] as String? ?? '',
            startYear: m['start_year'] as int? ?? 2020,
            endYear: m['end_year'] as int?,
            description: m['description'] as String?,
          );
        }).toList() ??
        [];

    // Parse certificates
    final certList =
        (json['certificates'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          final issueDateStr = m['issue_date'] as String?;
          final submittedAtStr = m['submitted_at'] as String?;
          return Certificate(
            id: m['id'] as String? ?? '',
            type: CertificateType.values.firstWhere(
              (t) => t.name == (m['type'] as String?),
              orElse: () => CertificateType.other,
            ),
            name: m['name'] as String? ?? '',
            issuingBody: m['issuing_body'] as String? ?? '',
            issueDate: issueDateStr != null
                ? DateTime.tryParse(issueDateStr) ?? DateTime.now()
                : DateTime.now(),
            imageUrl: m['image_url'] as String? ?? '',
            submittedAt: submittedAtStr != null
                ? DateTime.tryParse(submittedAtStr) ?? DateTime.now()
                : DateTime.now(),
            status: CertificateStatus.values.firstWhere(
              (s) => s.name == (m['status'] as String?),
              orElse: () => CertificateStatus.pending,
            ),
          );
        }).toList() ??
        [];

    // Parse visibility settings
    final visJson = json['visibility_settings'] as Map<String, dynamic>?;
    final visibility = visJson != null
        ? ProfileVisibilitySettings(
            isSearchable: visJson['is_searchable'] as bool? ?? true,
            contactVisibility: _parseVisibility(visJson['contact_visibility']),
            feeVisibility: _parseVisibility(visJson['fee_visibility']),
            careerVisibility: _parseVisibility(visJson['career_visibility']),
            certificateVisibility: _parseVisibility(
              visJson['certificate_visibility'],
            ),
          )
        : const ProfileVisibilitySettings();

    // Parse bank account (legacy single — flat fields)
    final bankName = json['bank_name'] as String?;
    final accountNumber = json['account_number'] as String?;
    final accountHolder = json['account_holder'] as String?;
    final bankAccount = (bankName != null || accountNumber != null)
        ? BankAccount(
            id: json['bank_account_id'] as String? ?? '',
            bankName: bankName ?? '',
            accountNumber: accountNumber ?? '',
            accountHolder: accountHolder ?? '',
            createdAt: json['bank_account_created_at'] != null
                ? DateTime.parse(json['bank_account_created_at'] as String)
                : DateTime.now(),
          )
        : null;

    // 2026-06-12 — 복수 계좌 (bank_accounts) 역파싱. 이전엔 왕복 직렬화가
    // 모두 누락되어 베타에서 "계좌 추가 무반응" (저장도 조회도 안 됨).
    // best-effort: 비호환 요소는 skip (#706 원칙).
    final bankAccounts = <BankAccount>[];
    final rawBankAccounts = json['bank_accounts'] as List<dynamic>? ?? const [];
    for (final raw in rawBankAccounts) {
      try {
        bankAccounts.add(BankAccount.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        // skip incompatible payloads
      }
    }
    // 복수 목록이 비었는데 legacy 단수가 있으면 단수를 목록으로 승격
    // (구버전 BE 응답 호환).
    if (bankAccounts.isEmpty && bankAccount != null) {
      bankAccounts.add(bankAccount);
    }

    return TeacherProfile(
      id: json['id'] as String,
      userId: userId,
      name: name,
      profileImage: profileImage,
      backgroundImage: json['background_image'] as String?,
      instruments: instruments,
      specialties: specialties,
      introduction: json['introduction'] as String? ?? '',
      experienceYears: json['experience_years'] as int?,
      lessonAreas: lessonAreas,
      lessonTypes: lessonTypes,
      feeRange: (feeMin != null || feeMax != null)
          ? FeeRange(
              minFee: feeMin ?? 0,
              maxFee: feeMax ?? 0,
              duration: feeDuration,
            )
          : null,
      teachingStyle: json['teaching_style'] as String?,
      education: educationList,
      career: careerList,
      verification: TeacherVerification(certificates: certList),
      visibilitySettings: visibility,
      bankAccount: bankAccount,
      bankAccounts: bankAccounts,
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  /// Convert TeacherProfile to backend-compatible JSON.
  Map<String, dynamic> _profileToJson(TeacherProfile profile) {
    return {
      'instruments': profile.instruments,
      'introduction': profile.introduction,
      'experience_years': profile.experienceYears,
      'specialties': profile.specialties,
      'lesson_areas': profile.lessonAreas,
      'lesson_types': profile.lessonTypes?.map((t) {
        switch (t) {
          case LessonTypeOption.inPerson:
            return 'in_person';
          case LessonTypeOption.online:
            return 'online';
          case LessonTypeOption.visit:
            return 'visit';
        }
      }).toList(),
      if (profile.feeRange != null) 'fee_min': profile.feeRange!.minFee,
      if (profile.feeRange != null) 'fee_max': profile.feeRange!.maxFee,
      if (profile.feeRange != null) 'fee_duration': profile.feeRange!.duration,
      'teaching_style': profile.teachingStyle,
      if (profile.backgroundImage != null)
        'background_image': profile.backgroundImage,
      if (profile.bankAccount != null) ...{
        'bank_name': profile.bankAccount!.bankName,
        'account_number': profile.bankAccount!.accountNumber,
        'account_holder': profile.bankAccount!.accountHolder,
      },
      // 2026-06-12 — 복수 계좌 직렬화 (이전 누락 → 베타 저장 무반응 원인).
      // BE TeacherUpdate.bank_accounts: list[dict] | None.
      'bank_accounts': profile.bankAccounts.map((a) => a.toJson()).toList(),
      if (profile.verification.isPhoneVerified) ...{
        'is_phone_verified': true,
        'phone_number': profile.verification.phoneNumber,
      },
      'visibility_settings': {
        'is_searchable': profile.visibilitySettings.isSearchable,
        'contact_visibility': profile.visibilitySettings.contactVisibility.name,
        'fee_visibility': profile.visibilitySettings.feeVisibility.name,
        'career_visibility': profile.visibilitySettings.careerVisibility.name,
        'certificate_visibility':
            profile.visibilitySettings.certificateVisibility.name,
      },
    };
  }
}
