import '../models/teacher_profile.dart';

/// Repository interface for teacher profile data
abstract class TeacherProfileRepository {
  /// Get teacher profile by ID
  Future<TeacherProfile?> getProfileById(String id);

  /// Get teacher profile by user ID
  Future<TeacherProfile?> getProfileByUserId(String userId);

  /// Create a new teacher profile
  Future<TeacherProfile> createProfile(TeacherProfile profile);

  /// Update teacher profile
  Future<TeacherProfile> updateProfile(TeacherProfile profile);

  /// Update phone verification status
  Future<TeacherProfile> updatePhoneVerification(
    String profileId,
    TeacherVerification verification,
  );

  /// Update visibility settings
  Future<TeacherProfile> updateVisibilitySettings(
    String profileId,
    ProfileVisibilitySettings settings,
  );

  /// Add certificate
  Future<TeacherProfile> addCertificate(String profileId, Certificate cert);

  /// Update certificate status (admin only)
  Future<Certificate> updateCertificateStatus(
    String certificateId,
    CertificateStatus status,
    String? rejectionReason,
  );

  /// Search teachers by filter (for student to find teachers)
  Future<List<TeacherProfile>> searchProfiles(TeacherProfileFilter filter);

  /// Get featured teachers
  Future<List<TeacherProfile>> getFeaturedProfiles();
}

/// Filter for searching teacher profiles
class TeacherProfileFilter {
  final List<String>? instruments;
  final String? area;
  final List<LessonType>? lessonTypes;
  final int? maxFee;
  final int? minFee;
  final bool? hasVerifiedCertificate;
  final ProfileCompletionLevel? minCompletionLevel;

  const TeacherProfileFilter({
    this.instruments,
    this.area,
    this.lessonTypes,
    this.maxFee,
    this.minFee,
    this.hasVerifiedCertificate,
    this.minCompletionLevel,
  });

  bool matches(TeacherProfile profile) {
    // Check if can be searched
    if (!profile.canBeSearched) return false;
    if (!profile.visibilitySettings.isSearchable) return false;

    // Check instruments
    if (instruments != null && instruments!.isNotEmpty) {
      final hasMatch =
          profile.instruments.any((i) => instruments!.contains(i));
      if (!hasMatch) return false;
    }

    // Check area
    if (area != null &&
        profile.lessonAreas != null &&
        !profile.lessonAreas!.any((a) => a.contains(area!))) {
      return false;
    }

    // Check lesson types
    if (lessonTypes != null &&
        lessonTypes!.isNotEmpty &&
        profile.lessonTypes != null) {
      final hasMatch =
          profile.lessonTypes!.any((t) => lessonTypes!.contains(t));
      if (!hasMatch) return false;
    }

    // Check fee range
    if (profile.feeRange != null) {
      if (maxFee != null && profile.feeRange!.minFee > maxFee!) return false;
      if (minFee != null && profile.feeRange!.maxFee < minFee!) return false;
    }

    // Check certificate verification
    if (hasVerifiedCertificate == true &&
        !profile.verification.hasVerifiedCertificate) {
      return false;
    }

    // Check completion level
    if (minCompletionLevel != null) {
      final levelIndex = ProfileCompletionLevel.values.indexOf(
        profile.completionLevel,
      );
      final minLevelIndex = ProfileCompletionLevel.values.indexOf(
        minCompletionLevel!,
      );
      if (levelIndex < minLevelIndex) return false;
    }

    return true;
  }
}

/// Mock implementation of TeacherProfileRepository
class MockTeacherProfileRepository implements TeacherProfileRepository {
  final Map<String, TeacherProfile> _profiles = {};

  MockTeacherProfileRepository() {
    // Initialize with some mock data
    final mockProfiles = _generateMockProfiles();
    for (final profile in mockProfiles) {
      _profiles[profile.id] = profile;
    }
  }

