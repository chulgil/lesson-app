/// Headphone / external audio route detection for safer mic recording.
///
/// Implementation backed by `audio_session` package — listens to route-change
/// events and exposes a stream + snapshot.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.4
abstract class AudioRoutingService {
  /// Snapshot — is a wired or wireless headphone currently connected?
  bool get isHeadphoneConnected;

  /// Stream of route-change events. Emits the new `isHeadphoneConnected`
  /// boolean on every change.
  Stream<bool> get headphoneConnectedStream;

  /// Disposes underlying subscriptions.
  Future<void> dispose();
}
