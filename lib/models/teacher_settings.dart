import 'time_slot.dart';

/// Teacher settings for lesson management
class TeacherSettings {
  final String id;
  final List<String> instruments;
  final int defaultLessonDuration; // in minutes
  final List<int> customLessonDurations; // custom durations added by teacher
  final List<int> disabledDurations; // disabled durations (both default and custom)
  final List<TimeSlot> availableSlots;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherSettings({
    required this.id,
    required this.instruments,
    this.defaultLessonDuration = 60,
    this.customLessonDurations = const [],
    this.disabledDurations = const [],
    required this.availableSlots,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get all configured durations (default + custom, sorted) - includes disabled
  List<int> get allConfiguredDurations {
    final all = {...LessonDurations.defaults, ...customLessonDurations}.toList();
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

  /// Get default lesson duration as formatted string
  String get formattedDuration {
    if (defaultLessonDuration >= 60) {
      final hours = defaultLessonDuration ~/ 60;
      final minutes = defaultLessonDuration % 60;
      if (minutes == 0) {
        return '$hours시간';
      }
      return '$hours시간 $minutes분';
    }
    return '$defaultLessonDuration분';
  }

  /// Get active slots only
  List<TimeSlot> get activeSlots =>
      availableSlots.where((slot) => slot.isActive).toList();

  /// Get slots for a specific day
  List<TimeSlot> getSlotsForDay(int dayOfWeek) =>
      availableSlots.where((slot) => slot.dayOfWeek == dayOfWeek).toList();

  TeacherSettings copyWith({
    String? id,
    List<String>? instruments,
    int? defaultLessonDuration,
    List<int>? customLessonDurations,
    List<int>? disabledDurations,
    List<TimeSlot>? availableSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherSettings(
      id: id ?? this.id,
      instruments: instruments ?? this.instruments,
      defaultLessonDuration: defaultLessonDuration ?? this.defaultLessonDuration,
      customLessonDurations: customLessonDurations ?? this.customLessonDurations,
      disabledDurations: disabledDurations ?? this.disabledDurations,
      availableSlots: availableSlots ?? this.availableSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