  @override
  Future<TeacherProfile?> getProfileById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _profiles[id];
  }

  @override
  Future<TeacherProfile?> getProfileByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _profiles.values.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeacherProfile> createProfile(TeacherProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profiles[profile.id] = profile;
    return profile;
  }

  @override
  Future<TeacherProfile> updateProfile(TeacherProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profiles[profile.id] = profile.copyWith(updatedAt: DateTime.now());
    return _profiles[profile.id]!;
  }

  @override
  Future<TeacherProfile> updatePhoneVerification(
    String profileId,
    TeacherVerification verification,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final profile = _profiles[profileId];
    if (profile == null) throw Exception('Profile not found');

    final updated = profile.copyWith(
      verification: verification,
      updatedAt: DateTime.now(),
    );
    _profiles[profileId] = updated;
    return updated;
  }

  @override
  Future<TeacherProfile> updateVisibilitySettings(
    String profileId,
    ProfileVisibilitySettings settings,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final profile = _profiles[profileId];
    if (profile == null) throw Exception('Profile not found');

    final updated = profile.copyWith(
      visibilitySettings: settings,
      updatedAt: DateTime.now(),
    );
    _profiles[profileId] = updated;
    return updated;
  }

  @override
  Future<TeacherProfile> addCertificate(
    String profileId,
    Certificate cert,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final profile = _profiles[profileId];
    if (profile == null) throw Exception('Profile not found');

    final newCerts = [...profile.verification.certificates, cert];
    final updated = profile.copyWith(
      verification: profile.verification.copyWith(certificates: newCerts),
      updatedAt: DateTime.now(),
    );
    _profiles[profileId] = updated;
    return updated;
  }

  @override
  Future<Certificate> updateCertificateStatus(
    String certificateId,
    CertificateStatus status,
    String? rejectionReason,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Find profile with this certificate
    for (final profile in _profiles.values) {
      final certIndex = profile.verification.certificates
          .indexWhere((c) => c.id == certificateId);
      if (certIndex != -1) {
        final cert = profile.verification.certificates[certIndex];
        final updatedCert = cert.copyWith(
          status: status,
          rejectionReason: rejectionReason,
          reviewedAt: DateTime.now(),
        );

        final newCerts = List<Certificate>.from(
          profile.verification.certificates,
        );
        newCerts[certIndex] = updatedCert;

        _profiles[profile.id] = profile.copyWith(
          verification: profile.verification.copyWith(certificates: newCerts),
          updatedAt: DateTime.now(),
        );

        return updatedCert;
      }
    }

    throw Exception('Certificate not found');
  }

  @override
  Future<List<TeacherProfile>> searchProfiles(
    TeacherProfileFilter filter,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final results = _profiles.values.where((p) => filter.matches(p)).toList();

    // Sort by completion level, then by name
    results.sort((a, b) {
      final levelCompare = ProfileCompletionLevel.values
          .indexOf(b.completionLevel)
          .compareTo(ProfileCompletionLevel.values.indexOf(a.completionLevel));
      if (levelCompare != 0) return levelCompare;
      return a.name.compareTo(b.name);
    });

    return results;
  }

  @override
  Future<List<TeacherProfile>> getFeaturedProfiles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final results =
        _profiles.values.where((p) => p.canBeSearched).toList()
          ..sort((a, b) {
            // Prioritize by: premium badge, completion level
            final aHasPremium =
                a.allBadges.contains(VerificationBadge.premium) ? 1 : 0;
            final bHasPremium =
                b.allBadges.contains(VerificationBadge.premium) ? 1 : 0;
            if (bHasPremium != aHasPremium) return bHasPremium - aHasPremium;

            return ProfileCompletionLevel.values
                .indexOf(b.completionLevel)
                .compareTo(
                  ProfileCompletionLevel.values.indexOf(a.completionLevel),
                );
          });

    return results.take(5).toList();
  }
}

List<TeacherProfile> _generateMockProfiles() {
  final now = DateTime.now();
  return [
    TeacherProfile(
      id: 'profile_1',
      userId: 'user_teacher_1',
      name: '김선생님',
      profileImage: 'https://example.com/profile1.jpg',
      instruments: ['바이올린', '비올라'],
      introduction: '서울대학교 음악대학 졸업 후 15년간 바이올린을 가르치고 있습니다. '
          '초보자부터 전공생까지 다양한 학생들을 지도한 경험이 있습니다.',
      experienceYears: 15,
      lessonAreas: ['서울 강남구', '서울 서초구'],
      lessonTypes: [LessonType.inPerson, LessonType.online],
      feeRange: const FeeRange(minFee: 50000, maxFee: 80000),
      education: [
        const Education(
          school: '서울대학교',
          major: '바이올린',
          degree: 'bachelor',
          graduationYear: 2008,
        ),
      ],
      career: [
        const Career(
          organization: '서울시립교향악단',
          position: '객원 연주자',
          startYear: 2010,
          endYear: 2015,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-1234-5678',
        phoneVerifiedAt: now.subtract(const Duration(days: 100)),
      ),
      createdAt: now.subtract(const Duration(days: 365)),
    ),
    TeacherProfile(
      id: 'profile_2',
      userId: 'user_teacher_2',
      name: '박선생님',
      profileImage: 'https://example.com/profile2.jpg',
      instruments: ['피아노'],
      introduction: '독일 뮌헨 음대에서 피아노를 전공했습니다. 클래식부터 재즈까지 다양한 장르의 피아노 레슨이 가능합니다.',
      experienceYears: 12,
      lessonAreas: ['서울 서초구'],
      lessonTypes: [LessonType.inPerson],
      feeRange: const FeeRange(minFee: 60000, maxFee: 100000),
      verification: const TeacherVerification(isPhoneVerified: true),
      createdAt: now.subtract(const Duration(days: 200)),
    ),
  ];
}
