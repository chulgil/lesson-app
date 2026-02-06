import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/availability_slot.dart';

/// Individual time block for teacher's availability grid
class AvailabilityBlock extends StatelessWidget {
  final TimeOfDay time;
  final AvailabilitySlotStatus status;
  final bool isSelected;
  final String? bookedByName;
  final VoidCallback? onTap;

  const AvailabilityBlock({
    super.key,
    required this.time,
    required this.status,
    this.isSelected = false,
    this.bookedByName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusIcon,
                style: const TextStyle(fontSize: 16),
              ),
              if (status == AvailabilitySlotStatus.booked &&
                  bookedByName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    bookedByName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canTap {
    return status == AvailabilitySlotStatus.available ||
        status == AvailabilitySlotStatus.cancelled;
  }

  Color get _backgroundColor {
    if (isSelected) {
      return AppColors.primary.withValues(alpha: 0.15);
    }
    switch (status) {
      case AvailabilitySlotStatus.available:
        return const Color(0xFFE8F5E9); // Light green
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return const Color(0xFFE3F2FD); // Light blue
      case AvailabilitySlotStatus.cancelled:
      case AvailabilitySlotStatus.past:
        return const Color(0xFFF5F5F5); // Light gray
    }
  }

  Color get _borderColor {
    switch (status) {
      case AvailabilitySlotStatus.available:
        return const Color(0xFFA5D6A7); // Green border
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return const Color(0xFF90CAF9); // Blue border
      case AvailabilitySlotStatus.cancelled:
      case AvailabilitySlotStatus.past:
        return const Color(0xFFE0E0E0); // Gray border
    }
  }

  String get _statusIcon {
    switch (status) {
      case AvailabilitySlotStatus.available:
        return '🟢';
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return '🔵';
      case AvailabilitySlotStatus.cancelled:
      case AvailabilitySlotStatus.past:
        return '⛔';
    }
  }
}
