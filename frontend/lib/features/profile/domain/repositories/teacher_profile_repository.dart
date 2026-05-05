import '../entities/teacher_profile.dart';

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
      final hasMatch = profile.instruments.any((i) => instruments!.contains(i));
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
      final hasMatch = profile.lessonTypes!.any(
        (t) => lessonTypes!.contains(t),
      );
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
