/// Challenge (mission) entity for gamification Phase 3.
///
/// Challenges are time-bound goals that reward points and badges on completion.

enum ChallengePeriod {
  weekly,
  monthly;

  String get displayName => switch (this) {
        weekly => '주간',
        monthly => '월간',
      };
}

enum ChallengeType {
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
  pointsEarned;

  String get displayName => switch (this) {
        practiceDays => '연습 일수',
        practiceMinutes => '연습 시간',
        recordings => '녹음 횟수',
        lessons => '레슨 완료',
        streak => '연속 연습',
        pointsEarned => '포인트 획득',
      };

  String get icon => switch (this) {
        practiceDays => '📅',
        practiceMinutes => '⏱️',
        recordings => '🎙️',
        lessons => '🎵',
        streak => '🔥',
        pointsEarned => '💎',
      };
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
  final ChallengeType type;
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
  double get progress => targetValue > 0
      ? (currentValue / targetValue).clamp(0.0, 1.0)
      : 0.0;

  /// Remaining days until deadline.
  int get remainingDays {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the challenge is still active (not expired and not completed).
  bool get isActive =>
      !isCompleted && DateTime.now().isBefore(endDate);

  /// Display string for the target (e.g., "5일", "30분", "3회").
  String get targetDisplay => switch (type) {
        ChallengeType.practiceDays => '$targetValue일',
        ChallengeType.practiceMinutes => '$targetValue분',
        ChallengeType.recordings => '$targetValue회',
        ChallengeType.lessons => '$targetValue회',
        ChallengeType.streak => '$targetValue일',
        ChallengeType.pointsEarned => '${targetValue}P',
      };

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
