import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/onboarding/presentation/extensions/onboarding_step_visuals.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_onboarding.dart';

void main() {
  group('OnboardingStepVisuals', () {
    test('provides centralized labels for each step', () {
      expect(OnboardingStep.roleSelect.label, '역할 선택');
      expect(OnboardingStep.phoneVerification.label, '휴대폰 인증');
      expect(OnboardingStep.profileSetup.label, '프로필 설정');
      expect(OnboardingStep.tutorial.label, '튜토리얼');
      expect(OnboardingStep.completed.label, '완료');
    });

    test('provides UI step number and progress', () {
      expect(OnboardingStep.roleSelect.stepNumber, 1);
      expect(OnboardingStep.completed.stepNumber, 5);
      expect(OnboardingStep.completed.progress, 1.0);
    });
  });
}
