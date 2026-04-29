import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_format_utils.dart';
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
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.issueFormTypeSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            _buildTypeChip(
              SubscriptionType.trial,
              AppStrings.issueFormTypeTrialLabel,
              Icons.star_outline,
            ),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.package,
              AppStrings.issueFormTypePackageLabel,
              Icons.confirmation_number_outlined,
            ),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.monthly,
              AppStrings.issueFormTypeMonthlyLabel,
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
            color: isSelected ? AppColors.paperAccentSoft : AppColors.paper,
            border: Border.all(
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkSecondary,
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
        description = AppStrings.issueFormTypeTrialDescription;
        icon = Icons.lightbulb_outline;
      case SubscriptionType.package:
        description = AppStrings.issueFormTypePackageDescription;
        icon = Icons.swap_horiz;
      case SubscriptionType.monthly:
        description = AppStrings.issueFormTypeMonthlyDescription;
        icon = Icons.event_repeat;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
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
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.issueFormPaymentSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _PaymentStatusChip(
                label: AppStrings.issueFormPaymentPrepaidLabel,
                icon: Icons.payment,
                isSelected: isPaymentConfirmed,
                onTap: () => onPaymentConfirmedChanged(true),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _PaymentStatusChip(
                label: AppStrings.issueFormPaymentPostpaidLabel,
                icon: Icons.schedule,
                isSelected: !isPaymentConfirmed,
                onTap: () => onPaymentConfirmedChanged(false),
                accentColor: AppColors.paperAccent,
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
                    selectedColor: AppColors.paperAccent.withValues(
                      alpha: 0.15,
                    ),
                    checkmarkColor: AppColors.paperAccent,
                    backgroundColor: AppColors.paper,
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.inkQuaternary,
                    ),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
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
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.issueFormPaymentPostpaidNotice,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
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
    final color = accentColor ?? AppColors.paperAccent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.paper,
          border: Border.all(
            color: isSelected ? color : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? color : AppColors.inkSecondary,
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
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.issueFormAmountSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
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
                      label: Text(AppStrings.issueFormAmountChipLabel(amount)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.text = formatNumberWithComma(amount);
                          onAmountChanged(amount);
                        }
                      },
                      selectedColor: AppColors.paperAccent.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color:
                            isSelected ? AppColors.paperAccent : AppColors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                      shape: RoundedRectangleBorder(),
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
            hintText: AppStrings.issueFormAmountHint,
            suffixText: AppStrings.issueFormAmountSuffix,
            filled: true,
            fillColor: AppColors.paper,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
          ),
          onChanged: (value) {
            final cleanValue = value.replaceAll(',', '');
            onAmountChanged(int.tryParse(cleanValue) ?? 0);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.issueFormAmountValidation;
            }
            return null;
          },
        ),
        if (selectedType == SubscriptionType.package && originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.issueFormPerLessonAmount(
              formatWonWithComma((originalAmount / totalLessons).round()),
            ),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.issueFormStartDateSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
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
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.inkSecondary),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  startDate != null
                      ? formatDateYMDKorean(startDate!)
                      : AppStrings.issueFormStartDateHint,
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.inkTertiary),
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

    final formatted = formatNumberWithComma(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
