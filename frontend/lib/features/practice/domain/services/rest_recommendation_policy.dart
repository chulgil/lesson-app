/// 휴식 권고 종류.
///
/// 스펙 §9.4 / 플랜 Job 8 / AC-7.
enum RestRecommendationKind {
  none,

  /// 단일 세션 임계값 도달 (성인 30분 / 14세 미만 15분).
  session30,

  /// 일일 누적 3시간 도달.
  daily180,
}

/// 휴식 권고 평가 결과.
class RestRecommendationResult {
  final bool shouldShow;
  final RestRecommendationKind kind;

  const RestRecommendationResult({
    required this.shouldShow,
    required this.kind,
  });

  static const none = RestRecommendationResult(
    shouldShow: false,
    kind: RestRecommendationKind.none,
  );
}

/// 휴식 권고 정책 — 순수 함수, side-effect 0.
///
/// 스펙 §9.4 / 플랜 Job 8 Task 8.1 / AC-7.
/// - 세션 30분 도달 (14세 미만 15분) → "잠깐 쉬는 게 어때요?" 1회
/// - 일일 누적 3시간 도달 → 차분 종료 권유 1회
/// - 우선순위: 세션 우선 (즉시성)
/// - 같은 세션 / 같은 날 재호출 → no-op (1회 보장)
class RestRecommendationPolicy {
  RestRecommendationPolicy._();

  static const int sessionThresholdAdult = 30;
  static const int sessionThresholdUnder14 = 15;
  static const int dailyThreshold = 180; // 3시간

  /// [sessionMinutes] / [dailyCumulativeMinutes] 기준으로 권고 평가.
  ///
  /// [sessionToastShownAt] != null → 같은 세션에서 이미 노출 (1회 보장).
  /// [lastDailyToastDate] 가 [now] 와 같은 calendar day → 일일 토스트 노출 0.
  static RestRecommendationResult evaluate({
    required int sessionMinutes,
    required int dailyCumulativeMinutes,
    required bool isUnder14,
    required DateTime? sessionToastShownAt,
    required DateTime? lastDailyToastDate,
    required DateTime now,
  }) {
    // 1. 세션 토스트 (우선) — 미노출 + 임계값 도달
    final sessionThreshold =
        isUnder14 ? sessionThresholdUnder14 : sessionThresholdAdult;
    if (sessionToastShownAt == null && sessionMinutes >= sessionThreshold) {
      return const RestRecommendationResult(
        shouldShow: true,
        kind: RestRecommendationKind.session30,
      );
    }

    // 2. 일일 토스트 — 같은 날 미노출 + 임계값 도달
    final sameDay =
        lastDailyToastDate != null && _isSameDay(lastDailyToastDate, now);
    if (!sameDay && dailyCumulativeMinutes >= dailyThreshold) {
      return const RestRecommendationResult(
        shouldShow: true,
        kind: RestRecommendationKind.daily180,
      );
    }

    return RestRecommendationResult.none;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
