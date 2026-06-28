import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/network/cache/response_cache_policy.dart';
import 'package:lessonaza/core/network/cache/response_cache_store.dart';
import 'package:lessonaza/core/network/interceptors/response_cache_interceptor.dart';
import 'package:lessonaza/core/sync/application/connectivity_service.dart';
import 'package:lessonaza/core/sync/application/mutation_queue_helper.dart';
import 'package:lessonaza/core/sync/application/sync_service.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/data/repositories/sync_aware_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:mocktail/mocktail.dart';

/// Batch 1e (일원화) end-to-end: the teacher-availability stack — SyncAware (no
/// own cache) → Remote → ApiClient + ResponseCacheInterceptor — serves
/// last-known-good data offline via the single HTTP response cache
/// (offline-first plan §3 / §5). Uses the single-object `getAvailability`
/// endpoint (`GET /schedule/availability/$teacherId`) so the fake adapter body
/// is one TeacherAvailability.

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncService extends Mock implements SyncService {}

enum _Mode { online, offline }

class _FakeAdapter implements HttpClientAdapter {
  _Mode mode = _Mode.online;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (mode == _Mode.offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

TeacherAvailability _availability({String teacherId = 'teacher-1'}) =>
    TeacherAvailability(
      id: 'avail-$teacherId',
      teacherId: teacherId,
      slotDurationMinutes: 60,
      weeklySchedules: const [],
      exceptions: const [],
      autoGenerateWeeks: 4,
      createdAt: DateTime(2026, 6, 1),
      slotStartInterval: 60,
      breakTimeBetweenLessons: 0,
      minBookingHours: 24,
    );

/// `toJson` emits snake_case keys (teacher_id, created_at, …) — exactly what
/// [RemoteTeacherAvailabilityRepository]'s parser reads.
String _single(TeacherAvailability availability) =>
    jsonEncode(availability.toJson());

void main() {
  late _FakeAdapter adapter;
  late Box<String> box;
  late SyncAwareTeacherAvailabilityRepository repo;

  setUp(() async {
    await setUpTestHive();
    box = await Hive.openBox<String>(ResponseCacheStore.boxName);

    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      ResponseCacheInterceptor(
        store: ResponseCacheStore(box: box),
        policy: ResponseCachePolicy.active,
      ),
    );

    repo = SyncAwareTeacherAvailabilityRepository(
      remote: RemoteTeacherAvailabilityRepository(ApiClient(dio)),
      queue: MutationQueueHelper(
        connectivity: MockConnectivityService(),
        syncService: MockSyncService(),
      ),
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('online read populates the HTTP cache and returns data', () async {
    adapter
      ..mode = _Mode.online
      ..body = _single(_availability(teacherId: 'online-1'));

    final result = await repo.getAvailability('online-1');

    expect(result?.teacherId, equals('online-1'));
    expect(
      box.get('GET /schedule/availability/online-1'),
      isNotNull,
      reason: 'cached by interceptor',
    );
  });

  test(
    'offline read after a prior online read returns cached availability',
    () async {
      // Prime online.
      adapter
        ..mode = _Mode.online
        ..body = _single(_availability(teacherId: 'last-known-good'));
      await repo.getAvailability('last-known-good');

      // Go offline — no SyncAware cache exists; HTTP interceptor must serve.
      adapter.mode = _Mode.offline;
      final offline = await repo.getAvailability('last-known-good');

      expect(offline?.teacherId, equals('last-known-good'));
    },
  );

  test(
    'offline read with no prior cache propagates the network error',
    () async {
      adapter.mode = _Mode.offline;
      expect(
        () => repo.getAvailability('teacher-x'),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
