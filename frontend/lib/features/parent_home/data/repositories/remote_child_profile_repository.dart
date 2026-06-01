import '../../../../core/network/api_client.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';

/// Remote implementation of [ChildProfileRepository] using FastAPI backend.
///
/// Maps to /api/v1/parents endpoints for child profile management.
/// Backend responses use camelCase alias (pydantic alias_generator).
class RemoteChildProfileRepository implements ChildProfileRepository {
  final ApiClient _apiClient;

  RemoteChildProfileRepository(this._apiClient);

  @override
  Future<List<ChildProfile>> getChildProfilesByParent(String parentId) async {
    final response = await _apiClient.get('/parents/$parentId/child-profiles');
    final items = response.data as List<dynamic>;
    return items.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ChildProfile?> getChildProfile(String childId) async {
    final response = await _apiClient.get('/parents/child-profiles/$childId');
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChildProfile> addChildProfile(ChildProfile profile) async {
    final response = await _apiClient.post(
      '/parents/child-profiles',
      data: {
        'parentId': profile.parentId,
        'name': profile.name,
        'birthYear': profile.birthYear,
        'instrument': profile.instrument,
        'level': profile.level,
        if (profile.profileColorKey.isNotEmpty)
          'profileColor': profile.profileColorKey,
      },
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChildProfile> updateChildProfile(ChildProfile profile) async {
    final response = await _apiClient.put(
      '/parents/child-profiles/${profile.id}',
      data: {
        'name': profile.name,
        'birthYear': profile.birthYear,
        'instrument': profile.instrument,
        'level': profile.level,
        'profileColor': profile.profileColorKey,
      },
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteChildProfile(String childId) async {
    await _apiClient.delete('/parents/child-profiles/$childId');
  }

  @override
  Future<ChildProfile> connectTeacher(
    String childId,
    String teacherId,
    String teacherName,
  ) async {
    final response = await _apiClient.post(
      '/parents/child-profiles/$childId/teacher',
      data: {'teacherId': teacherId, 'teacherName': teacherName},
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChildProfile> disconnectTeacher(String childId) async {
    final response = await _apiClient.delete(
      '/parents/child-profiles/$childId/teacher',
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  ChildProfile _fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      parentId: (json['parentId'] ?? json['parent_id']) as String,
      name: json['name'] as String,
      birthYear: (json['birthYear'] ?? json['birth_year']) as int,
      instrument: (json['instrument'] ?? '') as String,
      level: (json['level'] ?? 'beginner') as String,
      teacherId: (json['teacherId'] ?? json['teacher_id']) as String?,
      teacherName: (json['teacherName'] ?? json['teacher_name']) as String?,
      linkedStudentId:
          (json['linkedStudentId'] ?? json['linked_student_id']) as String?,
      profileColorKey:
          (json['profileColor'] ?? json['profile_color'] ?? 'blue') as String,
      status: _parseStatus((json['status'] ?? 'active') as String),
      connectionStatus: _parseConnectionStatus(
        (json['connectionStatus'] ?? json['connection_status'] ?? 'unconnected')
            as String,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            json['created_at'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  static ChildProfileStatus _parseStatus(String value) {
    switch (value) {
      case 'inactive':
        return ChildProfileStatus.inactive;
      default:
        return ChildProfileStatus.active;
    }
  }

  static ChildConnectionStatus _parseConnectionStatus(String value) {
    switch (value) {
      case 'connected':
        return ChildConnectionStatus.connected;
      case 'pending':
        return ChildConnectionStatus.pending;
      default:
        return ChildConnectionStatus.unconnected;
    }
  }
}
