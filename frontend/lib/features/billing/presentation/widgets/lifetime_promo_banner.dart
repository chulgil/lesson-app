// #415 R4 Phase C2 — Lifetime 얼리어답터 프로모 배너.
//
// spec: docs/specs/subscription/paywall_spec.md §1, §6.2
//
// 노출 조건: snapshot.lifetimeOfferActive == true
//  - lifetimeOfferEndsAt 가 미래
//  - free 또는 trial 상태 (이미 유료 결제 사용자는 노출 안 함)
//
// 위치: 프로필 탭의 SubscriptionStatusCard 위 (inline).
// 백엔드 endpoint 가 lifetimeOfferEndsAt 를 채우기 시작하면 자동 노출.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Lifetime 얼리어답터 한정 1회 결제 프로모 배너.
class LifetimePromoBanner extends StatelessWidget {
  const LifetimePromoBanner({
    super.key,
    required this.endsAt,
    required this.onBuy,
    this.onDismiss,
    DateTime? now,
  }) : _nowOverride = now;

  static const buyButtonKey = Key('lifetime_promo_banner_buy');
  static const dismissButtonKey = Key('lifetime_promo_banner_dismiss');

  /// Lifetime 얼리어답터 오퍼 종료 시각.
  final DateTime endsAt;

  /// 구매하기 탭 콜백.
  final VoidCallback onBuy;

  /// 닫기(X) 콜백 — 호출 시 부모가 [lifetimePromoDismissedProvider] 를 갱신해
  /// banner 를 숨기는 책임을 진다. null 이면 X 버튼 미노출 (테스트/임시 사용).
  final VoidCallback? onDismiss;

  /// 테스트용 시계 주입. 운영 코드는 항상 [DateTime.now].
  final DateTime? _nowOverride;

  DateTime get _now => _nowOverride ?? DateTime.now();

  /// 만료까지 남은 일수. 음수면 0 으로 보정.
  int get _daysLeft {
    final diff = endsAt.difference(_now).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EyebrowChip(label: AppStrings.paywallLifetimePromoEyebrow),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.paywallLifetimePromoCountdown.replaceAll(
                    '{days}',
                    _daysLeft.toString(),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paper,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (onDismiss != null)
                  GestureDetector(
                    key: dismissButtonKey,
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      // 터치 면적 확보 — paperAccent 위 X 아이콘 단독은 작아서 padding 필수.
                      padding: EdgeInsets.all(AppSpacing.space1),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.paper,
                        semanticLabel:
                            AppStrings.paywallLifetimePromoDismissLabel,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            const Text(
              AppStrings.paywallLifetimePromoTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.paper,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            const Text(
              AppStrings.paywallLifetimePromoSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.paper,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: buyButtonKey,
                onPressed: onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paper,
                  foregroundColor: AppColors.paperAccent,
                  minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
                child: const Text(
                  AppStrings.paywallLifetimeBuyCta,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EyebrowChip extends StatelessWidget {
  const _EyebrowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.paperAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
