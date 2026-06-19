import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/sync/application/sync_adapter.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:mocktail/mocktail.dart';

class FakeApiClient extends Mock implements ApiClient {}

/// Builds a [Response] whose data map contains an updatedAt field.
Response<dynamic> _responseWithUpdatedAt(String path, String updatedAt) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: <String, dynamic>{'updatedAt': updatedAt},
  );
}

Response<dynamic> _emptyResponse(String path) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

SyncQueueEntry _makeEntry({
  required String domain,
  String httpMethod = 'PATCH',
  DateTime? clientUpdatedAt,
}) {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: 'test-id',
    domain: domain,
    operation: SyncOperationType.update,
    httpMethod: httpMethod,
    path: '/test/$domain/1',
    payload: const {'value': 1},
    status: SyncQueueStatus.pending,
    createdAt: now,
    updatedAt: now,
    clientUpdatedAt: clientUpdatedAt,
  );
}

void main() {
  late FakeApiClient apiClient;

  setUp(() {
    apiClient = FakeApiClient();
    registerFallbackValue(<String, dynamic>{});
  });

  group('conflictStrategyForDomain', () {
    test('lesson → serverWins', () {
      expect(
        conflictStrategyForDomain('lesson'),
        SyncConflictStrategy.serverWins,
      );
    });

    test('subscription → serverWins', () {
      expect(
        conflictStrategyForDomain('subscription'),
        SyncConflictStrategy.serverWins,
      );
    });

    test('practice → lastWriteWins', () {
      expect(
        conflictStrategyForDomain('practice'),
        SyncConflictStrategy.lastWriteWins,
      );
    });

    test('settings → lastWriteWins', () {
      expect(
        conflictStrategyForDomain('settings'),
        SyncConflictStrategy.lastWriteWins,
      );
    });

    test('notification-settings → lastWriteWins', () {
      expect(
        conflictStrategyForDomain('notification-settings'),
        SyncConflictStrategy.lastWriteWins,
      );
    });

    test('recording → clientWins', () {
      expect(
        conflictStrategyForDomain('recording'),
        SyncConflictStrategy.clientWins,
      );
    });

    test('unknown domain defaults to serverWins', () {
      expect(
        conflictStrategyForDomain('some-unknown-domain'),
        SyncConflictStrategy.serverWins,
      );
    });
  });

  group('RestSyncAdapter — Server-Wins (lesson)', () {
    test('sends PATCH and does not throw even if server is newer', () async {
      final adapter = RestSyncAdapter(domain: 'lesson');
      final entry = _makeEntry(
        domain: 'lesson',
        clientUpdatedAt: DateTime(2026, 1, 1),
      );

      // Server responds with a timestamp newer than client.
      when(
        () => apiClient.patch<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _responseWithUpdatedAt(
          '/test/lesson/1',
          '2026-12-31T00:00:00.000Z',
        ),
      );

      // Server-Wins never throws — the HTTP call is authoritative by itself.
      await expectLater(
        adapter.replay(entry: entry, apiClient: apiClient),
        completes,
      );
    });
  });

  group('RestSyncAdapter — Client-Wins (recording)', () {
    test('sends PATCH without any conflict check', () async {
      final adapter = RestSyncAdapter(domain: 'recording');
      final entry = _makeEntry(
        domain: 'recording',
        clientUpdatedAt: DateTime(2026, 1, 1),
      );

      when(
        () => apiClient.patch<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _emptyResponse('/test/recording/1'));

      // Client-Wins always applies; no SyncConflictException.
      await expectLater(
        adapter.replay(entry: entry, apiClient: apiClient),
        completes,
      );
    });
  });

  group('RestSyncAdapter — LWW (practice)', () {
    test('applies when client is newer than server', () async {
      final adapter = RestSyncAdapter(domain: 'practice');

      final serverTime = DateTime(2026, 6, 1, 12, 0, 0).toUtc();
      final clientTime = DateTime(2026, 6, 1, 13, 0, 0).toUtc(); // newer

      final entry = _makeEntry(domain: 'practice', clientUpdatedAt: clientTime);

      when(
        () => apiClient.patch<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _responseWithUpdatedAt(
          '/test/practice/1',
          serverTime.toIso8601String(),
        ),
      );

      // Client is newer → no exception.
      await expectLater(
        adapter.replay(entry: entry, apiClient: apiClient),
        completes,
      );
    });

    test(
      'throws SyncConflictException when server is newer than client',
      () async {
        final adapter = RestSyncAdapter(domain: 'practice');

        final serverTime = DateTime(2026, 6, 1, 14, 0, 0).toUtc(); // newer
        final clientTime = DateTime(2026, 6, 1, 12, 0, 0).toUtc();

        final entry = _makeEntry(
          domain: 'practice',
          clientUpdatedAt: clientTime,
        );

        when(
          () => apiClient.patch<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _responseWithUpdatedAt(
            '/test/practice/1',
            serverTime.toIso8601String(),
          ),
        );

        // Server is newer → conflict exception.
        await expectLater(
          adapter.replay(entry: entry, apiClient: apiClient),
          throwsA(
            isA<SyncConflictException>()
                .having((e) => e.domain, 'domain', 'practice')
                .having(
                  (e) => e.toString(),
                  'toString',
                  contains(SyncConflictException.errorCode),
                ),
          ),
        );
      },
    );

    test(
      'applies when server response has no updatedAt (new record)',
      () async {
        final adapter = RestSyncAdapter(domain: 'practice');

        final entry = _makeEntry(
          domain: 'practice',
          clientUpdatedAt: DateTime(2026, 6, 1).toUtc(),
        );

        // Response body has no updatedAt field → treat as no server record.
        when(
          () => apiClient.patch<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => _emptyResponse('/test/practice/1'));

        await expectLater(
          adapter.replay(entry: entry, apiClient: apiClient),
          completes,
        );
      },
    );

    test('applies when entry has no clientUpdatedAt', () async {
      final adapter = RestSyncAdapter(domain: 'practice');

      final entry = _makeEntry(domain: 'practice'); // clientUpdatedAt = null

      final serverTime = DateTime(2026, 6, 1, 14, 0, 0).toUtc();

      when(
        () => apiClient.patch<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _responseWithUpdatedAt(
          '/test/practice/1',
          serverTime.toIso8601String(),
        ),
      );

      // No client timestamp → conservative: apply (no exception).
      await expectLater(
        adapter.replay(entry: entry, apiClient: apiClient),
        completes,
      );
    });
  });

  group('RestSyncAdapter — LWW (settings)', () {
    test('throws SyncConflictException when server is newer', () async {
      final adapter = RestSyncAdapter(domain: 'settings');

      final serverTime = DateTime(2026, 6, 2).toUtc();
      final clientTime = DateTime(2026, 6, 1).toUtc();

      final entry = _makeEntry(
        domain: 'settings',
        httpMethod: 'PUT',
        clientUpdatedAt: clientTime,
      );

      when(
        () => apiClient.put<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _responseWithUpdatedAt(
          '/test/settings/1',
          serverTime.toIso8601String(),
        ),
      );

      await expectLater(
        adapter.replay(entry: entry, apiClient: apiClient),
        throwsA(isA<SyncConflictException>()),
      );
    });
  });

  group('shouldApplyByLastWriteWins', () {
    final adapter = RestSyncAdapter(domain: 'practice');
    final baseEntry = _makeEntry(domain: 'practice');

    test('returns true when serverUpdatedAt is null', () async {
      final entry = baseEntry.copyWith(
        clientUpdatedAt: DateTime(2026, 1, 1).toUtc(),
      );
      final result = await adapter.shouldApplyByLastWriteWins(
        entry: entry,
        serverUpdatedAt: null,
      );
      expect(result, isTrue);
    });

    test('returns true when clientUpdatedAt is null', () async {
      final result = await adapter.shouldApplyByLastWriteWins(
        entry: baseEntry,
        serverUpdatedAt: DateTime(2026, 6, 1).toUtc(),
      );
      expect(result, isTrue);
    });

    test('returns true when client is strictly after server', () async {
      final entry = baseEntry.copyWith(
        clientUpdatedAt: DateTime(2026, 6, 2).toUtc(),
      );
      final result = await adapter.shouldApplyByLastWriteWins(
        entry: entry,
        serverUpdatedAt: DateTime(2026, 6, 1).toUtc(),
      );
      expect(result, isTrue);
    });

    test('returns false when server is after client', () async {
      final entry = baseEntry.copyWith(
        clientUpdatedAt: DateTime(2026, 6, 1).toUtc(),
      );
      final result = await adapter.shouldApplyByLastWriteWins(
        entry: entry,
        serverUpdatedAt: DateTime(2026, 6, 2).toUtc(),
      );
      expect(result, isFalse);
    });

    test(
      'returns false when timestamps are equal (server not strictly older)',
      () async {
        final ts = DateTime(2026, 6, 1).toUtc();
        final entry = baseEntry.copyWith(clientUpdatedAt: ts);
        final result = await adapter.shouldApplyByLastWriteWins(
          entry: entry,
          serverUpdatedAt: ts,
        );
        expect(result, isFalse);
      },
    );
  });
}
