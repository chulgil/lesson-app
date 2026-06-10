import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// audit C2-F02: 수강권 발급 직후 학생용 하단 액션바.
///
/// `proposal_detail_screen.dart` 의 ProposalStatus.confirmed 케이스에서
/// SubscriptionDetail 로의 진입점을 제공해 "발급 후 다음 단계 단절"을 막는다.
///
/// student_direct_booking_spec §8 "수강권 발급 완료" 진입점 구현.
class ProposalIssuedActionBar extends StatelessWidget {
  /// 발급된 수강권 ID — 탭 시 SubscriptionDetail 로 라우팅하는 데 사용.
  final String subscriptionId;

  /// CTA 탭 콜백 — 보통 `context.go('/subscriptions/$id')` 호출.
  final VoidCallback onTap;

  const ProposalIssuedActionBar({
    super.key,
    required this.subscriptionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperOk.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.paperOk,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Flexible(
                    child: Text(
                      AppStrings.proposalDetailIssuedHint,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperOk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                icon: const Icon(Icons.event_available),
                label: const Text(
                  AppStrings.proposalDetailViewSubscriptionAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
