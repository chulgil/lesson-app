import '../../../../core/network/api_client.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/repositories/lesson_policy_repository.dart';

/// Remote implementation of [LessonPolicyRepository] using FastAPI backend.
class RemoteLessonPolicyRepository implements LessonPolicyRepository {
  final ApiClient _apiClient;

  RemoteLessonPolicyRepository(this._apiClient);

  @override
  Future<LessonPolicy?> getTeacherPolicy(String teacherId) async {
    try {
      final response =
          await _apiClient.get('/lesson-policies/teacher/$teacherId');
      return LessonPolicy.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonPolicy?> getClassPolicy(String lessonClassId) async {
    try {
      final response =
          await _apiClient.get('/lesson-policies/class/$lessonClassId');
      return LessonPolicy.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonPolicy?> getEffectivePolicy({
    required String teacherId,
    String? lessonClassId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/lesson-policies/effective',
        queryParameters: {
          'teacher_id': teacherId,
          if (lessonClassId != null) 'lesson_class_id': lessonClassId,
        },
      );
      return LessonPolicy.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonPolicy> savePolicy(LessonPolicy policy) async {
    if (policy.id.isNotEmpty) {
      final response = await _apiClient.put(
        '/lesson-policies/${policy.id}',
        data: policy.toJson(),
      );
      return LessonPolicy.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    final response = await _apiClient.post(
      '/lesson-policies',
      data: policy.toJson(),
    );
    return LessonPolicy.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deletePolicy(String policyId) async {
    await _apiClient.delete('/lesson-policies/$policyId');
  }
}
