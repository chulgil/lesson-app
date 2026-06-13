// #415 R4 Phase C2 — Pro/Studio 전용 기능 진입 차단 sheet.
//
// spec: docs/specs/subscription/paywall_spec.md §3.1, §7
//
// FreeLimitSheet 는 "학생 한도" 컨텍스트, 본 sheet 는 "기능 진입" 컨텍스트.
// 메시지/CTA 가 다르므로 별개 위젯으로 유지한다.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';

/// 차단된 기능이 요구하는 최소 플랜.
enum LockedFeatureTier { pro, studio }

/// Pro/Studio 전용 기능 진입 시 노출되는 Paywall sheet.
class FeatureLockedSheet extends StatelessWidget {
  const FeatureLockedSheet({
    super.key,
    required this.tier,
    required this.onUpgrade,
    required this.onLater,
    this.featureName,
  });

  static const upgradeButtonKey = Key('feature_locked_sheet_upgrade');
  static const laterButtonKey = Key('feature_locked_sheet_later');

  final LockedFeatureTier tier;
  final VoidCallback onUpgrade;
  final VoidCallback onLater;

  /// 진입 시도한 기능명 — 안내 본문 첫 줄에 prefix 로 노출 (옵션).
  final String? featureName;

  String get _title => switch (tier) {
    LockedFeatureTier.pro => AppStrings.featureLockedProTitle,
    LockedFeatureTier.studio => AppStrings.featureLockedStudioTitle,
  };

  String get _subtitle => switch (tier) {
    LockedFeatureTier.pro => AppStrings.featureLockedProSubtitle,
    LockedFeatureTier.studio => AppStrings.featureLockedStudioSubtitle,
  };

  String get _ctaLabel => switch (tier) {
    LockedFeatureTier.pro => AppStrings.paywallProBuyCta,
    LockedFeatureTier.studio => AppStrings.billingStudioUpgradeCta,
  };

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
          featureName != null ? '$featureName — $_subtitle' : _subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.inkSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.space5),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: upgradeButtonKey,
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: AppColors.paper,
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(_ctaLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
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

/// FeatureLockedSheet 를 Notebook BottomSheet 로 노출.
///
/// 사용자가 "나중에" 또는 backdrop 으로 닫으면 `false`. 업그레이드 누르면
/// 콜백 실행 후 `true`. caller 는 결과로 라우팅 여부 판단 가능.
Future<bool> showFeatureLockedSheet({
  required BuildContext context,
  required LockedFeatureTier tier,
  required VoidCallback onUpgrade,
  String? featureName,
}) async {
  final result = await showNotebookBottomSheet<bool>(
    context: context,
    builder: (ctx) => FeatureLockedSheet(
      tier: tier,
      featureName: featureName,
      onUpgrade: () {
        Navigator.of(ctx).pop(true);
        onUpgrade();
      },
      onLater: () => Navigator.of(ctx).pop(false),
    ),
  );
  return result ?? false;
}
