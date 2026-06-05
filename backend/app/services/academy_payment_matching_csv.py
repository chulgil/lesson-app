"""CSV import parser for bank transactions — AC-M3 §5.1.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.1.

목적: 한국 학원장이 매월 통장 CSV 를 한 번에 업로드 → 수기 입력 N번을 1번으로 압축.

설계:
- 한글/영문 헤더 모두 지원 (KB, 신한, 카뱅, 토스 일부 + 표준 형식).
- 행별 graceful 처리 — 1행 잘못이어도 나머지는 처리. ``error_rows`` 로 분리 보고.
- 표준 ``AcademyBankTransaction`` 필드로 정규화 후 반환. 저장은 service 책임.

비범위:
- 은행별 어댑터 (KB/신한 raw 포맷별 변환) — 학원장이 사전 변환 또는 추후 라운드.
- 인코딩 자동 감지 — endpoint 가 BOM 포함 utf-8 디코드 책임.
"""

from __future__ import annotations

import csv
from datetime import UTC, datetime
from io import StringIO
from typing import TypedDict


class ParsedRow(TypedDict, total=False):
    """파싱 완료된 행 — service 가 ``AcademyBankTransaction`` 으로 변환할 값들."""

    tx_at: datetime
    depositor_raw: str
    amount: int
    memo_raw: str | None
    bank_name: str | None
    source_ref: str  # "row:{n}" — CSV 행번호 audit


class ErrorRow(TypedDict):
    row_number: int  # CSV 데이터 행 번호 (헤더=1, 첫 데이터=2)
    reason: str


# 한국 은행 CSV 헤더 매핑 — 흔히 보는 변형 흡수.
_HEADER_ALIASES: dict[str, str] = {
    # tx_at
    "거래일시": "tx_at",
    "거래일자": "tx_at",
    "입금일시": "tx_at",
    "입금일자": "tx_at",
    "입금일": "tx_at",
    "tx_at": "tx_at",
    "txat": "tx_at",
    "date": "tx_at",
    "datetime": "tx_at",
    # depositor_raw
    "입금자명": "depositor_raw",
    "입금자": "depositor_raw",
    "보내신분": "depositor_raw",
    "보낸분": "depositor_raw",
    "송금인": "depositor_raw",
    "depositor": "depositor_raw",
    "depositor_raw": "depositor_raw",
    "sender": "depositor_raw",
    # amount
    "금액": "amount",
    "입금액": "amount",
    "거래금액": "amount",
    "amount": "amount",
    # memo_raw
    "메모": "memo_raw",
    "내용": "memo_raw",
    "적요": "memo_raw",
    "memo": "memo_raw",
    "memo_raw": "memo_raw",
    "note": "memo_raw",
    # bank_name
    "은행": "bank_name",
    "은행명": "bank_name",
    "bank": "bank_name",
    "bank_name": "bank_name",
}

# 지원 날짜 포맷 — 한국 은행 CSV 에서 자주 등장하는 형태.
_DATETIME_FORMATS: tuple[str, ...] = (
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d",
    "%Y/%m/%d %H:%M:%S",
    "%Y/%m/%d %H:%M",
    "%Y/%m/%d",
    "%Y.%m.%d %H:%M:%S",
    "%Y.%m.%d %H:%M",
    "%Y.%m.%d",
)


def _parse_datetime(value: str) -> datetime | None:
    """다양한 한국 은행 날짜 포맷을 ``datetime`` 으로. 실패 시 None."""
    cleaned = value.strip()
    if not cleaned:
        return None
    # ISO 8601 with timezone (예: 2026-05-03T14:30:00+09:00)
    try:
        return datetime.fromisoformat(cleaned)
    except ValueError:
        pass
    for fmt in _DATETIME_FORMATS:
        try:
            dt = datetime.strptime(cleaned, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=UTC)
            return dt
        except ValueError:
            continue
    return None


def _parse_amount(value: str) -> int | None:
    """쉼표/공백 제거 후 정수. 음수/0 / 비숫자는 None."""
    cleaned = value.replace(",", "").replace(" ", "").strip()
    if not cleaned:
        return None
    if not cleaned.lstrip("-").isdigit():
        return None
    try:
        amount = int(cleaned)
    except ValueError:
        return None
    return amount if amount > 0 else None


def parse_csv(content: str) -> tuple[list[ParsedRow], list[ErrorRow]]:
    """CSV 본문 → (정상 행, 에러 행) 분리.

    Returns:
        valid_rows: ``AcademyBankTransaction`` 으로 매핑 가능한 행들
        error_rows: 실패 행 (row_number + 사유)

    원칙: 1행 실패는 다른 행 처리를 막지 않는다. 학원장이 error_rows 를 확인하고
    수정 후 재업로드 또는 해당 행만 수기 입력.
    """
    if not content.strip():
        return [], [ErrorRow(row_number=0, reason="빈 CSV")]

    # BOM 잔재 제거 (endpoint 가 utf-8-sig 로 디코드해도 fallback).
    if content.startswith("﻿"):
        content = content[1:]

    reader = csv.DictReader(StringIO(content))
    if not reader.fieldnames:
        return [], [ErrorRow(row_number=0, reason="헤더 없음")]

    # 컬럼 정규화 — 원본 header → 표준 필드명.
    header_map: dict[str, str] = {}
    for field in reader.fieldnames:
        key = (field or "").strip().lower().replace(" ", "")
        if not key:
            continue
        if field.strip() in _HEADER_ALIASES:
            header_map[field] = _HEADER_ALIASES[field.strip()]
        elif key in _HEADER_ALIASES:
            header_map[field] = _HEADER_ALIASES[key]

    # 필수 필드 헤더 확인.
    standard_fields = set(header_map.values())
    missing = {"tx_at", "depositor_raw", "amount"} - standard_fields
    if missing:
        return [], [
            ErrorRow(
                row_number=0,
                reason=f"필수 헤더 누락: {sorted(missing)} (지원 헤더: 거래일시/입금자명/금액 또는 영문)",
            )
        ]

    valid_rows: list[ParsedRow] = []
    error_rows: list[ErrorRow] = []
    for index, raw_row in enumerate(reader, start=2):
        # 완전히 빈 행 skip — error 로 기록하지 않음.
        if not any((v or "").strip() for v in raw_row.values()):
            continue

        mapped: dict[str, str] = {}
        for original, std in header_map.items():
            mapped[std] = (raw_row.get(original) or "").strip()

        tx_at_str = mapped.get("tx_at", "")
        depositor = mapped.get("depositor_raw", "")
        amount_str = mapped.get("amount", "")
        if not tx_at_str or not depositor or not amount_str:
            error_rows.append(ErrorRow(row_number=index, reason="필수 필드(거래일시/입금자명/금액) 누락"))
            continue

        tx_at = _parse_datetime(tx_at_str)
        if tx_at is None:
            error_rows.append(ErrorRow(row_number=index, reason=f"거래일시 파싱 실패: {tx_at_str!r}"))
            continue

        amount = _parse_amount(amount_str)
        if amount is None:
            error_rows.append(ErrorRow(row_number=index, reason=f"금액이 양의 정수가 아님: {amount_str!r}"))
            continue

        valid_rows.append(
            ParsedRow(
                tx_at=tx_at,
                depositor_raw=depositor,
                amount=amount,
                memo_raw=mapped.get("memo_raw") or None,
                bank_name=mapped.get("bank_name") or None,
                source_ref=f"row:{index}",
            )
        )

    return valid_rows, error_rows


__all__ = ["ErrorRow", "ParsedRow", "parse_csv"]
