import '../entities/teacher.dart';

/// Repository interface for teacher data
abstract class TeacherRepository {
  /// Get all teachers
  Future<List<Teacher>> getAllTeachers();

  /// Get teacher by ID
  Future<Teacher?> getTeacherById(String id);

  /// Search teachers by filter
  Future<List<Teacher>> searchTeachers(TeacherFilter filter);

  /// Get teachers by instrument
  Future<List<Teacher>> getTeachersByInstrument(String instrument);

  /// Get featured/recommended teachers
  Future<List<Teacher>> getFeaturedTeachers();
}
