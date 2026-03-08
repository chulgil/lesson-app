import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Summary row displaying label-value pair
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool strikethrough;
  final bool isBold;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.strikethrough = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color:
                  valueColor ??
                  (strikethrough ? AppColors.textTertiaryLight : null),
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card for single student subscription issuance
class SubscriptionSummaryCard extends StatelessWidget {
  final SubscriptionType selectedType;
  final int totalLessons;
  final int monthsCount;
  final int validityDays;
  final int originalAmount;
  final int finalAmount;
  final int discountPercent;
  final int bonusLessons;
  final String? effectiveBonusReason;
  final bool isPaymentConfirmed;
  final SubscriptionPaymentMethod selectedPaymentMethod;
  final DateTime? startDate;

  const SubscriptionSummaryCard({
    super.key,
    required this.selectedType,
    required this.totalLessons,
    required this.monthsCount,
    required this.validityDays,
    required this.originalAmount,
    required this.finalAmount,
    required this.discountPercent,
    required this.bonusLessons,
    this.effectiveBonusReason,
    required this.isPaymentConfirmed,
    required this.selectedPaymentMethod,
    this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 M월 d일');
    final endDate = _calculateEndDate();
    final lessonsDisplay = _buildLessonsDisplay();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '발급 요약',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SummaryRow(label: '유형', value: lessonsDisplay),

          // Amount with discount
          if (discountPercent > 0 && originalAmount > 0) ...[
            SummaryRow(
              label: '정가',
              value: '${NumberFormat('#,###').format(originalAmount)}원',
              strikethrough: true,
            ),
            SummaryRow(
              label: '할인',
              value:
                  '-${NumberFormat('#,###').format(originalAmount - finalAmount)}원 ($discountPercent%)',
              valueColor: AppColors.secondary,
            ),
            SummaryRow(
              label: '결제금액',
              value: '${NumberFormat('#,###').format(finalAmount)}원',
              isBold: true,
            ),
          ] else ...[
            SummaryRow(
              label: '금액',
              value: '${NumberFormat('#,###').format(originalAmount)}원',
            ),
          ],

          // Bonus
          if (bonusLessons > 0)
            SummaryRow(
              label: '보너스',
              value:
                  '+$bonusLessons회${effectiveBonusReason != null ? ' ($effectiveBonusReason)' : ''}',
              valueColor: AppColors.primary,
            ),

          // Payment status
          SummaryRow(
            label: '결제',
            value:
                isPaymentConfirmed
                    ? '${selectedPaymentMethod.label} (확인됨)'
                    : '미결제 (후불)',
            valueColor: isPaymentConfirmed ? null : AppColors.warning,
          ),

          if (startDate != null)
            SummaryRow(label: '시작일', value: dateFormat.format(startDate!)),
          if (endDate != null)
            SummaryRow(label: '만료일', value: dateFormat.format(endDate)),
        ],
      ),
    );
  }

  DateTime? _calculateEndDate() {
    if (startDate == null) return null;
    if (selectedType == SubscriptionType.monthly) {
      return DateTime(
        startDate!.year,
        startDate!.month + monthsCount,
        startDate!.day,
      );
    } else if (selectedType == SubscriptionType.trial) {
      return startDate!.add(const Duration(days: 7));
    } else if (selectedType == SubscriptionType.package) {
      return startDate!.add(Duration(days: validityDays));
    }
    return null;
  }

  String _buildLessonsDisplay() {
    if (selectedType == SubscriptionType.trial) {
      return '체험 (1회)';
    } else if (selectedType == SubscriptionType.package) {
      return bonusLessons > 0
          ? '회차제 ($totalLessons + $bonusLessons회, $validityDays일)'
          : '회차제 ($totalLessons회, $validityDays일)';
    } else {
      return '월정액 ($monthsCount개월)';
    }
  }
}

/// Batch info banner showing student count
class BatchInfoBanner extends StatelessWidget {
  final int studentCount;

  const BatchInfoBanner({super.key, required this.studentCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: AppColors.info),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentCount명의 학생에게 동일한 수강권을 발급합니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '각 학생에게 개별 수강권이 생성됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card for batch subscription issuance
class BatchSummaryCard extends StatelessWidget {
  final int studentCount;
  final SubscriptionType selectedType;
  final int totalLessons;
  final int monthsCount;
  final int validityDays;
  final int originalAmount;
  final int finalAmount;
  final int discountPercent;
  final int bonusLessons;
  final String? effectiveBonusReason;
  final DateTime? startDate;

  const BatchSummaryCard({
    super.key,
    required this.studentCount,
    required this.selectedType,
    required this.totalLessons,
    required this.monthsCount,
    required this.validityDays,
    required this.originalAmount,
    required this.finalAmount,
    required this.discountPercent,
    required this.bonusLessons,
    this.effectiveBonusReason,
    this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 M월 d일');
    final endDate = _calculateEndDate();
    final lessonsDisplay = _buildLessonsDisplay();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '배치 발급 요약',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SummaryRow(label: '발급 대상', value: '$studentCount명'),
          SummaryRow(label: '유형', value: lessonsDisplay),

          // Amount with discount
          if (discountPercent > 0 && originalAmount > 0) ...[
            SummaryRow(
              label: '정가',
              value: '${NumberFormat('#,###').format(originalAmount)}원',
              strikethrough: true,
            ),
            SummaryRow(
              label: '할인',
              value:
                  '-${NumberFormat('#,###').format(originalAmount - finalAmount)}원 ($discountPercent%)',
              valueColor: AppColors.secondary,
            ),
            SummaryRow(
              label: '개인당 금액',
              value: '${NumberFormat('#,###').format(finalAmount)}원',
              isBold: true,
            ),
          ] else ...[
            SummaryRow(
              label: '개인당 금액',
              value: '${NumberFormat('#,###').format(originalAmount)}원',
            ),
          ],

          // Total amount
          SummaryRow(
            label: '총 예상 금액',
            value:
                '${NumberFormat('#,###').format(finalAmount * studentCount)}원',
            isBold: true,
            valueColor: AppColors.primary,
          ),

          // Bonus
          if (bonusLessons > 0)
            SummaryRow(
              label: '보너스',
              value:
                  '+$bonusLessons회${effectiveBonusReason != null ? ' ($effectiveBonusReason)' : ''}',
              valueColor: AppColors.primary,
            ),

          if (startDate != null)
            SummaryRow(label: '시작일', value: dateFormat.format(startDate!)),
          if (endDate != null)
            SummaryRow(label: '만료일', value: dateFormat.format(endDate)),
        ],
      ),
    );
  }

  DateTime? _calculateEndDate() {
    if (startDate == null) return null;
    if (selectedType == SubscriptionType.monthly) {
      return DateTime(
        startDate!.year,
        startDate!.month + monthsCount,
        startDate!.day,
      );
    } else if (selectedType == SubscriptionType.trial) {
      return startDate!.add(const Duration(days: 7));
    } else if (selectedType == SubscriptionType.package) {
      return startDate!.add(Duration(days: validityDays));
    }
    return null;
  }

  String _buildLessonsDisplay() {
    if (selectedType == SubscriptionType.trial) {
      return '체험 (1회)';
    } else if (selectedType == SubscriptionType.package) {
      return bonusLessons > 0
          ? '회차제 ($totalLessons + $bonusLessons회, $validityDays일)'
          : '회차제 ($totalLessons회, $validityDays일)';
    } else {
      return '월정액 ($monthsCount개월)';
    }
  }
}
