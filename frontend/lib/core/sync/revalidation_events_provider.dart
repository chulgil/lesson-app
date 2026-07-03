import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revalidation_events_provider.g.dart';

/// A background-revalidation refresh signal (G-04 / SN-1).
///
/// [path] is the allowlist prefix whose cached read was superseded by fresh
/// data; [seq] is a monotonic counter so consecutive signals for the same
/// prefix are distinct state values (a plain equal object would be ignored).
class RevalidationSignal {
  const RevalidationSignal({required this.path, required this.seq});

  final String path;
  final int seq;
}

/// Bus carrying stale-while-revalidate completion events.
///
/// The `ResponseCacheInterceptor` emits here (wired in `apiClient`) when a
/// background revalidation returned data that differs from the stale response a
/// caller was already served. Read providers opt in via
/// [RevalidationRefX.autoRevalidate] to refresh themselves live, so slow-network
/// users see the fresh data land without a manual pull-to-refresh.
@Riverpod(keepAlive: true)
class RevalidationEvents extends _$RevalidationEvents {
  int _seq = 0;

  @override
  RevalidationSignal? build() => null;

  /// Publishes a refresh signal for [path] (an allowlist prefix).
  void emit(String path) {
    state = RevalidationSignal(path: path, seq: ++_seq);
  }
}

/// One-line opt-in for a read provider to refresh when a [prefix] it reads is
/// revalidated in the background. Call at the top of the provider build, e.g.
/// `ref.autoRevalidate('/practice');`.
///
/// Matching is segment-aware and bidirectional so a provider may register a
/// broader or narrower prefix than the emitted one (e.g. register `/practice`,
/// receive `/practice`; or register `/parents`, receive `/parents`).
extension RevalidationRefX on Ref {
  void autoRevalidate(String prefix) {
    listen(revalidationEventsProvider, (previous, next) {
      if (next == null) return;
      final emitted = next.path;
      final matches =
          emitted == prefix ||
          emitted.startsWith('$prefix/') ||
          prefix.startsWith('$emitted/');
      if (matches) invalidateSelf();
    });
  }
}
