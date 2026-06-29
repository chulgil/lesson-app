// Parent visibility settings domain entity
// Moved from lib/features/parent_home/domain/entities/parent_visibility_settings.dart for Clean Architecture

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
