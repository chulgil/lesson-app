import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/sync_queue_entry.dart';
import '../data/sync_queue_store.dart';
import 'connectivity_service.dart';
import 'sync_adapter_registry.dart';

class SyncServiceStats {
  const SyncServiceStats({
    required this.total,
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
    required this.online,
    required this.lastSyncAt,
    required this.nextAction,
  });

  final int total;
  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final bool online;
  final DateTime? lastSyncAt;
  final String nextAction;

  int get queueBacklog => pending + failed;
  bool get hasFailures => failed > 0;
}

class SyncService {
  SyncService({
    required SyncQueueStore queueStore,
    required ConnectivityService connectivityService,
    required SyncAdapterRegistry adapterRegistry,
    required ApiClient apiClient,
    this.pollingInterval = const Duration(seconds: 30),
    this.defaultMaxRetryCount = 5,
  }) : _queueStore = queueStore,
       _connectivityService = connectivityService,
       _adapterRegistry = adapterRegistry,
       _apiClient = apiClient;

  final SyncQueueStore _queueStore;
  final ConnectivityService _connectivityService;
  final SyncAdapterRegistry _adapterRegistry;
  final ApiClient _apiClient;
  final Duration pollingInterval;
  final int defaultMaxRetryCount;

  final _uuid = const Uuid();
  final _statsStream = StreamController<SyncServiceStats>.broadcast();
  StreamSubscription<SyncConnectivity>? _connectivitySubscription;

  bool _isInitialized = false;
  bool _isRunning = false;
  DateTime? _lastSyncAt;
  Timer? _pollTimer;

  Stream<SyncServiceStats> get statsStream => _statsStream.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    await _queueStore.runMigrations();
    await _refreshStats();
    await syncPending();

    _connectivitySubscription = _connectivityService.connectivityChanges.listen(
      (state) {
        if (state == SyncConnectivity.online) {
          unawaited(syncPending());
        }
      },
    );

