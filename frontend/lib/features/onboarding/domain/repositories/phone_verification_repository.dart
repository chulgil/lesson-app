/// Phone verification repository contract — #709.
///
/// OTP 코드는 서버에서 생성·해시 저장·서버 검증한다.
/// FE 는 결과만 신뢰한다 — 로컬 코드 비교 없음.
library;

/// 서버 검증 실패 사유. UI 레이어가 AppStrings 메시지로 매핑한다.
enum PhoneVerificationFailure {
  /// 60초 쿨다운 중 재요청 (서버 코드: otp_cooldown)
  cooldown,

  /// 번호당 일일 5회 한도 초과 (otp_daily_limit)
  dailyLimit,

  /// TTL 3분 만료 (otp_expired)
  expired,

  /// 검증 시도 5회 초과 (otp_attempts_exceeded)
  attemptsExceeded,

  /// 잘못된 코드 (otp_invalid)
  invalidCode,

  /// 발송된 코드 없음 (otp_not_found)
  codeNotFound,

  /// SMS 벤더 발송 실패 (sms_send_failed)
  sendFailed,

  /// 네트워크/기타 오류
  network,
}

/// request/verify 호출의 결과.
class PhoneVerificationResult {
  final bool success;
  final PhoneVerificationFailure? failure;

  /// otp_invalid 실패 시 서버가 알려준 남은 시도 횟수.
  final int? attemptsRemaining;

  /// otp_cooldown 실패 시 남은 쿨다운 (초).
  final int? cooldownSecondsRemaining;

  const PhoneVerificationResult.success()
    : success = true,
      failure = null,
      attemptsRemaining = null,
      cooldownSecondsRemaining = null;

  const PhoneVerificationResult.failed(
    this.failure, {
    this.attemptsRemaining,
    this.cooldownSecondsRemaining,
  }) : success = false;
}

/// 서버측 SMS OTP 전화인증 — request/verify 2 메서드.
abstract class PhoneVerificationRepository {
  /// POST /auth/phone/request-code — 6자리 OTP 발송 요청.
  Future<PhoneVerificationResult> requestCode(String phoneNumber);

  /// POST /auth/phone/verify-code — 서버 검증. 성공 시 서버가
  /// teacher.is_phone_verified=true 를 세팅한다 (클라이언트 쓰기 불가).
  Future<PhoneVerificationResult> verifyCode(String phoneNumber, String code);
}
