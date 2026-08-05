import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stale_data_provider.g.dart';

/// `cachedAt` of the most recently cache-served HTTP response (D2 배너 입력).
///
/// Written by the ResponseCacheInterceptor's `onCacheServed` callback (wired
/// in the apiClient provider); read by the offline banner to render
/// "마지막 동기화 HH:MM" while stale data is on screen. Null until the first
/// offline cache serve of the session.
@Riverpod(keepAlive: true)
class LastServedFromCacheAt extends _$LastServedFromCacheAt {
  @override
  DateTime? build() => null;

  void record(DateTime cachedAt) {
    state = cachedAt;
  }

  /// Clears the marker when a genuinely live (non-cache) allowlisted response
  /// reaches a caller — on-screen data is fresh again, so the banner can hide
  /// even while the device is on a slow (but connected) network. (G-06)
  void clear() {
    state = null;
  }
}
