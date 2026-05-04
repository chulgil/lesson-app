import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/pencil_primitives.dart';

/// Chip selection widget for goal settings
class GoalSettingChips extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<int> options;
  final String unit;
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final bool allowCustom;

  const GoalSettingChips({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.unit,
    required this.selectedValue,
    required this.onChanged,
    this.allowCustom = true,
  });

  @override
  State<GoalSettingChips> createState() => _GoalSettingChipsState();
}

class _GoalSettingChipsState extends State<GoalSettingChips> {
  final _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    // Check if current value is custom
    if (widget.selectedValue != null &&
        !widget.options.contains(widget.selectedValue)) {
      _showCustomInput = true;
      _customController.text = widget.selectedValue.toString();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(widget.icon, color: AppColors.paperAccent, size: 18),
              const SizedBox(width: AppSpacing.space2),
              Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.selectedValue != null)
                IconButton(
                  onPressed: () {
                    widget.onChanged(null);
                    setState(() {
                      _showCustomInput = false;
                      _customController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    color: AppColors.inkSecondary,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '설정 해제',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Option chips
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              ...widget.options.map((value) => _buildChip(value)),
              if (widget.allowCustom) _buildCustomChip(),
            ],
          ),

          // Custom input
          if (_showCustomInput) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: AppStrings.practiceCustomInputLabel,
                      suffixText: widget.unit,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        widget.onChanged(parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(int value) {
    final isSelected = widget.selectedValue == value;

    return ChoiceChip(
      label: Text('$value${widget.unit}'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          widget.onChanged(value);
          setState(() {
            _showCustomInput = false;
            _customController.clear();
          });
        }
      },
      // Notebook × Score: 선택 상태를 연필 동그라미로 표시.
      avatar: isSelected ? const PencilCircle(size: 16) : null,
      showCheckmark: false,
      selectedColor: AppColors.paperAccent.withAlpha(30),
      backgroundColor: AppColors.paperDark,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: isSelected ? AppColors.paperAccent : AppColors.ink,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? AppColors.paperAccent : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    final isCustomSelected =
        widget.selectedValue != null &&
        !widget.options.contains(widget.selectedValue);

    final isActive = _showCustomInput || isCustomSelected;
    return ChoiceChip(
      label: const Text(AppStrings.practiceCustomInputLabel),
      selected: isActive,
      onSelected: (selected) {
        setState(() {
          _showCustomInput = selected;
          if (!selected) {
            _customController.clear();
            widget.onChanged(null);
          }
        });
      },
      // Notebook × Score: 선택 상태를 연필 동그라미로 표시.
      avatar: isActive ? const PencilCircle(size: 16) : null,
      showCheckmark: false,
      selectedColor: AppColors.paperAccent.withAlpha(30),
      backgroundColor: AppColors.paperDark,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color:
            _showCustomInput || isCustomSelected
                ? AppColors.paperAccent
                : AppColors.ink,
        fontWeight:
            _showCustomInput || isCustomSelected
                ? FontWeight.w600
                : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color:
              _showCustomInput || isCustomSelected
                  ? AppColors.paperAccent
                  : Colors.transparent,
        ),
      ),
    );
  }
}
