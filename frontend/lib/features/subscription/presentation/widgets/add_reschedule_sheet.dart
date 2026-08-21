import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/subscription.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Bottom sheet for granting bonus reschedule credits to a subscription.
class AddRescheduleSheet extends StatefulWidget {
  final Subscription subscription;
  final Future<void> Function(int count) onConfirm;

  const AddRescheduleSheet({
    super.key,
    required this.subscription,
    required this.onConfirm,
  });

  @override
  State<AddRescheduleSheet> createState() => _AddRescheduleSheetState();
}

class _AddRescheduleSheetState extends State<AddRescheduleSheet> {
  int _count = 1;
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
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
            AppStrings.addRescheduleCredit,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Count row
          Row(
            children: [
              Text(
                AppStrings.additionalCount,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _CounterButton(
                value: _count,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _count = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Reason field
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: AppStrings.addReason,
              hintText: AppStrings.scheduleChangeReasonHint,
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
                        setState(() => _saving = true);
                        try {
                          await widget.onConfirm(_count);
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
                      : Text(
                        AppLocalizations.of(
                          context,
                        ).rescheduleAddCountButton(_count),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple +/- counter button for number inputs.
class _CounterButton extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterButton({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
