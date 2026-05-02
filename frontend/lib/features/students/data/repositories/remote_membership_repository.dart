import '../../../../core/network/api_client.dart';
import '../../domain/entities/class_membership.dart';
import '../../domain/repositories/membership_repository.dart';

/// Remote implementation of [MembershipRepository] using FastAPI backend.
class RemoteMembershipRepository implements MembershipRepository {
  final ApiClient _apiClient;

  RemoteMembershipRepository(this._apiClient);

  @override
  Future<List<ClassMembership>> getByClassId(String classId) async {
    final response = await _apiClient.get(
      '/lessons-classes/$classId/memberships',
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => ClassMembership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ClassMembership>> getByStudentId(String studentId) async {
    final response = await _apiClient.get(
      '/memberships',
      queryParameters: {'student_id': studentId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => ClassMembership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClassMembership?> getById(String id) async {
    try {
      final response = await _apiClient.get('/memberships/$id');
      return ClassMembership.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClassMembership> create(ClassMembership membership) async {
    final classId = membership.lessonClassId;
    final response = await _apiClient.post(
      '/lessons-classes/$classId/memberships',
      data: membership.toJson(),
    );
    return ClassMembership.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ClassMembership> update(ClassMembership membership) async {
    final classId = membership.lessonClassId;
    final response = await _apiClient.put(
      '/lessons-classes/$classId/memberships/${membership.id}',
      data: membership.toJson(),
    );
    return ClassMembership.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateStatus(String id, MembershipStatus status) async {
    await _apiClient.patch(
      '/memberships/$id/status',
      data: {'status': status.name},
    );
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/memberships/$id');
  }

  @override
  Stream<List<ClassMembership>> watchByClassId(String classId) async* {
    yield await getByClassId(classId);
  }

  @override
  Stream<List<ClassMembership>> watchByStudentId(String studentId) async* {
    yield await getByStudentId(studentId);
  }
}
