// Student dashboard domain entities

/// Student tab type for navigation
enum StudentTab {
  home,
  lessons,
  practice,
  profile;

  String get label {
    switch (this) {
      case StudentTab.home:
        return '홈';
      case StudentTab.lessons:
        return '레슨';
      case StudentTab.practice:
        return '연습';
      case StudentTab.profile:
        return '프로필';
    }
  }

  int get tabIndex {
    switch (this) {
      case StudentTab.home:
        return 0;
      case StudentTab.lessons:
        return 1;
      case StudentTab.practice:
        return 2;
      case StudentTab.profile:
        return 3;
    }
  }
}

/// Weekly practice status for bar chart display
class WeeklyPracticeStatus {
  final List<String> dayLabels;
  final List<double> progress; // 0.0 to 1.0 scale
  final int todayIndex;
  final int practicedDays;
  final Duration totalPracticeTime;
  final double achievementRate;

  const WeeklyPracticeStatus({
    required this.dayLabels,
    required this.progress,
    required this.todayIndex,
    required this.practicedDays,
    required this.totalPracticeTime,
    required this.achievementRate,
  });

  static const empty = WeeklyPracticeStatus(
    dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
    progress: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    todayIndex: 0,
    practicedDays: 0,
    totalPracticeTime: Duration.zero,
    achievementRate: 0.0,
  );
}

/// Teacher feedback summary for dashboard
class TeacherFeedback {
  final String id;
  final String teacherName;
  final String teacherInitial;
  final DateTime feedbackDate;
  final String content;
  final List<String> tags;

  const TeacherFeedback({
    required this.id,
    required this.teacherName,
    required this.teacherInitial,
    required this.feedbackDate,
    required this.content,
    required this.tags,
  });
}

/// Next lesson card data
class NextLessonInfo {
  final String teacherName;
  final String teacherInitial;
  final String instrument;
  final DateTime lessonDate;
  final int daysUntil;

  const NextLessonInfo({
    required this.teacherName,
    required this.teacherInitial,
    required this.instrument,
    required this.lessonDate,
    required this.daysUntil,
  });

  String get formattedDate {
    final month = lessonDate.month;
    final day = lessonDate.day;
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][lessonDate.weekday % 7];
    final hour = lessonDate.hour;
    final minute = lessonDate.minute.toString().padLeft(2, '0');
    return '$month월 $day일 ($weekday) $hour:$minute';
  }

  String get dDayLabel => daysUntil == 0 ? 'D-Day' : 'D-$daysUntil';
}
