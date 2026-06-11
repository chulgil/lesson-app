// Teacher settings domain entity
// Moved from lib/features/profile/domain/entities/teacher_settings.dart for Clean Architecture

import 'package:json_annotation/json_annotation.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';

part 'teacher_settings.g.dart';

/// Teacher settings for lesson management
@JsonSerializable()
class TeacherSettings {
  final String id;
  final List<String> instruments;

  /// @deprecated — use [lessonDurationMinutes].
  /// Field kept for BE JSON compat (W1 2026-06-11 spec §5.2).
  @Deprecated(
    'Use lessonDurationMinutes — TeacherSettings 단일 SSOT (W1 2026-06-11)',
  )
  final int defaultLessonDuration; // in minutes
  final List<int> customLessonDurations; // custom durations added by teacher
  final List<int>
  disabledDurations; // disabled durations (both default and custom)
  /// @deprecated — use [TeacherAvailability.weeklySchedules] (schedule 도메인 SSOT).
  /// Field kept for BE JSON compat (W1 2026-06-11 spec §5.2).
  @Deprecated(
    'Use TeacherAvailability.weeklySchedules — schedule 도메인 SSOT (W1 2026-06-11 spec §5.2)',
  )
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<TimeSlot> availableSlots;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Break time between lessons in minutes (0, 5, 10, 15, 20, 30)
  /// @deprecated — use [TeacherAvailability.breakTimeBetweenLessons] (운영시간 묶음 SSOT).
  /// Field kept for BE JSON compat (W1 2026-06-11 spec §5.2).
  @Deprecated(
    'Use TeacherAvailability.breakTimeBetweenLessons — 운영시간 묶음 SSOT (W1 2026-06-11 spec §5.2)',
  )
  final int breakTimeBetweenLessons;

  /// Minimum hours before booking (e.g., 24 = must book at least 24 hours ahead)
  final int minBookingHours;

  /// Lesson price table: {"바이올린": {"beginner": 40000, "intermediate": 50000, "advanced": 70000}}
  final Map<String, Map<String, int>>? lessonPriceTable;

  /// Whether trial lessons are free
  final bool trialLessonFree;

  /// Custom booking guidance message shown to students in the lesson request form.
  /// null or empty → default message is used.
  final String? bookingGuidanceMessage;

  /// Default booking guidance message
  static const defaultGuidanceMessage = '희망레슨시간은 상담가능하니 편하게 메시지 주세요.';

  /// Returns custom message if set, otherwise default
  String get effectiveGuidanceMessage =>
      (bookingGuidanceMessage != null && bookingGuidanceMessage!.isNotEmpty)
          ? bookingGuidanceMessage!
          : defaultGuidanceMessage;

  const TeacherSettings({
    required this.id,
    required this.instruments,
    @Deprecated(
      'Use lessonDurationMinutes — TeacherSettings 단일 SSOT (W1 2026-06-11)',
    )
    int? defaultLessonDuration,
    int? lessonDurationMinutes,
    this.customLessonDurations = const [],
    this.disabledDurations = const [],
    @Deprecated(
      'Use TeacherAvailability.weeklySchedules — schedule 도메인 SSOT (W1 2026-06-11 spec §5.2)',
    )
    this.availableSlots = const [],
    required this.createdAt,
    this.updatedAt,
    @Deprecated(
      'Use TeacherAvailability.breakTimeBetweenLessons — 운영시간 묶음 SSOT (W1 2026-06-11 spec §5.2)',
    )
    this.breakTimeBetweenLessons = 0,
    this.minBookingHours = 24,
    this.lessonPriceTable,
    this.trialLessonFree = false,
    this.bookingGuidanceMessage,
  }) : defaultLessonDuration =
           lessonDurationMinutes ?? defaultLessonDuration ?? 50;

  /// Lesson duration in minutes — SSOT (W1 2026-06-11 spec §5.2).
  /// Default 50 (Korean music lesson standard).
  /// Replaces deprecated [defaultLessonDuration] / `slotDurationMinutes` (schedule).
  // ignore: deprecated_member_use_from_same_package
  int get lessonDurationMinutes => defaultLessonDuration;

  factory TeacherSettings.fromJson(Map<String, dynamic> json) =>
      _$TeacherSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherSettingsToJson(this);

  /// Get all configured durations (default + custom, sorted) - includes disabled
  List<int> get allConfiguredDurations {
    final all =
        {...LessonDurations.defaults, ...customLessonDurations}.toList();
    all.sort();
    return all;
  }

