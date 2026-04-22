import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A chip suggestion with display label and actual value.
class ChipSuggestion {
  /// Display text shown on the chip (e.g., "4회", "20만").
  final String label;

  /// Actual numeric value (e.g., 4, 200000).
  final int value;

  const ChipSuggestion({required this.label, required this.value});
}

/// Smart input field with suggestion chips.
///
/// Chips appear below the text field when focused and hide on blur.
/// Tapping a chip fills the value into the controller, calls [onValueChanged],
/// and unfocuses the field. Users can also type values manually.
///
/// Usage:
/// ```dart
/// ChipInputField(
///   label: '레슨 횟수',
///   hint: '횟수 입력',
///   suffix: '회',
///   controller: _countController,
///   keyboardType: TextInputType.number,
///   suggestions: [
///     ChipSuggestion(label: '4회', value: 4),
///     ChipSuggestion(label: '8회', value: 8),
///     ChipSuggestion(label: '12회', value: 12),
///   ],
///   onValueChanged: (value) => setState(() => _count = value),
/// )
/// ```
class ChipInputField extends StatefulWidget {
  const ChipInputField({
    super.key,
    required this.label,
    this.hint,
    required this.suggestions,
    required this.controller,
    this.onValueChanged,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  /// Label displayed above the text field.
  final String label;

  /// Hint text inside the text field.
  final String? hint;

  /// Suggestion chips shown when focused.
  final List<ChipSuggestion> suggestions;

  /// Controller for the text field value.
  final TextEditingController controller;

  /// Called when a chip is tapped with the chip's [ChipSuggestion.value].
  final ValueChanged<int>? onValueChanged;

  /// Keyboard type for manual input.
  final TextInputType keyboardType;

  /// Suffix text displayed inside the text field (e.g., "회", "원").
  final String? suffix;

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onChipTapped(ChipSuggestion suggestion) {
    widget.controller.text = suggestion.value.toString();
    widget.onValueChanged?.call(suggestion.value);
    _focusNode.unfocus();
  }

  bool _isChipSelected(ChipSuggestion suggestion) {
    return widget.controller.text == suggestion.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixText: widget.suffix,
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.paperAccent),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isFocused ? _buildChipRow() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildChipRow() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFocused ? 1.0 : 0.0,
        child: Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: widget.suggestions.map((suggestion) {
            final selected = _isChipSelected(suggestion);
            return ChoiceChip(
              label: Text(suggestion.label),
              selected: selected,
              onSelected: (_) => _onChipTapped(suggestion),
              backgroundColor: AppColors.paper,
              selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
              checkmarkColor: AppColors.paperAccent,
              side: BorderSide(
                color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: selected
                    ? AppColors.paperAccent
                    : AppColors.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
