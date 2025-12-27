/// Notification category for grouping settings
enum NotificationCategory {
  payment, // Required, cannot be disabled
  lesson,
  assignment,
  practice,
  communication,
  report;

  String get label {
    switch (this) {
      case NotificationCategory.payment:
        return '결제';
      case NotificationCategory.lesson:
        return '레슨';
      case NotificationCategory.assignment:
        return '과제/숙제';
      case NotificationCategory.practice:
        return '연습';
      case NotificationCategory.communication:
        return '소통';
      case NotificationCategory.report:
        return '리포트';
    }
  }

  String get icon {
    switch (this) {
      case NotificationCategory.payment:
        return '💰';
      case NotificationCategory.lesson:
        return '📅';
      case NotificationCategory.assignment:
        return '📝';
      case NotificationCategory.practice:
        return '🔥';
      case NotificationCategory.communication:
        return '💬';
      case NotificationCategory.report:
        return '📊';
    }
  }
}

/// Parent notification settings model
/// Parents can customize which notifications they receive
class ParentNotificationSettings {
  final String id;
  final String parentId;

  // Payment (required, always ON)
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
    // Payment (required)
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
        NotificationItem('결제 요청', paymentRequest, isRequired: true),
        NotificationItem('결제 완료 확인', paymentComplete, isRequired: true),
        NotificationItem('결제 기한 임박', paymentDueSoon),
      ],
      NotificationCategory.lesson: [
        NotificationItem('레슨 일정 변경', lessonChange, isRecommended: true),
        NotificationItem('레슨 취소/노쇼', lessonCancel, isRecommended: true),
        NotificationItem('레슨 시작 알림', lessonStart),
        NotificationItem('레슨 종료 알림', lessonEnd),
      ],
      NotificationCategory.assignment: [
        NotificationItem('새 과제 등록', newAssignment, isRecommended: true),
        NotificationItem('과제 미완료 알림 (D-1)', assignmentIncomplete,
            isRecommended: true),
      ],
      NotificationCategory.practice: [
        NotificationItem('연습 완료 알림', practiceComplete),
        NotificationItem('스트릭 달성 알림', streakAchievement),
      ],
      NotificationCategory.communication: [
        NotificationItem('선생님 메시지', teacherMessage, isRecommended: true),
        NotificationItem('레슨 노트 업데이트', lessonNoteUpdate),
      ],
      NotificationCategory.report: [
        NotificationItem('주간 요약 리포트', weeklyReport, isRecommended: true),
        NotificationItem('월간 상세 리포트', monthlyReport, isRecommended: true),
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
      // Payment required fields cannot be changed
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

/// Helper class for displaying notification items
class NotificationItem {
  final String label;
  final bool isEnabled;
  final bool isRequired;
  final bool isRecommended;

  const NotificationItem(
    this.label,
    this.isEnabled, {
    this.isRequired = false,
    this.isRecommended = false,
  });

  String get suffix {
    if (isRequired) return '(필수)';
    if (isRecommended) return '(권장)';
    return '';
  }
}
