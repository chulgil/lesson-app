// Onboarding step extensions for teacher registration flow
// Note: The main OnboardingStep enum is defined in teacher_onboarding.dart

import '../../../profile/domain/entities/teacher_onboarding.dart';

/// Extension to add UI helpers to OnboardingStep
extension OnboardingStepExtensions on OnboardingStep {
  String get label {
    switch (this) {
      case OnboardingStep.roleSelect:
        return '역할 선택';
      case OnboardingStep.phoneVerification:
        return '휴대폰 인증';
      case OnboardingStep.profileSetup:
        return '프로필 설정';
      case OnboardingStep.tutorial:
        return '튜토리얼';
      case OnboardingStep.completed:
        return '완료';
    }
  }

  int get stepNumber {
    switch (this) {
      case OnboardingStep.roleSelect:
        return 1;
      case OnboardingStep.phoneVerification:
        return 2;
      case OnboardingStep.profileSetup:
        return 3;
      case OnboardingStep.tutorial:
        return 4;
      case OnboardingStep.completed:
        return 5;
    }
  }

  double get progress {
    return stepNumber / OnboardingStep.values.length;
  }
}
