"""#1142 — beta mock SMS 분기의 OTP 로깅 게이트 테스트.

beta(SMS_USE_MOCK=true)에서는 실제 SMS 가 발송되지 않아 QA 가 코드를 받을 수 없다.
SMS_MOCK_LOG_CODES 플래그가 켜졌을 때만 mock 분기가 발급 코드를 서버 로그에 남긴다.

커버리지:
1. 플래그 ON  + mock  → 코드가 INFO 로그에 노출
2. 플래그 OFF + mock  → 코드가 로그에 없음 (기본값)
3. 실발송 경로 → 어떤 플래그 상태에서도 코드를 로그에 남기지 않음
"""

from __future__ import annotations

import logging

import pytest

from app.core.config import settings
from app.services.sms_service import SmsService

PHONE = "01012345678"
CODE = "483920"


class _FakeResponse:
    status_code = 200


class _FakeAsyncClient:
    """httpx.AsyncClient 대체 — 실발송 경로를 성공으로 흉내내되 네트워크 없이 동작."""

    def __init__(self, *args, **kwargs) -> None:  # noqa: D401 - test stub
        pass

    async def __aenter__(self) -> _FakeAsyncClient:
        return self

    async def __aexit__(self, *args) -> bool:
        return False

    async def post(self, *args, **kwargs) -> _FakeResponse:
        return _FakeResponse()


@pytest.mark.asyncio
async def test_mock_log_codes_on_logs_code(monkeypatch, caplog) -> None:
    monkeypatch.setattr(settings, "SMS_USE_MOCK", True)
    monkeypatch.setattr(settings, "SMS_MOCK_LOG_CODES", True)

    with caplog.at_level(logging.INFO, logger="app.services.sms_service"):
        result = await SmsService().send_otp(PHONE, CODE)

    assert result is True
    assert CODE in caplog.text
    # 전화번호는 마스킹되어 원본 전체가 로그에 남지 않는다.
    assert PHONE not in caplog.text
    assert "5678" in caplog.text  # 뒤 4자리는 유지


@pytest.mark.asyncio
async def test_mock_log_codes_off_hides_code(monkeypatch, caplog) -> None:
    monkeypatch.setattr(settings, "SMS_USE_MOCK", True)
    monkeypatch.setattr(settings, "SMS_MOCK_LOG_CODES", False)

    with caplog.at_level(logging.DEBUG, logger="app.services.sms_service"):
        result = await SmsService().send_otp(PHONE, CODE)

    assert result is True
    assert CODE not in caplog.text


@pytest.mark.asyncio
async def test_real_send_path_never_logs_code(monkeypatch, caplog) -> None:
    # 실발송 경로 (mock=False) 는 플래그가 켜져 있어도 코드를 로그에 남기지 않는다.
    monkeypatch.setattr(settings, "SMS_USE_MOCK", False)
    monkeypatch.setattr(settings, "SMS_MOCK_LOG_CODES", True)
    monkeypatch.setattr(settings, "SMS_API_KEY", "test-key")
    monkeypatch.setattr(settings, "SMS_API_SECRET", "test-secret")
    monkeypatch.setattr(settings, "SMS_SENDER_NUMBER", "01000000000")
    monkeypatch.setattr("app.services.sms_service.httpx.AsyncClient", _FakeAsyncClient)

    with caplog.at_level(logging.DEBUG, logger="app.services.sms_service"):
        result = await SmsService().send_otp(PHONE, CODE)

    assert result is True
    assert CODE not in caplog.text
