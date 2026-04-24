import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/lesson_policy.dart';
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
              color: AppColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color:
                  valueColor ?? (strikethrough ? AppColors.inkTertiary : null),
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Applied-policy summary block
/// Displays change/cancel/no-show policy derived from [LessonPolicy].
/// If [rescheduleAllowance] / [rescheduleDeadlineHours] override the policy
/// default, the override value wins.
class AppliedPolicySection extends StatelessWidget {
  final LessonPolicy policy;
  final int? rescheduleAllowance;
  final int? rescheduleDeadlineHours;

  const AppliedPolicySection({
    super.key,
    required this.policy,
    this.rescheduleAllowance,
    this.rescheduleDeadlineHours,
  });

  @override
  Widget build(BuildContext context) {
    final allowance = rescheduleAllowance ?? policy.maxChangesPerMonth;
    final deadline = rescheduleDeadlineHours ?? policy.minCancelHours;
    final changeLine = '$deadline시간 전까지 · 월 $allowance회';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: AppColors.paperAccent.withValues(alpha: 0.12),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Icon(Icons.rule_rounded, size: 16, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '적용 정책',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          _PolicyLine(label: '변경/취소', value: changeLine),
          _PolicyLine(label: '노쇼', value: policy.noShowPolicySummary),
          _PolicyLine(label: '이월', value: policy.carryoverPolicySummary),
        ],
      ),
    );
  }
}

class _PolicyLine extends StatelessWidget {
  final String label;
  final String value;

  const _PolicyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
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
  final LessonPolicy? effectivePolicy;
  final int? rescheduleAllowance;
  final int? rescheduleDeadlineHours;

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
    this.effectivePolicy,
    this.rescheduleAllowance,
    this.rescheduleDeadlineHours,
  });

  @override
  Widget build(BuildContext context) {
    final endDate = _calculateEndDate();
    final lessonsDisplay = _buildLessonsDisplay();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 요약 카드 섹션 제목은 Playfair sectionTitle
          // 로 통일 (§7.17). paperAccent 틴트 유지.
          Text(
            '발급 요약',
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SummaryRow(label: '유형', value: lessonsDisplay),

          // Amount with discount
          if (discountPercent > 0 && originalAmount > 0) ...[
            SummaryRow(
              label: '정가',
              value: formatWonWithComma(originalAmount),
              strikethrough: true,
            ),
            SummaryRow(
              label: '할인',
              value:
                  '-${formatWonWithComma(originalAmount - finalAmount)} ($discountPercent%)',
              valueColor: AppColors.paperAccent,
            ),
            SummaryRow(
              label: '결제금액',
              value: formatWonWithComma(finalAmount),
              isBold: true,
            ),
          ] else ...[
            SummaryRow(label: '금액', value: formatWonWithComma(originalAmount)),
          ],

          // Bonus
          if (bonusLessons > 0)
            SummaryRow(
              label: '보너스',
              value:
                  '+$bonusLessons회${effectiveBonusReason != null ? ' ($effectiveBonusReason)' : ''}',
              valueColor: AppColors.paperAccent,
            ),

          // Payment status
          SummaryRow(
            label: '결제',
            value:
                isPaymentConfirmed
                    ? '${selectedPaymentMethod.label} (확인됨)'
                    : '미결제 (후불)',
            valueColor: isPaymentConfirmed ? null : AppColors.paperAccent,
          ),

          if (startDate != null)
            SummaryRow(label: '시작일', value: formatDateYMDKorean(startDate!)),
          if (endDate != null)
            SummaryRow(label: '만료일', value: formatDateYMDKorean(endDate)),

          if (effectivePolicy != null)
            AppliedPolicySection(
              policy: effectivePolicy!,
              rescheduleAllowance: rescheduleAllowance,
              rescheduleDeadlineHours: rescheduleDeadlineHours,
            ),
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
        color: AppColors.ink.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentCount명의 학생에게 동일한 수강권을 발급합니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '각 학생에게 개별 수강권이 생성됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.8),
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
  final LessonPolicy? effectivePolicy;
  final int? rescheduleAllowance;
  final int? rescheduleDeadlineHours;

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
    this.effectivePolicy,
    this.rescheduleAllowance,
    this.rescheduleDeadlineHours,
  });

  @override
  Widget build(BuildContext context) {
    final endDate = _calculateEndDate();
    final lessonsDisplay = _buildLessonsDisplay();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 요약 카드 섹션 제목은 Playfair sectionTitle
          // 로 통일 (§7.17). paperAccent 틴트 유지.
          Text(
            '배치 발급 요약',
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SummaryRow(label: '발급 대상', value: '$studentCount명'),
          SummaryRow(label: '유형', value: lessonsDisplay),

          // Amount with discount
          if (discountPercent > 0 && originalAmount > 0) ...[
            SummaryRow(
              label: '정가',
              value: formatWonWithComma(originalAmount),
              strikethrough: true,
            ),
            SummaryRow(
              label: '할인',
              value:
                  '-${formatWonWithComma(originalAmount - finalAmount)} ($discountPercent%)',
              valueColor: AppColors.paperAccent,
            ),
            SummaryRow(
              label: '개인당 금액',
              value: formatWonWithComma(finalAmount),
              isBold: true,
            ),
          ] else ...[
            SummaryRow(
              label: '개인당 금액',
              value: formatWonWithComma(originalAmount),
            ),
          ],

          // Total amount
          SummaryRow(
            label: '총 예상 금액',
            value: formatWonWithComma(finalAmount * studentCount),
            isBold: true,
            valueColor: AppColors.paperAccent,
          ),

          // Bonus
          if (bonusLessons > 0)
            SummaryRow(
              label: '보너스',
              value:
                  '+$bonusLessons회${effectiveBonusReason != null ? ' ($effectiveBonusReason)' : ''}',
              valueColor: AppColors.paperAccent,
            ),

          if (startDate != null)
            SummaryRow(label: '시작일', value: formatDateYMDKorean(startDate!)),
          if (endDate != null)
            SummaryRow(label: '만료일', value: formatDateYMDKorean(endDate)),

          if (effectivePolicy != null)
            AppliedPolicySection(
              policy: effectivePolicy!,
              rescheduleAllowance: rescheduleAllowance,
              rescheduleDeadlineHours: rescheduleDeadlineHours,
            ),
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
