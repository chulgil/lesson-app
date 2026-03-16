import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/mock_lesson_class_repository.dart';
import '../../domain/entities/lesson_class.dart';
import '../../domain/repositories/lesson_class_repository.dart';

part 'lesson_class_providers.g.dart';

/// Repository provider for LessonClass.
@riverpod
LessonClassRepository lessonClassRepository(LessonClassRepositoryRef ref) {
  if (EnvironmentConfig.useMockData) {
    return MockLessonClassRepository();
  }
  // Backend API 미구현 — 레슨 클래스 엔드포인트 필요
  return MockLessonClassRepository();
}

/// Get all classes for the current teacher.
@riverpod
Future<List<LessonClass>> teacherLessonClasses(
  TeacherLessonClassesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(lessonClassRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Get a single class by ID.
@riverpod
Future<LessonClass?> lessonClass(LessonClassRef ref, String classId) async {
  final repository = ref.watch(lessonClassRepositoryProvider);
  return repository.getById(classId);
}

/// Notifier for managing LessonClass CRUD operations.
@riverpod
class LessonClassNotifier extends _$LessonClassNotifier {
  @override
  Future<List<LessonClass>> build(String teacherId) async {
    final repository = ref.watch(lessonClassRepositoryProvider);
    return repository.getByTeacherId(teacherId);
  }

  Future<LessonClass> create(LessonClass lessonClass) async {
    final repository = ref.read(lessonClassRepositoryProvider);
    final created = await repository.create(lessonClass);
    ref.invalidateSelf();
    return created;
  }

  Future<LessonClass> updateClass(LessonClass lessonClass) async {
    final repository = ref.read(lessonClassRepositoryProvider);
    final updated = await repository.update(lessonClass);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> archive(String id) async {
    final repository = ref.read(lessonClassRepositoryProvider);
    await repository.archive(id);
    ref.invalidateSelf();
  }

  Future<void> restore(String id) async {
    final repository = ref.read(lessonClassRepositoryProvider);
    await repository.restore(id);
    ref.invalidateSelf();
  }

  Future<void> reorder(List<String> orderedIds) async {
    final repository = ref.read(lessonClassRepositoryProvider);
    await repository.reorder(orderedIds);
    ref.invalidateSelf();
  }
}
