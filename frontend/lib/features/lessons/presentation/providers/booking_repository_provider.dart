import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../repositories/booking_repository.dart';
import '../../../schedule/data/repositories/remote_booking_repository.dart';

/// Booking repository provider - switches between Mock and Remote.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockBookingRepository();
  }
  return RemoteBookingRepository(ref.read(apiClientProvider));
});
