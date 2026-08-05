// #1209 — analytics composition root.
//
// Owns the platform decision (Firebase vs no-op) in one place so call sites
// stay unconditional, and exposes it both as a Riverpod provider (UI code) and
// as a process-wide singleton (bootstrap, which runs before ProviderScope).

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'analytics_service.dart';
import 'firebase_analytics_service.dart';

part 'analytics_provider.g.dart';

AnalyticsService? _instance;

/// Process-wide analytics sink for call sites without a [Ref] (app bootstrap).
///
/// Prefer [analyticsServiceProvider] anywhere a [Ref]/[WidgetRef] is available.
AnalyticsService get analytics => _instance ??= createAnalyticsService();

/// Builds the analytics sink for the current platform.
///
/// Firebase is native-only here: `firebase_options.dart` has no web options
/// (bootstrap skips `Firebase.initializeApp` on web), and unit tests never
/// initialize a Firebase app. Both cases degrade to [NoopAnalyticsService]
/// rather than throwing.
AnalyticsService createAnalyticsService() {
  if (kIsWeb) return const NoopAnalyticsService();
  try {
    return FirebaseAnalyticsService(FirebaseAnalytics.instance);
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[analytics] Firebase unavailable, using no-op sink: $error');
    }
    return const NoopAnalyticsService();
  }
}

/// Replaces the [analytics] singleton. Pass null to restore the default.
@visibleForTesting
void debugSetAnalyticsService(AnalyticsService? service) {
  _instance = service;
}

/// Analytics sink for UI call sites. Override in tests with a fake.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) => analytics;
