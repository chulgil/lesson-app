// Onboarding domain entities barrel file

// Re-export from profile domain for backwards compatibility
// Note: OnboardingStep enum is defined in teacher_onboarding.dart
export 'onboarding_progress.dart';
export '../../../profile/domain/entities/teacher_onboarding.dart';
