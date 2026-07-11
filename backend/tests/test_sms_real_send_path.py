"""#1179 — Solapi 실발송 경로 하드닝 테스트.

Solapi ``/messages/v4/send-many/detail`` 은 개별 메시지 등록 실패여도
HTTP 200 + ``failedMessageList`` 로 응답한다. 200 만 보고 성공 처리하면
문자가 안 갔는데 사용자에게 "발송했어요" 를 반환하는 유령 성공이 된다.

또한 production-like 환경에서 SMS_USE_MOCK=false 인데 자격증명이 비어
있으면 부팅 시점에 거부해야 한다 (런타임 전건 502 방지).
"""

from __future__ import annotations

import logging

import pytest

from app.core.config import settings, validate_runtime_configuration
from app.services.sms_service import SmsService

PHONE = "01012345678"
CODE = "483920"


class _FakeResponse:
    def __init__(self, status_code=200, body=None, raise_on_json=False):
        self.status_code = status_code
        self._body = body if body is not None else {"failedMessageList": []}
        self._raise_on_json = raise_on_json

    def json(self):
        if self._raise_on_json:
            raise ValueError("not json")
        return self._body


def _fake_client_returning(response: _FakeResponse):
    class _FakeAsyncClient:
        def __init__(self, *args, **kwargs) -> None:
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args) -> bool:
            return False

        async def post(self, *args, **kwargs):
            return response

    return _FakeAsyncClient


def _set_real_send(monkeypatch) -> None:
    monkeypatch.setattr(settings, "SMS_USE_MOCK", False)
    monkeypatch.setattr(settings, "SMS_API_KEY", "test-key")
    monkeypatch.setattr(settings, "SMS_API_SECRET", "test-secret")
    monkeypatch.setattr(settings, "SMS_SENDER_NUMBER", "01000000000")


@pytest.mark.asyncio
async def test_http_200_with_failed_message_returns_false(monkeypatch, caplog) -> None:
    """등록 실패가 failedMessageList 로 오면 200 이어도 실패로 처리한다."""
    _set_real_send(monkeypatch)
    response = _FakeResponse(
        body={"failedMessageList": [{"to": PHONE, "statusMessage": "발신번호 미등록", "errorCode": "ValidationError"}]}
    )
    monkeypatch.setattr("app.services.sms_service.httpx.AsyncClient", _fake_client_returning(response))

    with caplog.at_level(logging.DEBUG, logger="app.services.sms_service"):
        result = await SmsService().send_otp(PHONE, CODE)

    assert result is False
    assert "발신번호 미등록" in caplog.text or "ValidationError" in caplog.text
    # 실패 로그에도 OTP 코드·원본 전화번호는 남지 않는다.
    assert CODE not in caplog.text
    assert PHONE not in caplog.text


@pytest.mark.asyncio
async def test_http_200_with_empty_failed_list_returns_true(monkeypatch) -> None:
    _set_real_send(monkeypatch)
    monkeypatch.setattr(
        "app.services.sms_service.httpx.AsyncClient",
        _fake_client_returning(_FakeResponse(body={"groupInfo": {}, "failedMessageList": []})),
    )

    assert await SmsService().send_otp(PHONE, CODE) is True


@pytest.mark.asyncio
async def test_http_200_with_unparseable_body_trusts_status(monkeypatch, caplog) -> None:
    """비정상 body 는 경고만 남기고 200 상태를 신뢰한다 (재시도 폭주 방지)."""
    _set_real_send(monkeypatch)
    monkeypatch.setattr(
        "app.services.sms_service.httpx.AsyncClient",
        _fake_client_returning(_FakeResponse(raise_on_json=True)),
    )

    with caplog.at_level(logging.WARNING, logger="app.services.sms_service"):
        result = await SmsService().send_otp(PHONE, CODE)

    assert result is True


@pytest.mark.asyncio
async def test_http_4xx_returns_false(monkeypatch) -> None:
    _set_real_send(monkeypatch)
    monkeypatch.setattr(
        "app.services.sms_service.httpx.AsyncClient",
        _fake_client_returning(_FakeResponse(status_code=401, body={})),
    )

    assert await SmsService().send_otp(PHONE, CODE) is False


@pytest.mark.asyncio
async def test_missing_credentials_returns_false(monkeypatch) -> None:
    monkeypatch.setattr(settings, "SMS_USE_MOCK", False)
    monkeypatch.setattr(settings, "SMS_API_KEY", "")
    monkeypatch.setattr(settings, "SMS_API_SECRET", "")
    monkeypatch.setattr(settings, "SMS_SENDER_NUMBER", "")

    assert await SmsService().send_otp(PHONE, CODE) is False


# ---------------------------------------------------------------------------
# Boot-time guard — production-like + real send requires credentials
# ---------------------------------------------------------------------------


def _set_valid_production_base(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "beta")
    monkeypatch.setattr(settings, "DEBUG", False)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["https://lessonaza.app"])


def test_runtime_config_rejects_real_sms_without_credentials(monkeypatch) -> None:
    _set_valid_production_base(monkeypatch)
    monkeypatch.setattr(settings, "SMS_USE_MOCK", False)
    monkeypatch.setattr(settings, "SMS_API_KEY", "")
    monkeypatch.setattr(settings, "SMS_API_SECRET", "")
    monkeypatch.setattr(settings, "SMS_SENDER_NUMBER", "")

    with pytest.raises(RuntimeError, match="SMS"):
        validate_runtime_configuration()


def test_runtime_config_allows_real_sms_with_credentials(monkeypatch) -> None:
    _set_valid_production_base(monkeypatch)
    monkeypatch.setattr(settings, "SMS_USE_MOCK", False)
    monkeypatch.setattr(settings, "SMS_API_KEY", "real-key")
    monkeypatch.setattr(settings, "SMS_API_SECRET", "real-secret")
    monkeypatch.setattr(settings, "SMS_SENDER_NUMBER", "0212345678")

    validate_runtime_configuration()


def test_runtime_config_allows_mock_without_credentials(monkeypatch) -> None:
    """mock 모드(현 beta 상태)는 자격증명 없이 부팅 가능해야 한다."""
    _set_valid_production_base(monkeypatch)
    monkeypatch.setattr(settings, "SMS_USE_MOCK", True)
    monkeypatch.setattr(settings, "SMS_API_KEY", "")

    validate_runtime_configuration()
