import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/hive_recording_repository.dart';
import '../../data/repositories/remote_recording_repository.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../../../core/audio/audio_recorder_service.dart';
import '../../../../core/audio/audio_player_service.dart';
import '../../../gamification/gamification_facade.dart';
import 'practice_recording_provider.dart' show practiceSourceLoggersProvider;

part 'recording_provider.g.dart';

/// State for the recording feature.
@immutable
class RecordingState {
  const RecordingState({
    this.recordings = const [],
    this.isLoading = false,
    this.isRecovering = false,
    this.isRecording = false,
    this.isPaused = false,
    this.isPlaying = false,
    this.hasMicInput = true,
    this.currentRecordingPath,
    this.currentRecordingDuration = Duration.zero,
    this.playingRecordingId,
    this.playbackPosition = Duration.zero,
    this.playbackDuration = Duration.zero,
    this.error,
    this.recoveryMessage,
  });

  final List<Recording> recordings;
  final bool isLoading;
  final bool isRecovering; // true during path recovery
  final bool isRecording;
  final bool isPaused;
  final bool isPlaying;
  final bool hasMicInput; // true if mic input is detected during recording
  final String? currentRecordingPath;
  final Duration currentRecordingDuration;
  final String? playingRecordingId;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final String? error;
  final String? recoveryMessage; // Message to show after recovery

  /// Get representative recording.
  Recording? get representativeRecording {
    try {
      return recordings.firstWhere((r) => r.isRepresentative);
    } catch (e) {
      return null;
    }
  }

  RecordingState copyWith({
    List<Recording>? recordings,
    bool? isLoading,
    bool? isRecovering,
    bool? isRecording,
    bool? isPaused,
    bool? isPlaying,
    bool? hasMicInput,
    String? currentRecordingPath,
    Duration? currentRecordingDuration,
    String? playingRecordingId,
    Duration? playbackPosition,
    Duration? playbackDuration,
    String? error,
    String? recoveryMessage,
    bool clearRecoveryMessage = false,
  }) {
    return RecordingState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      isRecovering: isRecovering ?? this.isRecovering,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isPlaying: isPlaying ?? this.isPlaying,
      hasMicInput: hasMicInput ?? this.hasMicInput,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      currentRecordingDuration:
          currentRecordingDuration ?? this.currentRecordingDuration,
      playingRecordingId: playingRecordingId ?? this.playingRecordingId,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      playbackDuration: playbackDuration ?? this.playbackDuration,
      error: error,
      recoveryMessage:
          clearRecoveryMessage
              ? null
              : (recoveryMessage ?? this.recoveryMessage),
    );
  }
}

/// Provider for recording repository - switches between Hive (local) and Remote.
@Riverpod(keepAlive: true)
RecordingRepository recordingRepository(Ref ref) =>
    createRepository<RecordingRepository>(
      ref: ref,
      mock: () => HiveRecordingRepository(),
      remote: (api) => RemoteRecordingRepository(api),
    );

