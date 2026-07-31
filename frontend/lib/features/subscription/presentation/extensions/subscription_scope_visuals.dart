import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription.dart';
import 'subscription_visuals.dart';

/// Display rules for a subscription's lesson-format scope (spec §4).
///
/// Single source of the two-branch rule so that no surface re-derives it:
///   groupClassId 有            -> 그룹 클래스명
///   groupClassId 無 + group    -> "그룹 수강권"
///   그 외                      -> 멤버십 수업명(폴백 포함)
///
/// A group ticket never falls back to the 1:1 class name — that fallback is
/// what made group subscriptions read as "개인레슨" on the parent payment tab.
extension SubscriptionScopeVisualX on Subscription {
  /// Class name to print on a subscription card.
  ///
  /// [groupClassName] is the resolved name of [Subscription.groupClassId] when
  /// the caller has it; group tickets degrade to the group label instead of the
  /// membership name when it is missing.
  String displayClassName({
    String? groupClassName,
    String? membershipClassName,
    required String fallback,
  }) {
    if (isGroupScoped) return _groupLabel(groupClassName);
    return membershipClassName ?? fallback;
  }

  /// Subscription kind shown on expiry-soon cards and alerts, so the reader
  /// knows *which* ticket is running out (P1-5).
  String expiryKindLabel({String? groupClassName}) {
    if (isGroupScoped) return _groupLabel(groupClassName);
    return typeLabel;
  }

  String _groupLabel(String? groupClassName) {
    final name = groupClassName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return AppStrings.subscriptionGroupTicketLabel;
  }
}
