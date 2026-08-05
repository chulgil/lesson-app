import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_update_payload.dart';

/// Remote implementation of [LessonRepository] using FastAPI backend.
class RemoteLessonRepository implements LessonRepository {
  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RemoteLessonRepository(this._apiClient);

  @override
  Future<List<Lesson>> getLessons() async {
    final response = await _apiClient.get('/lessons');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) async {
    final response = await _apiClient.get(
      '/lessons',
      queryParameters: {'student_id': studentId},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) async {
    final dateStr = _dateFormat.format(date);
    final response = await _apiClient.get(
      '/lessons',
      queryParameters: {'date_from': dateStr, 'date_to': dateStr},
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Lesson>> getLessonsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _apiClient.get(
      '/lessons',
      queryParameters: {
        'date_from': _dateFormat.format(start),
        'date_to': _dateFormat.format(end),
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) async {
    final response = await _apiClient.get(
      '/lessons',
      queryParameters: {
        'date_from': _dateFormat.format(DateTime.now()),
        'status': 'scheduled',
        'size': limit,
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) async {
    final response = await _apiClient.get(
      '/lessons',
      queryParameters: {
        'date_to': _dateFormat.format(DateTime.now()),
        'status': 'completed',
        'size': limit,
      },
    );
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Lesson.fromJson(json),
    );
    return paginated.items;
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    final response = await _apiClient.get('/lessons/$id');
    return Lesson.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async {
    final response = await _apiClient.post(
      '/lessons',
      data: {
        ...lesson.toJson(),
        if (overflowMode != null) 'overflow_mode': overflowMode,
      },
    );
    return Lesson.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    final response = await _apiClient.put(
      '/lessons/${lesson.id}',
      data: lessonScheduleUpdatePayload(lesson),
    );
    return Lesson.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    final response = await _apiClient.patch(
      '/lessons/${lesson.id}/status',
      data: {'status': status.name},
    );
    return Lesson.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) async {
    final response = await _apiClient.put(
      '/lessons/${lesson.id}/feedback',
      data: {
        if (feedback != null) 'feedback': feedback,
        if (keyPoints != null) 'key_points': keyPoints,
        if (practiceTips != null) 'practice_tips': practiceTips,
      },
    );
    return Lesson.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLesson(String id) async {
    await _apiClient.delete('/lessons/$id');
  }

  @override
  Future<void> cancelLesson(String id) async {
    await _apiClient.patch(
      '/lessons/$id/status',
      data: {'status': 'cancelled'},
    );
  }

  @override
  Future<void> archiveLesson(String id) async {
    await _apiClient.patch('/lessons/$id/archive');
  }

  @override
  Future<void> unarchiveLesson(String id) async {
    await _apiClient.patch('/lessons/$id/unarchive');
  }
}
