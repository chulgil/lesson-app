import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../providers/refund_request_providers.dart';

/// Teacher home [환불 대기] card (#1271) — mirrors [PaymentPendingCard].
/// Hides itself when the pending count is 0.
class RefundPendingCard extends ConsumerWidget {
  const RefundPendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final countAsync = ref.watch(
      teacherPendingRefundRequestCountProvider(teacherId),
    );

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
      onTap: () => context.push(AppRoutes.refundPendingList),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccentSoft,
          border: Border.all(color: AppColors.paperAccent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.refundPendingCardTitle,
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
