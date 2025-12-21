import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/student.dart';
import '../../repositories/student_repository.dart';
import 'student_repository_provider.dart';

/// All students provider
final studentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudents();
});

/// Single student provider
final studentProvider =
    FutureProvider.family<Student?, String>((ref, id) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudent(id);
});

/// Search students provider
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final query = ref.watch(studentSearchQueryProvider);
  final repository = ref.watch(studentRepositoryProvider);

  if (query.isEmpty) {
    return repository.getStudents();
  }
  return repository.searchStudents(query);
});

/// Student list notifier for CRUD operations
class StudentsNotifier extends AsyncNotifier<List<Student>> {
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

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getStudents());
  }

  /// Update student status (trial → active, active → paused, etc.)
  Future<Student> updateStudentStatus(
      String studentId, StudentStatus status) async {
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
final studentsByEnrollmentStatusProvider =
    FutureProvider.family<List<Student>, StudentStatus>((ref, status) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentsByStatus(status);
});

/// Trial students provider
final trialStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentsByStatus(StudentStatus.trial);
});

final studentsNotifierProvider =
    AsyncNotifierProvider<StudentsNotifier, List<Student>>(
  StudentsNotifier.new,
);
