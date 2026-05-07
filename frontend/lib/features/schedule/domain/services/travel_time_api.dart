import '../entities/travel_time_result.dart';

/// Service for estimating travel time between two addresses.
/// Fallback chain: Kakao → Naver → Google → null.
abstract class TravelTimeApi {
  Future<TravelTimeResult> estimate({
    required String originAddress,
    required String destinationAddress,
  });
}
