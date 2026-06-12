import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_migration_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_streak_migration_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(StreakFreezeMigrationKeys.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('streakFreezeBootMigration — AC-5.2', () {
    test('새 학생 (flag 미설정) → balance=2 + flag 저장', () async {
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

      // flag 영속 확인 — 재호출 시 service 호출 0
      final box = await Hive.openBox(StreakFreezeMigrationKeys.boxName);
      expect(box.get(StreakFreezeMigrationKeys.doneKey('s1')), isTrue);
      await box.close();
    });

    test('flag 설정 후 재실행 → no-op (idempotent)', () async {
      final freezeRepo = MockStreakFreezeRepository();
      final container1 = ProviderContainer(
        overrides: [
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container1.dispose);

      // 첫 마이그레이션
      await container1.read(streakFreezeBootMigrationProvider('s1').future);
      final firstBalance = (await freezeRepo.getOrCreate('s1')).balance;
      final firstLastGrant = (await freezeRepo.getOrCreate('s1')).lastGrantedAt;
      expect(firstBalance, 2);

      // freeze 적용 시뮬레이션 (balance 줄어듦)
      await freezeRepo.apply('s1', DateTime.now());

      // 새 container — 마이그레이션 재실행 시도
      final container2 = ProviderContainer(
        overrides: [
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container2.dispose);

      await container2.read(streakFreezeBootMigrationProvider('s1').future);

      final after = await freezeRepo.getOrCreate('s1');
      expect(
        after.balance,
        1,
        reason: 'flag idempotent — 재마이그레이션 0 = balance 변경 없음',
      );
      expect(after.lastGrantedAt, firstLastGrant, reason: 'lastGrantedAt 갱신 X');
    });

    test('학생별 flag 격리 — s1 마이그레이션 후 s2 첫 진입은 정상 동작', () async {
      final freezeRepo = MockStreakFreezeRepository();
      final container = ProviderContainer(
        overrides: [
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(streakFreezeBootMigrationProvider('s1').future);
      await container.read(streakFreezeBootMigrationProvider('s2').future);

      final s1 = await freezeRepo.getOrCreate('s1');
      final s2 = await freezeRepo.getOrCreate('s2');
      expect(s1.balance, 2);
      expect(s2.balance, 2);
    });
  });

  group('streakFreezeMigrationToastShown — AC-5.3', () {
    test('첫 호출 시 false (미표시)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final shown = await container.read(
        streakFreezeMigrationToastShownProvider('s1').future,
      );
      expect(shown, isFalse);
    });

    test('markStreakFreezeMigrationToastShown 후 true 영속', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // mark 호출
      await StreakFreezeMigrationToast.markShown('s1');

      // 새 container 에서도 영속 확인
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final shown = await container2.read(
        streakFreezeMigrationToastShownProvider('s1').future,
      );
      expect(shown, isTrue);
    });

    test('학생별 토스트 flag 격리', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await StreakFreezeMigrationToast.markShown('s1');

      final shownS1 = await container.read(
        streakFreezeMigrationToastShownProvider('s1').future,
      );
      final shownS2 = await container.read(
        streakFreezeMigrationToastShownProvider('s2').future,
      );
      expect(shownS1, isTrue);
      expect(shownS2, isFalse);
    });
  });
}
