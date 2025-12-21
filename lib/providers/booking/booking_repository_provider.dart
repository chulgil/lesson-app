import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/booking_repository.dart';

/// Booking repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository();
});
