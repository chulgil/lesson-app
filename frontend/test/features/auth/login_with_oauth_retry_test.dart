import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';

/// Retry policy contract for [AuthNotifier.loginWithOAuth].
///
/// 일시 네트워크 장애는 재시도하고 클라이언트 오류는 즉시 종료해야
/// "구글 로그인 후 잠깐의 네트워크 끊김으로 SnackBar만 뜨고 화면이
/// 그대로 멈추는" 회귀(#676 후속)를 방지한다.
void main() {
  group('isRetryableApiError — transient failures', () {
    test('network error (no status code) is retryable', () {
      expect(
        isRetryableApiError(const NetworkException(message: 'no connection')),
        isTrue,
      );
    });

    test('base ApiException with null status is retryable', () {
      expect(
        isRetryableApiError(const ApiException(message: 'unknown')),
        isTrue,
      );
    });

    test('500 internal server error is retryable', () {
      expect(isRetryableApiError(const ServerException()), isTrue);
    });

    test('502 / 503 / 504 gateway errors are retryable', () {
      expect(
        isRetryableApiError(
          const ApiException(message: 'bad gateway', statusCode: 502),
        ),
        isTrue,
      );
      expect(
        isRetryableApiError(
          const ApiException(message: 'unavailable', statusCode: 503),
        ),
        isTrue,
      );
      expect(
        isRetryableApiError(
          const ApiException(message: 'gateway timeout', statusCode: 504),
        ),
        isTrue,
      );
    });
  });

  group('isRetryableApiError — client errors stop immediately', () {
    test('401 unauthorized is not retryable', () {
      expect(isRetryableApiError(const UnauthorizedException()), isFalse);
    });

    test('403 forbidden is not retryable', () {
      expect(isRetryableApiError(const ForbiddenException()), isFalse);
    });

    test('404 not found is not retryable', () {
      expect(isRetryableApiError(const NotFoundException()), isFalse);
    });

    test('422 validation error is not retryable', () {
      expect(isRetryableApiError(const ValidationException()), isFalse);
    });

    test('400 bad request is not retryable', () {
      expect(
        isRetryableApiError(
          const ApiException(message: 'bad request', statusCode: 400),
        ),
        isFalse,
      );
    });

    test('409 conflict (e.g. PhoneVerificationRequired) is not retryable', () {
      expect(
        isRetryableApiError(const PhoneVerificationRequiredException()),
        isFalse,
      );
    });
  });
}
