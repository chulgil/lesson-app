/// Result from travel time estimation API.
class TravelTimeResult {
  final int? estimatedMinutes; // null = unavailable
  final String source; // "kakao" | "naver" | "google" | "mock" | "unavailable"
  final double? distanceKm;

  const TravelTimeResult({
    this.estimatedMinutes,
    this.source = 'unavailable',
    this.distanceKm,
  });

  bool get isAvailable => estimatedMinutes != null;
}
