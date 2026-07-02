/// Notifications facade — public entry point for notification settings reads.
library;

export 'presentation/providers/notification_providers.dart'
    show
        connectionNotificationServiceProvider,
        notificationServiceProvider,
        notificationSchedulerServiceProvider,
        proposalNotificationServiceProvider,
        unreadNotificationCountProvider;
export 'domain/services/connection_notification_service.dart'
    show ConnectionInfo;
export 'presentation/providers/subscription_expiry_providers.dart'
    show subscriptionExpiryReminderSettingsNotifierProvider;
export 'presentation/widgets/context_switch_toast.dart' show ContextSwitchToast;
