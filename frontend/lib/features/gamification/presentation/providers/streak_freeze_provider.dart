// Student gamification P2 — StreakFreeze providers (Job 4 Task 4.2).

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/hive_streak_freeze_repository.dart';
import '../../data/repositories/mock_streak_freeze_repository.dart';
import '../../domain/entities/streak_freeze.dart';
import '../../domain/repositories/streak_freeze_repository.dart';
import '../../domain/services/streak_freeze_service.dart';

part 'streak_freeze_provider.g.dart';

/// P2: Mock 우선 (P1 패턴 일관). HiveStreakFreezeRepository 운영 통합은 Job 5
/// D-day 마이그레이션 + Job 10 e2e 단계에서 환경 분기 추가.
@Riverpod(keepAlive: true)
StreakFreezeRepository streakFreezeRepository(StreakFreezeRepositoryRef ref) {
  // DEV(mock) / 실사용(Hive 로컬 영속) 분기 — box 부팅 사전 open (#422).
  if (ref.watch(mockDataModeProvider)) return MockStreakFreezeRepository();
  return HiveStreakFreezeRepository(
    box: Hive.box<String>(HiveStreakFreezeRepository.boxName),
  );
}

/// 자동 발급/적용/시험 모드 로직 — KST 정렬 책임.
@Riverpod(keepAlive: true)
StreakFreezeService streakFreezeService(StreakFreezeServiceRef ref) =>
    StreakFreezeService(repository: ref.watch(streakFreezeRepositoryProvider));

/// 학생별 StreakFreeze 조회 — autoDispose (Family).
@riverpod
Future<StreakFreeze> studentStreakFreeze(
  StudentStreakFreezeRef ref,
  String studentId,
) async {
  final repo = ref.watch(streakFreezeRepositoryProvider);
  return repo.getOrCreate(studentId);
}
