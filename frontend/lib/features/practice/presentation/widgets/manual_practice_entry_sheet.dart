import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../providers/practice_recording_provider.dart';

/// #405 — 수동 연습 기록 입력 시트.
///
/// 메트로놈/튜너 외 오프라인 연습(악기 단독 연습 등)을 학생이 직접 기록한다.
/// 분(필수) + 날짜(기본 오늘) + 메모(선택)를 받아
/// [PracticeSourceLoggers.logManual] 로 heatmap/streak/quest 에 반영한다.
class ManualPracticeEntrySheet extends ConsumerStatefulWidget {
  const ManualPracticeEntrySheet({super.key, required this.studentId});

  final String studentId;

  /// Returns true when a practice log was saved.
  static Future<bool?> show(BuildContext context, {required String studentId}) {
    return showNotebookModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ManualPracticeEntrySheet(studentId: studentId),
    );
  }

  @override
  ConsumerState<ManualPracticeEntrySheet> createState() =>
      _ManualPracticeEntrySheetState();
}

class _ManualPracticeEntrySheetState
    extends ConsumerState<ManualPracticeEntrySheet> {
  final _minutesController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final value = int.tryParse(_minutesController.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: AppStrings.manualPracticeDateLabel,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final minutes = _minutes;
    if (minutes == null) {
      setState(() => _error = AppStrings.manualPracticeInvalidMinutes);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _noteController.text.trim();
    try {
      await ref
          .read(practiceSourceLoggersProvider)
          .logManual(
            studentId: widget.studentId,
            durationMinutes: minutes,
            note: note.isEmpty ? null : note,
            occurredAt: _date,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.manualPracticeSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.manualPracticeTitle,
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.space4),
            // Date row — defaults to today, tap to change.
            InkWell(
              onTap: _saving ? null : _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      AppStrings.manualPracticeDateLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(formatDateYMD(_date), style: AppTypography.bodyMedium),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            // Minutes — required.
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: AppStrings.manualPracticeMinutesLabel,
                hintText: AppStrings.manualPracticeMinutesHint,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppSpacing.space3),
            // Note — optional.
            TextField(
              controller: _noteController,
              enabled: !_saving,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: AppStrings.memoOptional,
                hintText: AppStrings.memoHint,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child:
                        _saving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
