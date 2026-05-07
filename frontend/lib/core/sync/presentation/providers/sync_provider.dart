import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network/api_client.dart';
import '../../application/connectivity_service.dart';
import '../../application/sync_adapter_registry.dart';
import '../../application/sync_service.dart';
import '../../data/sync_queue_store.dart';

part 'sync_provider.g.dart';

@Riverpod(keepAlive: true)
SyncQueueStore syncQueueStore(SyncQueueStoreRef ref) {
  return SyncQueueStore();
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  return ConnectivityService();
}

@Riverpod(keepAlive: true)
SyncAdapterRegistry syncAdapterRegistry(SyncAdapterRegistryRef ref) {
  return SyncAdapterRegistry.create();
}

@Riverpod(keepAlive: true)
SyncService syncService(SyncServiceRef ref) {
  return SyncService(
    queueStore: ref.read(syncQueueStoreProvider),
    connectivityService: ref.read(connectivityServiceProvider),
    adapterRegistry: ref.read(syncAdapterRegistryProvider),
    apiClient: ref.read(apiClientProvider),
  );
}

@Riverpod(keepAlive: true)
Stream<SyncServiceStats> syncServiceStatsStream(SyncServiceStatsStreamRef ref) {
  return ref.watch(syncServiceProvider).statsStream;
}

@Riverpod(keepAlive: true)
Future<SyncServiceStats> syncServiceStats(Ref ref) async {
  return ref.read(syncServiceProvider).currentStats();
}
