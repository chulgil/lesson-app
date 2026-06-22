import '../entities/entities.dart';

/// Repository interface for managing student data
abstract class StudentRepository {
  Future<List<Student>> getStudents();
  Future<Student?> getStudent(String id);

  /// Get the authenticated student's own profile (GET /students/me/profile).
  ///
  /// Resolves the real [Student] record (incl. its `id`) for the logged-in
  /// user. Distinct from [getStudent], which looks up by `Student.id` — the
  /// auth `userId` is NOT a `Student.id` and must not be used as one.
  Future<Student> getMyProfile();
  Future<Student> createStudent(Student student);
  Future<Student> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<List<Student>> searchStudents(String query);

  /// Update student status (trial → active, active → paused, etc.)
  Future<Student> updateStudentStatus(String studentId, StudentStatus status);

  /// Get students by status
  Future<List<Student>> getStudentsByStatus(StudentStatus status);

  /// Archive a student (soft-delete)
  Future<void> archiveStudent(String id);

  /// Unarchive a previously archived student
  Future<void> unarchiveStudent(String id);
}
