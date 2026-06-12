import '../entities/spotlight_prompt.dart';
import '../entities/spotlight_type.dart';
import '../repositories/spotlight_prompt_repository.dart';

/// 스포트라이트 거절 학습 — 스펙 §7.3 / SC-9.
///
/// 알고리즘:
/// 1. 거절된 prompt: `incrementDecline` (declineCount +1, lastShownAt 갱신)
/// 2. 같은 학생 + 같은 type 의 모든 prompt declineCount 합 = `typeAccum`
/// 3. typeAccum < `cumulativeBeforeWeeksHide` (5) → 거절 prompt 만 7일 cooldown
/// 4. typeAccum == 5 → 같은 type 모든 prompt 56일 (8주) hide
/// 5. typeAccum >= `cumulativeBeforePermanent` (6) → 같은 type 모든 prompt 영구 hide
class SpotlightDeclineLearningService {
  SpotlightDeclineLearningService(this._repo);

  final SpotlightPromptRepository _repo;

  /// 7일 cooldown.
  static const Duration cooldown = Duration(days: 7);

  /// 8주 hide.
  static const Duration weeksHide = Duration(days: 56);

  /// 같은 type 누적 거절 5회에 도달하면 8주 hide.
  static const int cumulativeBeforeWeeksHide = 5;

  /// 8주 hide 후 재거절 — 누적 6회 도달하면 영구 hide.
  static const int cumulativeBeforePermanent = 6;

  /// "다음에" 거절 처리. 거절된 prompt 의 최신 상태를 반환.
  Future<SpotlightPrompt> decline(String promptId, DateTime now) async {
    final declined = await _repo.incrementDecline(promptId, now);
    final allOfType =
        (await _repo.listForStudent(
          declined.studentId,
        )).where((p) => p.type == declined.type).toList();
    final typeAccum = allOfType.fold<int>(0, (sum, p) => sum + p.declineCount);

    if (typeAccum >= cumulativeBeforePermanent) {
      for (final p in allOfType) {
        await _repo.markPermanentlyHidden(p.id);
      }
      // 거절 prompt 의 최신 상태 다시 조회 (permanent 적용 후).
      return (await _repo.getById(promptId))!;
    }
    if (typeAccum >= cumulativeBeforeWeeksHide) {
      final until = now.add(weeksHide);
      for (final p in allOfType) {
        await _repo.setHideUntil(p.id, until);
      }
      return (await _repo.getById(promptId))!;
    }
    // 일반 7일 cooldown — 거절된 prompt 만 hide.
    return _repo.setHideUntil(promptId, now.add(cooldown));
  }

  /// 같은 학생 + 같은 type 누적 거절 카운트 — 분석/디버그 용.
  Future<int> typeAccumulatorFor(String studentId, SpotlightType type) async {
    final list = await _repo.listForStudent(studentId);
    return list
        .where((p) => p.type == type)
        .fold<int>(0, (sum, p) => sum + p.declineCount);
  }
}
