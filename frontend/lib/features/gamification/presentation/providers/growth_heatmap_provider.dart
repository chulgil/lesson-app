// Student gamification P1 — growth heatmap providers.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_growth_heatmap_repository.dart';
import '../../domain/entities/growth_heatmap.dart';
import '../../domain/repositories/growth_heatmap_repository.dart';

part 'growth_heatmap_provider.g.dart';

/// P1: Mock 만 사용. P2 에서 BE 구현체 도입 시 환경 분기 추가 (O1 결정).
@Riverpod(keepAlive: true)
GrowthHeatmapRepository growthHeatmapRepository(
  GrowthHeatmapRepositoryRef ref,
) => MockGrowthHeatmapRepository();

@riverpod
Future<GrowthHeatmap> growthHeatmap(
  GrowthHeatmapRef ref,
  String studentId, {
  int yearsBack = 1,
}) async {
  final repo = ref.watch(growthHeatmapRepositoryProvider);
  return repo.getHeatmap(studentId, yearsBack: yearsBack);
}
