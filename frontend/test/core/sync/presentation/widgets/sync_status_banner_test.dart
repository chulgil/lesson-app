import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/sync_adapter_registry.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/core/sync/data/sync_queue_store.dart';
import 'package:lessonaza/core/sync/domain/sync_queue_entry.dart';
import 'package:lessonaza/core/sync/presentation/providers/connectivity_banner_provider.dart';
import 'package:lessonaza/core/sync/presentation/providers/sync_provider.dart';
import 'package:lessonaza/core/sync/presentation/widgets/sync_status_banner.dart';
import 'package:lessonaza/core/widgets/offline_banner.dart';
import 'package:mocktail/mocktail.dart';

class _FakeApiClient extends Mock implements ApiClient {}

class _OfflineConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.none,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A SyncService whose failure list is an in-memory fixture — no Hive I/O, so
/// the panel's FutureBuilder resolves immediately (a real Hive read never
/// settles under the test binding, hanging pumpAndSettle on the spinner).
class _FakeSyncService extends SyncService {
  _FakeSyncService(this._entries)
    : super(
        queueStore: SyncQueueStore(),
        connectivityService: ConnectivityService(_OfflineConnectivity()),
        adapterRegistry: SyncAdapterRegistry.create(),
        apiClient: _FakeApiClient(),
      );

  final List<SyncQueueEntry> _entries;

  @override
  Future<List<SyncQueueEntry>> failedEntries() async => List.of(_entries);

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> retryEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}

SyncQueueEntry _failedEntry(String id, {String? errorCode}) {
  final now = DateTime.now().toUtc();
  return SyncQueueEntry(
    id: id,
    domain: 'practice',
    operation: SyncOperationType.update,
    httpMethod: 'PUT',
    path: '/practice-logs/$id',
    payload: const {},
    status: SyncQueueStatus.failed,
    createdAt: now,
    updatedAt: now,
    retryCount: 5,
    maxRetryCount: 5,
    errorCode: errorCode,
  );
}

SyncServiceStats _stats({
  int pending = 0,
  int syncing = 0,
  int failed = 0,
  bool online = true,
}) {
  return SyncServiceStats(
    total: pending + syncing + failed,
    pending: pending,
    syncing: syncing,
    synced: 0,
    failed: failed,
    online: online,
    lastSyncAt: null,
    nextAction: '',
  );
}

Widget _host(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('SyncStatusBanner — strip states', () {
    testWidgets('empty backlog renders nothing', (tester) async {
      await tester.pumpWidget(_host(SyncStatusBanner(stats: _stats())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('pending (online) shows the waiting count', (tester) async {
      await tester.pumpWidget(
        _host(SyncStatusBanner(stats: _stats(pending: 3, online: true))),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.syncStatusPending(3)), findsOneWidget);
    });

    testWidgets('pending (offline) shows the offline waiting count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(SyncStatusBanner(stats: _stats(pending: 3, online: false))),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.syncStatusPendingOffline(3)), findsOneWidget);
    });

    testWidgets('syncing shows count and a spinner', (tester) async {
      await tester.pumpWidget(
        _host(SyncStatusBanner(stats: _stats(syncing: 2))),
      );
      await tester.pump();
      expect(find.text(AppStrings.syncStatusSyncing(2)), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('failed strip wins over pending without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(SyncStatusBanner(stats: _stats(pending: 1, failed: 1))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.syncStatusFailed(1)), findsOneWidget);
      expect(find.text(AppStrings.syncStatusPending(1)), findsNothing);
    });
  });

  group('SyncStatusBanner — failed panel', () {
    testWidgets('tapping the failed strip expands per-entry descriptions '
        'including the orphan copy', (tester) async {
      final service = _FakeSyncService([
        _failedEntry('e1', errorCode: SyncService.orphanedUnsafeReplayCode),
        _failedEntry('e2'),
      ]);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        _host(
          SyncStatusBanner(stats: _stats(failed: 2)),
          overrides: [syncServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.syncStatusFailed(2)));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.syncOrphanEntryDescription), findsOneWidget);
      expect(find.text(AppStrings.syncEntryFailedDescription), findsOneWidget);
    });

    testWidgets('delete removes the entry from the queue', (tester) async {
      final service = _FakeSyncService([
        _failedEntry('e1'),
        _failedEntry('e2'),
      ]);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        _host(
          SyncStatusBanner(stats: _stats(failed: 2)),
          overrides: [syncServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      await tester.tap(find.text(AppStrings.syncStatusFailed(2)));
      await tester.pumpAndSettle();

      expect(await service.failedEntries(), hasLength(2));

      await tester.tap(find.text(AppStrings.syncDeleteAction).first);
      await tester.pumpAndSettle();

      expect(await service.failedEntries(), hasLength(1));
    });
  });

  group('OfflineBannerWrapper mounts the sync strip (all roles)', () {
    testWidgets('write backlog renders the failed sync strip globally', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineBannerProvider.overrideWith((ref) => Stream.value(false)),
            syncServiceStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_stats(failed: 2)),
            ),
          ],
          child: const MaterialApp(
            home: OfflineBannerWrapper(child: Scaffold(body: Text('content'))),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.syncStatusFailed(2)), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
