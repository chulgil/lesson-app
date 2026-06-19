import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/lesson.dart';

/// Hive-backed read-through cache for [Lesson] lists.
///
/// Uses [Box<String>] + JSON serialisation (same pattern as
/// [HiveStreakFreezeRepository]) — no TypeAdapter required.
///
/// Key structure:
///   `all`                → getLessons() result
///   `student:<id>`       → getLessonsByStudent(id)
///   `date:<iso>`         → getLessonsByDate(date)
///   `range:<from>:<to>`  → getLessonsByDateRange(from, to)
///   `upcoming:<limit>`   → getUpcomingLessons(limit)
///   `recent:<limit>`     → getRecentLessons(limit)
///   `lesson:<id>`        → getLesson(id) — nullable, stored as JSON | 'null'
///
/// Each entry is a JSON object:
/// ```json
/// { "cachedAt": "<iso>", "data": [...] }
/// ```
class LessonCacheStore {
  LessonCacheStore({required Box<String> box}) : _box = box;

  static const String boxName = 'lesson_cache_v1';

  final Box<String> _box;

  // --------------------------------------------------------------------------
  // Write helpers
  // --------------------------------------------------------------------------

  Future<void> putLessons(String key, List<Lesson> lessons) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': lessons.map((l) => l.toJson()).toList(),
    });
    await _box.put(key, payload);
  }

  Future<void> putLesson(String key, Lesson? lesson) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': lesson?.toJson(),
    });
    await _box.put(key, payload);
  }

  // --------------------------------------------------------------------------
  // Read helpers
  // --------------------------------------------------------------------------

  List<Lesson>? getLessons(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dataList = map['data'] as List<dynamic>?;
      if (dataList == null) return null;
      return dataList
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Lesson? getLesson(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = map['data'];
      if (data == null) return null;
      return Lesson.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Key builders
  // --------------------------------------------------------------------------

  static String keyAll() => 'all';
  static String keyStudent(String studentId) => 'student:$studentId';
  static String keyDate(DateTime date) =>
      'date:${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String keyRange(DateTime start, DateTime end) =>
      'range:${start.toUtc().toIso8601String()}:${end.toUtc().toIso8601String()}';
  static String keyUpcoming(int limit) => 'upcoming:$limit';
  static String keyRecent(int limit) => 'recent:$limit';
  static String keyLesson(String id) => 'lesson:$id';
}
