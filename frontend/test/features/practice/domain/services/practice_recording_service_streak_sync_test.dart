import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_practice_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';

/// G3 PR-C2 — 데이터경로 통합. PracticeRecordingService(모든 연습의 단일
/// 진입점)가 연습일을 practice-logs store 에도 반영해, 표시 SSOT
/// (practiceStreakProvider ← practiceRepository.getStreak) 가 새 연습을
/// 읽도록 한다. recording(0분)은 연습일이 아니므로 제외.
void main() {
  late MockGrowthHeatmapRepository heatmap;
  late MockStudentQuestRepository quest;
  late MockPracticeRepository practiceRepo;
  late PracticeRecordingService service;

  setUp(() {
    heatmap = MockGrowthHeatmapRepository();
    quest = MockStudentQuestRepository();
    practiceRepo = MockPracticeRepository();
    service = PracticeRecordingService(
      heatmapRepository: heatmap,
      questRepository: quest,
      practiceRepository: practiceRepo,
    );
  });

  test('연습(minutes>0)은 practice-logs 에 반영돼 SSOT streak 가 오른다', () async {
    // 시드에 없는 학생 — 사전 streak 0.
    expect((await practiceRepo.getStreak('s_new')).currentStreak, 0);

    await service.recordPractice(
      's_new',
      PracticeEvidence(
        source: PracticeSource.metronome,
        durationMinutes: 5,
        occurredAt: DateTime.now(),
        metadata: const {},
      ),
    );

    // 오늘 연습이 practice-logs 에 반영 → SSOT streak 1.
    expect((await practiceRepo.getStreak('s_new')).currentStreak, 1);
  });

  test('recording(0분)은 연습일이 아니므로 practice-logs 를 건드리지 않는다', () async {
    await service.recordPractice(
      's_new',
      PracticeEvidence(
        source: PracticeSource.recording,
        durationMinutes: 0,
        occurredAt: DateTime.now(),
        metadata: const {},
      ),
    );
    expect((await practiceRepo.getStreak('s_new')).currentStreak, 0);
  });

  test('practiceRepository 미연결(null)이어도 본경로는 회귀 안전', () async {
    final svcNoRepo = PracticeRecordingService(
      heatmapRepository: heatmap,
      questRepository: quest,
    );
    // 예외 없이 heatmap 본경로 진행.
    await svcNoRepo.recordPractice(
      's_new',
      PracticeEvidence(
        source: PracticeSource.metronome,
        durationMinutes: 5,
        occurredAt: DateTime.utc(2026, 6, 11),
        metadata: const {},
      ),
    );
    final hm = await heatmap.getHeatmap('s_new');
    expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 5);
  });
}
