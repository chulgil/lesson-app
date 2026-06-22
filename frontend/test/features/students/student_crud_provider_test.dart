import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';
import 'package:lessonaza/features/students/presentation/providers/student_repository_provider.dart';

void main() {
  test('addStudent refreshes home getting-started student source', () async {
    final repository = _FakeStudentRepository();
    final container = ProviderContainer(
      overrides: [studentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(homeStudentsProvider.future), isEmpty);

    await container
        .read(studentsNotifierProvider.notifier)
        .addStudent(
          Student(
            id: 'student-1',
            name: '이서연',
            instrument: '피아노',
            createdAt: DateTime(2026),
          ),
        );

    final students = await container.read(homeStudentsProvider.future);
    expect(students, hasLength(1));
    expect(students.single.id, 'student-1');
  });

  test(
    'currentStudentId resolves the real Student.id via getMyProfile (not auth userId)',
    () async {
      // Regression guard: the student home must resolve the logged-in user's
      // real Student.id (GET /students/me/profile), never use the auth userId
      // as a student id. On remote those differ → 404 "Student not found"
      // (mock matched by coincidence). The id must come from getMyProfile().
      final repository =
          _FakeStudentRepository()
            ..myProfile = Student(
              id: 'real-student-42',
              name: '김민준',
              instrument: '바이올린',
              createdAt: DateTime(2026),
            );
      final container = ProviderContainer(
        overrides: [studentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(currentStudentIdProvider.future),
        'real-student-42',
      );
      final student = await container.read(currentStudentProvider.future);
      expect(student.id, 'real-student-42');
    },
  );
}

class _FakeStudentRepository implements StudentRepository {
  final List<Student> _students = [];

  /// Profile returned by [getMyProfile] (the logged-in student's own record).
  Student? myProfile;

  @override
  Future<List<Student>> getStudents() async => List.unmodifiable(_students);

  @override
  Future<Student> createStudent(Student student) async {
    _students.add(student);
    return student;
  }

  @override
  Future<Student> getMyProfile() async =>
      myProfile ?? (throw StateError('myProfile not set'));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
