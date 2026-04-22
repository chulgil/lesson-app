import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Compact badge — **Notebook × Score 스타일 수강권 티켓 라벨**.
///
/// 티켓 스탬프 메타포: 사각형 1px 테두리 + IBM Plex Mono 카운트.
/// - 정상: `ink` 테두리 + `inkSecondary` 텍스트
/// - 만료 임박: `paperAccent` (vermillion) 테두리/텍스트 — 4대 시그니처
/// - 만료: `inkTertiary` 점선 느낌 테두리 + 텍스트 (강한 경고 지양)
///
/// 8 callsite 일괄 적용.
class SubscriptionBadge extends StatelessWidget {
  final Subscription subscription;
  final bool showIcon;

  const SubscriptionBadge({
    super.key,
    required this.subscription,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getAccentColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_getIcon(), size: 11, color: color),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            _getLabel(),
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

  String _getLabel() {
    if (subscription.type == SubscriptionType.package) {
      return '${subscription.remainingLessons}/${subscription.totalLessonsForDisplay}회';
    } else if (subscription.type == SubscriptionType.monthly) {
      final days = subscription.daysUntilExpiration ?? 0;
      return days > 0 ? 'D-$days' : '만료';
    } else {
      return '체험';
    }
  }

  IconData _getIcon() {
    switch (subscription.type) {
      case SubscriptionType.trial:
        return Icons.star_outline;
      case SubscriptionType.monthly:
        return Icons.calendar_month_outlined;
      case SubscriptionType.package:
        return Icons.confirmation_number_outlined;
    }
  }

  /// 한 색상으로 배경·테두리·텍스트를 묶는다 (Notebook 원칙 — 세미 3색 이하).
  Color _getAccentColor() {
    if (subscription.status == SubscriptionStatus.expired) {
      return AppColors.inkTertiary;
    }
    if (subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    return AppColors.inkSecondary;
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
      text =
          '${subscription.remainingLessons}/${subscription.totalLessonsForDisplay}회 남음';
    } else if (subscription.type == SubscriptionType.monthly) {
      final days = subscription.daysUntilExpiration ?? 0;
      text = days > 0 ? 'D-$days 남음' : '만료';
    } else {
      text = '체험 중';
    }

    return Text(text, style: style ?? defaultStyle);
  }
}
