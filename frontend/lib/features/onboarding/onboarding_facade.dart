/// Onboarding facade — public entry point for onboarding application providers.
library;

export 'presentation/providers/teacher_profile_repository_provider.dart'
    show teacherProfileRepositoryProvider;
export 'presentation/providers/onboarding_providers.dart'
    show
        currentTeacherProfileProvider,
        teacherOnboardingCompletedProvider,
        teacherOnboardingNotifierProvider;
export 'presentation/providers/onboarding_progress_storage_provider.dart'
    show OnboardingProgressStorageState, onboardingProgressStorageProvider;
export 'presentation/widgets/first_availability_interstitial.dart'
    show showFirstAvailabilityInterstitial;
