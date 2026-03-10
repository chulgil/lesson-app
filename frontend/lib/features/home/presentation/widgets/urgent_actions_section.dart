import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_routes.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/domain/entities/subscription_proposal.dart';

/// Displays urgent action items requiring immediate teacher attention.
class UrgentActionsSection extends StatelessWidget {
  final String teacherId;
  final int pendingRequests;
  final int pendingBookings;
  final List<SubscriptionProposal> awaitingConfirm;
  final List<Subscription> expiringSoon;

  const UrgentActionsSection({
    super.key,
    required this.teacherId,
    required this.pendingRequests,
    required this.pendingBookings,
    required this.awaitingConfirm,
    required this.expiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    final awaitingConfirmCount = awaitingConfirm.length;
    final expiringSoonStudentCount =
        expiringSoon.map((s) => s.studentId).toSet().length;

    final totalUrgent = pendingRequests +
        pendingBookings +
        (awaitingConfirmCount > 0 ? 1 : 0) +
        (expiringSoonStudentCount > 0 ? 1 : 0);

    if (totalUrgent == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(totalUrgent),
        const SizedBox(height: AppSpacing.space3),
        _buildItemsContainer(
          context,
          awaitingConfirmCount: awaitingConfirmCount,
          expiringSoonStudentCount: expiringSoonStudentCount,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int totalUrgent) {
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '즉시 확인 필요',
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalUrgent',
            style: AppTypography.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsContainer(
    BuildContext context, {
    required int awaitingConfirmCount,
    required int expiringSoonStudentCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (pendingRequests > 0)
            _UrgentItem(
              icon: Icons.person_add,
              iconColor: AppColors.error,
              title: '레슨 요청 $pendingRequests건 대기',
              onTap: () => context.push(
                AppRoutes.lessonRequests,
                extra: {'teacherId': teacherId},
              ),
            ),
          if (pendingBookings > 0)
            _UrgentItem(
              icon: Icons.event_note,
              iconColor: AppColors.warning,
              title: '예약 승인 $pendingBookings건 대기',
              onTap: () => context.push(AppRoutes.pendingBookings),
              showDivider: pendingRequests > 0,
            ),
          if (awaitingConfirmCount > 0)
            _UrgentItem(
              icon: Icons.payments,
              iconColor: AppColors.warning,
              title: '입금 확인 $awaitingConfirmCount건 대기',
              onTap: () => context.push(
                '${AppRoutes.proposalConfirm}?teacherId=$teacherId',
              ),
              showDivider: pendingRequests > 0 || pendingBookings > 0,
            ),
          if (expiringSoonStudentCount > 0)
            _UrgentItem(
              icon: Icons.card_membership,
              iconColor: AppColors.warning,
              title: '수강권 임박 $expiringSoonStudentCount명',
              onTap: () => context.push(AppRoutes.subscriptions),
              showDivider: pendingRequests > 0 ||
                  pendingBookings > 0 ||
                  awaitingConfirmCount > 0,
            ),
        ],
      ),
    );
  }
}

/// A single urgent action item row.
class _UrgentItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const _UrgentItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, color: AppColors.warning.withValues(alpha: 0.2)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '확인하기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
