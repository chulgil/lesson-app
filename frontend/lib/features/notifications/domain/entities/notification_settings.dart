import '../../../../core/domain/value_objects/clock_time.dart';

/// Student notification settings
class StudentNotificationSettings {
  // Lesson reminders
  final bool lessonReminderEnabled;
  final List<Duration> lessonReminderTimes;

  // Practice reminders
  final bool practiceReminderEnabled;
  final ClockTime practiceReminderTime;
  final bool streakWarningEnabled;
  final ClockTime streakWarningTime;

  // Payment reminders
  final bool paymentReminderEnabled;

  // Do Not Disturb
  final bool dndEnabled;
  final ClockTime dndStart;
  final ClockTime dndEnd;

  // Rate limiting
  final int maxDailyNotifications;

  const StudentNotificationSettings({
    this.lessonReminderEnabled = true,
    this.lessonReminderTimes = const [Duration(hours: 24)],
    this.practiceReminderEnabled = true,
    this.practiceReminderTime = const ClockTime(hour: 19, minute: 0),
    this.streakWarningEnabled = true,
    this.streakWarningTime = const ClockTime(hour: 21, minute: 0),
    this.paymentReminderEnabled = true,
    this.dndEnabled = true,
    this.dndStart = const ClockTime(hour: 22, minute: 0),
    this.dndEnd = const ClockTime(hour: 8, minute: 0),
    this.maxDailyNotifications = 5,
  });

  /// Default settings for new students
  static const defaultSettings = StudentNotificationSettings();

  StudentNotificationSettings copyWith({
    bool? lessonReminderEnabled,
    List<Duration>? lessonReminderTimes,
    bool? practiceReminderEnabled,
    ClockTime? practiceReminderTime,
    bool? streakWarningEnabled,
    ClockTime? streakWarningTime,
    bool? paymentReminderEnabled,
    bool? dndEnabled,
    ClockTime? dndStart,
    ClockTime? dndEnd,
    int? maxDailyNotifications,
  }) {
    return StudentNotificationSettings(
      lessonReminderEnabled:
          lessonReminderEnabled ?? this.lessonReminderEnabled,
      lessonReminderTimes: lessonReminderTimes ?? this.lessonReminderTimes,
      practiceReminderEnabled:
          practiceReminderEnabled ?? this.practiceReminderEnabled,
      practiceReminderTime: practiceReminderTime ?? this.practiceReminderTime,
      streakWarningEnabled: streakWarningEnabled ?? this.streakWarningEnabled,
      streakWarningTime: streakWarningTime ?? this.streakWarningTime,
      paymentReminderEnabled:
          paymentReminderEnabled ?? this.paymentReminderEnabled,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      dndStart: dndStart ?? this.dndStart,
      dndEnd: dndEnd ?? this.dndEnd,
      maxDailyNotifications:
          maxDailyNotifications ?? this.maxDailyNotifications,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'lessonReminderEnabled': lessonReminderEnabled,
      'lessonReminderTimes':
          lessonReminderTimes.map((d) => d.inMinutes).toList(),
      'practiceReminderEnabled': practiceReminderEnabled,
      'practiceReminderTime': practiceReminderTime.toJson(),
      'streakWarningEnabled': streakWarningEnabled,
      'streakWarningTime': streakWarningTime.toJson(),
      'paymentReminderEnabled': paymentReminderEnabled,
      'dndEnabled': dndEnabled,
      'dndStart': dndStart.toJson(),
      'dndEnd': dndEnd.toJson(),
      'maxDailyNotifications': maxDailyNotifications,
    };
  }

  /// Create from JSON
  factory StudentNotificationSettings.fromJson(Map<String, dynamic> json) {
    return StudentNotificationSettings(
      lessonReminderEnabled: json['lessonReminderEnabled'] ?? true,
      lessonReminderTimes:
          (json['lessonReminderTimes'] as List<dynamic>?)
              ?.map((m) => Duration(minutes: m as int))
              .toList() ??
          const [Duration(hours: 24)],
      practiceReminderEnabled: json['practiceReminderEnabled'] ?? true,
      practiceReminderTime:
          json['practiceReminderTime'] != null
              ? ClockTime.fromJson(json['practiceReminderTime'])
              : const ClockTime(hour: 19, minute: 0),
      streakWarningEnabled: json['streakWarningEnabled'] ?? true,
      streakWarningTime:
          json['streakWarningTime'] != null
              ? ClockTime.fromJson(json['streakWarningTime'])
              : const ClockTime(hour: 21, minute: 0),
      paymentReminderEnabled: json['paymentReminderEnabled'] ?? true,
      dndEnabled: json['dndEnabled'] ?? true,
      dndStart:
          json['dndStart'] != null
              ? ClockTime.fromJson(json['dndStart'])
              : const ClockTime(hour: 22, minute: 0),
      dndEnd:
          json['dndEnd'] != null
              ? ClockTime.fromJson(json['dndEnd'])
              : const ClockTime(hour: 8, minute: 0),
      maxDailyNotifications: json['maxDailyNotifications'] ?? 5,
    );
  }
}

