"""Phone OTP verification code storage — #709.

OTP 코드를 서버에서 생성·해시 저장하고 서버에서 검증한다.
클라이언트는 결과(성공/실패)만 받는다 — 코드 자체는 절대 응답에 노출하지 않는다.

Redis를 사용하지 않는 이유:
- rate_limit.py를 포함해 앱 내 어떤 곳도 Redis를 실제로 연결하지 않는다.
- beta 서버의 Redis 가동 여부 불명 — DB 기반이 가장 안전하고 SQLite 테스트와 호환된다.
- TTL은 expires_at 컬럼으로 애플리케이션 레벨에서 관리한다.
"""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import DateTime, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class PhoneVerificationCode(UUIDMixin, Base):
    """OTP 코드 저장 테이블.

    한 전화번호당 최신 코드 1건이 존재한다 (request_code 시 기존 행 삭제 후 재삽입).
    """

    __tablename__ = "phone_verification_codes"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    # SHA-256+salt 해시. 평문 코드는 저장하지 않는다.
    code_hash: Mapped[str] = mapped_column(String(256), nullable=False)
    salt: Mapped[str] = mapped_column(String(64), nullable=False)
    # 인증 대상 전화번호 (로그 목적 — 마스킹 후 로깅 가능)
    phone_number: Mapped[str] = mapped_column(String(20), nullable=False)
    # 코드 만료 시각 (UTC). TTL 3분.
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # 검증 시도 횟수. 5회 초과 시 잠금.
    attempt_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    # 마지막 발송 요청 시각 (쿨다운 60초 검사용).
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # 생성 시각
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    __table_args__ = (
        Index("ix_phone_verification_codes_teacher_id", "teacher_id"),
        Index("ix_phone_verification_codes_phone_number", "phone_number"),
    )


class PhoneVerificationDailyCount(UUIDMixin, Base):
    """번호당 일일 발송 횟수 추적 — 5회/일 한도.

    date_key = YYYY-MM-DD (UTC). 번호+날짜 조합으로 unique.
    """

    __tablename__ = "phone_verification_daily_counts"

    phone_number: Mapped[str] = mapped_column(String(20), nullable=False)
    date_key: Mapped[str] = mapped_column(String(10), nullable=False)
    count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index(
            "uq_phone_verification_daily",
            "phone_number",
            "date_key",
            unique=True,
        ),
    )
