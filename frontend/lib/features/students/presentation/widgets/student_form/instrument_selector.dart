import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Instrument selector chips.
class InstrumentSelector extends StatelessWidget {
  final String? selectedInstrument;
  final ValueChanged<String?> onChanged;

  /// The expertise catalog to choose from. Callers pass the active discipline's
  /// catalog (`ExpertiseCatalogRegistry.forDiscipline(activeDiscipline).items`),
  /// not a hardcoded music list (#1072). Music resolves byte-identically to the
  /// 22-item instrument catalog; unregistered disciplines degrade to it (#1278).
  final List<String> instruments;

  const InstrumentSelector({
    super.key,
    required this.selectedInstrument,
    required this.onChanged,
    required this.instruments,
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
          selectedColor: AppColors.paperAccentSoft,
          checkmarkColor: AppColors.paperAccent,
          side: BorderSide(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.paperAccent : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
