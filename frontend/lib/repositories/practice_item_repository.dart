import 'package:uuid/uuid.dart';

import '../models/practice_item.dart';

/// Repository interface for practice items (이번 주 연습)
abstract class PracticeItemRepository {
  /// Get all practice items for a lesson
  Future<List<PracticeItem>> getByLessonId(String lessonId);

  /// Get all practice items for a student
  Future<List<PracticeItem>> getByStudentId(String studentId);

  /// Get practice items for a student within a date range (for weekly view)
  Future<List<PracticeItem>> getByStudentIdAndDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a single practice item by ID
  Future<PracticeItem?> getById(String id);

  /// Create a new practice item
  Future<PracticeItem> create(PracticeItem item);

  /// Update a practice item
  Future<PracticeItem> update(PracticeItem item);

  /// Delete a practice item
  Future<void> delete(String id);

  /// Toggle completion status
  Future<PracticeItem> toggleComplete(String id);

  /// Toggle like status (teacher feedback)
  Future<PracticeItem> toggleLike(String id);

  /// Increment practice count
  Future<PracticeItem> incrementCount(String id);

  /// Decrement practice count
  Future<PracticeItem> decrementCount(String id);

  /// Get incomplete items for a student (for dashboard)
  Future<List<PracticeItem>> getIncompleteByStudentId(String studentId);

  /// Get items awaiting teacher confirmation (completed but not liked)
  Future<List<PracticeItem>> getAwaitingFeedback(String teacherId);
}

/// Mock implementation for development
class MockPracticeItemRepository implements PracticeItemRepository {
  final _uuid = const Uuid();
  final List<PracticeItem> _items = [];

  MockPracticeItemRepository() {
    _initMockData();
  }

  void _initMockData() {
    // No dummy data - users create their own practice items
  }

  @override
  Future<List<PracticeItem>> getByLessonId(String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items
        .where((item) => item.lessonId == lessonId)
        .toList()
        .sortedByPriority();
  }

  @override
  Future<List<PracticeItem>> getByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items
        .where((item) => item.studentId == studentId)
        .toList()
        .sortedByPriority();
  }

  @override
  Future<List<PracticeItem>> getByStudentIdAndDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _items
        .where((item) =>
            item.studentId == studentId &&
            item.createdAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            item.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList()
        .sortedByPriority();
  }

  @override
  Future<PracticeItem?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PracticeItem> create(PracticeItem item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: DateTime.now(),
    );
    _items.add(newItem);
    return newItem;
  }

  @override
  Future<PracticeItem> update(PracticeItem item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      throw Exception('Practice item not found');
    }
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    _items[index] = updatedItem;
    return updatedItem;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<PracticeItem> toggleComplete(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Practice item not found');
    }

    final item = _items[index];
    final updatedItem = item.isCompleted ? item.uncomplete() : item.complete();
    _items[index] = updatedItem;
    return updatedItem;
  }

  @override
  Future<PracticeItem> toggleLike(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Practice item not found');
    }

    final updatedItem = _items[index].toggleLike();
    _items[index] = updatedItem;
    return updatedItem;
  }

  @override
  Future<PracticeItem> incrementCount(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Practice item not found');
    }

    final updatedItem = _items[index].incrementCount();
    _items[index] = updatedItem;
    return updatedItem;
  }

  @override
  Future<PracticeItem> decrementCount(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Practice item not found');
    }

    final updatedItem = _items[index].decrementCount();
    _items[index] = updatedItem;
    return updatedItem;
  }

  @override
  Future<List<PracticeItem>> getIncompleteByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items
        .where((item) => item.studentId == studentId && !item.isCompleted)
        .toList()
        .sortedByPriority();
  }

  @override
  Future<List<PracticeItem>> getAwaitingFeedback(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items
        .where((item) =>
            item.teacherId == teacherId &&
            item.isCompleted &&
            !item.hasLike)
        .toList()
      ..sort((a, b) => (b.completedAt ?? DateTime.now())
          .compareTo(a.completedAt ?? DateTime.now()));
  }
}
