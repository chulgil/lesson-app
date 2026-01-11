import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/student_repository.dart';

/// Mock implementation for development
class MockStudentRepository implements StudentRepository {
  final _uuid = const Uuid();
  final List<Student> _students = [];

  MockStudentRepository() {
    _initMockData();
  }

  void _initMockData() {
    // No dummy data - users create their own students
  }

  @override
  Future<List<Student>> getStudents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_students.where((s) => s.isActive));
  }

  @override
  Future<Student?> getStudent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student> createStudent(Student student) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newStudent = student.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _students.add(newStudent);
    return newStudent;
  }

  @override
  Future<Student> updateStudent(Student student) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index == -1) {
      throw Exception('Student not found');
    }
    final updated = student.copyWith(updatedAt: DateTime.now());
    _students[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteStudent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _students.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Student>> searchStudents(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();
    return _students
        .where((s) =>
            s.name.toLowerCase().contains(lowerQuery) ||
            s.instrument.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<Student> updateStudentStatus(String studentId, StudentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) {
      throw Exception('Student not found');
    }

    // Update isActive based on status
    final isActive = status == StudentStatus.trial || status == StudentStatus.active;

    final updated = _students[index].copyWith(
      status: status,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    _students[index] = updated;
    return updated;
  }

  @override
  Future<List<Student>> getStudentsByStatus(StudentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _students.where((s) => s.status == status).toList();
  }
}
