import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_student_quest_repository.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';
import 'package:lessonaza/features/practice/domain/services/practice_source_loggers.dart';

void main() {
  late MockGrowthHeatmapRepository heatmap;
  late MockStudentQuestRepository quest;
  late PracticeSourceLoggers loggers;

  setUp(() {
    heatmap = MockGrowthHeatmapRepository();
    quest = MockStudentQuestRepository();
    loggers = PracticeSourceLoggers(
      PracticeRecordingService(
        heatmapRepository: heatmap,
        questRepository: quest,
      ),
    );
  });

  group('logMetronome', () {
    test('records metronome evidence with bpm metadata', () async {
      await loggers.logMetronome(
        studentId: 's1',
        durationMinutes: 5,
        bpm: 100,
        occurredAt: DateTime.utc(2026, 6, 11),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.metronomeMinutes, 5);
    });

    test('no-op when durationMinutes <= 0', () async {
      await loggers.logMetronome(studentId: 's1', durationMinutes: 0);
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days, isEmpty);
    });
  });

  group('logTuner / logManual', () {
    test('tuner routes to tunerMinutes', () async {
      await loggers.logTuner(
        studentId: 's1',
        durationMinutes: 3,
        occurredAt: DateTime.utc(2026, 6, 11),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.tunerMinutes, 3);
    });

    test(
      'manual routes to manualMinutes with optional note metadata',
      () async {
        await loggers.logManual(
          studentId: 's1',
          durationMinutes: 10,
          note: '왈츠 연습',
          occurredAt: DateTime.utc(2026, 6, 11),
        );
        final hm = await heatmap.getHeatmap('s1');
        expect(hm.days[DateTime.utc(2026, 6, 11)]?.manualMinutes, 10);
      },
    );
  });

  group('logYoutubeEnded', () {
    test('routes to youtubeMinutes with videoId', () async {
      await loggers.logYoutubeEnded(
        studentId: 's1',
        durationMinutes: 4,
        videoId: 'abc123',
        occurredAt: DateTime.utc(2026, 6, 11),
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days[DateTime.utc(2026, 6, 11)]?.youtubeMinutes, 4);
    });

    test('no-op when durationMinutes <= 0 (영상 시작 직후 onEnded 같은 비정상)', () async {
      await loggers.logYoutubeEnded(
        studentId: 's1',
        durationMinutes: 0,
        videoId: 'abc',
      );
      final hm = await heatmap.getHeatmap('s1');
      expect(hm.days, isEmpty);
    });
  });

  group('logRecording', () {
    test('records recordingCount += 1 regardless of duration', () async {
      await loggers.logRecording(
        studentId: 's1',
        occurredAt: DateTime.utc(2026, 6, 11),
      );
      await loggers.logRecording(
        studentId: 's1',
        occurredAt: DateTime.utc(2026, 6, 11),
      );
      final hm = await heatmap.getHeatmap('s1');
      final cell = hm.days[DateTime.utc(2026, 6, 11)];
      expect(cell?.recordingCount, 2);
      expect(cell?.totalMinutes, 0);
    });
  });
}
