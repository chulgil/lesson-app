// #1209 — Firebase Analytics adapter for [AnalyticsService].

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Sends events to Firebase Analytics (GA4).
///
/// Every failure is swallowed: a missing Firebase app, a rejected event name,
/// or a network error must never propagate into the calling business flow.
class FirebaseAnalyticsService extends AnalyticsService {
  const FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: analyticsWireParameters(parameters),
      );
    } catch (error) {
      // Instrumentation is best-effort. Surface it in debug builds only.
      if (kDebugMode) {
        debugPrint('[analytics] failed to log "$name": $error');
      }
    }
  }
}

/// Coerces event parameters into the scalar shape Firebase Analytics accepts.
///
/// Firebase only allows `String` and `num` values, so booleans are sent as
/// `'true'`/`'false'` and null-valued (omitted) attributes are dropped.
/// Returns null when nothing is left, which the SDK treats as "no parameters".
@visibleForTesting
Map<String, Object>? analyticsWireParameters(Map<String, Object?> parameters) {
  final wire = <String, Object>{};
  for (final entry in parameters.entries) {
    final value = entry.value;
    switch (value) {
      case null:
        continue;
      case final bool flag:
        wire[entry.key] = flag.toString();
      case final num number:
        wire[entry.key] = number;
      default:
        wire[entry.key] = value.toString();
    }
  }
  return wire.isEmpty ? null : wire;
}
