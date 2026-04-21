import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Instrument selector chips.
class InstrumentSelector extends StatelessWidget {
  final String? selectedInstrument;
  final ValueChanged<String?> onChanged;
  final List<String> instruments;

  const InstrumentSelector({
    super.key,
    required this.selectedInstrument,
    required this.onChanged,
    this.instruments = const [
      '바이올린',
      '피아노',
      '첼로',
      '플루트',
      '클라리넷',
      '비올라',
      '기타',
      '성악',
      '드럼',
      '기타(직접입력)',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: instruments.map((instrument) {
        final isSelected = selectedInstrument == instrument;
        return ChoiceChip(
          label: Text(instrument),
          selected: isSelected,
          onSelected: (selected) {
            onChanged(selected ? instrument : null);
          },
          backgroundColor: AppColors.paper,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.inkQuaternary,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
