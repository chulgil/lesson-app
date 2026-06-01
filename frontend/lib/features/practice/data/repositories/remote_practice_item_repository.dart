import '../../../../core/network/api_client.dart';
import '../../domain/entities/practice_item.dart';
import '../../domain/repositories/practice_item_repository.dart';

class RemotePracticeItemRepository implements PracticeItemRepository {
  RemotePracticeItemRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<PracticeItem>> getByLessonId(String lessonId) =>
      _list({'lesson_id': lessonId});

  @override
  Future<List<PracticeItem>> getByStudentId(String studentId) =>
      _list({'student_id': studentId});

  @override
  Future<List<PracticeItem>> getByStudentIdAndDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _list({
      'student_id': studentId,
      'date_from': _dateOnly(startDate),
      'date_to': _dateOnly(endDate),
    });
  }

  @override
  Future<PracticeItem?> getById(String id) async {
    try {
      final response = await _apiClient.get('/practice/items/$id');
      return PracticeItem.fromJson(_normalizeItemJson(response.data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PracticeItem> create(PracticeItem item) async {
    final data =
        item.toJson()
          ..remove('id')
          ..remove('teacher_id')
          ..remove('is_completed')
          ..remove('practice_count')
          ..remove('completed_at')
          ..remove('has_like')
          ..remove('liked_at')
          ..remove('teacher_reaction')
          ..remove('teacher_reaction_at')
          ..remove('student_response')
          ..remove('student_response_at')
          ..remove('created_at')
          ..remove('updated_at');
    final response = await _apiClient.post('/practice/items', data: data);
    return PracticeItem.fromJson(_normalizeItemJson(response.data));
  }

  @override
  Future<PracticeItem> update(PracticeItem item) async {
    final data =
        item.toJson()
          ..remove('id')
          ..remove('lesson_id')
          ..remove('student_id')
          ..remove('teacher_id')
          ..remove('practice_count')
          ..remove('completed_at')
          ..remove('has_like')
          ..remove('liked_at')
          ..remove('teacher_reaction')
          ..remove('teacher_reaction_at')
          ..remove('student_response')
          ..remove('student_response_at')
          ..remove('created_at')
          ..remove('updated_at');
    final response = await _apiClient.put(
      '/practice/items/${item.id}',
      data: data,
    );
    return PracticeItem.fromJson(_normalizeItemJson(response.data));
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/practice/items/$id');
  }

  @override
  Future<PracticeItem> toggleComplete(String id) =>
      _patchItem('/practice/items/$id/complete');

  @override
  Future<PracticeItem> toggleLike(String id) =>
      _patchItem('/practice/items/$id/like');

  @override
  Future<PracticeItem> incrementCount(String id) =>
      _patchItem('/practice/items/$id/practice-count/increment');

  @override
  Future<PracticeItem> decrementCount(String id) =>
      _patchItem('/practice/items/$id/practice-count/decrement');

  @override
  Future<List<PracticeItem>> getIncompleteByStudentId(String studentId) async {
    final response = await _apiClient.get(
      '/practice/items/incomplete',
      queryParameters: {'student_id': studentId},
    );
    return _itemsFromResponse(response.data);
  }

  @override
  Future<List<PracticeItem>> getAwaitingFeedback(String teacherId) async {
    final response = await _apiClient.get('/practice/items/awaiting-feedback');
    return _itemsFromResponse(response.data);
  }

  Future<List<PracticeItem>> _list(Map<String, dynamic> query) async {
    final response = await _apiClient.get(
      '/practice/items',
      queryParameters: query,
    );
    return _itemsFromResponse(response.data);
  }

  Future<PracticeItem> _patchItem(String path) async {
    final response = await _apiClient.patch(path);
    return PracticeItem.fromJson(_normalizeItemJson(response.data));
  }

  List<PracticeItem> _itemsFromResponse(Object? data) {
    final items = data as List<dynamic>;
    return items
        .map((item) => PracticeItem.fromJson(_normalizeItemJson(item)))
        .toList();
  }

  Map<String, dynamic> _normalizeItemJson(Object? raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    const aliases = {
      'lessonId': 'lesson_id',
      'studentId': 'student_id',
      'teacherId': 'teacher_id',
      'repertoireId': 'repertoire_id',
      'sectionId': 'section_id',
      'resourceIds': 'resource_ids',
      'isCompleted': 'is_completed',
      'practiceCount': 'practice_count',
      'completedAt': 'completed_at',
      'hasLike': 'has_like',
      'likedAt': 'liked_at',
      'teacherReaction': 'teacher_reaction',
      'teacherReactionAt': 'teacher_reaction_at',
      'studentResponse': 'student_response',
      'studentResponseAt': 'student_response_at',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    aliases.forEach((camel, snake) {
      if (!json.containsKey(snake) && json.containsKey(camel)) {
        json[snake] = json[camel];
      }
    });
    return json;
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
