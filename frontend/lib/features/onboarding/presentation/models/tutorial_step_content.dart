import '../../../../core/l10n/app_strings.dart';
import '../../../profile/domain/entities/teacher_onboarding.dart';

/// Tutorial step content for onboarding presentation.
class TutorialStepContent {
  final TutorialStep step;
  final String title;
  final String description;
  final String? imageAsset;
  final String? animationAsset;

  const TutorialStepContent({
    required this.step,
    required this.title,
    required this.description,
    this.imageAsset,
    this.animationAsset,
  });

  static const List<TutorialStepContent> allSteps = [
    TutorialStepContent(
      step: TutorialStep.welcome,
      title: '1. 선생님 기본 정보',
      description: AppStrings.tutorialDescProfileSetup,
      imageAsset: 'assets/images/onboarding/welcome.png',
    ),
    TutorialStepContent(
      step: TutorialStep.inviteStudent,
      title: '2. 샘플 학생 만들기',
      description: AppStrings.tutorialDescStudentPreview,
      imageAsset: 'assets/images/onboarding/invite.png',
    ),
    TutorialStepContent(
      step: TutorialStep.writeFeedback,
      title: '3. 첫 레슨 노트',
      description: AppStrings.tutorialDescLessonNote,
      imageAsset: 'assets/images/onboarding/feedback.png',
    ),
  ];

  static TutorialStepContent getContent(TutorialStep step) {
    return allSteps.firstWhere((content) => content.step == step);
  }
}
