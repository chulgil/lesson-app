import 'dart:ui' show Color;

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
    final now = DateTime.now();

    _students.addAll([
      // 수강권 테스트용 학생
      Student(
        id: 'student_1',
        name: '김민준',
        instrument: '바이올린',
        level: StudentLevel.intermediate,
        status: StudentStatus.active,
        isActive: true,
        profileColor: const Color(0xFF6B5B95),
        createdAt: now.subtract(const Duration(days: 90)),
        phone: '010-1234-5678',
        email: 'minjun@example.com',
        notes: '수강권 테스트 학생 - 14개 수강권 케이스',
      ),
      Student(
        id: 'student_2',
        name: '이서연',
        instrument: '피아노',
        level: StudentLevel.beginner,
        status: StudentStatus.active,
        isActive: true,
        profileColor: const Color(0xFFF4A460),
        createdAt: now.subtract(const Duration(days: 60)),
        phone: '010-2345-6789',
      ),
      Student(
        id: 'student_3',
        name: '박지호',
        instrument: '첼로',
        level: StudentLevel.advanced,
        status: StudentStatus.active,
        isActive: true,
        profileColor: const Color(0xFF2E8B57),
        createdAt: now.subtract(const Duration(days: 30)),
        phone: '010-3456-7890',
      ),
      Student(
        id: 'student_4',
        name: '최유진',
        instrument: '플루트',
        level: StudentLevel.beginner,
        status: StudentStatus.trial,
        isActive: true,
        profileColor: const Color(0xFF4A90D9),
        createdAt: now.subtract(const Duration(days: 7)),
        phone: '010-4567-8901',
        notes: '체험 레슨 예정',
      ),
      Student(
        id: 'student_5',
        name: '정하은',
        instrument: '클라리넷',
        level: StudentLevel.intermediate,
        status: StudentStatus.inactive,
        isActive: false,
        profileColor: const Color(0xFF999999),
        createdAt: now.subtract(const Duration(days: 120)),
        phone: '010-5678-9012',
        notes: '휴강 중',
      ),
    ]);
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
