import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/availability/availability_block_grid.dart';
import 'time_exception_screen.dart';
import 'weekly_schedule_screen.dart';

/// Teacher availability management screen
///
/// Allows teachers to manage their available time slots
/// using a block grid interface.
class TeacherAvailabilityScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const TeacherAvailabilityScreen({
    super.key,
    required this.teacherId,
  });

  @override
  ConsumerState<TeacherAvailabilityScreen> createState() =>
      _TeacherAvailabilityScreenState();
}

class _TeacherAvailabilityScreenState
    extends ConsumerState<TeacherAvailabilityScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가용 시간 관리'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'weekly':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WeeklyScheduleScreen(),
                    ),
                  );
                  break;
                case 'exception':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TimeExceptionScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_week, size: 20),
                    const SizedBox(width: AppSpacing.space2),
                    Text('주간 스케줄 설정', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'exception',
                child: Row(
                  children: [
                    const Icon(Icons.event_busy, size: 20),
                    const SizedBox(width: AppSpacing.space2),
                    Text('휴무 및 예외 설정', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Quick links
            _buildQuickLinks(),

            // Date navigation
            _buildDateNavigation(),

            // Grid content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildQuickLinkButton(
              icon: Icons.calendar_view_week,
              label: '주간 스케줄',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WeeklyScheduleScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _buildQuickLinkButton(
              icon: Icons.event_busy,
              label: '휴무 설정',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TimeExceptionScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.textSecondaryLight,
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.textSecondaryLight,
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
      ),
    );

    return slotsAsync.when(
      data: (slots) => _buildGrid(slots),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space8),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
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
                onPressed: () {
                  ref.invalidate(availableSlotsForDateProvider(
                    teacherId: widget.teacherId,
                    date: _selectedDate,
                  ));
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<AvailabilitySlot> slots) {
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider(widget.teacherId),
    );

    final duration = availabilityAsync.when(
      data: (availability) => availability?.slotDurationMinutes ?? 60,
      loading: () => 60,
      error: (_, __) => 60,
    );

    return AvailabilityBlockGrid(
      date: _selectedDate,
      slots: slots,
      slotDurationMinutes: duration,
      onToggle: (time) => _handleToggle(time, slots),
      onMultipleToggle: (times) => _handleMultipleToggle(times, slots),
    );
  }

  void _handleToggle(TimeOfDay time, List<AvailabilitySlot> slots) async {
    // Find if this slot is currently available
    final slot = slots.firstWhere(
      (s) =>
          s.startTime.hour == time.hour && s.startTime.minute == time.minute,
      orElse: () => AvailabilitySlot(
        id: '',
        teacherId: widget.teacherId,
        date: _selectedDate,
        startTime: time,
        endTime: time,
        durationMinutes: 60,
        status: AvailabilitySlotStatus.cancelled,
      ),
    );

    final isCurrentlyAvailable =
        slot.status == AvailabilitySlotStatus.available;

    await ref
        .read(teacherAvailabilityNotifierProvider(widget.teacherId).notifier)
        .toggleTimeBlock(_selectedDate, time, !isCurrentlyAvailable);

    // Refresh slots
    ref.invalidate(availableSlotsForDateProvider(
      teacherId: widget.teacherId,
      date: _selectedDate,
    ));
  }

  void _handleMultipleToggle(
    List<TimeOfDay> times,
    List<AvailabilitySlot> slots,
  ) async {
    // Toggle all selected times - default to making them available
    for (final time in times) {
      final slot = slots.firstWhere(
        (s) =>
            s.startTime.hour == time.hour && s.startTime.minute == time.minute,
        orElse: () => AvailabilitySlot(
          id: '',
          teacherId: widget.teacherId,
          date: _selectedDate,
          startTime: time,
          endTime: time,
          durationMinutes: 60,
          status: AvailabilitySlotStatus.cancelled,
        ),
      );

      final isCurrentlyAvailable =
          slot.status == AvailabilitySlotStatus.available;

      await ref
          .read(teacherAvailabilityNotifierProvider(widget.teacherId).notifier)
          .toggleTimeBlock(_selectedDate, time, !isCurrentlyAvailable);
    }

    // Refresh slots
    ref.invalidate(availableSlotsForDateProvider(
      teacherId: widget.teacherId,
      date: _selectedDate,
    ));
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }
}
