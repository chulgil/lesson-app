/// 스포트라이트 노출 조건 평가 — 스펙 §7.1.
///
/// 순수 함수. side-effect 0. 6 조건 모두 통과 시 [eligible]=true.
library;

/// 노출 조건 입력 컨텍스트.
class SpotlightEligibilityContext {
  /// 방금 종료된 연습 세션 길이.
  final Duration sessionDuration;

  /// 평가 시점.
  final DateTime now;

  /// 오늘 (KST 기준) 이미 노출된 prompt 수.
  final int promptsShownToday;

  /// 이번 주 (월요일 시작) 이미 노출된 prompt 수.
  final int promptsShownThisWeek;

  /// 학생이 14세 미만인지.
  final bool studentIsUnder14;

  /// 14세 미만 학생의 부모 동의 완료 여부 (P4 의존, P3 에서는 false 가정).
  final bool studentHasParentConsent;

  /// 큐에 promptable item 이 1개 이상 있는지 (Job 4 가 사전 평가).
  final bool queueHasPromptableItem;

  const SpotlightEligibilityContext({
    required this.sessionDuration,
    required this.now,
    required this.promptsShownToday,
    required this.promptsShownThisWeek,
    required this.studentIsUnder14,
    required this.studentHasParentConsent,
    required this.queueHasPromptableItem,
  });
}

/// 평가 결과 + 거절 사유 (분석/디버깅용).
class SpotlightEligibilityResult {
  final bool eligible;
  final String? reason;

  const SpotlightEligibilityResult.allow() : eligible = true, reason = null;
  const SpotlightEligibilityResult.deny(String r)
    : eligible = false,
      reason = r;
}

/// 스펙 §7.1 6 조건 평가.
class SpotlightEligibilityService {
  /// 세션 최소 길이 (§7.1).
  static const Duration minSessionDuration = Duration(minutes: 5);

  /// 오늘 최대 노출 수 (§7.1 "오늘 첫 prompt").
  static const int dailyCap = 1;

  /// 주간 최대 노출 수 (§7.1).
  static const int weeklyCap = 2;

  const SpotlightEligibilityService();

  /// 6 조건 순서대로 평가 (단조 단축):
  /// 1. 세션 ≥ 5분
  /// 2. 오늘 첫 prompt
  /// 3. 주간 ≤ 2
  /// 4. 큐 promptable 보유
  /// 5. 14세 미만 + 부모 동의 X → deny
  /// 6. 모두 통과 → allow
  SpotlightEligibilityResult evaluate(SpotlightEligibilityContext ctx) {
    if (ctx.sessionDuration < minSessionDuration) {
      return const SpotlightEligibilityResult.deny('session_too_short');
    }
    if (ctx.promptsShownToday >= dailyCap) {
      return const SpotlightEligibilityResult.deny('daily_cap_hit');
    }
    if (ctx.promptsShownThisWeek >= weeklyCap) {
      return const SpotlightEligibilityResult.deny('weekly_cap_hit');
    }
    if (!ctx.queueHasPromptableItem) {
      return const SpotlightEligibilityResult.deny('queue_empty');
    }
    if (ctx.studentIsUnder14 && !ctx.studentHasParentConsent) {
      return const SpotlightEligibilityResult.deny('parent_consent_required');
    }
    return const SpotlightEligibilityResult.allow();
  }
}
