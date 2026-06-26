import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/quest_origin.dart';
import '../../domain/entities/student_quest.dart';
import '../../domain/repositories/student_quest_repository.dart';

/// Hive 기반 [StudentQuestRepository] 구현 — 런타임 영속 (#422).
///
/// [HiveStreakFreezeRepository] 와 동일하게 `Box<String>` + JSON 직렬화 채택
/// (TypeAdapter 미사용). key = quest.id, value = jsonEncode(quest.toJson()).
/// [MockStudentQuestRepository] 와 동일 동작이되 인메모리 Map 대신 Hive box 에
/// 영속한다 — 앱 재시작/재설치 후에도 자가 quest 진척이 유지된다.
class HiveStudentQuestRepository implements StudentQuestRepository {
  HiveStudentQuestRepository({required Box<String> box}) : _box = box;

  /// Box name = `student_quest_v1`.
  static const String boxName = 'student_quest_v1';

  final Box<String> _box;

  StudentQuest? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return StudentQuest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Iterable<StudentQuest> _all() =>
      _box.values.map(_decode).whereType<StudentQuest>();

  @override
  Future<List<StudentQuest>> getActiveQuests(String studentId) async {
    return _all()
        .where((q) => q.studentId == studentId && !q.isCompleted)
        .toList(growable: false);
  }

  @override
  Future<StudentQuest> createQuest(StudentQuest quest) async {
    await _box.put(quest.id, jsonEncode(quest.toJson()));
    return quest;
  }

  @override
  Future<StudentQuest> updateProgress(String questId, int currentValue) async {
    final existing = _decode(_box.get(questId));
    if (existing == null) {
      throw StateError('Quest not found: $questId');
    }
    final updated = existing.copyWith(currentValue: currentValue);
    await _box.put(questId, jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<void> markCompleted(String questId) async {
    final existing = _decode(_box.get(questId));
    if (existing == null) {
      throw StateError('Quest not found: $questId');
    }
    final completed = existing.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await _box.put(questId, jsonEncode(completed.toJson()));
  }

  @override
  Future<List<StudentQuest>> getQuestsByOrigin(
    String studentId,
    QuestOrigin origin,
  ) async {
    return _all()
        .where((q) => q.studentId == studentId && q.origin == origin)
        .toList(growable: false);
  }
}
