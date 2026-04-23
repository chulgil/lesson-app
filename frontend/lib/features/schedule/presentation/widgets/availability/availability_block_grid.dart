import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../domain/entities/availability_slot.dart';
import 'availability_block.dart';
import 'availability_legend.dart';

/// Block grid for teacher's availability management
///
/// Displays a grid of time blocks for a single day.
/// Teacher can tap to toggle availability.
class AvailabilityBlockGrid extends StatefulWidget {
  final DateTime date;
  final List<AvailabilitySlot> slots;
  final int slotDurationMinutes;
  final TimeOfDay displayStart;
  final TimeOfDay displayEnd;
  final ValueChanged<TimeOfDay>? onToggle;
  final ValueChanged<List<TimeOfDay>>? onMultipleToggle;

  const AvailabilityBlockGrid({
    super.key,
    required this.date,
    required this.slots,
    this.slotDurationMinutes = 60,
    this.displayStart = const TimeOfDay(hour: 9, minute: 0),
    this.displayEnd = const TimeOfDay(hour: 21, minute: 0),
    this.onToggle,
    this.onMultipleToggle,
  });

  @override
  State<AvailabilityBlockGrid> createState() => _AvailabilityBlockGridState();
}

class _AvailabilityBlockGridState extends State<AvailabilityBlockGrid> {
  final Set<TimeOfDay> _selectedTimes = {};
  bool _isDragging = false;
  bool? _dragSetAvailable;

  // Grid layout info for hit testing
  double _blockWidth = 0;
  double _blockHeight = 50.0;
  int _columns = 1;
  List<List<TimeOfDay>> _currentTimeSlots = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with date and legend
        _buildHeader(),

        const SizedBox(height: AppSpacing.space3),

        // Time grid
        _buildTimeGrid(),

        const SizedBox(height: AppSpacing.space3),

        // Legend
        const AvailabilityLegend(),

