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
    final now = DateTime.now();
    const teacherId = 'teacher_1';

    PracticeItem makeItem({
      required String id,
      required String lessonId,
      required String studentId,
      required String title,
      PracticeType type = PracticeType.repertoire,
      PracticePriority priority = PracticePriority.should,
      bool isCompleted = false,
      int daysAgo = 0,
    }) {
      final created = now.subtract(Duration(days: daysAgo));
      return PracticeItem(
        id: id,
        lessonId: lessonId,
        studentId: studentId,
        teacherId: teacherId,
        type: type,
        title: title,
        priority: priority,
        isCompleted: isCompleted,
        practiceCount: isCompleted ? 1 : 0,
        completedAt: isCompleted ? created.add(const Duration(hours: 2)) : null,
        createdAt: created,
      );
    }

    _items.addAll([
      // student_1 (김민준) - 3 items, 2 completed
      makeItem(id: 'pi_01', lessonId: 'lesson_001', studentId: 'student_1',
          title: 'Canon in D - A섹션', priority: PracticePriority.must,
          isCompleted: true, daysAgo: 3),
      makeItem(id: 'pi_02', lessonId: 'lesson_001', studentId: 'student_1',
          title: 'G Major 음계 3옥타브', type: PracticeType.technique,
          isCompleted: true, daysAgo: 3),
      makeItem(id: 'pi_03', lessonId: 'lesson_001', studentId: 'student_1',
          title: 'Minuet No.2 - 리듬 연습', priority: PracticePriority.could,
          daysAgo: 3),

      // student_2 (이서연) - 4 items, 3 completed
      makeItem(id: 'pi_04', lessonId: 'lesson_002', studentId: 'student_2',
          title: 'Gavotte - 전체 통주', priority: PracticePriority.must,
          isCompleted: true, daysAgo: 2),
      makeItem(id: 'pi_05', lessonId: 'lesson_002', studentId: 'student_2',
          title: 'D Major 음계', type: PracticeType.technique,
          isCompleted: true, daysAgo: 2),
      makeItem(id: 'pi_06', lessonId: 'lesson_002', studentId: 'student_2',
          title: '활쏘기 자세 연습', type: PracticeType.technique,
          isCompleted: true, daysAgo: 2),
      makeItem(id: 'pi_07', lessonId: 'lesson_002', studentId: 'student_2',
          title: 'Bourree - B섹션 암보', priority: PracticePriority.could,
          daysAgo: 2),

      // student_3 (박지호) - 2 items, 0 completed
      makeItem(id: 'pi_08', lessonId: 'lesson_005', studentId: 'student_3',
          title: 'Cello Suite No.1 Prelude', priority: PracticePriority.must,
          daysAgo: 1),
      makeItem(id: 'pi_09', lessonId: 'lesson_005', studentId: 'student_3',
          title: 'C Major 음계', type: PracticeType.technique,
          daysAgo: 1),

      // student_5 (정다은) - 3 items, 1 completed
      makeItem(id: 'pi_10', lessonId: 'lesson_003', studentId: 'student_5',
          title: 'Suzuki Vol.2 Musette', priority: PracticePriority.must,
          isCompleted: true, daysAgo: 2),
      makeItem(id: 'pi_11', lessonId: 'lesson_003', studentId: 'student_5',
          title: 'A Minor 음계', type: PracticeType.technique,
          daysAgo: 2),
      makeItem(id: 'pi_12', lessonId: 'lesson_003', studentId: 'student_5',
          title: '비브라토 기초', type: PracticeType.technique,
          priority: PracticePriority.could, daysAgo: 2),

      // student_11 (이하은) - 3 items, 3 completed (모범생)
      makeItem(id: 'pi_13', lessonId: 'lesson_007', studentId: 'student_11',
          title: 'Meditation - 전체 통주', priority: PracticePriority.must,
          isCompleted: true, daysAgo: 1),
      makeItem(id: 'pi_14', lessonId: 'lesson_007', studentId: 'student_11',
          title: 'E Major 음계', type: PracticeType.technique,
          isCompleted: true, daysAgo: 1),
      makeItem(id: 'pi_15', lessonId: 'lesson_007', studentId: 'student_11',
          title: '3포지션 이동 연습', type: PracticeType.technique,
          isCompleted: true, daysAgo: 1),

      // student_12 (박준혁) - 2 items, 0 completed
      makeItem(id: 'pi_16', lessonId: 'lesson_004', studentId: 'student_12',
          title: 'Twinkle Variations', priority: PracticePriority.must,
          daysAgo: 3),
      makeItem(id: 'pi_17', lessonId: 'lesson_004', studentId: 'student_12',
          title: 'A장조 음계', type: PracticeType.technique,
          daysAgo: 3),
    ]);
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
