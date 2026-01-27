import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_chip_selector.dart';
import '../widgets/availability/empty_slots_suggestion.dart';
import '../widgets/availability/guest_student_input_dialog.dart';
import 'booking_confirmation_screen.dart';

/// New lesson booking screen using chip selector
///
/// Replaces the old multi-option schedule selector with
/// a simpler chip-based slot selection.
class LessonBookingScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String instrument;
  final String? studentId;
  final String? studentName;
  final int? remainingLessons;
  final int? totalLessons;
  final bool isReschedule;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReschedule ? '레슨 변경' : '레슨 예약'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Teacher info header
            _buildTeacherInfo(),

            // Main content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
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

  Widget _buildContent() {
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
          data: (teacher) => _buildChipSelector(slots, subscription, teacher),
          loading: () => _buildChipSelector(slots, subscription, null),
          error: (_, __) => _buildChipSelector(slots, subscription, null),
        ),
        loading: () => _buildChipSelector(slots, null, null),
        error: (_, __) => _buildChipSelector(slots, null, null),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildChipSelector(
    List<AvailabilitySlot> slots,
    dynamic subscription,
    dynamic teacher,
  ) {
    // Get alternative dates if no slots available
    final alternativeDatesAsync = slots.isEmpty
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
    final int? remaining = subscription?.remainingLessons ?? widget.remainingLessons;
    final int? total = subscription?.totalLessonsForDisplay ?? widget.totalLessons;

    // Get fee from teacher profile if available
    final int lessonFee = teacher?.regularLessonFee ?? 50000;

    return AvailabilityChipSelector(
      selectedDate: _selectedDate,
      availableSlots: slots,
      selectedSlot: _selectedSlot,
      alternativeDates: alternativeDates,
      teacherName: widget.teacherName,
      instrument: widget.instrument,
      remainingLessons: remaining,
      totalLessons: total,
      lessonFee: lessonFee,
      remainingReschedules:
          widget.isReschedule ? widget.remainingReschedules : null,
      totalReschedules: widget.isReschedule ? widget.totalReschedules : null,
      onDateChanged: _onDateChanged,
      onSlotSelected: _onSlotSelected,
      onBook: _selectedSlot != null ? () => _onBook(lessonFee) : null,
      isLoading: _isBooking,
    );
  }

  List<DateSuggestion> _buildDateSuggestions(List<DateTime> dates) {
    return dates.map((date) {
      // Get slots for this date (async but we'll handle it)
      return DateSuggestion(
        date: date,
        availableSlots: [], // Will be loaded when user selects
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
    if (_selectedSlot == null) return;

    String effectiveStudentId = widget.studentId ?? '';
    String effectiveStudentName = widget.studentName ?? '';

    // If no student info, show guest input dialog
    if (widget.studentId == null || widget.studentName == null) {
      final guestInfo = await GuestStudentInputDialog.show(context);
      if (guestInfo == null) return; // User cancelled

      effectiveStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      effectiveStudentName = guestInfo.name;
    }

    setState(() => _isBooking = true);

    try {
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

      if (mounted) {
        // Navigate to confirmation screen
        final confirmationData = BookingConfirmationData(
          teacherName: widget.teacherName,
          instrument: widget.instrument,
          lessonDate: _selectedSlot!.date,
          startTime: _selectedSlot!.startTime,
          endTime: _selectedSlot!.endTime,
          fee: lessonFee,
          studentName: effectiveStudentName,
          isPending: true,
        );

        // Replace current screen with confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingData: confirmationData,
            ),
          ),
        );
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
