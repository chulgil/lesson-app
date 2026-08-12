import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_date_navigator.dart';
import '../widgets/availability/availability_slot_chip_list.dart';
import '../widgets/availability/empty_slots_suggestion.dart';

/// Parameters for the student first-come direct booking screen.
///
/// See docs/specs/schedule/student_direct_booking_spec.md (#580).
class LessonBookingParams {
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String? instrument;
  final String? subscriptionId;

  const LessonBookingParams({
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    this.instrument,
    this.subscriptionId,
  });
}

/// First-come direct slot booking — student picks an available slot and
/// confirms immediately (schedule_master §3 — 선착순 즉시 확정).
class LessonBookingScreen extends ConsumerStatefulWidget {
  final LessonBookingParams params;

  const LessonBookingScreen({super.key, required this.params});

  @override
  ConsumerState<LessonBookingScreen> createState() =>
      _LessonBookingScreenState();
}

class _LessonBookingScreenState extends ConsumerState<LessonBookingScreen> {
  late DateTime _selectedDate;
  AvailabilitySlot? _selectedSlot;
  bool _isBooking = false;

  /// Booking-time deduction source (#928). Defaults to the regular subscription;
  /// the credit option only appears when the student has spendable credits.
  BookingPaymentSource _paymentSource =
      BookingPaymentSource.regularSubscription;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(
      availableSlotsForDateProvider(
        teacherId: widget.params.teacherId,
        date: _selectedDate,
        currentStudentId: widget.params.studentId,
      ),
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.lessonBookingTitle),
      body: SafeArea(
        child: Column(
          children: [
            AvailabilityDateNavigator(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedSlot = null;
                });
              },
            ),
            Expanded(
              child: slotsAsync.when(
                data: _buildSlots,
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) => Center(
                      child: Text(
                        AppStrings.cannotLoadData,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
              ),
            ),
            if (_selectedSlot != null) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlots(List<AvailabilitySlot> slots) {
    final available =
        slots
            .where((s) => s.status == AvailabilitySlotStatus.available)
            .toList();

    if (available.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.lessonBookingSelectTimeLabel,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AvailabilitySlotChipList(
            slots: available,
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
        teacherId: widget.params.teacherId,
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
        final suggestions =
            dates
                .map(
                  (date) =>
                      DateSuggestion(date: date, availableSlots: const []),
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
          (_, __) => Center(
            child: Text(
              AppStrings.noAvailableBookingTime,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
    );
  }

  Widget _buildBottomBar() {
    final slot = _selectedSlot!;
    final balance = ref.watch(studentMakeupCreditBalanceProvider).valueOrNull;
    return NotebookCard(
      color: AppColors.paperDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.lessonBookingPreview(
                widget.params.teacherName,
                slot.durationMinutes,
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            // #928: choose deduction source when the student has makeup credits.
            if (balance != null && balance.hasAny) ...[
              const SizedBox(height: AppSpacing.space3),
              MakeupCreditUseSelector(
                balance: balance,
                selected: _paymentSource,
                onChanged: (source) => setState(() => _paymentSource = source),
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isBooking ? null : _confirmAndBook,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  backgroundColor: AppColors.paperAccent,
                ),
                child:
                    _isBooking
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.paper,
                          ),
                        )
                        : Text(
                          AppStrings.bookAction,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndBook() async {
    // R3 (D2-class TOCTOU): engage the guard before ANY await, otherwise a
    // double tap on a slow network stacks two confirm dialogs → duplicate
    // bookings. Reset on every early return that keeps the screen alive.
    if (_isBooking) return;
    setState(() => _isBooking = true);
    final slot = _selectedSlot!;
    // #850 belt-and-suspenders — slots are already filtered by lead time in
    // the provider, but re-check here against a stale selection (screen left
    // open past the cutoff). 0 = no restriction.
    final availability = await ref.read(
      teacherAvailabilityProvider(widget.params.teacherId).future,
    );
    final minHours = availability?.minBookingHours ?? 0;
    if (minHours > 0 &&
        slot.startDateTime.isBefore(
          DateTime.now().add(Duration(hours: minHours)),
        )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.lessonBookingTooSoon(minHours)),
          backgroundColor: AppColors.paperAccent,
        ),
      );
      setState(() {
        _isBooking = false;
        _selectedSlot = null;
      });
      return;
    }
    if (!mounted) return;
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.lessonBookingConfirmTitle,
      content: Text(
        AppStrings.lessonBookingConfirmMessage(
          slot.formattedDate,
          slot.formattedStartTime,
        ),
        style: AppTypography.bodyMedium,
      ),
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context, false),
      confirmLabel: AppStrings.bookAction,
      onConfirm: () => Navigator.pop(context, true),
    );
    if (confirmed != true || !mounted) {
      if (mounted) setState(() => _isBooking = false);
      return;
    }

    try {
      final notifier = ref.read(slotBookingNotifierProvider.notifier);
      await notifier.bookSlot(
        slot.id,
        widget.params.studentId,
        widget.params.studentName,
        teacherId: widget.params.teacherId,
        teacherName: widget.params.teacherName,
        slotDate: slot.date,
        slotStartTime: slot.startTime.toFlutterTimeOfDay(),
        slotEndTime: slot.endTime.toFlutterTimeOfDay(),
        instrument: widget.params.instrument,
        lessonType: LessonType.oneTime,
        useCredit: _paymentSource == BookingPaymentSource.makeupCredit,
        subscriptionId: widget.params.subscriptionId,
      );
      if (ref.read(slotBookingNotifierProvider).hasError) {
        throw Exception('slot booking failed');
      }
      // Refresh the slot list so the just-booked slot disappears.
      ref.invalidate(
        availableSlotsForDateProvider(
          teacherId: widget.params.teacherId,
          date: _selectedDate,
          currentStudentId: widget.params.studentId,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.lessonBookingConfirmed(
              slot.formattedDate,
              slot.formattedStartTime,
            ),
          ),
          backgroundColor: AppColors.paperOk,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _selectedSlot = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.lessonBookingFailed),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }
}
