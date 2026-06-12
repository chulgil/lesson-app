import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/rest_recommendation_policy.dart';

void main() {
  group('RestRecommendationPolicy — Job 8 Task 8.1 / AC-7', () {
    final today = DateTime.utc(2026, 6, 12);

    group('14세 이상 (성인 임계값)', () {
      test('세션 < 30분 → 트리거 없음', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 29,
          dailyCumulativeMinutes: 0,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isFalse);
        expect(result.kind, RestRecommendationKind.none);
      });

      test('세션 = 30분 → 세션 토스트 트리거 (AC-7.1)', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 30,
          dailyCumulativeMinutes: 30,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
        expect(result.kind, RestRecommendationKind.session30);
      });

      test('세션 = 31분 → 세션 토스트 트리거', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 31,
          dailyCumulativeMinutes: 31,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
      });

      test('같은 세션 토스트 노출 후 재호출 → no-op (1회 보장)', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 35,
          dailyCumulativeMinutes: 35,
          isUnder14: false,
          sessionToastShownAt: today,
          lastDailyToastDate: null,
          now: today,
        );
        expect(
          result.shouldShow,
          isFalse,
          reason: 'sessionToastShownAt != null → 이미 노출',
        );
      });

      test('일일 누적 3시간 (180분) → 차분 종료 권유 (AC-7.2)', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 10,
          dailyCumulativeMinutes: 180,
          isUnder14: false,
          sessionToastShownAt: today,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
        expect(result.kind, RestRecommendationKind.daily180);
      });

      test('일일 토스트 같은 날 재진입 → 무노출', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 10,
          dailyCumulativeMinutes: 200,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: today,
          now: today,
        );
        expect(
          result.shouldShow,
          isFalse,
          reason: '같은 날 lastDailyToastDate 영속',
        );
      });

      test('일일 토스트 다음날 재진입 → 다시 노출 가능', () {
        final tomorrow = today.add(const Duration(days: 1));
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 10,
          dailyCumulativeMinutes: 200,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: today,
          now: tomorrow,
        );
        expect(result.shouldShow, isTrue);
        expect(result.kind, RestRecommendationKind.daily180);
      });
    });

    group('14세 미만 (강화된 임계값) — AC-7.3', () {
      test('세션 < 15분 → 트리거 없음', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 14,
          dailyCumulativeMinutes: 14,
          isUnder14: true,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isFalse);
      });

      test('세션 = 15분 → 세션 토스트 트리거 (강화)', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 15,
          dailyCumulativeMinutes: 15,
          isUnder14: true,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
        expect(
          result.kind,
          RestRecommendationKind.session30,
          reason: '14세 미만 = 동일 종류, 임계값만 다름',
        );
      });

      test('14세 미만 = 25분 (성인 임계값 미달) 도 트리거', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 25,
          dailyCumulativeMinutes: 25,
          isUnder14: true,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
      });
    });

    group('우선순위 — 세션 vs 일일', () {
      test('두 조건 동시 충족 + 둘 다 미노출 → 세션 우선', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 60,
          dailyCumulativeMinutes: 200,
          isUnder14: false,
          sessionToastShownAt: null,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
        expect(
          result.kind,
          RestRecommendationKind.session30,
          reason: '세션 토스트 우선 (즉시성)',
        );
      });

      test('세션 노출 + 일일 미노출 → 일일 노출', () {
        final result = RestRecommendationPolicy.evaluate(
          sessionMinutes: 60,
          dailyCumulativeMinutes: 200,
          isUnder14: false,
          sessionToastShownAt: today,
          lastDailyToastDate: null,
          now: today,
        );
        expect(result.shouldShow, isTrue);
        expect(result.kind, RestRecommendationKind.daily180);
      });
    });

    group('임계값 상수 노출 (외부 wiring)', () {
      test('성인 세션 임계값 = 30분', () {
        expect(RestRecommendationPolicy.sessionThresholdAdult, 30);
      });

      test('14세 미만 세션 임계값 = 15분', () {
        expect(RestRecommendationPolicy.sessionThresholdUnder14, 15);
      });

      test('일일 누적 임계값 = 180분 (3시간)', () {
        expect(RestRecommendationPolicy.dailyThreshold, 180);
      });
    });
  });
}
