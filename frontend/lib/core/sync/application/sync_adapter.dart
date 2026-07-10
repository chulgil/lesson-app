import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../network/interceptors/idempotency_interceptor.dart';
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

/// #1119 (D4): conditional-request header carrying the base version the client
/// edited from. The server rejects (412) when the resource was modified after
/// this timestamp, so a Last-Write-Wins conflict is decided BEFORE the write is
/// committed — not after (which could not reject). We send an ISO-8601 UTC value
/// (both ends are ours; full sub-second precision, unlike HTTP-date).
const String ifUnmodifiedSinceHeader = 'If-Unmodified-Since';

/// #1119 (D4): error code the server returns (HTTP 412) when a Last-Write-Wins
/// write is rejected because the server holds a newer version. Deterministic —
/// [SyncService] marks the entry failed immediately (no retries) and surfaces a
/// rejection to the user. Mirrors backend `LastWriteWinsConflictException`.
const String conflictLwwRejectedCode = 'CONFLICT_LWW_REJECTED';

abstract class SyncAdapter {
  const SyncAdapter({required this.domain});

  final String domain;

  bool canHandle(String entryDomain) {
    return domain == entryDomain;
  }

  Future<void> replay({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  });
}

class RestSyncAdapter extends SyncAdapter {
  RestSyncAdapter({required super.domain});

  /// #1119 (D4): every strategy just sends the request now — the conflict
  /// decision is a PRE-send precondition, not a POST-send response comparison.
  /// For [SyncConflictStrategy.lastWriteWins] domains [_replayOptions] attaches
  /// the [ifUnmodifiedSinceHeader] so the server rejects (412 with
  /// [conflictLwwRejectedCode]) when it holds a newer version; the rejection
  /// then propagates for [SyncService] to mark the entry failed and surface it.
  /// serverWins/clientWins send unconditionally (no precondition header).
  @override
  Future<void> replay({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  }) async {
    await _sendRequest(entry: entry, apiClient: apiClient);
  }

  /// Sends the appropriate HTTP request and returns the [Response] for callers
  /// that need to inspect the response body (e.g. LWW conflict detection).
  Future<dynamic> _sendRequest({
    required SyncQueueEntry entry,
    required ApiClient apiClient,
  }) async {
    final options = _replayOptions(entry);
    switch (entry.httpMethod.toUpperCase()) {
      case 'POST':
        return apiClient.post<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
          options: options,
        );
      case 'PUT':
        return apiClient.put<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
          options: options,
        );
      case 'PATCH':
        return apiClient.patch<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
          options: options,
        );
      case 'DELETE':
        return apiClient.delete<dynamic>(
          entry.path,
          queryParameters: _normalizeQuery(entry.queryParameters),
          options: options,
        );
      default:
        throw StateError('Unsupported queued method: ${entry.httpMethod}');
    }
  }

  /// Builds the replay request options, attaching:
  /// - #1117 the stored `Idempotency-Key` so the server dedupes a POST it may
  ///   already have committed (also makes `IdempotencyInterceptor` skip
  ///   regenerating one — it never overwrites an existing header).
  /// - #1119 the [ifUnmodifiedSinceHeader] for Last-Write-Wins domains carrying
  ///   the entry's `clientUpdatedAt` (the base version), so the server rejects a
  ///   write it has since superseded (412 [conflictLwwRejectedCode]).
  ///
  /// Returns null when neither header applies.
  Options? _replayOptions(SyncQueueEntry entry) {
    final headers = <String, dynamic>{};

    final key = entry.idempotencyKey;
    if (key != null) {
      headers[IdempotencyInterceptor.headerName] = key;
    }

    final clientUpdatedAt = entry.clientUpdatedAt;
    if (clientUpdatedAt != null &&
        conflictStrategyForDomain(entry.domain) ==
            SyncConflictStrategy.lastWriteWins) {
      headers[ifUnmodifiedSinceHeader] = clientUpdatedAt
          .toUtc()
          .toIso8601String();
    }

    return headers.isEmpty ? null : Options(headers: headers);
  }

  Map<String, dynamic>? _normalizeQuery(Map<String, dynamic> query) {
    return query.isEmpty ? null : query;
  }
}
