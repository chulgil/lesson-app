import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lost_writes_provider.g.dart';

/// Why unsent writes were dropped from the sync queue (drives the user notice).
enum LostWritesReason {
  /// Failed writes aged out after exhausting retries (INV-3, #1115).
  expired,

  /// The queue was cleared on logout to prevent cross-user replay (INV-4, #1114).
  logout,
}

/// A single "we dropped N unsent writes" notice.
///
/// [seq] is a monotonic counter so consecutive events with the same count/reason
/// are still distinct state values (a plain equal object would be ignored).
class LostWritesEvent {
  const LostWritesEvent({
    required this.count,
    required this.reason,
    required this.seq,
  });

  final int count;
  final LostWritesReason reason;
  final int seq;
}

/// Surfaces silently-dropped unsent writes so the UI can tell the user, honoring
/// "no silent loss" (INV-3/INV-4). Fed by [SyncService] (cleanup expiry) and the
/// auth logout flow (queue clear); consumed by a global UI listener that shows a
/// notice and then calls [clear].
@Riverpod(keepAlive: true)
class LostWrites extends _$LostWrites {
  int _seq = 0;

  @override
  LostWritesEvent? build() => null;

  /// Records that [count] unsent writes were dropped for [reason]. No-op when
  /// [count] <= 0 so callers need not guard.
  void record(int count, LostWritesReason reason) {
    if (count <= 0) return;
    state = LostWritesEvent(count: count, reason: reason, seq: ++_seq);
  }

  void clear() {
    state = null;
  }
}
