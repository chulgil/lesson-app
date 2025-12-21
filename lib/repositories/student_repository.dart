import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/student.dart';

/// Repository for managing student data
abstract class StudentRepository {
  Future<List<Student>> getStudents();
  Future<Student?> getStudent(String id);
  Future<Student> createStudent(Student student);
  Future<Student> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<List<Student>> searchStudents(String query);
}

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
      Student(
        id: 'student_1',
        name: '홍길동',
        instrument: '바이올린',
        phone: '010-1234-5678',
        parentPhone: '010-9876-5432',
        email: 'hong@example.com',
        profileColor: Colors.blue,
        lessonDay: '화요일',
        lessonTime: '14:00',
        lessonDuration: 60,
        totalLessons: 48,
        monthlyLessons: 8,
        practiceStatus: PracticeStatus.good,
        practiceRate: 5,
        createdAt: now.subtract(const Duration(days: 180)),
        isActive: true,
      ),
      Student(
        id: 'student_2',
        name: '김영희',
        instrument: '피아노',
        phone: '010-2345-6789',
        profileColor: Colors.purple,
        lessonDay: '수요일',
        lessonTime: '16:00',
        lessonDuration: 45,
        totalLessons: 24,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.normal,
        practiceRate: 3,
        createdAt: now.subtract(const Duration(days: 90)),
        isActive: true,
      ),
      Student(
        id: 'student_3',
        name: '이철수',
        instrument: '첼로',
        phone: '010-3456-7890',
        parentPhone: '010-8765-4321',
        profileColor: Colors.teal,
        lessonDay: '금요일',
        lessonTime: '15:00',
        lessonDuration: 60,
        totalLessons: 12,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.poor,
        practiceRate: 1,
        notes: '왼손 자세 교정 필요',
        createdAt: now.subtract(const Duration(days: 45)),
        isActive: true,
      ),
      Student(
        id: 'student_4',
        name: '박민수',
        instrument: '바이올린',
        phone: '010-4567-8901',
        profileColor: Colors.orange,
        lessonDay: '토요일',
        lessonTime: '10:00',
        lessonDuration: 60,
        totalLessons: 96,
        monthlyLessons: 8,
        practiceStatus: PracticeStatus.good,
        practiceRate: 6,
        createdAt: now.subtract(const Duration(days: 365)),
        isActive: true,
      ),
      Student(
        id: 'student_5',
        name: '정수진',
        instrument: '플루트',
        phone: '010-5678-9012',
        profileColor: Colors.pink,
        lessonDay: '목요일',
        lessonTime: '17:00',
        lessonDuration: 45,
        totalLessons: 8,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.paused,
        practiceRate: 0,
        notes: '시험 기간 휴강',
        createdAt: now.subtract(const Duration(days: 30)),
        isActive: false,
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
}
