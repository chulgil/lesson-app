import '../../domain/entities/streak_freeze.dart';
import '../../domain/repositories/streak_freeze_repository.dart';

/// 메모리 기반 [StreakFreezeRepository] 구현 — 테스트/dev 용.
///
/// 플랜 Job 3 Task 3.2. 비동기 시뮬레이션 50ms. 학생별 단일 record 영속.
class MockStreakFreezeRepository implements StreakFreezeRepository {
  final Map<String, StreakFreeze> _store = {};

  static const _latency = Duration(milliseconds: 50);

  @override
  Future<StreakFreeze> getOrCreate(String studentId) async {
    await Future.delayed(_latency);
    return _store.putIfAbsent(studentId, () => StreakFreeze.empty(studentId));
  }

  @override
  Future<StreakFreeze> grantWeekly(String studentId, {int amount = 2}) async {
    final current = await getOrCreate(studentId);
    final granted = current.grantWeekly(amount: amount);
    _store[studentId] = granted;
    return granted;
  }

  @override
  Future<StreakFreeze> apply(String studentId, DateTime date) async {
    final current = await getOrCreate(studentId);
    if (!current.canApply(asOf: date)) {
      return current;
    }
    final applied = current.apply(date);
    _store[studentId] = applied;
    return applied;
  }

  @override
  Future<StreakFreeze> setExamMode(String studentId, DateTime? until) async {
    final current = await getOrCreate(studentId);
    final updated = current.copyWith(
      examModeUntil: until,
      clearExamMode: until == null,
    );
    _store[studentId] = updated;
    return updated;
  }
}
