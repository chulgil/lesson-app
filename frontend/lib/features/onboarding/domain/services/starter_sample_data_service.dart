import 'package:uuid/uuid.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/domain/repositories/lesson_repository.dart';
import '../../../practice/domain/entities/practice_log.dart';
import '../../../practice/domain/repositories/practice_repository.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/starter_sample_data.dart';

/// Builds and removes the opt-in starter sample (UXB-1).
///
/// Every write goes through the ordinary manual (수기) repositories, so the
/// sample behaves exactly like data the teacher entered by hand. No
/// subscription is issued: completing a lesson whose `subscriptionId` is null
/// is a no-op for the deduction counter, which is what keeps the walkthrough
/// out of the billing domain.
class StarterSampleDataService {
  final StudentRepository _students;
  final LessonRepository _lessons;
  final PracticeRepository _practice;
  final Uuid _uuid;

  StarterSampleDataService({
    required StudentRepository studentRepository,
    required LessonRepository lessonRepository,
    required PracticeRepository practiceRepository,
    Uuid uuid = const Uuid(),
  }) : _students = studentRepository,
       _lessons = lessonRepository,
       _practice = practiceRepository,
       _uuid = uuid;

  /// How far in the past the sample lesson sits. Recent enough to read as
  /// "지난 레슨", old enough that it never collides with today's schedule.
  static const sampleLessonDaysAgo = 3;

  /// Creates the sample rows in dependency order.
  ///
  /// Throws [StarterSampleCreationFailure] when any step fails; rows created
  /// before the failure are removed in reverse order first.
  Future<StarterSampleData> create({
    required StarterSampleContent content,
    required DateTime now,
  }) async {
    StarterSampleData? progress;
    try {
      final student = await _students.createStudent(
        _buildStudent(content, now),
      );
      progress = StarterSampleData(studentId: student.id);

      final lesson = await _lessons.createLesson(
        _buildLesson(content, student, now),
      );
      progress = progress.copyWith(lessonId: lesson.id);

      // The note first, then the status: `updateLessonStatus` is the only path
      // that runs the completion side effects, so it has to see the final
      // entity (#1237/#1238 split the two writes for that reason).
      final noted = await _lessons.updateLessonFeedback(
        lesson,
        feedback: content.lessonFeedback,
        keyPoints: content.lessonKeyPoints,
        practiceTips: content.lessonPracticeTips,
      );
      await _lessons.updateLessonStatus(noted, LessonStatus.completed);

      final log = await _practice.createPracticeLog(
        _buildPracticeLog(content, student, now),
      );
      return progress.copyWith(practiceLogId: log.id);
    } catch (error) {
      final rolledBack = progress == null || await _rollback(progress);
      throw StarterSampleCreationFailure(error, rolledBack: rolledBack);
    }
  }

  /// Removes the sample rows in reverse creation order.
  ///
  /// The child rows are best-effort: only the student is visible to the
  /// teacher, so a stuck practice log must not block removing what they can
  /// actually see. A failed student delete propagates so the caller keeps the
  /// stored ids and can retry.
  Future<void> remove(StarterSampleData sample) async {
    final practiceLogId = sample.practiceLogId;
    if (practiceLogId != null) {
      await _bestEffort(() => _practice.deletePracticeLog(practiceLogId));
    }
    final lessonId = sample.lessonId;
    if (lessonId != null) {
      await _bestEffort(() => _lessons.deleteLesson(lessonId));
    }
    await _students.deleteStudent(sample.studentId);
  }

  /// Deletes whatever was created before the failure. Returns false when any
  /// delete failed, so the caller can warn about the residue.
  Future<bool> _rollback(StarterSampleData progress) async {
    var clean = true;
    final lessonId = progress.lessonId;
    if (lessonId != null) {
      clean = await _bestEffort(() => _lessons.deleteLesson(lessonId)) && clean;
    }
    clean =
        await _bestEffort(() => _students.deleteStudent(progress.studentId)) &&
        clean;
    return clean;
  }

  Future<bool> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  Student _buildStudent(StarterSampleContent content, DateTime now) {
    return Student(
      id: _uuid.v4(),
      name: content.studentName,
      instrument: content.instrument,
      status: StudentStatus.trial,
      notes: content.studentNotes,
      createdAt: now,
    );
  }

  Lesson _buildLesson(
    StarterSampleContent content,
    Student student,
    DateTime now,
  ) {
    final past = now.subtract(const Duration(days: sampleLessonDaysAgo));
    return Lesson(
      id: _uuid.v4(),
      studentId: student.id,
      studentName: student.name,
      instrument: student.instrument,
      date: DateTime(past.year, past.month, past.day),
      startTime: '16:00',
      createdAt: now,
    );
  }

  PracticeLog _buildPracticeLog(
    StarterSampleContent content,
    Student student,
    DateTime now,
  ) {
    final yesterday = now.subtract(const Duration(days: 1));
    return PracticeLog(
      id: _uuid.v4(),
      studentId: student.id,
      date: DateTime(yesterday.year, yesterday.month, yesterday.day),
      totalMinutes: 30,
      notes: content.practiceNotes,
      createdAt: now,
    );
  }
}
