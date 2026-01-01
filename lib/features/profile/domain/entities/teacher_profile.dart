// Teacher profile domain entity
// Moved from lib/models/teacher_profile.dart for Clean Architecture

import 'teacher_settings.dart';

/// Profile completion level based on filled information
enum ProfileCompletionLevel {
  minimum, // 30% - Required fields only (restricted)
  basic, // 60% - Basic info completed (limited activity)
  standard, // 80% - Most fields completed (normal activity)
  complete, // 100% - All fields completed (premium exposure)
}

/// Lesson type options
enum LessonTypeOption {
  inPerson, // Face-to-face
  online, // Online/video
  visit, // Home visit
}

/// Backward compatibility alias for LessonTypeOption
typedef LessonType = LessonTypeOption;

/// Verification badge types
enum VerificationBadge {
  phoneVerified, // Phone number verified
  certified, // Has verified certificate
  premium, // Profile 100% complete
}

/// Certificate verification status
enum CertificateStatus {
  pending, // Under review
  approved, // Approved
  rejected, // Rejected
}

/// Certificate type
enum CertificateType {
  musicTeacher, // Music teacher certificate
  cultureArtsEducator, // Culture/arts educator
  schoolTeacher, // School teacher license
  conservatory, // Conservatory completion
  degree, // Music degree
  performance, // Performance credentials
  other, // Other
}

/// Profile visibility setting
enum ProfileVisibility {
  public, // Visible to everyone
  students, // Visible to connected students only
  private, // Hidden
}

/// Education record
class Education {
  final String school;
  final String major;
  final String degree; // Bachelor, Master, Doctor
  final int? graduationYear;

  const Education({
    required this.school,
    required this.major,
    required this.degree,
    this.graduationYear,
  });

  Education copyWith({
    String? school,
    String? major,
    String? degree,
    int? graduationYear,
  }) {
    return Education(
      school: school ?? this.school,
      major: major ?? this.major,
      degree: degree ?? this.degree,
      graduationYear: graduationYear ?? this.graduationYear,
    );
  }
}

/// Career record
class Career {
  final String organization;
  final String position;
  final int startYear;
  final int? endYear; // null = current
  final String? description;

  const Career({
    required this.organization,
    required this.position,
    required this.startYear,
    this.endYear,
    this.description,
  });

  bool get isCurrent => endYear == null;

  String get period {
    if (endYear == null) {
      return '$startYear - 현재';
    }
    return '$startYear - $endYear';
  }

  Career copyWith({
    String? organization,
    String? position,
    int? startYear,
    int? endYear,
    String? description,
  }) {
    return Career(
      organization: organization ?? this.organization,
      position: position ?? this.position,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      description: description ?? this.description,
    );
  }
}

/// Fee range for lessons
class FeeRange {
  final int minFee;
  final int maxFee;
  final int duration; // in minutes (30, 45, 60)

  const FeeRange({
    required this.minFee,
    required this.maxFee,
    this.duration = 60,
  });

  String get formatted {
    final min = _formatCurrency(minFee);
    final max = _formatCurrency(maxFee);
    final durationStr = LessonDurations.format(duration);
    if (minFee == maxFee) {
      return '$min / $durationStr';
    }
    return '$min ~ $max / $durationStr';
  }

  String _formatCurrency(int amount) {
    if (amount >= 10000) {
      final man = amount ~/ 10000;
      return '$man만원';
    }
    return '$amount원';
  }

  FeeRange copyWith({
    int? minFee,
    int? maxFee,
    int? duration,
  }) {
    return FeeRange(
      minFee: minFee ?? this.minFee,
      maxFee: maxFee ?? this.maxFee,
      duration: duration ?? this.duration,
    );
  }
}

/// Certificate model
class Certificate {
  final String id;
  final CertificateType type;
  final String name;
  final String issuingBody;
  final DateTime issueDate;
  final String? certificateNumber;
  final String imageUrl;
  final CertificateStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  const Certificate({
    required this.id,
    required this.type,
    required this.name,
    required this.issuingBody,
    required this.issueDate,
    this.certificateNumber,
    required this.imageUrl,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
  });

  bool get isApproved => status == CertificateStatus.approved;
  bool get isPending => status == CertificateStatus.pending;
  bool get isRejected => status == CertificateStatus.rejected;

