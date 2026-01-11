import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_repository.dart';

/// Mock implementation for development
class MockPracticeRepository implements PracticeRepository {
  final _uuid = const Uuid();
  final Map<String, List<PracticeLog>> _logs = {};
  final Map<String, PracticeStreak> _streaks = {};

  MockPracticeRepository() {
    _initMockData();
  }

  void _initMockData() {
    // No dummy data - users create their own practice logs
  }

  void _initStreaks() {
    for (final studentId in _logs.keys) {
      final streak = _calculateStreak(studentId);
      _streaks[studentId] = streak;
    }
  }

  /// Check if a date is a weekend (Saturday or Sunday)
  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Check if all days between two dates are weekends
  /// Returns true if streak should continue (gap is only weekends)
  bool _isGapOnlyWeekends(DateTime newerDate, DateTime olderDate) {
    final daysDiff = newerDate.difference(olderDate).inDays;
    if (daysDiff <= 1) return true; // Consecutive days

    // Check each day in the gap
    for (int i = 1; i < daysDiff; i++) {
      final gapDate = olderDate.add(Duration(days: i));
      if (!_isWeekend(gapDate)) {
        return false; // Found a weekday in the gap
      }
    }
    return true; // Gap only contains weekends
  }

  /// Check if streak is still active considering weekend exclusion
  bool _isStreakActive(DateTime lastPracticeDate, DateTime today) {
    final daysSince = today.difference(lastPracticeDate).inDays;
    if (daysSince <= 1) return true; // Same day or yesterday

    // Check if gap is only weekends
    return _isGapOnlyWeekends(today, lastPracticeDate);
  }

