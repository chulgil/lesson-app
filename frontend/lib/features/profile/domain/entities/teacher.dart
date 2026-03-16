// Teacher domain entity
// Moved from lib/models/teacher.dart for Clean Architecture

import 'package:json_annotation/json_annotation.dart';

part 'teacher.g.dart';

/// Teacher model for lesson booking
@JsonSerializable()
class Teacher {
  final String id;
  final String name;
  final String? profileImageUrl;
  final List<String> instruments;
  final String? bio;
  final String? education;
  final int experienceYears;
  final double? rating;
  final int reviewCount;
  final int trialLessonFee; // in KRW
  final int regularLessonFee; // in KRW (per hour)
  final String? location;
  final bool isAvailable;
  final DateTime createdAt;

  const Teacher({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.instruments,
    this.bio,
    this.education,
    this.experienceYears = 0,
    this.rating,
    this.reviewCount = 0,
    this.trialLessonFee = 30000,
    this.regularLessonFee = 60000,
    this.location,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) =>
      _$TeacherFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherToJson(this);

  /// Get primary instrument (first in list)
  String get primaryInstrument =>
      instruments.isNotEmpty ? instruments.first : '악기 미지정';

  /// Get formatted instruments string
  String get instrumentsText => instruments.join(', ');

  /// Get initials for avatar
  String get initials {
    if (name.isEmpty) return '?';
    return name[0];
  }

  /// Get formatted trial fee
  String get formattedTrialFee => '₩${_formatNumber(trialLessonFee)}';

  /// Get formatted regular fee
  String get formattedRegularFee => '₩${_formatNumber(regularLessonFee)}/시간';

  /// Get formatted experience
  String get formattedExperience {
    if (experienceYears == 0) return '경력 미공개';
    return '경력 $experienceYears년';
  }

  /// Get formatted rating
  String get formattedRating {
    if (rating == null) return '평점 없음';
    return '★ ${rating!.toStringAsFixed(1)} ($reviewCount)';
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      final man = number ~/ 10000;
      final remainder = number % 10000;
      if (remainder == 0) {
        return '$man만';
      }
      return '$man만 ${remainder.toString().padLeft(4, '0')}';
    }
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    List<String>? instruments,
    String? bio,
    String? education,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    int? trialLessonFee,
    int? regularLessonFee,
    String? location,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      instruments: instruments ?? this.instruments,
      bio: bio ?? this.bio,
      education: education ?? this.education,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      trialLessonFee: trialLessonFee ?? this.trialLessonFee,
      regularLessonFee: regularLessonFee ?? this.regularLessonFee,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Teacher search filter options
class TeacherFilter {
  final String? instrument;
  final String? location;
  final int? maxTrialFee;
  final double? minRating;
  final bool onlyAvailable;

  const TeacherFilter({
    this.instrument,
    this.location,
    this.maxTrialFee,
    this.minRating,
    this.onlyAvailable = true,
  });

  TeacherFilter copyWith({
    String? instrument,
    String? location,
    int? maxTrialFee,
    double? minRating,
    bool? onlyAvailable,
  }) {
    return TeacherFilter(
      instrument: instrument ?? this.instrument,
      location: location ?? this.location,
      maxTrialFee: maxTrialFee ?? this.maxTrialFee,
      minRating: minRating ?? this.minRating,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }

  bool matches(Teacher teacher) {
    if (onlyAvailable && !teacher.isAvailable) return false;
    if (instrument != null && !teacher.instruments.contains(instrument)) {
      return false;
    }
    if (location != null &&
        teacher.location != null &&
        !teacher.location!.contains(location!)) {
      return false;
    }
    if (maxTrialFee != null && teacher.trialLessonFee > maxTrialFee!) {
      return false;
    }
    if (minRating != null &&
        (teacher.rating == null || teacher.rating! < minRating!)) {
      return false;
    }
    return true;
  }
}
