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
