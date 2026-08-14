import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_alert_dialog.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/price_input.dart';
import '../../domain/entities/refund_request.dart';
import '../providers/refund_request_providers.dart';
import 'refund_reject_reason_dialog.dart';

/// Teacher-side refund processing box — shown at the top of the
/// subscription detail screen while a refund request is `requested`
/// (#1271). Account info is unmasked here ([RefundRequest.isActionable]).
class RefundActionBox extends ConsumerStatefulWidget {
  final RefundRequest request;

  /// Reference-only estimate, prefilled into the amount field for
  /// convenience — the teacher can still edit it before completing.
  final int? estimatedAmount;

  const RefundActionBox({
    super.key,
    required this.request,
    this.estimatedAmount,
  });

  @override
  ConsumerState<RefundActionBox> createState() => _RefundActionBoxState();
}

class _RefundActionBoxState extends ConsumerState<RefundActionBox> {
  late final TextEditingController _amountController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text:
          widget.estimatedAmount != null
              ? formatPriceWithCommas(widget.estimatedAmount!)
              : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _copyAccount() async {
    await Clipboard.setData(ClipboardData(text: widget.request.accountNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.refundActionBoxAccountCopied)),
    );
  }

  Future<void> _complete() async {
    final amount = parsePrice(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.refundActionBoxAmountValidation),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: AppStrings.refundActionBoxCompleteConfirmTitle,
            content: const Text(AppStrings.refundActionBoxCompleteConfirmBody),
            confirmLabel: AppStrings.refundActionBoxComplete,
            cancelLabel: AppStrings.cancel,
            onConfirm: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(refundRequestActionsProvider)
          .complete(id: widget.request.id, processedAmount: amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.refundActionBoxCompleteSuccess),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.refundActionBoxCompleteFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const RefundRejectReasonDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(refundRequestActionsProvider)
          .reject(id: widget.request.id, rejectReason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.refundActionBoxRejectSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.refundActionBoxRejectFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.refundActionBoxTitle,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          _AccountRow(
            bankName: request.bankName,
            accountNumber: request.accountNumber,
            accountHolder: request.accountHolder,
            onCopy: _copyAccount,
          ),
          if (widget.estimatedAmount != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '${AppStrings.refundRequestEstimateLabel}: '
              '${formatWonWithComma(widget.estimatedAmount!)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              request.reason!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.refundActionBoxAmountLabel,
            style: AppTypography.buttonSmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [const ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              hintText: AppStrings.refundActionBoxAmountHint,
              suffixText: '원',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    foregroundColor: AppColors.paperAccent,
                    side: const BorderSide(color: AppColors.paperAccent),
                  ),
                  child: const Text(AppStrings.refundActionBoxReject),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _complete,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    backgroundColor: AppColors.paperAccent,
                  ),
                  child: const Text(AppStrings.refundActionBoxComplete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final VoidCallback onCopy;

  const _AccountRow({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$bankName $accountNumber ($accountHolder)',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onCopy,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          ),
          icon: const Icon(Icons.copy_outlined, size: 16),
          label: const Text(AppStrings.refundActionBoxAccountCopyLabel),
        ),
      ],
    );
  }
}
