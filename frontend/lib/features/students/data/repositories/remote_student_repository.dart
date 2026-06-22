import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/student_repository.dart';

/// Remote implementation of [StudentRepository] using FastAPI backend.
class RemoteStudentRepository implements StudentRepository {
  final ApiClient _apiClient;

  RemoteStudentRepository(this._apiClient);

  @override
  Future<List<Student>> getStudents() async {
    final response = await _apiClient.get('/students');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Student.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Student?> getStudent(String id) async {
    final response = await _apiClient.get('/students/$id');
    return Student.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Student> getMyProfile() async {
    final response = await _apiClient.get('/students/me/profile');
    return Student.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Student> createStudent(Student student) async {
    final response = await _apiClient.post('/students', data: student.toJson());
    return Student.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Student> updateStudent(Student student) async {
    final response = await _apiClient.put(
      '/students/${student.id}',
      data: student.toJson(),
    );
    return Student.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _apiClient.delete('/students/$id');
  }

  @override
  Future<List<Student>> searchStudents(String query) async {
    final response = await _apiClient.get(
      '/students',
      queryParameters: {'search': query},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Student.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Student> updateStudentStatus(
    String studentId,
    StudentStatus status,
  ) async {
    final response = await _apiClient.patch(
      '/students/$studentId/status',
      data: {'status': status.name},
    );
    return Student.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Student>> getStudentsByStatus(StudentStatus status) async {
    final response = await _apiClient.get(
      '/students',
      queryParameters: {'status': status.name},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Student.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<void> archiveStudent(String id) async {
    await _apiClient.patch('/students/$id/archive');
  }

  @override
  Future<void> unarchiveStudent(String id) async {
    await _apiClient.patch('/students/$id/unarchive');
  }
}
