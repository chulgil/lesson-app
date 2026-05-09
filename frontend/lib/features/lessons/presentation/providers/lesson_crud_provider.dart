import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_repository_provider.dart';

part 'lesson_crud_provider.g.dart';

/// All lessons provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> lessons(LessonsRef ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessons();
}

/// Single lesson provider
@Riverpod(keepAlive: true)
Future<Lesson?> lesson(LessonRef ref, String id) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLesson(id);
}

/// Lessons by student provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> lessonsByStudent(
  LessonsByStudentRef ref,
  String studentId,
) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByStudent(studentId);
}

/// Lessons by date provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> lessonsByDate(LessonsByDateRef ref, DateTime date) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(date);
}

/// Upcoming lessons provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> upcomingLessons(UpcomingLessonsRef ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getUpcomingLessons(limit: 10);
}

/// Recent lessons provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> recentLessons(RecentLessonsRef ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getRecentLessons(limit: 10);
}

/// Today's lessons provider
@Riverpod(keepAlive: true)
Future<List<Lesson>> todayLessons(TodayLessonsRef ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessonsByDate(DateTime.now());
}

/// Lesson list notifier for CRUD operations
@Riverpod(keepAlive: true)
class LessonsNotifier extends _$LessonsNotifier {
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

  Future<void> archiveLesson(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.archiveLesson(id);
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
