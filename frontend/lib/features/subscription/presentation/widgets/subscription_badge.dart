import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/subscription.dart';

/// Compact badge — **Notebook × Score 스타일 수강권 티켓 라벨**.
///
/// 티켓 스탬프 메타포: 사각형 1px 테두리 + IBM Plex Mono 카운트.
/// 긴급도 색 모델 (상태 우선순위 — 위에서 첫 일치):
/// 1. 입금대기: paperAccent + 경고 아이콘
/// 2. 만료: paperAccent + 경고 아이콘
/// 3. 임박: paperAccent + 시계 아이콘
/// 4. 정상: inkSecondary + 아이콘 없음
class SubscriptionBadge extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionBadge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();
    final icon = _stateIcon();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            _label(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// monthly 는 daysUntilExpiration 이 음수일 수 있어 status==expired 와 병합.
  bool get _isExpired =>
      subscription.status == SubscriptionStatus.expired ||
      (subscription.type == SubscriptionType.monthly &&
          (subscription.daysUntilExpiration ?? 0) <= 0);

  /// 긴급도 모델: 조치 필요(입금대기·만료·임박)=버밀리온, 정상=중립 잉크.
  Color _accentColor() {
    if (subscription.isUnpaid || _isExpired || subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    return AppColors.inkSecondary;
  }

  /// 색맹 안전: 조치 필요 상태에만 상태 아이콘. 정상은 아이콘 없음.
  IconData? _stateIcon() {
    if (subscription.isUnpaid || _isExpired) {
      return Icons.warning_amber_rounded;
    }
    if (subscription.isExpiringSoon) return Icons.access_time;
    return null;
  }

  /// Returns true when expiry is caused by session depletion (not date).
  bool get _isDepleted => subscription.isDepleted;

  String _label() {
    if (subscription.isUnpaid) return AppStrings.subscriptionBadgeUnpaid;

    // Expired: distinguish date-expiry from session depletion
    if (_isExpired) {
      if (_isDepleted) return AppStrings.statusDepleted; // 회차 소진
      return AppStrings.statusPeriodExpired; // 기간 만료
    }

    // Trial always shows its type label regardless of remaining count.
    if (subscription.type == SubscriptionType.trial) {
      return AppStrings.subscriptionTypeTrial;
    }

    // Expiring soon: show numeric context inline (package / monthly only).
    if (subscription.isExpiringSoon) {
      final remaining = subscription.remainingLessons;
      if (remaining != null && remaining <= 1) {
        return AppStrings.statusExpiringSoonSessions(
          remaining,
        ); // 소진 임박 · 잔여 N회
      }
      final days = subscription.daysUntilExpiration;
      if (days != null) {
        return AppStrings.statusExpiringSoonDays(days); // D-N
      }
    }

    switch (subscription.type) {
      case SubscriptionType.package:
        return AppStrings.subscriptionPackageBadgeFormat(
          subscription.remainingLessons ?? 0,
          subscription.totalLessonsForDisplay ?? 0,
        );
      case SubscriptionType.monthly:
        return AppStrings.subscriptionBadgeDday(
          subscription.daysUntilExpiration ?? 0,
        );
      case SubscriptionType.trial:
        return AppStrings.subscriptionTypeTrial;
    }
  }
}
