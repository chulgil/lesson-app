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

  Future<Lesson> addLesson(Lesson lesson, {String? overflowMode}) async {
    state = const AsyncValue.loading();
    try {
      final newLesson = await _repository.createLesson(
        lesson,
        overflowMode: overflowMode,
      );
      state = await AsyncValue.guard(() => _repository.getLessons());
      // keepAlive lessonsProvider(홈 대시보드)/lessonProvider(id)(상세) stale 방지 —
      // lesson_confirmation_provider 와 동일 패턴. weekLessons 는 notifier watch(#1141).
      ref.invalidate(lessonsProvider);
      _invalidateDerived();
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
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(lesson.id));
      _invalidateDerived();
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// #1237 — status transitions go through the dedicated endpoint so the
  /// server-side deduction and counterparty notifications actually run.
  /// The old `updateLesson(copyWith(status:))` route was silently dropped.
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateLessonStatus(lesson, status);
      state = await AsyncValue.guard(() => _repository.getLessons());
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(lesson.id));
      _invalidateDerived();
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// #1236 — lesson note writes go through the feedback endpoint; the entity
  /// PUT never persisted them.
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateLessonFeedback(
        lesson,
        feedback: feedback,
        keyPoints: keyPoints,
        practiceTips: practiceTips,
      );
      state = await AsyncValue.guard(() => _repository.getLessons());
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(lesson.id));
      _invalidateDerived();
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
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(id));
      _invalidateDerived();
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
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(id));
      _invalidateDerived();
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
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(id));
      _invalidateDerived();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getLessons());
  }

  /// Derived keepAlive read providers that fetch lesson lists straight from
  /// the repository. They have no watch-chain to this notifier, so every
  /// mutation must invalidate them or their consumer screens (student lesson
  /// sections, today/upcoming cards) keep showing pre-mutation data.
  void _invalidateDerived() {
    ref.invalidate(lessonsByStudentProvider);
    ref.invalidate(lessonsByDateProvider);
    ref.invalidate(upcomingLessonsProvider);
    ref.invalidate(recentLessonsProvider);
    ref.invalidate(todayLessonsProvider);
  }
}
