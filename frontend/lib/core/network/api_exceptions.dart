/// Base exception for all API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Network-level exception (no connectivity, timeout, etc.)
class NetworkException extends ApiException {
  const NetworkException({required super.message}) : super(statusCode: null);
}

/// Authentication error (401 after refresh attempt).
class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = '인증이 만료되었습니다. 다시 로그인해주세요.'})
    : super(statusCode: 401);
}

/// Forbidden error (403).
class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = '접근 권한이 없습니다.'})
    : super(statusCode: 403);
}

/// Not found error (404).
class NotFoundException extends ApiException {
  const NotFoundException({super.message = '요청한 리소스를 찾을 수 없습니다.'})
    : super(statusCode: 404);
}

/// Validation error (422).
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException({super.message = '입력 데이터가 올바르지 않습니다.', this.errors})
    : super(statusCode: 422);
}

/// Server error (500+).
class ServerException extends ApiException {
  const ServerException({super.message = '서버 오류가 발생했습니다.'})
    : super(statusCode: 500);
}
