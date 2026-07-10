"""Solapi SMS sending service — #709.

단문 메시지 발송 전용. Mock 모드(기본)에서는 실제 HTTP 요청 없이 로그만 남긴다.
Mock 모드 ON/OFF는 설정(SMS_USE_MOCK)으로만 제어하며 코드에서 분기하지 않는다.

Solapi HMAC-SHA256 인증:
  - Authorization: HMAC-SHA256 apiKey=<key>, date=<ISO8601>, salt=<16hex>, signature=<sha256>
  - signature = HMAC-SHA256(apiSecret, "{date}{salt}") — 공식 문서 방식

보안 규칙:
  - 전화번호는 로그에서 마스킹 (앞 3자리 + *** + 뒤 4자리).
  - SMS_API_KEY / SMS_API_SECRET / SMS_SENDER_NUMBER 는 환경변수에서만 로드.
"""

from __future__ import annotations

import hashlib
import hmac
import logging
import secrets
from datetime import UTC, datetime

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_HTTP_TIMEOUT_SECONDS = 10


def _mask_phone(phone: str) -> str:
    """전화번호 마스킹: 010-****-1234 스타일."""
    digits = phone.replace("-", "").replace(" ", "")
    if len(digits) >= 7:
        return f"{digits[:3]}-****-{digits[-4:]}"
    return "***"


def _build_hmac_auth_header(api_key: str, api_secret: str) -> str:
    """Solapi HMAC-SHA256 Authorization 헤더 생성."""
    date = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%S.000Z")
    salt = secrets.token_hex(16)
    signature_input = f"{date}{salt}".encode()
    sig = hmac.new(api_secret.encode(), signature_input, hashlib.sha256).hexdigest()  # type: ignore[attr-defined]
    return f"HMAC-SHA256 apiKey={api_key}, date={date}, salt={salt}, signature={sig}"


class SmsService:
    """단문 SMS 발송 서비스.

    mock 모드(SMS_USE_MOCK=True)에서는 실제 발송 없이 DEBUG 로그만 남긴다.
    """

    async def send_otp(self, phone_number: str, code: str) -> bool:
        """OTP 코드를 전화번호로 발송.

        Returns:
            True  발송 성공 (mock 포함)
            False 발송 실패 (네트워크/API 오류)
        """
        if settings.SMS_USE_MOCK:
            if settings.SMS_MOCK_LOG_CODES:
                # Beta/QA only (#1142): no real SMS is sent in mock mode, so expose the
                # OTP in the server log for testers. Gated behind an opt-in flag; the
                # real-send path below never logs the code regardless of any flag.
                logger.info(
                    "[MOCK SMS] OTP for %s: %s",
                    _mask_phone(phone_number),
                    code,
                )
            else:
                logger.debug(
                    "SMS mock send OTP to %s (mock=True, code not logged)",
                    _mask_phone(phone_number),
                )
            return True

        if not settings.SMS_API_KEY or not settings.SMS_API_SECRET or not settings.SMS_SENDER_NUMBER:
            logger.error("SMS credentials not configured — SMS_USE_MOCK must be True in dev/CI")
            return False

        message = f"[레슨아자] 인증번호 [{code}]를 입력해주세요. (3분 내 유효)"
        payload = {
            "messages": [
                {
                    "to": phone_number,
                    "from": settings.SMS_SENDER_NUMBER,
                    "text": message,
                }
            ]
        }
        auth_header = _build_hmac_auth_header(settings.SMS_API_KEY, settings.SMS_API_SECRET)
        headers = {
            "Authorization": auth_header,
            "Content-Type": "application/json",
        }
        url = f"{settings.SMS_API_BASE_URL}/messages/v4/send-many/detail"

        try:
            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT_SECONDS) as client:
                response = await client.post(url, json=payload, headers=headers)
            if response.status_code >= 400:
                logger.error(
                    "SMS send failed status=%d phone=%s",
                    response.status_code,
                    _mask_phone(phone_number),
                )
                return False
            logger.info("SMS OTP sent phone=%s", _mask_phone(phone_number))
            return True
        except Exception:
            logger.exception("SMS send raised phone=%s", _mask_phone(phone_number))
            return False
