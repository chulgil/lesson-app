import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Service for audio recording functionality.
///
/// Uses the record package for cross-platform audio recording.
/// Supports AAC/M4A format for efficient storage.
class AudioRecorderService {
  AudioRecorderService();

  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// Current recording state.
  RecordState _state = RecordState.stop;
  RecordState get state => _state;

  /// Whether currently recording.
  bool get isRecording => _state == RecordState.record;

  /// Whether paused.
  bool get isPaused => _state == RecordState.pause;

  /// Stream of recording state changes.
  Stream<RecordState> get stateStream => _recorder.onStateChanged();

  /// Stream of amplitude for waveform visualization.
  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  /// Cached normalized amplitude stream (0.0 to 1.0) for waveform widgets.
  /// Cached to ensure same stream instance is returned (prevents widget re-subscription).
  Stream<double>? _normalizedAmplitudeStreamCache;
  StreamSubscription<double>? _amplitudeBroadcastSubscription;

  /// Normalized amplitude stream (0.0 to 1.0) for waveform widgets.
  /// The broadcast stream keeps source subscription alive even when listeners come and go.
  Stream<double> get normalizedAmplitudeStream {
    _normalizedAmplitudeStreamCache ??= _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .map((amp) => ((amp.current + 60) / 60).clamp(0.0, 1.0))
        .asBroadcastStream(
          onListen: (subscription) {
            // Keep a reference to prevent cancellation when listener count drops to zero
            _amplitudeBroadcastSubscription = subscription;
          },
          onCancel: (subscription) {
            // Pause instead of cancel to keep stream alive for future listeners
            subscription.pause();
          },
        );
    // Resume if paused (when a new listener attaches)
    _amplitudeBroadcastSubscription?.resume();
    return _normalizedAmplitudeStreamCache!;
  }

  /// Current amplitude value (for UI).
  double _currentAmplitude = 0;
  double get currentAmplitude => _currentAmplitude;

  /// Recording start time for duration calculation.
  DateTime? _recordingStartTime;
  Duration? _pausedDuration;

  /// Current recording duration.
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_recordingStartTime!);
    return elapsed - (_pausedDuration ?? Duration.zero);
  }

  /// Initialize the recorder service.
  Future<void> init() async {
    _stateSubscription = _recorder.onStateChanged().listen((state) {
      _state = state;
      debugPrint('AudioRecorder: State changed to $state');
    });

    _amplitudeSubscription = amplitudeStream.listen((amp) {
      // Normalize amplitude to 0-1 range
      // amp.current is in dB, typically -160 to 0
      _currentAmplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);
    });
  }

  /// Check and request microphone permission.
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      debugPrint('AudioRecorder: Microphone permission granted');
      return true;
    }
    debugPrint('AudioRecorder: Microphone permission denied');
    return false;
  }

  /// Check if microphone permission is granted.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Get the recordings directory path.
  Future<String> _getRecordingsDirectory(String repertoireId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings/$repertoireId');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir.path;
  }

  /// Start recording.
  ///
  /// Returns the file path where recording will be saved.
  Future<String?> startRecording({
    required String repertoireId,
    int maxDurationSeconds = 180, // 3 minutes default
  }) async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('AudioRecorder: Permission not granted');
          return null;
        }
      }

      // Generate file path
      final dir = await _getRecordingsDirectory(repertoireId);
      final fileName = '${_uuid.v4()}.m4a';
      final filePath = '$dir/$fileName';

      // Reset stream cache before starting new recording
      // This ensures the amplitude stream is fresh for each recording session
      await _amplitudeBroadcastSubscription?.cancel();
      _amplitudeBroadcastSubscription = null;
      _normalizedAmplitudeStreamCache = null;
      debugPrint('AudioRecorder: Reset amplitude stream cache');

      // Configure and start recording
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;

      debugPrint('AudioRecorder: Recording started at $filePath');
      return filePath;
    } catch (e) {
      debugPrint('AudioRecorder: Failed to start recording: $e');
      return null;
    }
  }

  /// Pause recording.
  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      debugPrint('AudioRecorder: Recording paused');
    } catch (e) {
      debugPrint('AudioRecorder: Failed to pause recording: $e');
    }
  }

  /// Resume recording.
  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
      debugPrint('AudioRecorder: Recording resumed');
    } catch (e) {
      debugPrint('AudioRecorder: Failed to resume recording: $e');
    }
  }

  /// Stop recording and return the file path.
  ///
  /// Returns the path to the recorded file, or null if failed.
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _recordingStartTime = null;
      _pausedDuration = null;
      debugPrint('AudioRecorder: Recording stopped, saved to $path');
      return path;
    } catch (e) {
      debugPrint('AudioRecorder: Failed to stop recording: $e');
      return null;
    }
  }

  /// Cancel recording and delete the file.
  Future<void> cancelRecording() async {
    try {
      final path = await _recorder.stop();
      _recordingStartTime = null;
      _pausedDuration = null;

      // Delete the file
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('AudioRecorder: Recording cancelled and deleted');
        }
      }
    } catch (e) {
      debugPrint('AudioRecorder: Failed to cancel recording: $e');
    }
  }

  /// Delete a recording file.
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('AudioRecorder: Deleted recording at $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AudioRecorder: Failed to delete recording: $e');
      return false;
    }
  }

  /// Get file size in bytes.
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get formatted file size string.
  Future<String> getFormattedFileSize(String filePath) async {
    final bytes = await getFileSize(filePath);
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    await _amplitudeBroadcastSubscription?.cancel();
    _normalizedAmplitudeStreamCache = null;
    await _recorder.dispose();
    debugPrint('AudioRecorder: Disposed');
  }
}
