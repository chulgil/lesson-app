// #1214 Phase 3 — freeze/forgiveness 배선 회귀 테스트.
//
// 표시 스트릭이 "하루 빠지면 0" 으로 리셋되지 않고, freeze 가 공백을 덮는지
// 검증한다. 스펙 §14.1 (주간 발급) / §14.2 (freeze 1개 = 결석 1일).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/presentation/providers/effective_streak_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_log.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repository.dart';
import 'package:lessonaza/features/practice/domain/services/streak_calculator.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repository_provider.dart';

/// raw streak 을 **실제 SSOT 알고리즘**(StreakCalculator)으로 로그에서 계산한다.
///
/// 손으로 지어낸 불일치 상태(로그는 공백인데 currentStreak=7)를 쓰면 계산기가
/// 실제로 무엇을 하는지 검증하지 못한다 — 로그가 유일한 입력이어야 한다.
class _LogBackedPracticeRepository implements PracticeRepository {
  _LogBackedPracticeRepository(this.logs);

  final List<PracticeLog> logs;

  @override
  Future<List<PracticeLog>> getPracticeLogs(String studentId) async => logs;

  @override
  Future<PracticeStreak> getStreak(String studentId) async {
    final summary = StreakCalculator.fromLogs(logs);
    return PracticeStreak(
      id: 'streak_$studentId',
      studentId: studentId,
      currentStreak: summary.currentStreak,
      longestStreak: summary.longestStreak,
      lastPracticeDate: summary.lastPracticeDate,
      updatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  /// [endsAt] 에서 끝나는 [days] 일 연속 연습 로그.
  List<PracticeLog> practiceChain({
    required DateTime endsAt,
    required int days,
  }) => [
    for (var i = 0; i < days; i++)
      PracticeLog(
        id: 'log_$i',
        studentId: 's1',
        date: endsAt.subtract(Duration(days: i)),
        totalMinutes: 30,
        createdAt: endsAt.subtract(Duration(days: i)),
      ),
  ];

  ProviderContainer containerFor(
    List<PracticeLog> logs,
    MockStreakFreezeRepository freezeRepo,
  ) => ProviderContainer(
    overrides: [
      practiceRepositoryProvider.overrideWithValue(
        _LogBackedPracticeRepository(logs),
      ),
      streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
    ],
  );

  group('#1214 freeze forgiveness — 표시 스트릭', () {
    test('공백 1일 <= freeze 잔량 → 스트릭 유지 (0 리셋 X) + freeze 1개 차감', () async {
      // 7일 연속 후 어제 하루 결석. 정규 SSOT 는 여기서 0 으로 끊는다.
      final logs = practiceChain(
        endsAt: today.subtract(const Duration(days: 2)),
        days: 7,
      );
      final freezeRepo = MockStreakFreezeRepository();
      final container = containerFor(logs, freezeRepo);
      addTearDown(container.dispose);

      // 전제: raw(정규 스트릭)는 실제로 0 으로 끊겨 있다.
      final raw = await container
          .read(practiceRepositoryProvider)
          .getStreak('s1');
      expect(raw.currentStreak, 0, reason: '정규 SSOT 는 공백 하루에 끊긴다');

      final result = await container.read(effectiveStreakProvider('s1').future);

      expect(result.effectiveCurrentStreak, 7, reason: 'freeze 가 공백을 덮어 유지');
      expect(result.streakBroken, isFalse);
      // §14.1 주간 발급 +2 → §14.2 결석 1일 차감 = 잔량 1
      expect(result.freezeBalance, 1);
    });

    test('공백 3일 > freeze 잔량 2 → 스트릭 리셋 + 차감 없음', () async {
      final logs = practiceChain(
        endsAt: today.subtract(const Duration(days: 4)),
        days: 7,
      );
      final freezeRepo = MockStreakFreezeRepository();
      final container = containerFor(logs, freezeRepo);
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);

      expect(result.effectiveCurrentStreak, 0, reason: 'freeze 로 못 덮는 공백');
      expect(result.streakBroken, isTrue);
      expect(result.freezeBalance, 2, reason: '덮을 수 없으면 낭비 차감 금지');
    });

    test('§14.1 주간 발급 trigger — 최초 조회 시 balance 2 로 채워진다', () async {
      final logs = practiceChain(endsAt: today, days: 3);
      final freezeRepo = MockStreakFreezeRepository();
      final container = containerFor(logs, freezeRepo);
      addTearDown(container.dispose);

      final before = await freezeRepo.getOrCreate('s1');
      expect(before.balance, 0, reason: '발급 전');

      final result = await container.read(effectiveStreakProvider('s1').future);

      expect(result.freezeBalance, 2);
      expect(result.effectiveCurrentStreak, 3);
    });

    test('재조회해도 같은 결석일을 두 번 차감하지 않는다 (멱등)', () async {
      final logs = practiceChain(
        endsAt: today.subtract(const Duration(days: 2)),
        days: 7,
      );
      final freezeRepo = MockStreakFreezeRepository();
      final container = containerFor(logs, freezeRepo);
      addTearDown(container.dispose);

      final first = await container.read(effectiveStreakProvider('s1').future);
      container.invalidate(effectiveStreakProvider('s1'));
      final second = await container.read(effectiveStreakProvider('s1').future);

      expect(first.freezeBalance, 1);
      expect(second.freezeBalance, 1, reason: '재빌드가 잔량을 갉아먹으면 안 된다');
      expect(second.effectiveCurrentStreak, 7);
    });

    test('freeze 로 이어진 뒤 다시 연습하면 스트릭이 이어서 늘어난다', () async {
      // 7일 연속(…~D) + D+1 결석(freeze) + 오늘(D+2) 연습 → 8
      final base = today.subtract(const Duration(days: 2));
      final logs = <PracticeLog>[
        ...practiceChain(endsAt: base, days: 7),
        PracticeLog(
          id: 'log_today',
          studentId: 's1',
          date: today,
          totalMinutes: 30,
          createdAt: today,
        ),
      ];
      final freezeRepo = MockStreakFreezeRepository();
      // 어제 결석분은 이미 차감된 상태로 시작 (전날 앱 진입 시 적용됨).
      await freezeRepo.grantWeekly('s1', amount: 2, asOf: today);
      await freezeRepo.apply('s1', today.subtract(const Duration(days: 1)));

      final container = containerFor(logs, freezeRepo);
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);

      expect(
        result.effectiveCurrentStreak,
        8,
        reason: '동결일은 체인을 잇되 일수에는 더하지 않는다',
      );
      expect(result.streakBroken, isFalse);
    });
  });
}
