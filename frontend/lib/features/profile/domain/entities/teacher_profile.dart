// Teacher profile domain entity
// Moved from lib/features/profile/domain/entities/teacher_profile.dart for Clean Architecture

import 'teacher_settings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_profile.g.dart';

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
@JsonSerializable()
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

  factory Education.fromJson(Map<String, dynamic> json) =>
      _$EducationFromJson(json);
  Map<String, dynamic> toJson() => _$EducationToJson(this);

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
@JsonSerializable()
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

  factory Career.fromJson(Map<String, dynamic> json) =>
      _$CareerFromJson(json);
  Map<String, dynamic> toJson() => _$CareerToJson(this);

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

/// Bank account information for receiving payments
@JsonSerializable()
class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final bool isDefault;
  final DateTime createdAt;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.isDefault = false,
    required this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) =>
      _$BankAccountFromJson(json);
  Map<String, dynamic> toJson() => _$BankAccountToJson(this);

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Fee range for lessons
@JsonSerializable()
class FeeRange {
  final int minFee;
  final int maxFee;
  final int duration; // in minutes (30, 45, 60)

  const FeeRange({
    required this.minFee,
    required this.maxFee,
    this.duration = 60,
  });

  factory FeeRange.fromJson(Map<String, dynamic> json) =>
      _$FeeRangeFromJson(json);
  Map<String, dynamic> toJson() => _$FeeRangeToJson(this);

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
@JsonSerializable()
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

  factory Certificate.fromJson(Map<String, dynamic> json) =>
      _$CertificateFromJson(json);
  Map<String, dynamic> toJson() => _$CertificateToJson(this);

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
@JsonSerializable()
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

  factory TeacherVerification.fromJson(Map<String, dynamic> json) =>
      _$TeacherVerificationFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherVerificationToJson(this);

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
@JsonSerializable()
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

  factory ProfileVisibilitySettings.fromJson(Map<String, dynamic> json) =>
      _$ProfileVisibilitySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileVisibilitySettingsToJson(this);

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
@JsonSerializable()
class TeacherProfile {
  final String id;
  final String userId;

  // Organization info (null for individual teachers)
  final String? organizationId;
  final String? organizationName;

  // Basic info (required for minimum)
  final String name;
  final String? nickname; // 호칭/닉네임 (학생에게 표시, null이면 name 사용)
  final String? profileImage;
  final String? backgroundImage;
  final List<String> instruments;

  /// Discipline vertical (#963); null = music (DisciplineRegistry.fallback).
  final String? disciplineId;
  final String introduction;

  // Extended info (for basic/standard)
  final int? experienceYears;
  final List<String>? lessonAreas;
  final List<LessonTypeOption>? lessonTypes;
  final FeeRange? feeRange;
  final List<Education>? education;
  final List<Career>? career;

  // Location info (optional, used for visit lessons and profile display)
  final String? postalCode; // 우편번호 (5자리)
  final String? address; // 기본주소 (시/구/동)
  final String? addressDetail; // 상세주소 (비공개)

  // Complete info
  @JsonKey(name: 'specialties')
  final List<String>? expertiseTags;
  final String? teachingStyle;
  final List<String>? portfolioVideoUrls;

  // Payment info (legacy single + new multiple)
  final BankAccount? bankAccount;
  final List<BankAccount> bankAccounts;

  // Verification
  final TeacherVerification verification;

  // Settings
  final ProfileVisibilitySettings visibilitySettings;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Get the default bank account (from bankAccounts list, fallback to legacy)
  BankAccount? get defaultBankAccount {
    final defaultFromList = bankAccounts.where((a) => a.isDefault).firstOrNull;
    if (defaultFromList != null) return defaultFromList;
    if (bankAccounts.isNotEmpty) return bankAccounts.first;
    return bankAccount;
  }

  /// Check if this is an academy teacher
  bool get isAcademy => organizationId != null;

