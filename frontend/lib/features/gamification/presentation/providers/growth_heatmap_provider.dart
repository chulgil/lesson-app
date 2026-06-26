// Student gamification P1 — growth heatmap providers.

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/hive_growth_heatmap_repository.dart';
import '../../data/repositories/mock_growth_heatmap_repository.dart';
import '../../data/services/growth_heatmap_chunk_cache.dart';
import '../../domain/entities/growth_heatmap.dart';
import '../../domain/repositories/growth_heatmap_repository.dart';

part 'growth_heatmap_provider.g.dart';

/// P1: Mock 만 사용. P2 에서 BE 구현체 도입 시 환경 분기 추가 (O1 결정).
@Riverpod(keepAlive: true)
GrowthHeatmapRepository growthHeatmapRepository(
  GrowthHeatmapRepositoryRef ref,
) {
  // DEV(mock 샘플) / 실사용(Hive 로컬 영속) 분기. box 는 app_bootstrap
  // 에서 미리 열려 sync 동기 참조 — 소비처 async 연쇄 회피 (#422).
  if (ref.watch(mockDataModeProvider)) return MockGrowthHeatmapRepository();
  return HiveGrowthHeatmapRepository(
    box: Hive.box<String>(GrowthHeatmapChunkCache.boxName),
  );
}

@riverpod
Future<GrowthHeatmap> growthHeatmap(
  GrowthHeatmapRef ref,
  String studentId, {
  int yearsBack = 1,
}) async {
  final repo = ref.watch(growthHeatmapRepositoryProvider);
  return repo.getHeatmap(studentId, yearsBack: yearsBack);
}
