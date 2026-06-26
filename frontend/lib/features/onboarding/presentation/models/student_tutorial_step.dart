import '../../../../core/l10n/app_strings.dart';

enum StudentTutorialStep { metronome, tuner, recording, feedback }

class StudentTutorialStepContent {
  final StudentTutorialStep step;
  final int index;
  final String title;
  final String description;

  const StudentTutorialStepContent({
    required this.step,
    required this.index,
    required this.title,
    required this.description,
  });

  static const List<StudentTutorialStepContent> all = [
    StudentTutorialStepContent(
      step: StudentTutorialStep.metronome,
      index: 1,
      title: '1. 메트로놈 켜보기',
      description: 'BPM을 조정하고 박자를 들어보세요',
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.tuner,
      index: 2,
      title: '2. 튜너로 음 맞추기',
      description: AppStrings.studentTutorialDescTuner,
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.recording,
      index: 3,
      title: '3. 첫 녹음 체험',
      description: AppStrings.studentTutorialDescRecording,
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.feedback,
      index: 4,
      title: '4. 선생님 피드백 확인',
      description: AppStrings.studentTutorialDescFeedback,
    ),
  ];

  static StudentTutorialStepContent forIndex(int index) => all[index];
}
