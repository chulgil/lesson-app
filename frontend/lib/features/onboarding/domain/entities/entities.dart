// Onboarding domain entities barrel file

export 'onboarding_step.dart';

// Re-export from profile domain for backwards compatibility
// Note: OnboardingStep enum is defined in teacher_onboarding.dart
export '../../../profile/domain/entities/teacher_onboarding.dart';
