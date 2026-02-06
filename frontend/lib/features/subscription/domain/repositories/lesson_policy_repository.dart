import '../entities/lesson_policy.dart';

/// Repository interface for lesson policies.
abstract class LessonPolicyRepository {
  /// Get teacher's default policy
  Future<LessonPolicy?> getTeacherPolicy(String teacherId);

  /// Get policy for specific lesson class
  Future<LessonPolicy?> getClassPolicy(String lessonClassId);

  /// Get effective policy (class policy if exists, otherwise teacher default)
  Future<LessonPolicy?> getEffectivePolicy({
    required String teacherId,
    String? lessonClassId,
  });

  /// Create or update policy
  Future<LessonPolicy> savePolicy(LessonPolicy policy);

  /// Delete policy
  Future<void> deletePolicy(String policyId);
}
