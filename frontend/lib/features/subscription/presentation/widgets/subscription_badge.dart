import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

  String _label() {
    if (subscription.isUnpaid) return AppStrings.subscriptionBadgeUnpaid;
    if (_isExpired) return AppStrings.statusExpired;
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

/// Mini progress indicator for subscription usage.
///
/// Notebook 스타일: ink 스트로크 + paperDark 배경 + Playfair 숫자.
class SubscriptionProgressMini extends StatelessWidget {
  final Subscription subscription;
  final double size;

  const SubscriptionProgressMini({
    super.key,
    required this.subscription,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.type != SubscriptionType.package) {
      return const SizedBox.shrink();
    }

    final percentage = subscription.usagePercentage ?? 0;
    final color =
        subscription.isExpiringSoon ? AppColors.paperAccent : AppColors.ink;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 2,
            backgroundColor: AppColors.inkQuaternary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${subscription.remainingLessons}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary text widget for subscription.
///
/// Notebook 스타일로 축약. 이모지 제거, IBM Plex Mono 카운트.
class SubscriptionSummaryText extends StatelessWidget {
  final Subscription subscription;
  final TextStyle? style;

  const SubscriptionSummaryText({
    super.key,
    required this.subscription,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        subscription.isExpiringSoon
            ? AppColors.paperAccent
            : AppColors.inkSecondary;

    final defaultStyle = AppTypography.bodySmall.copyWith(color: color);

    String text;
    if (subscription.type == SubscriptionType.package) {
      text = AppStrings.subscriptionPackageRemainingFormat(
        subscription.remainingLessons ?? 0,
        subscription.totalLessonsForDisplay ?? 0,
      );
    } else if (subscription.type == SubscriptionType.monthly) {
      final days = subscription.daysUntilExpiration ?? 0;
      text =
          days > 0
              ? AppStrings.subscriptionDaysRemaining(days)
              : AppStrings.statusExpired;
    } else {
      text = AppStrings.subscriptionTrialActive;
    }

    return Text(text, style: style ?? defaultStyle);
  }
}
