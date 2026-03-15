import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/theme/app_colors.dart';
// Import shared enums from core layer
import '../../../../core/models/shared_enums.dart';

// Re-export shared enums for convenience
export '../../../../core/models/shared_enums.dart'
    show AgeGroup, ConnectionStatus, PracticeLevel, ConnectionStatusHelper;

part 'student.g.dart';

/// Student status enum (enrollment status)
enum StudentStatus {
  trial, // 체험 중
  active, // 정규 등록
  paused, // 휴강
  inactive; // 수강 종료

  String get label {
    switch (this) {
      case StudentStatus.trial:
        return '체험';
      case StudentStatus.active:
        return '정규';
      case StudentStatus.paused:
        return '휴강';
      case StudentStatus.inactive:
        return '종료';
    }
  }

  Color get color {
    switch (this) {
      case StudentStatus.trial:
        return AppColors.warning;
      case StudentStatus.active:
        return AppColors.success;
      case StudentStatus.paused:
        return AppColors.textTertiaryLight;
      case StudentStatus.inactive:
        return AppColors.error;
    }
  }

  /// Check if student is currently enrolled (trial or active)
  bool get isEnrolled =>
      this == StudentStatus.trial || this == StudentStatus.active;
}

/// Student level enum
enum StudentLevel {
  beginner, // 입문
  elementary, // 초급
  intermediate, // 중급
  advanced; // 고급

  String get label {
    switch (this) {
      case StudentLevel.beginner:
        return '입문';
      case StudentLevel.elementary:
        return '초급';
      case StudentLevel.intermediate:
        return '중급';
      case StudentLevel.advanced:
        return '고급';
    }
  }

  /// Default monthly fee for each level
  int get defaultMonthlyFee {
    switch (this) {
      case StudentLevel.beginner:
        return 160000;
      case StudentLevel.elementary:
        return 180000;
      case StudentLevel.intermediate:
        return 200000;
      case StudentLevel.advanced:
        return 240000;
    }
  }

  /// Default trial lesson fee
  static int get defaultTrialFee => 30000;
}

/// Practice status enum
enum PracticeStatus {
  good,
  normal,
  poor,
  paused;

  String get label {
    switch (this) {
      case PracticeStatus.good:
        return '우수';
      case PracticeStatus.normal:
        return '보통';
      case PracticeStatus.poor:
        return '부족';
      case PracticeStatus.paused:
        return '휴강';
    }
  }

  Color get color {
    switch (this) {
      case PracticeStatus.good:
        return AppColors.practiceGood;
      case PracticeStatus.normal:
        return AppColors.practiceNormal;
      case PracticeStatus.poor:
        return AppColors.practicePoor;
      case PracticeStatus.paused:
        return AppColors.practicePaused;
    }
  }
}

/// Name-based profile color generation for API responses.
Color _profileColorFromName(String name) {
  const colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.info,
    AppColors.profileRed,
    AppColors.profileTeal,
    AppColors.profilePurple,
    AppColors.profileOrange,
  ];
  if (name.isEmpty) return colors[0];
  final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
  return colors[hash % colors.length];
}

/// Student model
@JsonSerializable()
class Student {
  final String id;
  final String name;
  final String instrument;
  final StudentLevel level;
  final StudentStatus
  status; // Enrollment status (trial, active, paused, inactive)
  final int monthlyFee; // Custom monthly fee (can differ from level default)
  final int lessonsPerWeek; // 1 = 주 1회 (월 4회), 2 = 주 2회 (월 8회)
  final String? phone;
  final String? parentPhone;
  final String? email;
  final String? profileImageUrl;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Color profileColor;
  final String? lessonDay;
  final String? lessonTime;
  final int lessonDuration;
  final int totalLessons;
  final int monthlyLessons;
  final PracticeStatus practiceStatus;
  final int practiceRate; // days per week
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  // Age group related fields
  final DateTime? birthDate; // 생년월일 (비공개, 연령 그룹 자동 계산용)
  final AgeGroup? manualAgeGroup; // 수동 설정 연령 그룹 (학생 앱 미사용 시)

  // V2: Connection status (mutual follow system)
  final ConnectionStatus connectionStatus; // App connection status
  final DateTime?
  connectedAt; // When mutual follow was established (for newStudent check)

  // V2: Break (휴강) related fields
  final String? breakReason; // Reason for break
  final DateTime? expectedReturnDate; // Expected return date from break

  // V2: Practice level (calculated from practice records)
  final PracticeLevel? practiceLevel; // Calculated practice performance

  // V3: Address fields (for lesson location auto-fill)
  final String? postalCode; // 우편번호 (5자리)
  final String? address; // 기본주소 (시/구/동)
  final String? addressDetail; // 상세주소 (비공개, 연결된 선생님에게만)
  final String? district; // 구/동 이름 (검색용, 우편번호에서 자동추출)

  Student({
    required this.id,
    required String name,
    required this.instrument,
    this.level = StudentLevel.intermediate,
    this.status = StudentStatus.trial, // Default to trial for new students
    this.monthlyFee = 200000,
    this.lessonsPerWeek = 1,
    this.phone,
    this.parentPhone,
    this.email,
    this.profileImageUrl,
    Color? profileColor,
    this.lessonDay,
    this.lessonTime,
    this.lessonDuration = 60,
    this.totalLessons = 0,
    this.monthlyLessons = 0,
    this.practiceStatus = PracticeStatus.normal,
    this.practiceRate = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.birthDate,
    this.manualAgeGroup,
    this.connectionStatus = ConnectionStatus.offline,
    this.connectedAt,
    this.breakReason,
    this.expectedReturnDate,
    this.practiceLevel,
    this.postalCode,
    this.address,
    this.addressDetail,
    this.district,
  }) : name = name,
       profileColor = profileColor ?? _profileColorFromName(name);

