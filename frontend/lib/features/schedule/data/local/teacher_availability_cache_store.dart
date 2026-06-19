import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/teacher_availability.dart';

/// Hive-backed read-through cache for [TeacherAvailability] settings.
///
/// Uses [Box<String>] + JSON serialisation — no TypeAdapter required.
/// Only [TeacherAvailability] (settings root) is cached because computed
/// slots ([AvailabilitySlot]) use [ClockTime] value objects without a
/// public [fromJson] factory and must remain uncached.
///
/// Key structure:
///   `availability:<teacherId>` → getAvailability(teacherId) — nullable
///
/// Each entry is a JSON object:
/// ```json
/// { "cachedAt": "<iso>", "data": { ...TeacherAvailability } }
/// ```
class TeacherAvailabilityCacheStore {
  TeacherAvailabilityCacheStore({required Box<String> box}) : _box = box;

  static const String boxName = 'teacher_availability_cache_v1';

  final Box<String> _box;

  // --------------------------------------------------------------------------
  // Write helpers
  // --------------------------------------------------------------------------

  Future<void> putAvailability(
    String key,
    TeacherAvailability? availability,
  ) async {
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': availability?.toJson(),
    });
    await _box.put(key, payload);
  }

  // --------------------------------------------------------------------------
  // Read helpers
  // --------------------------------------------------------------------------

  TeacherAvailability? getAvailability(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = map['data'];
      if (data == null) return null;
      return TeacherAvailability.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Key builders
  // --------------------------------------------------------------------------

  static String keyAvailability(String teacherId) => 'availability:$teacherId';
}
