import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 학생 게이미피케이션 P1 — "오늘 N분 연습했어요" 수동 입력 다이얼로그.
///
/// 스펙 §6.0 4 경로 wiring / 플랜 Job 3 Task 3.6. Hick's Law 4 옵션 +
/// 직접입력 1개 (총 5 선택지 max). 확인 시 [onConfirm] 콜백으로 분 단위
/// duration + optional note 전달.
class ManualPracticeEntryDialog extends StatefulWidget {
  /// 분 단위 + optional note 를 받는 콜백. 호출자가 [PracticeSourceLoggers.logManual]
  /// 호출 후 dialog dismiss 책임.
  final Future<void> Function(int durationMinutes, String? note) onConfirm;

  static const presetMinutes = <int>[5, 15, 30];

  const ManualPracticeEntryDialog({super.key, required this.onConfirm});

  @override
  State<ManualPracticeEntryDialog> createState() =>
      _ManualPracticeEntryDialogState();
}

class _ManualPracticeEntryDialogState extends State<ManualPracticeEntryDialog> {
  int? _selectedPreset;
  bool _customMode = false;
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _customController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _resolvedMinutes {
    if (_customMode) {
      final parsed = int.tryParse(_customController.text);
      if (parsed != null && parsed > 0) return parsed;
      return null;
    }
    return _selectedPreset;
  }

  Future<void> _confirm() async {
    final minutes = _resolvedMinutes;
    if (minutes == null || _submitting) return;
    setState(() => _submitting = true);
    final note = _noteController.text.trim();
    await widget.onConfirm(minutes, note.isEmpty ? null : note);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('오늘 연습 기록', style: AppTypography.headingSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('얼마나 했어요?', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              for (final m in ManualPracticeEntryDialog.presetMinutes)
                ChoiceChip(
                  key: ValueKey('preset_$m'),
                  label: Text('$m분'),
                  selected: !_customMode && _selectedPreset == m,
                  onSelected:
                      (_) => setState(() {
                        _customMode = false;
                        _selectedPreset = m;
                      }),
                ),
              ChoiceChip(
                key: const ValueKey('preset_custom'),
                label: const Text('직접입력'),
                selected: _customMode,
                onSelected:
                    (_) => setState(() {
                      _customMode = true;
                      _selectedPreset = null;
                    }),
              ),
            ],
          ),
          if (_customMode) ...[
            const SizedBox(height: AppSpacing.space3),
            TextField(
              key: const ValueKey('custom_minutes_input'),
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '분',
                hintText: '예: 45',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          TextField(
            key: const ValueKey('note_input'),
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '예: 왈츠 1악장 연습',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          key: const ValueKey('confirm_button'),
          onPressed:
              (_resolvedMinutes != null && !_submitting) ? _confirm : null,
          child: const Text('기록하기'),
        ),
      ],
    );
  }
}
