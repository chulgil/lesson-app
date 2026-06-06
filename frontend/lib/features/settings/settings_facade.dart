/// Settings feature public boundary.
library;

export 'domain/entities/entities.dart'
    show
        AppNewsItem,
        AppReleaseSnapshot,
        AppRoadmapItem,
        AppRoadmapStatus,
        AppVersionSnapshot,
        ReviewPromptPolicy;
export 'domain/repositories/app_release_repository.dart'
    show AppReleaseRepository, AppReviewClient;
export 'presentation/providers/teacher_settings_provider.dart'
    show
        TeacherSettingsNotifier,
        teacherSettingsByIdProvider,
        teacherSettingsNotifierProvider,
        teacherSettingsProvider;
export 'presentation/providers/app_release_provider.dart'
    show
        appNewsFeedProvider,
        appReleaseRepositoryProvider,
        appReleaseSnapshotProvider,
        appRoadmapFeedProvider,
        appReviewClientProvider,
        appVersionSnapshotProvider,
        reviewPromptPolicyProvider,
        shouldPromptForReviewProvider;
export 'presentation/providers/orphan_recording_provider.dart'
    show allSectionsForAssignmentProvider;
export 'presentation/widgets/show_app_rating_prompt_helper.dart'
    show showAppRatingPromptIfNeeded;
