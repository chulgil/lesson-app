import '../../domain/entities/quest_origin.dart';
import '../../domain/entities/student_quest.dart';
import '../../domain/repositories/student_quest_repository.dart';

/// 메모리 기반 [StudentQuestRepository] 구현.
///
/// 플랜 Job 2 Task 2.2 — P1 베타 출시 가능 우선 (O1 결정). 비동기 시뮬레이션
/// 위해 [Future.delayed] 100ms. 영속화는 후속 (Hive box) 또는 P2 BE.
class MockStudentQuestRepository implements StudentQuestRepository {
  final Map<String, StudentQuest> _store = {};

  static const _latency = Duration(milliseconds: 100);

  @override
  Future<List<StudentQuest>> getActiveQuests(String studentId) async {
    await Future.delayed(_latency);
    return _store.values
        .where((q) => q.studentId == studentId && !q.isCompleted)
        .toList(growable: false);
  }

  @override
  Future<StudentQuest> createQuest(StudentQuest quest) async {
    await Future.delayed(_latency);
    _store[quest.id] = quest;
    return quest;
  }

  @override
  Future<StudentQuest> updateProgress(String questId, int currentValue) async {
    await Future.delayed(_latency);
    final existing = _store[questId];
    if (existing == null) {
      throw StateError('Quest not found: $questId');
    }
    final updated = existing.copyWith(currentValue: currentValue);
    _store[questId] = updated;
    return updated;
  }

  @override
  Future<void> markCompleted(String questId) async {
    await Future.delayed(_latency);
    final existing = _store[questId];
    if (existing == null) {
      throw StateError('Quest not found: $questId');
    }
    _store[questId] = existing.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<List<StudentQuest>> getQuestsByOrigin(
    String studentId,
    QuestOrigin origin,
  ) async {
    await Future.delayed(_latency);
    return _store.values
        .where((q) => q.studentId == studentId && q.origin == origin)
        .toList(growable: false);
  }
}