  /// Check if this is an individual teacher
  bool get isIndividual => organizationId == null;

  const TeacherProfile({
    required this.id,
    required this.userId,
    this.organizationId,
    this.organizationName,
    required this.name,
    this.nickname,
    this.profileImage,
    this.backgroundImage,
    required this.instruments,
    this.disciplineId,
    required this.introduction,
    this.experienceYears,
    this.lessonAreas,
    this.lessonTypes,
    this.feeRange,
    this.education,
    this.career,
    this.postalCode,
    this.address,
    this.addressDetail,
    this.expertiseTags,
    this.teachingStyle,
    this.portfolioVideoUrls,
    this.bankAccount,
    this.bankAccounts = const [],
    this.verification = const TeacherVerification(),
    this.visibilitySettings = const ProfileVisibilitySettings(),
    required this.createdAt,
    this.updatedAt,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    // Build bank_account from flat fields if nested object is missing
    final enriched = Map<String, dynamic>.from(json);
    if (enriched['bank_account'] == null &&
        enriched['bank_name'] != null &&
        enriched['account_number'] != null) {
      enriched['bank_account'] = {
        'id': 'legacy_${enriched['account_number']}',
        'bank_name': enriched['bank_name'],
        'account_number': enriched['account_number'],
        'account_holder': enriched['account_holder'] ?? '',
        'is_default': true,
        'created_at': enriched['created_at'] ?? DateTime.now().toIso8601String(),
      };
    }
    // Ensure bank_accounts items have 'id' field
    final bankAccounts = enriched['bank_accounts'] as List<dynamic>?;
    if (bankAccounts != null) {
      for (var i = 0; i < bankAccounts.length; i++) {
        final acc = bankAccounts[i] as Map<String, dynamic>;
        if (acc['id'] == null) {
          acc['id'] = 'ba_${acc['account_number'] ?? i}';
        }
      }
    }
    return _$TeacherProfileFromJson(enriched);
  }
  Map<String, dynamic> toJson() => _$TeacherProfileToJson(this);

  /// 학생에게 표시되는 이름 (닉네임 우선, 없으면 본명)
  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;

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
    if (expertiseTags != null && expertiseTags!.isNotEmpty) score += 6;

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
    if (expertiseTags == null || expertiseTags!.isEmpty) fields.add('전문 분야');

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
    String? organizationId,
    String? organizationName,
    String? name,
    String? nickname,
    String? profileImage,
    String? backgroundImage,
    List<String>? instruments,
    String? disciplineId,
    String? introduction,
    int? experienceYears,
    List<String>? lessonAreas,
    List<LessonTypeOption>? lessonTypes,
    FeeRange? feeRange,
    List<Education>? education,
    List<Career>? career,
    String? postalCode,
    String? address,
    String? addressDetail,
    List<String>? expertiseTags,
    String? teachingStyle,
    List<String>? portfolioVideoUrls,
    BankAccount? bankAccount,
    List<BankAccount>? bankAccounts,
    TeacherVerification? verification,
    ProfileVisibilitySettings? visibilitySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      instruments: instruments ?? this.instruments,
      disciplineId: disciplineId ?? this.disciplineId,
      introduction: introduction ?? this.introduction,
      experienceYears: experienceYears ?? this.experienceYears,
      lessonAreas: lessonAreas ?? this.lessonAreas,
      lessonTypes: lessonTypes ?? this.lessonTypes,
      feeRange: feeRange ?? this.feeRange,
      education: education ?? this.education,
      career: career ?? this.career,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      expertiseTags: expertiseTags ?? this.expertiseTags,
      teachingStyle: teachingStyle ?? this.teachingStyle,
      portfolioVideoUrls: portfolioVideoUrls ?? this.portfolioVideoUrls,
      bankAccount: bankAccount ?? this.bankAccount,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      verification: verification ?? this.verification,
      visibilitySettings: visibilitySettings ?? this.visibilitySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