/// Provider for audio recorder service.
@Riverpod(keepAlive: true)
AudioRecorderService audioRecorderService(Ref ref) {
  final service = AudioRecorderService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for audio player service.
@Riverpod(keepAlive: true)
AudioPlayerService audioPlayerService(Ref ref) {
  final service = AudioPlayerService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for checking microphone permission status.
@riverpod
Future<bool> microphonePermission(Ref ref) async {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return await recorder.hasPermission();
}

/// Look up a single recording by id, independent of repertoire/student
/// context. Used by the deep-linked recording detail screen
/// (`/recordings/:recordingId`, e.g. from a feedback push notification)
/// where only the recordingId is known.
@riverpod
Future<Recording?> recordingById(Ref ref, String recordingId) {
  final repository = ref.watch(recordingRepositoryProvider);
  return repository.getRecording(recordingId);
}

/// Main recording provider for a repertoire.
@riverpod
class RecordingNotifier extends _$RecordingNotifier {
  static const _uuid = Uuid();
  static const _micInputThreshold =
      0.05; // Minimum amplitude to consider as input
  static const _micCheckDuration = Duration(
    milliseconds: 1500,
  ); // Time to check for input

  RecordingRepository get _repository => ref.read(recordingRepositoryProvider);
  AudioRecorderService get _recorder => ref.read(audioRecorderServiceProvider);
  AudioPlayerService get _player => ref.read(audioPlayerServiceProvider);

  String _repertoireId = '';
  String _studentId = '';
  StreamSubscription<double>? _micInputCheckSubscription;

  @override
  RecordingState build(String repertoireId, String studentId) {
    _repertoireId = repertoireId;
    _studentId = studentId;

    // The mic-input watchdog subscription outlives fast navigation: leaving
    // the screen within the check window would otherwise leave it firing
    // `state=` on a disposed notifier (StateError).
    ref.onDispose(() {
      _micInputCheckSubscription?.cancel();
      _micInputCheckSubscription = null;
    });

    // Setup player completion callback
    _player.onComplete = () {
      state = state.copyWith(
        isPlaying: false,
        playingRecordingId: null,
        playbackPosition: Duration.zero,
      );
    };

    // Load recordings
    _loadRecordings();

    return const RecordingState(isLoading: true);
  }

  Future<void> _loadRecordings() async {
    try {
      // Show recovery status
      state = state.copyWith(isRecovering: true);

      // First, try to recover paths that became invalid
      final recovered = await _repository.migrateAndRecoverPaths();

      // Then clean up truly orphaned recordings
      final cleanedUp = await _repository.cleanupOrphanedRecordings();

      // Build recovery message
      String? message;
      if (recovered > 0 || cleanedUp > 0) {
        final parts = <String>[];
        if (recovered > 0) {
          parts.add('$recovered개 녹음 복구됨');
        }
        if (cleanedUp > 0) {
          parts.add('$cleanedUp개 누락 파일 정리됨');
        }
        message = parts.join(', ');
      }

      final recordings = await _repository.getRecordingsForRepertoire(
        _repertoireId,
      );
      state = state.copyWith(
        recordings: recordings,
        isLoading: false,
        isRecovering: false,
        recoveryMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRecovering: false,
        error: 'Failed to load recordings',
      );
    }
  }

  /// Clear the recovery message after showing it to the user.
  void clearRecoveryMessage() {
    state = state.copyWith(clearRecoveryMessage: true);
  }

  /// Start recording.
  Future<bool> startRecording() async {
    try {
      // Check permission first
      if (!await _recorder.hasPermission()) {
        final granted = await _recorder.requestPermission();
        if (!granted) {
          state = state.copyWith(error: 'Microphone permission denied');
          return false;
        }
      }

      // Stop any playing audio
      if (state.isPlaying) {
        await stopPlayback();
      }

      // Set recording state BEFORE starting recording
      // This ensures UI updates with amplitude waveform style before recording starts
      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        currentRecordingDuration: Duration.zero,
      );

      // Allow Riverpod to process state change and UI to rebuild
      // before starting recording (which resets stream cache)
      await Future.delayed(Duration.zero);

      final path = await _recorder.startRecording(repertoireId: _repertoireId);
      if (path != null) {
        state = state.copyWith(currentRecordingPath: path, hasMicInput: true);

        // Start monitoring amplitude for mic input detection
        _startMicInputCheck();

        return true;
      } else {
        // Revert recording state if failed
        state = state.copyWith(isRecording: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Failed to start recording',
      );
      return false;
    }
  }

  /// Start monitoring amplitude to check if mic input is present.
  void _startMicInputCheck() {
    _micInputCheckSubscription?.cancel();

    bool hasDetectedInput = false;
    final startTime = DateTime.now();

    _micInputCheckSubscription = _recorder.normalizedAmplitudeStream.listen((
      amplitude,
    ) {
      // If we detect any amplitude above threshold, mark as having input
      if (amplitude > _micInputThreshold) {
        hasDetectedInput = true;
        _micInputCheckSubscription?.cancel();
        _micInputCheckSubscription = null;
        return;
      }

      // After check duration, if no input detected, update state
      if (DateTime.now().difference(startTime) >= _micCheckDuration) {
        _micInputCheckSubscription?.cancel();
        _micInputCheckSubscription = null;

        if (!hasDetectedInput && state.isRecording) {
          state = state.copyWith(hasMicInput: false);
        }
      }
    });
  }

  /// Stop mic input check subscription.
  void _stopMicInputCheck() {
    _micInputCheckSubscription?.cancel();
    _micInputCheckSubscription = null;
  }

  /// Pause recording.
  Future<void> pauseRecording() async {
    if (!state.isRecording) return;
    await _recorder.pauseRecording();
    state = state.copyWith(isPaused: true);
  }

  /// Resume recording.
  Future<void> resumeRecording() async {
    if (!state.isRecording || !state.isPaused) return;
    await _recorder.resumeRecording();
    state = state.copyWith(isPaused: false);
  }

  /// Stop and save recording.
  Future<Recording?> stopRecording() async {
    if (!state.isRecording) return null;

    _stopMicInputCheck();

    try {
      final path = await _recorder.stopRecording();
      if (path == null) return null;

      // Calculate duration
      final duration = _recorder.currentDuration;
      final durationSeconds = duration.inSeconds;

      // Create recording model
      final recording = Recording(
        id: _uuid.v4(),
        repertoireId: _repertoireId,
        studentId: _studentId,
        type: RecordingType.student,
        localPath: path,
        durationSeconds: durationSeconds,
        recordedAt: DateTime.now(),
        isRepresentative:
        // #749: representative if none currently holds it (covers both the
        // first recording and a list whose representative was deleted).
        state.recordings.every((r) => !r.isRepresentative),
      );

      // Save to repository
      await _repository.saveRecording(recording);

      // Award points for saving a recording
      ref
          .read(pointAwardNotifierProvider.notifier)
          .awardRecordingSaved(_studentId);

      // #1129: count the recording in the growth heatmap (recordingCount += 1)
      // then refresh the heatmap viz so the "녹음 N개" cell updates immediately.
      unawaited(
        ref
            .read(practiceSourceLoggersProvider)
            .logRecording(
              studentId: _studentId,
              occurredAt: recording.recordedAt,
            ),
      );
      ref.invalidate(growthHeatmapProvider(_studentId));

      // Update state
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        hasMicInput: true, // Reset for next recording
        currentRecordingPath: null,
        currentRecordingDuration: Duration.zero,
        recordings: [recording, ...state.recordings],
      );

      return recording;
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Failed to save recording',
      );
      return null;
    }
  }

  /// Cancel recording without saving.
  Future<void> cancelRecording() async {
    if (!state.isRecording) return;

    _stopMicInputCheck();

    await _recorder.cancelRecording();
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      hasMicInput: true, // Reset for next recording
      currentRecordingPath: null,
      currentRecordingDuration: Duration.zero,
    );
  }

  /// Play a recording.
  Future<void> playRecording(String recordingId) async {
    try {
      // Find recording, guard against stale id (fixes #934)
      Recording? recording;
      try {
        recording = state.recordings.firstWhere((r) => r.id == recordingId);
      } catch (e) {
        state = state.copyWith(error: 'Recording not found');
        return;
      }

      // Check if file exists
      final file = File(recording.localPath);
      if (!await file.exists()) {
        state = state.copyWith(error: 'Recording file not found');
        return;
      }

      // Stop current playback if any
      if (state.isPlaying) {
        await _player.stop();
      }

      // Load and play
      final loaded = await _player.load(recording.localPath);
      if (loaded) {
        await _player.play();
        state = state.copyWith(
          isPlaying: true,
          playingRecordingId: recordingId,
          playbackDuration: Duration(seconds: recording.durationSeconds),
        );
      } else {
        state = state.copyWith(error: 'Failed to load recording');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to play recording: $e');
    }
  }

  /// Pause playback.
  Future<void> pausePlayback() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  /// Resume playback.
  Future<void> resumePlayback() async {
    await _player.play();
    state = state.copyWith(isPlaying: true);
  }

  /// Stop playback.
  Future<void> stopPlayback() async {
    await _player.stop();
    state = state.copyWith(
      isPlaying: false,
      playingRecordingId: null,
      playbackPosition: Duration.zero,
    );
  }

  /// Toggle playback.
  Future<void> togglePlayback(String recordingId) async {
    if (state.playingRecordingId == recordingId) {
      if (state.isPlaying) {
        await pausePlayback();
      } else {
        await resumePlayback();
      }
    } else {
      await playRecording(recordingId);
    }
  }

  /// Delete a recording.
  Future<void> deleteRecording(String recordingId) async {
    try {
      // Stop if playing
      if (state.playingRecordingId == recordingId) {
        await stopPlayback();
      }

      final wasRepresentative = state.recordings.any(
        (r) => r.id == recordingId && r.isRepresentative,
      );

      await _repository.deleteRecording(recordingId);

      var updatedRecordings =
          state.recordings.where((r) => r.id != recordingId).toList();

      // #749: if the representative was deleted, promote the most recent
      // remaining recording so the list never loses its representative.
      if (wasRepresentative) {
        final heir = Recording.pickRepresentativeHeir(updatedRecordings);
        if (heir != null) {
          await _repository.setRepresentative(heir.id);
          updatedRecordings = [
            for (final r in updatedRecordings)
              r.copyWith(isRepresentative: r.id == heir.id),
          ];
        }
      }

      state = state.copyWith(recordings: updatedRecordings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete recording');
    }
  }

  /// Set a recording as representative.
  Future<void> setAsRepresentative(String recordingId) async {
    try {
      await _repository.setRepresentative(recordingId);

      final updatedRecordings =
          state.recordings.map((r) {
            if (r.id == recordingId) {
              return r.copyWith(isRepresentative: true);
            }
            return r.copyWith(isRepresentative: false);
          }).toList();

      state = state.copyWith(recordings: updatedRecordings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set representative');
    }
  }

  /// Share representative recording with teacher.
  Future<void> shareWithTeacher() async {
    final representative = state.representativeRecording;
    if (representative == null) {
      state = state.copyWith(error: 'No representative recording selected');
      return;
    }

    try {
      await _repository.markAsShared(representative.id);

      final updatedRecordings =
          state.recordings.map((r) {
            if (r.id == representative.id) {
              return r.copyWith(
                sharedAt: DateTime.now(),
                storageStatus: StorageStatus.active,
              );
            }
            return r;
          }).toList();

      state = state.copyWith(recordings: updatedRecordings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to share recording');
    }
  }
}
