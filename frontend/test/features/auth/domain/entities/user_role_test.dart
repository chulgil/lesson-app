import 'package:flutter_test/flutter_test.dart';
import 'package:lesson_app/features/auth/domain/entities/user_role.dart';

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

    test('teacher has correct emoji', () {
      expect(UserRole.teacher.emoji, '👩‍🏫');
    });

    test('student has correct emoji', () {
      expect(UserRole.student.emoji, '🎻');
    });

    test('parent has correct emoji', () {
      expect(UserRole.parent.emoji, '👨‍👩‍👧');
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

    test('all roles have unique emojis', () {
      final emojis = UserRole.values.map((r) => r.emoji).toSet();
      expect(emojis.length, UserRole.values.length);
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
