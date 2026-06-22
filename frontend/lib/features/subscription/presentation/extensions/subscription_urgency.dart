import '../../domain/entities/subscription.dart';

/// 수강권 배지의 긴급도 상태 — 우선순위 순서(낮을수록 긴급).
///
/// 미수금 > 만료 > 임박 > 정상. enum 선언 순서가 곧 우선순위라
/// `SubscriptionUrgency.index` 를 정렬 키로 쓸 수 있다.
enum SubscriptionUrgency { unpaid, expired, expiringSoon, normal }

/// 배지/정렬이 공유하는 단일 긴급도 모델 (presentation SSOT).
///
/// 이전에는 `SubscriptionBadge._isExpired` 와 `StudentSubscriptionMiniBadge.
/// _urgencyRank` 가 같은 규칙(특히 monthly 만료 병합)을 각자 재구현하고 주석으로
/// 동기화를 유지했다. 그 drift 위험을 없애기 위해 한 곳에서 분류한다.
extension SubscriptionUrgencyX on Subscription {
  SubscriptionUrgency get badgeUrgency {
    if (isUnpaid) return SubscriptionUrgency.unpaid;
    if (isBadgeExpired) return SubscriptionUrgency.expired;
    if (isExpiringSoon) return SubscriptionUrgency.expiringSoon;
    return SubscriptionUrgency.normal;
  }

  /// 배지 표시용 만료 판정 — monthly 는 daysUntilExpiration 이 음수일 수 있어
  /// status==expired 와 병합한다(엔티티 `isExpired` 의 endDate 기준과 별개의
  /// 표시 규칙). 정상/임박과 구분되는 "조치 필요" 상태.
  bool get isBadgeExpired =>
      status == SubscriptionStatus.expired ||
      (type == SubscriptionType.monthly && (daysUntilExpiration ?? 0) <= 0);
}
