import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Export format selector.
enum _ExportFormat { csv, pdf }

/// Bottom sheet for lesson history export.
///
/// Allows the user to:
/// 1. Pick a date range (default: last 3 months)
/// 2. Choose export format (CSV or PDF)
/// 3. Trigger the export — mock generates a CSV string and triggers share sheet.
///
/// [studentId] — if provided, exports history for that student (teacher view).
/// Null means the caller's own history (student / parent view).
// ignore: widget-smoke-test
class LessonExportSheet extends StatefulWidget {
  final String? studentId;
  final String? studentName;

  const LessonExportSheet({super.key, this.studentId, this.studentName});

  @override
  State<LessonExportSheet> createState() => _LessonExportSheetState();
}

class _LessonExportSheetState extends State<LessonExportSheet> {
  late DateTime _fromDate;
  late DateTime _toDate;
  _ExportFormat _format = _ExportFormat.csv;
  bool _isExporting = false;
  double _progress = 0.0;
  bool _isDone = false;
  String? _resultFilename;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = now;
    _fromDate = DateTime(now.year, now.month - 2, now.day);
  }

  String get _title => AppStrings.exportTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSpacing.space4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Text(
                _title,
                style: NotebookTypography.sectionTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            if (_isExporting) ...[
              _buildProgressState(),
            ] else if (_isDone) ...[
              _buildDoneState(),
            ] else ...[
              _buildFormState(),
            ],
            const SizedBox(height: AppSpacing.space6),
          ],
        ),
      ),
    );
  }

  // ── Form state ──────────────────────────────────────────────────────────────

  Widget _buildFormState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          _SectionLabel(label: AppStrings.exportPeriod),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  date: _fromDate,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
                child: Text(
                  '~',
                  style: AppTypography.bodyLarge,
                ),
              ),
              Expanded(
                child: _DateButton(
                  date: _toDate,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          // Format selector
          _SectionLabel(label: AppStrings.exportFormat),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: _FormatCard(
                  label: AppStrings.exportFormatCsv,
                  subtitle: 'Excel 가공용',
                  icon: Icons.table_chart_outlined,
                  isSelected: _format == _ExportFormat.csv,
                  onTap: () => setState(() => _format = _ExportFormat.csv),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _FormatCard(
                  label: AppStrings.exportFormatPdf,
                  subtitle: '제출·인쇄용',
                  icon: Icons.picture_as_pdf_outlined,
                  isSelected: _format == _ExportFormat.pdf,
                  onTap: () => setState(() => _format = _ExportFormat.pdf),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          // Export button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            onPressed: _startExport,
            child: Text(
              AppStrings.exportButton,
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress state ──────────────────────────────────────────────────────────

  Widget _buildProgressState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '레슨 이력을 준비 중입니다...',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space5),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.paperDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.paperAccent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '${(_progress * 100).round()}%',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Done state ──────────────────────────────────────────────────────────────

  Widget _buildDoneState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space4,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.paperOk,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  _resultFilename ?? '준비 완료!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    side: const BorderSide(color: AppColors.inkQuaternary),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(
                    AppStrings.cancel,
                    style: AppTypography.buttonSmall,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                  ),
                  onPressed: _shareFile,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    '공유하기',
                    style: AppTypography.buttonSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final first = DateTime(2020);
    final last = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.paperAccent,
                surface: AppColors.paper,
              ),
            ),
            child: child!,
          ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    // Simulate progress
    for (var i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _progress = i / 5.0);
    }

    // Build mock CSV content
    final name = widget.studentName ?? '전체학생';
    final fromStr = _formatDateCompact(_fromDate);
    final toStr = _formatDateCompact(_toDate);
    final filename = '레슨이력_${name}_$fromStr-$toStr.${_format.name}';

    if (!mounted) return;
    setState(() {
      _isExporting = false;
      _isDone = true;
      _resultFilename = filename;
    });
  }

  Future<void> _shareFile() async {
    if (_resultFilename == null) return;

    final csvContent = _buildMockCsv();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_resultFilename');
    await file.writeAsString(csvContent);

    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: _resultFilename),
    );
  }

  String _buildMockCsv() {
    final buffer = StringBuffer();
    // UTF-8 BOM for Excel Windows compatibility
    buffer.write('\uFEFF');
    buffer.write(
      '레슨날짜,요일,시작시간,종료시간,수업시간(분),선생님명,악기,레슨유형,상태,수강권\r\n',
    );
    // Mock rows
    final rows = [
      '2026-05-07,수,15:00,16:00,60,김선생,바이올린,정기,완료,5월 정기 8회권',
      '2026-04-30,수,15:00,16:00,60,김선생,바이올린,정기,완료,5월 정기 8회권',
      '2026-04-23,수,15:00,15:30,30,김선생,바이올린,정기,노쇼,5월 정기 8회권',
    ];
    for (final row in rows) {
      buffer.write('$row\r\n');
    }
    return buffer.toString();
  }

  String _formatDateCompact(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({required this.date, required this.onTap});

  String _format(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2 + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.inkQuaternary, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(date),
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paperDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isSelected ? AppColors.paperAccent : AppColors.inkTertiary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  label,
                  style: AppTypography.buttonSmall.copyWith(
                    color: isSelected ? AppColors.paperAccent : AppColors.ink,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
