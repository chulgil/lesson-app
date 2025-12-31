import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../models/recording.dart';
import '../../repositories/recording_repository.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/audio_player_service.dart';

part 'recording_provider.g.dart';

/// State for the recording feature.
@immutable
class RecordingState {
  const RecordingState({
    this.recordings = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.isPaused = false,
    this.isPlaying = false,
    this.currentRecordingPath,
    this.currentRecordingDuration = Duration.zero,
    this.playingRecordingId,
    this.playbackPosition = Duration.zero,
    this.playbackDuration = Duration.zero,
    this.error,
  });

  final List<Recording> recordings;
  final bool isLoading;
  final bool isRecording;
  final bool isPaused;
  final bool isPlaying;
  final String? currentRecordingPath;
  final Duration currentRecordingDuration;
  final String? playingRecordingId;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final String? error;

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
    bool? isRecording,
    bool? isPaused,
    bool? isPlaying,
    String? currentRecordingPath,
    Duration? currentRecordingDuration,
    String? playingRecordingId,
    Duration? playbackPosition,
    Duration? playbackDuration,
    String? error,
  }) {
    return RecordingState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isPlaying: isPlaying ?? this.isPlaying,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      currentRecordingDuration: currentRecordingDuration ?? this.currentRecordingDuration,
      playingRecordingId: playingRecordingId ?? this.playingRecordingId,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      playbackDuration: playbackDuration ?? this.playbackDuration,
      error: error,
    );
  }
}

/// Provider for recording repository.
@Riverpod(keepAlive: true)
RecordingRepository recordingRepository(RecordingRepositoryRef ref) {
  return HiveRecordingRepository();
}

/// Provider for audio recorder service.
@Riverpod(keepAlive: true)
AudioRecorderService audioRecorderService(AudioRecorderServiceRef ref) {
  final service = AudioRecorderService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for audio player service.
@Riverpod(keepAlive: true)
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) {
  final service = AudioPlayerService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for checking microphone permission status.
@riverpod
Future<bool> microphonePermission(MicrophonePermissionRef ref) async {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return await recorder.hasPermission();
}

/// Main recording provider for a repertoire.
@riverpod
class RecordingNotifier extends _$RecordingNotifier {
  static const _uuid = Uuid();

  RecordingRepository get _repository => ref.read(recordingRepositoryProvider);
  AudioRecorderService get _recorder => ref.read(audioRecorderServiceProvider);
  AudioPlayerService get _player => ref.read(audioPlayerServiceProvider);

  String _repertoireId = '';
  String _studentId = '';

  @override
  RecordingState build(String repertoireId, String studentId) {
    _repertoireId = repertoireId;
    _studentId = studentId;

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
      final recordings = await _repository.getRecordingsForRepertoire(_repertoireId);
      state = state.copyWith(
        recordings: recordings,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('RecordingProvider: Failed to load recordings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recordings',
      );
    }
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
        state = state.copyWith(currentRecordingPath: path);
        debugPrint('RecordingProvider: Started recording at $path');
        return true;
      } else {
        // Revert recording state if failed
        state = state.copyWith(isRecording: false);
        return false;
      }
    } catch (e) {
      debugPrint('RecordingProvider: Failed to start recording: $e');
      state = state.copyWith(isRecording: false, error: 'Failed to start recording');
      return false;
    }
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
        isRepresentative: state.recordings.isEmpty, // First recording is representative
      );

      // Save to repository
      await _repository.saveRecording(recording);

      // Update state
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        currentRecordingPath: null,
        currentRecordingDuration: Duration.zero,
        recordings: [recording, ...state.recordings],
      );

      debugPrint('RecordingProvider: Saved recording ${recording.id}');
      return recording;
    } catch (e) {
      debugPrint('RecordingProvider: Failed to stop recording: $e');
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
    await _recorder.cancelRecording();
    state = state.copyWith(
      isRecording: false,
      isPaused: false,
      currentRecordingPath: null,
      currentRecordingDuration: Duration.zero,
    );
    debugPrint('RecordingProvider: Cancelled recording');
  }

  /// Play a recording.
  Future<void> playRecording(String recordingId) async {
    try {
      final recording = state.recordings.firstWhere((r) => r.id == recordingId);
      debugPrint('RecordingProvider: Playing recording ${recording.id}');
      debugPrint('RecordingProvider: File path: ${recording.localPath}');

      // Check if file exists
      final file = File(recording.localPath);
      if (!await file.exists()) {
        debugPrint('RecordingProvider: File does not exist!');
        state = state.copyWith(error: 'Recording file not found');
        return;
      }
      debugPrint('RecordingProvider: File exists, size: ${await file.length()} bytes');

      // Stop current playback if any
      if (state.isPlaying) {
        await _player.stop();
      }

      // Load and play
      final loaded = await _player.load(recording.localPath);
      debugPrint('RecordingProvider: Load result: $loaded');
      if (loaded) {
        await _player.play();
        state = state.copyWith(
          isPlaying: true,
          playingRecordingId: recordingId,
          playbackDuration: Duration(seconds: recording.durationSeconds),
        );
        debugPrint('RecordingProvider: Playback started');
      } else {
        state = state.copyWith(error: 'Failed to load recording');
        debugPrint('RecordingProvider: Failed to load recording');
      }
    } catch (e, stack) {
      debugPrint('RecordingProvider: Error playing recording: $e');
      debugPrint('RecordingProvider: Stack trace: $stack');
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

      await _repository.deleteRecording(recordingId);

      final updatedRecordings = state.recordings
          .where((r) => r.id != recordingId)
          .toList();

      state = state.copyWith(recordings: updatedRecordings);
      debugPrint('RecordingProvider: Deleted recording $recordingId');
    } catch (e) {
      debugPrint('RecordingProvider: Failed to delete recording: $e');
      state = state.copyWith(error: 'Failed to delete recording');
    }
  }

  /// Set a recording as representative.
  Future<void> setAsRepresentative(String recordingId) async {
    try {
      await _repository.setRepresentative(recordingId);

      final updatedRecordings = state.recordings.map((r) {
        if (r.id == recordingId) {
          return r.copyWith(isRepresentative: true);
        }
        return r.copyWith(isRepresentative: false);
      }).toList();

      state = state.copyWith(recordings: updatedRecordings);
      debugPrint('RecordingProvider: Set $recordingId as representative');
    } catch (e) {
      debugPrint('RecordingProvider: Failed to set representative: $e');
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

      final updatedRecordings = state.recordings.map((r) {
        if (r.id == representative.id) {
          return r.copyWith(
            sharedAt: DateTime.now(),
            storageStatus: StorageStatus.active,
          );
        }
        return r;
      }).toList();

      state = state.copyWith(recordings: updatedRecordings);
      debugPrint('RecordingProvider: Shared with teacher');
    } catch (e) {
      debugPrint('RecordingProvider: Failed to share: $e');
      state = state.copyWith(error: 'Failed to share recording');
    }
  }
}
