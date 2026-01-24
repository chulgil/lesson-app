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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _lessons.addAll([
      // Today's lessons
      Lesson(
        id: 'lesson_001',
        studentId: 'student_1',
        studentName: '김서연',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '바이올린',
        date: today,
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_001',
            name: '작은 별 변주곡',
            composer: 'Mozart',
          ),
        ],
        location: const LessonLocationInfo(
          name: '남부터미널 우드브릿지',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '활 잡는 자세가 많이 좋아졌어요. 다음 시간에는 3번 곡 연습해오세요.',
        keyPoints: ['보잉 연습', '음정 정확도'],
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      Lesson(
        id: 'lesson_002',
        studentId: 'student_2',
        studentName: '이준호',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '피아노',
        date: today,
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_002',
            name: '소나타',
            composer: 'Beethoven',
            opus: 'Op.27 No.2',
            movement: '1악장',
          ),
        ],
        location: const LessonLocationInfo(
          name: '학생 집 방문',
        ),
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      Lesson(
        id: 'lesson_003',
        studentId: 'student_3',
        studentName: '박민지',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '바이올린',
        date: today,
        startTime: '16:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_003',
            name: 'Concerto',
            composer: 'Vivaldi',
            opus: 'Op.8 No.1',
            notes: '봄 - 1악장',
          ),
        ],
        location: const LessonLocationInfo(
          name: '뮤직홀 연습실',
          address: '서울시 서초구 방배동 456',
        ),
        createdAt: today.subtract(const Duration(days: 3)),
      ),

      // Tomorrow's lessons
      Lesson(
        id: 'lesson_004',
        studentId: 'student_4',
        studentName: '최예은',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '첼로',
        date: today.add(const Duration(days: 1)),
        startTime: '11:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_004',
            name: 'Suite No.1',
            composer: 'Bach',
            movement: 'Prelude',
          ),
        ],
        location: const LessonLocationInfo(name: '온라인 (Zoom)'),
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Lesson(
        id: 'lesson_005',
        studentId: 'student_1',
        studentName: '김서연',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '바이올린',
        date: today.add(const Duration(days: 1)),
        startTime: '15:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_005',
            name: '가보트',
            composer: 'Gossec',
          ),
        ],
        location: const LessonLocationInfo(
          name: '남부터미널 우드브릿지',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 1)),
      ),

      // Day after tomorrow
      Lesson(
        id: 'lesson_006',
        studentId: 'student_2',
        studentName: '이준호',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '피아노',
        date: today.add(const Duration(days: 2)),
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_006',
            name: '터키 행진곡',
            composer: 'Mozart',
          ),
        ],
        location: const LessonLocationInfo(
          name: '학생 집 방문',
        ),
        createdAt: today,
      ),

      // Past lessons (yesterday)
      Lesson(
        id: 'lesson_007',
        studentId: 'student_3',
        studentName: '박민지',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 1)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_007',
            name: 'Minuet',
            composer: 'Boccherini',
          ),
        ],
        location: const LessonLocationInfo(
          name: '남부터미널 우드브릿지',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '비브라토 연습을 더 해오세요. 손목 힘을 빼고 자연스럽게.',
        keyPoints: ['비브라토', '운지법'],
        practiceTips: '메트로놈 60 템포로 천천히 연습하기',
        createdAt: today.subtract(const Duration(days: 8)),
      ),

      // Cancelled lesson
      Lesson(
        id: 'lesson_008',
        studentId: 'student_4',
        studentName: '최예은',
        teacherId: 'teacher_1',
        teacherName: '박선생',
        instrument: '첼로',
        date: today.subtract(const Duration(days: 2)),
        startTime: '11:00',
        duration: 60,
        status: LessonStatus.cancelled,
        pieces: const [],
        createdAt: today.subtract(const Duration(days: 9)),
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
