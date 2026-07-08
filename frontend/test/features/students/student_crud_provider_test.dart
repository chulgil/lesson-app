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
    'updateStudent 후 keepAlive studentsProvider 가 갱신된다 (read/write 분리 가드 — A1)',
    () async {
      // studentsProvider(keepAlive) 를 watch 하는 화면(레슨추가 피커·홈·분석)이
      // 학생 수정 후 stale 되던 버그(2026-07-08 감사 A1)의 회귀 가드.
      // fix(updateStudent 의 ref.invalidate)를 되돌리면 캐시된 옛 이름이 남아 RED.
      final repository = _FakeStudentRepository();
      final container = ProviderContainer(
        overrides: [studentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(studentsNotifierProvider.notifier)
          .addStudent(
            Student(
              id: 's1',
              name: '원래이름',
              instrument: '피아노',
              createdAt: DateTime(2026),
            ),
          );
      // 화면이 studentsProvider 를 watch 하는 상황을 재현 (keepAlive 유지).
      final sub = container.listen(studentsProvider, (_, __) {});
      addTearDown(sub.close);
      expect(
        (await container.read(studentsProvider.future)).single.name,
        '원래이름',
      );

      await container
          .read(studentsNotifierProvider.notifier)
          .updateStudent(
            Student(
              id: 's1',
              name: '바뀐이름',
              instrument: '피아노',
              createdAt: DateTime(2026),
            ),
          );

      expect(
        (await container.read(studentsProvider.future)).single.name,
        '바뀐이름',
      );
    },
  );

  test('deleteStudent 후 keepAlive studentsProvider 가 갱신된다 (A1)', () async {
    final repository = _FakeStudentRepository();
    final container = ProviderContainer(
      overrides: [studentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(studentsNotifierProvider.notifier)
        .addStudent(
          Student(
            id: 's1',
            name: '이서연',
            instrument: '피아노',
            createdAt: DateTime(2026),
          ),
        );
    final sub = container.listen(studentsProvider, (_, __) {});
    addTearDown(sub.close);
    expect(await container.read(studentsProvider.future), hasLength(1));

    await container.read(studentsNotifierProvider.notifier).deleteStudent('s1');

    expect(await container.read(studentsProvider.future), isEmpty);
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
  Future<Student> updateStudent(Student student) async {
    final i = _students.indexWhere((s) => s.id == student.id);
    if (i != -1) _students[i] = student;
    return student;
  }

  @override
  Future<void> deleteStudent(String id) async {
    _students.removeWhere((s) => s.id == id);
  }

  @override
  Future<Student> getMyProfile() async =>
      myProfile ?? (throw StateError('myProfile not set'));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
