import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../core/booking/repositories/booking_repository.dart';
import '../../../schedule/data/repositories/remote_booking_repository.dart';

part 'booking_repository_provider.g.dart';

/// Booking repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
BookingRepository bookingRepository(BookingRepositoryRef ref) =>
    createRepository<BookingRepository>(
      ref: ref,
      mock: () => MockBookingRepository(),
      remote: (api) => RemoteBookingRepository(api),
    );
