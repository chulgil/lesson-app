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
    // Backend doesn't have direct student-based membership query
    // TODO: Add GET /memberships?student_id= endpoint
    return [];
  }

  @override
  Future<ClassMembership?> getById(String id) async {
    // Use class memberships list — need class_id context
    // TODO: Add GET /memberships/{id} flat endpoint
    return null;
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
    // Backend doesn't have dedicated status endpoint — use full update
    // TODO: Add PATCH /memberships/{id}/status endpoint
  }

  @override
  Future<void> delete(String id) async {
    // Need class_id for nested URL — delete by iterating
    // TODO: Add flat DELETE /memberships/{id} endpoint
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
