import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/subscription_visuals.dart';

/// Chapter 2: Payment info (method, date, confirmation status).
class SubscriptionChapterPayment extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionChapterPayment({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        children: [
          _buildRow(
            AppStrings.paymentStatus,
            subscription.paymentStatusLabel,
            valueColor:
                subscription.paymentConfirmed
                    ? AppColors.paperOk
                    : AppColors.paperAccent,
          ),
          if (subscription.paymentMethod != null)
            _buildRow(
              AppStrings.paymentMethod,
              subscription.paymentMethod!.label,
            ),
          if (subscription.paidAt != null)
            _buildRow(
              AppStrings.paymentDate,
              formatDateTimeYMDHM(subscription.paidAt!),
            ),
          if (subscription.paymentConfirmedAt != null)
            _buildRow(
              AppStrings.confirmationDate,
              formatDateTimeYMDHM(subscription.paymentConfirmedAt!),
            ),
          if (subscription.originalAmount != null)
            _buildRow(
              AppStrings.originalAmount,
              '${formatNumberWithComma(subscription.originalAmount!)}${AppStrings.wonUnit}',
              valueColor: AppColors.inkTertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
