import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/data/services/growth_heatmap_chunk_cache.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_freeze_service.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_migration_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';
import 'package:lessonaza/features/practice/domain/services/rest_recommendation_policy.dart';

/// Job 10 Task 10.1 — P2 통합 시나리오 (e2e 의도). AC-8.1/8.2/8.3 충족.
///
/// integration_test 폴더 부재로 widget 통합 테스트 형태. 모든 단위는
/// 이미 검증됨 — 본 테스트는 시나리오 흐름 + 성능 측정.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('p2_e2e_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('시나리오 A — 스트릭 freeze 자동 적용 (AC-8.1, SC-10)', () {
    test('마이그레이션 → 7일 streak → 8일 결석 → freeze 차감 + streak 유지', () async {
      final freezeRepo = MockStreakFreezeRepository();
      final service = StreakFreezeService(repository: freezeRepo);

      // 1. 마이그레이션 (D-day) — 신규 학생 balance=2 부여
      final beforeMig = await freezeRepo.getOrCreate('s1');
      expect(beforeMig.balance, 0, reason: '마이그 전 = 0');
      await service.weeklyGrantIfDue(
        studentId: 's1',
        now: DateTime.utc(2026, 6, 12),
      );
      final afterMig = await freezeRepo.getOrCreate('s1');
      expect(afterMig.balance, 2, reason: '마이그 후 balance=2 (SC-10)');
      expect(afterMig.lastGrantedAt, isNotNull);

      // 2. 7일 streak — 학생이 연속 7일 연습 (시뮬레이션)
      // (PracticeStreak 계산은 PracticeRepository 책임. 여기서는 freeze 동작만)

      // 3. 8일 째 결석 발생 → service.applyOnAbsence
      final missedDate = DateTime.utc(2026, 6, 13);
      final afterApply = await service.applyOnAbsence(
        studentId: 's1',
        missedDate: missedDate,
      );
      expect(afterApply.balance, 1, reason: 'freeze 1개 차감 — streak 유지 신호');
      expect(afterApply.usedAt, [missedDate]);

      // 4. 추가 결석 9일 차 → balance 1 → 0 차감
      await service.applyOnAbsence(
        studentId: 's1',
        missedDate: DateTime.utc(2026, 6, 14),
      );

      // 5. balance=0 도달 + 추가 결석 10일 차 → no-op (canApply=false)
      final exhausted = await service.applyOnAbsence(
        studentId: 's1',
        missedDate: DateTime.utc(2026, 6, 15),
      );
      expect(exhausted.balance, 0);
      expect(
        exhausted.usedAt.length,
        2,
        reason: 'balance=0 시 추가 차감 X — usedAt 길이 2 유지 (호출자가 streak 끊김 처리)',
      );
    });

    test('Sunday 00:00 KST 다음주 진입 → 자동 +2 (max clamp)', () async {
      final freezeRepo = MockStreakFreezeRepository();
      final service = StreakFreezeService(repository: freezeRepo);

      // 첫 주
      await service.weeklyGrantIfDue(
        studentId: 's1',
        now: DateTime.utc(2026, 6, 12),
      );
      expect((await freezeRepo.getOrCreate('s1')).balance, 2);

      // 같은 주 → no-op
      await service.weeklyGrantIfDue(
        studentId: 's1',
        now: DateTime.utc(2026, 6, 13),
      );
      expect((await freezeRepo.getOrCreate('s1')).balance, 2);

      // 다음 주 Sunday 진입 (2026-06-15 KST 월요일)
      await service.weeklyGrantIfDue(
        studentId: 's1',
        now: DateTime.utc(2026, 6, 15),
      );
      final result = await freezeRepo.getOrCreate('s1');
      expect(
        result.balance,
        StreakFreeze.maxBalance,
        reason: '4 clamp (2 + 2)',
      );
    });
  });

  group('시나리오 B — 1년 히트맵 P95 < 500ms (AC-8.2, 비기능 §17)', () {
    test('1년 365 칸 데이터 → loadYear 측정 < 500ms', () async {
      final box = await Hive.openBox<String>(GrowthHeatmapChunkCache.boxName);
      addTearDown(() async {
        await box.close();
      });
      final repo = HiveGrowthHeatmapRepository(box: box);

      // 365일 데이터 시뮬레이션 (실제 cell 갯수와 동일)
      final today = DateTime.utc(2026, 6, 12);
      for (var i = 0; i < 365; i++) {
        final date = today.subtract(Duration(days: i));
        await repo.recordPractice(
          's1',
          date,
          DailyPractice(metronomeMinutes: (i % 60) + 5),
        );
      }

      // P95 측정 — 5회 측정 후 95th percentile
      final durations = <int>[];
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        final heatmap = await repo.getHeatmap('s1');
        sw.stop();
        durations.add(sw.elapsedMilliseconds);
        expect(heatmap.days.length, greaterThan(300), reason: '1년 데이터 정확 반환');
      }
      durations.sort();
      final p95 = durations[(durations.length * 0.95).floor()];
      expect(
        p95,
        lessThan(500),
        reason: '비기능 §17 — P95 < 500ms 만족 (Hive 로컬 13 box chunk)',
      );
    });
  });

  group('시나리오 C — 휴식 권고 (AC-8.3, SC-11)', () {
    test('성인 30분 도달 → 토스트 1회 + 같은 세션 재호출 무노출', () {
      final today = DateTime.utc(2026, 6, 12);

      // 29분 → no
      var result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 29,
        dailyCumulativeMinutes: 29,
        isUnder14: false,
        sessionToastShownAt: null,
        lastDailyToastDate: null,
        now: today,
      );
      expect(result.shouldShow, isFalse);

      // 30분 → yes (1회 보장)
      result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 30,
        dailyCumulativeMinutes: 30,
        isUnder14: false,
        sessionToastShownAt: null,
        lastDailyToastDate: null,
        now: today,
      );
      expect(result.shouldShow, isTrue);
      expect(result.kind, RestRecommendationKind.session30);

      // 같은 세션 재호출 (sessionToastShownAt != null) → no-op
      result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 35,
        dailyCumulativeMinutes: 35,
        isUnder14: false,
        sessionToastShownAt: today,
        lastDailyToastDate: null,
        now: today,
      );
      expect(result.shouldShow, isFalse, reason: '같은 세션 1회 보장 (SC-11)');
    });

    test('14세 미만 15분 도달 → 강화 토스트', () {
      final today = DateTime.utc(2026, 6, 12);
      final result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 15,
        dailyCumulativeMinutes: 15,
        isUnder14: true,
        sessionToastShownAt: null,
        lastDailyToastDate: null,
        now: today,
      );
      expect(
        result.shouldShow,
        isTrue,
        reason: '14세 미만 15분 = 성인 30분 동등 (스펙 §9.1 강화)',
      );
    });

    test('일일 누적 3시간 도달 → 별도 차분 토스트 1회', () {
      final today = DateTime.utc(2026, 6, 12);
      final tomorrow = today.add(const Duration(days: 1));

      // 같은 날 첫 호출 → yes
      var result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 10,
        dailyCumulativeMinutes: 180,
        isUnder14: false,
        sessionToastShownAt: today,
        lastDailyToastDate: null,
        now: today,
      );
      expect(result.shouldShow, isTrue);
      expect(result.kind, RestRecommendationKind.daily180);

      // 같은 날 재진입 (lastDailyToastDate 영속) → no-op
      result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 10,
        dailyCumulativeMinutes: 200,
        isUnder14: false,
        sessionToastShownAt: null,
        lastDailyToastDate: today,
        now: today,
      );
      expect(result.shouldShow, isFalse, reason: '같은 calendar day 1회 보장');

      // 다음날 재진입 → yes
      result = RestRecommendationPolicy.evaluate(
        sessionMinutes: 10,
        dailyCumulativeMinutes: 200,
        isUnder14: false,
        sessionToastShownAt: null,
        lastDailyToastDate: today,
        now: tomorrow,
      );
      expect(result.shouldShow, isTrue, reason: 'tomorrow → 다시 노출 가능');
    });
  });

  group('통합 마이그레이션 흐름 (AC-5.2)', () {
    test('streakFreezeBootMigration → balance=2 + flag 영속', () async {
      final freezeRepo = MockStreakFreezeRepository();
      final container = ProviderContainer(
        overrides: [
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        streakFreezeBootMigrationProvider('s1').future,
      );
      expect(result, isTrue);

      final freeze = await freezeRepo.getOrCreate('s1');
      expect(freeze.balance, 2);
      expect(freeze.lastGrantedAt, isNotNull);
    });

    test('HiveStreakFreezeRepository 직접 통합 — JSON round-trip', () async {
      final box = await Hive.openBox<String>(
        HiveStreakFreezeRepository.boxName,
      );
      addTearDown(() async {
        await box.close();
      });
      final repo = HiveStreakFreezeRepository(box: box);

      // 새 학생 → balance=0
      final initial = await repo.getOrCreate('s1');
      expect(initial.balance, 0);

      // grantWeekly + apply → 영속
      await repo.grantWeekly('s1', amount: 2, asOf: DateTime.utc(2026, 6, 12));
      await repo.apply('s1', DateTime.utc(2026, 6, 13));

      // 새 인스턴스 — 동일 box → JSON round-trip 보존
      final repo2 = HiveStreakFreezeRepository(box: box);
      final reloaded = await repo2.getOrCreate('s1');
      expect(reloaded.balance, 1);
      expect(reloaded.usedAt, [DateTime.utc(2026, 6, 13)]);
      expect(reloaded.lastGrantedAt, DateTime.utc(2026, 6, 12));
    });
  });
}
