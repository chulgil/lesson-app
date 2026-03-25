import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_repository_provider.dart';

/// All lessons provider
final lessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessons();
});

/// Single lesson provider
final lessonProvider =
    FutureProvider.family<Lesson?, String>((ref, id) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLesson(id);
});

/// Lessons by student provider
final lessonsByStudentProvider =
    FutureProvider.family<List<Lesson>, String>((ref, studentId) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByStudent(studentId);
});

/// Lessons by date provider
final lessonsByDateProvider =
    FutureProvider.family<List<Lesson>, DateTime>((ref, date) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(date);
});

/// Upcoming lessons provider
final upcomingLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getUpcomingLessons(limit: 10);
});

/// Recent lessons provider
final recentLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getRecentLessons(limit: 10);
});

/// Today's lessons provider
final todayLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(DateTime.now());
});

/// Lesson list notifier for CRUD operations
class LessonsNotifier extends AsyncNotifier<List<Lesson>> {
  LessonRepository get _repository => ref.read(lessonRepositoryProvider);

  @override
  Future<List<Lesson>> build() async {
    return _repository.getLessons();
  }

  Future<Lesson> addLesson(Lesson lesson) async {
    state = const AsyncValue.loading();
    try {
      final newLesson = await _repository.createLesson(lesson);
      state = await AsyncValue.guard(() => _repository.getLessons());
      return newLesson;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Lesson> updateLesson(Lesson lesson) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateLesson(lesson);
      state = await AsyncValue.guard(() => _repository.getLessons());
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteLesson(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteLesson(id);
      state = await AsyncValue.guard(() => _repository.getLessons());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelLesson(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelLesson(id);
      state = await AsyncValue.guard(() => _repository.getLessons());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getLessons());
  }
}

final lessonsNotifierProvider =
    AsyncNotifierProvider<LessonsNotifier, List<Lesson>>(
  LessonsNotifier.new,
);