  /// Get only active lesson durations (excludes disabled)
  List<int> get allLessonDurations {
    return allConfiguredDurations
        .where((d) => !disabledDurations.contains(d))
        .toList();
  }

  /// Check if a duration is disabled
  bool isDurationDisabled(int duration) => disabledDurations.contains(duration);

  /// Get lesson duration as formatted string (uses [lessonDurationMinutes] SSOT).
  String get formattedDuration {
    final m = lessonDurationMinutes;
    if (m >= 60) {
      final hours = m ~/ 60;
      final minutes = m % 60;
      if (minutes == 0) {
        return '$hours시간';
      }
      return '$hours시간 $minutes분';
    }
    return '$m분';
  }

  /// Get active slots only
  List<TimeSlot> get activeSlots =>
      availableSlots.where((slot) => slot.isActive).toList();

  /// Get slots for a specific day
  List<TimeSlot> getSlotsForDay(int dayOfWeek) =>
      availableSlots.where((slot) => slot.dayOfWeek == dayOfWeek).toList();

  /// Get price for a specific instrument and level
  int? getPrice(String instrument, String level) {
    return lessonPriceTable?[instrument]?[level];
  }

  /// Get price using [UnifiedExperienceLevel] enum (maps enum name to key).
  int? getPriceByExperience(String instrument, UnifiedExperienceLevel level) {
    return getPrice(instrument, level.name);
  }

  TeacherSettings copyWith({
    String? id,
    List<String>? instruments,
    @Deprecated(
      'Use lessonDurationMinutes — TeacherSettings 단일 SSOT (W1 2026-06-11)',
    )
    int? defaultLessonDuration,
    int? lessonDurationMinutes,
    List<int>? customLessonDurations,
    List<int>? disabledDurations,
    @Deprecated(
      'Use TeacherAvailability.weeklySchedules — schedule 도메인 SSOT (W1 2026-06-11 spec §5.2)',
    )
    List<TimeSlot>? availableSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Deprecated(
      'Use TeacherAvailability.breakTimeBetweenLessons — 운영시간 묶음 SSOT (W1 2026-06-11 spec §5.2)',
    )
    int? breakTimeBetweenLessons,
    int? minBookingHours,
    Map<String, Map<String, int>>? lessonPriceTable,
    bool? trialLessonFree,
    String? bookingGuidanceMessage,
  }) {
    return TeacherSettings(
      id: id ?? this.id,
      instruments: instruments ?? this.instruments,
      lessonDurationMinutes:
          lessonDurationMinutes ??
          defaultLessonDuration ??
          this.lessonDurationMinutes,
      customLessonDurations:
          customLessonDurations ?? this.customLessonDurations,
      disabledDurations: disabledDurations ?? this.disabledDurations,
      availableSlots: availableSlots ?? this.availableSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      breakTimeBetweenLessons:
          breakTimeBetweenLessons ?? this.breakTimeBetweenLessons,
      minBookingHours: minBookingHours ?? this.minBookingHours,
      lessonPriceTable: lessonPriceTable ?? this.lessonPriceTable,
      trialLessonFree: trialLessonFree ?? this.trialLessonFree,
      bookingGuidanceMessage:
          bookingGuidanceMessage ?? this.bookingGuidanceMessage,
    );
  }
}

/// Predefined list of common instruments
class InstrumentList {
  static const List<String> all = [
    '바이올린',
    '비올라',
    '첼로',
    '콘트라베이스',
    '피아노',
    '플루트',
    '클라리넷',
    '오보에',
    '바순',
    '호른',
    '트럼펫',
    '트롬본',
    '튜바',
    '타악기',
    '하프',
    '기타',
    '성악',
    '작곡/이론',
  ];

  /// Get commonly used instruments (top 10)
  static List<String> get common => all.take(10).toList();
}

/// Predefined lesson durations
class LessonDurations {
  /// Default preset durations
  static const List<int> defaults = [30, 45, 60, 90, 120];

  /// Minimum allowed duration (minutes)
  static const int minDuration = 10;

  /// Maximum allowed duration (minutes)
  static const int maxDuration = 240;

  static String format(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours시간';
      }
      return '$hours시간 $mins분';
    }
    return '$minutes분';
  }

  /// Check if duration is valid
  static bool isValid(int minutes) {
    return minutes >= minDuration && minutes <= maxDuration;
  }
}
