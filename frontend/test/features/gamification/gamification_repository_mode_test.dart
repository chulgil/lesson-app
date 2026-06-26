import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/data/services/growth_heatmap_chunk_cache.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/student_quest_provider.dart';

/// #422: gamification 영속 repo 3종이 mockDataMode 에 따라 Mock(DEV 샘플) /
/// Hive(실사용 로컬 영속) 로 분기하는지 검증. provider 는 sync 유지(소비처
/// async 연쇄 회피) — box 는 app_bootstrap 에서 미리 열린다고 가정.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_gamif_mode_');
    Hive.init(tempDir.path);
    // app_bootstrap 이 부팅 시 여는 3 box 를 테스트에서 사전 open.
    await Hive.openBox<String>(GrowthHeatmapChunkCache.boxName);
    await Hive.openBox<String>(HiveStreakFreezeRepository.boxName);
    await Hive.openBox<String>(HiveStudentQuestRepository.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('mock 모드 → Mock repos (DEV 샘플)', () {
    final c = ProviderContainer(
      overrides: [mockDataModeProvider.overrideWithValue(true)],
    );
    addTearDown(c.dispose);
    expect(
      c.read(growthHeatmapRepositoryProvider),
      isA<MockGrowthHeatmapRepository>(),
    );
    expect(
      c.read(streakFreezeRepositoryProvider),
      isA<MockStreakFreezeRepository>(),
    );
    expect(
      c.read(studentQuestRepositoryProvider),
      isA<MockStudentQuestRepository>(),
    );
  });

  test('hive 모드 → Hive repos (실사용 로컬 영속)', () {
    final c = ProviderContainer(
      overrides: [mockDataModeProvider.overrideWithValue(false)],
    );
    addTearDown(c.dispose);
    expect(
      c.read(growthHeatmapRepositoryProvider),
      isA<HiveGrowthHeatmapRepository>(),
    );
    expect(
      c.read(streakFreezeRepositoryProvider),
      isA<HiveStreakFreezeRepository>(),
    );
    expect(
      c.read(studentQuestRepositoryProvider),
      isA<HiveStudentQuestRepository>(),
    );
  });
}
