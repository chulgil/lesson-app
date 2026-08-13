import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/teacher_availability.dart';

/// Pure preview widget — renders the slots a student would see for the
/// current TeacherAvailability config.
///
/// Used in the Split layout (#433 G5) as the right-side panel. Updates
/// instantly whenever the left settings change (parent rebuilds with a
/// new TeacherAvailability).
///
/// Grid layout:
/// - 7 columns (Mon..Sun)
/// - 1 row per generated slot
/// - Empty days show "쉼" placeholder
class AvailabilityPreviewGrid extends StatelessWidget {
  /// The current availability config to preview.
  final TeacherAvailability availability;

  /// Optional override for lesson duration (SSOT from TeacherSettings).
  /// When provided, slot length uses this value instead of availability.slotDurationMinutes.
  final int? lessonDurationMinutes;

  const AvailabilityPreviewGrid({
    super.key,
    required this.availability,
    this.lessonDurationMinutes,
  });

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final byDay = _groupByDay(availability.weeklySchedules);
    final maxSlots = _computeMaxSlotsForGrid(byDay);
    final hasAnySchedule = byDay.values.any((list) => list.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.space3),
          if (!hasAnySchedule)
            _buildEmptyHint()
          else
            _buildGrid(byDay: byDay, rowCount: maxSlots),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.availabilityPreviewPanel,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          AppStrings.availabilityPreviewHint,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _buildEmptyHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      alignment: Alignment.center,
      child: Text(
        AppStrings.previewEmptyHint,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }

  Widget _buildGrid({
    required Map<int, List<_PreviewSlot>> byDay,
    required int rowCount,
  }) {
    return Column(
      children: [
        // Day header row
        Row(
          children: List.generate(7, (i) {
            final hasAny = byDay[i]?.isNotEmpty == true;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _dayLabels[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        hasAny ? AppColors.paperAccent : AppColors.inkTertiary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Slot rows
        for (int row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(7, (dayIndex) {
                final slots = byDay[dayIndex] ?? const [];
                final slot = row < slots.length ? slots[row] : null;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _PreviewCell(slot: slot),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  /// Generate one preview row per slot start, capped to avoid runaway grids.
  int _computeMaxSlotsForGrid(Map<int, List<_PreviewSlot>> byDay) {
    var max = 0;
    for (final list in byDay.values) {
      if (list.length > max) max = list.length;
    }
    // Cap at 12 rows in the preview to keep the right panel scrollable
    // without dominating the screen.
    return max > 12 ? 12 : max;
  }

  /// Generate slot starts for every active weekly schedule.
  ///
  /// A slot start = startTime, startTime + interval, ... while
  /// (slotStart + slotDurationMinutes) <= endTime.
  Map<int, List<_PreviewSlot>> _groupByDay(List<WeeklySchedule> schedules) {
    final byDay = <int, List<_PreviewSlot>>{};
    for (var i = 0; i < 7; i++) {
      byDay[i] = [];
    }

    final duration = lessonDurationMinutes ?? availability.slotDurationMinutes;
    final interval = lessonDurationMinutes != null
        ? duration + availability.breakTimeBetweenLessons
        : availability.slotStartInterval;
    if (interval <= 0 || duration <= 0) return byDay;

    for (final s in schedules) {
      if (!s.isActive) continue;
      if (s.dayOfWeek < 0 || s.dayOfWeek > 6) continue;
      final startMin = _toMinutes(s.startTime);
      final endMin = _toMinutes(s.endTime);
      if (startMin == null || endMin == null) continue;
      if (endMin <= startMin) continue;

      for (var t = startMin; t + duration <= endMin; t += interval) {
        byDay[s.dayOfWeek]!.add(_PreviewSlot(startMinute: t));
      }
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    }
    return byDay;
  }

  int? _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}

class _PreviewSlot {
  final int startMinute;
  const _PreviewSlot({required this.startMinute});

  String get label {
    final h = (startMinute ~/ 60).toString().padLeft(2, '0');
    final m = (startMinute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PreviewCell extends StatelessWidget {
  final _PreviewSlot? slot;

  const _PreviewCell({required this.slot});

  @override
  Widget build(BuildContext context) {
    if (slot == null) {
      return Container(
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.inkSoft,
        ),
        alignment: Alignment.center,
        child: Text(
          AppStrings.previewDayOff,
          style: AppTypography.captionXSmall.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
      );
    }
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      alignment: Alignment.center,
      child: Text(
        slot!.label,
        style: AppTypography.captionXSmall.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
