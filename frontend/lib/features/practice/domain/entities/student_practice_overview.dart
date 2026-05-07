/// Daily practice entry for weekly calendar view
class DailyPracticeEntry {
  final DateTime date;
  final int practiceMinutes;
  final bool hasPracticed;

  const DailyPracticeEntry({required this.date, required this.practiceMinutes})
    : hasPracticed = practiceMinutes > 0;

  /// Formatted practice time string
  String get formattedTime {
    if (practiceMinutes == 0) return '-';
    final hours = practiceMinutes ~/ 60;
    final minutes = practiceMinutes % 60;
    if (hours > 0) return '$hours시간 $minutes분';
    return '$minutes분';
  }
}

/// Shared recording visible to teacher
class SharedRecording {
  const SharedRecording({
    required this.recordingId,
    required this.repertoireName,
    required this.sectionName,
    required this.sharedAt,
    required this.durationSeconds,
    this.bpm,
    this.localPath = '',
  });

  final String recordingId;
  final String repertoireName;
  final String sectionName;
  final DateTime sharedAt;
  final int durationSeconds;
  final int? bpm;
  final String localPath;

  /// Formatted duration string (mm:ss)
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Teacher's view of a student's practice overview
class StudentPracticeOverview {
  const StudentPracticeOverview({
    required this.studentId,
    required this.studentName,
    required this.practiceDaysThisWeek,
    required this.totalPracticeMinutes,
    required this.sharedRecordings,
    required this.weeklyEntries,
  });

  final String studentId;
  final String studentName;
  final int practiceDaysThisWeek;
  final int totalPracticeMinutes;
  final List<SharedRecording> sharedRecordings;
  final List<DailyPracticeEntry> weeklyEntries;

  int get totalDaysInWeek => 7;

  /// Formatted total practice time
  String get formattedTotalTime {
    final hours = totalPracticeMinutes ~/ 60;
    final minutes = totalPracticeMinutes % 60;
    if (hours > 0) return '$hours시간 $minutes분';
    return '$minutes분';
  }

  /// Practice rate as 0.0 ~ 1.0
  double get practiceRate {
    if (totalDaysInWeek == 0) return 0.0;
    return practiceDaysThisWeek / totalDaysInWeek;
  }
}
