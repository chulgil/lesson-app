// Range picker bottom sheet widget for section forms

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Bottom sheet with iOS-style wheel picker for range selection
class RangePickerSheet extends StatefulWidget {
  final String title;
  final String unit;
  final int initialValue;
  final int maxValue;
  final ValueChanged<int> onSelected;

  const RangePickerSheet({
    super.key,
    required this.title,
    required this.unit,
    required this.initialValue,
    required this.maxValue,
    required this.onSelected,
  });

  @override
  State<RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<RangePickerSheet> {
  late int _selectedValue;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedValue - 1, // 0-indexed
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                Text(widget.title, style: AppTypography.headingSmall),
                TextButton(
                  onPressed: () {
                    widget.onSelected(_selectedValue);
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppStrings.confirm),
                ),
              ],
            ),
          ),

          // Picker
          Expanded(
            child: CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 50,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedValue = index + 1; // 1-indexed
                });
              },
              children: List.generate(
                widget.maxValue,
                (index) => Center(
                  child: Text(
                    '${index + 1} ${widget.unit}',
                    style: AppTypography.headingMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
