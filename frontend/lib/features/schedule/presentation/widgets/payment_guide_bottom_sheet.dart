import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Result from the payment guide bottom sheet.
class PaymentGuideResult {
  final bool isMonthly; // true=월정액, false=회차권
  final int totalLessons;
  final int amount;
  final String? message;

  const PaymentGuideResult({
    required this.isMonthly,
    required this.totalLessons,
    required this.amount,
    this.message,
  });
}

/// Bottom sheet for teacher to send payment guide to student.
///
/// Collects: subscription type, total lessons, amount, optional message.
/// Returns [PaymentGuideResult] or null if cancelled.
Future<PaymentGuideResult?> showPaymentGuideBottomSheet(BuildContext context) {
  return showModalBottomSheet<PaymentGuideResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PaymentGuideSheet(),
  );
}

class _PaymentGuideSheet extends StatefulWidget {
  const _PaymentGuideSheet();

  @override
  State<_PaymentGuideSheet> createState() => _PaymentGuideSheetState();
}

class _PaymentGuideSheetState extends State<_PaymentGuideSheet> {
  bool _isMonthly = false; // default: 회차권
  final _lessonsController = TextEditingController(text: '10');
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _lessonsController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final lessons = int.tryParse(_lessonsController.text) ?? 0;
    final amount =
        int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    return lessons > 0 && amount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
            const SizedBox(height: AppSpacing.space4),

            // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
            Text(
              AppStrings.paymentGuideTitle,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space4),

            // Subscription type toggle
            Text(
              '수강권 종류',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    label: AppStrings.subscriptionTypePackage,
                    selected: !_isMonthly,
                    onTap: () => setState(() => _isMonthly = false),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: _buildTypeChip(
                    label: AppStrings.subscriptionTypeMonthly,
                    selected: _isMonthly,
                    onTap: () => setState(() => _isMonthly = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Total lessons
            _buildInputField(
              label: AppStrings.totalLessonsLabel,
              controller: _lessonsController,
              suffix: AppStrings.lessonsUnit,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Amount
            _buildInputField(
              label: AppStrings.amountLabel,
              controller: _amountController,
              suffix: AppStrings.amountUnit,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Optional message
            Text(
              AppStrings.paymentMessageHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.paymentMessageHint,
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.inkQuaternary),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.space3),
              ),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space4),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightSmall,
              child: FilledButton(
                onPressed: _isValid ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  shape: RoundedRectangleBorder(),
                ),
                child: Text(
                  AppStrings.sendPaymentGuide,
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        decoration: BoxDecoration(
          color: selected ? AppColors.paperAccent : AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: selected ? AppColors.paper : AppColors.inkSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.inkQuaternary),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.inkQuaternary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              isDense: true,
            ),
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _submit() {
    final lessons = int.tryParse(_lessonsController.text) ?? 0;
    final amount =
        int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    Navigator.of(context).pop(
      PaymentGuideResult(
        isMonthly: _isMonthly,
        totalLessons: lessons,
        amount: amount,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
      ),
    );
  }
}
