"""Unit tests for CSV parser — AC-M3 §5.1.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.1.

Pure function 단위 — DB 없음.
"""

from __future__ import annotations

from app.services.academy_payment_matching_csv import parse_csv

# ---------------------------------------------------------------------------
# 한글 헤더 — 한국 은행 CSV
# ---------------------------------------------------------------------------


def test_parse_csv_korean_headers_full_columns() -> None:
    content = (
        "거래일시,입금자명,금액,메모,은행\n"
        "2026-05-03 14:30,김지민 어머니,200000,0418지민,KB\n"
        "2026-05-04 09:15,이지수아빠,150000,,신한\n"
    )
    valid, errors = parse_csv(content)
    assert errors == []
    assert len(valid) == 2
    assert valid[0]["depositor_raw"] == "김지민 어머니"
    assert valid[0]["amount"] == 200_000
    assert valid[0]["memo_raw"] == "0418지민"
    assert valid[0]["bank_name"] == "KB"
    assert valid[0]["source_ref"] == "row:2"
    assert valid[1]["memo_raw"] is None  # 빈 메모 → None
    assert valid[1]["bank_name"] == "신한"


# ---------------------------------------------------------------------------
# 영문 헤더
# ---------------------------------------------------------------------------


def test_parse_csv_english_headers() -> None:
    content = "tx_at,depositor,amount,memo,bank\n2026-05-03,Kim,100000,note,KB\n"
    valid, errors = parse_csv(content)
    assert errors == []
    assert len(valid) == 1
    assert valid[0]["depositor_raw"] == "Kim"


# ---------------------------------------------------------------------------
# 헤더 변형 — 송금인 / 적요 등
# ---------------------------------------------------------------------------


def test_parse_csv_header_aliases() -> None:
    content = "입금일시,송금인,입금액,적요,은행명\n2026-05-03,김지민,180000,수업료,카뱅\n"
    valid, errors = parse_csv(content)
    assert errors == []
    assert valid[0]["depositor_raw"] == "김지민"
    assert valid[0]["amount"] == 180_000
    assert valid[0]["memo_raw"] == "수업료"
    assert valid[0]["bank_name"] == "카뱅"


# ---------------------------------------------------------------------------
# 금액 쉼표 처리
# ---------------------------------------------------------------------------


def test_parse_csv_amount_with_commas() -> None:
    content = '거래일시,입금자명,금액\n2026-05-03,김지민,"200,000"\n'
    valid, errors = parse_csv(content)
    assert errors == []
    assert valid[0]["amount"] == 200_000


# ---------------------------------------------------------------------------
# 다양한 날짜 포맷
# ---------------------------------------------------------------------------


def test_parse_csv_multiple_date_formats() -> None:
    content = "거래일시,입금자명,금액\n2026-05-03 14:30:00,A,100000\n2026.05.04,B,100000\n2026/05/05 10:00,C,100000\n"
    valid, errors = parse_csv(content)
    assert errors == []
    assert len(valid) == 3


# ---------------------------------------------------------------------------
# 부분 실패 — graceful 처리
# ---------------------------------------------------------------------------


def test_parse_csv_reports_error_rows_continues_valid() -> None:
    content = (
        "거래일시,입금자명,금액\n"
        "2026-05-03,김지민,200000\n"  # OK
        "잘못된날짜,이지수,100000\n"  # 날짜 실패
        "2026-05-04,박철수,abc\n"  # 금액 실패
        "2026-05-05,,150000\n"  # 입금자명 누락
        "2026-05-06,홍길동,180000\n"  # OK
    )
    valid, errors = parse_csv(content)
    assert len(valid) == 2
    assert len(errors) == 3
    assert {e["row_number"] for e in errors} == {3, 4, 5}
    assert any("거래일시 파싱 실패" in e["reason"] for e in errors)
    assert any("양의 정수" in e["reason"] for e in errors)
    assert any("필수 필드" in e["reason"] for e in errors)


# ---------------------------------------------------------------------------
# 빈 행 skip — error 로 기록하지 않음
# ---------------------------------------------------------------------------


def test_parse_csv_skips_empty_rows() -> None:
    content = "거래일시,입금자명,금액\n2026-05-03,김지민,200000\n,,\n2026-05-04,이지수,150000\n"
    valid, errors = parse_csv(content)
    assert errors == []
    assert len(valid) == 2


# ---------------------------------------------------------------------------
# 필수 헤더 누락
# ---------------------------------------------------------------------------


def test_parse_csv_missing_required_header() -> None:
    content = "거래일시,입금자명\n2026-05-03,김지민\n"  # 금액 없음
    valid, errors = parse_csv(content)
    assert valid == []
    assert len(errors) == 1
    assert "필수 헤더 누락" in errors[0]["reason"]


# ---------------------------------------------------------------------------
# 빈 입력
# ---------------------------------------------------------------------------


def test_parse_csv_empty_input() -> None:
    valid, errors = parse_csv("")
    assert valid == []
    assert len(errors) == 1
    assert errors[0]["reason"] == "빈 CSV"


def test_parse_csv_negative_amount_rejected() -> None:
    """음수 금액 거부 — 출금 행은 본 endpoint 범위 아님."""
    content = "거래일시,입금자명,금액\n2026-05-03,김지민,-100000\n"
    valid, errors = parse_csv(content)
    assert valid == []
    assert len(errors) == 1
    assert "양의 정수" in errors[0]["reason"]
