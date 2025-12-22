/// Practice task model
class PracticeTask {
  final String id;
  final String title;
  final String? description;
  final int targetMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? pieceId;

  const PracticeTask({
    required this.id,
    required this.title,
    this.description,
    this.targetMinutes = 15,
    this.isCompleted = false,
    this.completedAt,
    this.pieceId,
  });

  PracticeTask copyWith({
    String? id,
    String? title,
    String? description,
    int? targetMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    String? pieceId,
  }) {
    return PracticeTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      pieceId: pieceId ?? this.pieceId,
    );
  }
}

/// Daily practice log
class PracticeLog {
  final String id;
  final String studentId;
  final DateTime date;
  final int totalMinutes;
  final List<PracticeTask> tasks;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PracticeLog({
    required this.id,
    required this.studentId,
    required this.date,
    this.totalMinutes = 0,
    this.tasks = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get completion rate (0.0 to 1.0)
  double get completionRate {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }

  /// Check if all tasks are completed
  bool get isFullyCompleted => tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

  /// Get completion level for calendar display
  /// 0: no practice, 1: minimal, 2: partial, 3: full
  int get completionLevel {
    if (tasks.isEmpty && totalMinutes == 0) return 0;
    final rate = completionRate;
    if (rate >= 0.8) return 3;
    if (rate >= 0.5) return 2;
    if (rate > 0 || totalMinutes > 0) return 1;
    return 0;
  }

  PracticeLog copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    int? totalMinutes,
    List<PracticeTask>? tasks,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Practice streak tracking
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

/// Monthly practice statistics
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

  /// Get achievement rate (0.0 to 1.0)
  double get achievementRate {
    if (totalDays == 0) return 0.0;
    return practicedDays / totalDays;
  }

  /// Get achievement percentage string
  String get achievementPercentage => '${(achievementRate * 100).round()}%';
}
