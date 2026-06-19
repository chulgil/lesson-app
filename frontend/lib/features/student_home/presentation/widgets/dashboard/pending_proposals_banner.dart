import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';
import '../../../../../core/l10n/app_strings.dart';

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
                // §7.132: round → 사각 아이콘 컨테이너 (Notebook 메타포).
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: const BoxDecoration(color: AppColors.paperDark),
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
                        AppStrings.notifProposalTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        proposal.isAutoProposal
                            ? (proposal.discountReason ?? AppStrings.pendingProposalDefaultReason)
                            : (proposal.message ?? AppStrings.pendingProposalDefaultMessage),
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
