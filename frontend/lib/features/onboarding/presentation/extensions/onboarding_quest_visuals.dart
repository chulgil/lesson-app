import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/onboarding_progress.dart';

/// Presentation mapping for [OnboardingQuest] (#602).
///
/// Resolves the user-facing title/description from the quest [OnboardingQuest.id]
/// so the domain entity stays free of display strings. Unknown ids fall back to
/// the raw id (defensive — keeps the checklist renderable).
extension OnboardingQuestVisuals on OnboardingQuest {
  String get title => switch (id) {
    'profile-created' => AppStrings.onboardingQuestProfileCreatedTitle,
    'first-student' => AppStrings.onboardingQuestFirstStudentTitle,
    'first-lesson' => AppStrings.onboardingQuestFirstLessonTitle,
    'first-note' => AppStrings.onboardingQuestFirstNoteTitle,
    'phone-verified' => AppStrings.onboardingQuestPhoneVerifiedTitle,
    _ => id,
  };

  String get description => switch (id) {
    'profile-created' => AppStrings.onboardingQuestProfileCreatedDescription,
    'first-student' => AppStrings.onboardingQuestFirstStudentDescription,
    'first-lesson' => AppStrings.onboardingQuestFirstLessonDescription,
    'first-note' => AppStrings.onboardingQuestFirstNoteDescription,
    'phone-verified' => AppStrings.onboardingQuestPhoneVerifiedDescription,
    _ => '',
  };
}
