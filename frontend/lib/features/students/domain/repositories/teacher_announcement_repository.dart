import '../entities/teacher_announcement.dart';

/// Repository interface for teacher announcements (v3 공지 시스템).
abstract class TeacherAnnouncementRepository {
  /// Create a new announcement and notify students.
  /// Returns the announcement with affected lessons populated.
  Future<TeacherAnnouncement> create(TeacherAnnouncement announcement);

  /// Get all announcements for a teacher, newest first.
  Future<List<TeacherAnnouncement>> getByTeacherId(String teacherId);

  /// Update an existing announcement (message, dates).
  Future<TeacherAnnouncement> update(TeacherAnnouncement announcement);

  /// Delete an announcement by ID.
  Future<void> delete(String id);

  /// Get day-off dates for a teacher within a date range.
  /// Used by schedule tab and time slot selection to mark/disable days.
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  });
}
