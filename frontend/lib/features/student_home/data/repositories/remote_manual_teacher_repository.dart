import '../../../../core/network/api_client.dart';
import '../../domain/entities/manual_teacher.dart';
import '../../domain/repositories/manual_teacher_repository.dart';

/// Remote implementation of [ManualTeacherRepository] using FastAPI backend.
class RemoteManualTeacherRepository implements ManualTeacherRepository {
  final ApiClient _apiClient;

  RemoteManualTeacherRepository(this._apiClient);

  @override
  Future<List<ManualTeacher>> getAll() async {
    final response = await _apiClient.get('/manual-teachers');
    return _parseList(response.data);
  }

  @override
  Future<ManualTeacher?> getById(String id) async {
    try {
      final response = await _apiClient.get('/manual-teachers/$id');
      return ManualTeacher.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(ManualTeacher teacher) async {
    await _apiClient.post(
      '/manual-teachers',
      data: teacher.toJson(),
    );
  }

  @override
  Future<void> update(ManualTeacher teacher) async {
    await _apiClient.put(
      '/manual-teachers/${teacher.id}',
      data: teacher.toJson(),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/manual-teachers/$id');
  }

  List<ManualTeacher> _parseList(dynamic data) {
    List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      items = data['items'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((e) => ManualTeacher.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
