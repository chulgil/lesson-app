import '../entities/practice_evidence.dart';
import 'practice_recording_service.dart';

/// 4 경로 wiring 의 thin helper — 메트로놈/튜너/YouTube/녹음/수동 stop hook
/// 에서 호출. 본 helper 가 [PracticeRecordingService] 를 직접 의존하여
/// metronome_provider / tuner_provider / YouTube widget 등 caller 의
/// boilerplate 를 제거하고 단위 테스트 가능하게 한다.
///
/// 스펙 §6.0 단일 진입점 / 플랜 Job 3 Task 3.3~3.6. Caller 는 [studentId]
/// 와 [durationMinutes] 만 알면 된다.
class PracticeSourceLoggers {
  final PracticeRecordingService service;

  const PracticeSourceLoggers(this.service);

  /// 메트로놈 stop 시 호출. [durationMinutes] <= 0 이면 no-op.
  Future<void> logMetronome({
    required String studentId,
    required int durationMinutes,
    int? bpm,
    DateTime? occurredAt,
  }) => _log(
    studentId: studentId,
    source: PracticeSource.metronome,
    durationMinutes: durationMinutes,
    occurredAt: occurredAt,
    metadata: {if (bpm != null) 'bpm': bpm},
  );

  /// 튜너 stop 시 호출.
  Future<void> logTuner({
    required String studentId,
    required int durationMinutes,
    DateTime? occurredAt,
  }) => _log(
    studentId: studentId,
    source: PracticeSource.tuner,
    durationMinutes: durationMinutes,
    occurredAt: occurredAt,
    metadata: const {},
  );

  /// YouTube 영상 onEnded 시 호출 — P1 에서는 영상 끝까지 시청한 경우 1회만.
  Future<void> logYoutubeEnded({
    required String studentId,
    required int durationMinutes,
    required String videoId,
    DateTime? occurredAt,
  }) => _log(
    studentId: studentId,
    source: PracticeSource.youtube,
    durationMinutes: durationMinutes,
    videoId: videoId,
    occurredAt: occurredAt,
    metadata: const {},
  );

  /// 사용자 수동 입력 — "오늘 N분 연습했어요".
  Future<void> logManual({
    required String studentId,
    required int durationMinutes,
    String? note,
    DateTime? occurredAt,
  }) => _log(
    studentId: studentId,
    source: PracticeSource.manual,
    durationMinutes: durationMinutes,
    occurredAt: occurredAt,
    metadata: {if (note != null) 'note': note},
  );

  /// 녹음 1회 완료 시 호출 — recordingCount += 1, 분 단위 진척 무영향.
  Future<void> logRecording({
    required String studentId,
    DateTime? occurredAt,
  }) => _log(
    studentId: studentId,
    source: PracticeSource.recording,
    durationMinutes: 0,
    occurredAt: occurredAt,
    metadata: const {},
  );

  Future<void> _log({
    required String studentId,
    required PracticeSource source,
    required int durationMinutes,
    required Map<String, dynamic> metadata,
    String? videoId,
    DateTime? occurredAt,
  }) async {
    if (source != PracticeSource.recording && durationMinutes <= 0) return;
    await service.recordPractice(
      studentId,
      PracticeEvidence(
        source: source,
        durationMinutes: durationMinutes,
        occurredAt: occurredAt ?? DateTime.now(),
        metadata: metadata,
        videoId: videoId,
      ),
    );
  }
}
