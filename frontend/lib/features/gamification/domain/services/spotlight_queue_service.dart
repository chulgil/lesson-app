import '../entities/spotlight_prompt.dart';
import '../repositories/spotlight_prompt_repository.dart';

/// 스포트라이트 큐 우선순위 평가 — 스펙 §7.2.
///
/// 우선순위 (priority asc, tie-break queuedAt asc):
/// 1. teacherRec + isMandatory (priority=0)
/// 2. teacherRec 일반 (priority=10)
/// 3. seasonEvent (priority=20)
/// 4. routineSuggestion (priority=30)
///
/// hideUntil/permanentlyHidden 인 prompt 는 평가 대상에서 제외 (isHiddenAt(now)).
class SpotlightQueueService {
  SpotlightQueueService(this._repo);

  final SpotlightPromptRepository _repo;

  /// [studentId] 의 큐에서 다음 노출 가능한 prompt 1개 반환. 없으면 null.
  Future<SpotlightPrompt?> nextPromptableFor(
    String studentId,
    DateTime now,
  ) async {
    final all = await _repo.listForStudent(studentId);
    final promptable = all.where((p) => !p.isHiddenAt(now)).toList();
    if (promptable.isEmpty) return null;
    promptable.sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      if (byPriority != 0) return byPriority;
      return a.queuedAt.compareTo(b.queuedAt);
    });
    return promptable.first;
  }

  /// 큐에 promptable item 이 1개 이상 있는지 (Job 3 Eligibility 컨텍스트).
  Future<bool> hasPromptableFor(String studentId, DateTime now) async {
    final next = await nextPromptableFor(studentId, now);
    return next != null;
  }
}