        // Selection indicator and save button
        if (_selectedTimes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          _buildSelectionActions(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[widget.date.weekday - 1];
    final dateStr =
        '${widget.date.month}/${widget.date.day}($weekday) 가용 시간 관리';

    // Notebook × Score: 카드 헤더는 Playfair sectionTitle 로 통일
    // (§7.17). dateStr 은 날짜 접두어 + '가용 시간 관리' 고정 접미어로
    // 구조적 역할은 카드 섹션 제목.
    return Text(
      dateStr,
      style: NotebookTypography.sectionTitle.copyWith(color: AppColors.ink),
    );
  }

  Widget _buildTimeGrid() {
    final timeSlots = _generateTimeSlots();
    final has30MinSlots = widget.slotDurationMinutes <= 30;
    final columns = has30MinSlots ? 2 : 1;

    // Store for hit testing
    _currentTimeSlots = timeSlots;
    _columns = columns;

    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
        _dragSetAvailable = null;
        _handleDragAt(details.localPosition);
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          _handleDragAt(details.localPosition);
        }
      },
      onPanEnd: (_) {
        _isDragging = false;
        _dragSetAvailable = null;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final blockWidth =
              (constraints.maxWidth - (columns - 1) * AppSpacing.space2 - 50) /
              columns;
          final blockHeight = 50.0;

          // Store for hit testing
          _blockWidth = blockWidth;
          _blockHeight = blockHeight;

          return Column(
            children: [
              // Header row
              Row(
                children: [
                  const SizedBox(width: 50), // Time label space
                  if (has30MinSlots) ...[
                    SizedBox(
                      width: blockWidth,
                      child: Center(
                        child: Text(
                          ':00',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    SizedBox(
                      width: blockWidth,
                      child: Center(
                        child: Text(
                          ':30',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              // Grid rows
              ...timeSlots.map((hourSlots) {
                final hour = hourSlots.first.hour;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Row(
                    children: [
                      // Hour label
                      SizedBox(
                        width: 50,
                        child: Text(
                          hour.toString().padLeft(2, ' '),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Time blocks
                      ...hourSlots.map((time) {
                        final slot = _findSlot(time);
                        final status =
                            slot?.status ?? AvailabilitySlotStatus.cancelled;
                        final isSelected = _selectedTimes.contains(time);

                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                time != hourSlots.last ? AppSpacing.space2 : 0,
                          ),
                          child: SizedBox(
                            width: blockWidth,
                            height: blockHeight,
                            child: AvailabilityBlock(
                              time: time,
                              status: status,
                              isSelected: isSelected,
                              bookedByName: slot?.bookedByStudentName,
                              onTap: () => _handleTap(time, status),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<List<TimeOfDay>> _generateTimeSlots() {
    final slots = <List<TimeOfDay>>[];
    final startMinutes =
        widget.displayStart.hour * 60 + widget.displayStart.minute;
    final endMinutes = widget.displayEnd.hour * 60 + widget.displayEnd.minute;
    final interval = widget.slotDurationMinutes <= 30 ? 30 : 60;

    var currentHour = widget.displayStart.hour;

    while (currentHour * 60 < endMinutes) {
      final hourSlots = <TimeOfDay>[];

      if (interval == 30) {
        // 30-minute intervals: :00 and :30
        if (currentHour * 60 >= startMinutes) {
          hourSlots.add(TimeOfDay(hour: currentHour, minute: 0));
        }
        if (currentHour * 60 + 30 >= startMinutes &&
            currentHour * 60 + 30 < endMinutes) {
          hourSlots.add(TimeOfDay(hour: currentHour, minute: 30));
        }
      } else {
        // 60-minute intervals: :00 only
        if (currentHour * 60 >= startMinutes) {
          hourSlots.add(TimeOfDay(hour: currentHour, minute: 0));
        }
      }

      if (hourSlots.isNotEmpty) {
        slots.add(hourSlots);
      }
      currentHour++;
    }

    return slots;
  }

  AvailabilitySlot? _findSlot(TimeOfDay time) {
    for (final slot in widget.slots) {
      if (slot.startTime.hour == time.hour &&
          slot.startTime.minute == time.minute) {
        return slot;
      }
    }
    return null;
  }

  void _handleTap(TimeOfDay time, AvailabilitySlotStatus status) {
    // If already selected, deselect
    if (_selectedTimes.contains(time)) {
      setState(() => _selectedTimes.remove(time));
      return;
    }

    // Can only toggle available or cancelled slots
    if (status == AvailabilitySlotStatus.booked ||
        status == AvailabilitySlotStatus.myBooking) {
      return;
    }

    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
      } else {
        _selectedTimes.add(time);
      }
    });
  }

  void _handleDragAt(Offset position) {
    // Calculate which time block the position corresponds to
    final time = _hitTestTimeBlock(position);
    if (time == null) return;

    // Check if this slot can be toggled
    final slot = _findSlot(time);
    final status = slot?.status ?? AvailabilitySlotStatus.cancelled;

    // Can only toggle available or cancelled slots
    if (status == AvailabilitySlotStatus.booked ||
        status == AvailabilitySlotStatus.myBooking) {
      return;
    }

    // First touch determines the action (select or deselect)
    _dragSetAvailable ??= !_selectedTimes.contains(time);

    // Apply consistent action across drag
    setState(() {
      if (_dragSetAvailable!) {
        _selectedTimes.add(time);
      } else {
        _selectedTimes.remove(time);
      }
    });
  }

  /// Hit test to find which time block contains the given position
  TimeOfDay? _hitTestTimeBlock(Offset position) {
    if (_currentTimeSlots.isEmpty || _blockWidth <= 0) return null;

    // Layout constants
    const timeColumnWidth = 50.0;
    const headerHeight = 24.0 + AppSpacing.space2; // Header row + spacing

    // Adjust position for header
    final adjustedY = position.dy - headerHeight;
    if (adjustedY < 0) return null;

    // Calculate row index
    final rowHeight = _blockHeight + AppSpacing.space2;
    final rowIndex = (adjustedY / rowHeight).floor();

    if (rowIndex < 0 || rowIndex >= _currentTimeSlots.length) return null;

    // Calculate column index
    final adjustedX = position.dx - timeColumnWidth;
    if (adjustedX < 0) return null;

    final columnWidth = _blockWidth + AppSpacing.space2;
    final columnIndex = (adjustedX / columnWidth).floor();

    if (columnIndex < 0 || columnIndex >= _columns) return null;

    // Get the time slot
    final hourSlots = _currentTimeSlots[rowIndex];
    if (columnIndex >= hourSlots.length) return null;

    return hourSlots[columnIndex];
  }

  Widget _buildSelectionActions() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_selectedTimes.length}개 시간대 선택됨',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() => _selectedTimes.clear());
          },
          child: const Text(AppStrings.cancel),
        ),
        const SizedBox(width: AppSpacing.space2),
        FilledButton(
          onPressed: () {
            widget.onMultipleToggle?.call(_selectedTimes.toList());
            setState(() => _selectedTimes.clear());
          },
          child: const Text('적용'),
        ),
      ],
    );
  }
}
