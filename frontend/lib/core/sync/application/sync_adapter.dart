import '../../../core/network/api_client.dart';

import '../domain/sync_queue_entry.dart';

/// Conflict resolution strategy per domain type.
///
/// Mapping (see docs/proposal/offline_first_architecture.md):
///   serverWins  — lesson, subscription (booking / payment)
///   lastWriteWins — practice, settings
///   clientWins  — recording (device-only origin)
enum SyncConflictStrategy {
  /// Server response always overwrites the local change.
  /// Used for: lesson, subscription/payment domains.
  serverWins,

  /// Whichever side has the later timestamp wins.
  /// Used for: practice, settings domains.
  lastWriteWins,

  /// Local (client) change is always applied without checking the server.
  /// Used for: recording domains.
  clientWins,
}

/// Maps a domain string to its conflict resolution strategy.
///
/// Domains not listed here default to [SyncConflictStrategy.serverWins]
/// (safe fallback: never lose server-authoritative data).
SyncConflictStrategy conflictStrategyForDomain(String domain) {
  switch (domain) {
    // Practice data is user-device-independent — LWW is safe.
    case 'practice':
    // User preferences — latest edit wins.
    case 'settings':
    case 'notification-settings':
      return SyncConflictStrategy.lastWriteWins;

    // Recordings are only created on device — client always wins.
    case 'recording':
      return SyncConflictStrategy.clientWins;

    // Everything else (lesson, subscription, payment, auth, …) — server wins.
    default:
      return SyncConflictStrategy.serverWins;
  }
}

abstract class SyncAdapter {
  const SyncAdapter({required this.domain});

  final String domain;

  bool canHandle(String entryDomain) {
    return domain == entryDomain;
  }

  /// Returns true if the local mutation should be applied based on LWW.
  ///
  /// Only called when the conflict strategy is [SyncConflictStrategy.lastWriteWins].
  /// Returns true when [serverUpdatedAt] is null (no server record yet) or when
  /// [entry.clientUpdatedAt] is strictly after [serverUpdatedAt].
  Future<bool> shouldApplyByLastWriteWins({
    required SyncQueueEntry entry,
    DateTime? serverUpdatedAt,
  }) {
    if (serverUpdatedAt == null) {
      return Future.value(true);
    }

    final localUpdatedAt = entry.clientUpdatedAt;
    if (localUpdatedAt == null) {
      return Future.value(true);
    }

    return Future.value(localUpdatedAt.isAfter(serverUpdatedAt));
  }

  Future<void> replay({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  });
}

class RestSyncAdapter extends SyncAdapter {
  RestSyncAdapter({required super.domain});

  @override
  Future<void> replay({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  }) async {
    final strategy = conflictStrategyForDomain(entry.domain);

    // clientWins: send the request unconditionally without conflict check.
    if (strategy == SyncConflictStrategy.clientWins) {
      await _sendRequest(entry: entry, apiClient: apiClient);
      return;
    }

    // serverWins or lastWriteWins: send the request and inspect the response.
    final response = await _sendRequest(entry: entry, apiClient: apiClient);

    if (strategy == SyncConflictStrategy.serverWins) {
      // Server-Wins: the HTTP request itself is enough — the server's state
      // is authoritative. No client-side conflict guard needed.
      return;
    }

    // lastWriteWins: check the server's updatedAt in the response body.
    if (strategy == SyncConflictStrategy.lastWriteWins) {
      final responseData = response?.data;
      final serverUpdatedAt = _extractUpdatedAt(responseData);

      // If the server record is newer, the server already has a more recent
      // write. We still completed the HTTP round-trip; the local data should
      // be treated as superseded. This adapter does not auto-revert the local
      // cache — callers (repository layer) are responsible for refreshing.
      // We only raise a [SyncConflictException] so the caller can handle it.
      final shouldApply = await shouldApplyByLastWriteWins(
        entry: entry,
        serverUpdatedAt: serverUpdatedAt,
      );
      if (!shouldApply) {
        throw SyncConflictException(
          domain: entry.domain,
          entryId: entry.id,
          clientUpdatedAt: entry.clientUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
        );
      }
    }
  }

  /// Sends the appropriate HTTP request and returns the [Response] for callers
  /// that need to inspect the response body (e.g. LWW conflict detection).
  Future<dynamic> _sendRequest({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  }) async {
    switch (entry.httpMethod.toUpperCase()) {
      case 'POST':
        return apiClient.post<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
      case 'PUT':
        return apiClient.put<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
      case 'PATCH':
        return apiClient.patch<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
      case 'DELETE':
        return apiClient.delete<dynamic>(
          entry.path,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
      default:
        throw StateError('Unsupported queued method: ${entry.httpMethod}');
    }
  }

  /// Parses `updatedAt` from the response body map.
  ///
  /// Our backend returns `{"updated_at": "..."}` (snake_case) or
  /// `{"updatedAt": "..."}` (camelCase). Returns null if neither key exists
  /// or if the value is not a valid ISO-8601 string.
  DateTime? _extractUpdatedAt(dynamic responseData) {
    if (responseData is! Map) {
      return null;
    }
    final raw =
        responseData['updatedAt'] as String? ??
        responseData['updated_at'] as String?;
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  Map<String, dynamic>? _normalizeQuery(Map<String, dynamic> query) {
    return query.isEmpty ? null : query;
  }
}

/// Thrown by [RestSyncAdapter] when a LWW conflict is detected:
/// the server record was updated more recently than the local mutation.
///
/// The sync service catches this and marks the entry as [SyncQueueStatus.failed]
/// with errorCode [SyncConflictException.errorCode]. The repository layer is
/// responsible for re-fetching the server state if needed.
class SyncConflictException implements Exception {
  const SyncConflictException({
    required this.domain,
    required this.entryId,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
  });

  static const String errorCode = 'CONFLICT_LWW_REJECTED';

  final String domain;
  final String entryId;
  final DateTime? clientUpdatedAt;
  final DateTime? serverUpdatedAt;

  @override
  String toString() =>
      'SyncConflictException[$domain/$entryId] $errorCode: '
      'client=$clientUpdatedAt server=$serverUpdatedAt — server is newer, local write rejected';
}
