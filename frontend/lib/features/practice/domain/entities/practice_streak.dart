/// Practice streak tracking entity
class PracticeStreak {
  final String id;
  final String studentId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPracticeDate;
  final DateTime updatedAt;

  const PracticeStreak({
    required this.id,
    required this.studentId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    required this.updatedAt,
  });

  /// Check if streak is active (practiced today or yesterday)
  bool get isActive {
    if (lastPracticeDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastPracticeDate!.year,
      lastPracticeDate!.month,
      lastPracticeDate!.day,
    );
    final difference = today.difference(lastDate).inDays;
    return difference <= 1;
  }

  /// Check if practiced today
  bool get practicedToday {
    if (lastPracticeDate == null) return false;
    final now = DateTime.now();
    return lastPracticeDate!.year == now.year &&
        lastPracticeDate!.month == now.month &&
        lastPracticeDate!.day == now.day;
  }

  /// Get streak level for display
  /// 0: no streak, 1: 1-6 days, 2: 7-29 days, 3: 30+ days
  int get streakLevel {
    if (currentStreak == 0) return 0;
    if (currentStreak < 7) return 1;
    if (currentStreak < 30) return 2;
    return 3;
  }

  /// Get fire emoji based on streak level
  String get fireEmoji {
    switch (streakLevel) {
      case 3:
        return '🔥🔥';
      case 2:
        return '🔥';
      case 1:
        return '✨';
      default:
        return '';
    }
  }

  /// Get motivational message
  String get motivationMessage {
    if (currentStreak == 0) {
      return '오늘 연습을 시작해보세요!';
    } else if (currentStreak < 7) {
      return '${7 - currentStreak}일 더 연습하면 불꽃이 켜져요!';
    } else if (currentStreak < 30) {
      return '${30 - currentStreak}일 더하면 더블 불꽃!';
    } else {
      return '대단해요! 연습 마스터!';
    }
  }

  PracticeStreak copyWith({
    String? id,
    String? studentId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    DateTime? updatedAt,
  }) {
    return PracticeStreak(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
