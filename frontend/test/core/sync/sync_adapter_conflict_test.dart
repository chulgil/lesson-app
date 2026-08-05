import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/network/interceptors/idempotency_interceptor.dart';
import 'package:lessonaza/core/sync/application/sync_adapter.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:mocktail/mocktail.dart';

class FakeApiClient extends Mock implements ApiClient {}

Response<dynamic> _emptyResponse(String path) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
}

SyncQueueEntry _makeEntry({
  required String domain,
  String httpMethod = 'PUT',
  DateTime? clientUpdatedAt,
  String? idempotencyKey,
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
    idempotencyKey: idempotencyKey,
  );
}

void main() {
  late FakeApiClient apiClient;

  setUp(() {
    apiClient = FakeApiClient();
    registerFallbackValue(<String, dynamic>{});
    when(
      () => apiClient.put<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((inv) async {
      return _emptyResponse(inv.positionalArguments.first as String);
    });
  });

  Options? capturedPutOptions() {
    return verify(
          () => apiClient.put<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: captureAny(named: 'options'),
          ),
        ).captured.single
        as Options?;
  }

  group('conflictStrategyForDomain', () {
    test('lesson / subscription → serverWins', () {
      expect(
        conflictStrategyForDomain('lesson'),
        SyncConflictStrategy.serverWins,
      );
      expect(
        conflictStrategyForDomain('subscription'),
        SyncConflictStrategy.serverWins,
      );
    });

    test('practice / settings / notification-settings → lastWriteWins', () {
      expect(
        conflictStrategyForDomain('practice'),
        SyncConflictStrategy.lastWriteWins,
      );
      expect(
        conflictStrategyForDomain('settings'),
        SyncConflictStrategy.lastWriteWins,
      );
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

  group('RestSyncAdapter — pre-send If-Unmodified-Since (#1119)', () {
    test(
      'LWW entry with clientUpdatedAt attaches the precondition header',
      () async {
        final adapter = RestSyncAdapter(domain: 'practice');
        final base = DateTime.utc(2026, 6, 1, 12);
        final entry = _makeEntry(domain: 'practice', clientUpdatedAt: base);

        await adapter.replay(entry: entry, apiClient: apiClient);

        final options = capturedPutOptions();
        expect(options, isNotNull);
        expect(
          options!.headers?[ifUnmodifiedSinceHeader],
          base.toIso8601String(),
        );
      },
    );

    test(
      'LWW entry without clientUpdatedAt sends no precondition header',
      () async {
        final adapter = RestSyncAdapter(domain: 'practice');
        final entry = _makeEntry(domain: 'practice'); // clientUpdatedAt = null

        await adapter.replay(entry: entry, apiClient: apiClient);

        final options = capturedPutOptions();
        expect(
          options?.headers?.containsKey(ifUnmodifiedSinceHeader) ?? false,
          isFalse,
        );
      },
    );

    test('serverWins domain never attaches the precondition header', () async {
      final adapter = RestSyncAdapter(domain: 'lesson');
      final entry = _makeEntry(
        domain: 'lesson',
        clientUpdatedAt: DateTime.utc(2026, 6, 1),
      );

      // Server-Wins just sends — it does not reject on a newer server version.
      await adapter.replay(entry: entry, apiClient: apiClient);

      final options = capturedPutOptions();
      expect(
        options?.headers?.containsKey(ifUnmodifiedSinceHeader) ?? false,
        isFalse,
      );
    });

    test('clientWins domain never attaches the precondition header', () async {
      final adapter = RestSyncAdapter(domain: 'recording');
      final entry = _makeEntry(
        domain: 'recording',
        clientUpdatedAt: DateTime.utc(2026, 6, 1),
      );

      await adapter.replay(entry: entry, apiClient: apiClient);

      final options = capturedPutOptions();
      expect(
        options?.headers?.containsKey(ifUnmodifiedSinceHeader) ?? false,
        isFalse,
      );
    });

    test('LWW entry with both idempotency key and clientUpdatedAt sends both '
        'headers', () async {
      final adapter = RestSyncAdapter(domain: 'practice');
      final base = DateTime.utc(2026, 6, 1, 12);
      final entry = _makeEntry(
        domain: 'practice',
        clientUpdatedAt: base,
        idempotencyKey: 'key-123',
      );

      await adapter.replay(entry: entry, apiClient: apiClient);

      final options = capturedPutOptions();
      expect(
        options!.headers?[ifUnmodifiedSinceHeader],
        base.toIso8601String(),
      );
      expect(options.headers?[IdempotencyInterceptor.headerName], 'key-123');
    });
  });
}
