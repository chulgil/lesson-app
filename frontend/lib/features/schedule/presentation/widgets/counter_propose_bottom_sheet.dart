import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import 'schedule_slot_picker.dart';

/// Bottom sheet for proposing alternative time slots to a student.
///
/// Allows teacher to select up to 3 alternative slots and add an optional message.
class CounterProposeBottomSheet extends ConsumerStatefulWidget {
  final UnifiedLessonRequest request;
  final VoidCallback? onComplete;

  const CounterProposeBottomSheet({
    super.key,
    required this.request,
    this.onComplete,
  });

  @override
  ConsumerState<CounterProposeBottomSheet> createState() =>
      _CounterProposeBottomSheetState();
}

class _CounterProposeBottomSheetState
    extends ConsumerState<CounterProposeBottomSheet> {
  final _selectedSlots = <TimeSlotOption>[];
  final _messageController = TextEditingController();

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
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '대안 시간 선택 (${_selectedSlots.length}/3)',
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
          // Scrollable content: picker + chips
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ScheduleSlotPicker(
                    teacherId: widget.request.teacherId,
                    selectedDay: _selectedSlots.isNotEmpty
                        ? _selectedSlots.last.dayOfWeek
                        : null,
                    selectedTime: _selectedSlots.isNotEmpty
                        ? _selectedSlots.last.startTime
                        : null,
                    onSlotSelected: (slot) {
                      setState(() {
                        final existing = _selectedSlots.indexWhere(
                          (s) =>
                              s.dayOfWeek == slot.dayOfWeek &&
                              s.startTime == slot.startTime,
                        );
                        if (existing >= 0) {
                          _selectedSlots.removeAt(existing);
                        } else if (_selectedSlots.length < 3) {
                          _selectedSlots.add(TimeSlotOption(
                            id: 'ts_${DateTime.now().millisecondsSinceEpoch}_${_selectedSlots.length}',
                            dayOfWeek: slot.dayOfWeek,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                          ));
                        }
                      });
                    },
                  ),
                  if (_selectedSlots.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space4),
                      child: Wrap(
                        spacing: 8,
                        children: _selectedSlots
                            .map((s) => Chip(
                                  label: Text('${s.dayLabel} ${s.startTime}',
                                      style: AppTypography.caption),
                                  deleteIcon:
                                      const Icon(Icons.close, size: 16),
                                  onDeleted: () =>
                                      setState(() => _selectedSlots.remove(s)),
                                ))
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: TextField(
                      controller: _messageController,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '메모 (선택)',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed bottom button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space4,
              MediaQuery.of(context).padding.bottom + AppSpacing.space4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedSlots.isNotEmpty ? _submit : null,
                child: Text('대안 ${_selectedSlots.length}개 제안하기'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.proposeAlternatives(
        widget.request.id,
        widget.request.teacherId,
        widget.request.studentId,
        slots: _selectedSlots,
        message: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('대안 ${_selectedSlots.length}개를 제안했습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Shows the counter-propose bottom sheet.
Future<void> showCounterProposeBottomSheet(
  BuildContext context,
  UnifiedLessonRequest request, {
  VoidCallback? onComplete,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => CounterProposeBottomSheet(
        request: request,
        onComplete: onComplete,
      ),
    ),
  );
}
