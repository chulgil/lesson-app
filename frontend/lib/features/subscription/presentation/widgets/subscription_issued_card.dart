import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/subscription.dart';

/// Chat bubble card displayed when a subscription is first issued.
///
/// Shows subscription summary: instrument, schedule, validity period,
/// reschedule credits, and deadline hours in a compact card format.
class SubscriptionIssuedCard extends StatelessWidget {
  final Subscription subscription;
  final String? instrument;
  final String? scheduleSummary;

  const SubscriptionIssuedCard({
    super.key,
    required this.subscription,
    this.instrument,
    this.scheduleSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '\u{1F3B5} ${AppStrings.subscriptionIssuedMessage}',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // Dashed divider
          _buildDashedDivider(),
          const SizedBox(height: AppSpacing.space2),
          // Info rows
          _buildTitleRow(),
          if (scheduleSummary != null && scheduleSummary!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space1),
            _buildInfoText(scheduleSummary!),
          ],
          if (subscription.startDate != null &&
              subscription.endDate != null) ...[
            const SizedBox(height: AppSpacing.space1),
            _buildInfoText(
              '${AppStrings.validityPeriod}: '
              '${formatDateMD(subscription.startDate!)} ~ '
              '${formatDateMD(subscription.endDate!)}',
            ),
          ],
          const SizedBox(height: AppSpacing.space1),
          _buildInfoText(
            '${AppStrings.rescheduleCreditsLabel}: '
            '${subscription.totalRescheduleAllowance}'
            '${AppStrings.countSuffix}',
          ),
          const SizedBox(height: AppSpacing.space1),
          _buildInfoText(
            '${AppStrings.deadlineHoursLabel}: '
            '${subscription.rescheduleDeadlineHours}'
            '${AppStrings.hoursUnit}',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    final parts = <String>[];
    if (instrument != null && instrument!.isNotEmpty) {
      parts.add(instrument!);
    }
    parts.add(subscription.typeLabel);

    return Text(
      parts.join(' '),
      style: AppTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.inkSecondary,
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
