// Parent visibility settings domain entity
// Moved from lib/models/parent_visibility_settings.dart for Clean Architecture

/// Visibility settings for parent access to student information
/// Teacher sets these per student
class ParentVisibilitySettings {
  final String id;
  final String teacherId;
  final String studentId;

  // Core visibility (default ON)
  final bool canViewSchedule; // Lesson schedule
  final bool canViewAssignments; // Homework/assignments
  final bool canViewPractice; // Practice records
  final bool canViewLessonNotes; // Teacher's lesson notes

  // Extended visibility (default OFF)
  final bool canViewRecordings; // Student practice recordings
  final bool canViewDetailedFeedback; // Detailed teacher feedback
  final bool canViewChat; // Student-teacher chat history

  final DateTime createdAt;
  final DateTime? updatedAt;

  const ParentVisibilitySettings({
    required this.id,
    required this.teacherId,
    required this.studentId,
    // Default ON
    this.canViewSchedule = true,
    this.canViewAssignments = true,
    this.canViewPractice = true,
    this.canViewLessonNotes = true,
    // Default OFF
    this.canViewRecordings = false,
    this.canViewDetailedFeedback = false,
    this.canViewChat = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create default settings for a new student
  factory ParentVisibilitySettings.defaultSettings({
    required String id,
    required String teacherId,
    required String studentId,
  }) {
    return ParentVisibilitySettings(
      id: id,
      teacherId: teacherId,
      studentId: studentId,
      createdAt: DateTime.now(),
    );
  }

  /// Get list of enabled visibility items for display
  List<String> get enabledItems {
    final items = <String>[];
    if (canViewSchedule) items.add('레슨 일정');
    if (canViewAssignments) items.add('과제 현황');
    if (canViewPractice) items.add('연습 기록');
    if (canViewLessonNotes) items.add('레슨 노트');
    if (canViewRecordings) items.add('연습 녹음');
    if (canViewDetailedFeedback) items.add('상세 피드백');
    if (canViewChat) items.add('채팅 내역');
    return items;
  }

  /// Get count of enabled items
  int get enabledCount {
    int count = 0;
    if (canViewSchedule) count++;
    if (canViewAssignments) count++;
    if (canViewPractice) count++;
    if (canViewLessonNotes) count++;
    if (canViewRecordings) count++;
    if (canViewDetailedFeedback) count++;
    if (canViewChat) count++;
    return count;
  }

  /// Total available items
  static const int totalItems = 7;

  /// Get visibility summary (e.g., "5/7 항목 공개")
  String get summary => '$enabledCount/$totalItems 항목 공개';

  /// Copy with new values
  ParentVisibilitySettings copyWith({
    String? id,
    String? teacherId,
    String? studentId,
    bool? canViewSchedule,
    bool? canViewAssignments,
    bool? canViewPractice,
    bool? canViewLessonNotes,
    bool? canViewRecordings,
    bool? canViewDetailedFeedback,
    bool? canViewChat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentVisibilitySettings(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      canViewSchedule: canViewSchedule ?? this.canViewSchedule,
      canViewAssignments: canViewAssignments ?? this.canViewAssignments,
      canViewPractice: canViewPractice ?? this.canViewPractice,
      canViewLessonNotes: canViewLessonNotes ?? this.canViewLessonNotes,
      canViewRecordings: canViewRecordings ?? this.canViewRecordings,
      canViewDetailedFeedback:
          canViewDetailedFeedback ?? this.canViewDetailedFeedback,
      canViewChat: canViewChat ?? this.canViewChat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentVisibilitySettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
