// Regression test — SectionDetailRecordingMixin.stopRecording (곡 상세 녹음,
// the only reachable recording path before the 녹음 practice-tool wiring) did
// not fire PracticeSourceLoggers.logRecording, so those recordings never
// counted toward the journal/growth-heatmap/points, unlike
// RecordingNotifier.stopRecording (see recording_provider_heatmap_wiring_test.dart,
// which this test mirrors).
//
// Strategy: mix SectionDetailRecordingMixin into a minimal test widget, arm
// its recording state directly (bypassing the native-audio startRecording()
// path, out of scope here), and drive stopRecording() through a fake
// recorder + fake repository. A spy on practiceSourceLoggersProvider counts
// logRecording calls.
//
// stopRecording() also probes the saved file's real duration via just_audio's
// AudioPlayer (_getActualFileDuration). Two test-only fixes were needed to
// keep that from hanging:
//   1. JustAudioPlatform.instance is swapped for a minimal fake whose load()
//      throws immediately — _load()'s own try/catch converts that into a
//      PlayerException, which _getActualFileDuration's catch already handles
//      by returning null (same fallback a real "file unreadable" error takes).
//   2. The stopRecording() call is wrapped in tester.runAsync(): inside
//      testWidgets(), AudioPlayer's internal Future chain never resolves
//      without it (confirmed via bisection — the exact same fake resolves
//      instantly in a plain test(), and instantly here too once wrapped in
//      runAsync — a testWidgets()-only interaction between just_audio's
//      plugin-activation Futures and the widget-test zone, unrelated to
//      this mixin or the logging wiring under test).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:lessonaza/core/audio/audio_recorder_service.dart';
import 'package:lessonaza/features/gamification/domain/entities/gamification.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/domain/repositories/student_quest_repository.dart';
import 'package:lessonaza/features/gamification/gamification_facade.dart'
    show PointAwardNotifier, pointAwardNotifierProvider;
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repertoire_repository.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';
import 'package:lessonaza/features/practice/domain/services/practice_source_loggers.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_recording_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_repository_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_provider.dart'
    show audioRecorderServiceProvider;
import 'package:lessonaza/features/practice/presentation/screens/section_detail_recording_mixin.dart';

import '../../../../test_helper.dart';

/// Fake just_audio platform. Only the calls AudioPlayer makes unconditionally
/// while activating are implemented (setVolume/setSpeed/setLoopMode/
/// setShuffleMode/dispose); load() throws so _getActualFileDuration's
/// try/catch takes the "duration unknown" fallback instead of hanging.
class _FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  _FakeAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      const Stream.empty();

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    throw PlatformException(
      code: 'test_stub',
      message: 'no real audio backend in test',
    );
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async =>
      DisposeResponse.fromMap(const {});
}

class _FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return _FakeAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse.fromMap(const {});
  }
}

/// Counts logRecording calls; forwards nothing to a real service.
class _SpyLoggers extends PracticeSourceLoggers {
  _SpyLoggers() : super(_UnusedService());

  int recordingCalls = 0;
  String? lastStudentId;

  @override
  Future<void> logRecording({
    required String studentId,
    DateTime? occurredAt,
  }) async {
    recordingCalls++;
    lastStudentId = studentId;
  }
}

/// Never invoked — _SpyLoggers overrides every method it needs.
class _UnusedService extends PracticeRecordingService {
  _UnusedService()
    : super(
        heatmapRepository: _ThrowingHeatmap(),
        questRepository: _ThrowingQuest(),
      );
}

class _ThrowingHeatmap implements GrowthHeatmapRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('should not be called');
}

class _ThrowingQuest implements StudentQuestRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('should not be called');
}

/// Fake recorder — only stopRecording() is exercised (armRecording bypasses
/// the native-audio startRecording() path).
class _FakeRecorder extends AudioRecorderService {
  @override
  Future<String?> stopRecording() async => '/tmp/section_recording.m4a';
}

/// In-memory fake — only the two repository methods the mixin's stopRecording
/// touches (createRecording, incrementPracticeCount).
class _FakeSectionRecordingRepository implements PracticeRepertoireRepository {
  final List<PracticeRecording> createdRecordings = [];
  int incrementPracticeCalls = 0;

  @override
  Future<PracticeRecording> createRecording(PracticeRecording recording) async {
    final saved = recording.copyWith(id: 'rec_${createdRecordings.length + 1}');
    createdRecordings.add(saved);
    return saved;
  }

  @override
  Future<PracticeSection> incrementPracticeCount(
    String sectionId,
    int practiceSeconds,
  ) async {
    incrementPracticeCalls++;
    return PracticeSection(
      id: sectionId,
      repertoireId: 'rep_1',
      pieceName: '테스트 곡',
      startMeasure: 1,
      endMeasure: 4,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: ${invocation.memberName}');
  }
}

/// Point-award fake so the gamification badge chain is not exercised.
class _FakePointAward extends PointAwardNotifier {
  @override
  List<PointHistory> build() => const [];

  @override
  PointHistory awardRecordingSaved(String studentId) {
    return PointHistory(
      id: 'x',
      studentId: studentId,
      points: 10,
      type: PointType.practiceComplete,
      description: '녹음 등록',
      earnedAt: DateTime(2026, 7, 3),
    );
  }
}

class _RecordingHarness extends ConsumerStatefulWidget {
  const _RecordingHarness({super.key});

  @override
  ConsumerState<_RecordingHarness> createState() => _RecordingHarnessState();
}

class _RecordingHarnessState extends ConsumerState<_RecordingHarness>
    with SectionDetailRecordingMixin<_RecordingHarness> {
  @override
  String get sectionId => 'sec_1';
  @override
  String get repertoireId => 'rep_1';
  @override
  String get studentId => 'student_1';

  /// Arms recording state directly — startRecording()'s native mic-permission
  /// + metronome-check path is out of scope for this logging regression test.
  void armRecording({int seconds = 5}) {
    isRecording = true;
    isPaused = false;
    recordingSeconds = seconds;
    usedMetronome = false;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
    JustAudioPlatform.instance = _FakeJustAudioPlatform();
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  final section = PracticeSection(
    id: 'sec_1',
    repertoireId: 'rep_1',
    pieceName: '테스트 곡',
    startMeasure: 1,
    endMeasure: 4,
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets(
    'stopRecording calls logRecording exactly once with the section studentId',
    (tester) async {
      final key = GlobalKey<_RecordingHarnessState>();
      final spy = _SpyLoggers();
      final repo = _FakeSectionRecordingRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(_FakeRecorder()),
            practiceRepertoireRepositoryProvider.overrideWithValue(repo),
            practiceSourceLoggersProvider.overrideWithValue(spy),
            pointAwardNotifierProvider.overrideWith(_FakePointAward.new),
          ],
          child: MaterialApp(home: Scaffold(body: _RecordingHarness(key: key))),
        ),
      );
      await tester.pump();

      expect(spy.recordingCalls, 0, reason: '녹음 시작 전에는 호출되면 안 된다');

      key.currentState!.armRecording(seconds: 5);
      await tester.runAsync(() => key.currentState!.stopRecording(section));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.createdRecordings, hasLength(1));
      expect(
        spy.recordingCalls,
        1,
        reason:
            '곡 상세 녹음 저장 성공 시 practiceSourceLoggersProvider.logRecording 가 '
            '1회 호출되어야 한다 (잔디/포인트 배선 회귀)',
      );
      expect(spy.lastStudentId, 'student_1');
      expect(tester.takeException(), isNull);
    },
  );
}
