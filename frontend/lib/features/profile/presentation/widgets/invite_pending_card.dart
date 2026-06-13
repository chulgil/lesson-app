import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../providers/invite_pending_provider.dart';

/// 선생님 홈 [초대 대기] 카드 — #5 D-G3 Phase 2.
///
/// 대기 중인 초대가 0건이면 노출되지 않는다. 탭 시 리스트 화면 진입.
class InvitePendingCard extends ConsumerWidget {
  const InvitePendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingInviteCountProvider);
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
      onTap: () => context.push(AppRoutes.invitePending),
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
                    AppStrings.invitePendingCardTitle,
                    style: NotebookTypography.eyebrow.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '$count건',
                    style: NotebookTypography.sectionTitle.copyWith(
                      color: AppColors.paperTrial,
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
