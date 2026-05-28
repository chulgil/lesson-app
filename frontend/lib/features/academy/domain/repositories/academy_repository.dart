import '../entities/academy.dart';
import '../entities/academy_member.dart';
import '../entities/academy_student.dart';

/// AcademyRepository — 학원 기본 정보 접근
abstract class AcademyRepository {
  /// Get academy by ID
  Future<Academy?> getById(String id);

  /// List all members of an academy
  Future<List<AcademyMember>> listMembers(String academyId);

  /// List all students of an academy
  Future<List<AcademyStudent>> listStudents(String academyId);
}
