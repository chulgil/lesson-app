import 'dart:io';

import 'package:dio/dio.dart';

import '../api_exceptions.dart';
import 'idempotency_interceptor.dart';

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
    // #1117: the key the IdempotencyInterceptor attached to this attempt. Carried
    // into queue-fallback exceptions so the replay reuses the exact same key.
    final idempotencyKey =
        err.requestOptions.extra[IdempotencyInterceptor.extraKey] as String?;

    // Network / timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message: '서버 응답 시간이 초과되었습니다.',
        idempotencyKey: idempotencyKey,
      );
    }
    if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      return NetworkException(
        message: '네트워크 연결을 확인해주세요.',
        idempotencyKey: idempotencyKey,
      );
    }

    // HTTP status errors
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    // #709: detail 이 String 이 아닌 dict 인 응답(OTP 쿨다운/시도초과 등)에서
    // `as String?` 캐스트가 TypeError 로 크래시하지 않도록 타입 가드.
    final detailRaw = data is Map ? data['detail'] : null;
    final detail = detailRaw is String ? detailRaw : null;
    // #430: backend AppException handler wraps payload as
    // ``{"error": {"code": ..., "detail": ...}}`` — read both shapes.
    final errorBlock = data is Map ? data['error'] : null;
    final errorCode = errorBlock is Map ? errorBlock['code'] as String? : null;
    final errorDetail = errorBlock is Map
        ? errorBlock['detail'] as String?
        : null;

    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          message: detail ?? errorDetail ?? '인증이 만료되었습니다. 다시 로그인해주세요.',
        );
      case 403:
        return ForbiddenException(
          message: detail ?? errorDetail ?? '접근 권한이 없습니다.',
        );
      case 404:
        return NotFoundException(
          message: detail ?? errorDetail ?? '요청한 리소스를 찾을 수 없습니다.',
        );
      case 409:
        if (errorCode == 'phone_verification_required') {
          return PhoneVerificationRequiredException(
            message: errorDetail ?? detail ?? '수강권 발급에는 전화인증이 필요해요',
          );
        }
        return ApiException(
          message: detail ?? errorDetail ?? '요청이 충돌했습니다.',
          statusCode: statusCode,
          data: data,
        );
      case 422:
        return ValidationException(
          message: detail ?? errorDetail ?? '입력 데이터가 올바르지 않습니다.',
          errors: _parseValidationErrors(data),
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: detail ?? '서버 오류가 발생했습니다.',
            idempotencyKey: idempotencyKey,
          );
        }
        return ApiException(
          message: detail ?? err.message ?? '알 수 없는 오류가 발생했습니다.',
          statusCode: statusCode,
          data: data,
          idempotencyKey: idempotencyKey,
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
