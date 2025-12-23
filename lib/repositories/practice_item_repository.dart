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

    // Student 1 - 김민준 (child)
    const student1Id = 'student_1';
    const lesson1Id = 'lesson_1';

    _items.addAll([
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson1Id,
        studentId: student1Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: '도레미송 1-8마디',
        description: '손가락 번호 정확하게!',
        priority: PracticePriority.must,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson1Id,
        studentId: student1Id,
        teacherId: teacherId,
        type: PracticeType.technique,
        title: '손가락 체조',
        description: '매일 5분씩',
        priority: PracticePriority.should,
        isCompleted: true,
        practiceCount: 3,
        completedAt: now.subtract(const Duration(hours: 5)),
        hasLike: true,
        likedAt: now.subtract(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson1Id,
        studentId: student1Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: '도레미송 9-16마디',
        description: '미리 봐두기',
        priority: PracticePriority.could,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    // Student 2 - 이서연 (student)
    const student2Id = 'student_2';
    const lesson2Id = 'lesson_2';

    _items.addAll([
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson2Id,
        studentId: student2Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: 'Canon in D - A섹션',
        description: '메트로놈 60으로 정확하게',
        priority: PracticePriority.must,
        isCompleted: true,
        practiceCount: 5,
        completedAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson2Id,
        studentId: student2Id,
        teacherId: teacherId,
        type: PracticeType.technique,
        title: 'G장조 스케일',
        description: '3옥타브, 레가토로',
        priority: PracticePriority.must,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson2Id,
        studentId: student2Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: 'Canon in D - B섹션',
        description: '천천히 음 확인하며 봐두기',
        priority: PracticePriority.should,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson2Id,
        studentId: student2Id,
        teacherId: teacherId,
        type: PracticeType.theory,
        title: '화성학 복습',
        description: '딸림 7화음 p.23-25',
        priority: PracticePriority.could,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    // Student 3 - 박지훈 (adult)
    const student3Id = 'student_3';
    const lesson3Id = 'lesson_3';

    _items.addAll([
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson3Id,
        studentId: student3Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: '에튀드 Op.25 No.1',
        description: '아르페지오 부분 집중',
        priority: PracticePriority.must,
        isCompleted: true,
        practiceCount: 7,
        completedAt: now.subtract(const Duration(days: 1)),
        hasLike: true,
        likedAt: now.subtract(const Duration(hours: 20)),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson3Id,
        studentId: student3Id,
        teacherId: teacherId,
        type: PracticeType.repertoire,
        title: '베토벤 소나타 1악장',
        description: '전개부 (67-120마디)',
        priority: PracticePriority.must,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      PracticeItem(
        id: _uuid.v4(),
        lessonId: lesson3Id,
        studentId: student3Id,
        teacherId: teacherId,
        type: PracticeType.technique,
        title: '스케일 전조 연습',
        description: 'C-G-D-A 순환',
        priority: PracticePriority.should,
        isCompleted: true,
        practiceCount: 2,
        completedAt: now.subtract(const Duration(hours: 8)),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
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
