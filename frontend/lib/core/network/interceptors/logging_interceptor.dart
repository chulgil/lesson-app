import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that logs HTTP requests/responses in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log('→ ${options.method} ${options.uri}', name: 'HTTP');
      if (options.data != null) {
        developer.log('  Body: ${options.data}', name: 'HTTP');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        name: 'HTTP',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✗ ${err.response?.statusCode ?? 'ERR'} ${err.requestOptions.uri}: ${err.message}',
        name: 'HTTP',
        level: 900,
      );
    }
    handler.next(err);
  }
}
