import 'package:flutter/material.dart';

/// Student status enum (enrollment status)
enum StudentStatus {
  trial,    // 체험 중
  active,   // 정규 등록
  paused,   // 휴강
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
        return const Color(0xFFFF9800); // Orange
      case StudentStatus.active:
        return const Color(0xFF4CAF50); // Green
      case StudentStatus.paused:
        return const Color(0xFF9E9E9E); // Grey
      case StudentStatus.inactive:
        return const Color(0xFFE57373); // Red
    }
  }

  /// Check if student is currently enrolled (trial or active)
  bool get isEnrolled => this == StudentStatus.trial || this == StudentStatus.active;
}

/// Student level enum
enum StudentLevel {
  beginner,    // 입문
  elementary,  // 초급
  intermediate, // 중급
  advanced;    // 고급

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
        return const Color(0xFF2E8B57);
      case PracticeStatus.normal:
        return const Color(0xFFF4A460);
      case PracticeStatus.poor:
        return const Color(0xFFDC143C);
      case PracticeStatus.paused:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Student model
class Student {
  final String id;
  final String name;
  final String instrument;
  final StudentLevel level;
  final StudentStatus status; // Enrollment status (trial, active, paused, inactive)
  final int monthlyFee; // Custom monthly fee (can differ from level default)
  final int lessonsPerWeek; // 1 = 주 1회 (월 4회), 2 = 주 2회 (월 8회)
  final String? phone;
  final String? parentPhone;
  final String? email;
  final String? profileImageUrl;
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

  const Student({
    required this.id,
    required this.name,
    required this.instrument,
    this.level = StudentLevel.intermediate,
    this.status = StudentStatus.trial, // Default to trial for new students
    this.monthlyFee = 200000,
    this.lessonsPerWeek = 1,
    this.phone,
    this.parentPhone,
    this.email,
    this.profileImageUrl,
    required this.profileColor,
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
  });

  /// Monthly lesson count based on lessons per week
  int get monthlyLessonCount => lessonsPerWeek * 4;

  /// Calculate per-lesson fee (monthly / lesson count)
  int get lessonFee => (monthlyFee / monthlyLessonCount).round();

  /// Get formatted lesson frequency
  String get lessonFrequency =>
      lessonsPerWeek == 1 ? '주 1회 (월 4회)' : '주 2회 (월 8회)';

  /// Get short lesson frequency label
  String get lessonFrequencyShort => lessonsPerWeek == 1 ? '주1회' : '주2회';

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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
