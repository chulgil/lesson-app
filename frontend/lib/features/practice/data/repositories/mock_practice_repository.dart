import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/services/streak_calculator.dart';
import '../mock/mock_practice_logs.dart';

/// Mock implementation for development
class MockPracticeRepository implements PracticeRepository {
  final _uuid = const Uuid();
  final Map<String, List<PracticeLog>> _logs = {};

  MockPracticeRepository() {
    _logs.addAll(buildMockPracticeLogs());
  }

  /// Recompute the streak from the student's logs on every read (self-healing),
  /// using the single shared algorithm. See docs/specs/practice/streak_ssot.md.
  PracticeStreak _toStreak(String studentId) {
    final summary = StreakCalculator.fromLogs(_logs[studentId] ?? const []);
    return PracticeStreak(
      id: 'streak_$studentId',
      studentId: studentId,
      currentStreak: summary.currentStreak,
      longestStreak: summary.longestStreak,
      lastPracticeDate: summary.lastPracticeDate,
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
    String studentId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    try {
      return logs.firstWhere(
        (l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
    String studentId,
    int year,
    int month,
  ) async {
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
    String studentId,
    int year,
    int month,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logs = _logs[studentId] ?? [];
    final monthLogs = logs.where(
      (l) => l.date.year == year && l.date.month == month,
    );

    final totalDays = DateTime(year, month + 1, 0).day;
    final practicedDays = monthLogs.where((l) => l.totalMinutes > 0).length;
    final totalMinutes = monthLogs.fold(0, (sum, l) => sum + l.totalMinutes);

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
      return logs.any(
        (l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day &&
            l.totalMinutes > 0,
      );
    });
  }

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newLog = log.copyWith(id: _uuid.v4(), createdAt: DateTime.now());
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
    return _toStreak(studentId);
  }

  @override
  Future<PracticeStreak> updateStreak(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _toStreak(studentId);
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
