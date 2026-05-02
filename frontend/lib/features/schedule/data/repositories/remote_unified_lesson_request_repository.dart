import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';

/// Remote implementation of [UnifiedLessonRequestRepository] using FastAPI.
class RemoteUnifiedLessonRequestRepository
    implements UnifiedLessonRequestRepository {
  final ApiClient _apiClient;

  static const _basePath = '/schedule/lesson-requests';

  RemoteUnifiedLessonRequestRepository(this._apiClient);

  @override
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request) async {
    final response = await _apiClient.post(_basePath, data: request.toJson());
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest?> getById(String id) async {
    final response = await _apiClient.get('$_basePath/$id');
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<UnifiedLessonRequest>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: {'teacher_id': teacherId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UnifiedLessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<UnifiedLessonRequest>> getByStudentId(String studentId) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UnifiedLessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<UnifiedLessonRequest>> getPendingByTeacherId(
    String teacherId,
  ) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: {'teacher_id': teacherId, 'status': 'pending'},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UnifiedLessonRequest.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async {
    final response = await _apiClient.put(
      '$_basePath/${request.id}',
      data: request.toJson(),
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> approve(String id) async {
    final response = await _apiClient.patch(
      '$_basePath/$id/status',
      data: {'status': 'approved'},
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> withdrawApproval(String id) async {
    final response = await _apiClient.patch(
      '$_basePath/$id/status',
      data: {'status': 'pending'},
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> reject(String id, {String? reason}) async {
    final response = await _apiClient.patch(
      '$_basePath/$id/status',
      data: {
        'status': 'rejected',
        if (reason != null) 'decline_reason': reason,
      },
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> proposeAlternatives(
    String id, {
    required List<TimeSlotOption> slots,
    String? message,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/$id/propose-alternatives',
      data: {
        'slots':
            slots
                .map(
                  (s) => {
                    'day_of_week': s.dayOfWeek,
                    'start_time': s.startTime,
                    'end_time': s.endTime,
                  },
                )
                .toList(),
        if (message != null) 'message': message,
      },
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> acceptAlternative(
    String id, {
    required int selectedSlotIndex,
    String? message,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/$id/accept-alternative',
      data: {
        'selected_slot_index': selectedSlotIndex,
        if (message != null) 'message': message,
      },
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UnifiedLessonRequest> counterPropose(
    String id, {
    required TimeSlotOption slot,
    String? message,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/$id/counter-propose',
      data: {
        'slots': [
          {
            'day_of_week': slot.dayOfWeek,
            'start_time': slot.startTime,
            'end_time': slot.endTime,
          },
        ],
        if (message != null) 'message': message,
      },
    );
    return UnifiedLessonRequest.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<RequestEvent>> getEventsByRequestId(String requestId) async {
    final response = await _apiClient.get('$_basePath/$requestId/events');
    final items = response.data as List<dynamic>;
    return items
        .map((json) => RequestEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RequestEvent> addEvent(RequestEvent event) async {
    final response = await _apiClient.post(
      '$_basePath/${event.requestId}/events',
      data: event.toJson(),
    );
    return RequestEvent.fromJson(response.data as Map<String, dynamic>);
  }
}
