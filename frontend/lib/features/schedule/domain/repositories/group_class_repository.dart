// Group class definition repository interface
// Teacher-side CRUD for the class itself (bookings live in
// GroupClassBookingRepository).

import '../entities/group_class.dart';
import '../entities/group_class_draft.dart';
import '../entities/group_class_member.dart';
import '../entities/group_class_schedule.dart';

/// Repository for group class definitions (반 / 드롭인).
abstract class GroupClassRepository {
  /// Classes owned by a teacher, newest first.
  ///
  /// Deactivated classes are hidden unless [includeInactive] is set — only the
  /// owning teacher can see those.
  Future<List<GroupClass>> getClassesForTeacher(
    String teacherId, {
    bool includeInactive = false,
  });

  /// Active classes the student is enrolled in (cohort roster).
  ///
  /// Roster membership only — this is not a discovery feed, so a class the
  /// student could join but has not been assigned to never shows up here.
  Future<List<GroupClass>> getClassesForStudent(String studentId);

  /// A single class by ID, or null when it no longer exists.
  Future<GroupClass?> getClassById(String classId);

  /// Sessions opened for a class, earliest first.
  ///
  /// Screens that only hold a class (list rows, agenda rows) resolve a concrete
  /// session through this before pushing the detail/attendance screens.
  Future<List<GroupClassSchedule>> getSchedulesForClass(String classId);

  /// Create a class. For a regular class the backend also lays down the
  /// recurring sessions derived from the repeat settings.
  Future<GroupClass> createClass(GroupClassDraft draft);

  /// Update a class definition. Changing the repeat settings regenerates the
  /// future sessions that have no bookings yet.
  Future<GroupClass> updateClass(String classId, GroupClassDraft draft);

  /// Take a class down. Soft delete — booking and attendance history keeps
  /// pointing at it, so the class comes back with [isActive] false.
  Future<GroupClass> deactivateClass(String classId);

  /// Open one session. Drop-in classes need this because they have no repeat
  /// rule for the backend to expand.
  Future<GroupClassSchedule> createSchedule({
    required String groupClassId,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Cohort roster of a class, oldest assignment first.
  Future<List<GroupClassMember>> listMembers(String classId);

  /// Put one of the teacher's own students on the roster.
  ///
  /// Rejected when the roster already holds [GroupClass.maxCapacity] students,
  /// when the student is already on it, or when they belong to another teacher.
  Future<GroupClassMember> assignMember({
    required String classId,
    required String studentId,
  });

  /// Take a student off the roster. Attendance history keeps pointing at the
  /// class, so past sessions stay intact.
  Future<void> removeMember({
    required String classId,
    required String studentId,
  });
}
