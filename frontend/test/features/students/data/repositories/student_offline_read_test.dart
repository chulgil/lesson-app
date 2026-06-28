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
import 'package:lessonaza/features/students/data/repositories/remote_student_repository.dart';
import 'package:lessonaza/features/students/data/repositories/sync_aware_student_repository.dart';
import 'package:lessonaza/features/students/domain/entities/entities.dart';
import 'package:mocktail/mocktail.dart';

/// Batch 1c (일원화) end-to-end: the students stack — SyncAware (no own cache) →
/// Remote → ApiClient + ResponseCacheInterceptor — serves last-known-good data
/// offline via the single HTTP response cache (offline-first plan §3 / §5).

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

Student _student({String id = 's1'}) => Student(
  id: id,
  name: 'Test Student',
  instrument: 'violin',
  status: StudentStatus.active,
  createdAt: DateTime(2026, 5, 9),
);

String _paginated(List<Student> students) => jsonEncode({
  'items': students.map((s) => s.toJson()).toList(),
  'total': students.length,
  'page': 1,
  'size': students.length,
  'pages': 1,
});

void main() {
  late _FakeAdapter adapter;
  late Box<String> box;
  late SyncAwareStudentRepository repo;

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

    repo = SyncAwareStudentRepository(
      remote: RemoteStudentRepository(ApiClient(dio)),
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
      ..body = _paginated([_student(id: 'online-1')]);

    final result = await repo.getStudents();

    expect(result.map((s) => s.id), equals(['online-1']));
    expect(
      box.get('GET /students'),
      isNotNull,
      reason: 'cached by interceptor',
    );
  });

  test(
    'offline read after a prior online read returns cached students',
    () async {
      // Prime online.
      adapter
        ..mode = _Mode.online
        ..body = _paginated([_student(id: 'last-known-good')]);
      await repo.getStudents();

      // Go offline — no SyncAware cache exists; HTTP interceptor must serve.
      adapter.mode = _Mode.offline;
      final offline = await repo.getStudents();

      expect(offline.map((s) => s.id), equals(['last-known-good']));
    },
  );

  test(
    'offline read with no prior cache propagates the network error',
    () async {
      adapter.mode = _Mode.offline;
      expect(() => repo.getStudents(), throwsA(isA<ApiException>()));
    },
  );
}
