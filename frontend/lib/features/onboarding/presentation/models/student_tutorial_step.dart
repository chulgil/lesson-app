import 'package:flutter/material.dart';

enum StudentTutorialStep { metronome, tuner, recording, feedback }

class StudentTutorialStepContent {
  final StudentTutorialStep step;
  final int index;
  final String title;
  final String description;
  final IconData icon;

  const StudentTutorialStepContent({
    required this.step,
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<StudentTutorialStepContent> all = [
    StudentTutorialStepContent(
      step: StudentTutorialStep.metronome,
      index: 1,
      title: '1. 메트로놈 켜보기',
      description: 'BPM을 조정하고 박자를 들어보세요',
      icon: Icons.av_timer_rounded,
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.tuner,
      index: 2,
      title: '2. 튜너로 음 맞추기',
      description: '원하는 음을 선택해 정확한 음높이를 확인하세요',
      icon: Icons.graphic_eq_rounded,
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.recording,
      index: 3,
      title: '3. 첫 녹음 체험',
      description: '버튼을 길게 눌러 2초 이상 녹음해보세요',
      icon: Icons.fiber_manual_record_rounded,
    ),
    StudentTutorialStepContent(
      step: StudentTutorialStep.feedback,
      index: 4,
      title: '4. 선생님 피드백 확인',
      description: '레슨 후 받게 될 피드백을 미리 살펴보세요',
      icon: Icons.edit_note_rounded,
    ),
  ];

  static StudentTutorialStepContent forIndex(int index) => all[index];
}
