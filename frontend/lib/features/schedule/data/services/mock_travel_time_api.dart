import '../../domain/entities/travel_time_result.dart';
import '../../domain/services/travel_time_api.dart';

/// Mock implementation — returns plausible estimates based on address similarity.
class MockTravelTimeApi implements TravelTimeApi {
  @override
  Future<TravelTimeResult> estimate({
    required String originAddress,
    required String destinationAddress,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simple heuristic: same district → 15min, different district → 30min, different city → 60min
    final originDistrict = _extractDistrict(originAddress);
    final destDistrict = _extractDistrict(destinationAddress);

    if (originDistrict == destDistrict && originDistrict.isNotEmpty) {
      return const TravelTimeResult(
        estimatedMinutes: 15,
        source: 'mock',
        distanceKm: 3.2,
      );
    }

    // Different district in same city
    final originCity = _extractCity(originAddress);
    final destCity = _extractCity(destinationAddress);
    if (originCity == destCity && originCity.isNotEmpty) {
      return const TravelTimeResult(
        estimatedMinutes: 30,
        source: 'mock',
        distanceKm: 8.5,
      );
    }

    return const TravelTimeResult(
      estimatedMinutes: 60,
      source: 'mock',
      distanceKm: 25.0,
    );
  }

  String _extractDistrict(String address) {
    // Extract 구/군 from Korean address
    final parts = address.split(' ');
    for (final p in parts) {
      if (p.endsWith('구') || p.endsWith('군')) return p;
    }
    return '';
  }

  String _extractCity(String address) {
    final parts = address.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }
}
