import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/services/spotlight_eligibility_service.dart';

void main() {
  final now = DateTime.utc(2026, 6, 12, 9);

  SpotlightEligibilityContext make({
    Duration sessionDuration = const Duration(minutes: 10),
    int promptsShownToday = 0,
    int promptsShownThisWeek = 0,
    bool studentIsUnder14 = false,
    bool studentHasParentConsent = false,
    bool queueHasPromptableItem = true,
  }) => SpotlightEligibilityContext(
    sessionDuration: sessionDuration,
    now: now,
    promptsShownToday: promptsShownToday,
    promptsShownThisWeek: promptsShownThisWeek,
    studentIsUnder14: studentIsUnder14,
    studentHasParentConsent: studentHasParentConsent,
    queueHasPromptableItem: queueHasPromptableItem,
  );

  const svc = SpotlightEligibilityService();

  group('§7.1 노출 조건', () {
    test('happy path — 14세 이상 + 모든 조건 통과 → allow', () {
      final r = svc.evaluate(make());
      expect(r.eligible, isTrue);
      expect(r.reason, isNull);
    });

    test('세션 < 5분 → session_too_short', () {
      final r = svc.evaluate(make(sessionDuration: const Duration(minutes: 4)));
      expect(r.eligible, isFalse);
      expect(r.reason, 'session_too_short');
    });

    test('세션 정확히 5분 → 통과 (경계 inclusive)', () {
      final r = svc.evaluate(make(sessionDuration: const Duration(minutes: 5)));
      expect(r.eligible, isTrue);
    });

    test('오늘 이미 1회 노출 → daily_cap_hit', () {
      final r = svc.evaluate(make(promptsShownToday: 1));
      expect(r.eligible, isFalse);
      expect(r.reason, 'daily_cap_hit');
    });

    test('주간 2회 도달 → weekly_cap_hit', () {
      final r = svc.evaluate(make(promptsShownThisWeek: 2));
      expect(r.eligible, isFalse);
      expect(r.reason, 'weekly_cap_hit');
    });

    test('주간 1회 + 오늘 0회 → allow', () {
      final r = svc.evaluate(make(promptsShownThisWeek: 1));
      expect(r.eligible, isTrue);
    });

    test('큐 비어있음 → queue_empty', () {
      final r = svc.evaluate(make(queueHasPromptableItem: false));
      expect(r.eligible, isFalse);
      expect(r.reason, 'queue_empty');
    });

    test('14세 미만 + 부모 동의 X → parent_consent_required', () {
      final r = svc.evaluate(
        make(studentIsUnder14: true, studentHasParentConsent: false),
      );
      expect(r.eligible, isFalse);
      expect(r.reason, 'parent_consent_required');
    });

    test('14세 미만 + 부모 동의 O → allow (P4 의존 흐름)', () {
      final r = svc.evaluate(
        make(studentIsUnder14: true, studentHasParentConsent: true),
      );
      expect(r.eligible, isTrue);
    });

    test('14세 이상은 부모 동의 무관 → allow', () {
      final r = svc.evaluate(
        make(studentIsUnder14: false, studentHasParentConsent: false),
      );
      expect(r.eligible, isTrue);
    });
  });

  group('단조 단축 (순서 보장)', () {
    test('세션 < 5분 + 주간 cap → session_too_short 우선 (먼저 평가)', () {
      final r = svc.evaluate(
        make(
          sessionDuration: const Duration(minutes: 4),
          promptsShownThisWeek: 5,
        ),
      );
      expect(r.reason, 'session_too_short');
    });

    test('daily cap + queue empty → daily 우선', () {
      final r = svc.evaluate(
        make(promptsShownToday: 1, queueHasPromptableItem: false),
      );
      expect(r.reason, 'daily_cap_hit');
    });
  });

  group('상수 노출', () {
    test('minSessionDuration = 5분', () {
      expect(
        SpotlightEligibilityService.minSessionDuration,
        const Duration(minutes: 5),
      );
    });

    test('dailyCap = 1, weeklyCap = 2', () {
      expect(SpotlightEligibilityService.dailyCap, 1);
      expect(SpotlightEligibilityService.weeklyCap, 2);
    });
  });
}
