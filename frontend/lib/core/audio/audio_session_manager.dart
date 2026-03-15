import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';

/// Manages audio session configuration for playback and recording.
///
/// Default: `.playback` category (metronome, no "in call" indicator).
/// Tuner: switches to `.playAndRecord` while recording, then back to `.playback`.
class AudioSessionManager {
  AudioSessionManager._();

  static AudioSession? _session;
  static bool _isConfigured = false;
  static bool _isInterrupted = false;
  static bool _isRecordingMode = false;
  static StreamSubscription? _interruptionSubscription;

  /// Callback when audio is interrupted (e.g., phone call).
  static void Function(bool isInterrupted)? onInterruption;

  /// Configure audio session for playback (default mode).
  ///
  /// Uses `.playback` category to avoid iOS showing "in call" indicator
  /// when Bluetooth earphones are connected.
  /// Should be called once at app startup (in main.dart).
  static Future<void> configureForPlayAndRecord() async {
    if (_isConfigured) {
      return;
    }

    try {
      _session = await AudioSession.instance;

      if (Platform.isIOS) {
        await _configurePlayback();
      } else if (Platform.isAndroid) {
        // Android: Configure for media playback
        await _session!.configure(const AudioSessionConfiguration(
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ));
      }

      // Subscribe to interruption events
      _interruptionSubscription?.cancel();
      _interruptionSubscription = _session!.interruptionEventStream.listen((event) {
        // Ignore unknown type on Android (false positive at app start)
        if (Platform.isAndroid && event.type == AudioInterruptionType.unknown) {
          return;
        }

        if (event.begin) {
          // Audio interrupted (e.g., phone call started)
          _isInterrupted = true;
          onInterruption?.call(true);
        } else {
          // Interruption ended
          _isInterrupted = false;
          onInterruption?.call(false);

          // Re-activate the session after interruption
          _session?.setActive(true);
        }
      });

      // Activate the session
      await _session!.setActive(true);
      _isConfigured = true;
    } catch (_) {
      // Configuration failed silently
    }
  }

  /// Re-activate the audio session after app resume or interruption end.
  ///
  /// iOS deactivates the audio session when the app goes to background.
  /// This must be called before restarting any audio streams.
  static Future<void> reactivate() async {
    if (_session == null) return;
    try {
      await _session!.setActive(true);
      _isInterrupted = false;
    } catch (_) {
      // Re-activation failed — another app may hold the session
    }
  }

  /// Switch to recording mode (tuner needs microphone).
  ///
  /// Changes category to `.playAndRecord` so tuner can access the mic.
  /// Call [disableRecordingMode] when tuner stops.
  static Future<void> enableRecordingMode() async {
    if (_session == null || _isRecordingMode) return;
    if (!Platform.isIOS) {
      _isRecordingMode = true;
      return;
    }

    try {
      await _session!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers |
                AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.allowBluetoothA2dp,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      ));
      await _session!.setActive(true);
      _isRecordingMode = true;
    } catch (_) {
      // Fallback: stay in current mode
    }
  }

  /// Switch back to playback-only mode (after tuner stops).
  ///
  /// Restores `.playback` category to prevent "in call" indicator
  /// on Bluetooth headphones.
  static Future<void> disableRecordingMode() async {
    if (_session == null || !_isRecordingMode) return;
    if (!Platform.isIOS) {
      _isRecordingMode = false;
      return;
    }

    try {
      await _configurePlayback();
      await _session!.setActive(true);
      _isRecordingMode = false;
    } catch (_) {
      // Fallback: stay in current mode
    }
  }

  /// Configure iOS for playback-only (no "in call" indicator).
  static Future<void> _configurePlayback() async {
    await _session!.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    ));
  }

  /// Check if audio session is configured.
  static bool get isConfigured => _isConfigured;

  /// Check if audio is currently interrupted.
  static bool get isInterrupted => _isInterrupted;

  /// Check if currently in recording mode.
  static bool get isRecordingMode => _isRecordingMode;

  /// Get the current audio session instance.
  static AudioSession? get session => _session;

  /// Dispose resources.
  static Future<void> dispose() async {
    await _interruptionSubscription?.cancel();
    _interruptionSubscription = null;
    onInterruption = null;
  }
}
