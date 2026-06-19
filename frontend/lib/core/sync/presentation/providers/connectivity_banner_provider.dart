import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application/connectivity_service.dart';
import 'sync_provider.dart';

part 'connectivity_banner_provider.g.dart';

/// Streams the current offline state for the global banner.
///
/// Emits `true` when the device is offline, `false` when online or unknown.
/// keepAlive so the stream subscription lives for the app lifetime.
@Riverpod(keepAlive: true)
Stream<bool> offlineBanner(OfflineBannerRef ref) async* {
  final service = ref.watch(connectivityServiceProvider);

  // Emit initial state immediately.
  final initial = await service.current;
  yield initial == SyncConnectivity.offline;

  // Then follow changes.
  yield* service.connectivityChanges.map((c) => c == SyncConnectivity.offline);
}
