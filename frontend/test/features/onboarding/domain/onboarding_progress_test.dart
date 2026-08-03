import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/onboarding/domain/entities/onboarding_progress.dart';

void main() {
  group('OnboardingProgress', () {
    test('exposes the teacher required quest checklist in a fixed order', () {
      final progress = OnboardingProgress.teacher(userId: 'teacher_1');

      expect(progress.userId, 'teacher_1');
      expect(progress.quests, hasLength(5));
      expect(progress.quests.map((quest) => quest.id).toList(), <String>[
        'profile-created',
        'first-student',
        'first-lesson',
        'first-note',
        'phone-verified',
      ]);
      expect(progress.completedRequiredQuestCount, 0);
      expect(progress.totalRequiredQuestCount, 5);
      expect(progress.progressPercentage, 0);
      expect(progress.isComplete, isFalse);
      expect(progress.progressLabel, '0/5');
    });

    test(
      'keeps five total required quests until all required quests are complete',
      () {
        final quests = OnboardingProgress.teacherRequiredQuests;
        final progress = OnboardingProgress(
          userId: 'teacher_1',
          quests: [
            quests[0].copyWith(isComplete: true),
            quests[1].copyWith(isComplete: true),
            quests[2].copyWith(isComplete: true),
            quests[3],
            quests[4],
          ],
          startedAt: DateTime(2026, 5, 7),
        );

        expect(progress.completedRequiredQuestCount, 3);
        expect(progress.totalRequiredQuestCount, 5);
        expect(progress.progressPercentage, 60);
        expect(progress.isComplete, isFalse);
        expect(progress.progressLabel, '3/5');
      },
    );

    test(
      'marks the progress complete only when all five required quests are complete',
      () {
        final progress = OnboardingProgress(
          userId: 'teacher_1',
          quests: OnboardingProgress.teacherRequiredQuests
              .map((quest) => quest.copyWith(isComplete: true))
              .toList(growable: false),
          startedAt: DateTime(2026, 5, 7),
        );

        expect(progress.completedRequiredQuestCount, 5);
        expect(progress.totalRequiredQuestCount, 5);
        expect(progress.progressPercentage, 100);
        expect(progress.isComplete, isTrue);
        expect(progress.progressLabel, '5/5');
      },
    );
  });
}
