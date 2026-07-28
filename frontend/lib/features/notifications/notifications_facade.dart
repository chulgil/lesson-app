/// Notifications facade — public entry point for notification settings reads.
library;

export 'presentation/providers/notification_providers.dart'
    show
        connectionNotificationServiceProvider,
        notificationServiceProvider,
        notificationSchedulerServiceProvider,
        practiceReminderSchedulerProvider,
        proposalNotificationServiceProvider,
        unreadNotificationCountProvider;
export 'domain/services/connection_notification_service.dart'
    show ConnectionInfo;
export 'domain/services/practice_reminder_scheduler.dart'
    show PracticeReminderScheduler;
export 'presentation/providers/subscription_expiry_providers.dart'
    show subscriptionExpiryReminderSettingsNotifierProvider;
export 'presentation/providers/push_registration_provider.dart'
    show
        pushRegistrationProvider,
        pushInitializerProvider,
        pushUnregistrarProvider;
export 'presentation/widgets/context_switch_toast.dart' show ContextSwitchToast;
