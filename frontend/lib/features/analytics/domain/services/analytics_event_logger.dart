import 'package:flutter/foundation.dart';

/// Metric event names — docs/specs/user/phone_verification_policy.md §5.5.
///
/// #695 E3 gate / proposal-draft funnel instrumentation. The five events
/// below measure verification completion rate and draft recovery rate.
abstract final class AnalyticsEvents {
  /// E3 gate modal shown (수강권 발급 직전 게이트 노출).
  static const phoneVerificationGateShown =
      'auth.phone_verification_gate_shown';

  /// Phone verification completed (trigger: quest/gate).
  static const phoneVerificationCompleted = 'auth.phone_verification_completed';

  /// "나중에" selected on the E3 gate (draftSaved: bool).
  static const gateLaterSelected = 'subscription.gate_later_selected';

  /// Draft recovery banner "이어서 발급하기" tapped (draftAgeDays: int).
  static const draftRecovered = 'subscription.draft_recovered';

  /// Draft auto-discarded after the 7-day TTL.
  static const draftExpired = 'subscription.draft_expired';
}

/// Lightweight analytics event logger.
///
/// 비유: 가게 문 앞의 계수기 — 손님이 몇 명 들어오고 나가는지 똑딱똑딱 센다.
/// 현재는 로컬 디버그 로그 sink 만 존재하며, 원격 수집기(예: BE collector)가
/// 생기면 [log] 내부 구현만 교체하면 된다. 호출부 시그니처는 불변.
class AnalyticsEventLogger {
  const AnalyticsEventLogger();

  /// Record a single event with its payload.
  void log(String event, Map<String, Object?> properties) {
    // Local sink: debug log only. Replace with a remote sink when the
    // collection endpoint lands (tracked separately from #695).
    debugPrint('[analytics] $event $properties');
  }
}
