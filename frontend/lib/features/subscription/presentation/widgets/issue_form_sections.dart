import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Subscription type selector with chips and description
class SubscriptionTypeSelector extends StatelessWidget {
  final SubscriptionType selectedType;
  final ValueChanged<SubscriptionType> onChanged;

  const SubscriptionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수강권 유형', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            _buildTypeChip(SubscriptionType.trial, '체험', Icons.star_outline),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.package,
              '회차제',
              Icons.confirmation_number_outlined,
            ),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.monthly,
              '월정액',
              Icons.calendar_month,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildTypeDescription(),
      ],
    );
  }

  Widget _buildTypeChip(SubscriptionType type, String label, IconData icon) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDescription() {
    final String description;
    final IconData icon;

    switch (selectedType) {
      case SubscriptionType.trial:
        description =
            '1회 체험 레슨으로, 학생과 선생님의 적합성을 확인합니다. 무료 또는 할인 금액으로 설정할 수 있습니다.';
        icon = Icons.lightbulb_outline;
      case SubscriptionType.package:
        description = '정해진 횟수만큼 레슨을 진행합니다. 매 레슨마다 유연하게 스케줄을 조율할 수 있습니다.';
        icon = Icons.swap_horiz;
      case SubscriptionType.monthly:
        description = '월 단위 정기 수강권입니다. 고정된 요일·시간에 레슨이 자동 배정되어 스케줄 관리가 편리합니다.';
        icon = Icons.event_repeat;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment status section with prepaid/postpaid toggle and payment method selector
class PaymentStatusSection extends StatelessWidget {
  final bool isPaymentConfirmed;
  final SubscriptionPaymentMethod selectedPaymentMethod;
  final ValueChanged<bool> onPaymentConfirmedChanged;
  final ValueChanged<SubscriptionPaymentMethod> onPaymentMethodChanged;

  const PaymentStatusSection({
    super.key,
    required this.isPaymentConfirmed,
    required this.selectedPaymentMethod,
    required this.onPaymentConfirmedChanged,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('결제 방식', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _PaymentStatusChip(
                label: '선불',
                icon: Icons.payment,
                isSelected: isPaymentConfirmed,
                onTap: () => onPaymentConfirmedChanged(true),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _PaymentStatusChip(
                label: '후불',
                icon: Icons.schedule,
                isSelected: !isPaymentConfirmed,
                onTap: () => onPaymentConfirmedChanged(false),
                accentColor: AppColors.warning,
              ),
            ),
          ],
        ),

        // Payment method selector (only when prepaid)
        if (isPaymentConfirmed) ...[
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children:
                SubscriptionPaymentMethod.values.map((method) {
                  final isSelected = selectedPaymentMethod == method;
                  return ChoiceChip(
                    label: Text(method.label),
                    selected: isSelected,
                    onSelected: (_) => onPaymentMethodChanged(method),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                    ),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
          ),
        ],

        // Info for postpaid
        if (!isPaymentConfirmed) ...[
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '후불 수강권은 미수금으로 표시됩니다. 입금 확인 후 결제완료 처리할 수 있습니다.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;

  const _PaymentStatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amount input section with presets and text field
class AmountInputSection extends StatelessWidget {
  final int originalAmount;
  final TextEditingController controller;
  final SubscriptionType selectedType;
  final int totalLessons;
  final int finalAmount;
  final int discountPercent;
  final ValueChanged<int> onAmountChanged;

  const AmountInputSection({
    super.key,
    required this.originalAmount,
    required this.controller,
    required this.selectedType,
    required this.totalLessons,
    required this.finalAmount,
    required this.discountPercent,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    const presets = [200000, 300000, 400000, 500000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('정가', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),

        // Amount preset chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                presets.map((amount) {
                  final isSelected = originalAmount == amount;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: ChoiceChip(
                      label: Text('${amount ~/ 10000}만원'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.text = NumberFormat('#,###').format(amount);
                          onAmountChanged(amount);
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryLight,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '직접 입력',
            suffixText: '원',
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
          ),
          onChanged: (value) {
            final cleanValue = value.replaceAll(',', '');
            onAmountChanged(int.tryParse(cleanValue) ?? 0);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '금액을 입력해주세요';
            }
            return null;
          },
        ),
        if (selectedType == SubscriptionType.package && originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '회당 ${NumberFormat('#,###').format((originalAmount / totalLessons).round())}원',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

/// Start date picker field
class StartDatePickerField extends StatelessWidget {
  final DateTime? startDate;
  final ValueChanged<DateTime> onChanged;

  const StartDatePickerField({
    super.key,
    required this.startDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 M월 d일');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('시작일', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondaryLight),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  startDate != null ? dateFormat.format(startDate!) : '날짜 선택',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Text input formatter for thousands separator
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(',', '');
    final number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
