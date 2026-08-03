import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:lessonaza/features/onboarding/presentation/extensions/onboarding_quest_visuals.dart';

void main() {
  group('OnboardingQuestVisuals', () {
    test('maps the teacher required quest ids to their display strings', () {
      final titles = OnboardingProgress.teacherRequiredQuests
          .map((quest) => quest.title)
          .toList();
      expect(titles, <String>[
        AppStrings.onboardingQuestProfileCreatedTitle,
        AppStrings.onboardingQuestFirstStudentTitle,
        AppStrings.onboardingQuestFirstLessonTitle,
        AppStrings.onboardingQuestFirstNoteTitle,
        AppStrings.onboardingQuestPhoneVerifiedTitle,
      ]);

      final descriptions = OnboardingProgress.teacherRequiredQuests
          .map((quest) => quest.description)
          .toList();
      expect(descriptions, <String>[
        AppStrings.onboardingQuestProfileCreatedDescription,
        AppStrings.onboardingQuestFirstStudentDescription,
        AppStrings.onboardingQuestFirstLessonDescription,
        AppStrings.onboardingQuestFirstNoteDescription,
        AppStrings.onboardingQuestPhoneVerifiedDescription,
      ]);
    });

    test('falls back to the raw id for unknown quests', () {
      const unknown = OnboardingQuest.optional(id: 'unknown-quest');
      expect(unknown.title, 'unknown-quest');
      expect(unknown.description, '');
    });
  });
}
