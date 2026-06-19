import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/student.dart';

/// Hive-backed read-through cache for [Student] lists.
///
/// Uses [Box<String>] + JSON serialisation — no TypeAdapter required.
///
/// Key structure:
///   `all`                       → getStudents() result
///   `student:<id>`              → getStudent(id) — nullable
///   `search:<query>`            → searchStudents(query)
///   `status:<statusName>`       → getStudentsByStatus(status)
///
/// Each entry is a JSON object:
/// ```json
/// { "cachedAt": "<iso>", "data": [...] }
/// ```
class StudentCacheStore {
  StudentCacheStore({required Box<String> box}) : _box = box;

  static const String boxName = 'student_cache_v1';

  final Box<String> _box;

  // --------------------------------------------------------------------------
  // Write helpers
  // --------------------------------------------------------------------------

  Future<void> putStudents(String key, List<Student> students) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': students.map((s) => s.toJson()).toList(),
    });
    await _box.put(key, payload);
  }

  Future<void> putStudent(String key, Student? student) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': student?.toJson(),
    });
    await _box.put(key, payload);
  }

  // --------------------------------------------------------------------------
  // Read helpers
  // --------------------------------------------------------------------------

  List<Student>? getStudents(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dataList = map['data'] as List<dynamic>?;
      if (dataList == null) return null;
      return dataList
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Student? getStudent(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = map['data'];
      if (data == null) return null;
      return Student.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Key builders
  // --------------------------------------------------------------------------

  static String keyAll() => 'all';
  static String keyStudent(String id) => 'student:$id';
  static String keySearch(String query) => 'search:$query';
  static String keyStatus(String statusName) => 'status:$statusName';
}
