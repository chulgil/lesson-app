import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/payment_receipt.dart';
import '../providers/payment_receipt_providers.dart';

/// Receipt list screen — displays payment receipts with month picker filter.
///
/// Notebook × Score layout:
/// - NotebookMasthead with "RECEIPTS" eyebrow
/// - Month picker chip row
/// - Scrollable receipt card list
// ignore: widget-smoke-test
class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  String get _monthLabel =>
      '$_selectedYear년 ${_selectedMonth.toString().padLeft(2, '0')}월';

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(
      teacherPaymentReceiptsProvider(
        year: _selectedYear,
        month: _selectedMonth,
      ),
    );

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.receiptTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          // ── Month picker ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _MonthPickerRow(
              year: _selectedYear,
              month: _selectedMonth,
              label: _monthLabel,
              onPick: _showMonthPicker,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          // ── Receipt list ──
          Expanded(
            child: receiptsAsync.when(
              data: (receipts) {
                if (receipts.isEmpty) {
                  return _EmptyReceiptState(monthLabel: _monthLabel);
                }
                return _ReceiptList(receipts: receipts);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Center(
                    child: Text(
                      '데이터를 불러오지 못했습니다.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    int pickedYear = _selectedYear;
    int pickedMonth = _selectedMonth;

    final result = await showDialog<(int, int)>(
      context: context,
      builder:
          (context) => _MonthPickerDialog(
            initialYear: pickedYear,
            initialMonth: pickedMonth,
          ),
    );

    if (result != null) {
      setState(() {
        _selectedYear = result.$1;
        _selectedMonth = result.$2;
      });
    }
  }
}

// ── Month picker row ──────────────────────────────────────────────────────────

class _MonthPickerRow extends StatelessWidget {
  final int year;
  final int month;
  final String label;
  final VoidCallback onPick;

  const _MonthPickerRow({
    required this.year,
    required this.month,
    required this.label,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.inkQuaternary, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month picker dialog ───────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title: '월 선택',
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space1,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space1,
        AppSpacing.space3,
        AppSpacing.space3,
      ),
      actionsAlignment: MainAxisAlignment.end,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_year년', style: AppTypography.bodyLarge),
              IconButton(
                onPressed: () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final m = i + 1;
              final isSelected = m == _month;
              return GestureDetector(
                onTap: () => setState(() => _month = m),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.paperAccent : Colors.transparent,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    // ignore: unnecessary_brace_in_string_interps
                    '${m}월',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.paper : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.cancel,
            style: TextStyle(color: AppColors.inkSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop((_year, _month)),
          child: Text(
            AppStrings.confirm,
            style: TextStyle(color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

// ── Receipt list ──────────────────────────────────────────────────────────────

class _ReceiptList extends StatelessWidget {
  final List<PaymentReceipt> receipts;

  const _ReceiptList({required this.receipts});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      itemCount: receipts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) => _ReceiptCard(receipt: receipts[index]),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;

  const _ReceiptCard({required this.receipt});

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    final offset = s.length % 3;
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt number
          Text(
            '#${receipt.receiptNumber}',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkTertiary,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // Student · type · amount
          Row(
            children: [
              Expanded(
                child: Text(
                  '${receipt.studentName} · ${receipt.subscriptionType} · ${_formatAmount(receipt.amount)}원',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Date + PDF button
          Row(
            children: [
              Text(
                _formatDate(receipt.paymentDate),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const Spacer(),
              _PdfDownloadButton(receipt: receipt),
            ],
          ),
        ],
      ),
    );
  }
}

// ── PDF download button ───────────────────────────────────────────────────────

class _PdfDownloadButton extends StatelessWidget {
  final PaymentReceipt receipt;

  const _PdfDownloadButton({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final hasPdf = receipt.pdfUrl != null;

    return GestureDetector(
      onTap:
          hasPdf
              ? () => _handleDownload(context)
              : () => _showPdfNotReady(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: hasPdf ? AppColors.paperAccentSoft : AppColors.paperDark,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: hasPdf ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 14,
              color: hasPdf ? AppColors.paperAccent : AppColors.inkTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              AppStrings.receiptDownload,
              style: AppTypography.caption.copyWith(
                color: hasPdf ? AppColors.paperAccent : AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDownload(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF 다운로드 기능은 준비 중입니다.')));
  }

  void _showPdfNotReady(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF가 아직 생성 중입니다. 잠시 후 다시 시도해 주세요.')),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyReceiptState extends StatelessWidget {
  final String monthLabel;

  const _EmptyReceiptState({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '$monthLabel 영수증이 없습니다.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
