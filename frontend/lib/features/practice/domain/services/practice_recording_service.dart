import '../../../gamification/domain/entities/challenge.dart';
import '../../../gamification/domain/entities/daily_practice.dart';
import '../../../gamification/domain/repositories/growth_heatmap_repository.dart';
import '../../../gamification/domain/repositories/student_quest_repository.dart';
import '../entities/practice_evidence.dart';

/// 모든 연습 evidence 의 단일 진입점 서비스.
///
/// 스펙 §6.0 의존성 그래프 / 플랜 Job 3 Task 3.2. 4 경로 wiring (메트로놈/
/// 튜너/YouTube/녹음/수동) 의 hub.
///
/// 책임:
/// 1. [GrowthHeatmapRepository.recordPractice] 호출 — [PracticeSource] 에
///    대응하는 [DailyPractice] 필드 1개만 채워서 전달.
/// 2. 학생의 active [ChallengeType.practiceMinutes] quest 진척 갱신
///    (recording 은 분 단위 X — 진척 무영향).
///
/// 단방향 의존: Service → Repository. 역방향 금지.
class PracticeRecordingService {
  final GrowthHeatmapRepository heatmapRepository;
  final StudentQuestRepository questRepository;

  const PracticeRecordingService({
    required this.heatmapRepository,
    required this.questRepository,
  });

  Future<void> recordPractice(
    String studentId,
    PracticeEvidence evidence,
  ) async {
    final date = DateTime.utc(
      evidence.occurredAt.year,
      evidence.occurredAt.month,
      evidence.occurredAt.day,
    );
    await heatmapRepository.recordPractice(
      studentId,
      date,
      _toDailyPractice(evidence),
    );
    if (evidence.source != PracticeSource.recording) {
      await _bumpPracticeMinutesQuests(studentId, evidence.durationMinutes);
    }
  }

  DailyPractice _toDailyPractice(PracticeEvidence evidence) {
    switch (evidence.source) {
      case PracticeSource.metronome:
        return DailyPractice(metronomeMinutes: evidence.durationMinutes);
      case PracticeSource.tuner:
        return DailyPractice(tunerMinutes: evidence.durationMinutes);
      case PracticeSource.youtube:
        return DailyPractice(youtubeMinutes: evidence.durationMinutes);
      case PracticeSource.manual:
        return DailyPractice(manualMinutes: evidence.durationMinutes);
      case PracticeSource.recording:
        return const DailyPractice(recordingCount: 1);
    }
  }

  Future<void> _bumpPracticeMinutesQuests(String studentId, int minutes) async {
    if (minutes <= 0) return;
    final active = await questRepository.getActiveQuests(studentId);
    for (final q in active) {
      if (q.type != ChallengeType.practiceMinutes) continue;
      await questRepository.updateProgress(q.id, q.currentValue + minutes);
    }
  }
}
