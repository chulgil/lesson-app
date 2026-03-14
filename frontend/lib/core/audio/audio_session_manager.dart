import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';

/// Manages audio session configuration for simultaneous playback and recording.
///
/// This ensures that:
/// - Metronome playback continues uninterrupted when tuner starts
/// - Tuner can record while metronome plays
/// - Audio session is configured once at app start
class AudioSessionManager {
  AudioSessionManager._();

  static AudioSession? _session;
  static bool _isConfigured = false;
  static bool _isInterrupted = false;
  static StreamSubscription? _interruptionSubscription;

  /// Callback when audio is interrupted (e.g., phone call).
  static void Function(bool isInterrupted)? onInterruption;

  /// Configure audio session for simultaneous playback and recording.
  ///
  /// Should be called once at app startup (in main.dart).
  /// This prevents audio interruption when switching between metronome and tuner.
  static Future<void> configureForPlayAndRecord() async {
    if (_isConfigured) {
      return;
    }

    try {
      _session = await AudioSession.instance;

      if (Platform.isIOS) {
        // iOS: Configure for simultaneous playback and recording
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers |
                  AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.allowBluetoothA2dp,
          avAudioSessionMode: AVAudioSessionMode.defaultMode, // measurement mode reduces speaker volume
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ));
      } else if (Platform.isAndroid) {
        // Android: Configure for media playback with recording capability
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

  /// Check if audio session is configured.
  static bool get isConfigured => _isConfigured;

  /// Check if audio is currently interrupted.
  static bool get isInterrupted => _isInterrupted;

  /// Get the current audio session instance.
  static AudioSession? get session => _session;

  /// Dispose resources.
  static Future<void> dispose() async {
    await _interruptionSubscription?.cancel();
    _interruptionSubscription = null;
    onInterruption = null;
  }
}
