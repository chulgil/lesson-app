import 'package:flutter/material.dart';

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
