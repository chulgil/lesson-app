import 'package:uuid/uuid.dart';

import '../../domain/entities/lesson_policy.dart';
import '../../domain/repositories/lesson_policy_repository.dart';

/// Mock implementation of LessonPolicyRepository for development.
class MockLessonPolicyRepository implements LessonPolicyRepository {
  final _uuid = const Uuid();
  final Map<String, LessonPolicy> _policies = {};

  MockLessonPolicyRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Default policy for teacher_1
    final defaultPolicy = LessonPolicy(
      id: 'policy_1',
      teacherId: 'teacher_1',
      lessonClassId: null,
      minCancelHours: 4,
      maxChangesPerMonth: 2,
      allowSameDayCancel: false,
      lateCancelDeadline: '20:00',
      deductLessonOnNoShow: true,
      gracePeriodMinutes: 15,
      allowCarryover: true,
      maxCarryoverLessons: 1,
      carryoverPeriodMonths: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _policies[defaultPolicy.id] = defaultPolicy;

    // Custom policy for a specific class (more strict)
    final classPolicy = LessonPolicy(
      id: 'policy_2',
      teacherId: 'teacher_1',
      lessonClassId: 'class_academy_1',
      minCancelHours: 24,
      maxChangesPerMonth: 1,
      allowSameDayCancel: false,
      lateCancelDeadline: '18:00',
      deductLessonOnNoShow: true,
      gracePeriodMinutes: 10,
      allowCarryover: false,
      maxCarryoverLessons: 0,
      carryoverPeriodMonths: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );
    _policies[classPolicy.id] = classPolicy;
  }

  @override
  Future<LessonPolicy?> getTeacherPolicy(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _policies.values
        .where((p) => p.teacherId == teacherId && p.lessonClassId == null)
        .firstOrNull;
  }

  @override
  Future<LessonPolicy?> getClassPolicy(String lessonClassId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _policies.values
        .where((p) => p.lessonClassId == lessonClassId)
        .firstOrNull;
  }

  @override
  Future<LessonPolicy?> getEffectivePolicy({
    required String teacherId,
    String? lessonClassId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // First try class-specific policy
    if (lessonClassId != null) {
      final classPolicy = await getClassPolicy(lessonClassId);
      if (classPolicy != null) return classPolicy;
    }

    // Fall back to teacher's default policy
    final teacherPolicy = await getTeacherPolicy(teacherId);
    if (teacherPolicy != null) return teacherPolicy;

    // Return system default if no policy exists
    return LessonPolicy.defaultPolicy(
      id: _uuid.v4(),
      teacherId: teacherId,
      lessonClassId: lessonClassId,
    );
  }

  @override
  Future<LessonPolicy> savePolicy(LessonPolicy policy) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();
    LessonPolicy savedPolicy;

    if (_policies.containsKey(policy.id)) {
      // Update existing
      savedPolicy = policy.copyWith(updatedAt: now);
    } else {
      // Create new
      savedPolicy = policy.copyWith(
        id: policy.id.isEmpty ? _uuid.v4() : policy.id,
        createdAt: now,
      );
    }

    _policies[savedPolicy.id] = savedPolicy;
    return savedPolicy;
  }

  @override
  Future<void> deletePolicy(String policyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _policies.remove(policyId);
  }
}
