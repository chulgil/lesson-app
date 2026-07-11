import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Attaches a client-generated ``Idempotency-Key`` to mutating requests (#1117).
///
/// The whole point: a POST can reach the server and commit while the client's
/// response times out. If the client then replays the queued write without a
/// key the server creates a duplicate. Generating the key here — on the initial
/// Dio call — means the key exists *before* the first network attempt, and the
/// same key can be replayed (server dedupes).
///
/// The key is also stashed in `options.extra` so `ErrorInterceptor` can carry
/// it into the thrown exception; the mutation queue then persists that exact key
/// and re-attaches it on replay. On replay the adapter sets the header itself, so
/// this interceptor must NOT overwrite an existing header.
class IdempotencyInterceptor extends Interceptor {
  IdempotencyInterceptor({Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  static const String headerName = 'Idempotency-Key';
  static const String extraKey = 'idempotencyKey';

  static const Set<String> _mutatingMethods = {
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutatingMethods.contains(options.method.toUpperCase())) {
      final existing = options.headers[headerName];
      final key = (existing is String && existing.isNotEmpty)
          ? existing
          : _uuid.v4();
      options.headers[headerName] = key;
      options.extra[extraKey] = key;
    }
    handler.next(options);
  }
}
