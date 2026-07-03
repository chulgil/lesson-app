// Regression test for #1129 (껍데기 감사 N6): RecordingNotifier.stopRecording
// must fire PracticeSourceLoggers.logRecording exactly once on the save-success
// path so the growth heatmap counts the recording. Cancel and save-failure paths
// must NOT log.
//
// Strategy: spy on practiceSourceLoggersProvider with a call-counting fake and
// drive the notifier through a fake AudioRecorderService (no real hardware).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/audio_player_service.dart';
import 'package:lessonaza/core/audio/audio_recorder_service.dart';
import 'package:lessonaza/core/providers/repository_provider.dart'
    show mockDataModeProvider;
import 'package:lessonaza/features/gamification/gamification_facade.dart'
    show pointAwardNotifierProvider, PointAwardNotifier;
import 'package:lessonaza/features/gamification/domain/entities/gamification.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/domain/repositories/student_quest_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/practice/domain/repositories/recording_repository.dart';
import 'package:lessonaza/features/practice/domain/services/practice_recording_service.dart';
import 'package:lessonaza/features/practice/domain/services/practice_source_loggers.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_recording_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_provider.dart';

import '../../../../test_helper.dart';

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

/// Fake recorder: returns a path on success, or null to simulate save failure.
class _FakeRecorder extends AudioRecorderService {
  _FakeRecorder({required this.stopPath});

  final String? stopPath;
  bool cancelled = false;
  final _amplitude = StreamController<double>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<String?> startRecording({
    required String repertoireId,
    int maxDurationSeconds = 180,
  }) async => '/tmp/$repertoireId.m4a';

  // Open, event-less broadcast stream: the mic-input check subscribes but
  // never sees a close-during-add race (the empty stream caused that).
  @override
  Stream<double> get normalizedAmplitudeStream => _amplitude.stream;

  @override
  Duration get currentDuration => const Duration(seconds: 42);

  @override
  Future<String?> stopRecording() async => stopPath;

  @override
  Future<void> cancelRecording() async => cancelled = true;

  @override
  Future<void> dispose() async {
    await _amplitude.close();
  }
}

/// Fake player so build() does not touch real audio.
class _FakePlayer extends AudioPlayerService {
  @override
  Future<void> init() async {}
  @override
  Future<void> dispose() async {}
}

/// Fake recording repository — records saves in memory.
class _FakeRecordingRepository implements RecordingRepository {
  final List<Recording> saved = [];
  final bool throwOnSave;

  _FakeRecordingRepository({this.throwOnSave = false});

  @override
  Future<void> saveRecording(Recording recording) async {
    if (throwOnSave) throw StateError('save failed');
    saved.add(recording);
  }

  @override
  Future<int> migrateAndRecoverPaths() async => 0;

  @override
  Future<int> cleanupOrphanedRecordings() async => 0;

  @override
  Future<List<Recording>> getRecordingsForRepertoire(
    String repertoireId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
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

/// Test double that reuses the real recording/cancel logic but skips the
/// fire-and-forget `_loadRecordings` in build. That async load sets state during
/// build (a Riverpod anti-pattern the widget path tolerates only via real event
/// loop timing) and is irrelevant to the logging contract under test.
///
/// The private `_repertoireId`/`_studentId` fields stay at their `''` defaults,
/// so stopRecording logs with studentId ''. The exact-studentId passthrough is
/// covered by practice_source_loggers_test.dart; here we assert the CALL fires.
class _TestRecordingNotifier extends RecordingNotifier {
  @override
  RecordingState build(String repertoireId, String studentId) {
    // Wire the player completion callback the way the real build does, but do
    // not kick off _loadRecordings.
    return const RecordingState();
  }
}

({
  RecordingNotifier notifier,
  _SpyLoggers spy,
  _FakeRecordingRepository repo,
  _FakeRecorder recorder,
})
_mount({bool throwOnSave = false}) {
  const repertoireId = 'rep_1';
  const studentId = 'student_1';
  final spy = _SpyLoggers();
  final recorder = _FakeRecorder(stopPath: '/tmp/rec.m4a');
  final repo = _FakeRecordingRepository(throwOnSave: throwOnSave);
  final provider = recordingNotifierProvider(repertoireId, studentId);

  final container = ProviderContainer(
    overrides: [
      // Mock mode so the heatmap invalidate in stopRecording resolves to the
      // in-memory repository instead of an unopened Hive box.
      mockDataModeProvider.overrideWithValue(true),
      practiceSourceLoggersProvider.overrideWithValue(spy),
      audioRecorderServiceProvider.overrideWithValue(recorder),
      audioPlayerServiceProvider.overrideWithValue(_FakePlayer()),
      recordingRepositoryProvider.overrideWithValue(repo),
      pointAwardNotifierProvider.overrideWith(_FakePointAward.new),
      // _TestRecordingNotifier skips the async _loadRecordings that would set
      // state during build.
      provider.overrideWith(_TestRecordingNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  // Keep the notifier element alive across the test.
  final sub = container.listen(provider, (_, _) {}, fireImmediately: true);
  addTearDown(sub.close);

  return (
    notifier: container.read(provider.notifier),
    spy: spy,
    repo: repo,
    recorder: recorder,
  );
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
    // Stub the record/audioplayers platform channels so the real service
    // constructors (field initializers) do not throw MissingPluginException.
    // The notifier's recording/playback logic is exercised via fake providers.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const [
      'com.llfbandit.record/messages',
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async => null,
      );
    }
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  test('save-success path calls logRecording exactly once', () async {
    final m = _mount();
    await m.notifier.startRecording();
    final rec = await m.notifier.stopRecording();

    expect(rec, isNotNull);
    expect(m.repo.saved, hasLength(1));
    expect(m.spy.recordingCalls, 1);
    // studentId is forwarded from the notifier's _studentId (default '' in this
    // test double). Exact value passthrough is covered by the loggers unit test.
    expect(m.spy.lastStudentId, isNotNull);
  });

  test('cancelRecording does NOT call logRecording', () async {
    final m = _mount();
    await m.notifier.startRecording();
    await m.notifier.cancelRecording();

    expect(m.recorder.cancelled, isTrue);
    expect(m.spy.recordingCalls, 0);
    expect(m.repo.saved, isEmpty);
  });

  test('save failure (catch path) does NOT call logRecording', () async {
    final m = _mount(throwOnSave: true);
    await m.notifier.startRecording();
    final rec = await m.notifier.stopRecording();

    expect(rec, isNull);
    expect(m.spy.recordingCalls, 0);
  });
}
