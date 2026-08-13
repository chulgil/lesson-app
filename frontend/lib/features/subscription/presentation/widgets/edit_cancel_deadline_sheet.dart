import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Bottom sheet for editing a subscription's cancel deadline (hours).
class EditCancelDeadlineSheet extends StatefulWidget {
  final int currentHours;
  final Future<void> Function(int hours) onSave;

  const EditCancelDeadlineSheet({
    super.key,
    required this.currentHours,
    required this.onSave,
  });

  @override
  State<EditCancelDeadlineSheet> createState() =>
      _EditCancelDeadlineSheetState();
}

class _EditCancelDeadlineSheetState extends State<EditCancelDeadlineSheet> {
  static const _presets = [4, 12, 24, 48];
  late int _selected;
  late final TextEditingController _customController;
  bool _isCustom = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentHours;
    _isCustom = !_presets.contains(widget.currentHours);
    _customController = TextEditingController(
      text: _isCustom ? widget.currentHours.toString() : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _effectiveHours =>
      _isCustom
          ? (int.tryParse(_customController.text) ?? _selected)
          : _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.editCancelDeadline,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Preset chips
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              ..._presets.map(
                (h) => ChoiceChip(
                  label: Text('$h시간'),
                  selected: !_isCustom && _selected == h,
                  onSelected: (_) {
                    setState(() {
                      _selected = h;
                      _isCustom = false;
                    });
                  },
                  selectedColor: AppColors.paperAccent,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color:
                        (!_isCustom && _selected == h)
                            ? AppColors.paper
                            : AppColors.ink,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text(
                  AppStrings.unifiedSubscriptionDirectInputToggle,
                ),
                selected: _isCustom,
                onSelected: (_) => setState(() => _isCustom = true),
                selectedColor: AppColors.paperAccent,
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: _isCustom ? AppColors.paper : AppColors.ink,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ],
          ),

          if (_isCustom) ...[
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                suffixText: AppStrings.hourSuffix,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: AppColors.paperAccent,
                    width: 1.5,
                  ),
                ),
              ),
              style: AppTypography.bodyMedium,
            ),
          ],

          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed:
                  _saving
                      ? null
                      : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(_effectiveHours);
                          if (context.mounted) Navigator.of(context).pop();
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}
