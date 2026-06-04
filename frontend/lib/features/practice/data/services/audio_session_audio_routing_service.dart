// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:audio_session/audio_session.dart';

import '../../domain/services/audio_routing_service.dart';

/// Default [AudioRoutingService] implementation backed by the `audio_session`
/// package. Maps any wired/wireless headphone-class output to "connected".
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.4
class AudioSessionAudioRoutingService implements AudioRoutingService {
  AudioSession? _session;
  StreamSubscription? _devicesChangedSub;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isHeadphoneConnected = false;
  bool _initialized = false;

  AudioSessionAudioRoutingService();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _session = await AudioSession.instance;
      _isHeadphoneConnected = await _detectFromDevices();
      _devicesChangedSub = _session!.devicesChangedEventStream.listen((
        event,
      ) async {
        final connected = await _detectFromDevices();
        if (connected != _isHeadphoneConnected) {
          _isHeadphoneConnected = connected;
          if (!_controller.isClosed) _controller.add(connected);
        }
      });
    } catch (_) {
      // Best effort — leave _isHeadphoneConnected as false.
    }
  }

  Future<bool> _detectFromDevices() async {
    try {
      final session = _session;
      if (session == null) return false;
      final devices = await session.getDevices();
      for (final d in devices) {
        if (!d.isOutput) continue;
        switch (d.type) {
          case AudioDeviceType.wiredHeadset:
          case AudioDeviceType.wiredHeadphones:
          case AudioDeviceType.bluetoothA2dp:
          case AudioDeviceType.bluetoothLe:
          case AudioDeviceType.bluetoothSco:
          case AudioDeviceType.usbAudio:
            return true;
          default:
            continue;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isHeadphoneConnected {
    // Lazy init — first read kicks off async detection. Returns false until
    // it resolves; subscribers get the real value via the stream.
    _ensureInitialized();
    return _isHeadphoneConnected;
  }

  @override
  Stream<bool> get headphoneConnectedStream {
    _ensureInitialized();
    return _controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _devicesChangedSub?.cancel();
    _devicesChangedSub = null;
    if (!_controller.isClosed) await _controller.close();
  }
}
