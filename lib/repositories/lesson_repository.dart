import 'package:uuid/uuid.dart';

import '../models/lesson.dart';

/// Repository for managing lesson data
abstract class LessonRepository {
  Future<List<Lesson>> getLessons();
  Future<List<Lesson>> getLessonsByStudent(String studentId);
  Future<List<Lesson>> getLessonsByDate(DateTime date);
  Future<List<Lesson>> getLessonsByDateRange(DateTime start, DateTime end);
  Future<List<Lesson>> getUpcomingLessons({int limit = 10});
  Future<List<Lesson>> getRecentLessons({int limit = 10});
  Future<Lesson?> getLesson(String id);
  Future<Lesson> createLesson(Lesson lesson);
  Future<Lesson> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
  Future<void> cancelLesson(String id);
}

/// Mock implementation for development
class MockLessonRepository implements LessonRepository {
  final _uuid = const Uuid();
  final List<Lesson> _lessons = [];

  MockLessonRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    _lessons.addAll([
      // Upcoming lessons
      Lesson(
        id: 'lesson_1',
        studentId: 'student_1',
        studentName: '홍길동',
        teacherName: '김선생님',
        instrument: '바이올린',
        date: now.add(const Duration(days: 2)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(id: 'p1', name: '바흐 파르티타 2번', movement: 'Allemande'),
          LessonPiece(id: 'p2', name: '크로이처 에튀드', movement: '2번'),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Lesson(
        id: 'lesson_2',
        studentId: 'student_2',
        studentName: '김영희',
        teacherName: '김선생님',
        instrument: '피아노',
        date: now.add(const Duration(days: 1)),
        startTime: '16:00',
        duration: 45,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(id: 'p3', name: '쇼팽 왈츠', opus: 'Op.64', movement: 'No.2'),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Lesson(
        id: 'lesson_3',
        studentId: 'student_4',
        studentName: '박민수',
        teacherName: '김선생님',
        instrument: '바이올린',
        date: now.add(const Duration(days: 3)),
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
              id: 'p4', name: '멘델스존 바이올린 협주곡', movement: '1악장'),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // Today's lesson
      Lesson(
        id: 'lesson_today',
        studentId: 'student_3',
        studentName: '이철수',
        teacherName: '김선생님',
        instrument: '첼로',
        date: now,
        startTime: '15:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(id: 'p5', name: '바흐 무반주 첼로 모음곡', movement: '1번'),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      ),

      // Past lessons
      Lesson(
        id: 'lesson_past_1',
        studentId: 'student_1',
        studentName: '홍길동',
        teacherName: '김선생님',
        instrument: '바이올린',
        date: now.subtract(const Duration(days: 5)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(id: 'p1', name: '바흐 파르티타 2번', movement: 'Allemande'),
        ],
        feedback: '보잉이 많이 개선되었습니다. 특히 레가토 부분이 좋아졌어요.',
        keyPoints: const [
          '활 압력 조절 연습',
          '3번 손가락 음정 주의',
          '프레이징 4마디 단위로',
        ],
        practiceTips: '매일 스케일 연습 15분 + 곡 연습 30분을 권장합니다.',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Lesson(
        id: 'lesson_past_2',
        studentId: 'student_1',
        studentName: '홍길동',
        teacherName: '김선생님',
        instrument: '바이올린',
        date: now.subtract(const Duration(days: 12)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(id: 'p1', name: '바흐 파르티타 2번', movement: 'Allemande'),
        ],
        feedback: '1악장 템포 안정화 작업을 진행했습니다.',
        createdAt: now.subtract(const Duration(days: 19)),
      ),
      Lesson(
        id: 'lesson_past_3',
        studentId: 'student_2',
        studentName: '김영희',
        teacherName: '김선생님',
        instrument: '피아노',
        date: now.subtract(const Duration(days: 7)),
        startTime: '16:00',
        duration: 45,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(id: 'p3', name: '쇼팽 왈츠', opus: 'Op.64', movement: 'No.2'),
        ],
        feedback: '왈츠 리듬감이 좋아졌습니다. 페달 사용에 더 신경 써주세요.',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ]);
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
