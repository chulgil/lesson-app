import 'dart:io';

import 'package:dio/dio.dart';

import '../api_exceptions.dart';

/// Interceptor that converts Dio errors into typed [ApiException]s.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  ApiException _mapDioError(DioException err) {
    // Network / timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const NetworkException(message: '서버 응답 시간이 초과되었습니다.');
    }
    if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      return const NetworkException(message: '네트워크 연결을 확인해주세요.');
    }

    // HTTP status errors
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final detail = data is Map ? data['detail'] as String? : null;

    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          message: detail ?? '인증이 만료되었습니다. 다시 로그인해주세요.',
        );
      case 403:
        return ForbiddenException(message: detail ?? '접근 권한이 없습니다.');
      case 404:
        return NotFoundException(message: detail ?? '요청한 리소스를 찾을 수 없습니다.');
      case 422:
        return ValidationException(
          message: detail ?? '입력 데이터가 올바르지 않습니다.',
          errors: _parseValidationErrors(data),
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message: detail ?? '서버 오류가 발생했습니다.');
        }
        return ApiException(
          message: detail ?? err.message ?? '알 수 없는 오류가 발생했습니다.',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  Map<String, List<String>>? _parseValidationErrors(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is! List) return null;

    final errors = <String, List<String>>{};
    for (final item in detail) {
      if (item is Map) {
        final loc = item['loc'] as List?;
        final msg = item['msg'] as String?;
        if (loc != null && msg != null) {
          final field = loc.length > 1 ? loc.last.toString() : 'general';
          errors.putIfAbsent(field, () => []).add(msg);
        }
      }
    }
    return errors.isEmpty ? null : errors;
  }
}
