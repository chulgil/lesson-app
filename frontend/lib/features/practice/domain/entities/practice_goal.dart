import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'practice_goal.g.dart';

/// Practice goal model for tracking daily/weekly targets
@HiveType(typeId: 32)
@JsonSerializable()
class PracticeGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  // === Daily goals ===
  @HiveField(2)
  final int? dailyTimeMinutes; // Daily practice time goal (minutes)

  @HiveField(3)
  final int? dailySectionCount; // Daily completed section count goal

  // === Weekly goals ===
  @HiveField(4)
  final int? weeklyTimeMinutes; // Weekly practice time goal (minutes)

  @HiveField(5)
  final int? weeklyDayCount; // Weekly practice day count goal

  // === Metadata ===
  @HiveField(6)
  final bool isActive; // Whether goal is active

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  PracticeGoal({
    required this.id,
    required this.studentId,
    this.dailyTimeMinutes,
    this.dailySectionCount,
    this.weeklyTimeMinutes,
    this.weeklyDayCount,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeGoal.fromJson(Map<String, dynamic> json) =>
      _$PracticeGoalFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeGoalToJson(this);

  /// Whether daily goal is set
  bool get hasDailyGoal =>
      dailyTimeMinutes != null || dailySectionCount != null;

  /// Whether weekly goal is set
  bool get hasWeeklyGoal =>
      weeklyTimeMinutes != null || weeklyDayCount != null;

  /// Whether any goal is set
  bool get hasAnyGoal => hasDailyGoal || hasWeeklyGoal;

  /// Format daily time goal as text
  String get dailyTimeText {
    if (dailyTimeMinutes == null) return '미설정';
    if (dailyTimeMinutes! >= 60) {
      final hours = dailyTimeMinutes! ~/ 60;
      final mins = dailyTimeMinutes! % 60;
      return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
    }
    return '$dailyTimeMinutes분';
  }

  /// Format weekly time goal as text
  String get weeklyTimeText {
    if (weeklyTimeMinutes == null) return '미설정';
    if (weeklyTimeMinutes! >= 60) {
      final hours = weeklyTimeMinutes! ~/ 60;
      final mins = weeklyTimeMinutes! % 60;
      return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
    }
    return '$weeklyTimeMinutes분';
  }

  PracticeGoal copyWith({
    String? id,
    String? studentId,
    int? dailyTimeMinutes,
    int? dailySectionCount,
    int? weeklyTimeMinutes,
    int? weeklyDayCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDailyTime = false,
    bool clearDailySection = false,
    bool clearWeeklyTime = false,
    bool clearWeeklyDay = false,
  }) {
    return PracticeGoal(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      dailyTimeMinutes:
          clearDailyTime ? null : (dailyTimeMinutes ?? this.dailyTimeMinutes),
      dailySectionCount: clearDailySection
          ? null
          : (dailySectionCount ?? this.dailySectionCount),
      weeklyTimeMinutes: clearWeeklyTime
          ? null
          : (weeklyTimeMinutes ?? this.weeklyTimeMinutes),
      weeklyDayCount:
          clearWeeklyDay ? null : (weeklyDayCount ?? this.weeklyDayCount),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PracticeGoal(id: $id, studentId: $studentId, '
        'dailyTimeMinutes: $dailyTimeMinutes, dailySectionCount: $dailySectionCount, '
        'weeklyTimeMinutes: $weeklyTimeMinutes, weeklyDayCount: $weeklyDayCount, '
        'isActive: $isActive)';
  }
}
