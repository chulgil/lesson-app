import '../../../../core/network/api_client.dart';
import '../../domain/entities/academy_activity_log.dart';
import '../../domain/repositories/academy_activity_repository.dart';

/// REST client for academy activity timeline (teacher own-only) — issue #554 영역 5.
///
/// 백엔드 엔드포인트 (baseUrl 에 `/api/v1` 포함):
/// - `GET /academies/{academyId}/activities?actor_member_id={memberId}`
///   → AcademyActivityLogListResponse (강사는 본인 활동만, NFR-A-5)
///
/// 백엔드가 created_at desc 로 정렬하지만, 계약(최신순) 보장을 위해 방어적 재정렬.
class RemoteAcademyActivityRepository implements AcademyActivityRepository {
  final ApiClient _apiClient;

  RemoteAcademyActivityRepository(this._apiClient);

  @override
  Future<List<AcademyActivityLog>> listByAcademyAndActor(
    String academyId,
    String actorMemberId,
  ) async {
    final response = await _apiClient.get(
      '/academies/$academyId/activities',
      queryParameters: {'actor_member_id': actorMemberId},
    );
    final map = response.data as Map<String, dynamic>;
    final items =
        (map['activities'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final logs = items.map(_fromJson).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  static AcademyActivityLog _fromJson(Map<String, dynamic> json) {
    return AcademyActivityLog(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      actorMemberId: json['actor_member_id'] as String,
      actorName: json['actor_name'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      targetResourceType: json['target_resource_type'] as String?,
      targetResourceId: json['target_resource_id'] as String?,
      // BE 의 metadata_json → FE 의 metadata (academy_activity_log.dart 주석 참조).
      metadata: (json['metadata_json'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