    _pollTimer = Timer.periodic(
      pollingInterval,
      (_) => unawaited(syncPending()),
    );
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _pollTimer?.cancel();
    await _statsStream.close();
  }

  Future<void> syncPending() async {
    if (_isRunning) {
      return;
    }

    if (!await _connectivityService.isOnline) {
      await _refreshStats(nextAction: 'offline — waiting for network');
      return;
    }

    _isRunning = true;

    try {
      await _flushQueue();
      await _refreshStats(nextAction: 'all queued operations processed');
    } catch (_) {
      await _refreshStats(nextAction: 'sync error');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  Future<SyncQueueEntry> queueMutation({
    required String domain,
    required String httpMethod,
    required String path,
    required Map<String, dynamic> payload,
    Map<String, dynamic> queryParameters = const {},
    int? maxRetryCount,
    SyncOperationType? operation,
    DateTime? clientUpdatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final resolvedOperation =
        operation ?? _operationFromMethod(httpMethod.toUpperCase());
    final entry = SyncQueueEntry(
      id: _uuid.v4(),
      domain: domain,
      operation: resolvedOperation,
      httpMethod: httpMethod.toUpperCase(),
      path: path,
      payload: Map<String, dynamic>.from(payload),
      queryParameters: Map<String, dynamic>.from(queryParameters),
      status: SyncQueueStatus.pending,
      createdAt: now,
      updatedAt: now,
      maxRetryCount: maxRetryCount ?? defaultMaxRetryCount,
      clientUpdatedAt: clientUpdatedAt,
      versionVector: const {},
    );

    await _queueStore.upsert(entry);
    await _refreshStats(nextAction: 'queued operation');
    unawaited(syncPending());

    return entry;
  }

  Future<void> retryFailedEntries() async {
    final entries = await _queueStore.fetchByStatus(SyncQueueStatus.failed);
    if (entries.isEmpty) {
      return;
    }
    await Future.wait(
      entries.map((entry) async {
        if (!entry.isRetryable) {
          return;
        }
        final retried = entry.copyWith(
          status: SyncQueueStatus.pending,
          errorMessage: null,
          errorCode: null,
        );
        await _queueStore.upsert(retried);
      }),
    );

    await syncPending();
  }

  Future<SyncServiceStats> currentStats() async {
    return _readStats(nextAction: 'manual status');
  }

  Future<void> _flushQueue() async {
    final entries = await _queueStore.fetchAll();
    final processable = [...entries.where(_isProcessable)]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final entry in processable) {
      final adapter = _adapterRegistry.resolve(entry.domain);
      if (adapter == null) {
        final notHandled = entry.copyWith(
          status: SyncQueueStatus.failed,
          errorCode: 'NO_ADAPTER',
          errorMessage: 'No sync adapter found for domain: ${entry.domain}',
        );
        await _queueStore.upsert(notHandled);
        continue;
      }

      final syncing = entry.copyWith(status: SyncQueueStatus.syncing);
      await _queueStore.upsert(syncing);

      try {
        await adapter.replay(entry: syncing, apiClient: _apiClient);
        final done = syncing.copyWith(
          status: SyncQueueStatus.synced,
          lastSyncedAt: DateTime.now().toUtc(),
          errorMessage: null,
          errorCode: null,
          retryCount: 0,
        );
        await _queueStore.upsert(done);
        _lastSyncAt = DateTime.now().toUtc();
      } catch (error, stack) {
        final (errorCode, message) = _buildReplayError(error);
        final nextRetryCount = syncing.retryCount + 1;

        final failed = syncing.copyWith(
          status:
              nextRetryCount >= syncing.maxRetryCount
                  ? SyncQueueStatus.failed
                  : SyncQueueStatus.pending,
          lastSyncedAt: DateTime.now().toUtc(),
          retryCount: nextRetryCount,
          errorCode: errorCode,
          errorMessage: message,
        );
        await _queueStore.upsert(failed);
        unawaited(_logReplayError(entry.id, error, stack));
      }
    }
  }

  bool _isProcessable(SyncQueueEntry entry) {
    if (entry.status == SyncQueueStatus.synced) {
      return false;
    }
    return entry.isRetryable || entry.status == SyncQueueStatus.pending;
  }

  Future<void> _refreshStats({String nextAction = 'idle'}) async {
    final stats = await _readStats(nextAction: nextAction);
    _statsStream.add(stats);
  }

  Future<SyncServiceStats> _readStats({String nextAction = 'idle'}) async {
    final allEntries = await _queueStore.fetchAll();
    return SyncServiceStats(
      total: allEntries.length,
      pending:
          allEntries.where((e) => e.status == SyncQueueStatus.pending).length,
      syncing:
          allEntries.where((e) => e.status == SyncQueueStatus.syncing).length,
      synced:
          allEntries.where((e) => e.status == SyncQueueStatus.synced).length,
      failed:
          allEntries.where((e) => e.status == SyncQueueStatus.failed).length,
      online: await _connectivityService.isOnline,
      lastSyncAt: _lastSyncAt,
      nextAction: nextAction,
    );
  }

  Future<void> _logReplayError(
    String entryId,
    Object error,
    StackTrace? stack,
  ) async {
    // Keep this intentionally lightweight to avoid recursion or dependency on logging.
    if (stack == null) return;
    final message = '$error\n$stack';
    // ignore: avoid_print
    print('[SyncService] replay failed for $entryId: $message');
  }

  SyncOperationType _operationFromMethod(String method) {
    switch (method) {
      case 'POST':
        return SyncOperationType.create;
      case 'PUT':
      case 'PATCH':
        return SyncOperationType.update;
      case 'DELETE':
        return SyncOperationType.delete;
      default:
        return SyncOperationType.custom;
    }
  }

  (String? code, String message) _buildReplayError(Object error) {
    final errorText = '$error';
    return (null, errorText);
  }
}
