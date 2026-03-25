/// Booking Shared Kernel — shared types for schedule ↔ lessons interop.
///
/// Both features import from here; neither imports the other directly.
///
/// Usage:
///   import 'package:lesson_app/core/booking/booking.dart';
library;

export 'entities/lesson_booking.dart';
export 'entities/time_slot.dart';
export 'repositories/booking_repository.dart';
