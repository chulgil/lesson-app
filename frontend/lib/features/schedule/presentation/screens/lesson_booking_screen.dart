import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/week_calendar_widget.dart';
import '../../../../models/lesson_booking.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_booking_preview.dart';
import '../widgets/availability/empty_slots_suggestion.dart';
import '../widgets/availability/booking_confirm_dialog.dart';
import '../widgets/availability/guest_student_input_dialog.dart';
import '../widgets/availability/no_subscription_view.dart';

/// New lesson booking screen using week calendar + chip selector
///
/// Features:
/// - Week calendar widget (same as student home) with available dates marked
/// - Time slot chips for the selected date
/// - Booking preview and confirmation
class LessonBookingScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String instrument;
  final String? studentId;
  final String? studentName;
  final int? remainingLessons;
  final int? totalLessons;
  final bool isReschedule;
  final bool isTrialLesson;
  final int? remainingReschedules;
  final int? totalReschedules;

  const LessonBookingScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.instrument,
    this.studentId,
    this.studentName,
    this.remainingLessons,
    this.totalLessons,
    this.isReschedule = false,
    this.isTrialLesson = false,
    this.remainingReschedules,
    this.totalReschedules,
  });

  @override
  ConsumerState<LessonBookingScreen> createState() =>
      _LessonBookingScreenState();
}

class _LessonBookingScreenState extends ConsumerState<LessonBookingScreen> {
  late DateTime _selectedDate;
  AvailabilitySlot? _selectedSlot;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _appBarTitle {
    if (widget.isReschedule) return '레슨 변경';
    if (widget.isTrialLesson) return '체험 레슨 예약';
    return '레슨 예약';
  }

