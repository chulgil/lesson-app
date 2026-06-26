import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/extensions/user_role_visuals.dart';

void main() {
  group('UserRole', () {
    test('teacher has correct label', () {
      expect(UserRole.teacher.label, '선생님');
    });

    test('student has correct label', () {
      expect(UserRole.student.label, '학생');
    });

    test('parent has correct label', () {
      expect(UserRole.parent.label, '학부모');
    });

    test('teacher has correct icon', () {
      expect(UserRole.teacher.icon, Icons.school);
    });

    test('student has correct icon', () {
      expect(UserRole.student.icon, Icons.music_note);
    });

    test('parent has correct icon', () {
      expect(UserRole.parent.icon, Icons.family_restroom);
    });

    test('teacher has correct home route', () {
      expect(UserRole.teacher.homeRoute, '/home');
    });

    test('student has correct home route', () {
      expect(UserRole.student.homeRoute, '/student-home');
    });

    test('parent has correct home route', () {
      expect(UserRole.parent.homeRoute, '/parent-home');
    });

    test('all roles have unique labels', () {
      final labels = UserRole.values.map((r) => r.label).toSet();
      expect(labels.length, UserRole.values.length);
    });

    test('all roles have unique icons', () {
      final icons = UserRole.values.map((r) => r.icon).toSet();
      expect(icons.length, UserRole.values.length);
    });
  });

  group('MockStudentInfo', () {
    test('creates instance correctly', () {
      const info = MockStudentInfo(id: 'test_id', name: 'Test Student');
      expect(info.id, 'test_id');
      expect(info.name, 'Test Student');
    });
  });
}
