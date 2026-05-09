import '../../network/api_exceptions.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

/// Shared helper that wraps repository mutation calls with offline-queue support.
///
/// Online path: calls [remoteCall] directly and returns its result.
/// Offline / network-error path: enqueues via [SyncService.queueMutation],
/// then returns an optimistic result so the UI can proceed without blocking.
class MutationQueueHelper {
  MutationQueueHelper({
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _connectivity = connectivity,
        _syncService = syncService;

  final ConnectivityService _connectivity;
  final SyncService _syncService;

  /// Execute a mutation that returns [T].
  ///
  /// - [remoteCall]: the actual API call via RemoteRepository.
  /// - [queueCall]: enqueues the mutation via [SyncService].
  /// - [optimisticResult]: fabricates an immediate return value for offline use.
  Future<T> executeMutation<T>({
    required Future<T> Function() remoteCall,
    required Future<void> Function(SyncService syncService) queueCall,
    required T Function() optimisticResult,
  }) async {
    final online = await _connectivity.isOnline;

    if (!online) {
      await queueCall(_syncService);
      return optimisticResult();
    }

    try {
      return await remoteCall();
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        await queueCall(_syncService);
        return optimisticResult();
      }
      rethrow;
    }
  }

  /// Execute a void mutation (delete, cancel, archive, etc.)
  Future<void> executeVoidMutation({
    required Future<void> Function() remoteCall,
    required Future<void> Function(SyncService syncService) queueCall,
  }) async {
    final online = await _connectivity.isOnline;

    if (!online) {
      await queueCall(_syncService);
      return;
    }

    try {
      await remoteCall();
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        await queueCall(_syncService);
        return;
      }
      rethrow;
    }
  }

  /// Returns true for exceptions that indicate network unavailability
  /// (should fall back to queue), false for business errors (should propagate).
  bool _isNetworkFailure(Exception e) {
    if (e is NetworkException) return true;
    if (e is ServerException) return true;
    if (e is ApiException && e.statusCode != null && e.statusCode! >= 500) {
      return true;
    }
    return false;
  }
}
