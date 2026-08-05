import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/subscription_urgency.dart';

/// Compact badge — **Notebook × Score 스타일 수강권 티켓 라벨**.
///
/// 티켓 스탬프 메타포: 사각형 1px 테두리 + IBM Plex Mono 카운트.
/// 긴급도 색 모델 (상태 우선순위 — 위에서 첫 일치):
/// 1. 미수금: paperAccent + 경고 아이콘
/// 2. 만료: paperAccent + 경고 아이콘
/// 3. 임박: paperAccent + 시계 아이콘
/// 4. 정상: inkSecondary + 아이콘 없음
class SubscriptionBadge extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionBadge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return _BadgeFrame(
      color: _accentColor(),
      icon: _stateIcon(),
      label: _label(),
    );
  }

  /// 배지 표시용 만료 — 공유 긴급도 모델(SSOT) 위임.
  bool get _isExpired =>
      subscription.badgeUrgency == SubscriptionUrgency.expired;

  /// 긴급도 모델: 조치 필요(미수금·만료·임박)=버밀리온, 정상=중립 잉크.
  Color _accentColor() {
    return subscription.badgeUrgency == SubscriptionUrgency.normal
        ? AppColors.inkSecondary
        : AppColors.paperAccent;
  }

  /// 색맹 안전: 조치 필요 상태에만 상태 아이콘. 정상은 아이콘 없음.
  IconData? _stateIcon() {
    switch (subscription.badgeUrgency) {
      case SubscriptionUrgency.unpaid:
      case SubscriptionUrgency.expired:
        return Icons.warning_amber_rounded;
      case SubscriptionUrgency.expiringSoon:
        return Icons.access_time;
      case SubscriptionUrgency.normal:
        return null;
    }
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

/// 그룹 수강권 표식 — 긴급도 배지와 **같은 티켓 스탬프 프레임**을 공유한다.
/// 새 배지 언어를 만들지 않기 위해 [_BadgeFrame] 을 재사용하고 색은 시맨틱 토큰만 쓴다.
class GroupSubscriptionBadge extends StatelessWidget {
  const GroupSubscriptionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BadgeFrame(
      color: AppColors.inkSecondary,
      icon: Icons.groups_outlined,
      label: AppStrings.subscriptionGroupBadge,
    );
  }
}

/// 수강권 배지 공통 프레임: 1px 사각 테두리 + IBM Plex Mono 라벨.
class _BadgeFrame extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;

  const _BadgeFrame({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
          // Flexible+ellipsis: compact 배지는 좁은 컨테이너(home 카드 info 칼럼,
          // students 탭 56px)에 놓여 라벨이 폭을 넘을 수 있다. bounded 폭을 받으면
          // 축약, 넉넉하면 자연폭(#853). 모든 사용처가 bounded 폭이라 flex assert 없음.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
