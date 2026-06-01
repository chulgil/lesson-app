"""Kakao alimtalk vendor client — #423.

The carrier behind the alimtalk gateway (e.g. Aligo, Solomon, Kakao Biz) is
abstracted behind the `AlimTalkClient` protocol so the rest of the codebase can
treat alimtalk sending as a value-typed operation.

`MockAlimTalkClient` is used in tests and in dev when the vendor account is not
yet provisioned. The real `KakaoAlimTalkClient` is intentionally a stub until
the business onboarding (#423 외부 선행 작업) ships.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable

logger = logging.getLogger(__name__)


@dataclass
class AlimTalkResult:
    success: bool
    message_id: str | None = None
    error: str | None = None
    # Provider-specific raw response — useful for ops triage. Not stored verbatim.
    raw: dict | None = None


@runtime_checkable
class AlimTalkClient(Protocol):
    """Send one alimtalk message and return a structured result."""

    async def send(
        self,
        *,
        template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkResult: ...


@dataclass
class MockAlimTalkClient:
    """Used by tests and by dev when the carrier API key is not set.

    Captures every send into `sent` so tests can assert what would have gone out.
    `next_failure` flips the next call into a failure so fallback paths can be
    exercised without monkey-patching.
    """

    sent: list[tuple[str, str, dict[str, str]]] = field(default_factory=list)
    next_failure: bool = False
    next_error: str = "mock failure"

    async def send(
        self,
        *,
        template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkResult:
        if self.next_failure:
            self.next_failure = False
            return AlimTalkResult(success=False, error=self.next_error)
        self.sent.append((template_id, recipient_phone, variables))
        return AlimTalkResult(success=True, message_id=f"mock-{len(self.sent)}")


class KakaoAlimTalkClient:
    """Real Kakao alimtalk vendor client.

    Stubbed until business onboarding (#423 §3 외부 선행) finishes.
    Code path is structurally complete so the wiring can be exercised, but the
    HTTP call is replaced with a log-and-fail until credentials land in env.
    """

    def __init__(self, *, api_base_url: str, api_key: str, sender_profile: str) -> None:
        self._api_base_url = api_base_url
        self._api_key = api_key
        self._sender_profile = sender_profile

    async def send(
        self,
        *,
        template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkResult:
        # TODO(#423): HTTP POST to vendor once onboarding completes.
        logger.warning(
            "KakaoAlimTalkClient called before vendor onboarding completed: template=%s",
            template_id,
        )
        return AlimTalkResult(
            success=False,
            error="vendor onboarding pending; use MockAlimTalkClient until ready",
        )
