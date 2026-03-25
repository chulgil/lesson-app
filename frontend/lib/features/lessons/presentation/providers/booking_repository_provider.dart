import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../schedule/domain/repositories/booking_repository.dart';
import '../../../schedule/data/repositories/remote_booking_repository.dart';

/// Booking repository provider - switches between Mock and Remote.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) =>
    createRepository<BookingRepository>(
      ref: ref,
      mock: () => MockBookingRepository(),
      remote: (api) => RemoteBookingRepository(api),
    ));
