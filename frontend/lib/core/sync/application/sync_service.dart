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
    Future<void> Function(String path)? invalidateCachedReads,
    this.pollingInterval = const Duration(seconds: 30),
    this.defaultMaxRetryCount = 5,
  }) : _queueStore = queueStore,
       _connectivityService = connectivityService,
       _adapterRegistry = adapterRegistry,
       _apiClient = apiClient,
       _invalidateCachedReads = invalidateCachedReads;

  final SyncQueueStore _queueStore;
  final ConnectivityService _connectivityService;
  final SyncAdapterRegistry _adapterRegistry;
  final ApiClient _apiClient;

  /// N7: drops cached GET responses for the mutated path's domain so an
  /// offline write is not followed by a stale offline read. Replays go
  /// through the HTTP interceptor, which invalidates again on success.
  final Future<void> Function(String path)? _invalidateCachedReads;

  final Duration pollingInterval;
  final int defaultMaxRetryCount;

  final _uuid = const Uuid();
  final _statsStream = StreamController<SyncServiceStats>.broadcast();
  StreamSubscription<SyncConnectivity>? _connectivitySubscription;
  bool _isDisposed = false;

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
    // #1162: reclassify entries left in `syncing` by an app kill mid-replay
    // BEFORE any flush, so an orphan is never blindly re-sent.
    await _recoverOrphanedSyncingEntries();
    await _queueStore.cleanup();
    await _refreshStats();
    await syncPending();

    _connectivitySubscription = _connectivityService.connectivityChanges.listen(
      (state) {
        if (_isDisposed) {
          return;
        }
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
    _isDisposed = true;
    await _connectivitySubscription?.cancel();
    _pollTimer?.cancel();
    if (!_statsStream.isClosed) {
      await _statsStream.close();
    }
  }

  Future<void> syncPending() async {
    if (_isDisposed) {
      return;
    }
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
      await _queueStore.cleanup();
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
    String? idempotencyKey,
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
      idempotencyKey: idempotencyKey,
    );

    await _queueStore.upsert(entry);
    final invalidate = _invalidateCachedReads;
    if (invalidate != null) {
      try {
        await invalidate(path);
      } catch (_) {
        // Best-effort — a failed invalidation must not lose the queued write.
      }
    }
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
    final candidates = [...entries.where(_isPending)]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // S3 — dependency order. Writes to one domain are causally ordered
    // (create → update → delete). If an earlier write is still waiting on its
    // backoff, or fails during this pass, every later write to the SAME domain
    // must wait too — otherwise an update replays before the create that
    // produced the row (404 → retries exhausted → the write is lost).
    // Permanently failed entries (retries exhausted) do NOT block, or the queue
    // would stall forever.
    final blockedDomains = <String>{};

    for (final entry in candidates) {
      if (blockedDomains.contains(entry.domain)) {
        continue;
      }
      if (!_isProcessable(entry)) {
        // Still in backoff — hold the rest of this domain for the next pass.
        blockedDomains.add(entry.domain);
        continue;
      }

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
        // Retryable failure → later writes to this domain must not overtake it.
        if (failed.status == SyncQueueStatus.pending) {
          blockedDomains.add(entry.domain);
        }
        unawaited(_logReplayError(entry.id, error, stack));
      }
    }
  }

  /// #1162: error code stamped on a legacy `POST` orphan that cannot be safely
  /// replayed (no idempotency key → replay risks a duplicate). Surfaced to the
  /// sync status UI (#1120) rather than silently dropped or duplicated.
  static const String orphanedUnsafeReplayCode = 'ORPHANED_UNSAFE_REPLAY';

  /// #1162: reclassify entries stuck in `syncing` after an app kill mid-replay.
  ///
  /// The server-delivery state of an orphan is unknown, so neither blind replay
  /// (duplicate) nor drop (lost write) is safe on its own:
  /// - has an idempotency key → `pending`; replay dedupes on the server (#1117).
  /// - no key, PUT/PATCH/DELETE → `pending`; these are naturally idempotent
  ///   (they set a target resource's state, they don't create new rows).
  /// - no key, POST (legacy entry) → `failed` with [orphanedUnsafeReplayCode];
  ///   a blind replay could duplicate, so hand the decision to the user.
  Future<void> _recoverOrphanedSyncingEntries() async {
    final orphans = await _queueStore.fetchByStatus(SyncQueueStatus.syncing);
    for (final entry in orphans) {
      final safeToReplay =
          entry.idempotencyKey != null ||
          entry.httpMethod.toUpperCase() != 'POST';
      if (safeToReplay) {
        await _queueStore.upsert(
          entry.copyWith(status: SyncQueueStatus.pending),
        );
      } else {
        // Terminal failure (retryCount maxed) so the flush never auto-replays
        // it — the user decides via the sync status UI (#1120).
        await _queueStore.upsert(
          entry.copyWith(
            status: SyncQueueStatus.failed,
            retryCount: entry.maxRetryCount,
            errorCode: orphanedUnsafeReplayCode,
            errorMessage:
                'App closed mid-sync; this create request has no idempotency key '
                'and cannot be safely retried automatically.',
          ),
        );
      }
    }
  }

  /// Entries that are candidates for this flush pass (backoff is evaluated
  /// per-entry by [_isProcessable] so a skipped entry can block its domain).
  ///
  /// #1162: `syncing` is NOT a candidate. Within a flush each entry is set to
  /// `syncing` and processed immediately, so a leftover `syncing` means a prior
  /// run was killed mid-replay — that orphan is reclassified explicitly at
  /// startup ([_recoverOrphanedSyncingEntries]), never implicitly re-sent here.
  bool _isPending(SyncQueueEntry entry) =>
      entry.status != SyncQueueStatus.synced &&
      entry.status != SyncQueueStatus.syncing &&
      entry.isRetryable;

  bool _isProcessable(SyncQueueEntry entry) {
    if (entry.status == SyncQueueStatus.synced) {
      return false;
    }
    // #1162: never treat `syncing` as implicitly retryable (see [_isPending]).
    if (entry.status == SyncQueueStatus.syncing) {
      return false;
    }

    // For pending entries with retry count, check if backoff period has elapsed
    if (entry.status == SyncQueueStatus.pending && entry.retryCount > 0) {
      final requiredBackoff = _backoffDelay(entry.retryCount);
      final timeSinceUpdate = DateTime.now().toUtc().difference(
        entry.updatedAt,
      );
      if (timeSinceUpdate < requiredBackoff) {
        return false; // Still in backoff period
      }
    }

    return entry.isRetryable || entry.status == SyncQueueStatus.pending;
  }

  Future<void> _refreshStats({String nextAction = 'idle'}) async {
    if (_statsStream.isClosed) {
      return;
    }
    final stats = await _readStats(nextAction: nextAction);
    if (_statsStream.isClosed) {
      return;
    }
    try {
      _statsStream.add(stats);
    } catch (error) {
      if (_statsStream.isClosed || error is StateError) {
        return;
      }
      rethrow;
    }
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

  Duration _backoffDelay(int retryCount) {
    // Exponential backoff: 2^retryCount, capped at 30 seconds
    final baseSeconds =
        1 << (retryCount - 1).clamp(0, 4); // 2^0=1, 2^1=2, 2^2=4, 2^3=8, 2^4=16
    return Duration(seconds: baseSeconds.clamp(1, 30));
  }
}
