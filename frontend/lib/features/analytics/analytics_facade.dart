// Analytics feature public entry point.
// Cross-feature code must import from here — never directly from presentation/providers.
library;

export 'domain/services/analytics_event_logger.dart'
    show AnalyticsEventLogger, AnalyticsEvents;
export 'presentation/providers/analytics_event_logger_provider.dart'
    show analyticsEventLoggerProvider;
