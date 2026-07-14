import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../providers/payment_tracking_provider.dart';

/// 선생님 홈 [입금 확인 대기] 카드 — #424.
///
/// 입금 확인 대기 건수가 0일 때는 표시되지 않습니다.
/// 탭 시 [/profile/payment-pending] 리스트 화면으로 진입.
class PaymentPendingCard extends ConsumerWidget {
  const PaymentPendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(paymentPendingCountProvider);

    return countAsync.when(
      data: (count) {
        if (count <= 0) return const SizedBox.shrink();
        return _buildCard(context, count);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, int count) {
    return InkWell(
      onTap: () => context.push(AppRoutes.paymentPending),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.paymentPendingCardTitle,
                    style: NotebookTypography.eyebrow.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '$count건',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}
