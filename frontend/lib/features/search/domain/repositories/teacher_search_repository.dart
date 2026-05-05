import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/domain/entities/teacher_search.dart';

/// Academy info for student app display
class AcademyInfo {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final List<String> instruments;
  final int teacherCount;

  const AcademyInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.instruments = const [],
    this.teacherCount = 0,
  });
}

/// Repository for searching teachers
abstract class TeacherSearchRepository {
  /// Search teachers with filter
  Future<TeacherSearchResult> searchTeachers({
    TeacherSearchFilter filter = TeacherSearchFilter.empty,
    TeacherSortOption sort = TeacherSortOption.relevance,
    int page = 0,
    int pageSize = 20,
  });

  /// Get teacher public profile by id
  Future<TeacherPublicProfile?> getTeacherPublicProfile(String teacherId);

  /// Get full teacher profile by id (for connected students - includes bank account)
  Future<TeacherProfile?> getTeacherFullProfile(String teacherId);

  /// Get popular/featured teachers
  Future<List<TeacherPublicProfile>> getFeaturedTeachers({int limit = 10});

  /// Get available instruments for filtering
  Future<List<String>> getAvailableInstruments();

  /// Get available areas for filtering
  Future<List<String>> getAvailableAreas();

  /// Get academy info by organization ID
  Future<AcademyInfo?> getAcademyInfo(String organizationId);

  /// Get all teachers belonging to an organization/academy
  Future<List<TeacherPublicProfile>> getTeachersByOrganization(
    String organizationId,
  );

  /// Get all academies (unique organizations)
  Future<List<AcademyInfo>> getAllAcademies();
}
