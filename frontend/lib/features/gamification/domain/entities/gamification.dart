// Gamification entities: points, levels, and badges.

/// Student gamification profile with points and level.
class StudentGamification {
  final String studentId;
  final int totalPoints;
  final int level;
  final String levelTitle;
  final int pointsToNextLevel;
  final int currentLevelMinPoints;
  final int nextLevelMinPoints;
  final List<PracticeBadge> earnedBadges;
  final List<PointHistory> recentHistory;

  const StudentGamification({
    required this.studentId,
    required this.totalPoints,
    required this.level,
    required this.levelTitle,
    required this.pointsToNextLevel,
    required this.currentLevelMinPoints,
    required this.nextLevelMinPoints,
    this.earnedBadges = const [],
    this.recentHistory = const [],
  });

  /// Progress to next level (0.0 to 1.0).
  double get levelProgress {
    final range = nextLevelMinPoints - currentLevelMinPoints;
    if (range <= 0) return 1.0;
    final progress = totalPoints - currentLevelMinPoints;
    return (progress / range).clamp(0.0, 1.0);
  }
}

/// Point history entry.
class PointHistory {
  final String id;
  final String studentId;
  final int points;
  final PointType type;
  final String description;
  final DateTime earnedAt;

  const PointHistory({
    required this.id,
    required this.studentId,
    required this.points,
    required this.type,
    required this.description,
    required this.earnedAt,
  });
}

/// Types of point-earning activities.
enum PointType {
  practiceComplete,
  streakBonus,
  lessonAttendance,
  goalAchieved,
  badgeEarned,
}

/// PracticeBadge earned by a student.
class PracticeBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final DateTime? earnedAt;
  final bool isEarned;

  const PracticeBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.earnedAt,
    this.isEarned = false,
  });
}

/// PracticeBadge rarity levels.
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Level definition with title and required points.
class LevelDefinition {
  final int level;
  final String title;
  final int minPoints;

  const LevelDefinition({
    required this.level,
    required this.title,
    required this.minPoints,
  });

  /// All level definitions.
  static const List<LevelDefinition> levels = [
    LevelDefinition(level: 1, title: '초보 연습생', minPoints: 0),
    LevelDefinition(level: 2, title: '열정 연습생', minPoints: 100),
    LevelDefinition(level: 3, title: '꾸준한 연주자', minPoints: 300),
    LevelDefinition(level: 4, title: '실력파 연주자', minPoints: 600),
    LevelDefinition(level: 5, title: '음악 마스터', minPoints: 1000),
    LevelDefinition(level: 6, title: '전설의 연주자', minPoints: 1500),
  ];

  /// Get level for given points.
  static LevelDefinition forPoints(int points) {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].minPoints) return levels[i];
    }
    return levels.first;
  }

  /// Get next level definition (null if max level).
  static LevelDefinition? nextLevel(int currentLevel) {
    if (currentLevel >= levels.length) return null;
    return levels[currentLevel]; // currentLevel is 1-based, array is 0-based
  }
}
