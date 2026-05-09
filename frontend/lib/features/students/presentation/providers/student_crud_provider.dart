import 'package:riverpod_annotation/riverpod_annotation.dart';

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
