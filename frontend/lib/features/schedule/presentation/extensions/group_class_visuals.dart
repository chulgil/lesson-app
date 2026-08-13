import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/group_class_booking.dart';
import '../../domain/entities/group_class_schedule.dart';

/// Presentation-layer display text for [GroupClassBooking] and
/// [GroupClassSchedule]. Domain stays pure — formatted strings live here.
extension GroupClassBookingVisuals on GroupClassBooking {
  /// Get status display text
  String get statusText {
    switch (status) {
      case GroupBookingStatus.confirmed:
        return AppStrings.groupClassBookingStatusConfirmed;
      case GroupBookingStatus.waitlist:
        return AppStrings.groupClassBookingStatusWaitlist(waitlistPosition);
      case GroupBookingStatus.attended:
        return AppStrings.attendedLabel;
      case GroupBookingStatus.noShow:
        return AppStrings.absentLabel;
      case GroupBookingStatus.cancelled:
        return AppStrings.groupClassStatusCancelled;
      case GroupBookingStatus.autoCancelled:
        return AppStrings.groupClassBookingStatusAutoCancelled;
    }
  }
}

extension GroupClassScheduleVisuals on GroupClassSchedule {
  /// Get capacity text (e.g., "4/6명")
  String get capacityText => '$currentBookings/$maxCapacity명';

  /// Get status display text
  String get statusText {
    switch (status) {
      case ScheduleStatus.open:
        if (isFull) return AppStrings.capacityFull;
        if (availableSpots <= 2) return AppStrings.capacityAlmostFull;
        return AppStrings.capacityAvailable;
      case ScheduleStatus.full:
        return AppStrings.capacityFull;
      case ScheduleStatus.closed:
        return AppStrings.groupClassScheduleStatusClosed;
      case ScheduleStatus.cancelled:
        return AppStrings.groupClassStatusCancelled;
      case ScheduleStatus.completed:
        return AppStrings.statusCompleted;
      case ScheduleStatus.inProgress:
        return AppStrings.groupClassScheduleStatusInProgress;
    }
  }

  /// Get formatted date text
  String get dateText => formatDateMDWithDay(startTime);

  /// Get formatted time text
  String get timeText =>
      '${formatTimeHM(startTime)} ~ ${formatTimeHM(endTime)}';
}
