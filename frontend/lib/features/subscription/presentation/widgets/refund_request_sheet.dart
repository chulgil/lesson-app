import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_bottom_sheet.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../providers/refund_request_providers.dart';

/// Student-side bottom sheet — enter a bank account and submit a refund
/// request for a subscription with remaining lessons (#1271).
class RefundRequestSheet extends ConsumerStatefulWidget {
  final String subscriptionId;
  final String studentId;
  final String teacherId;
  final String studentName;

  /// Reference-only estimate from [estimateRefundAmount] — null when it
  /// couldn't be computed (shown as "계산 불가" rather than hidden).
  final int? estimatedAmount;

  const RefundRequestSheet({
    super.key,
    required this.subscriptionId,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    this.estimatedAmount,
  });

  /// Shows the sheet and returns true when a request was submitted.
  static Future<bool?> show(
    BuildContext context, {
    required String subscriptionId,
    required String studentId,
    required String teacherId,
    required String studentName,
    int? estimatedAmount,
  }) {
    return showNotebookModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => RefundRequestSheet(
            subscriptionId: subscriptionId,
            studentId: studentId,
            teacherId: teacherId,
            studentName: studentName,
            estimatedAmount: estimatedAmount,
          ),
    );
  }

  @override
  ConsumerState<RefundRequestSheet> createState() => _RefundRequestSheetState();
}

class _RefundRequestSheetState extends ConsumerState<RefundRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _selectedDropdownValue;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _bankNameController.addListener(_onBankNameChanged);
  }

  @override
  void dispose() {
    _bankNameController.removeListener(_onBankNameChanged);
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onBankNameChanged() {
    final text = _bankNameController.text.trim();
    if (AppStrings.bankNames.contains(text)) {
      if (_selectedDropdownValue != text) {
        setState(() => _selectedDropdownValue = text);
      }
    } else if (_selectedDropdownValue != AppStrings.bankAccountDirectInput) {
      setState(
        () =>
            _selectedDropdownValue =
                text.isEmpty ? null : AppStrings.bankAccountDirectInput,
      );
    }
  }

  void _onDropdownChanged(String? value) {
    if (value == null) return;
    if (value == AppStrings.bankAccountDirectInput) {
      setState(() {
        _selectedDropdownValue = AppStrings.bankAccountDirectInput;
        _bankNameController.clear();
      });
      FocusScope.of(context).nextFocus();
    } else {
      setState(() {
        _selectedDropdownValue = value;
        _bankNameController.text = value;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(refundRequestActionsProvider)
          .create(
            subscriptionId: widget.subscriptionId,
            studentId: widget.studentId,
            teacherId: widget.teacherId,
            bankName: _bankNameController.text.trim(),
            accountNumber: _accountNumberController.text.trim(),
            accountHolder: _accountHolderController.text.trim(),
            studentName: widget.studentName,
            reason:
                _reasonController.text.trim().isEmpty
                    ? null
                    : _reasonController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message =
          e.toString().contains('진행 중')
              ? AppStrings.refundRequestDuplicateBlocked
              : AppStrings.refundRequestFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scrollable: title + estimate + 4 fields can exceed the sheet's
    // available height on shorter viewports/keyboard-open states.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.refundRequestSheetTitle,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space4),
            _buildEstimateNote(),
            const SizedBox(height: AppSpacing.space4),
            _buildBankNameField(),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.refundRequestAccountNumberLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.refundRequestValidationNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.refundRequestAccountHolderLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.refundRequestValidationHolder;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.refundRequestReasonLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: AppStrings.refundRequestReasonHint,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(AppStrings.refundRequestSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateNote() {
    final amount = widget.estimatedAmount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.refundRequestEstimateLabel,
            style: NotebookTypography.eyebrow.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            amount != null
                ? formatWonWithComma(amount)
                : AppStrings.refundRequestEstimateUnavailable,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.refundRequestEstimateNote,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildBankNameField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDropdownValue,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: AppStrings.refundRequestBankLabel,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space3,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            items: [
              DropdownMenuItem(
                value: AppStrings.bankAccountDirectInput,
                child: Text(
                  AppStrings.bankAccountDirectInput,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
              ...AppStrings.bankNames.map(
                (name) => DropdownMenuItem(
                  value: name,
                  child: Text(name, style: AppTypography.bodySmall),
                ),
              ),
            ],
            onChanged: _onDropdownChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              hintText: AppStrings.profileBankAccountHintBankName,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.refundRequestValidationBank;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
