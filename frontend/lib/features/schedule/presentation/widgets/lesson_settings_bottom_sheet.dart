import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Bottom sheet for lesson time settings
class LessonSettingsBottomSheet extends StatefulWidget {
  final int currentLessonDuration;
  final int currentStartInterval;
  final int currentBreakTime;

  const LessonSettingsBottomSheet({
    super.key,
    required this.currentLessonDuration,
    required this.currentStartInterval,
    required this.currentBreakTime,
  });

  @override
  State<LessonSettingsBottomSheet> createState() =>
      _LessonSettingsBottomSheetState();
}

class _LessonSettingsBottomSheetState extends State<LessonSettingsBottomSheet> {
  late int _lessonDuration;
  late int _startInterval;
  late int _breakTime;

  @override
  void initState() {
    super.initState();
    _lessonDuration = widget.currentLessonDuration;
    _startInterval = widget.currentStartInterval;
    _breakTime = widget.currentBreakTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

                const SizedBox(height: AppSpacing.space5),

                // Title
                Text('레슨 시간 설정', style: AppTypography.headingMedium),

                const SizedBox(height: AppSpacing.space2),

                Text(
                  '학생들이 예약할 수 있는 시간 단위를 설정합니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Lesson duration
                _buildSettingSection(
                  title: '레슨 시간',
                  description: '한 레슨의 기본 길이',
                  options: [30, 45, 50, 60],
                  selectedValue: _lessonDuration,
                  suffix: '분',
                  onChanged: (value) => setState(() => _lessonDuration = value),
                ),

                const SizedBox(height: AppSpacing.space5),

                // Start interval
                _buildSettingSection(
                  title: '시작 시간 간격',
                  description: '예약 가능한 시작 시간 단위',
                  options: [30, 60],
                  selectedValue: _startInterval,
                  suffix: '분',
                  onChanged: (value) => setState(() => _startInterval = value),
                ),

                const SizedBox(height: AppSpacing.space5),

                // Break time
                _buildSettingSection(
                  title: '레슨 사이 쉬는 시간',
                  description: '레슨과 레슨 사이 휴식 시간',
                  options: [0, 5, 10, 15],
                  selectedValue: _breakTime,
                  suffix: '분',
                  onChanged: (value) => setState(() => _breakTime = value),
                ),

                const SizedBox(height: AppSpacing.space5),

                // Preview
                _buildPreview(),

                const SizedBox(height: AppSpacing.space6),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String description,
    required List<int> options,
    required int selectedValue,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children:
              options.map((value) {
                final isSelected = selectedValue == value;
                return ChoiceChip(
                  label: Text('$value$suffix'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(value);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
    );
  }

  Widget _buildPreview() {
    // Calculate example slots
    final exampleSlots = <String>[];
    var currentMinutes = 10 * 60; // Start at 10:00
    for (var i = 0; i < 4; i++) {
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;
      final endMinutes = currentMinutes + _lessonDuration;
      final endHour = endMinutes ~/ 60;
      final endMinute = endMinutes % 60;
      exampleSlots.add(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}~'
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
      );
      currentMinutes += _startInterval;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '미리보기',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children:
                exampleSlots.map((slot) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(slot, style: AppTypography.bodySmall),
                  );
                }).toList(),
          ),
          if (_startInterval == 30 && _lessonDuration > 30) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.space1),
                Expanded(
                  child: Text(
                    '10:00 예약 시 10:30 슬롯은 자동으로 막힘',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop({
      'lessonDuration': _lessonDuration,
      'startInterval': _startInterval,
      'breakTime': _breakTime,
    });
  }
}
