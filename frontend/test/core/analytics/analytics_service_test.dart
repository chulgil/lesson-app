import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/analytics/analytics_provider.dart';
import 'package:lessonaza/core/analytics/analytics_service.dart';
import 'package:lessonaza/core/analytics/firebase_analytics_service.dart';

/// Records every event a call site emits so tests can assert the wire schema.
class RecordingAnalyticsService extends AnalyticsService {
  final List<({String name, Map<String, Object?> parameters})> events = [];

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    events.add((name: name, parameters: parameters));
  }
}

void main() {
  group('AnalyticsService typed events', () {
    late RecordingAnalyticsService analytics;

    setUp(() => analytics = RecordingAnalyticsService());

    test('logPaywallLimitReached forwards plan and student_count', () async {
      await analytics.logPaywallLimitReached(plan: 'free', studentCount: 5);

      expect(analytics.events, hasLength(1));
      expect(analytics.events.single.name, 'paywall_limit_reached');
      expect(analytics.events.single.parameters, {
        'plan': 'free',
        'student_count': 5,
      });
    });

    test('logTrialStarted forwards the resulting plan', () async {
      await analytics.logTrialStarted(plan: 'pro');

      expect(analytics.events.single.name, 'trial_started');
      expect(analytics.events.single.parameters, {'plan': 'pro'});
    });

    test('logSubscriptionUpgraded forwards plan and from_trial', () async {
      await analytics.logSubscriptionUpgraded(plan: 'pro', fromTrial: true);

      expect(analytics.events.single.name, 'subscription_upgraded');
      expect(analytics.events.single.parameters, {
        'plan': 'pro',
        'from_trial': true,
      });
    });

    test('logAppOpened omits an unknown role', () async {
      await analytics.logAppOpened();

      expect(analytics.events.single.name, 'app_opened');
      expect(analytics.events.single.parameters, {'role': null});
    });

    test('logStudentAdded omits an unknown method', () async {
      await analytics.logStudentAdded();

      expect(analytics.events.single.name, 'student_added');
      expect(analytics.events.single.parameters, {'method': null});
    });
  });

  group('analyticsWireParameters', () {
    test('coerces bool to string and keeps num as-is', () {
      final wire = analyticsWireParameters({
        'from_trial': true,
        'student_count': 5,
        'plan': 'pro',
      });

      expect(wire, {'from_trial': 'true', 'student_count': 5, 'plan': 'pro'});
    });

    test('drops null values so omitted attributes are not sent', () {
      expect(analyticsWireParameters({'role': null, 'plan': 'free'}), {
        'plan': 'free',
      });
    });

    test('returns null when every value is omitted', () {
      expect(analyticsWireParameters({'role': null}), isNull);
      expect(analyticsWireParameters(const {}), isNull);
    });
  });

  group('no-op safety', () {
    test('NoopAnalyticsService swallows every event', () async {
      const analytics = NoopAnalyticsService();

      await expectLater(
        analytics.logPaywallLimitReached(plan: 'free', studentCount: 5),
        completes,
      );
      await expectLater(analytics.logEvent('anything'), completes);
    });

    test(
      'createAnalyticsService degrades to no-op when Firebase is unavailable',
      () async {
        // No Firebase app is initialized in unit tests, so the factory must
        // fall back instead of throwing at the call site.
        final analytics = createAnalyticsService();

        expect(analytics, isA<NoopAnalyticsService>());
        await expectLater(analytics.logAppOpened(role: 'teacher'), completes);
      },
    );

    test('analytics singleton never throws and is overridable', () async {
      final fake = RecordingAnalyticsService();
      debugSetAnalyticsService(fake);
      addTearDown(() => debugSetAnalyticsService(null));

      await expectLater(analytics.logAppOpened(), completes);
      expect(fake.events.single.name, 'app_opened');
    });
  });
}
