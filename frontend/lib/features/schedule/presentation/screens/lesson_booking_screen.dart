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
                loading:
                    () => const Center(child: CircularProgressIndicator()),
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
            .toList()
          ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

    if (available.isEmpty) return _buildEmptyState();

    final morning = available.where((s) => s.isMorning).toList();
    final afternoon = available.where((s) => s.isAfternoon).toList();

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
          if (morning.isNotEmpty) ...[
            _GroupLabel(AppStrings.timeAM),
            const SizedBox(height: AppSpacing.space2),
            _SlotChips(
              slots: morning,
              selectedId: _selectedSlot?.id,
              onSelect: (s) => setState(() => _selectedSlot = s),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          if (afternoon.isNotEmpty) ...[
            _GroupLabel(AppStrings.timePM),
            const SizedBox(height: AppSpacing.space2),
            _SlotChips(
              slots: afternoon,
              selectedId: _selectedSlot?.id,
              onSelect: (s) => setState(() => _selectedSlot = s),
            ),
          ],
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
      setState(() => _selectedSlot = null);
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
    if (confirmed != true || !mounted) return;

    setState(() => _isBooking = true);
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

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.inkTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SlotChips extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  final String? selectedId;
  final ValueChanged<AvailabilitySlot> onSelect;

  const _SlotChips({
    required this.slots,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          slots.map((slot) {
            final isSelected = selectedId == slot.id;
            return GestureDetector(
              onTap: () => onSelect(slot),
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
                // 시스템 데이터(시간) → 산세리프. Notebook §7.130 Gaegu 이항 룰.
                child: Text(
                  slot.formattedStartTime,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.paper : AppColors.ink,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
