import '../entities/manual_teacher.dart';

/// Repository interface for manually registered teachers.
abstract class ManualTeacherRepository {
  Future<List<ManualTeacher>> getAll();
  Future<ManualTeacher?> getById(String id);
  Future<void> add(ManualTeacher teacher);
  Future<void> update(ManualTeacher teacher);
  Future<void> delete(String id);
}
