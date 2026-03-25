import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/stat_card.dart';
import '../../../../../features/lessons/domain/entities/payment.dart';

/// Payment summary section showing received/pending amounts.
class PaymentSummarySection extends StatelessWidget {
  const PaymentSummarySection({
    super.key,
    required this.summary,
    this.onViewOverdue,
  });

  final PaymentSummary summary;
  final VoidCallback? onViewOverdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateTime.now().month}월 수강료 현황',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Main stats row
          StatCardRow(
            cards: [
              StatCard(
                title: '수납 완료',
                value: summary.formattedTotalReceived,
                subtitle: '${summary.paidStudents}명',
                color: AppColors.practiceGood,
                icon: Icons.check_circle,
              ),
              StatCard(
                title: '미납',
                value: summary.formattedTotalPending,
                subtitle: '${summary.unpaidStudents}명',
                color: summary.overdueStudents > 0
                    ? AppColors.error
                    : AppColors.warning,
                icon: Icons.pending,
              ),
            ],
          ),

          // Overdue warning
          if (summary.overdueStudents > 0) ...[
            const SizedBox(height: AppSpacing.space3),
            _OverdueWarningBanner(
              overdueCount: summary.overdueStudents,
              onViewDetails: onViewOverdue,
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner showing overdue payment warning.
class _OverdueWarningBanner extends StatelessWidget {
  const _OverdueWarningBanner({
    required this.overdueCount,
    this.onViewDetails,
  });

  final int overdueCount;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '연체 $overdueCount명',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onViewDetails != null)
            TextButton(
              onPressed: onViewDetails,
              child: const Text('확인하기'),
            ),
        ],
      ),
    );
  }
}
