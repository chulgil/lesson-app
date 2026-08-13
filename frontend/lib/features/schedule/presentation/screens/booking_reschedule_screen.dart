import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/notifications_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/cancel_reason.dart';
import '../../domain/services/cancellation_credit_policy.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_date_navigator.dart';
import '../widgets/availability/availability_slot_chip_list.dart';
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
  final int
  cancelDeadlineHours; // Free-change window (reschedule_credit_spec §3)

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
    this.cancelDeadlineHours = 12,
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
      appBar: const NotebookDetailAppBar(
        title: AppStrings.bookingRescheduleTitle,
      ),
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
    final outcome = _computeOutcome();

    // Before the deadline → free, regardless of remaining credits
    // (reschedule_credit_spec §3).
    if (!outcome.blocked && outcome.creditUsed == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(color: AppColors.inkSoft),
        child: Row(
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.ink,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.rescheduleNoCreditUsed,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // After the deadline: one credit will be used; warn on the last one.
    final isLastChance = outcome.remainingAfter == 0;
    final cannotReschedule = outcome.blocked;

    if (cannotReschedule) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(color: AppColors.paperAccentSoft),
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
                ? AppColors.paperAccentSoft
                : AppColors.inkSoft,
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
          AvailabilitySlotChipList(
            slots: availableSlots,
            selectedId: _selectedSlot?.id,
            onSelect: (s) => setState(() => _selectedSlot = s),
          ),
        ],
      ),
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
          return const EmptyStateWidget(
            icon: Icons.event_busy,
            title: AppStrings.noAvailableBookingTime,
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
      error:
          (_, __) =>
              const ErrorStateWidget(title: AppStrings.loadDataFailed),
    );
  }

  Widget _buildActionButtons() {
    final canReschedule = !_computeOutcome().blocked;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New booking preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
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
                  canReschedule && !_isLoading ? _handleReschedule : null,
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

  /// Scheduled lesson start datetime (currentDate + currentStartTime).
  DateTime _lessonStart() => DateTime(
    widget.currentDate.year,
    widget.currentDate.month,
    widget.currentDate.day,
    widget.currentStartTime.hour,
    widget.currentStartTime.minute,
  );

  /// Reschedule credit outcome per spec (CancellationCreditPolicy = SSOT).
  /// A reschedule is a student-reason change: free before the deadline, one
  /// credit after, blocked after the deadline with no credits left
  /// (reschedule_credit_spec §3).
  CancellationCreditOutcome _computeOutcome() =>
      const CancellationCreditPolicy().compute(
        reason: CancelReason.studentSchedule,
        lessonStart: _lessonStart(),
        now: DateTime.now(),
        deadlineHours: widget.cancelDeadlineHours,
        usedReschedule: widget.totalReschedules - widget.remainingReschedules,
        maxReschedule: widget.totalReschedules,
      );

  Future<void> _handleReschedule() async {
    // Re-evaluate at tap time in case the lesson crossed the deadline while
    // the screen was open.
    final outcome = _computeOutcome();
    if (outcome.blocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.bookingRescheduleImpossible)),
        );
      }
      return;
    }

    // Confirm only when this change will consume the last credit (after the
    // deadline). Before-deadline changes are free — no dialog.
    if (outcome.creditUsed > 0 && outcome.remainingAfter == 0) {
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

    await _performReschedule(outcome);
  }

  Future<void> _performReschedule(CancellationCreditOutcome outcome) async {
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

      // 3. Deduct a credit only when the policy charges this change (after
      //    the deadline). Before-deadline changes are free
      //    (reschedule_credit_spec §3) — no deduction, no usage notification.
      if (outcome.creditUsed > 0) {
        int newRemainingReschedules = widget.remainingReschedules - 1;
        if (widget.subscriptionId != null) {
          final updated = await ref
              .read(subscriptionNotifierProvider(widget.studentId).notifier)
              .useReschedule(widget.subscriptionId!);
          newRemainingReschedules = updated.remainingReschedule;
        }

        // 4. Notify about reschedule allowance usage.
        await _sendRescheduleNotification(newRemainingReschedules);
      }

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
