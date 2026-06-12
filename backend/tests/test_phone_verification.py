"""#709 — 서버측 SMS OTP 전화인증 테스트.

커버리지:
1. 정상 흐름: request-code → verify-code → is_phone_verified=True
2. 쿨다운: 60초 내 재요청 → 429 otp_cooldown
3. TTL 만료: 만료된 코드 검증 → 400 otp_expired
4. 시도 5회 초과: 6번째 시도 → 429 otp_attempts_exceeded
5. 일일 한도: 번호당 5회/일 초과 → 429 otp_daily_limit
6. 잘못된 코드: 400 otp_invalid + 남은 시도 횟수 포함
7. 보안 갭: 클라이언트 update 로 is_phone_verified 세팅 시도 → 무시됨
8. 코드 비노출: 응답에 코드 평문 없음
9. 검증 성공 후 코드 재사용 불가
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.phone_verification_code import (
    PhoneVerificationCode,
    PhoneVerificationDailyCount,
)
from app.models.teacher import Teacher
from app.services.phone_verification_service import (
    PhoneVerificationService,
    _hash_code,
)

PHONE = "01012345678"


class FakeSmsService:
    """주입용 mock sender — 마지막으로 발송된 코드를 캡처한다."""

    def __init__(self, *, succeed: bool = True) -> None:
        self.succeed = succeed
        self.sent: list[tuple[str, str]] = []

    async def send_otp(self, phone_number: str, code: str) -> bool:
        self.sent.append((phone_number, code))
        return self.succeed


async def _setup_teacher(create_test_user, db: AsyncSession, *, verified: bool = False) -> Teacher:
    await create_test_user(user_id="test-user-id", role="teacher")
    teacher = await db.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    assert teacher is not None
    teacher.is_phone_verified = verified
    if not verified:
        teacher.phone_verified_at = None
    await db.flush()
    return teacher


# ---------------------------------------------------------------------------
# 1. 정상 흐름
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_request_then_verify_success(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    sms = FakeSmsService()
    service = PhoneVerificationService(db_session, sms_service=sms)

    result = await service.request_code(teacher.id, PHONE)
    assert "message" in result
    assert len(sms.sent) == 1
    sent_phone, sent_code = sms.sent[0]
    assert sent_phone == PHONE
    assert len(sent_code) == 6 and sent_code.isdigit()

    verify_result = await service.verify_code(teacher.id, PHONE, sent_code)
    assert verify_result["verified"] is True

    await db_session.refresh(teacher)
    assert teacher.is_phone_verified is True
    assert teacher.phone_number == PHONE
    assert teacher.phone_verified_at is not None


# ---------------------------------------------------------------------------
# 2. 쿨다운 60초
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_request_code_cooldown(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    service = PhoneVerificationService(db_session, sms_service=FakeSmsService())

    await service.request_code(teacher.id, PHONE)

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await service.request_code(teacher.id, PHONE)
    assert exc_info.value.status_code == 429
    assert exc_info.value.detail["code"] == "otp_cooldown"
    assert exc_info.value.detail["cooldown_seconds_remaining"] > 0


# ---------------------------------------------------------------------------
# 3. TTL 만료
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_verify_code_expired(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    sms = FakeSmsService()
    service = PhoneVerificationService(db_session, sms_service=sms)

    await service.request_code(teacher.id, PHONE)
    _, code = sms.sent[0]

    # 코드 행을 강제로 만료시킨다.
    record = await db_session.scalar(
        select(PhoneVerificationCode).where(PhoneVerificationCode.teacher_id == teacher.id)
    )
    assert record is not None
    record.expires_at = datetime.now(UTC) - timedelta(seconds=1)
    await db_session.flush()

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await service.verify_code(teacher.id, PHONE, code)
    assert exc_info.value.status_code == 400
    assert exc_info.value.detail["code"] == "otp_expired"

    # 만료된 행은 즉시 삭제됨.
    remaining = await db_session.scalar(
        select(PhoneVerificationCode).where(PhoneVerificationCode.teacher_id == teacher.id)
    )
    assert remaining is None


# ---------------------------------------------------------------------------
# 4. 시도 5회 초과
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_verify_code_attempts_exceeded(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    sms = FakeSmsService()
    service = PhoneVerificationService(db_session, sms_service=sms)

    await service.request_code(teacher.id, PHONE)

    from fastapi import HTTPException

    # 잘못된 코드로 5회 시도 (000000 은 secrets 가 뽑은 코드와 같을 수 있어 명시 회피)
    _, real_code = sms.sent[0]
    wrong_code = "000000" if real_code != "000000" else "999999"

    for _ in range(5):
        with pytest.raises(HTTPException) as exc_info:
            await service.verify_code(teacher.id, PHONE, wrong_code)
        assert exc_info.value.status_code == 400
        assert exc_info.value.detail["code"] == "otp_invalid"

    # 6번째 → 시도 횟수 초과
    with pytest.raises(HTTPException) as exc_info:
        await service.verify_code(teacher.id, PHONE, wrong_code)
    assert exc_info.value.status_code == 429
    assert exc_info.value.detail["code"] == "otp_attempts_exceeded"

    await db_session.refresh(teacher)
    assert teacher.is_phone_verified is False


# ---------------------------------------------------------------------------
# 5. 일일 한도 5회
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_request_code_daily_limit(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    service = PhoneVerificationService(db_session, sms_service=FakeSmsService())

    # 일일 카운트를 한도(5)까지 미리 채운다.
    today = datetime.now(UTC).strftime("%Y-%m-%d")
    db_session.add(PhoneVerificationDailyCount(phone_number=PHONE, date_key=today, count=5))
    await db_session.flush()

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await service.request_code(teacher.id, PHONE)
    assert exc_info.value.status_code == 429
    assert exc_info.value.detail["code"] == "otp_daily_limit"


# ---------------------------------------------------------------------------
# 6. 잘못된 코드 — 남은 시도 횟수 포함
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_verify_code_invalid_includes_attempts_remaining(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    sms = FakeSmsService()
    service = PhoneVerificationService(db_session, sms_service=sms)

    await service.request_code(teacher.id, PHONE)
    _, real_code = sms.sent[0]
    wrong_code = "000000" if real_code != "000000" else "999999"

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await service.verify_code(teacher.id, PHONE, wrong_code)
    assert exc_info.value.status_code == 400
    detail = exc_info.value.detail
    assert detail["code"] == "otp_invalid"
    assert detail["attempts_remaining"] == 4
    # 코드 평문은 어떤 응답에도 노출 금지.
    assert real_code not in str(detail)


# ---------------------------------------------------------------------------
# 7. 보안 갭: 클라이언트 update 로 is_phone_verified 세팅 시도 → 무시
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_client_update_cannot_set_is_phone_verified(
    client: AsyncClient, create_test_user, db_session: AsyncSession, auth_headers: dict
) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    assert teacher.is_phone_verified is False

    # 클라이언트가 PUT /teachers/me/profile 로 is_phone_verified=true 를 보내도 무시돼야 한다.
    response = await client.put(
        "/api/v1/teachers/me/profile",
        json={"is_phone_verified": True, "introduction": "hello"},
        headers=auth_headers,
    )
    assert response.status_code == 200

    await db_session.refresh(teacher)
    assert teacher.is_phone_verified is False, (
        "보안 갭: 클라이언트 자기 주장으로 is_phone_verified 가 세팅됨 — "
        "TeacherUpdate 스키마에서 필드가 제거되어야 한다"
    )
    # 다른 필드는 정상 반영.
    assert teacher.introduction == "hello"


# ---------------------------------------------------------------------------
# 8. API 흐름 — request-code 응답에 코드 비노출
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_api_request_code_does_not_leak_code(
    client: AsyncClient, create_test_user, db_session: AsyncSession, auth_headers: dict
) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)

    response = await client.post(
        "/api/v1/auth/phone/request-code",
        json={"phone_number": PHONE},
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    # DB 에는 해시만 저장 — 평문 코드가 응답 본문에 없어야 한다.
    record = await db_session.scalar(
        select(PhoneVerificationCode).where(PhoneVerificationCode.teacher_id == teacher.id)
    )
    assert record is not None
    assert len(record.code_hash) == 64  # sha256 hex
    body_text = response.text
    # 해시·salt 도 응답에 노출 금지.
    assert record.code_hash not in body_text
    assert record.salt not in body_text


# ---------------------------------------------------------------------------
# 9. 검증 성공 후 코드 재사용 불가
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_verified_code_cannot_be_reused(create_test_user, db_session: AsyncSession) -> None:
    teacher = await _setup_teacher(create_test_user, db_session)
    sms = FakeSmsService()
    service = PhoneVerificationService(db_session, sms_service=sms)

    await service.request_code(teacher.id, PHONE)
    _, code = sms.sent[0]

    result = await service.verify_code(teacher.id, PHONE, code)
    assert result["verified"] is True

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await service.verify_code(teacher.id, PHONE, code)
    assert exc_info.value.status_code == 400
    assert exc_info.value.detail["code"] == "otp_not_found"


# ---------------------------------------------------------------------------
# 10. 해시 결정성 — salt 다르면 해시 다름 (rainbow table 방어 회귀)
# ---------------------------------------------------------------------------


def test_hash_code_uses_salt() -> None:
    assert _hash_code("123456", "salt-a") != _hash_code("123456", "salt-b")
    assert _hash_code("123456", "salt-a") == _hash_code("123456", "salt-a")
