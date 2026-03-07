import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_date_navigator.dart';
import '../widgets/availability/empty_slots_suggestion.dart';

/// Booking reschedule screen
///
/// Allows students to change their existing booking to a new time slot.
/// Shows remaining reschedule count and warns when it's the last one.
class BookingRescheduleScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String currentBookingId;
  final DateTime currentDate;
  final TimeOfDay currentStartTime;
  final int remainingReschedules;
  final int totalReschedules;
  final String? instrument;
  final String? subscriptionId; // 🆕 For reschedule count deduction

  const BookingRescheduleScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.currentBookingId,
    required this.currentDate,
    required this.currentStartTime,
    required this.remainingReschedules,
    required this.totalReschedules,
    this.instrument,
    this.subscriptionId,
  });

  @override
  ConsumerState<BookingRescheduleScreen> createState() =>
      _BookingRescheduleScreenState();
}

class _BookingRescheduleScreenState
    extends ConsumerState<BookingRescheduleScreen> {
  late DateTime _selectedDate;
  AvailabilitySlot? _selectedSlot;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentDate;
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(
      availableSlotsForDateProvider(
        teacherId: widget.teacherId,
        date: _selectedDate,
        currentStudentId: widget.studentId,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 변경'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Current booking info
            _buildCurrentBookingInfo(),

            // Reschedule count warning
            _buildRescheduleCountBadge(),

            // Date navigation
            AvailabilityDateNavigator(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedSlot = null;
                });
              },
            ),

            // Slot selection
            Expanded(
              child: slotsAsync.when(
                data: (slots) => _buildSlotSelection(slots),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    '데이터를 불러올 수 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            if (_selectedSlot != null) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBookingInfo() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 예약',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              const Icon(
                Icons.event,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                _formatCurrentBooking(),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${widget.teacherName}${widget.instrument != null ? ' · ${widget.instrument}' : ''}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleCountBadge() {
    final isLastChance = widget.remainingReschedules == 1;
    final cannotReschedule = widget.remainingReschedules <= 0;

    if (cannotReschedule) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.block, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                '변경 불가 (${widget.totalReschedules - widget.remainingReschedules}/${widget.totalReschedules}회 사용완료)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: isLastChance
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            isLastChance ? Icons.warning_amber : Icons.swap_horiz,
            color: isLastChance ? AppColors.warning : AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            isLastChance
                ? '마지막 변경 기회! (${widget.remainingReschedules}/${widget.totalReschedules}회 남음)'
                : '변경 가능: ${widget.remainingReschedules}/${widget.totalReschedules}회',
            style: AppTypography.bodyMedium.copyWith(
              color: isLastChance ? AppColors.warning : AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelection(List<AvailabilitySlot> slots) {
    // Filter out unavailable slots
    final availableSlots = slots
        .where((s) => s.status == AvailabilitySlotStatus.available)
        .toList();

    if (availableSlots.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '새로운 시간 선택',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildSlotChips(availableSlots),
        ],
      ),
    );
  }

  Widget _buildSlotChips(List<AvailabilitySlot> slots) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: slots.map((slot) {
        final isSelected = _selectedSlot?.id == slot.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(
              minWidth: 72,
              minHeight: 44,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (slot.isRecommended && !isSelected) ...[
                  const Text(
                    '⭐',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  slot.formattedStartTime,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    final nextDatesAsync = ref.watch(
      nextAvailableDatesProvider(
        teacherId: widget.teacherId,
        fromDate: _selectedDate,
        limit: 3,
      ),
    );

    return nextDatesAsync.when(
      data: (dates) {
        if (dates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 64,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '예약 가능한 시간이 없습니다',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        // Convert dates to DateSuggestion format
        final suggestions = dates.map((date) => DateSuggestion(
              date: date,
              availableSlots: const [], // Will be loaded when selected
            )).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: EmptySlotsSuggestion(
            selectedDate: _selectedDate,
            suggestions: suggestions,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              });
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActionButtons() {
    final canReschedule = widget.remainingReschedules > 0;
    final isLastChance = widget.remainingReschedules == 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New booking preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '변경 후: ${_selectedSlot!.formattedDate} ${_selectedSlot!.formattedStartTime}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canReschedule && !_isLoading
                  ? () => _handleReschedule(isLastChance)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '예약 변경하기',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReschedule(bool isLastChance) async {
    if (isLastChance) {
      // Show confirmation dialog for last chance
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('마지막 변경 기회입니다'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재: ${widget.totalReschedules - widget.remainingReschedules}/${widget.totalReschedules}회 사용',
                style: AppTypography.bodyMedium,
              ),
              Text(
                '변경 후: ${widget.totalReschedules}/${widget.totalReschedules}회 (마지막)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              const Text('이후 더 이상 변경/취소가 불가합니다.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('변경하기'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await _performReschedule();
  }

  Future<void> _performReschedule() async {
    if (_selectedSlot == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Cancel old booking
      await ref
          .read(slotBookingNotifierProvider.notifier)
          .cancelBooking(widget.currentBookingId);

      // 2. Create new booking
      await ref.read(slotBookingNotifierProvider.notifier).bookSlotSimple(
            _selectedSlot!.id,
            widget.studentId,
            widget.studentName,
          );

      // 3. 🆕 Deduct reschedule allowance from subscription
      int newRemainingReschedules = widget.remainingReschedules - 1;
      if (widget.subscriptionId != null) {
        final updated = await ref
            .read(subscriptionNotifierProvider(widget.studentId).notifier)
            .useReschedule(widget.subscriptionId!);
        newRemainingReschedules = updated.remainingReschedule;
      }

      // 4. 🆕 Send notification about reschedule allowance usage
      await _sendRescheduleNotification(newRemainingReschedules);

      if (mounted) {
        // Show success and pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '예약이 ${_selectedSlot!.formattedDate} ${_selectedSlot!.formattedStartTime}로 변경되었습니다',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 변경에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrentBooking() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[widget.currentDate.weekday - 1];
    final hour = widget.currentStartTime.hour.toString().padLeft(2, '0');
    final minute = widget.currentStartTime.minute.toString().padLeft(2, '0');
    return '${widget.currentDate.month}/${widget.currentDate.day}($weekday) $hour:$minute';
  }

  /// 🆕 Send notification about reschedule allowance usage
  Future<void> _sendRescheduleNotification(int remainingCount) async {
    final notificationService = ref.read(notificationServiceProvider);

    if (remainingCount <= 0) {
      // All reschedules used - send depletion warning
      final notification = AppNotification(
        id: const Uuid().v4(),
        userId: widget.studentId,
        type: NotificationType.rescheduleAllowanceDepleted,
        priority: NotificationPriority.high,
        title: '변경권을 모두 사용했습니다',
        body: '더 이상 레슨 일정을 직접 변경할 수 없습니다. 변경이 필요한 경우 선생님에게 문의해주세요.',
        createdAt: DateTime.now(),
        data: {
          'subscriptionId': widget.subscriptionId,
          'teacherId': widget.teacherId,
        },
      );
      await notificationService.showNotification(notification);
    } else if (remainingCount == 1) {
      // Last reschedule remaining - send warning
      final notification = AppNotification(
        id: const Uuid().v4(),
        userId: widget.studentId,
        type: NotificationType.rescheduleAllowanceUsed,
        priority: NotificationPriority.normal,
        title: '변경권 1회 남음',
        body: '변경권이 1회 남았습니다. 신중하게 사용해주세요.',
        createdAt: DateTime.now(),
        data: {
          'subscriptionId': widget.subscriptionId,
          'remainingCount': remainingCount,
        },
      );
      await notificationService.showNotification(notification);
    }
  }
}
