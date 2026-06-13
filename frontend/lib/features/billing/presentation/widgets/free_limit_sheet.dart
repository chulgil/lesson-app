// #415 R4 Phase B — Paywall bottom sheet.
//
// spec: docs/specs/subscription/paywall_spec.md §6.1
// Phase B 는 IAP 미연결: Pro 구매/체험 시작 버튼은 SnackBar 안내만.
// Phase C 에서 onBuyPro / onStartTrial 콜백을 실제 IAP 흐름에 연결.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../domain/services/billing_guard.dart';

/// Free 한도 도달 / 플랜 만료 시 노출되는 Paywall sheet.
///
/// [reason] 이 [LimitReason.withinLimit] 이면 정의상 노출되지 않는다 (호출 측 가드).
class FreeLimitSheet extends StatelessWidget {
  const FreeLimitSheet({
    super.key,
    required this.reason,
    required this.trialAvailable,
    required this.onBuyPro,
    required this.onStartTrial,
    required this.onLater,
  });

  static const buyProButtonKey = Key('free_limit_sheet_buy_pro');
  static const startTrialButtonKey = Key('free_limit_sheet_start_trial');
  static const laterButtonKey = Key('free_limit_sheet_later');

  final LimitReason reason;
  final bool trialAvailable;
  final VoidCallback onBuyPro;
  final VoidCallback onStartTrial;
  final VoidCallback onLater;

  bool get _isExpired => reason == LimitReason.planExpired;

  String get _title => _isExpired
      ? AppStrings.paywallPlanExpiredTitle
      : AppStrings.paywallFreeLimitTitle;

  String get _subtitle => _isExpired
      ? AppStrings.paywallPlanExpiredSubtitle
      : AppStrings.paywallFreeLimitSubtitle;

  /// 만료 케이스는 trial 카드를 숨긴다 (이미 trial/active 종료).
  bool get _showTrial => trialAvailable && !_isExpired;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          _subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.inkSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.space5),
        _PlanCard(
          title: AppStrings.paywallProMonthlyTitle,
          description: AppStrings.paywallProMonthlyDescription,
          ctaLabel: AppStrings.paywallProBuyCta,
          ctaKey: buyProButtonKey,
          onPressed: onBuyPro,
          emphasized: true,
        ),
        if (_showTrial) ...[
          const SizedBox(height: AppSpacing.space3),
          _PlanCard(
            title: AppStrings.paywallTrialTitle,
            description: AppStrings.paywallTrialNote,
            ctaLabel: AppStrings.paywallTrialStartCta,
            ctaKey: startTrialButtonKey,
            onPressed: onStartTrial,
            emphasized: false,
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        Center(
          child: TextButton(
            key: laterButtonKey,
            onPressed: onLater,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkSecondary,
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
            ),
            child: const Text(AppStrings.paywallLaterCta),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.ctaKey,
    required this.onPressed,
    required this.emphasized,
  });

  final String title;
  final String description;
  final String ctaLabel;
  final Key ctaKey;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.paperAccentSoft : AppColors.paperDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: emphasized ? AppColors.paperAccent : AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: emphasized
                ? FilledButton(
                    key: ctaKey,
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      foregroundColor: AppColors.paper,
                      minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(ctaLabel),
                  )
                : OutlinedButton(
                    key: ctaKey,
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.inkTertiary),
                      minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(ctaLabel),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Paywall sheet 를 Notebook 스타일 BottomSheet 로 노출한다.
///
/// 사용자가 "나중에" 또는 backdrop 으로 닫으면 [Future] 가 `false` 로 resolve.
/// Buy/Trial 을 누르면 콜백 실행 후 sheet 가 닫히고 `true` 로 resolve.
Future<bool> showFreeLimitSheet({
  required BuildContext context,
  required LimitReason reason,
  required bool trialAvailable,
  required VoidCallback onBuyPro,
  required VoidCallback onStartTrial,
}) async {
  final result = await showNotebookBottomSheet<bool>(
    context: context,
    builder: (ctx) => FreeLimitSheet(
      reason: reason,
      trialAvailable: trialAvailable,
      onBuyPro: () {
        Navigator.of(ctx).pop(true);
        onBuyPro();
      },
      onStartTrial: () {
        Navigator.of(ctx).pop(true);
        onStartTrial();
      },
      onLater: () => Navigator.of(ctx).pop(false),
    ),
  );
  return result ?? false;
}
