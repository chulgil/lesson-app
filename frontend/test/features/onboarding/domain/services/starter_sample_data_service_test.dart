import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/onboarding/domain/entities/starter_sample_data.dart';
import 'package:lessonaza/features/onboarding/domain/services/starter_sample_data_service.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repository.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';

const _content = StarterSampleContent(
  studentName: '예시 학생 (지워도 돼요)',
  studentNotes: '예시 데이터입니다',
  instrument: '바이올린',
  lessonFeedback: '레슨 노트 예시',
  lessonKeyPoints: ['활 속도', '음정'],
  lessonPracticeTips: '느리게 다섯 번',
  practiceNotes: '연습 기록 예시',
);

final _now = DateTime(2026, 8, 20, 10, 30);

void main() {
  group('StarterSampleDataService.create', () {
    test(
      'writes a student, a completed lesson with a note, and a log',
      () async {
        final students = _FakeStudentRepository();
        final lessons = _FakeLessonRepository();
        final practice = _FakePracticeRepository();

        final sample = await _service(
          students,
          lessons,
          practice,
        ).create(content: _content, now: _now);

        expect(students.created, hasLength(1));
        expect(students.created.single.name, _content.studentName);
        expect(students.created.single.notes, _content.studentNotes);

        expect(lessons.created, hasLength(1));
        final lesson = lessons.created.single;
        expect(lesson.studentId, students.created.single.id);
        // 무수강권 완료 경로 — 구독을 만들지 않으므로 차감 로직에 닿지 않는다.
        expect(lesson.subscriptionId, isNull);
        expect(
          lesson.date,
          DateTime(2026, 8, 17),
          reason: '지난 레슨은 now 로부터 3일 전 날짜여야 한다',
        );

        expect(lessons.feedbackWrites.single.$2, _content.lessonFeedback);
        expect(lessons.statusWrites.single.$2, LessonStatus.completed);

        expect(practice.created, hasLength(1));
        expect(practice.created.single.studentId, students.created.single.id);

        expect(sample.studentId, students.created.single.id);
        expect(sample.lessonId, lesson.id);
        expect(sample.practiceLogId, practice.created.single.id);
      },
    );

    test(
      'rolls back the student and lesson when the log write fails',
      () async {
        final students = _FakeStudentRepository();
        final lessons = _FakeLessonRepository();
        final practice = _FakePracticeRepository()..failOnCreate = true;

        await expectLater(
          _service(
            students,
            lessons,
            practice,
          ).create(content: _content, now: _now),
          throwsA(
            isA<StarterSampleCreationFailure>().having(
              (failure) => failure.rolledBack,
              'rolledBack',
              isTrue,
            ),
          ),
        );

        expect(students.deleted, [students.created.single.id]);
        expect(lessons.deleted, [lessons.created.single.id]);
        expect(practice.deleted, isEmpty);
      },
    );

    test('reports residue when the rollback delete also fails', () async {
      final students = _FakeStudentRepository()..failOnDelete = true;
      final lessons = _FakeLessonRepository();
      final practice = _FakePracticeRepository()..failOnCreate = true;

      await expectLater(
        _service(
          students,
          lessons,
          practice,
        ).create(content: _content, now: _now),
        throwsA(
          isA<StarterSampleCreationFailure>().having(
            (failure) => failure.rolledBack,
            'rolledBack',
            isFalse,
          ),
        ),
      );
    });
  });

  group('StarterSampleDataService.remove', () {
    test('deletes exactly the sample rows in reverse order', () async {
      final students = _FakeStudentRepository();
      final lessons = _FakeLessonRepository();
      final practice = _FakePracticeRepository();
      final service = _service(students, lessons, practice);

      final sample = await service.create(content: _content, now: _now);
      // 예시와 무관한 실제 학생 — 정리 후에도 남아 있어야 한다.
      await students.createStudent(
        Student(
          id: 'real-student',
          name: '김하늘',
          instrument: '피아노',
          createdAt: _now,
        ),
      );

      await service.remove(sample);

      expect(practice.deleted, [sample.practiceLogId]);
      expect(lessons.deleted, [sample.lessonId]);
      expect(students.deleted, [sample.studentId]);
      expect(
        students.remaining.map((student) => student.name),
        ['김하늘'],
        reason: '정리는 예시 학생만 지워야 한다',
      );
    });

    test('still removes the student when a child delete fails', () async {
      final students = _FakeStudentRepository();
      final lessons = _FakeLessonRepository()..failOnDelete = true;
      final practice = _FakePracticeRepository();
      final service = _service(students, lessons, practice);

      final sample = await service.create(content: _content, now: _now);
      await service.remove(sample);

      expect(students.deleted, [sample.studentId]);
    });
  });
}

StarterSampleDataService _service(
  StudentRepository students,
  LessonRepository lessons,
  PracticeRepository practice,
) {
  return StarterSampleDataService(
    studentRepository: students,
    lessonRepository: lessons,
    practiceRepository: practice,
  );
}

class _FakeStudentRepository implements StudentRepository {
  final List<Student> created = [];
  final List<Student> remaining = [];
  final List<String> deleted = [];
  bool failOnDelete = false;
  int _sequence = 0;

  @override
  Future<Student> createStudent(Student student) async {
    final stored = student.copyWith(id: 'student-${++_sequence}');
    created.add(stored);
    remaining.add(stored);
    return stored;
  }

  @override
  Future<void> deleteStudent(String id) async {
    if (failOnDelete) throw StateError('delete failed');
    deleted.add(id);
    remaining.removeWhere((student) => student.id == id);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLessonRepository implements LessonRepository {
  final List<Lesson> created = [];
  final List<(String, String?)> feedbackWrites = [];
  final List<(String, LessonStatus)> statusWrites = [];
  final List<String> deleted = [];
  bool failOnDelete = false;
  int _sequence = 0;

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async {
    final stored = lesson.copyWith(id: 'lesson-${++_sequence}');
    created.add(stored);
    return stored;
  }

  @override
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) async {
    feedbackWrites.add((lesson.id, feedback));
    return lesson.copyWith(
      feedback: feedback,
      keyPoints: keyPoints,
      practiceTips: practiceTips,
    );
  }

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusWrites.add((lesson.id, status));
    return lesson.copyWith(status: status);
  }

  @override
  Future<void> deleteLesson(String id) async {
    if (failOnDelete) throw StateError('delete failed');
    deleted.add(id);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePracticeRepository implements PracticeRepository {
  final List<PracticeLog> created = [];
  final List<String> deleted = [];
  bool failOnCreate = false;
  int _sequence = 0;

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) async {
    if (failOnCreate) throw StateError('create failed');
    final stored = log.copyWith(id: 'log-${++_sequence}');
    created.add(stored);
    return stored;
  }

  @override
  Future<void> deletePracticeLog(String id) async {
    deleted.add(id);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
