import 'package:json_annotation/json_annotation.dart';
part 'practice_stats.g.dart';

/// Monthly practice statistics entity
@JsonSerializable()
class PracticeStats {
  final int year;
  final int month;
  final int totalDays;
  final int practicedDays;
  final int totalMinutes;
  final double averageMinutesPerDay;

  const PracticeStats({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.practicedDays,
    required this.totalMinutes,
    required this.averageMinutesPerDay,
  });

  factory PracticeStats.fromJson(Map<String, dynamic> json) =>
      _$PracticeStatsFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeStatsToJson(this);

  /// Get achievement rate (0.0 to 1.0)
  double get achievementRate {
    if (totalDays == 0) return 0.0;
    return practicedDays / totalDays;
  }

  /// Get achievement percentage string
  String get achievementPercentage => '${(achievementRate * 100).round()}%';
}
