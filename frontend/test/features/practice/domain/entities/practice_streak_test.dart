import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';

void main() {
  test('calculates streak display state without presentation dependencies', () {
    final now = DateTime(2026, 5, 7);

    expect(
      PracticeStreak(
        id: 'streak_0',
        studentId: 'student_1',
        updatedAt: now,
      ).streakLevel,
      0,
    );

    expect(
      PracticeStreak(
        id: 'streak_3',
        studentId: 'student_1',
        currentStreak: 3,
        updatedAt: now,
      ).streakLevel,
      1,
    );

    expect(
      PracticeStreak(
        id: 'streak_12',
        studentId: 'student_1',
        currentStreak: 12,
        updatedAt: now,
      ).streakLevel,
      2,
    );

    expect(
      PracticeStreak(
        id: 'streak_30',
        studentId: 'student_1',
        currentStreak: 30,
        updatedAt: now,
      ).streakLevel,
      3,
    );
  });
}
