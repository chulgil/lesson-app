import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../widgets/booking_card.dart';

/// Screen showing pending booking requests for teacher approval
class PendingBookingsScreen extends ConsumerWidget {
  final String teacherId;

  const PendingBookingsScreen({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBookings = ref.watch(pendingBookingsProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('승인 대기'),
      ),
      body: pendingBookings.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingBookingsProvider(teacherId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  showActions: true,
                  onTap: () {
                    context.push('/schedule/trial/${booking.id}/review');
                  },
                  onApprove: () async {
                    final confirmed = await _showApproveConfirmation(context);
                    if (confirmed && context.mounted) {
                      try {
                        await ref
                            .read(bookingsNotifierProvider.notifier)
                            .approveTrialLesson(booking.id);
                        ref.invalidate(pendingBookingsProvider(teacherId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${booking.studentName}님의 체험레슨이 승인되었습니다'),
                              backgroundColor: AppColors.practiceGood,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('승인 처리 중 오류가 발생했습니다: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  onReject: () async {
                    final result = await showModalBottomSheet<
                        ({UnavailableReason reason, List<TimeSlot> suggestedSlots})>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => _UnavailableBottomSheet(
                        teacherId: booking.teacherId,
                      ),
                    );
                    if (result != null && context.mounted) {
                      try {
                        await ref
                            .read(bookingsNotifierProvider.notifier)
                            .markUnavailable(
                              booking.id,
                              result.reason,
                              suggestedTimeSlots: result.suggestedSlots.isNotEmpty
                                  ? result.suggestedSlots
                                  : null,
                            );
                        ref.invalidate(pendingBookingsProvider(teacherId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.suggestedSlots.isNotEmpty
                                  ? '대안 시간과 함께 학생에게 안내가 전달되었습니다'
                                  : '학생에게 안내가 전달되었습니다'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('처리 중 오류가 발생했습니다: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text('오류가 발생했습니다', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(pendingBookingsProvider(teacherId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '대기 중인 신청이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '새로운 체험레슨 신청이 들어오면\n여기에 표시됩니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _showApproveConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('체험레슨 승인'),
            content: const Text('이 체험레슨 신청을 승인하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('승인'),
              ),
            ],
          ),
        ) ??
        false;
  }

}

/// Bottom sheet for marking booking as unavailable with optional time suggestions
class _UnavailableBottomSheet extends ConsumerStatefulWidget {
  final String teacherId;

  const _UnavailableBottomSheet({required this.teacherId});

  @override
  ConsumerState<_UnavailableBottomSheet> createState() =>
      _UnavailableBottomSheetState();
}

class _UnavailableBottomSheetState
    extends ConsumerState<_UnavailableBottomSheet> {
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
