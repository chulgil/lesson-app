import 'dart:developer' as developer;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/repositories/phone_verification_repository.dart';

/// Remote implementation of [PhoneVerificationRepository] — #709.
///
/// Endpoints (인증된 선생님 본인 계정에 귀속):
/// - POST /auth/phone/request-code
/// - POST /auth/phone/verify-code
class RemotePhoneVerificationRepository implements PhoneVerificationRepository {
  final ApiClient _apiClient;

  RemotePhoneVerificationRepository(this._apiClient);

  @override
  Future<PhoneVerificationResult> requestCode(String phoneNumber) async {
    try {
      await _apiClient.post(
        '/auth/phone/request-code',
        data: {'phone_number': phoneNumber},
      );
      return const PhoneVerificationResult.success();
    } on ApiException catch (e) {
      developer.log('[PhoneVerification] requestCode failed: ${e.statusCode}');
      return _mapFailure(e);
    }
  }

  @override
  Future<PhoneVerificationResult> verifyCode(
    String phoneNumber,
    String code,
  ) async {
    try {
      await _apiClient.post(
        '/auth/phone/verify-code',
        data: {'phone_number': phoneNumber, 'code': code},
      );
      return const PhoneVerificationResult.success();
    } on ApiException catch (e) {
      developer.log('[PhoneVerification] verifyCode failed: ${e.statusCode}');
      return _mapFailure(e);
    }
  }

  /// 서버 detail.code → [PhoneVerificationFailure] 매핑.
  PhoneVerificationResult _mapFailure(ApiException e) {
    if (e is NetworkException) {
      return const PhoneVerificationResult.failed(
        PhoneVerificationFailure.network,
      );
    }

    final data = e.data;
    final detail = data is Map ? data['detail'] : null;
    final code = detail is Map ? detail['code'] as String? : null;

    switch (code) {
      case 'otp_cooldown':
        final remaining =
            detail is Map ? detail['cooldown_seconds_remaining'] as int? : null;
        return PhoneVerificationResult.failed(
          PhoneVerificationFailure.cooldown,
          cooldownSecondsRemaining: remaining,
        );
      case 'otp_daily_limit':
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.dailyLimit,
        );
      case 'otp_expired':
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.expired,
        );
      case 'otp_attempts_exceeded':
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.attemptsExceeded,
        );
      case 'otp_invalid':
        final remaining =
            detail is Map ? detail['attempts_remaining'] as int? : null;
        return PhoneVerificationResult.failed(
          PhoneVerificationFailure.invalidCode,
          attemptsRemaining: remaining,
        );
      case 'otp_not_found':
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.codeNotFound,
        );
      case 'sms_send_failed':
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.sendFailed,
        );
      default:
        return const PhoneVerificationResult.failed(
          PhoneVerificationFailure.network,
        );
    }
  }
}
