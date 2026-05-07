import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/settings/domain/entities/app_release.dart';

void main() {
  test('AppVersionSnapshot formats the display version and update state', () {
    final snapshot = AppVersionSnapshot(
      currentVersion: '1.2.0',
      buildNumber: '45',
      latestVersion: '1.3.0',
      checkedAt: DateTime.utc(2026, 5, 7),
    );

    expect(snapshot.displayVersion, '1.2.0 (45)');
    expect(snapshot.hasUpdate, isTrue);
  });

  test('ReviewPromptPolicy waits for the lesson threshold and cooldown', () {
    const policy = ReviewPromptPolicy(completedLessonThreshold: 10);
    final now = DateTime.utc(2026, 5, 7);

    expect(policy.isEligible(completedLessonCount: 9, now: now), isFalse);
    expect(policy.isEligible(completedLessonCount: 10, now: now), isTrue);
    expect(
      policy.isEligible(
        completedLessonCount: 12,
        lastPromptedAt: now.subtract(const Duration(days: 29)),
        now: now,
      ),
      isFalse,
    );
    expect(
      policy.isEligible(
        completedLessonCount: 12,
        lastPromptedAt: now.subtract(const Duration(days: 30)),
        now: now,
      ),
      isTrue,
    );
  });
}
