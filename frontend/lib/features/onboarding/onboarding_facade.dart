/// Onboarding facade — public entry point for onboarding application providers.
library;

export 'presentation/providers/teacher_profile_repository_provider.dart'
    show teacherProfileRepositoryProvider;
export 'presentation/providers/onboarding_providers.dart'
    show
        currentTeacherProfileProvider,
        currentTeacherProfileNotifierProvider,
        teacherOnboardingCompletedProvider,
        teacherOnboardingNotifierProvider;
export 'presentation/providers/onboarding_progress_storage_provider.dart'
    show OnboardingProgressStorageState, onboardingProgressStorageProvider;
// W6 마이그레이션 overlay 재사용 — ProfileTab 이 기존 가입자 첫 진입 시 띄움.
export 'presentation/providers/onboarding_category_shown_provider.dart'
    show OnboardingCategoryShown, onboardingCategoryShownProvider;
export 'presentation/screens/onboarding_category_preview_screen.dart'
    show OnboardingCategoryPreviewScreen;
// 퀘스트 unlock 축하 시트 — home 화면이 Q6 완료 시 호출.
export 'presentation/widgets/quest_unlock_celebration_sheet.dart'
    show showQuestUnlockCelebrationSheet;
// UXB-1 스타터 샘플 — 수강 관리 탭이 빈 상태 제안 + 정리 배너로 노출.
export 'domain/entities/starter_sample_data.dart' show StarterSampleData;
export 'presentation/providers/starter_sample_providers.dart'
    show
        StarterSampleOutcome,
        starterSampleCleanupVisibleProvider,
        starterSampleControllerProvider,
        starterSampleOfferVisibleProvider;
export 'presentation/providers/starter_sample_storage_provider.dart'
    show starterSampleStorageProvider;
export 'presentation/widgets/starter_sample_cleanup_banner.dart'
    show StarterSampleCleanupBanner;
export 'presentation/widgets/starter_sample_offer.dart' show StarterSampleOffer;
