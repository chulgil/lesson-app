import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_lesson_policy_repository.dart';
import '../../data/repositories/remote_lesson_policy_repository.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/repositories/lesson_policy_repository.dart';

part 'lesson_policy_providers.g.dart';

/// Provider for the lesson policy repository — switches between Mock and Remote.
@Riverpod(keepAlive: true)
LessonPolicyRepository lessonPolicyRepository(Ref ref) =>
    createRepository<LessonPolicyRepository>(
      ref: ref,
      mock: () => MockLessonPolicyRepository(),
      remote: (api) => RemoteLessonPolicyRepository(api),
    );

/// Provider for teacher's default policy.
@riverpod
Future<LessonPolicy?> teacherPolicy(Ref ref, String teacherId) async {
  final repository = ref.watch(lessonPolicyRepositoryProvider);
  return repository.getTeacherPolicy(teacherId);
}

/// Provider for class-specific policy.
@riverpod
Future<LessonPolicy?> classPolicy(Ref ref, String lessonClassId) async {
  final repository = ref.watch(lessonPolicyRepositoryProvider);
  return repository.getClassPolicy(lessonClassId);
}

/// Provider for effective policy (class or teacher default).
@riverpod
Future<LessonPolicy?> effectivePolicy(
  Ref ref, {
  required String teacherId,
  String? lessonClassId,
}) async {
  final repository = ref.watch(lessonPolicyRepositoryProvider);
  return repository.getEffectivePolicy(
    teacherId: teacherId,
    lessonClassId: lessonClassId,
  );
}

/// Provider for academy subscription policy prefill.
/// Returns 5 policy variables for read-only display when ownership=academy.
@riverpod
Future<Map<String, dynamic>> academySubscriptionPolicyPrefill(
  Ref ref, {
  required String teacherId,
  String? academyId,
}) async {
  final repository = ref.watch(lessonPolicyRepositoryProvider);
  final policy = await repository.getTeacherPolicy(teacherId);

  if (policy == null) {
    return {
      'cancellation_deadline_hours': 12,
      'student_compensation_extra_minutes_enabled': true,
      'include_extra_minutes_text_on_late_cancel': true,
      'student_compensation_extra_minutes_message': null,
      'notify_owner_on_late_cancel': true,
    };
  }

  return {
    'cancellation_deadline_hours': policy.minCancelHours,
    'student_compensation_extra_minutes_enabled': true,
    'include_extra_minutes_text_on_late_cancel': true,
    'student_compensation_extra_minutes_message': null,
    'notify_owner_on_late_cancel': true,
  };
}
