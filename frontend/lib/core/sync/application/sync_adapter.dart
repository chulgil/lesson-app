import '../../network/api_client.dart';

import '../domain/sync_queue_entry.dart';

abstract class SyncAdapter {
  const SyncAdapter({required this.domain});

  final String domain;

  bool canHandle(String entryDomain) {
    return domain == entryDomain;
  }

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
    switch (entry.httpMethod.toUpperCase()) {
      case 'POST':
        await apiClient.post<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
        break;
      case 'PUT':
        await apiClient.put<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
        break;
      case 'PATCH':
        await apiClient.patch<dynamic>(
          entry.path,
          data: entry.payload,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
        break;
      case 'DELETE':
        await apiClient.delete<dynamic>(
          entry.path,
          queryParameters: _normalizeQuery(entry.queryParameters),
        );
        break;
      default:
        throw StateError('Unsupported queued method: ${entry.httpMethod}');
    }
  }

  Map<String, dynamic>? _normalizeQuery(Map<String, dynamic> query) {
    return query.isEmpty ? null : query;
  }
}
