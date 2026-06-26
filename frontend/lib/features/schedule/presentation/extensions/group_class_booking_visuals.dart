import 'package:flutter/material.dart';

import '../../domain/entities/group_class_booking.dart';

/// Presentation-layer visuals for [GroupBookingStatus].
///
/// Domain stays pure (no display getters) — the status icon lives here as
/// [IconData] per the C2 consistency contract (no emoji/icon string getters).
extension GroupBookingStatusVisuals on GroupBookingStatus {
  IconData get statusIcon => switch (this) {
    GroupBookingStatus.confirmed => Icons.check_circle,
    GroupBookingStatus.waitlist => Icons.hourglass_empty,
    GroupBookingStatus.attended => Icons.check_circle_outline,
    GroupBookingStatus.noShow => Icons.cancel,
    GroupBookingStatus.cancelled => Icons.close,
    GroupBookingStatus.autoCancelled => Icons.warning_amber,
  };
}
