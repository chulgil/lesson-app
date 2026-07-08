/// Challenge (mission) entity for gamification Phase 3.
///
/// Challenges are time-bound goals that reward points and badges on completion.
library;

enum ChallengePeriod { weekly, monthly }

/// Activity measurement type for a challenge/quest.
///
/// Discipline-neutral value. Display labels/icons live in
/// presentation/extensions/challenge_visuals.dart (flutter-architecture rule).
enum ActivityType {
  /// Practice N days in a period.
  practiceDays,

  /// Practice total N minutes in a period.
  practiceMinutes,

  /// Record N times in a period.
  recordings,

  /// Complete N lessons in a period.
  lessons,

  /// Achieve N-day streak.
  streak,

  /// Earn N points in a period.
  pointsEarned,
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.targetValue,
    required this.currentValue,
    required this.rewardPoints,
    required this.startDate,
    required this.endDate,
    this.rewardBadgeId,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final ChallengePeriod period;
  final int targetValue;
  final int currentValue;
  final int rewardPoints;
  final DateTime startDate;
  final DateTime endDate;
  final String? rewardBadgeId;
  final bool isCompleted;
  final DateTime? completedAt;

  /// Progress ratio (0.0 ~ 1.0).
  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  /// Remaining days until deadline.
  ///
  /// 캘린더 날짜 차이로 계산 (#D5) — Duration.inDays 는 24시간 미만을 0 으로
  /// 버려, 내일 마감이어도 "D-0" 로 하루 일찍 표시하던 버그가 있었다.
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = deadline.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the challenge is still active (not expired and not completed).
  bool get isActive => !isCompleted && DateTime.now().isBefore(endDate);

  Challenge copyWith({
    int? currentValue,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: type,
      period: period,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      rewardPoints: rewardPoints,
      startDate: startDate,
      endDate: endDate,
      rewardBadgeId: rewardBadgeId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
