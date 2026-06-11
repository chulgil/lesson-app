import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';

StudentQuest _quest({
  String id = 'q1',
  String studentId = 's1',
  required ChallengeType? type,
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
          _quest(
            id: 'q1',
            type: ChallengeType.practiceMinutes,
            currentValue: 5,
          ),
        );
        await quest.createQuest(
          _quest(id: 'q2', type: ChallengeType.practiceDays, currentValue: 2),
        );
        await quest.createQuest(
          _quest(id: 'q3', type: ChallengeType.streak, currentValue: 1),
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
          type: ChallengeType.practiceMinutes,
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
          type: ChallengeType.practiceMinutes,
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
        _quest(id: 'q1', type: ChallengeType.practiceMinutes, currentValue: 5),
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
}
