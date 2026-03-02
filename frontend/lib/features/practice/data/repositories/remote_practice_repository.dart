import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_repository.dart';

/// Remote implementation of [PracticeRepository] using FastAPI backend.
///
/// Handles practice logs, tasks, statistics, and streaks.
/// Recording files stay in local Hive storage; only metadata syncs via API.
class RemotePracticeRepository implements PracticeRepository {
  final ApiClient _apiClient;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RemotePracticeRepository(this._apiClient);

  @override
  Future<List<PracticeLog>> getPracticeLogs(String studentId) async {
    final response = await _apiClient.get(
      '/practice/logs',
      queryParameters: {'student_id': studentId},
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _practiceLogFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PracticeLog?> getPracticeLog(String id) async {
    final response = await _apiClient.get('/practice/logs/$id');
    return _practiceLogFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeLog?> getPracticeLogByDate(
    String studentId,
    DateTime date,
  ) async {
    final dateStr = _dateFormat.format(date);
    final response = await _apiClient.get(
      '/practice/logs',
      queryParameters: {'student_id': studentId, 'date': dateStr},
    );
    final items = response.data['items'] as List<dynamic>;
    if (items.isEmpty) return null;
    return _practiceLogFromJson(items.first as Map<String, dynamic>);
  }

  @override
  Future<Map<DateTime, PracticeLog>> getPracticeLogsByMonth(
    String studentId,
    int year,
    int month,
  ) async {
    final response = await _apiClient.get(
      '/practice/logs',
      queryParameters: {'student_id': studentId, 'year': year, 'month': month},
    );
    final items = response.data['items'] as List<dynamic>;
    final logs =
        items
            .map((e) => _practiceLogFromJson(e as Map<String, dynamic>))
            .toList();

    return {for (final log in logs) _dateOnly(log.date): log};
  }

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) async {
    final response = await _apiClient.post(
      '/practice/logs',
      data: _practiceLogToJson(log),
    );
    return _practiceLogFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeLog> updatePracticeLog(PracticeLog log) async {
    final response = await _apiClient.put(
      '/practice/logs/${log.id}',
      data: _practiceLogToJson(log),
    );
    return _practiceLogFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deletePracticeLog(String id) async {
    await _apiClient.delete('/practice/logs/$id');
  }

  @override
  Future<PracticeTask> toggleTask(String logId, String taskId) async {
    final response = await _apiClient.patch(
      '/practice/logs/$logId/tasks/$taskId/toggle',
    );
    return _practiceTaskFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeStats> getPracticeStats(
    String studentId,
    int year,
    int month,
  ) async {
    final response = await _apiClient.get(
      '/practice/stats',
      queryParameters: {'student_id': studentId, 'year': year, 'month': month},
    );
    return _practiceStatsFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<bool>> getWeeklyPractice(String studentId) async {
    final response = await _apiClient.get(
      '/practice/weekly',
      queryParameters: {'student_id': studentId},
    );
    return (response.data as List<dynamic>).cast<bool>();
  }

  @override
  Future<PracticeStreak> getStreak(String studentId) async {
    final response = await _apiClient.get(
      '/practice/streak',
      queryParameters: {'student_id': studentId},
    );
    return _practiceStreakFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeStreak> updateStreak(String studentId) async {
    final response = await _apiClient.put(
      '/practice/streak',
      queryParameters: {'student_id': studentId},
    );
    return _practiceStreakFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeStreak> recordPractice(String studentId) async {
    final response = await _apiClient.post(
      '/practice/streak/record',
      queryParameters: {'student_id': studentId},
    );
    return _practiceStreakFromJson(response.data as Map<String, dynamic>);
  }

  // --- Manual JSON helpers (entities don't have @JsonSerializable) ---

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  PracticeTask _practiceTaskFromJson(Map<String, dynamic> json) {
    return PracticeTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetMinutes: json['target_minutes'] as int? ?? 15,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      pieceId: json['piece_id'] as String?,
    );
  }

  PracticeLog _practiceLogFromJson(Map<String, dynamic> json) {
    return PracticeLog(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((e) => _practiceTaskFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> _practiceLogToJson(PracticeLog log) {
    return {
      'id': log.id,
      'student_id': log.studentId,
      'date': log.date.toIso8601String(),
      'total_minutes': log.totalMinutes,
      'notes': log.notes,
    };
  }

  PracticeStats _practiceStatsFromJson(Map<String, dynamic> json) {
    return PracticeStats(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      totalDays: json['total_days'] as int? ?? 30,
      practicedDays: json['practiced_days'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
      averageMinutesPerDay:
          (json['average_minutes_per_day'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PracticeStreak _practiceStreakFromJson(Map<String, dynamic> json) {
    return PracticeStreak(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastPracticeDate:
          json['last_practice_date'] != null
              ? DateTime.parse(json['last_practice_date'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }
}
