import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/metronome_settings.dart';
import 'metronome_engine_interface.dart';

/// Native platform metronome engine using AVAudioEngine (iOS) and AudioTrack (Android).
///
/// Uses Platform Channels to communicate with native code for sample-accurate timing.
/// Falls back gracefully if native implementation is not available.
class NativeMetronomeEngine implements MetronomeEngineInterface {
  NativeMetronomeEngine();

  static const _methodChannel = MethodChannel('com.lessonapp/metronome');
  static const _eventChannel = EventChannel('com.lessonapp/metronome_events');

  StreamSubscription<dynamic>? _beatSubscription;
  MetronomeSettings _settings = const MetronomeSettings();
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _initialized = false;

  @override
  BeatCallback? onBeat;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get currentBeat => _currentBeat;

  @override
  MetronomeSettings get settings => _settings;

  /// Check if native engine is available on current platform.
  static bool get isSupported => Platform.isIOS || Platform.isAndroid;

  @override
  Future<void> init() async {
    if (_initialized) return;

    debugPrint('NativeMetronomeEngine: init started');

    try {
      // Initialize native engine with current settings
      final result = await _methodChannel.invokeMethod<bool>('init', {
        'bpm': _settings.bpm,
        'beatsPerMeasure': _settings.timeSignature.beatsPerMeasure,
        'accentPattern': _settings.accentPattern.name,
        'strongSound': _settings.sound.getAssetPath(BeatType.strong),
        'mediumSound': _settings.sound.getAssetPath(BeatType.medium),
        'weakSound': _settings.sound.getAssetPath(BeatType.weak),
      });

      if (result != true) {
        throw PlatformException(
          code: 'INIT_FAILED',
          message: 'Native metronome engine initialization failed',
        );
      }

      // Setup event channel for beat callbacks
      _setupEventChannel();

      _initialized = true;
      debugPrint('NativeMetronomeEngine: initialized successfully');
    } on PlatformException catch (e) {
      debugPrint('NativeMetronomeEngine: init failed - ${e.message}');
      rethrow;
    } on MissingPluginException catch (e) {
      debugPrint('NativeMetronomeEngine: plugin not found - $e');
      rethrow;
    }
  }

  void _setupEventChannel() {
    _beatSubscription?.cancel();
    _beatSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final beat = event['beat'] as int? ?? 0;
          final isAccent = event['isAccent'] as bool? ?? false;

          _currentBeat = beat;
          onBeat?.call(beat, isAccent);
        }
      },
      onError: (dynamic error) {
        debugPrint('NativeMetronomeEngine: event error - $error');
      },
    );
  }

  @override
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      await stop();
    }

    final soundChanged = _settings.sound != newSettings.sound;
    final timeSignatureChanged =
        _settings.timeSignature != newSettings.timeSignature;
    final accentPatternChanged =
        _settings.accentPattern != newSettings.accentPattern;

    _settings = newSettings;

    if (_initialized) {
      // Update native settings
      if (soundChanged) {
        await _methodChannel.invokeMethod('setSound', {
          'strongSound': newSettings.sound.getAssetPath(BeatType.strong),
          'mediumSound': newSettings.sound.getAssetPath(BeatType.medium),
          'weakSound': newSettings.sound.getAssetPath(BeatType.weak),
        });
      }

      if (timeSignatureChanged) {
        await _methodChannel.invokeMethod(
          'setTimeSignature',
          newSettings.timeSignature.beatsPerMeasure,
        );
      }

      if (accentPatternChanged) {
        await _methodChannel.invokeMethod(
          'setAccentPattern',
          newSettings.accentPattern.name,
        );
      }

      // BPM is always updated
      await _methodChannel.invokeMethod('setBpm', newSettings.bpm);
    }

    if (wasPlaying) {
      await start();
    }
  }

  @override
  Future<void> start() async {
    if (_isPlaying) return;

    if (!_initialized) {
      await init();
    }

    try {
      _isPlaying = true;
      _currentBeat = 0;
      await _methodChannel.invokeMethod('start');
      debugPrint('NativeMetronomeEngine: Started at ${_settings.bpm} BPM');
    } on PlatformException catch (e) {
      _isPlaying = false;
      debugPrint('NativeMetronomeEngine: start failed - ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      _isPlaying = false;
      _currentBeat = 0;
      await _methodChannel.invokeMethod('stop');
      debugPrint('NativeMetronomeEngine: Stopped');
    } on PlatformException catch (e) {
      debugPrint('NativeMetronomeEngine: stop failed - ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> toggle() async {
    if (_isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_initialized) {
      await _methodChannel.invokeMethod('setBpm', clampedBpm);
    }
  }

  @override
  Future<void> incrementBpm(int delta) async {
    await setBpm(_settings.bpm + delta);
  }

  @override
  Future<void> playTapSound() async {
    if (!_initialized) {
      await init();
    }

    try {
      await _methodChannel.invokeMethod('playTapSound');
    } on PlatformException catch (e) {
      debugPrint('NativeMetronomeEngine: playTapSound failed - ${e.message}');
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _beatSubscription?.cancel();
    _beatSubscription = null;

    if (_initialized) {
      try {
        await _methodChannel.invokeMethod('dispose');
      } on PlatformException catch (e) {
        debugPrint('NativeMetronomeEngine: dispose failed - ${e.message}');
      }
    }

    _initialized = false;
    debugPrint('NativeMetronomeEngine: Disposed');
  }
}