/// Teacher notification settings
class TeacherNotificationSettings {
  // Lesson reminders
  final bool lessonReminderEnabled;
  final List<Duration> lessonReminderTimes;

  // Student activity alerts
  final bool newStudentAlert;
  final bool trialBookingAlert;
  final bool paymentReceivedAlert;
  final bool studentPracticeReport;
  final bool reviewReceivedAlert;

  // Do Not Disturb
  final bool dndEnabled;
  final ClockTime dndStart;
  final ClockTime dndEnd;

  const TeacherNotificationSettings({
    this.lessonReminderEnabled = true,
    this.lessonReminderTimes = const [Duration(hours: 24)],
    this.newStudentAlert = true,
    this.trialBookingAlert = true,
    this.paymentReceivedAlert = true,
    this.studentPracticeReport = false,
    this.reviewReceivedAlert = true,
    this.dndEnabled = true,
    this.dndStart = const ClockTime(hour: 22, minute: 0),
    this.dndEnd = const ClockTime(hour: 8, minute: 0),
  });

  /// Default settings for new teachers
  static const defaultSettings = TeacherNotificationSettings();

  TeacherNotificationSettings copyWith({
    bool? lessonReminderEnabled,
    List<Duration>? lessonReminderTimes,
    bool? newStudentAlert,
    bool? trialBookingAlert,
    bool? paymentReceivedAlert,
    bool? studentPracticeReport,
    bool? reviewReceivedAlert,
    bool? dndEnabled,
    ClockTime? dndStart,
    ClockTime? dndEnd,
  }) {
    return TeacherNotificationSettings(
      lessonReminderEnabled:
          lessonReminderEnabled ?? this.lessonReminderEnabled,
      lessonReminderTimes: lessonReminderTimes ?? this.lessonReminderTimes,
      newStudentAlert: newStudentAlert ?? this.newStudentAlert,
      trialBookingAlert: trialBookingAlert ?? this.trialBookingAlert,
      paymentReceivedAlert: paymentReceivedAlert ?? this.paymentReceivedAlert,
      studentPracticeReport:
          studentPracticeReport ?? this.studentPracticeReport,
      reviewReceivedAlert: reviewReceivedAlert ?? this.reviewReceivedAlert,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      dndStart: dndStart ?? this.dndStart,
      dndEnd: dndEnd ?? this.dndEnd,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'lessonReminderEnabled': lessonReminderEnabled,
      'lessonReminderTimes':
          lessonReminderTimes.map((d) => d.inMinutes).toList(),
      'newStudentAlert': newStudentAlert,
      'trialBookingAlert': trialBookingAlert,
      'paymentReceivedAlert': paymentReceivedAlert,
      'studentPracticeReport': studentPracticeReport,
      'reviewReceivedAlert': reviewReceivedAlert,
      'dndEnabled': dndEnabled,
      'dndStart': dndStart.toJson(),
      'dndEnd': dndEnd.toJson(),
    };
  }

  /// Create from JSON
  factory TeacherNotificationSettings.fromJson(Map<String, dynamic> json) {
    return TeacherNotificationSettings(
      lessonReminderEnabled: json['lessonReminderEnabled'] ?? true,
      lessonReminderTimes:
          (json['lessonReminderTimes'] as List<dynamic>?)
              ?.map((m) => Duration(minutes: m as int))
              .toList() ??
          const [Duration(hours: 24)],
      newStudentAlert: json['newStudentAlert'] ?? true,
      trialBookingAlert: json['trialBookingAlert'] ?? true,
      paymentReceivedAlert: json['paymentReceivedAlert'] ?? true,
      studentPracticeReport: json['studentPracticeReport'] ?? false,
      reviewReceivedAlert: json['reviewReceivedAlert'] ?? true,
      dndEnabled: json['dndEnabled'] ?? true,
      dndStart:
          json['dndStart'] != null
              ? ClockTime.fromJson(json['dndStart'])
              : const ClockTime(hour: 22, minute: 0),
      dndEnd:
          json['dndEnd'] != null
              ? ClockTime.fromJson(json['dndEnd'])
              : const ClockTime(hour: 8, minute: 0),
    );
  }
}

/// Check if current time is within DND period
bool isInDndPeriod(ClockTime dndStart, ClockTime dndEnd, {DateTime? now}) {
  final effectiveNow = now ?? DateTime.now();
  final nowMinutes = effectiveNow.hour * 60 + effectiveNow.minute;
  final startMinutes = dndStart.inMinutes;
  final endMinutes = dndEnd.inMinutes;

  // Handle midnight crossover (e.g., 22:00 - 08:00)
  if (startMinutes > endMinutes) {
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  return nowMinutes >= startMinutes && nowMinutes < endMinutes;
}