  PracticeStreak _calculateStreak(String studentId) {
    final logs = _logs[studentId] ?? [];
    if (logs.isEmpty) {
      return PracticeStreak(
        id: 'streak_$studentId',
        studentId: studentId,
        currentStreak: 0,
        longestStreak: 0,
        lastPracticeDate: null,
        updatedAt: DateTime.now(),
      );
    }

    // Sort logs by date descending
    final sortedLogs = List<PracticeLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Find consecutive practice days
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastPracticeDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all practice dates with actual practice
    final practiceDates = sortedLogs
        .where((log) => log.totalMinutes > 0 || log.tasks.any((t) => t.isCompleted))
        .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (practiceDates.isEmpty) {
      return PracticeStreak(
        id: 'streak_$studentId',
        studentId: studentId,
        currentStreak: 0,
        longestStreak: 0,
        lastPracticeDate: null,
        updatedAt: DateTime.now(),
      );
    }

    lastPracticeDate = practiceDates.first;

    // Calculate current streak with weekend exclusion
    // Streak is active if practiced today, yesterday, or gap is only weekends
    if (_isStreakActive(lastPracticeDate, today)) {
      currentStreak = 1;

      for (int i = 1; i < practiceDates.length; i++) {
        final currentDate = practiceDates[i - 1];
        final previousDate = practiceDates[i];

        // Check if streak continues (consecutive or gap is only weekends)
        if (_isGapOnlyWeekends(currentDate, previousDate)) {
          currentStreak++;
        } else {
          break; // Streak broken by weekday gap
        }
      }
    }

    // Calculate longest streak with weekend exclusion
    int tempStreak = 1;
    for (int i = 0; i < practiceDates.length - 1; i++) {
      final currentDate = practiceDates[i];
      final previousDate = practiceDates[i + 1];

      if (_isGapOnlyWeekends(currentDate, previousDate)) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    return PracticeStreak(
      id: 'streak_$studentId',
      studentId: studentId,
      currentStreak: currentStreak,
      longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
      lastPracticeDate: lastPracticeDate,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<PracticeLog>> getPracticeLogs(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _logs[studentId] ?? [];
  }

  @override
  Future<PracticeLog?> getPracticeLog(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final logs in _logs.values) {
      try {
        return logs.firstWhere((l) => l.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<PracticeLog?> getPracticeLogByDate(
      String studentId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    try {
      return logs.firstWhere((l) =>
          l.date.year == date.year &&
          l.date.month == date.month &&
          l.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
      String studentId, int year, int month) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    final result = <DateTime, PracticeLog>{};
    for (final log in logs) {
      if (log.date.year == year && log.date.month == month) {
        final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
        result[dateKey] = log;
      }
    }
    return result;
  }

  @override
  Future<PracticeStats> getPracticeStats(
      String studentId, int year, int month) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    final monthLogs = logs.where(
        (l) => l.date.year == year && l.date.month == month);

    final totalDays = DateTime(year, month + 1, 0).day;
    final practicedDays = monthLogs.where((l) => l.totalMinutes > 0).length;
    final totalMinutes =
        monthLogs.fold(0, (sum, l) => sum + l.totalMinutes);

    return PracticeStats(
      year: year,
      month: month,
      totalDays: totalDays,
      practicedDays: practicedDays,
      totalMinutes: totalMinutes,
      averageMinutesPerDay:
          practicedDays > 0 ? totalMinutes / practicedDays : 0,
    );
  }

  @override
  Future<List<bool>> getWeeklyPractice(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    final now = DateTime.now();

    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return logs.any((l) =>
          l.date.year == date.year &&
          l.date.month == date.month &&
          l.date.day == date.day &&
          l.totalMinutes > 0);
    });
  }

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newLog = log.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _logs.putIfAbsent(log.studentId, () => []);
    _logs[log.studentId]!.add(newLog);
    return newLog;
  }

  @override
  Future<PracticeLog> updatePracticeLog(PracticeLog log) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final logs = _logs[log.studentId];
    if (logs == null) throw Exception('Student not found');

    final index = logs.indexWhere((l) => l.id == log.id);
    if (index == -1) throw Exception('Practice log not found');

    final updated = log.copyWith(updatedAt: DateTime.now());
    logs[index] = updated;
    return updated;
  }

  @override
  Future<void> deletePracticeLog(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final logs in _logs.values) {
      logs.removeWhere((l) => l.id == id);
    }
  }

  @override
  Future<PracticeTask> toggleTask(String logId, String taskId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    PracticeLog? log;
    String? studentId;
    int logIndex = -1;

    for (final entry in _logs.entries) {
      final idx = entry.value.indexWhere((l) => l.id == logId);
      if (idx != -1) {
        log = entry.value[idx];
        studentId = entry.key;
        logIndex = idx;
        break;
      }
    }

    if (log == null || studentId == null) {
      throw Exception('Practice log not found');
    }

    final taskIndex = log.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) throw Exception('Task not found');

    final task = log.tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );

    final updatedTasks = List<PracticeTask>.from(log.tasks);
    updatedTasks[taskIndex] = updatedTask;

    final updatedLog = log.copyWith(
      tasks: updatedTasks,
      updatedAt: DateTime.now(),
    );

    _logs[studentId]![logIndex] = updatedLog;

    return updatedTask;
  }

  @override
  Future<PracticeStreak> getStreak(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_streaks.containsKey(studentId)) {
      return _streaks[studentId]!;
    }

    // Create new streak for student
    final streak = PracticeStreak(
      id: 'streak_$studentId',
      studentId: studentId,
      currentStreak: 0,
      longestStreak: 0,
      lastPracticeDate: null,
      updatedAt: DateTime.now(),
    );
    _streaks[studentId] = streak;
    return streak;
  }

  @override
  Future<PracticeStreak> updateStreak(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final streak = _calculateStreak(studentId);
    _streaks[studentId] = streak;
    return streak;
  }

  @override
  Future<PracticeStreak> recordPractice(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already has practice log for today
    final existingLog = await getPracticeLogByDate(studentId, today);
    if (existingLog == null) {
      // Create a minimal practice log for streak
      final newLog = PracticeLog(
        id: _uuid.v4(),
        studentId: studentId,
        date: today,
        totalMinutes: 1, // Minimal practice recorded
        tasks: [],
        createdAt: now,
      );
      _logs.putIfAbsent(studentId, () => []);
      _logs[studentId]!.add(newLog);
    }

    // Recalculate streak
    return updateStreak(studentId);
  }
}
