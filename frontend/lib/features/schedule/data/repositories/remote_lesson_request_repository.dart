import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/lesson_request.dart';
import '../../domain/repositories/lesson_request_repository.dart';

/// Remote implementation of [LessonRequestRepository] using FastAPI backend.
class RemoteLessonRequestRepository implements LessonRequestRepository {
  final ApiClient _apiClient;

  RemoteLessonRequestRepository(this._apiClient);

  @override
  Future<LessonRequest> create(LessonRequest request) async {
    final response = await _apiClient.post(
      '/schedule/lesson-requests',
      data: request.toJson(),
    );
    return LessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonRequest?> getById(String id) async {
    final response = await _apiClient.get('/schedule/lesson-requests/$id');
    return LessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<LessonRequest>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get(
      '/schedule/lesson-requests',
      queryParameters: {'teacher_id': teacherId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonRequest>> getByStudentId(String studentId) async {
    final response = await _apiClient.get(
      '/schedule/lesson-requests',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<LessonRequest>> getPendingByTeacherId(String teacherId) async {
    final response = await _apiClient.get(
      '/schedule/lesson-requests',
      queryParameters: {'teacher_id': teacherId, 'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<LessonRequest?> getActiveRequest({
    required String studentId,
    required String teacherId,
  }) async {
    final response = await _apiClient.get(
      '/schedule/lesson-requests',
      queryParameters: {
        'student_id': studentId,
        'teacher_id': teacherId,
        'active': 'true',
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonRequest.fromJson(json),
    );
    return paginated.items.isEmpty ? null : paginated.items.first;
  }

  @override
  Future<LessonRequest> update(LessonRequest request) async {
    final response = await _apiClient.put(
      '/schedule/lesson-requests/${request.id}',
      data: request.toJson(),
    );
    return LessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonRequest> updateStatus({
    required String id,
    required LessonRequestStatus status,
    String? proposalId,
    String? declineReason,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (proposalId != null) data['proposal_id'] = proposalId;
    if (declineReason != null) data['decline_reason'] = declineReason;

    final response = await _apiClient.patch(
      '/schedule/lesson-requests/$id/status',
      data: data,
    );
    return LessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/schedule/lesson-requests/$id');
  }

  @override
  Future<int> processExpiredRequests() async {
    final response = await _apiClient.post(
      '/schedule/lesson-requests/process-expired',
    );
    return response.data['count'] as int? ?? 0;
  }
}
