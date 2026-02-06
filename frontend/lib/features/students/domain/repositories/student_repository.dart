import '../entities/entities.dart';

/// Repository interface for managing student data
abstract class StudentRepository {
  Future<List<Student>> getStudents();
  Future<Student?> getStudent(String id);
  Future<Student> createStudent(Student student);
  Future<Student> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<List<Student>> searchStudents(String query);

  /// Update student status (trial → active, active → paused, etc.)
  Future<Student> updateStudentStatus(String studentId, StudentStatus status);

  /// Get students by status
  Future<List<Student>> getStudentsByStatus(StudentStatus status);
}
