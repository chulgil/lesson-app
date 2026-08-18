import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_draft.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../../domain/repositories/group_class_repository.dart';

/// Remote implementation of [GroupClassRepository] using the FastAPI backend.
///
/// Wire keys follow the `group_class.dart` entity contract:
/// `repeat_days_of_week` is 1=Mon…7=Sun and `repeat_time_of_day` is a KST wall
/// clock — the backend maps those onto its own column names.
class RemoteGroupClassRepository implements GroupClassRepository {
  final ApiClient _apiClient;

  RemoteGroupClassRepository(this._apiClient);

  @override
  Future<List<GroupClass>> getClassesForTeacher(
    String teacherId, {
    bool includeInactive = false,
  }) async {
    final response = await _apiClient.get(
      '/groups/classes',
      queryParameters: {
        'teacher_id': teacherId,
        if (includeInactive) 'include_inactive': 'true',
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClass.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<GroupClass>> getClassesForStudent(String studentId) async {
    final response = await _apiClient.get(
      '/groups/classes',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClass.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<GroupClass?> getClassById(String classId) async {
    final response = await _apiClient.get('/groups/classes/$classId');
    if (response.data == null) return null;
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<GroupClassSchedule>> getSchedulesForClass(String classId) async {
    final response = await _apiClient.get('/groups/$classId/schedules');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GroupClassSchedule.fromJson(json),
    );
    return paginated.items.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<GroupClass> createClass(GroupClassDraft draft) async {
    final response = await _apiClient.post(
      '/groups/classes',
      data: _draftToWire(draft),
    );
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GroupClass> updateClass(String classId, GroupClassDraft draft) async {
    final response = await _apiClient.patch(
      '/groups/classes/$classId',
      data: _draftToWire(draft),
    );
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GroupClass> deactivateClass(String classId) async {
    final response = await _apiClient.delete('/groups/classes/$classId');
    return GroupClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GroupClassSchedule> createSchedule({
    required String groupClassId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _apiClient.post(
      '/groups/schedules',
      data: {
        'group_class_id': groupClassId,
        // Naive local ISO — the backend reads bare datetimes as KST wall clock,
        // matching how repeat_time_of_day is interpreted.
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      },
    );
    return GroupClassSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  /// Capacity is not sent per session — the class owns it (P1-0 SSOT).
  Map<String, dynamic> _draftToWire(GroupClassDraft draft) {
    return {
      'name': draft.name,
      'type': draft.type.name,
      'description': draft.description,
      'max_capacity': draft.maxCapacity,
      'waitlist_capacity': draft.waitlistCapacity,
      'duration_minutes': draft.durationMinutes,
      'booking_deadline_minutes': draft.bookingDeadlineMinutes,
      'cancel_deadline_minutes': draft.cancelDeadlineMinutes,
      'no_show_policy': draft.noShowPolicy.name,
      'repeat_days_of_week': draft.isDropIn ? null : draft.repeatDaysOfWeek,
      'repeat_time_of_day': draft.isDropIn ? null : draft.repeatTimeOfDay,
      'instrument': draft.instrument,
      'price_per_session': draft.pricePerSession,
    };
  }
}
