import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/analytics_event_logger.dart';

part 'analytics_event_logger_provider.g.dart';

/// App-wide analytics event logger (#695 §5.5 metric events).
@Riverpod(keepAlive: true)
AnalyticsEventLogger analyticsEventLogger(AnalyticsEventLoggerRef ref) =>
    const AnalyticsEventLogger();