  Certificate copyWith({
    String? id,
    CertificateType? type,
    String? name,
    String? issuingBody,
    DateTime? issueDate,
    String? certificateNumber,
    String? imageUrl,
    CertificateStatus? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return Certificate(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      issuingBody: issuingBody ?? this.issuingBody,
      issueDate: issueDate ?? this.issueDate,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

/// Teacher verification status
class TeacherVerification {
  final bool isPhoneVerified;
  final String? phoneNumber;
  final DateTime? phoneVerifiedAt;
  final List<Certificate> certificates;

  const TeacherVerification({
    this.isPhoneVerified = false,
    this.phoneNumber,
    this.phoneVerifiedAt,
    this.certificates = const [],
  });

  bool get hasVerifiedCertificate =>
      certificates.any((c) => c.status == CertificateStatus.approved);

  List<VerificationBadge> get badges {
    final list = <VerificationBadge>[];
    if (isPhoneVerified) list.add(VerificationBadge.phoneVerified);
    if (hasVerifiedCertificate) list.add(VerificationBadge.certified);
    return list;
  }

  TeacherVerification copyWith({
    bool? isPhoneVerified,
    String? phoneNumber,
    DateTime? phoneVerifiedAt,
    List<Certificate>? certificates,
  }) {
    return TeacherVerification(
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      certificates: certificates ?? this.certificates,
    );
  }
}

/// Profile visibility settings
class ProfileVisibilitySettings {
  final bool isSearchable;
  final ProfileVisibility nameVisibility;
  final ProfileVisibility photoVisibility;
  final ProfileVisibility contactVisibility;
  final ProfileVisibility feeVisibility;
  final ProfileVisibility careerVisibility;
  final ProfileVisibility certificateVisibility;

  const ProfileVisibilitySettings({
    this.isSearchable = true,
    this.nameVisibility = ProfileVisibility.public,
    this.photoVisibility = ProfileVisibility.public,
    this.contactVisibility = ProfileVisibility.students,
    this.feeVisibility = ProfileVisibility.public,
    this.careerVisibility = ProfileVisibility.public,
    this.certificateVisibility = ProfileVisibility.public,
  });

  static const defaults = ProfileVisibilitySettings();

  ProfileVisibilitySettings copyWith({
    bool? isSearchable,
    ProfileVisibility? nameVisibility,
    ProfileVisibility? photoVisibility,
    ProfileVisibility? contactVisibility,
    ProfileVisibility? feeVisibility,
    ProfileVisibility? careerVisibility,
    ProfileVisibility? certificateVisibility,
  }) {
    return ProfileVisibilitySettings(
      isSearchable: isSearchable ?? this.isSearchable,
      nameVisibility: nameVisibility ?? this.nameVisibility,
      photoVisibility: photoVisibility ?? this.photoVisibility,
      contactVisibility: contactVisibility ?? this.contactVisibility,
      feeVisibility: feeVisibility ?? this.feeVisibility,
      careerVisibility: careerVisibility ?? this.careerVisibility,
      certificateVisibility:
          certificateVisibility ?? this.certificateVisibility,
    );
  }
}

/// Extended teacher profile with all fields
class TeacherProfile {
  final String id;
  final String userId;

  // Basic info (required for minimum)
  final String name;
  final String? profileImage;
  final List<String> instruments;
  final String introduction;

  // Extended info (for basic/standard)
  final int? experienceYears;
  final List<String>? lessonAreas;
  final List<LessonTypeOption>? lessonTypes;
  final FeeRange? feeRange;
  final List<Education>? education;
  final List<Career>? career;

  // Complete info
  final List<String>? specialties;
  final String? teachingStyle;
  final List<String>? portfolioVideoUrls;

  // Verification
  final TeacherVerification verification;

  // Settings
  final ProfileVisibilitySettings visibilitySettings;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.profileImage,
    required this.instruments,
    required this.introduction,
    this.experienceYears,
    this.lessonAreas,
    this.lessonTypes,
    this.feeRange,
    this.education,
    this.career,
    this.specialties,
    this.teachingStyle,
    this.portfolioVideoUrls,
    this.verification = const TeacherVerification(),
    this.visibilitySettings = const ProfileVisibilitySettings(),
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate profile completion level
  ProfileCompletionLevel get completionLevel {
    final percentage = completionPercentage;
    if (percentage >= 100) return ProfileCompletionLevel.complete;
    if (percentage >= 80) return ProfileCompletionLevel.standard;
    if (percentage >= 60) return ProfileCompletionLevel.basic;
    return ProfileCompletionLevel.minimum;
  }

  /// Calculate profile completion percentage
  int get completionPercentage {
    int score = 0;

    // Minimum (30%)
    if (name.isNotEmpty) score += 8;
    if (profileImage != null && profileImage!.isNotEmpty) score += 7;
    if (instruments.isNotEmpty) score += 8;
    if (introduction.length >= 20) score += 7;

    // Basic (60%)
    if (experienceYears != null) score += 8;
    if (lessonAreas != null && lessonAreas!.isNotEmpty) score += 8;
    if (lessonTypes != null && lessonTypes!.isNotEmpty) score += 7;
    if (feeRange != null) score += 7;

    // Standard (80%)
    if (education != null && education!.isNotEmpty) score += 10;
    if (career != null && career!.isNotEmpty) score += 10;

    // Complete (100%)
    if (portfolioVideoUrls != null && portfolioVideoUrls!.isNotEmpty) {
      score += 8;
    }
    if (teachingStyle != null && teachingStyle!.isNotEmpty) score += 6;
    if (specialties != null && specialties!.isNotEmpty) score += 6;

    return score.clamp(0, 100);
  }

  /// Get list of incomplete fields for user guidance
  List<String> get incompleteFields {
    final fields = <String>[];

    // Minimum fields
    if (name.isEmpty) fields.add('이름');
    if (profileImage == null || profileImage!.isEmpty) fields.add('프로필 사진');
    if (instruments.isEmpty) fields.add('악기');
    if (introduction.length < 20) fields.add('소개글 (20자 이상)');

    // Basic fields
    if (experienceYears == null) fields.add('경력');
    if (lessonAreas == null || lessonAreas!.isEmpty) fields.add('레슨 가능 지역');
    if (lessonTypes == null || lessonTypes!.isEmpty) fields.add('레슨 방식');
    if (feeRange == null) fields.add('레슨료');

    // Standard fields
    if (education == null || education!.isEmpty) fields.add('학력');
    if (career == null || career!.isEmpty) fields.add('경력 상세');

    // Complete fields
    if (portfolioVideoUrls == null || portfolioVideoUrls!.isEmpty) {
      fields.add('연주 영상');
    }
    if (teachingStyle == null || teachingStyle!.isEmpty) fields.add('레슨 스타일');
    if (specialties == null || specialties!.isEmpty) fields.add('전문 분야');

    return fields;
  }

  /// Get next steps for profile completion
  List<String> get nextSteps {
    final level = completionLevel;
    switch (level) {
      case ProfileCompletionLevel.minimum:
        return incompleteFields.take(3).toList();
      case ProfileCompletionLevel.basic:
        return incompleteFields.take(2).toList();
      case ProfileCompletionLevel.standard:
        return incompleteFields.take(2).toList();
      case ProfileCompletionLevel.complete:
        return [];
    }
  }

  /// Check if teacher can invite students
  bool get canInviteStudents =>
      completionLevel != ProfileCompletionLevel.minimum;

  /// Check if teacher can be searched
  bool get canBeSearched =>
      completionLevel == ProfileCompletionLevel.standard ||
      completionLevel == ProfileCompletionLevel.complete;

  /// Check if teacher can create lessons
  bool get canCreateLessons =>
      completionLevel != ProfileCompletionLevel.minimum;

  /// Get all verification badges including premium
  List<VerificationBadge> get allBadges {
    final badges = List<VerificationBadge>.from(verification.badges);
    if (completionLevel == ProfileCompletionLevel.complete) {
      badges.add(VerificationBadge.premium);
    }
    return badges;
  }

  TeacherProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? profileImage,
    List<String>? instruments,
    String? introduction,
    int? experienceYears,
    List<String>? lessonAreas,
    List<LessonTypeOption>? lessonTypes,
    FeeRange? feeRange,
    List<Education>? education,
    List<Career>? career,
    List<String>? specialties,
    String? teachingStyle,
    List<String>? portfolioVideoUrls,
    TeacherVerification? verification,
    ProfileVisibilitySettings? visibilitySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      instruments: instruments ?? this.instruments,
      introduction: introduction ?? this.introduction,
      experienceYears: experienceYears ?? this.experienceYears,
      lessonAreas: lessonAreas ?? this.lessonAreas,
      lessonTypes: lessonTypes ?? this.lessonTypes,
      feeRange: feeRange ?? this.feeRange,
      education: education ?? this.education,
      career: career ?? this.career,
      specialties: specialties ?? this.specialties,
      teachingStyle: teachingStyle ?? this.teachingStyle,
      portfolioVideoUrls: portfolioVideoUrls ?? this.portfolioVideoUrls,
      verification: verification ?? this.verification,
      visibilitySettings: visibilitySettings ?? this.visibilitySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
