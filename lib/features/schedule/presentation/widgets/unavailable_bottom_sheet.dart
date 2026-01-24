import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';

/// Bottom sheet for marking booking as unavailable with optional time suggestions.
class UnavailableBottomSheet extends ConsumerStatefulWidget {
  final String teacherId;

  const UnavailableBottomSheet({super.key, required this.teacherId});

  @override
  ConsumerState<UnavailableBottomSheet> createState() =>
      _UnavailableBottomSheetState();
}

class _UnavailableBottomSheetState
    extends ConsumerState<UnavailableBottomSheet> {
  UnavailableReason? _selectedReason;
  final Set<TimeSlot> _selectedSlots = {};
  bool _showTimeSelection = false;

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.screenPadding,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppSpacing.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '일정 조율 안내',
                    style: AppTypography.headingMedium,
                  ),
                  if (_showTimeSelection)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showTimeSelection = false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('이전'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              if (!_showTimeSelection) ...[
                // Step 1: Select reason
                Text(
                  '학생에게 전달할 사유를 선택해주세요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                ...UnavailableReason.values.map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedReason = reason;
                            _showTimeSelection = true;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          side: BorderSide(
                            color: _selectedReason == reason
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: _selectedReason == reason ? 2 : 1,
                          ),
                        ),
                        tileColor: _selectedReason == reason
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                        leading: Icon(
                          Icons.schedule,
                          color: _selectedReason == reason
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                        ),
                        title: Text(reason.label),
                        subtitle: Text(
                          reason.studentMessage,
                          style: AppTypography.caption,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    )),
              ] else ...[
                // Step 2: Select alternative times
                Text(
                  '대안 시간을 제안해주세요 (선택)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '대안 시간을 제안하면 학생이 더 쉽게 다른 시간을 선택할 수 있어요',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Available time slots
                availabilityAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return _buildNoSlotsMessage();
                    }
                    return _buildTimeSlotGrid(slots);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildNoSlotsMessage(),
                ),

                const SizedBox(height: AppSpacing.space3),

                // Manual time input button
                OutlinedButton.icon(
                  onPressed: _showManualTimeInputDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('직접 시간 추가'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Selected slots display
                if (_selectedSlots.isNotEmpty) ...[
                  Text(
                    '선택된 대안 시간 (${_selectedSlots.length}개)',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: _selectedSlots.map((slot) {
                      return Chip(
                        label: Text(slot.displayLabel),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selectedSlots.remove(slot));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Submit without suggestions
                          Navigator.pop(context, (
                            reason: _selectedReason!,
                            suggestedSlots: <TimeSlot>[],
                          ));
                        },
                        child: const Text('대안 없이 전송'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedSlots.isNotEmpty
                            ? () {
                                Navigator.pop(context, (
                                  reason: _selectedReason!,
                                  suggestedSlots: _selectedSlots.toList(),
                                ));
                              }
                            : null,
                        child: Text(_selectedSlots.isNotEmpty
                            ? '대안과 함께 전송'
                            : '시간을 선택하세요'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.space4),
              if (!_showTimeSelection)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSlotsMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 32, color: AppColors.textTertiaryLight),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '등록된 가용 시간이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '프로필 > 레슨 시간 설정에서 가용 시간을 등록하세요',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlot> slots) {
    // Group slots by day
    final slotsByDay = <int, List<TimeSlot>>{};
    for (final slot in slots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    final days = slotsByDay.keys.toList()..sort();

    return Column(
      children: days.map((day) {
        final daySlots = slotsByDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              daySlots.first.fullDayName,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: daySlots.map((slot) {
                final isSelected = _selectedSlots.contains(slot);
                return FilterChip(
                  label: Text(slot.timeRange),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSlots.add(slot);
                      } else {
                        _selectedSlots.remove(slot);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _showManualTimeInputDialog() async {
    // Step 1: Select date
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (selectedDate == null || !mounted) return;

    // Step 2: Select start time
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      helpText: '시작 시간',
      cancelText: '취소',
      confirmText: '다음',
    );

    if (startTime == null || !mounted) return;

    // Step 3: Select end time
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
      helpText: '종료 시간',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (endTime == null || !mounted) return;

    // Validate end time is after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Create custom time slot
    final customSlot = TimeSlot(
      id: 'custom_${selectedDate.toIso8601String()}_${startTime.hour}',
      dayOfWeek: selectedDate.weekday,
      startTime: startTime,
      endTime: endTime,
      isActive: true,
      specificDate: selectedDate,
    );

    setState(() {
      _selectedSlots.add(customSlot);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_formatDate(selectedDate)} ${customSlot.timeRange} 추가됨',
          ),
          backgroundColor: AppColors.practiceGood,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}/${date.day}(${weekdays[date.weekday]})';
  }
}
