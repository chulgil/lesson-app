import '../../../../core/l10n/app_strings.dart';
import '../../../profile/domain/entities/teacher_onboarding.dart';

extension OnboardingStepVisuals on OnboardingStep {
  String get label {
    switch (this) {
      case OnboardingStep.roleSelect:
        return AppStrings.onboardingRoleSelect;
      case OnboardingStep.phoneVerification:
        return AppStrings.onboardingPhoneVerification;
      case OnboardingStep.profileSetup:
        return AppStrings.onboardingProfileSetup;
      case OnboardingStep.tutorial:
        return AppStrings.onboardingTutorial;
      case OnboardingStep.completed:
        return AppStrings.onboardingCompleted;
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

  double get progress => stepNumber / OnboardingStep.values.length;
}
