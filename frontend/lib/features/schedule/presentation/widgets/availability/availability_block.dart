import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_statusIcon, style: AppTypography.bodyLarge),
              if (status == AvailabilitySlotStatus.booked &&
                  bookedByName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    bookedByName!,
                    style: AppTypography.captionXSmall.copyWith(
                      color: AppColors.inkSecondary,
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
      return AppColors.paperAccentSoft;
    }
    switch (status) {
      case AvailabilitySlotStatus.available:
        return AppColors.paperDark;
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return AppColors.paperDark;
      case AvailabilitySlotStatus.cancelled:
        return AppColors.paperAccentSoft;
      case AvailabilitySlotStatus.past:
        return AppColors.paperDark;
    }
  }

  Color get _borderColor {
    switch (status) {
      case AvailabilitySlotStatus.available:
        return AppColors.paperOk;
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return AppColors.inkQuaternary;
      case AvailabilitySlotStatus.cancelled:
        return AppColors.inkQuaternary;
      case AvailabilitySlotStatus.past:
        return AppColors.inkQuaternary;
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
        return '⛔';
      case AvailabilitySlotStatus.past:
        return '⏹️';
    }
  }
}
