import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/payment.dart';

/// Card displaying a single payment with status and actions.
class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onConfirm,
  });

  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final isOverdue = payment.isOverdue;
    final statusColor = _getStatusColor(payment.status, isOverdue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                _buildHeader(),
                const SizedBox(height: AppSpacing.space3),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.space3),
                // Amount and action row
                _buildAmountRow(statusColor),
                // Overdue warning
                if (isOverdue) _buildOverdueWarning(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: payment.type == PaymentType.trial
              ? AppColors.info
              : AppColors.primaryLight,
          child: Text(
            payment.studentName.isNotEmpty ? payment.studentName[0] : '?',
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    payment.studentName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  PaymentTypeBadge(type: payment.type),
                ],
              ),
              Text(
                payment.periodDisplay,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        PaymentStatusBadge(payment: payment),
      ],
    );
  }

  Widget _buildAmountRow(Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payment.formattedAmount,
              style: AppTypography.headingMedium.copyWith(
                color: statusColor,
              ),
            ),
            Text(
              payment.method.label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        if (payment.status == PaymentStatus.pending && onConfirm != null)
          Flexible(child: PaymentActionButton(payment: payment, onConfirm: onConfirm!)),
      ],
    );
  }

  Widget _buildOverdueWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 14, color: AppColors.error),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '연체 ${DateTime.now().difference(payment.dueDate!).inDays}일',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status, bool isOverdue) {
    if (isOverdue) return AppColors.error;
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.paid:
        return AppColors.info;
      case PaymentStatus.confirmed:
      // ignore: deprecated_member_use_from_same_package
      case PaymentStatus.completed:
        return AppColors.practiceGood;
      case PaymentStatus.overdue:
        return AppColors.error;
      case PaymentStatus.cancelled:
        return AppColors.textTertiaryLight;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }
}

/// Badge showing payment type (regular/trial).
class PaymentTypeBadge extends StatelessWidget {
  const PaymentTypeBadge({super.key, required this.type});

  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final isTrial = type == PaymentType.trial;
    final color = isTrial ? AppColors.info : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Badge showing payment status with optional notification indicator.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    Color color;
    final label = payment.displayStatus;

    if (payment.isOverdue) {
      color = AppColors.error;
    } else if (payment.isAwaitingTeacherConfirmation) {
      color = AppColors.info;
    } else {
      switch (payment.status) {
        case PaymentStatus.pending:
          color = AppColors.warning;
        case PaymentStatus.paid:
          color = AppColors.info;
        case PaymentStatus.confirmed:
        // ignore: deprecated_member_use_from_same_package
        case PaymentStatus.completed:
          color = AppColors.practiceGood;
        case PaymentStatus.overdue:
          color = AppColors.error;
        case PaymentStatus.cancelled:
          color = AppColors.textTertiaryLight;
        case PaymentStatus.refunded:
          color = AppColors.info;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (payment.isAwaitingTeacherConfirmation) ...[
            Icon(Icons.notifications_active, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for confirming payment.
class PaymentActionButton extends StatelessWidget {
  const PaymentActionButton({
    super.key,
    required this.payment,
    required this.onConfirm,
  });

  final Payment payment;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show notification indicator if student confirmed
        if (payment.isAwaitingTeacherConfirmation) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '입금알림',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Confirm button
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('입금확인'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.practiceGood,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
          ),
        ),
      ],
    );
  }
}
