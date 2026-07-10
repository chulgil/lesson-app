import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/network/interceptors/error_interceptor.dart';
import 'package:lessonaza/core/network/interceptors/idempotency_interceptor.dart';

class _CaptureHandler extends RequestInterceptorHandler {
  RequestOptions? captured;
  @override
  void next(RequestOptions options) => captured = options;
}

class _CaptureErrorHandler extends ErrorInterceptorHandler {
  DioException? captured;
  @override
  void next(DioException err) => captured = err;
}

void main() {
  final interceptor = IdempotencyInterceptor();

  RequestOptions run(String method, {Map<String, dynamic>? headers}) {
    final handler = _CaptureHandler();
    interceptor.onRequest(
      RequestOptions(path: '/lessons', method: method, headers: headers ?? {}),
      handler,
    );
    return handler.captured!;
  }

  group('IdempotencyInterceptor.onRequest (#1117)', () {
    test('POST gets a key header + extra', () {
      final options = run('POST');
      final header = options.headers[IdempotencyInterceptor.headerName];
      expect(header, isA<String>());
      expect(header, isNotEmpty);
      expect(options.extra[IdempotencyInterceptor.extraKey], equals(header));
    });

    for (final method in ['PUT', 'PATCH', 'DELETE']) {
      test('$method also gets a key', () {
        final options = run(method);
        expect(options.headers[IdempotencyInterceptor.headerName], isNotEmpty);
      });
    }

    test('GET is left untouched', () {
      final options = run('GET');
      expect(
        options.headers.containsKey(IdempotencyInterceptor.headerName),
        isFalse,
      );
      expect(
        options.extra.containsKey(IdempotencyInterceptor.extraKey),
        isFalse,
      );
    });

    test('existing header (replay path) is not overwritten', () {
      final options = run(
        'POST',
        headers: {IdempotencyInterceptor.headerName: 'replay-key'},
      );
      expect(
        options.headers[IdempotencyInterceptor.headerName],
        equals('replay-key'),
      );
      expect(
        options.extra[IdempotencyInterceptor.extraKey],
        equals('replay-key'),
      );
    });
  });

  group('ErrorInterceptor carries the key (#1117)', () {
    ApiException mapTimeout({String? key}) {
      final handler = _CaptureErrorHandler();
      ErrorInterceptor().onError(
        DioException(
          requestOptions: RequestOptions(
            path: '/lessons',
            extra: {if (key != null) IdempotencyInterceptor.extraKey: key},
          ),
          type: DioExceptionType.receiveTimeout,
        ),
        handler,
      );
      return handler.captured!.error as ApiException;
    }

    test('receiveTimeout → NetworkException carries the key from extra', () {
      final ex = mapTimeout(key: 'attempt-key');
      expect(ex, isA<NetworkException>());
      expect(ex.idempotencyKey, equals('attempt-key'));
    });

    test('no key in extra → idempotencyKey is null', () {
      final ex = mapTimeout();
      expect(ex.idempotencyKey, isNull);
    });
  });
}
