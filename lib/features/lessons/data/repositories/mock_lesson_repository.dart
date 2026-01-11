import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Mock implementation for development
class MockLessonRepository implements LessonRepository {
  final _uuid = const Uuid();
  final List<Lesson> _lessons = [];

  MockLessonRepository() {
    _initMockData();
  }

  void _initMockData() {
    // No dummy data - users create their own lessons
  }

  @override
  Future<List<Lesson>> getLessons() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_lessons);
  }

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) => l.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) {
      return l.date.year == date.year &&
          l.date.month == date.month &&
          l.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Lesson>> getLessonsByDateRange(
      DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) {
      return l.date.isAfter(start.subtract(const Duration(days: 1))) &&
          l.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _lessons
        .where((l) =>
            l.status == LessonStatus.scheduled &&
            l.date.isAfter(now.subtract(const Duration(hours: 2))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date))
      ..take(limit);
  }

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _lessons
        .where((l) =>
            l.status == LessonStatus.completed &&
            l.date.isBefore(now))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(limit);
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newLesson = lesson.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _lessons.add(newLesson);
    return newLesson;
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _lessons.indexWhere((l) => l.id == lesson.id);
    if (index == -1) {
      throw Exception('Lesson not found');
    }
    final updated = lesson.copyWith(updatedAt: DateTime.now());
    _lessons[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _lessons.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> cancelLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _lessons.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw Exception('Lesson not found');
    }
    _lessons[index] = _lessons[index].copyWith(
      status: LessonStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }
}
