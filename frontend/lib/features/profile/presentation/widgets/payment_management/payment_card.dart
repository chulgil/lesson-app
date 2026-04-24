import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/lessons/domain/entities/payment.dart';

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
        color: AppColors.paper,
        border: Border.all(
          color:
              isOverdue
                  ? AppColors.paperAccent.withValues(alpha: 0.3)
                  : AppColors.inkQuaternary,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
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
          backgroundColor:
              payment.type == PaymentType.trial
                  ? AppColors.ink
                  : AppColors.paperAccentSoft,
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
                  color: AppColors.inkSecondary,
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
              style: AppTypography.headingMedium.copyWith(color: statusColor),
            ),
            Text(
              payment.method.label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        if (payment.status == PaymentStatus.pending && onConfirm != null)
          Flexible(
            child: PaymentActionButton(payment: payment, onConfirm: onConfirm!),
          ),
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
          color: AppColors.paperAccent.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 14, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '연체 ${DateTime.now().difference(payment.dueDate!).inDays}일',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status, bool isOverdue) {
    if (isOverdue) return AppColors.paperAccent;
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.paperAccent;
      case PaymentStatus.paid:
        return AppColors.ink;
      case PaymentStatus.confirmed:
      // ignore: deprecated_member_use_from_same_package
      case PaymentStatus.completed:
        return AppColors.paperOk;
      case PaymentStatus.overdue:
        return AppColors.paperAccent;
      case PaymentStatus.cancelled:
        return AppColors.inkTertiary;
      case PaymentStatus.refunded:
        return AppColors.ink;
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
    final color = isTrial ? AppColors.ink : AppColors.paperAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15)),
      child: Text(
        type.label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
      color = AppColors.paperAccent;
    } else if (payment.isAwaitingTeacherConfirmation) {
      color = AppColors.ink;
    } else {
      switch (payment.status) {
        case PaymentStatus.pending:
          color = AppColors.paperAccent;
        case PaymentStatus.paid:
          color = AppColors.ink;
        case PaymentStatus.confirmed:
        // ignore: deprecated_member_use_from_same_package
        case PaymentStatus.completed:
          color = AppColors.paperOk;
        case PaymentStatus.overdue:
          color = AppColors.paperAccent;
        case PaymentStatus.cancelled:
          color = AppColors.inkTertiary;
        case PaymentStatus.refunded:
          color = AppColors.ink;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (payment.isAwaitingTeacherConfirmation) ...[
            Icon(Icons.notifications_active, size: 12, color: color),
            const SizedBox(width: AppSpacing.space1),
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
              color: AppColors.ink.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '입금알림',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        // Confirm button
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('입금확인'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.paperOk,
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
