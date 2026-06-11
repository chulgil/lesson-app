// Practice recording service provider — 4 경로 wiring hub.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../gamification/presentation/providers/growth_heatmap_provider.dart';
import '../../../gamification/presentation/providers/student_quest_provider.dart';
import '../../domain/services/practice_recording_service.dart';

part 'practice_recording_provider.g.dart';

/// P1: 모든 연습 evidence 의 단일 진입점 서비스 provider.
///
/// 4 경로 wiring (메트로놈/튜너/YouTube/녹음/수동) 은 본 provider 를 통해
/// service 에 접근. 의존성: growthHeatmapRepository + studentQuestRepository.
@Riverpod(keepAlive: true)
PracticeRecordingService practiceRecordingService(
  PracticeRecordingServiceRef ref,
) {
  return PracticeRecordingService(
    heatmapRepository: ref.watch(growthHeatmapRepositoryProvider),
    questRepository: ref.watch(studentQuestRepositoryProvider),
  );
}
