import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/mock_travel_time_api.dart';
import '../../domain/entities/travel_time_result.dart';
import '../../domain/services/travel_time_api.dart';

part 'travel_time_providers.g.dart';

@Riverpod(keepAlive: true)
TravelTimeApi travelTimeApi(Ref ref) {
  return MockTravelTimeApi();
}

/// Estimate travel time between teacher and student addresses.
/// Returns null if either address is missing or API fails.
/// Used by LocationTravelSelector to auto-fill travel time input.
@riverpod
Future<TravelTimeResult?> estimatedTravelTime(
  Ref ref, {
  required String originAddress,
  required String destinationAddress,
}) async {
  if (originAddress.isEmpty || destinationAddress.isEmpty) return null;

  final api = ref.watch(travelTimeApiProvider);
  try {
    return await api.estimate(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
    );
  } catch (_) {
    return null;
  }
}
