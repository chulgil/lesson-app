import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repertoire_repository.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/empty_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

StudentQuest _quest({
  String id = 'q1',
  String studentId = 's1',
  required ActivityType? type,
  int currentValue = 0,
  bool isCompleted = false,
}) => StudentQuest(
  id: id,
  studentId: studentId,
  origin: QuestOrigin.selfCreated,
  title: 'q',
  type: type,
  targetValue: 60,
  currentValue: currentValue,
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 30),
  isCompleted: isCompleted,
);

/// upsertMark 가 throw 하는 stub — #424 가드(본경로 보호) 검증용.
class _ThrowingJournalRepository extends EmptyPracticeJournalRepository {
  @override
  Future<void> upsertMark(
    String childProfileId,
    DateTime date,
    MarkIntensity intensity,
  ) async => throw UnsupportedError('boom');
}

/// incrementPracticeCount 호출을 캡처하는 fake — 선택적 곡 연결(§1.2) 검증용.
class _RecordingRepertoireRepo implements PracticeRepertoireRepository {
  final List<({String sectionId, int seconds})> credited = [];

  @override
  Future<PracticeSection> incrementPracticeCount(
    String sectionId,
    int practiceSeconds,
  ) async {
    credited.add((sectionId: sectionId, seconds: practiceSeconds));
    return PracticeSection(
      id: sectionId,
      repertoireId: 'rep',
      pieceName: 'p',
      startMeasure: 1,
      endMeasure: 2,
      createdAt: DateTime.utc(2026, 6, 11),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockGrowthHeatmapRepository heatmap;
  late MockStudentQuestRepository quest;
  late PracticeRecordingService service;

  setUp(() {
    heatmap = MockGrowthHeatmapRepository();
    quest = MockStudentQuestRepository();
    service = PracticeRecordingService(
      heatmapRepository: heatmap,
      questRepository: quest,
    );
  });

  group('recordPractice — heatmap routing per source', () {
    test('metronome source → metronomeMinutes += duration', () async {
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11),
          metadata: const {},
        ),
      );
      final hm = await heatmap.getHeatmap('s1');
      final cell = hm.days[DateTime.utc(2026, 6, 11)];
      expect(cell?.metronomeMinutes, 5);
      expect(cell?.tunerMinutes, 0);
      expect(cell?.totalMinutes, 5);
    });

    test('tuner / youtube / manual map to their respective fields', () async {
      final base = DateTime.utc(2026, 6, 11);
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.tuner,
          durationMinutes: 3,
          occurredAt: base,
          metadata: const {},
        ),
      );
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.youtube,
          durationMinutes: 10,
          occurredAt: base,
          metadata: const {},
          videoId: 'abc',
        ),
      );
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.manual,
          durationMinutes: 7,
          occurredAt: base,
          metadata: const {},
        ),
      );
      final hm = await heatmap.getHeatmap('s1');
      final cell = hm.days[base];
      expect(cell?.tunerMinutes, 3);
      expect(cell?.youtubeMinutes, 10);
      expect(cell?.manualMinutes, 7);
      expect(cell?.totalMinutes, 20);
    });

    test(
      'recording source → recordingCount += 1 (durationMinutes ignored)',
      () async {
        await service.recordPractice(
          's1',
          PracticeEvidence(
            source: PracticeSource.recording,
            durationMinutes: 0,
            occurredAt: DateTime.utc(2026, 6, 11),
            metadata: const {},
          ),
        );
        await service.recordPractice(
          's1',
          PracticeEvidence(
            source: PracticeSource.recording,
            durationMinutes: 99, // 무시
            occurredAt: DateTime.utc(2026, 6, 11),
            metadata: const {},
          ),
        );
        final hm = await heatmap.getHeatmap('s1');
        final cell = hm.days[DateTime.utc(2026, 6, 11)];
        expect(cell?.recordingCount, 2);
        expect(cell?.totalMinutes, 0); // recording 은 totalMinutes 미반영
      },
    );

    test('occurredAt normalized to UTC midnight before persistence', () async {
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11, 14, 30, 45),
          metadata: const {},
        ),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 5);
    });
  });

  group('recordPractice — quest progress wiring', () {
    test(
      'updates currentValue of active practiceMinutes quests only',
      () async {
        await quest.createQuest(
          _quest(id: 'q1', type: ActivityType.practiceMinutes, currentValue: 5),
        );
        await quest.createQuest(
          _quest(id: 'q2', type: ActivityType.practiceDays, currentValue: 2),
        );
        await quest.createQuest(
          _quest(id: 'q3', type: ActivityType.streak, currentValue: 1),
        );

        await service.recordPractice(
          's1',
          PracticeEvidence(
            source: PracticeSource.metronome,
            durationMinutes: 7,
            occurredAt: DateTime.utc(2026, 6, 11),
            metadata: const {},
          ),
        );

        final byOrigin = await quest.getQuestsByOrigin(
          's1',
          QuestOrigin.selfCreated,
        );
        final q1 = byOrigin.firstWhere((q) => q.id == 'q1');
        final q2 = byOrigin.firstWhere((q) => q.id == 'q2');
        final q3 = byOrigin.firstWhere((q) => q.id == 'q3');
        expect(q1.currentValue, 12); // 5 + 7
        expect(q2.currentValue, 2); // 무변 (type 불일치)
        expect(q3.currentValue, 1); // 무변
      },
    );

    test('does not update completed quests', () async {
      await quest.createQuest(
        _quest(
          id: 'q-done',
          type: ActivityType.practiceMinutes,
          currentValue: 60,
          isCompleted: true,
        ),
      );
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11),
          metadata: const {},
        ),
      );
      final all = await quest.getQuestsByOrigin('s1', QuestOrigin.selfCreated);
      expect(all.single.currentValue, 60); // 무변
    });

    test('does not update quests of other students', () async {
      await quest.createQuest(
        _quest(
          id: 'q-other',
          studentId: 's2',
          type: ActivityType.practiceMinutes,
          currentValue: 5,
        ),
      );
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 7,
          occurredAt: DateTime.utc(2026, 6, 11),
          metadata: const {},
        ),
      );
      final all = await quest.getQuestsByOrigin('s2', QuestOrigin.selfCreated);
      expect(all.single.currentValue, 5); // 무변
    });

    test('recording source does not affect practiceMinutes quests', () async {
      await quest.createQuest(
        _quest(id: 'q1', type: ActivityType.practiceMinutes, currentValue: 5),
      );
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.recording,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11),
          metadata: const {},
        ),
      );
      final all = await quest.getQuestsByOrigin('s1', QuestOrigin.selfCreated);
      expect(all.single.currentValue, 5); // 무변 (recording 은 분 단위 X)
    });
  });

  group('#424 — journal 훅 가드', () {
    test('journal upsertMark throw 해도 heatmap+quest 본경로 진행', () async {
      await quest.createQuest(
        _quest(id: 'q1', type: ActivityType.practiceMinutes, currentValue: 5),
      );
      final throwingService = PracticeRecordingService(
        heatmapRepository: heatmap,
        questRepository: quest,
        journalRepository: _ThrowingJournalRepository(),
      );
      // 가드가 throw 를 삼켜 본경로가 완료되어야 한다 (예외 전파 X).
      await throwingService.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 7,
          occurredAt: DateTime.utc(2026, 6, 11),
          metadata: const {},
        ),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 7);
      final all = await quest.getQuestsByOrigin('s1', QuestOrigin.selfCreated);
      expect(all.single.currentValue, 12); // 5 + 7 — 가드 없으면 throw 로 스킵
    });
  });

  group('선택적 곡 연결 (§1.2) — 섹션 연습시간 크레딧', () {
    late _RecordingRepertoireRepo repertoire;
    late PracticeRecordingService svcWithRepertoire;

    setUp(() {
      repertoire = _RecordingRepertoireRepo();
      svcWithRepertoire = PracticeRecordingService(
        heatmapRepository: heatmap,
        questRepository: quest,
        repertoireRepository: repertoire,
      );
    });

    test(
      'sectionId 있는 metronome → 섹션에 minutes*60 초 크레딧 + heatmap 본경로 유지',
      () async {
        await svcWithRepertoire.recordPractice(
          's1',
          PracticeEvidence(
            source: PracticeSource.metronome,
            durationMinutes: 5,
            occurredAt: DateTime.utc(2026, 6, 11),
            sectionId: 'sec-1',
          ),
        );
        expect(repertoire.credited, [(sectionId: 'sec-1', seconds: 300)]);
        final hm = await heatmap.getHeatmap('s1');
        expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 5);
      },
    );

    test('sectionId 없으면 섹션 크레딧 없음 (무마찰 홈 시작)', () async {
      await svcWithRepertoire.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11),
        ),
      );
      expect(repertoire.credited, isEmpty);
    });

    test('recording source 는 섹션 크레딧 안 함 (녹음 완료 경로가 별도 누적 — 이중계산 방지)', () async {
      await svcWithRepertoire.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.recording,
          durationMinutes: 0,
          occurredAt: DateTime.utc(2026, 6, 11),
          sectionId: 'sec-1',
        ),
      );
      expect(repertoire.credited, isEmpty);
    });

    test('0분 metronome 은 섹션 크레딧 안 함', () async {
      await svcWithRepertoire.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 0,
          occurredAt: DateTime.utc(2026, 6, 11),
          sectionId: 'sec-1',
        ),
      );
      expect(repertoire.credited, isEmpty);
    });

    test('repertoireRepository 미연결(null)이어도 본경로 회귀 안전', () async {
      // service = repertoireRepository 없이 생성된 인스턴스 (setUp).
      await service.recordPractice(
        's1',
        PracticeEvidence(
          source: PracticeSource.metronome,
          durationMinutes: 5,
          occurredAt: DateTime.utc(2026, 6, 11),
          sectionId: 'sec-1',
        ),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 5);
    });
  });
}
