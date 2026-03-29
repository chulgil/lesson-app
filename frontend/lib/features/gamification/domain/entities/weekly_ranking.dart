// Weekly ranking entities for class-level leaderboard.

import 'package:json_annotation/json_annotation.dart';

part 'weekly_ranking.g.dart';

/// Tier for weekly ranking: top 30% gold, next 30% silver, rest bronze.
enum RankingTier {
  gold,
  silver,
  bronze,
}

/// A single student's entry in the weekly ranking.
@JsonSerializable()
class WeeklyRankingEntry {
  final String studentId;
  final String studentName;
  final int weeklyPoints;
  final RankingTier tier;
  final int rank;

  const WeeklyRankingEntry({
    required this.studentId,
    required this.studentName,
    required this.weeklyPoints,
    required this.tier,
    required this.rank,
  });

  factory WeeklyRankingEntry.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRankingEntryFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyRankingEntryToJson(this);
}

/// Weekly ranking for a class with tier-based entries.
@JsonSerializable()
class WeeklyRanking {
  final String classId;
  final DateTime weekStartDate;
  final List<WeeklyRankingEntry> entries;

  const WeeklyRanking({
    required this.classId,
    required this.weekStartDate,
    required this.entries,
  });

  factory WeeklyRanking.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRankingFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyRankingToJson(this);

  /// Total number of students in this ranking.
  int get totalStudents => entries.length;

  /// Get entries filtered by tier.
  List<WeeklyRankingEntry> entriesByTier(RankingTier tier) =>
      entries.where((e) => e.tier == tier).toList();

  /// Find a student's entry by ID. Returns null if not found.
  WeeklyRankingEntry? findStudent(String studentId) {
    final matches = entries.where((e) => e.studentId == studentId);
    return matches.isEmpty ? null : matches.first;
  }

  /// Maximum points in this week's ranking.
  int get maxPoints =>
      entries.isEmpty ? 0 : entries.first.weeklyPoints;

  /// Whether this ranking has any entries.
  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;
}
