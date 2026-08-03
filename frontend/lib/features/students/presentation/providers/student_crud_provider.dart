import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/analytics/analytics_provider.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import 'student_repository_provider.dart';

part 'student_crud_provider.g.dart';

/// All students provider
@Riverpod(keepAlive: true)
Future<List<Student>> students(StudentsRef ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudents();
}

/// Single student provider
@Riverpod(keepAlive: true)
Future<Student?> student(StudentRef ref, String id) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudent(id);
}

/// Current authenticated student's own profile (GET /students/me/profile).
///
/// SSOT for resolving the logged-in user's real [Student.id]. The auth
/// `userId` is NOT a `Student.id`; using it as one yields 404 "Student not
/// found" on remote (mock happened to match by coincidence). Watch this
/// instead of passing `currentUserId` as a student id.
@Riverpod(keepAlive: true)
Future<Student> currentStudent(CurrentStudentRef ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getMyProfile();
}

/// Convenience: the logged-in student's real `Student.id`.
@Riverpod(keepAlive: true)
Future<String> currentStudentId(CurrentStudentIdRef ref) async {
  final student = await ref.watch(currentStudentProvider.future);
  return student.id;
}

/// Search students provider
@Riverpod(keepAlive: true)
class StudentSearchQuery extends _$StudentSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

@Riverpod(keepAlive: true)
Future<List<Student>> filteredStudents(FilteredStudentsRef ref) async {
  final query = ref.watch(studentSearchQueryProvider);
  final repository = ref.watch(studentRepositoryProvider);

  if (query.isEmpty) {
    return repository.getStudents();
  }
  return repository.searchStudents(query);
}

/// Student list notifier for CRUD operations
@Riverpod(keepAlive: true)
class StudentsNotifier extends _$StudentsNotifier {
  StudentRepository get _repository => ref.read(studentRepositoryProvider);

  @override
  Future<List<Student>> build() async {
    return _repository.getStudents();
  }

  Future<Student> addStudent(Student student) async {
    state = const AsyncValue.loading();
    try {
      final newStudent = await _repository.createStudent(student);
      state = await AsyncValue.guard(() => _repository.getStudents());
      ref.invalidate(studentsProvider);
      ref.invalidate(filteredStudentsProvider);
      // #1209 — 학생 생성 성공. 진입점(수동 등록/온보딩)은 이 notifier 에서
      // 구분되지 않으므로 method 는 생략한다.
      unawaited(ref.read(analyticsServiceProvider).logStudentAdded());
      return newStudent;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Student> updateStudent(Student student) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateStudent(student);
      state = await AsyncValue.guard(() => _repository.getStudents());
      // keepAlive studentsProvider/filteredStudentsProvider 를 watch 하는 화면
      // (레슨추가 피커·홈·분석)이 stale 되지 않도록 addStudent 와 동일하게 무효화.
      ref.invalidate(studentsProvider);
      ref.invalidate(filteredStudentsProvider);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteStudent(id);
      state = await AsyncValue.guard(() => _repository.getStudents());
      ref.invalidate(studentsProvider);
      ref.invalidate(filteredStudentsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> archiveStudent(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.archiveStudent(id);
      state = await AsyncValue.guard(() => _repository.getStudents());
      ref.invalidate(studentsProvider);
      ref.invalidate(filteredStudentsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getStudents());
  }

  /// Update student status (trial → active, active → paused, etc.)
  Future<Student> updateStudentStatus(
    String studentId,
    StudentStatus status,
  ) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateStudentStatus(studentId, status);
      state = await AsyncValue.guard(() => _repository.getStudents());
      ref.invalidate(studentsProvider);
      ref.invalidate(filteredStudentsProvider);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider to get students by enrollment status (trial/active/paused/inactive)
@Riverpod(keepAlive: true)
Future<List<Student>> studentsByEnrollmentStatus(
  StudentsByEnrollmentStatusRef ref,
  StudentStatus status,
) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentsByStatus(status);
}

/// Trial students provider
@Riverpod(keepAlive: true)
Future<List<Student>> trialStudents(TrialStudentsRef ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentsByStatus(StudentStatus.trial);
}
