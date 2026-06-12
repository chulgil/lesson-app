import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/streak_freeze.dart';
import '../../domain/repositories/streak_freeze_repository.dart';

/// Hive 기반 [StreakFreezeRepository] 구현 — 런타임 영속.
///
/// 플랜 Job 3 Task 3.3 / AC-1.2 결정: `Box<String>` + JSON 직렬화 채택
/// (TypeAdapter 패턴 미사용). 학생당 1 record, key = studentId.
///
/// 직렬화 비용: 학생당 record `<` 100 bytes — 메트로놈 stop 빈도 (~분당 1회)
/// 에서 무시 가능.
class HiveStreakFreezeRepository implements StreakFreezeRepository {
  HiveStreakFreezeRepository({required Box<String> box}) : _box = box;

  /// Box name = `streak_freeze_v1` (글로서리 §15 P2 / AC-1.2).
  static const String boxName = 'streak_freeze_v1';

  final Box<String> _box;

  StreakFreeze _decode(String studentId, String? raw) {
    if (raw == null) return StreakFreeze.empty(studentId);
    try {
      return StreakFreeze.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StreakFreeze.empty(studentId);
    }
  }

  Future<StreakFreeze> _save(StreakFreeze freeze) async {
    await _box.put(freeze.studentId, jsonEncode(freeze.toJson()));
    return freeze;
  }

  @override
  Future<StreakFreeze> getOrCreate(String studentId) async {
    final existing = _box.get(studentId);
    if (existing != null) return _decode(studentId, existing);
    return _save(StreakFreeze.empty(studentId));
  }

  @override
  Future<StreakFreeze> grantWeekly(String studentId, {int amount = 2}) async {
    final current = await getOrCreate(studentId);
    return _save(current.grantWeekly(amount: amount));
  }

  @override
  Future<StreakFreeze> apply(String studentId, DateTime date) async {
    final current = await getOrCreate(studentId);
    if (!current.canApply(asOf: date)) return current;
    return _save(current.apply(date));
  }

  @override
  Future<StreakFreeze> setExamMode(String studentId, DateTime? until) async {
    final current = await getOrCreate(studentId);
    return _save(
      current.copyWith(examModeUntil: until, clearExamMode: until == null),
    );
  }
}
