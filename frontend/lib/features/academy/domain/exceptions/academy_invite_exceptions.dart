/// audit C3-F03: 학원 초대 에러를 명시적 타입으로 분류한다.
///
/// 종래 `AcademyInviteAcceptScreen._errorCodeFor` 는 `error.toString()` 의
/// 문자열 매칭(`contains('expired')` 등) 으로 분기했다. BE 응답 detail 이
/// 한 글자만 바뀌어도 분기가 깨지는 약한 결합이라, type-check 기반으로
/// 안정화한다.
///
/// Remote/Mock repository 가 동일 타입을 throw 하고, 화면은 `error is X`
/// 패턴으로 분기한다. `debugMessage` 는 로그/toString 전용 디버그 문자열이며
/// UI 표시 문자열이 아니다 (UI 매핑은 presentation 에서 type 기준 수행).
sealed class AcademyInviteException implements Exception {
  final String debugMessage;

  const AcademyInviteException(this.debugMessage);

  @override
  String toString() => 'AcademyInviteException: $debugMessage';
}

/// 토큰이 만료되었거나 일정 기간이 지나 더 이상 유효하지 않음.
/// BE: 409 + detail contains "expired" / preview 의 is_expired:true.
class AcademyInviteExpiredException extends AcademyInviteException {
  const AcademyInviteExpiredException([
    super.debugMessage = 'Invite token expired',
  ]);
}

/// 토큰이 이미 사용되었거나 (수락/거절) 회수(revoked) 됨.
/// BE: 409 + detail contains "accepted" / "declined" / "revoked".
class AcademyInviteAlreadyUsedException extends AcademyInviteException {
  const AcademyInviteAlreadyUsedException([
    super.debugMessage = 'Invite token already used',
  ]);
}

/// 토큰 자체가 존재하지 않음 (오탈자 또는 삭제된 학원).
/// BE: 404.
class AcademyInviteNotFoundException extends AcademyInviteException {
  const AcademyInviteNotFoundException([
    super.debugMessage = 'Invite token not found',
  ]);
}
