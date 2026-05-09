import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // 사용자 식별
  Future<void> setUserId(String userId) =>
      _analytics.setUserId(id: userId);

  Future<void> setUserRole(String role) =>
      _analytics.setUserProperty(name: 'user_role', value: role);

  // 핵심 이벤트 10개
  Future<void> logOnboardingCompleted({required int step, required int durationSec}) =>
      _analytics.logEvent(name: 'onboarding_completed', parameters: {
        'step': step,
        'duration_sec': durationSec,
      });

  Future<void> logStudentAdded({required bool isDemo, required String method}) =>
      _analytics.logEvent(name: 'student_added', parameters: {
        'is_demo': isDemo,
        'method': method,
      });

  Future<void> logLessonCompleted({required int duration, required bool hasNote}) =>
      _analytics.logEvent(name: 'lesson_completed', parameters: {
        'duration': duration,
        'has_note': hasNote,
      });

  Future<void> logPracticeStarted({required String tool}) =>
      _analytics.logEvent(name: 'practice_started', parameters: {
        'tool': tool,
      });

  Future<void> logSubscriptionUpgraded({required String plan, required bool trial}) =>
      _analytics.logEvent(name: 'subscription_upgraded', parameters: {
        'plan': plan,
        'trial': trial,
      });

  Future<void> logInviteShared({required String channel}) =>
      _analytics.logEvent(name: 'invite_shared', parameters: {
        'channel': channel,
      });

  Future<void> logFeatureUsed({required String name}) =>
      _analytics.logEvent(name: 'feature_used', parameters: {
        'name': name,
      });

  Future<void> logAppOpened({required int sessionCount}) =>
      _analytics.logEvent(name: 'app_opened', parameters: {
        'session_count': sessionCount,
      });

  Future<void> logReviewPrompted({required String result}) =>
      _analytics.logEvent(name: 'review_prompted', parameters: {
        'result': result,
      });

  Future<void> logChurnRisk({required int daysInactive, required String lastAction}) =>
      _analytics.logEvent(name: 'churn_risk', parameters: {
        'days_inactive': daysInactive,
        'last_action': lastAction,
      });
}

// Riverpod provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
