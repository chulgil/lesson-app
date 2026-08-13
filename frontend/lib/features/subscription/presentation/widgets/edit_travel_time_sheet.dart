import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Bottom sheet for editing a membership's travel time (minutes).
class EditTravelTimeSheet extends StatefulWidget {
  final int currentMinutes;
  final Future<void> Function(int minutes) onSave;

  const EditTravelTimeSheet({
    super.key,
    required this.currentMinutes,
    required this.onSave,
  });

  @override
  State<EditTravelTimeSheet> createState() => _EditTravelTimeSheetState();
}

class _EditTravelTimeSheetState extends State<EditTravelTimeSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentMinutes.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            AppStrings.editTravelTime,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: AppStrings.travelTimeMinutesSuffix,
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
                        final minutes = int.tryParse(_controller.text) ?? 0;
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(minutes);
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
