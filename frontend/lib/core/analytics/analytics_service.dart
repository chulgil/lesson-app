// #1209 — monetization funnel instrumentation.
//
// Event schema SSOT for the funnel the pricing plan measures:
//   paywall_limit_reached -> trial_started -> subscription_upgraded
//
// Instrumentation must never affect the user flow. Every implementation
// swallows its own failures, and platforms where Firebase is not configured
// (web, unit tests) degrade to [NoopAnalyticsService].

/// Canonical analytics event names.
///
/// These strings are the wire contract shared with the analytics spec
/// (`docs/specs/analytics/`) and the GA4 console — never rename in place.
abstract final class AnalyticsEvents {
  /// Free-plan student limit blocked the action and the paywall sheet opened.
  static const String paywallLimitReached = 'paywall_limit_reached';

  /// 14-day trial activation succeeded.
  static const String trialStarted = 'trial_started';

  /// IAP purchase + receipt verification succeeded.
  static const String subscriptionUpgraded = 'subscription_upgraded';

  /// App cold start finished bootstrapping.
  static const String appOpened = 'app_opened';

  /// A student record was created.
  static const String studentAdded = 'student_added';
}

/// Canonical analytics parameter names.
abstract final class AnalyticsParams {
  static const String plan = 'plan';
  static const String studentCount = 'student_count';
  static const String fromTrial = 'from_trial';
  static const String role = 'role';
  static const String method = 'method';
}

/// Product analytics port.
///
/// Callers should treat every method as fire-and-forget: the returned future
/// always completes normally, so a failed log can never surface as an error to
/// the user. Call sites belong in presentation or bootstrap code only —
/// domain/data layers stay free of instrumentation (layer boundary contract).
abstract class AnalyticsService {
  const AnalyticsService();

  /// Logs a raw event. Values must be scalars; adapters coerce them for the
  /// backend and drop nulls.
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  });

  /// Funnel step 1 — the free-plan guard blocked the action and showed the
  /// paywall. [plan] is the plan in effect at that moment.
  Future<void> logPaywallLimitReached({
    required String plan,
    required int studentCount,
  }) {
    return logEvent(
      AnalyticsEvents.paywallLimitReached,
      parameters: {
        AnalyticsParams.plan: plan,
        AnalyticsParams.studentCount: studentCount,
      },
    );
  }

  /// Funnel step 2 — trial activation succeeded. [plan] is the resulting plan.
  Future<void> logTrialStarted({required String plan}) {
    return logEvent(
      AnalyticsEvents.trialStarted,
      parameters: {AnalyticsParams.plan: plan},
    );
  }

  /// Funnel step 3 — a paid plan was granted. [fromTrial] distinguishes a
  /// trial-to-paid conversion from a direct purchase.
  Future<void> logSubscriptionUpgraded({
    required String plan,
    required bool fromTrial,
  }) {
    return logEvent(
      AnalyticsEvents.subscriptionUpgraded,
      parameters: {
        AnalyticsParams.plan: plan,
        AnalyticsParams.fromTrial: fromTrial,
      },
    );
  }

  /// App cold start. [role] is omitted when it is not yet known at boot.
  Future<void> logAppOpened({String? role}) {
    return logEvent(
      AnalyticsEvents.appOpened,
      parameters: {AnalyticsParams.role: role},
    );
  }

  /// A student was created. [method] is omitted when the entry point is not
  /// distinguishable at the call site.
  Future<void> logStudentAdded({String? method}) {
    return logEvent(
      AnalyticsEvents.studentAdded,
      parameters: {AnalyticsParams.method: method},
    );
  }
}

/// Analytics sink that drops every event.
///
/// Used on platforms without Firebase configuration (web QA builds, unit
/// tests) so instrumentation call sites stay unconditional.
class NoopAnalyticsService extends AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}
}