  /// Create from JSON (profileColor is auto-generated from name).
  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => _$StudentToJson(this);

  /// Calculate age group from birth date (private)
  AgeGroup? get calculatedAgeGroup {
    if (birthDate == null) return null;
    return AgeGroup.fromBirthDate(birthDate!);
  }

  /// Effective age group (calculated from birthDate, or manual, or default student)
  AgeGroup get effectiveAgeGroup =>
      calculatedAgeGroup ?? manualAgeGroup ?? AgeGroup.student;

  /// V2: Check if student is on break (휴강 상태)
  bool get isOnBreak => status == StudentStatus.paused;

  /// V2: Get effective practice level (considers break status)
  PracticeLevel get effectivePracticeLevel {
    if (isOnBreak) return PracticeLevel.onBreak;
    return practiceLevel ?? PracticeLevel.newStudent;
  }

  /// V2: Check if student is newly connected (less than 7 days)
  bool get isNewStudent {
    if (connectedAt == null) return false;
    return DateTime.now().difference(connectedAt!).inDays < 7;
  }

  /// V2: Check if student has app connection
  bool get isAppConnected => connectionStatus == ConnectionStatus.connected;

  /// Monthly lesson count based on lessons per week
  int get monthlyLessonCount => lessonsPerWeek * 4;

  /// Calculate per-lesson fee (monthly / lesson count)
  int get lessonFee => (monthlyFee / monthlyLessonCount).round();

  /// Get formatted lesson frequency
  String get lessonFrequency {
    switch (lessonsPerWeek) {
      case 1:
        return '주 1회 (월 4회)';
      case 2:
        return '주 2회 (월 8회)';
      default:
        return '주 $lessonsPerWeek회 (월 ${lessonsPerWeek * 4}회)';
    }
  }

  /// Get short lesson frequency label
  String get lessonFrequencyShort {
    switch (lessonsPerWeek) {
      case 1:
        return '주1회';
      case 2:
        return '주2회';
      default:
        return '주${lessonsPerWeek}회';
    }
  }

  /// Format monthly fee as Korean won
  String get formattedMonthlyFee {
    final formatter = monthlyFee.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatter원';
  }

  /// Format lesson fee as Korean won
  String get formattedLessonFee {
    final formatter = lessonFee.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatter원';
  }

  /// Get first character of name for avatar
  String get initial => name.isNotEmpty ? name[0] : '?';

  /// Get formatted lesson schedule
  String? get lessonSchedule {
    if (lessonDay == null || lessonTime == null) return null;
    return '$lessonDay $lessonTime';
  }

  /// Check if student has a registered address
  bool get hasAddress => postalCode != null && postalCode!.isNotEmpty;

  /// Get display-friendly address (without detail for privacy)
  String? get displayAddress {
    if (address == null) return null;
    return address;
  }

  /// Get full address including detail (for connected teacher only)
  String? get fullAddress {
    if (address == null) return null;
    if (addressDetail != null && addressDetail!.isNotEmpty) {
      return '$address $addressDetail';
    }
    return address;
  }

  /// Copy with new values
  Student copyWith({
    String? id,
    String? name,
    String? instrument,
    StudentLevel? level,
    StudentStatus? status,
    int? monthlyFee,
    int? lessonsPerWeek,
    String? phone,
    String? parentPhone,
    String? email,
    String? profileImageUrl,
    Color? profileColor,
    String? lessonDay,
    String? lessonTime,
    int? lessonDuration,
    int? totalLessons,
    int? monthlyLessons,
    PracticeStatus? practiceStatus,
    int? practiceRate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? birthDate,
    AgeGroup? manualAgeGroup,
    ConnectionStatus? connectionStatus,
    DateTime? connectedAt,
    String? breakReason,
    DateTime? expectedReturnDate,
    PracticeLevel? practiceLevel,
    String? postalCode,
    String? address,
    String? addressDetail,
    String? district,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      level: level ?? this.level,
      status: status ?? this.status,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      lessonsPerWeek: lessonsPerWeek ?? this.lessonsPerWeek,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileColor: profileColor ?? this.profileColor,
      lessonDay: lessonDay ?? this.lessonDay,
      lessonTime: lessonTime ?? this.lessonTime,
      lessonDuration: lessonDuration ?? this.lessonDuration,
      totalLessons: totalLessons ?? this.totalLessons,
      monthlyLessons: monthlyLessons ?? this.monthlyLessons,
      practiceStatus: practiceStatus ?? this.practiceStatus,
      practiceRate: practiceRate ?? this.practiceRate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      birthDate: birthDate ?? this.birthDate,
      manualAgeGroup: manualAgeGroup ?? this.manualAgeGroup,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedAt: connectedAt ?? this.connectedAt,
      breakReason: breakReason ?? this.breakReason,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      practiceLevel: practiceLevel ?? this.practiceLevel,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      district: district ?? this.district,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
