import 'package:uuid/uuid.dart';

import '../models/practice.dart';

/// Repository for managing practice data
abstract class PracticeRepository {
  Future<List<PracticeLog>> getPracticeLogs(String studentId);
  Future<PracticeLog?> getPracticeLog(String id);
  Future<PracticeLog?> getPracticeLogByDate(String studentId, DateTime date);
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
      String studentId, int year, int month);
  Future<PracticeStats> getPracticeStats(String studentId, int year, int month);
  Future<List<bool>> getWeeklyPractice(String studentId);
  Future<PracticeLog> createPracticeLog(PracticeLog log);
  Future<PracticeLog> updatePracticeLog(PracticeLog log);
  Future<void> deletePracticeLog(String id);
  Future<PracticeTask> toggleTask(String logId, String taskId);
}

/// Mock implementation for development
class MockPracticeRepository implements PracticeRepository {
  final _uuid = const Uuid();
  final Map<String, List<PracticeLog>> _logs = {};

  MockPracticeRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // Student 1 practice logs
    _logs['student_1'] = List.generate(30, (index) {
      final date = now.subtract(Duration(days: index));
      final hasPractice = index % 7 != 0 && index % 7 != 6; // Skip some weekends
      if (!hasPractice && index < 7) return null;

      return PracticeLog(
        id: 'practice_1_$index',
        studentId: 'student_1',
        date: date,
        totalMinutes: hasPractice ? 45 + (index % 3) * 15 : 0,
        tasks: hasPractice
            ? [
                PracticeTask(
                  id: 'task_1_${index}_1',
                  title: '스케일 연습 (G Major)',
                  targetMinutes: 15,
                  isCompleted: true,
                ),
                PracticeTask(
                  id: 'task_1_${index}_2',
                  title: '바흐 파르티타 2번 - 1악장',
                  targetMinutes: 30,
                  isCompleted: index % 2 == 0,
                ),
                PracticeTask(
                  id: 'task_1_${index}_3',
                  title: '비브라토 연습',
                  targetMinutes: 10,
                  isCompleted: index % 3 == 0,
                ),
              ]
            : [],
        createdAt: date,
      );
    }).whereType<PracticeLog>().toList();

    // Student 2 practice logs
    _logs['student_2'] = List.generate(30, (index) {
      final date = now.subtract(Duration(days: index));
      final hasPractice = index % 3 != 0;
      if (!hasPractice) return null;

      return PracticeLog(
        id: 'practice_2_$index',
        studentId: 'student_2',
        date: date,
        totalMinutes: hasPractice ? 30 + (index % 2) * 15 : 0,
        tasks: hasPractice
            ? [
                PracticeTask(
                  id: 'task_2_${index}_1',
                  title: '하논 연습',
                  targetMinutes: 10,
                  isCompleted: true,
                ),
                PracticeTask(
                  id: 'task_2_${index}_2',
                  title: '쇼팽 왈츠 연습',
                  targetMinutes: 20,
                  isCompleted: index % 2 == 0,
                ),
              ]
            : [],
        createdAt: date,
      );
    }).whereType<PracticeLog>().toList();
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
}
