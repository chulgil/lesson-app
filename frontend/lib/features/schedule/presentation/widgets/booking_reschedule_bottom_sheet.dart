import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/notifications_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/cancel_reason.dart';
import '../../domain/services/cancellation_credit_policy.dart';
import '../providers/teacher_availability_providers.dart';
import 'availability/availability_date_navigator.dart';
import 'availability/availability_slot_chip_list.dart';
import 'availability/empty_slots_suggestion.dart';

/// Shows the direct-booking reschedule flow as a Notebook-styled bottom sheet.
///
/// #1268 — unifies the entry presentation with the chat-style schedule-change
/// bottom sheets (`showScheduleChangeTypeBottomSheet` /
/// `showScheduleChangeSlotBottomSheet`). Per
/// `docs/specs/schedule/schedule_change_unification_spec.md` §2.3 (C-1,
/// reaffirmed by the 2026-08-13 board decision 4), the direct-booking policy
/// itself stays immediate-confirm — only the presentation (full-screen push →
/// bottom sheet) is unified, not the negotiation/RequestEvent model.
Future<bool?> showBookingRescheduleBottomSheet(
  BuildContext context, {
  required String teacherId,
  required String teacherName,
  required String studentId,
  required String studentName,
  required String currentBookingId,
  required DateTime currentDate,
  required TimeOfDay currentStartTime,
  required int remainingReschedules,
  required int totalReschedules,
  String? instrument,
  String? subscriptionId,
  int cancelDeadlineHours = 12,
}) {
  return showNotebookBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder: (_) => BookingRescheduleSheet(
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: studentId,
      studentName: studentName,
      currentBookingId: currentBookingId,
      currentDate: currentDate,
      currentStartTime: currentStartTime,
      remainingReschedules: remainingReschedules,
      totalReschedules: totalReschedules,
      instrument: instrument,
      subscriptionId: subscriptionId,
      cancelDeadlineHours: cancelDeadlineHours,
    ),
  );
}

/// Bottom sheet content for rescheduling a direct booking.
///
/// Allows students to change their existing booking to a new time slot.
/// Shows remaining reschedule count and warns when it's the last one.
///
/// Public (not `_`-prefixed) so widget tests can pump it directly without
/// driving the modal-route trigger — mirrors how the full-screen predecessor
/// (`BookingRescheduleScreen`, removed by #1268) was tested.
class BookingRescheduleSheet extends ConsumerStatefulWidget {
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
  final String? subscriptionId; // For reschedule count deduction
  final int
  cancelDeadlineHours; // Free-change window (reschedule_credit_spec §3)

  const BookingRescheduleSheet({
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
  ConsumerState<BookingRescheduleSheet> createState() =>
      _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState
    extends ConsumerState<BookingRescheduleSheet> {
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
    final mq = MediaQuery.of(context);

    // proposal_bottom_sheet / schedule_change_slot_bottom_sheet 패턴 —
    // maxHeight 으로 sheet 상한 고정, 내부는 self-surfaced Container.
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.space3),
              child: Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
            ),
            const SizedBox(height: AppSpacing.space2),
            _buildHeader(context),

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
            Flexible(
              child: slotsAsync.when(
                data: (slots) => _buildSlotSelection(slots),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            AppStrings.bookingRescheduleTitle,
            style: NotebookTypography.sectionTitle,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBookingInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
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
        color: isLastChance ? AppColors.paperAccentSoft : AppColors.inkSoft,
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
        final suggestions = dates
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
      error: (_, __) =>
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
              onPressed: canReschedule && !_isLoading
                  ? _handleReschedule
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space4,
                ),
                shape: RoundedRectangleBorder(),
              ),
              child: _isLoading
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
    // the sheet was open.
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

  /// Send notification about reschedule allowance usage
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
