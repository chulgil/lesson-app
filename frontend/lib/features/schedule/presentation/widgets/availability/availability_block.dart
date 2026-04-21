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
              Text(_statusIcon, style: const TextStyle(fontSize: 16)),
              if (status == AvailabilitySlotStatus.booked &&
                  bookedByName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    bookedByName!,
                    style: AppTypography.captionXSmall.copyWith(
                      color: AppColors.textSecondaryLight,
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
        return AppColors.successLight;
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return AppColors.infoLight;
      case AvailabilitySlotStatus.cancelled:
        return AppColors.error.withValues(alpha: 0.08);
      case AvailabilitySlotStatus.past:
        return AppColors.surfaceSecondaryLight;
    }
  }

  Color get _borderColor {
    switch (status) {
      case AvailabilitySlotStatus.available:
        return AppColors.successBorder;
      case AvailabilitySlotStatus.booked:
      case AvailabilitySlotStatus.myBooking:
        return AppColors.infoBorder;
      case AvailabilitySlotStatus.cancelled:
        return AppColors.error.withValues(alpha: 0.3);
      case AvailabilitySlotStatus.past:
        return AppColors.borderLight;
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
