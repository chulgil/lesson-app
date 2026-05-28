// Teacher search domain entity
// Moved from lib/features/profile/domain/entities/teacher_search.dart for Clean Architecture

import 'teacher_profile.dart';

/// Type of teacher/academy to search for
enum TeacherSearchType {
  /// Search for academies (organizationId != null)
  academy,

  /// Search for individual teachers (organizationId == null)
  individual,
}

/// Search filter for finding teachers
class TeacherSearchFilter {
  final String? keyword;
  final List<String>? instruments;
  final List<String>? areas;
  final List<LessonTypeOption>? lessonTypes;
  final int? minFee;
  final int? maxFee;
  final int? minExperience;
  final bool? hasVerifiedCertificate;
  final ProfileCompletionLevel? minCompletionLevel;
  final TeacherSearchType? teacherType;

  const TeacherSearchFilter({
    this.keyword,
    this.instruments,
    this.areas,
    this.lessonTypes,
    this.minFee,
    this.maxFee,
    this.minExperience,
    this.hasVerifiedCertificate,
    this.minCompletionLevel,
    this.teacherType,
  });

  static const empty = TeacherSearchFilter();

  bool get isEmpty =>
      keyword == null &&
      (instruments == null || instruments!.isEmpty) &&
      (areas == null || areas!.isEmpty) &&
      (lessonTypes == null || lessonTypes!.isEmpty) &&
      minFee == null &&
      maxFee == null &&
      minExperience == null &&
      hasVerifiedCertificate == null &&
      minCompletionLevel == null;
  // Note: teacherType is not included in isEmpty check
  // because it's controlled by tab, not by filter sheet

  TeacherSearchFilter copyWith({
    String? keyword,
    List<String>? instruments,
    List<String>? areas,
    List<LessonTypeOption>? lessonTypes,
    int? minFee,
    int? maxFee,
    int? minExperience,
    bool? hasVerifiedCertificate,
    ProfileCompletionLevel? minCompletionLevel,
    TeacherSearchType? teacherType,
  }) {
    return TeacherSearchFilter(
      keyword: keyword ?? this.keyword,
      instruments: instruments ?? this.instruments,
      areas: areas ?? this.areas,
      lessonTypes: lessonTypes ?? this.lessonTypes,
      minFee: minFee ?? this.minFee,
      maxFee: maxFee ?? this.maxFee,
      minExperience: minExperience ?? this.minExperience,
      hasVerifiedCertificate:
          hasVerifiedCertificate ?? this.hasVerifiedCertificate,
      minCompletionLevel: minCompletionLevel ?? this.minCompletionLevel,
      teacherType: teacherType ?? this.teacherType,
    );
  }

  TeacherSearchFilter clearKeyword() => TeacherSearchFilter(
    instruments: instruments,
    areas: areas,
    lessonTypes: lessonTypes,
    minFee: minFee,
    maxFee: maxFee,
    minExperience: minExperience,
    hasVerifiedCertificate: hasVerifiedCertificate,
    minCompletionLevel: minCompletionLevel,
    teacherType: teacherType,
  );
}

/// Sort options for teacher search
enum TeacherSortOption {
  relevance,
  experienceDesc,
  experienceAsc,
  feeAsc,
  feeDesc,
  rating,
  completionLevel,
}

/// Search result with pagination info
class TeacherSearchResult {
  final List<TeacherProfile> teachers;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const TeacherSearchResult({
    required this.teachers,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  static const empty = TeacherSearchResult(
    teachers: [],
    totalCount: 0,
    page: 0,
    pageSize: 20,
    hasMore: false,
  );
}

/// Public profile view - only visible fields based on settings
class TeacherPublicProfile {
  final String id;
  final String? name;
  final String? profileImage;
  final String? organizationId;
  final String? organizationName;
  final List<String> instruments;
  final String introduction;
  final int? experienceYears;
  final FeeRange? feeRange;
  final List<String>? lessonAreas;
  final List<LessonTypeOption>? lessonTypes;
  final List<Education>? education;
  final List<Career>? career;
  final List<Certificate> verifiedCertificates;
  final List<VerificationBadge> badges;
  final ProfileCompletionLevel completionLevel;

  /// Academy public page consent (G5/W3).
  /// 학원 공개 페이지에 노출 동의 여부. 개인 강사(isIndividual)는 무관.
  /// AcademyMember.publicPageConsent 와 1:1 매핑.
  final bool publicPageConsent;

  /// Check if this is an academy teacher
  bool get isAcademy => organizationId != null;

  /// Check if this is an individual teacher
  bool get isIndividual => organizationId == null;

  const TeacherPublicProfile({
    required this.id,
    this.name,
    this.profileImage,
    this.organizationId,
    this.organizationName,
    required this.instruments,
    required this.introduction,
    this.experienceYears,
    this.feeRange,
    this.lessonAreas,
    this.lessonTypes,
    this.education,
    this.career,
    this.verifiedCertificates = const [],
    this.badges = const [],
    required this.completionLevel,
    this.publicPageConsent = false,
  });

  /// Create from TeacherProfile applying visibility settings
  factory TeacherPublicProfile.fromProfile(
    TeacherProfile profile, {
    bool publicPageConsent = false,
  }) {
    final settings = profile.visibilitySettings;

    return TeacherPublicProfile(
      id: profile.id,
      name:
          settings.nameVisibility == ProfileVisibility.public
              ? profile.name
              : null,
      profileImage:
          settings.photoVisibility == ProfileVisibility.public
              ? profile.profileImage
              : null,
      organizationId: profile.organizationId,
      organizationName: profile.organizationName,
      instruments: profile.instruments,
      introduction: profile.introduction,
      experienceYears: profile.experienceYears,
      feeRange:
          settings.feeVisibility == ProfileVisibility.public
              ? profile.feeRange
              : null,
      lessonAreas: profile.lessonAreas,
      lessonTypes: profile.lessonTypes,
      education:
          settings.careerVisibility == ProfileVisibility.public
              ? profile.education
              : null,
      career:
          settings.careerVisibility == ProfileVisibility.public
              ? profile.career
              : null,
      verifiedCertificates:
          settings.certificateVisibility == ProfileVisibility.public
              ? profile.verification.certificates
                  .where((c) => c.isApproved)
                  .toList()
              : [],
      badges: profile.allBadges,
      completionLevel: profile.completionLevel,
      publicPageConsent: publicPageConsent,
    );
  }
}
