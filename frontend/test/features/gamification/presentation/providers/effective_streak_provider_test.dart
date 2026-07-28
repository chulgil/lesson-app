import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_with_freeze_calculator.dart';
import 'package:lessonaza/features/gamification/presentation/providers/effective_streak_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repository_provider.dart';

/// 테스트용 stub — getStreak/getPracticeLogs 만 반환, 나머지는 throw.
///
/// 로그를 비워 두면 계산기가 raw 값을 그대로 신뢰한다 (로그 미조회 fallback) —
/// 이 파일은 그 fallback 경로의 분기 판정만 검증한다. 로그 기반 실제 브리지
/// 계산은 `effective_streak_freeze_wiring_test.dart` 가 담당.
class _StubPracticeRepository implements PracticeRepository {
  _StubPracticeRepository(this._streak);
  final PracticeStreak _streak;

  @override
  Future<List<PracticeLog>> getPracticeLogs(String studentId) async => const [];

  @override
  Future<PracticeStreak> getStreak(String studentId) async => _streak;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('effectiveStreakProvider — Job 5 Task 5.1', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    PracticeStreak buildStreak({
      int currentStreak = 0,
      DateTime? lastPracticeDate,
    }) => PracticeStreak(
      id: 'streak_s1',
      studentId: 's1',
      currentStreak: currentStreak,
      longestStreak: currentStreak,
      lastPracticeDate: lastPracticeDate,
      updatedAt: today,
    );

    test('어제 활동 + freeze balance=2 → freezeShouldApply=false', () async {
      final freezeRepo = MockStreakFreezeRepository();
      await freezeRepo.grantWeekly('s1', amount: 2);

      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 7, lastPracticeDate: yesterday),
            ),
          ),
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result, isA<StreakWithFreezeResult>());
      expect(result.freezeShouldApply, isFalse);
      expect(result.streakBroken, isFalse);
      expect(result.effectiveCurrentStreak, 7);
    });

    // Phase 3(#1214): provider 가 권고를 즉시 **집행**하므로 반환값은 차감 후
    // 정착 상태다 — freezeShouldApply 는 false, 대신 스트릭이 유지되고 잔량이 준다.
    test('어제 결석 + freeze 보유 → 차감 후 스트릭 유지', () async {
      final freezeRepo = MockStreakFreezeRepository();
      await freezeRepo.grantWeekly('s1', amount: 2);

      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 7, lastPracticeDate: twoDaysAgo),
            ),
          ),
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.streakBroken, isFalse);
      expect(result.effectiveCurrentStreak, 7, reason: '공백이 덮여 유지');
      expect(result.freezeShouldApply, isFalse, reason: '이미 차감 완료');
      expect(result.freezeBalance, lessThan(4), reason: '결석 1일분 차감됨');
    });

    test('어제 결석 + freeze balance=0 → streakBroken=true', () async {
      final freezeRepo = MockStreakFreezeRepository();
      // 이번 주 발급을 소진한 상태 재현 — amount 0 + asOf 로 lastGrantedAt 만 세워
      // provider 의 §14.1 자동 발급이 다시 채우지 않게 한다.
      await freezeRepo.grantWeekly('s1', amount: 0, asOf: today);

      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 0, lastPracticeDate: twoDaysAgo),
            ),
          ),
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.streakBroken, isTrue);
      expect(result.freezeShouldApply, isFalse);
    });

    test('신규 학생 (lastPracticeDate=null) → streakBroken=false', () async {
      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(buildStreak()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.streakBroken, isFalse);
      expect(result.freezeShouldApply, isFalse);
    });
  });
}
