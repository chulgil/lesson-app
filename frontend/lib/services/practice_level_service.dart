import '../models/practice_repertoire.dart';
import '../models/student.dart';

/// Service for calculating student practice levels
///
/// Practice level is calculated based on the number of days
/// with completed practice records in the last 7 days:
/// - excellent: 5+ days
/// - average: 3-4 days
/// - poor: 1-2 days
/// - newStudent: connected < 7 days or no practice records
/// - onBreak: student is on break status
class PracticeLevelService {
  /// Calculate practice level for a student
  ///
  /// [student] The student to calculate level for
  /// [practiceRepertoires] List of active practice repertoires with sections
  ///
  /// Returns calculated [PracticeLevel]
  PracticeLevel calculatePracticeLevel({
    required Student student,
    required List<PracticeRepertoire> practiceRepertoires,
  }) {
    // Check break status first
    if (student.isOnBreak) {
      return PracticeLevel.onBreak;
    }

    // Check if new student (connected less than 7 days)
    if (student.isNewStudent) {
      return PracticeLevel.newStudent;
    }

    // Get practice days count in last 7 days
    final practiceDays = _countPracticeDaysInLast7Days(practiceRepertoires);

    // Use helper to calculate level
    return ConnectionStatusHelper.calculatePracticeLevel(
      practiceDaysInLast7Days: practiceDays,
      isOnBreak: false,
      isNewStudent: false,
    );
  }

  /// Count unique practice days in the last 7 days
  ///
  /// Collects all DailyPracticeStatus from all sections in all repertoires
  /// and counts unique dates with completed status
  int _countPracticeDaysInLast7Days(
    List<PracticeRepertoire> practiceRepertoires,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    // Collect all unique dates with completed practice
    final completedDates = <DateTime>{};

    for (final repertoire in practiceRepertoires) {
      for (final section in repertoire.sections) {
        for (final status in section.dailyStatuses) {
          if (!status.isCompleted) continue;

          final statusDate = status.dateOnly;

          // Check if within last 7 days (inclusive of today)
          if (statusDate.isAfter(sevenDaysAgo) &&
              !statusDate.isAfter(today)) {
            completedDates.add(statusDate);
          }
        }
      }
    }

    return completedDates.length;
  }

  /// Calculate practice level from just the days count
  ///
  /// Useful when you already have the practice days count
  /// from a different data source
  PracticeLevel calculateFromDaysCount({
    required int practiceDays,
    required bool isOnBreak,
    required bool isNewStudent,
  }) {
    return ConnectionStatusHelper.calculatePracticeLevel(
      practiceDaysInLast7Days: practiceDays,
      isOnBreak: isOnBreak,
      isNewStudent: isNewStudent,
    );
  }

  /// Get practice statistics for a student
  ///
  /// Returns a map with:
  /// - practiceDays: Number of practice days in last 7 days
  /// - level: Calculated PracticeLevel
  /// - levelLabel: Korean label for the level
  /// - levelColor: Color for the level indicator
  Map<String, dynamic> getPracticeStats({
    required Student student,
    required List<PracticeRepertoire> practiceRepertoires,
  }) {
    final level = calculatePracticeLevel(
      student: student,
      practiceRepertoires: practiceRepertoires,
    );

    final practiceDays = student.isOnBreak || student.isNewStudent
        ? 0
        : _countPracticeDaysInLast7Days(practiceRepertoires);

    return {
      'practiceDays': practiceDays,
      'level': level,
      'levelLabel': level.label,
      'levelColor': level.color,
    };
  }
}
