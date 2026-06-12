import '../../domain/entities/spotlight_prompt.dart';
import '../../domain/repositories/spotlight_prompt_repository.dart';

/// 메모리 기반 [SpotlightPromptRepository] 구현 — 테스트/dev 용.
///
/// 플랜 Job 2 Task 2.2. 비동기 시뮬레이션 20ms.
class MockSpotlightPromptRepository implements SpotlightPromptRepository {
  final Map<String, SpotlightPrompt> _store = {};

  static const _latency = Duration(milliseconds: 20);

  @override
  Future<void> enqueue(SpotlightPrompt prompt) async {
    await Future.delayed(_latency);
    _store[prompt.id] = prompt;
  }

  @override
  Future<List<SpotlightPrompt>> listForStudent(String studentId) async {
    await Future.delayed(_latency);
    return _store.values.where((p) => p.studentId == studentId).toList();
  }

  @override
  Future<SpotlightPrompt?> getById(String id) async {
    await Future.delayed(_latency);
    return _store[id];
  }

  SpotlightPrompt _requireById(String id) {
    final p = _store[id];
    if (p == null) {
      throw StateError('SpotlightPrompt not found: $id');
    }
    return p;
  }

  @override
  Future<SpotlightPrompt> markShown(String id, DateTime now) async {
    await Future.delayed(_latency);
    final updated = _requireById(id).copyWith(lastShownAt: now);
    _store[id] = updated;
    return updated;
  }

  @override
  Future<SpotlightPrompt> incrementDecline(String id, DateTime now) async {
    await Future.delayed(_latency);
    final current = _requireById(id);
    final updated = current.copyWith(
      declineCount: current.declineCount + 1,
      lastShownAt: now,
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<SpotlightPrompt> setHideUntil(String id, DateTime until) async {
    await Future.delayed(_latency);
    final updated = _requireById(id).copyWith(hideUntil: until);
    _store[id] = updated;
    return updated;
  }

  @override
  Future<SpotlightPrompt> markPermanentlyHidden(String id) async {
    await Future.delayed(_latency);
    final updated = _requireById(id).copyWith(permanentlyHidden: true);
    _store[id] = updated;
    return updated;
  }
}
