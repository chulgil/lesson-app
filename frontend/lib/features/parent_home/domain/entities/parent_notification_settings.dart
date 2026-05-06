// Parent notification settings domain entity
// Moved from lib/features/parent_home/domain/entities/parent_notification_settings.dart for Clean Architecture

/// Notification category for grouping settings
enum NotificationCategory {
  payment, // Deposit status, required, cannot be disabled
  lesson,
  assignment,
  practice,
  communication,
  report,
}

/// Stable setting identifiers. UI labels are resolved in presentation.
enum NotificationSettingType {
  paymentRequest,
  paymentComplete,
  paymentDueSoon,
  lessonChange,
  lessonCancel,
  lessonStart,
  lessonEnd,
  newAssignment,
  assignmentIncomplete,
  practiceComplete,
  streakAchievement,
  teacherMessage,
  lessonNoteUpdate,
  weeklyReport,
  monthlyReport,
}

/// Parent notification settings model
/// Parents can customize which notifications they receive
class ParentNotificationSettings {
  final String id;
  final String parentId;

  // Deposit status (required, always ON)
  final bool paymentRequest; // Cannot be disabled
  final bool paymentComplete; // Cannot be disabled
  final bool paymentDueSoon; // Configurable

  // Lesson
  final bool lessonChange; // Lesson schedule changed
  final bool lessonCancel; // Lesson cancelled/no-show
  final bool lessonStart; // Lesson starting soon
  final bool lessonEnd; // Lesson completed

  // Assignment
  final bool newAssignment; // New homework assigned
  final bool assignmentIncomplete; // Incomplete assignment reminder (D-1)

  // Practice
  final bool practiceComplete; // Daily practice completed
  final bool streakAchievement; // Streak milestone reached

  // Communication
  final bool teacherMessage; // New message from teacher
  final bool lessonNoteUpdate; // Lesson note updated

  // Report
  final bool weeklyReport; // Weekly summary
  final bool monthlyReport; // Monthly detailed report

  final DateTime createdAt;
  final DateTime? updatedAt;

  const ParentNotificationSettings({
    required this.id,
    required this.parentId,
    // Deposit status (required)
    this.paymentRequest = true, // Cannot change
    this.paymentComplete = true, // Cannot change
    this.paymentDueSoon = true,
    // Lesson (recommended ON)
    this.lessonChange = true,
    this.lessonCancel = true,
    this.lessonStart = false,
    this.lessonEnd = false,
    // Assignment (recommended ON)
    this.newAssignment = true,
    this.assignmentIncomplete = true,
    // Practice (default OFF)
    this.practiceComplete = false,
    this.streakAchievement = false,
    // Communication (recommended ON)
    this.teacherMessage = true,
    this.lessonNoteUpdate = false,
    // Report (recommended ON)
    this.weeklyReport = true,
    this.monthlyReport = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create default settings for a new parent
  factory ParentNotificationSettings.defaultSettings({
    required String id,
    required String parentId,
  }) {
    return ParentNotificationSettings(
      id: id,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
  }

  /// Get settings grouped by category
  Map<NotificationCategory, List<NotificationItem>> get groupedSettings {
    return {
      NotificationCategory.payment: [
        NotificationItem(
          NotificationSettingType.paymentRequest,
          paymentRequest,
          isRequired: true,
        ),
        NotificationItem(
          NotificationSettingType.paymentComplete,
          paymentComplete,
          isRequired: true,
        ),
        NotificationItem(
          NotificationSettingType.paymentDueSoon,
          paymentDueSoon,
        ),
      ],
      NotificationCategory.lesson: [
        NotificationItem(
          NotificationSettingType.lessonChange,
          lessonChange,
          isRecommended: true,
        ),
        NotificationItem(
          NotificationSettingType.lessonCancel,
          lessonCancel,
          isRecommended: true,
        ),
        NotificationItem(NotificationSettingType.lessonStart, lessonStart),
        NotificationItem(NotificationSettingType.lessonEnd, lessonEnd),
      ],
      NotificationCategory.assignment: [
        NotificationItem(
          NotificationSettingType.newAssignment,
          newAssignment,
          isRecommended: true,
        ),
        NotificationItem(
          NotificationSettingType.assignmentIncomplete,
          assignmentIncomplete,
          isRecommended: true,
        ),
      ],
      NotificationCategory.practice: [
        NotificationItem(
          NotificationSettingType.practiceComplete,
          practiceComplete,
        ),
        NotificationItem(
          NotificationSettingType.streakAchievement,
          streakAchievement,
        ),
      ],
      NotificationCategory.communication: [
        NotificationItem(
          NotificationSettingType.teacherMessage,
          teacherMessage,
          isRecommended: true,
        ),
        NotificationItem(
          NotificationSettingType.lessonNoteUpdate,
          lessonNoteUpdate,
        ),
      ],
      NotificationCategory.report: [
        NotificationItem(
          NotificationSettingType.weeklyReport,
          weeklyReport,
          isRecommended: true,
        ),
        NotificationItem(
          NotificationSettingType.monthlyReport,
          monthlyReport,
          isRecommended: true,
        ),
      ],
    };
  }

  /// Get count of enabled non-required notifications
  int get enabledCount {
    int count = 0;
    // Don't count required ones
    if (paymentDueSoon) count++;
    if (lessonChange) count++;
    if (lessonCancel) count++;
    if (lessonStart) count++;
    if (lessonEnd) count++;
    if (newAssignment) count++;
    if (assignmentIncomplete) count++;
    if (practiceComplete) count++;
    if (streakAchievement) count++;
    if (teacherMessage) count++;
    if (lessonNoteUpdate) count++;
    if (weeklyReport) count++;
    if (monthlyReport) count++;
    return count;
  }

  /// Total configurable (non-required) items
  static const int totalConfigurable = 13;

  /// Copy with new values
  ParentNotificationSettings copyWith({
    String? id,
    String? parentId,
    bool? paymentDueSoon,
    bool? lessonChange,
    bool? lessonCancel,
    bool? lessonStart,
    bool? lessonEnd,
    bool? newAssignment,
    bool? assignmentIncomplete,
    bool? practiceComplete,
    bool? streakAchievement,
    bool? teacherMessage,
    bool? lessonNoteUpdate,
    bool? weeklyReport,
    bool? monthlyReport,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentNotificationSettings(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      // Deposit status required fields cannot be changed
      paymentRequest: true,
      paymentComplete: true,
      paymentDueSoon: paymentDueSoon ?? this.paymentDueSoon,
      lessonChange: lessonChange ?? this.lessonChange,
      lessonCancel: lessonCancel ?? this.lessonCancel,
      lessonStart: lessonStart ?? this.lessonStart,
      lessonEnd: lessonEnd ?? this.lessonEnd,
      newAssignment: newAssignment ?? this.newAssignment,
      assignmentIncomplete: assignmentIncomplete ?? this.assignmentIncomplete,
      practiceComplete: practiceComplete ?? this.practiceComplete,
      streakAchievement: streakAchievement ?? this.streakAchievement,
      teacherMessage: teacherMessage ?? this.teacherMessage,
      lessonNoteUpdate: lessonNoteUpdate ?? this.lessonNoteUpdate,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      monthlyReport: monthlyReport ?? this.monthlyReport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentNotificationSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Parent notification item state.
class NotificationItem {
  final NotificationSettingType type;
  final bool isEnabled;
  final bool isRequired;
  final bool isRecommended;

  const NotificationItem(
    this.type,
    this.isEnabled, {
    this.isRequired = false,
    this.isRecommended = false,
  });
}
