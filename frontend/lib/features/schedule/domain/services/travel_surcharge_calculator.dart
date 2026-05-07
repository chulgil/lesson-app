/// Calculate suggested travel surcharge based on teacher's hourly rate.
/// This is a REFERENCE suggestion only — teacher decides final amount.
class TravelSurchargeCalculator {
  /// Returns suggested surcharge in KRW, rounded up to nearest 1000.
  /// Returns 0 if travelTime is 0 or negative.
  static int suggestedSurcharge({
    required int travelTimeMinutes,
    required int baseLessonFee,
    required int lessonDurationMinutes,
  }) {
    if (travelTimeMinutes <= 0 || lessonDurationMinutes <= 0) return 0;

    final hourlyRate = baseLessonFee / (lessonDurationMinutes / 60);
    final travelCost = hourlyRate * (travelTimeMinutes / 60);
    return ((travelCost / 1000).ceil() * 1000).toInt();
  }
}
