// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Education _$EducationFromJson(Map<String, dynamic> json) => Education(
      school: json['school'] as String,
      major: json['major'] as String,
      degree: json['degree'] as String,
      graduationYear: (json['graduation_year'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EducationToJson(Education instance) => <String, dynamic>{
      'school': instance.school,
      'major': instance.major,
      'degree': instance.degree,
      'graduation_year': instance.graduationYear,
    };

Career _$CareerFromJson(Map<String, dynamic> json) => Career(
      organization: json['organization'] as String,
      position: json['position'] as String,
      startYear: (json['start_year'] as num).toInt(),
      endYear: (json['end_year'] as num?)?.toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CareerToJson(Career instance) => <String, dynamic>{
      'organization': instance.organization,
      'position': instance.position,
      'start_year': instance.startYear,
      'end_year': instance.endYear,
      'description': instance.description,
    };

BankAccount _$BankAccountFromJson(Map<String, dynamic> json) => BankAccount(
      id: json['id'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolder: json['account_holder'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BankAccountToJson(BankAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_name': instance.bankName,
      'account_number': instance.accountNumber,
      'account_holder': instance.accountHolder,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt.toIso8601String(),
    };

FeeRange _$FeeRangeFromJson(Map<String, dynamic> json) => FeeRange(
      minFee: (json['min_fee'] as num).toInt(),
      maxFee: (json['max_fee'] as num).toInt(),
      duration: (json['duration'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$FeeRangeToJson(FeeRange instance) => <String, dynamic>{
      'min_fee': instance.minFee,
      'max_fee': instance.maxFee,
      'duration': instance.duration,
    };

Certificate _$CertificateFromJson(Map<String, dynamic> json) => Certificate(
      id: json['id'] as String,
      type: $enumDecode(_$CertificateTypeEnumMap, json['type']),
      name: json['name'] as String,
      issuingBody: json['issuing_body'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      certificateNumber: json['certificate_number'] as String?,
      imageUrl: json['image_url'] as String,
      status: $enumDecode(_$CertificateStatusEnumMap, json['status']),
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
    );

Map<String, dynamic> _$CertificateToJson(Certificate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$CertificateTypeEnumMap[instance.type]!,
      'name': instance.name,
      'issuing_body': instance.issuingBody,
      'issue_date': instance.issueDate.toIso8601String(),
      'certificate_number': instance.certificateNumber,
      'image_url': instance.imageUrl,
      'status': _$CertificateStatusEnumMap[instance.status]!,
      'rejection_reason': instance.rejectionReason,
      'submitted_at': instance.submittedAt.toIso8601String(),
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
    };

const _$CertificateTypeEnumMap = {
  CertificateType.musicTeacher: 'musicTeacher',
  CertificateType.cultureArtsEducator: 'cultureArtsEducator',
  CertificateType.schoolTeacher: 'schoolTeacher',
  CertificateType.conservatory: 'conservatory',
  CertificateType.degree: 'degree',
  CertificateType.performance: 'performance',
  CertificateType.other: 'other',
};

const _$CertificateStatusEnumMap = {
  CertificateStatus.pending: 'pending',
  CertificateStatus.approved: 'approved',
  CertificateStatus.rejected: 'rejected',
};

TeacherVerification _$TeacherVerificationFromJson(Map<String, dynamic> json) =>
    TeacherVerification(
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] == null
          ? null
          : DateTime.parse(json['phone_verified_at'] as String),
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => Certificate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TeacherVerificationToJson(
        TeacherVerification instance) =>
    <String, dynamic>{
      'is_phone_verified': instance.isPhoneVerified,
      'phone_number': instance.phoneNumber,
      'phone_verified_at': instance.phoneVerifiedAt?.toIso8601String(),
      'certificates': instance.certificates.map((e) => e.toJson()).toList(),
    };

ProfileVisibilitySettings _$ProfileVisibilitySettingsFromJson(
        Map<String, dynamic> json) =>
    ProfileVisibilitySettings(
      isSearchable: json['is_searchable'] as bool? ?? true,
      nameVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['name_visibility']) ??
          ProfileVisibility.public,
      photoVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['photo_visibility']) ??
          ProfileVisibility.public,
      contactVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['contact_visibility']) ??
          ProfileVisibility.students,
      feeVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['fee_visibility']) ??
          ProfileVisibility.public,
      careerVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['career_visibility']) ??
          ProfileVisibility.public,
      certificateVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['certificate_visibility']) ??
          ProfileVisibility.public,
    );

Map<String, dynamic> _$ProfileVisibilitySettingsToJson(
        ProfileVisibilitySettings instance) =>
    <String, dynamic>{
      'is_searchable': instance.isSearchable,
      'name_visibility': _$ProfileVisibilityEnumMap[instance.nameVisibility]!,
      'photo_visibility': _$ProfileVisibilityEnumMap[instance.photoVisibility]!,
      'contact_visibility':
          _$ProfileVisibilityEnumMap[instance.contactVisibility]!,
      'fee_visibility': _$ProfileVisibilityEnumMap[instance.feeVisibility]!,
      'career_visibility':
          _$ProfileVisibilityEnumMap[instance.careerVisibility]!,
      'certificate_visibility':
          _$ProfileVisibilityEnumMap[instance.certificateVisibility]!,
    };

const _$ProfileVisibilityEnumMap = {
  ProfileVisibility.public: 'public',
  ProfileVisibility.students: 'students',
  ProfileVisibility.private: 'private',
};

TeacherProfile _$TeacherProfileFromJson(Map<String, dynamic> json) =>
    TeacherProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      organizationId: json['organization_id'] as String?,
      organizationName: json['organization_name'] as String?,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      profileImage: json['profile_image'] as String?,
      backgroundImage: json['background_image'] as String?,
      instruments: (json['instruments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      disciplineId: json['discipline_id'] as String?,
      introduction: json['introduction'] as String,
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      lessonAreas: (json['lesson_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lessonTypes: (json['lesson_types'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$LessonTypeOptionEnumMap, e))
          .toList(),
      feeRange: json['fee_range'] == null
          ? null
          : FeeRange.fromJson(json['fee_range'] as Map<String, dynamic>),
      education: (json['education'] as List<dynamic>?)
          ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList(),
      career: (json['career'] as List<dynamic>?)
          ?.map((e) => Career.fromJson(e as Map<String, dynamic>))
          .toList(),
      postalCode: json['postal_code'] as String?,
      address: json['address'] as String?,
      addressDetail: json['address_detail'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      teachingStyle: json['teaching_style'] as String?,
      portfolioVideoUrls: (json['portfolio_video_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bankAccount: json['bank_account'] == null
          ? null
          : BankAccount.fromJson(json['bank_account'] as Map<String, dynamic>),
      bankAccounts: (json['bank_accounts'] as List<dynamic>?)
              ?.map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      verification: json['verification'] == null
          ? const TeacherVerification()
          : TeacherVerification.fromJson(
              json['verification'] as Map<String, dynamic>),
      visibilitySettings: json['visibility_settings'] == null
          ? const ProfileVisibilitySettings()
          : ProfileVisibilitySettings.fromJson(
              json['visibility_settings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeacherProfileToJson(TeacherProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'organization_id': instance.organizationId,
      'organization_name': instance.organizationName,
      'name': instance.name,
      'nickname': instance.nickname,
      'profile_image': instance.profileImage,
      'background_image': instance.backgroundImage,
      'instruments': instance.instruments,
      'discipline_id': instance.disciplineId,
      'introduction': instance.introduction,
      'experience_years': instance.experienceYears,
      'lesson_areas': instance.lessonAreas,
      'lesson_types': instance.lessonTypes
          ?.map((e) => _$LessonTypeOptionEnumMap[e]!)
          .toList(),
      'fee_range': instance.feeRange?.toJson(),
      'education': instance.education?.map((e) => e.toJson()).toList(),
      'career': instance.career?.map((e) => e.toJson()).toList(),
      'postal_code': instance.postalCode,
      'address': instance.address,
      'address_detail': instance.addressDetail,
      'specialties': instance.specialties,
      'teaching_style': instance.teachingStyle,
      'portfolio_video_urls': instance.portfolioVideoUrls,
      'bank_account': instance.bankAccount?.toJson(),
      'bank_accounts': instance.bankAccounts.map((e) => e.toJson()).toList(),
      'verification': instance.verification.toJson(),
      'visibility_settings': instance.visibilitySettings.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$LessonTypeOptionEnumMap = {
  LessonTypeOption.inPerson: 'inPerson',
  LessonTypeOption.online: 'online',
  LessonTypeOption.visit: 'visit',
};
