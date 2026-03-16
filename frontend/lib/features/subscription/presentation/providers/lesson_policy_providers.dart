import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/mock_lesson_policy_repository.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/repositories/lesson_policy_repository.dart';

part 'lesson_policy_providers.g.dart';

/// Provider for the lesson policy repository.
@Riverpod(keepAlive: true)
LessonPolicyRepository lessonPolicyRepository(Ref ref) {
  if (EnvironmentConfig.useMockData) {
    return MockLessonPolicyRepository();
  }
  // Backend API 미구현 — 레슨 정책 엔드포인트 필요
  return MockLessonPolicyRepository();
}

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
