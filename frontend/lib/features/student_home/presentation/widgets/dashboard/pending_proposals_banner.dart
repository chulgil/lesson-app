import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// Banner showing pending subscription proposals for a student.
class PendingProposalsBanner extends ConsumerWidget {
  final String studentId;

  const PendingProposalsBanner({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingProposalsAsync = ref.watch(
      pendingStudentProposalsProvider(studentId),
    );

    return pendingProposalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (proposals) {
        if (proposals.isEmpty) {
          return const SizedBox.shrink();
        }

        final proposal = proposals.first;
        final count = proposals.length;

        return GestureDetector(
          onTap: () {
            if (count == 1) {
              context.push(
                AppRoutes.proposalDetail.replaceFirst(':id', proposal.id),
              );
            } else {
              context.push(AppRoutes.notifications);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: const BoxDecoration(
                    color: AppColors.paperDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.paperAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수강권 제안이 도착했어요!',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        proposal.isAutoProposal
                            ? (proposal.discountReason ?? '지금 확인하고 혜택 받으세요')
                            : (proposal.message ?? '선생님이 수강권을 제안했습니다'),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