  /// Check if this booking requires subscription validation
  bool get _requiresSubscriptionCheck =>
      !widget.isTrialLesson &&
      !widget.isReschedule &&
      widget.studentId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _requiresSubscriptionCheck
            ? _buildWithSubscriptionCheck()
            : _buildBookingContent(),
      ),
    );
  }

  /// Build content with subscription validation for regular lessons
  Widget _buildWithSubscriptionCheck() {
    final subscriptionAsync = ref.watch(
      activeSubscriptionBetweenProvider(
        studentId: widget.studentId!,
        teacherId: widget.teacherId,
      ),
    );

    return subscriptionAsync.when(
      data: (subscription) {
        // No active subscription - show NoSubscriptionView
        if (subscription == null ||
            (subscription.remainingLessons ?? 0) <= 0) {
          return NoSubscriptionView(
            studentId: widget.studentId!,
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            instrument: widget.instrument,
          );
        }

        // Has active subscription - show booking content
        return _buildBookingContent();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '수강권 정보를 확인할 수 없습니다',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextButton(
              onPressed: () => ref.invalidate(
                activeSubscriptionBetweenProvider(
                  studentId: widget.studentId!,
                  teacherId: widget.teacherId,
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the main booking content (calendar + time slots)
  Widget _buildBookingContent() {
    return Column(
      children: [
        // Teacher info header
        _buildTeacherInfo(),

        // Week calendar with available dates
        _buildWeekCalendar(),

        // Time slots for selected date
        Expanded(
          child: _buildTimeSlots(),
        ),
      ],
    );
  }

  Widget _buildTeacherInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.teacherName.isNotEmpty ? widget.teacherName[0] : 'T',
              style: AppTypography.headingSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.teacherName} · ${widget.instrument}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.remainingLessons != null &&
                    widget.totalLessons != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '수강권: ${widget.remainingLessons}/${widget.totalLessons}회',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    // Get available dates for the current month range
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 30));

    final availableDatesAsync = ref.watch(
      availableSlotsForDateRangeProvider(
        teacherId: widget.teacherId,
        startDate: startDate,
        endDate: endDate,
        currentStudentId: widget.studentId,
      ),
    );

    // Convert available slots to dates with available slots
    // Group slots by date and check if any are available
    final availableDates = availableDatesAsync.when(
      data: (slots) {
        final dates = <DateTime>{};
        for (final slot in slots) {
          // Only include dates with available or myBooking slots
          if (slot.status == AvailabilitySlotStatus.available ||
              slot.status == AvailabilitySlotStatus.myBooking) {
            dates.add(DateTime(
              slot.date.year,
              slot.date.month,
              slot.date.day,
            ));
          }
        }
        return dates;
      },
      loading: () => <DateTime>{},
      error: (_, __) => <DateTime>{},
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: WeekCalendarWidget(
        selectedDate: _selectedDate,
        onDateSelected: _onDateChanged,
        availableDates: availableDates, // Show green dot on dates with available slots
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slotsAsync = ref.watch(
      availableSlotsForDateProvider(
        teacherId: widget.teacherId,
        date: _selectedDate,
        currentStudentId: widget.studentId,
      ),
    );

    // Watch subscription if studentId is provided
    final subscriptionAsync = widget.studentId != null
        ? ref.watch(
            bookingSubscriptionProvider(
              studentId: widget.studentId!,
              teacherId: widget.teacherId,
            ),
          )
        : const AsyncValue<dynamic>.data(null);

    // Watch teacher info for fee
    final teacherInfoAsync = ref.watch(
      bookingTeacherInfoProvider(teacherId: widget.teacherId),
    );

    return slotsAsync.when(
      data: (slots) => subscriptionAsync.when(
        data: (subscription) => teacherInfoAsync.when(
          data: (teacher) => _buildSlotContent(slots, subscription, teacher),
          loading: () => _buildSlotContent(slots, subscription, null),
          error: (_, __) => _buildSlotContent(slots, subscription, null),
        ),
        loading: () => _buildSlotContent(slots, null, null),
        error: (_, __) => _buildSlotContent(slots, null, null),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildSlotContent(
    List<AvailabilitySlot> slots,
    dynamic subscription,
    dynamic teacher,
  ) {
    // Only show available slots (not blocked/booked slots)
    final selectableSlots = slots.where(
      (s) =>
          s.status == AvailabilitySlotStatus.available ||
          s.status == AvailabilitySlotStatus.myBooking,
    ).toList();

    // Sort by start time
    selectableSlots.sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    // Get alternative dates if no slots available
    final alternativeDatesAsync = selectableSlots.isEmpty
        ? ref.watch(
            nextAvailableDatesProvider(
              teacherId: widget.teacherId,
              fromDate: _selectedDate.add(const Duration(days: 1)),
            ),
          )
        : const AsyncValue<List<DateTime>>.data([]);

    final alternativeDates = alternativeDatesAsync.when(
      data: (dates) => _buildDateSuggestions(dates),
      loading: () => <DateSuggestion>[],
      error: (_, __) => <DateSuggestion>[],
    );

    // Use subscription data if available, otherwise use widget props
    final int? remaining =
        subscription?.remainingLessons ?? widget.remainingLessons;
    final int? total =
        subscription?.totalLessonsForDisplay ?? widget.totalLessons;

    // Get fee from teacher profile if available
    final int lessonFee = teacher?.regularLessonFee ?? 50000;

    if (selectableSlots.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: EmptySlotsSuggestion(
          selectedDate: _selectedDate,
          suggestions: alternativeDates,
          onDateSelected: _onDateChanged,
        ),
      );
    }

    return Column(
      children: [
        // Time slots (only available slots)
        Expanded(
          child: _buildSlotChips(selectableSlots),
        ),

        // Booking preview (when slot selected)
        if (_selectedSlot != null)
          AvailabilityBookingPreview(
            selectedSlot: _selectedSlot!,
            teacherName: widget.teacherName,
            instrument: widget.instrument,
            remainingLessons: remaining,
            totalLessons: total,
            lessonFee: lessonFee,
            remainingReschedules:
                widget.isReschedule ? widget.remainingReschedules : null,
            totalReschedules:
                widget.isReschedule ? widget.totalReschedules : null,
            onBook: () => _onBook(lessonFee),
            isLoading: _isBooking,
          ),
      ],
    );
  }

  Widget _buildSlotChips(List<AvailabilitySlot> slots) {
    // Group by morning/afternoon if 5+ slots
    final shouldGroup = slots.length >= 5;
    final morningSlots = slots.where((s) => s.isMorning).toList();
    final afternoonSlots = slots.where((s) => s.isAfternoon).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '예약 가능한 시간',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          if (shouldGroup && morningSlots.isNotEmpty) ...[
            // Morning section
            _buildTimeSection('🌅 오전', morningSlots),
            const SizedBox(height: AppSpacing.space4),
          ],

          if (shouldGroup && afternoonSlots.isNotEmpty) ...[
            // Afternoon section
            _buildTimeSection('🌆 오후', afternoonSlots),
          ] else if (!shouldGroup) ...[
            // No grouping - flat list
            _buildChipGrid(slots),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSection(String label, List<AvailabilitySlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildChipGrid(slots),
      ],
    );
  }

  Widget _buildChipGrid(List<AvailabilitySlot> slots) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: slots.map((slot) {
        final isSelected = _selectedSlot?.id == slot.id;
        final isBlocked = slot.status == AvailabilitySlotStatus.booked ||
            slot.status == AvailabilitySlotStatus.past;
        return _TimeChip(
          slot: slot,
          isSelected: isSelected,
          isBlocked: isBlocked,
          onTap: isBlocked ? null : () => _onSlotSelected(slot),
        );
      }).toList(),
    );
  }

  List<DateSuggestion> _buildDateSuggestions(List<DateTime> dates) {
    return dates.map((date) {
      return DateSuggestion(
        date: date,
        availableSlots: [],
      );
    }).toList();
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextButton(
              onPressed: _refresh,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null; // Clear selection when date changes
    });
  }

  void _onSlotSelected(AvailabilitySlot slot) {
    setState(() {
      // Toggle selection
      if (_selectedSlot?.id == slot.id) {
        _selectedSlot = null;
      } else {
        _selectedSlot = slot;
      }
    });
  }

  Future<void> _onBook(int lessonFee) async {
    debugPrint('[BookingScreen] _onBook called, selectedSlot: ${_selectedSlot?.id}');
    if (_selectedSlot == null) return;

    String effectiveStudentId = widget.studentId ?? '';
    String effectiveStudentName = widget.studentName ?? '학생';

    debugPrint('[BookingScreen] studentId: $effectiveStudentId, studentName: $effectiveStudentName');

    // Case 1: Logged-in student booking (has studentId) - show confirmation dialog only
    if (widget.studentId != null) {
      debugPrint('[BookingScreen] Showing confirmation dialog...');
      final confirmed = await BookingConfirmDialog.show(
        context,
        teacherName: widget.teacherName,
        lessonDate: _selectedSlot!.date,
        startTime: _selectedSlot!.formattedStartTime,
        endTime: _selectedSlot!.formattedEndTime,
        remainingReschedules: widget.remainingReschedules,
        totalReschedules: widget.totalReschedules,
        isReschedule: widget.isReschedule,
        isTrialLesson: widget.isTrialLesson,
      );
      debugPrint('[BookingScreen] Confirmation result: $confirmed');
      if (!confirmed) return; // User cancelled
    }
    // Case 2: Teacher booking on behalf of guest student - show guest input dialog
    else {
      debugPrint('[BookingScreen] Showing guest input dialog...');
      final guestInfo = await GuestStudentInputDialog.show(context);
      if (guestInfo == null) return; // User cancelled

      effectiveStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      effectiveStudentName = guestInfo.name;
    }

    debugPrint('[BookingScreen] Starting booking process...');
    setState(() => _isBooking = true);

    try {
      debugPrint('[BookingScreen] Calling slotBookingNotifier.bookSlot...');
      debugPrint('[BookingScreen] slotId: ${_selectedSlot!.id}');
      // Create actual lesson booking with slot info
      await ref.read(slotBookingNotifierProvider.notifier).bookSlot(
            _selectedSlot!.id,
            effectiveStudentId,
            effectiveStudentName,
            teacherId: widget.teacherId,
            teacherName: widget.teacherName,
            slotDate: _selectedSlot!.date,
            slotStartTime: _selectedSlot!.startTime,
            slotEndTime: _selectedSlot!.endTime,
            instrument: widget.instrument,
            lessonType: LessonType.oneTime,
            fee: lessonFee,
          );
      debugPrint('[BookingScreen] Booking succeeded!');

      if (mounted) {
        // Show success message and go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 완료되었습니다. 선생님 확인 후 확정됩니다.'),
            backgroundColor: AppColors.practiceGood,
          ),
        );

        // Go back to previous screen
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  void _refresh() {
    ref.invalidate(
      availableSlotsForDateProvider(
        teacherId: widget.teacherId,
        date: _selectedDate,
        currentStudentId: widget.studentId,
      ),
    );
  }
}

/// Individual time chip
class _TimeChip extends StatelessWidget {
  final AvailabilitySlot slot;
  final bool isSelected;
  final bool isBlocked;
  final VoidCallback? onTap;

  const _TimeChip({
    required this.slot,
    required this.isSelected,
    this.isBlocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(
          minWidth: 88,
          minHeight: 44,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isRecommended && !isSelected && !isBlocked) ...[
              const Text(
                '⭐',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
            ],
            if (isBlocked) ...[
              Icon(
                Icons.block,
                size: 14,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(width: 4),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.formattedTimeRange,
                  style: AppTypography.bodySmall.copyWith(
                    color: _textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isBlocked && slot.bookedByStudentName != null) ...[
                  Text(
                    slot.bookedByStudentName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (isBlocked) {
      return const Color(0xFFF5F5F5); // Light gray for blocked
    }
    if (isSelected) {
      return AppColors.primary;
    }
    if (slot.isRecommended) {
      return const Color(0xFFFFF5EB); // Light orange
    }
    return AppColors.backgroundLight; // #FFFAF5
  }

  Color get _borderColor {
    if (isBlocked) {
      return const Color(0xFFE0E0E0);
    }
    if (isSelected) {
      return AppColors.primary;
    }
    if (slot.isRecommended) {
      return AppColors.secondary; // #F4A460
    }
    return const Color(0xFFE0E0E0);
  }

  Color get _textColor {
    if (isBlocked) {
      return AppColors.textTertiaryLight;
    }
    if (isSelected) {
      return Colors.white;
    }
    return AppColors.textPrimaryLight;
  }
}
