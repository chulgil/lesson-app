import '../../../gamification/domain/entities/challenge.dart';
import '../../../gamification/domain/entities/daily_practice.dart';
import '../../../gamification/domain/entities/daily_practice_effort.dart';
import '../../../gamification/domain/repositories/growth_heatmap_repository.dart';
import '../../../gamification/domain/repositories/student_quest_repository.dart';
import '../../../practice_journal/domain/entities/practice_mark.dart';
import '../../../practice_journal/domain/journal_thresholds.dart';
import '../../../practice_journal/domain/repositories/practice_journal_repository.dart';
import '../entities/practice_evidence.dart';
import '../entities/practice_evidence_effort.dart';
import '../repositories/practice_repository.dart';

/// 모든 연습 evidence 의 단일 진입점 서비스.
///
/// 스펙 §6.0 의존성 그래프 / 플랜 Job 3 Task 3.2. 4 경로 wiring (메트로놈/
/// 튜너/YouTube/녹음/수동) 의 hub.
///
/// 책임:
/// 1. [GrowthHeatmapRepository.recordPractice] 호출 — [PracticeSource] 에
///    대응하는 [DailyPractice] 필드 1개만 채워서 전달.
/// 2. 학생의 active [ActivityType.practiceMinutes] quest 진척 갱신
///    (recording 은 분 단위 X — 진척 무영향).
///
/// 단방향 의존: Service → Repository. 역방향 금지.
class PracticeRecordingService {
  final GrowthHeatmapRepository heatmapRepository;
  final StudentQuestRepository questRepository;

  /// 연습장(practice_journal) 도장 파생용. 미연결 시 null — 회귀 안전.
  final PracticeJournalRepository? journalRepository;

  /// 스트릭 SSOT 동기화용 — 연습일을 practice-logs store 에도 반영해
  /// practiceStreakProvider(표시 SSOT) 가 새 연습을 읽도록 한다 (G3 PR-C2).
  /// 미연결 시 null — best-effort, 본경로(heatmap/quest) 회귀 안전.
  final PracticeRepository? practiceRepository;

  const PracticeRecordingService({
    required this.heatmapRepository,
    required this.questRepository,
    this.journalRepository,
    this.practiceRepository,
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
    // *** practice_journal 훅: 연습 → 연습 도장 파생(이중 기록 0) ***
    final journalIntensity =
        evidence.durationMinutes >= JournalThresholds.fullMinutes
            ? MarkIntensity.full
            : MarkIntensity.short;
    // 연습장 도장은 best-effort — journal 미가용/실패가 본경로(heatmap/quest)를
    // 막지 않도록 가드 (#424). EmptyPracticeJournalRepository 는 no-op 이지만
    // 미래 remote 구현이 throw 해도 quest bump 가 스킵되지 않게 한다.
    try {
      await journalRepository?.upsertMark(studentId, date, journalIntensity);
    } catch (_) {
      // 도장 파생 실패는 조용히 무시 — 본경로는 계속 진행한다.
    }
    // 스트릭 SSOT 동기화: 연습일(minutes>0)을 practice-logs store 에도 반영해
    // practiceStreakProvider(표시 SSOT)가 새 연습을 읽도록 한다 (G3 PR-C2).
    // recording(0분)은 연습일 아님(스펙 §1 minutes 게이트)→ 제외. best-effort —
    // 실패가 본경로(heatmap/quest)를 막지 않도록 가드.
    if (evidence.source != PracticeSource.recording &&
        evidence.durationMinutes > 0) {
      try {
        await practiceRepository?.recordPractice(studentId);
      } catch (_) {
        // streak 동기화 실패는 조용히 무시 — 본경로는 계속 진행한다.
      }
    }
    if (evidence.source != PracticeSource.recording) {
      await _bumpPracticeMinutesQuests(studentId, evidence.durationMinutes);
    }
  }

  DailyPractice _toDailyPractice(PracticeEvidence evidence) =>
      evidence.source.effortSource.toDailyPractice(evidence.durationMinutes);

  Future<void> _bumpPracticeMinutesQuests(String studentId, int minutes) async {
    if (minutes <= 0) return;
    final active = await questRepository.getActiveQuests(studentId);
    for (final q in active) {
      if (q.type != ActivityType.practiceMinutes) continue;
      await questRepository.updateProgress(q.id, q.currentValue + minutes);
    }
  }
}
