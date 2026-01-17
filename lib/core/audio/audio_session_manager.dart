import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

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

  /// Configure audio session for simultaneous playback and recording.
  ///
  /// Should be called once at app startup (in main.dart).
  /// This prevents audio interruption when switching between metronome and tuner.
  static Future<void> configureForPlayAndRecord() async {
    if (_isConfigured) {
      debugPrint('AudioSessionManager: Already configured');
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
          avAudioSessionMode: AVAudioSessionMode.measurement, // Best for tuner
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ));
        debugPrint('AudioSessionManager: iOS configured for playAndRecord');
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
        debugPrint('AudioSessionManager: Android configured');
      }

      // Activate the session
      await _session!.setActive(true);
      _isConfigured = true;

      debugPrint('AudioSessionManager: Audio session activated successfully');
    } catch (e) {
      debugPrint('AudioSessionManager: Configuration failed - $e');
    }
  }

  /// Check if audio session is configured.
  static bool get isConfigured => _isConfigured;

  /// Get the current audio session instance.
  static AudioSession? get session => _session;
}
