// Teacher search domain entity
// Moved from lib/models/teacher_search.dart for Clean Architecture

import 'teacher_profile.dart';

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

  const TeacherPublicProfile({
    required this.id,
    this.name,
    this.profileImage,
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
  });

  /// Create from TeacherProfile applying visibility settings
  factory TeacherPublicProfile.fromProfile(TeacherProfile profile) {
    final settings = profile.visibilitySettings;

    return TeacherPublicProfile(
      id: profile.id,
      name: settings.nameVisibility == ProfileVisibility.public
          ? profile.name
          : null,
      profileImage: settings.photoVisibility == ProfileVisibility.public
          ? profile.profileImage
          : null,
      instruments: profile.instruments,
      introduction: profile.introduction,
      experienceYears: profile.experienceYears,
      feeRange: settings.feeVisibility == ProfileVisibility.public
          ? profile.feeRange
          : null,
      lessonAreas: profile.lessonAreas,
      lessonTypes: profile.lessonTypes,
      education: settings.careerVisibility == ProfileVisibility.public
          ? profile.education
          : null,
      career: settings.careerVisibility == ProfileVisibility.public
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
    );
  }
}
