import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/notifications_facade.dart';
import '../../../subscription/subscription_facade.dart';
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

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.bookingRescheduleTitle),
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
                error:
                    (error, _) => Center(
                      child: Text(
                        AppStrings.cannotLoadData,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.currentBookingLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              const Icon(Icons.event, size: 20, color: AppColors.paperAccent),
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
              color: AppColors.inkSecondary,
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
          color: AppColors.paperAccent.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            const Icon(Icons.block, color: AppColors.paperAccent, size: 20),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.bookingRescheduleQuotaUsed(
                  widget.totalReschedules - widget.remainingReschedules,
                  widget.totalReschedules,
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
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
        color:
            isLastChance
                ? AppColors.paperAccent.withValues(alpha: 0.1)
                : AppColors.ink.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Icon(
            isLastChance ? Icons.warning_amber : Icons.swap_horiz,
            color: isLastChance ? AppColors.paperAccent : AppColors.ink,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            isLastChance
                ? AppStrings.rescheduleLastChanceWithCount(
                  widget.remainingReschedules,
                  widget.totalReschedules,
                )
                : AppStrings.bookingRescheduleAvailable(
                  widget.remainingReschedules,
                  widget.totalReschedules,
                ),
            style: AppTypography.bodyMedium.copyWith(
              color: isLastChance ? AppColors.paperAccent : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelection(List<AvailabilitySlot> slots) {
    // Filter out unavailable slots
    final availableSlots =
        slots
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
            AppStrings.selectNewTimeLabel,
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
      children:
          slots.map((slot) {
            final isSelected = _selectedSlot?.id == slot.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.paperAccent : AppColors.paperDark,
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (slot.isRecommended && !isSelected) ...[
                      Text('⭐', style: AppTypography.bodySmall),
                      const SizedBox(width: AppSpacing.space1),
                    ],
                    Text(
                      slot.formattedStartTime,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? AppColors.paper : AppColors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
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
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  AppStrings.noAvailableBookingTime,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Convert dates to DateSuggestion format
        final suggestions =
            dates
                .map(
                  (date) => DateSuggestion(
                    date: date,
                    availableSlots: const [], // Will be loaded when selected
                  ),
                )
                .toList();

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
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.loadDataFailed,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canReschedule = widget.remainingReschedules > 0;
    final isLastChance = widget.remainingReschedules == 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New booking preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.afterChangeDateTime(
                      _selectedSlot!.formattedDate,
                      _selectedSlot!.formattedStartTime,
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
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
              onPressed:
                  canReschedule && !_isLoading
                      ? () => _handleReschedule(isLastChance)
                      : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space4,
                ),
                shape: RoundedRectangleBorder(),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.paper,
                          ),
                        ),
                      )
                      : Text(
                        AppStrings.bookingRescheduleAction,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.paper,
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
      final confirmed = await showNotebookDialog<bool>(
        context: context,
        title: AppStrings.bookingRescheduleLastChanceDialogTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.rescheduleUsageStatusWithColon(
                widget.totalReschedules - widget.remainingReschedules,
                widget.totalReschedules,
              ),
              style: AppTypography.bodyMedium,
            ),
            Text(
              AppStrings.rescheduleAfterChangeMarker(widget.totalReschedules),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            const Text(AppStrings.rescheduleNoMoreAfter),
          ],
        ),
        cancelLabel: AppStrings.cancel,
        onCancel: () => Navigator.pop(context, false),
        confirmLabel: AppStrings.changeAction,
        onConfirm: () => Navigator.pop(context, true),
      );

      if (confirmed != true) return;
    }

    await _performReschedule();
  }

  Future<void> _performReschedule() async {
    if (_selectedSlot == null) return;

    setState(() => _isLoading = true);

    final newSlotId = _selectedSlot!.id;
    // Set when the old-booking cancel failed AND the rollback (cancelling the
    // freshly booked new slot) also failed — the student may now hold two
    // active reservations and must be warned explicitly.
    var rollbackFailed = false;

    try {
      // Atomicity: book the new slot FIRST. Only cancel the old booking once
      // the new one is confirmed, so a failure here never loses the original.
      final notifier = ref.read(slotBookingNotifierProvider.notifier);

      // 1. Create new booking
      await notifier.bookSlotSimple(
        newSlotId,
        widget.studentId,
        widget.studentName,
      );
      // bookSlotSimple swallows errors into AsyncValue.error; surface it.
      if (ref.read(slotBookingNotifierProvider).hasError) {
        throw Exception('new slot booking failed');
      }

      // 2. Cancel old booking. If this fails, roll back the new booking
      //    so we never end up with two active reservations.
      try {
        await notifier.cancelBooking(widget.currentBookingId);
        if (ref.read(slotBookingNotifierProvider).hasError) {
          throw Exception('old booking cancel failed');
        }
      } catch (cancelError) {
        // Roll back the new booking so we never end up with two active
        // reservations. If the rollback itself fails, the new slot is still
        // booked alongside the old one — flag it so the user is told to check.
        try {
          await notifier.cancelBooking(newSlotId);
          if (ref.read(slotBookingNotifierProvider).hasError) {
            rollbackFailed = true;
          }
        } catch (_) {
          rollbackFailed = true;
        }
        rethrow;
      }

      // 3. 🆕 Deduct reschedule allowance from subscription (only after the
      //    slot swap succeeded).
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
              AppStrings.bookingRescheduledTo(
                _selectedSlot!.formattedDate,
                _selectedSlot!.formattedStartTime,
              ),
            ),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rollbackFailed
                  ? AppStrings.bookingRescheduleRollbackFailed
                  : AppStrings.bookingRescheduleFailed,
            ),
            backgroundColor: AppColors.paperAccent,
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
        title: AppStrings.rescheduleCreditsAllUsedTitle,
        body: AppStrings.rescheduleCreditsAllUsedBody,
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
        title: AppStrings.rescheduleCreditLastOneTitle,
        body: AppStrings.rescheduleCreditLastOneBody,
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
