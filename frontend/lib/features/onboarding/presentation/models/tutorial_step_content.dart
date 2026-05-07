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
      description: '이름과 대표 악기를 입력해 첫 설정을 완성하세요',
      imageAsset: 'assets/images/onboarding/welcome.png',
    ),
    TutorialStepContent(
      step: TutorialStep.inviteStudent,
      title: '2. 샘플 학생 만들기',
      description: '학생 카드가 어떻게 보이는지 샘플로 확인하세요',
      imageAsset: 'assets/images/onboarding/invite.png',
    ),
    TutorialStepContent(
      step: TutorialStep.writeFeedback,
      title: '3. 첫 레슨 노트',
      description: '레슨 후 남길 기록을 미리 작성해보세요',
      imageAsset: 'assets/images/onboarding/feedback.png',
    ),
  ];

  static TutorialStepContent getContent(TutorialStep step) {
    return allSteps.firstWhere((content) => content.step == step);
  }
}
