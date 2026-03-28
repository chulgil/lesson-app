import 'package:flutter/material.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../screens/suggest_alternative_screen.dart';

/// Result from the decline bottom sheet.
typedef DeclineResult = ({String message, List<TimeSlot> suggestedSlots});

/// Shows the unified decline/schedule-negotiation bottom sheet.
///
/// Returns [DeclineResult] with the message and optional suggested time slots,
/// or null if cancelled. Callers handle their own API calls with the result.
Future<DeclineResult?> showDeclineBottomSheet(
  BuildContext context, {
  required int durationMinutes,
  String? teacherId,
}) {
  return showModalBottomSheet<DeclineResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DeclineBottomSheet(
      durationMinutes: durationMinutes,
      teacherId: teacherId,
    ),
  );
}

class _DeclineBottomSheet extends StatefulWidget {
  final int durationMinutes;
  final String? teacherId;

  const _DeclineBottomSheet({
    required this.durationMinutes,
    this.teacherId,
  });

  @override
  State<_DeclineBottomSheet> createState() => _DeclineBottomSheetState();
}

class _DeclineBottomSheetState extends State<_DeclineBottomSheet> {
  final _messageController = TextEditingController(
    text: '현재 가능한 시간이 없어 이번에는 어렵습니다.',
  );

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                '이 시간에 레슨이 어렵습니다',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Message input
              TextField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '학생에게 전달할 메시지',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // CTA buttons
              Row(
                children: [
                  // Send message only (complete rejection, 5%)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sendMessageOnly,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                        side: BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(AppStrings.messageOnly),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  // Suggest alternative times (95%)
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _suggestAlternative,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(AppStrings.counterPropose),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessageOnly() {
    final message = _messageController.text.trim().isEmpty
        ? '현재 가능한 시간이 없어 이번에는 어렵습니다.'
        : _messageController.text.trim();

    Navigator.pop<DeclineResult>(
      context,
      (message: message, suggestedSlots: <TimeSlot>[]),
    );
  }

  Future<void> _suggestAlternative() async {
    final message = _messageController.text.trim().isEmpty
        ? '현재 가능한 시간이 없어 이번에는 어렵습니다.'
        : _messageController.text.trim();

    final suggestedSlots = await Navigator.push<List<TimeSlot>>(
      context,
      MaterialPageRoute(
        builder: (context) => SuggestAlternativeScreen(
          message: message,
          durationMinutes: widget.durationMinutes,
          teacherId: widget.teacherId,
        ),
      ),
    );

    if (suggestedSlots != null && mounted) {
      Navigator.pop<DeclineResult>(
        context,
        (message: message, suggestedSlots: suggestedSlots),
      );
    }
  }
}
