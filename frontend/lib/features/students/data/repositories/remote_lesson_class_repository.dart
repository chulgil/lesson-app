import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_class.dart';
import '../../domain/repositories/lesson_class_repository.dart';

/// Remote implementation of [LessonClassRepository] using FastAPI backend.
class RemoteLessonClassRepository implements LessonClassRepository {
  final ApiClient _apiClient;

  RemoteLessonClassRepository(this._apiClient);

  @override
  Future<List<LessonClass>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get('/lessons-classes');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => LessonClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LessonClass?> getById(String id) async {
    final response = await _apiClient.get('/lessons-classes/$id');
    return LessonClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonClass> create(LessonClass lessonClass) async {
    final response = await _apiClient.post(
      '/lessons-classes',
      data: lessonClass.toJson(),
    );
    return LessonClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LessonClass> update(LessonClass lessonClass) async {
    final response = await _apiClient.put(
      '/lessons-classes/${lessonClass.id}',
      data: lessonClass.toJson(),
    );
    return LessonClass.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> archive(String id) async {
    await _apiClient.delete('/lessons-classes/$id');
  }

  @override
  Future<void> restore(String id) async {
    await _apiClient.patch('/lessons-classes/$id/restore');
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await _apiClient.put(
      '/lessons-classes/reorder',
      data: {'ordered_ids': orderedIds},
    );
  }

  @override
  Stream<List<LessonClass>> watchByTeacherId(String teacherId) async* {
    // REST polling fallback — emit once on subscribe
    yield await getByTeacherId(teacherId);
  }
}
