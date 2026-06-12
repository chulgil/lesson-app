"""Phone OTP verification service — #709.

보안 원칙:
- OTP 코드는 서버에서 생성 (secrets 모듈, 6자리 숫자).
- 저장은 SHA-256+salt 해시만. 평문 코드는 메모리에도 최소 시간 체류.
- TTL 3분, 쿨다운 60초, 번호당 5회/일, 시도 5회 제한.
- 코드 자체는 어떤 응답/로그에도 노출 금지.
- 전화번호는 로그에서 마스킹.
- 검증 성공 시 즉시 코드 행 삭제 (재사용 차단).
- is_phone_verified는 오직 이 서비스의 verify_code 성공 경로에서만 True로 세팅.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.phone_verification_code import PhoneVerificationCode, PhoneVerificationDailyCount
from app.models.teacher import Teacher
from app.services.sms_service import SmsService, _mask_phone

logger = logging.getLogger(__name__)

_OTP_TTL_MINUTES = 3
_COOLDOWN_SECONDS = 60
_MAX_DAILY_SENDS = 5
_MAX_VERIFY_ATTEMPTS = 5


def _generate_otp() -> str:
    """암호학적으로 안전한 6자리 숫자 OTP."""
    return f"{secrets.randbelow(1_000_000):06d}"


def _hash_code(code: str, salt: str) -> str:
    """SHA-256(code + salt) hex digest."""
    return hashlib.sha256(f"{code}{salt}".encode()).hexdigest()


def _make_salt() -> str:
    return secrets.token_hex(32)


def _today_key() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%d")


class PhoneVerificationService:
    def __init__(self, db: AsyncSession, sms_service: SmsService | None = None) -> None:
        self.db = db
        self._sms = sms_service or SmsService()

    async def request_code_for_user(self, user_id: str, phone_number: str) -> dict:
        """라우터 진입점 — user_id 로 본인 teacher 행을 해석한 뒤 request_code."""
        teacher = await self._get_teacher_by_user(user_id)
        return await self.request_code(teacher.id, phone_number)

    async def verify_code_for_user(self, user_id: str, phone_number: str, code: str) -> dict:
        """라우터 진입점 — user_id 로 본인 teacher 행을 해석한 뒤 verify_code."""
        teacher = await self._get_teacher_by_user(user_id)
        return await self.verify_code(teacher.id, phone_number, code)

    async def _get_teacher_by_user(self, user_id: str) -> Teacher:
        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == user_id))
        if teacher is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher profile not found",
            )
        return teacher

    async def request_code(self, teacher_id: str, phone_number: str) -> dict:
        """OTP 코드 발송 요청.

        Returns: {"cooldown_seconds_remaining": int} — 0이면 바로 발송됨.
        Raises:
            HTTP 429 — 쿨다운 중
            HTTP 429 — 일일 한도 초과
        """
        # 쿨다운 확인 (기존 코드 행 기준)
        existing = await self._get_existing_code(teacher_id)
        if existing is not None:
            elapsed = (datetime.now(UTC) - existing.requested_at.replace(tzinfo=UTC)).total_seconds()
            remaining = int(_COOLDOWN_SECONDS - elapsed)
            if remaining > 0:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "code": "otp_cooldown",
                        "message": f"인증번호를 이미 발송했어요. {remaining}초 후 다시 시도해주세요.",
                        "cooldown_seconds_remaining": remaining,
                    },
                )

        # 일일 한도 확인
        today = _today_key()
        daily = await self._get_daily_count(phone_number, today)
        if daily is not None and daily.count >= _MAX_DAILY_SENDS:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "code": "otp_daily_limit",
                    "message": "오늘 인증 시도 횟수를 초과했어요. 내일 다시 시도해주세요.",
                },
            )

        # 기존 코드 삭제 (재발송 시)
        if existing is not None:
            await self.db.delete(existing)
            await self.db.flush()

        # 새 코드 생성 및 저장
        code = _generate_otp()
        salt = _make_salt()
        code_hash = _hash_code(code, salt)
        now = datetime.now(UTC)

        new_code = PhoneVerificationCode(
            teacher_id=teacher_id,
            code_hash=code_hash,
            salt=salt,
            phone_number=phone_number,
            expires_at=now + timedelta(minutes=_OTP_TTL_MINUTES),
            attempt_count=0,
            requested_at=now,
        )
        self.db.add(new_code)

        # 일일 카운트 증가
        if daily is None:
            daily = PhoneVerificationDailyCount(
                phone_number=phone_number,
                date_key=today,
                count=1,
            )
            self.db.add(daily)
        else:
            daily.count += 1

        await self.db.flush()

        # SMS 발송 (mock 모드 포함 — 실패해도 코드 행은 남긴다)
        sent = await self._sms.send_otp(phone_number, code)
        if not sent:
            # 발송 실패: 행은 남기되 에러 반환 (클라이언트가 재시도 가능)
            logger.warning("SMS send failed, code stored but not delivered phone=%s", _mask_phone(phone_number))
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={"code": "sms_send_failed", "message": "SMS 발송에 실패했어요. 잠시 후 다시 시도해주세요."},
            )

        logger.info("OTP requested teacher=%s phone=%s", teacher_id, _mask_phone(phone_number))
        return {"message": "인증번호를 발송했어요."}

    async def verify_code(self, teacher_id: str, phone_number: str, code: str) -> dict:
        """OTP 코드 검증.

        Returns: {"verified": True}
        Raises:
            HTTP 400 — 코드 없음 / 만료됨
            HTTP 400 — 잘못된 코드 (남은 시도 횟수 포함)
            HTTP 429 — 시도 횟수 초과
        """
        record = await self._get_existing_code(teacher_id)

        if record is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"code": "otp_not_found", "message": "인증번호를 먼저 요청해주세요."},
            )

        # TTL 확인
        if datetime.now(UTC) > record.expires_at.replace(tzinfo=UTC):
            await self.db.delete(record)
            await self.db.flush()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"code": "otp_expired", "message": "인증번호가 만료됐어요. 다시 요청해주세요."},
            )

        # 시도 횟수 초과
        if record.attempt_count >= _MAX_VERIFY_ATTEMPTS:
            await self.db.delete(record)
            await self.db.flush()
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "code": "otp_attempts_exceeded",
                    "message": "시도 횟수를 초과했어요. 인증번호를 다시 요청해주세요.",
                },
            )

        # 전화번호 불일치 (IDOR 방어 — 발송 시의 번호와 검증 시의 번호가 다른 경우)
        if record.phone_number != phone_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"code": "otp_phone_mismatch", "message": "전화번호가 일치하지 않아요."},
            )

        # 코드 해시 비교
        expected_hash = _hash_code(code, record.salt)
        if not secrets.compare_digest(expected_hash, record.code_hash):
            record.attempt_count += 1
            remaining = _MAX_VERIFY_ATTEMPTS - record.attempt_count
            await self.db.flush()
            logger.info(
                "OTP verify failed teacher=%s phone=%s attempts_left=%d",
                teacher_id,
                _mask_phone(phone_number),
                remaining,
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "otp_invalid",
                    "message": "인증번호가 일치하지 않아요.",
                    "attempts_remaining": remaining,
                },
            )

        # 검증 성공: 코드 행 즉시 삭제 (재사용 차단)
        await self.db.delete(record)

        # teacher.is_phone_verified = True 세팅 (오직 이 경로에서만)
        teacher = await self.db.scalar(select(Teacher).where(Teacher.id == teacher_id))
        if teacher is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
        teacher.is_phone_verified = True
        teacher.phone_number = phone_number
        teacher.phone_verified_at = datetime.now(UTC)
        await self.db.flush()

        logger.info("OTP verify success teacher=%s phone=%s", teacher_id, _mask_phone(phone_number))
        return {"verified": True, "message": "전화인증이 완료됐어요."}

    # ------------------------------------------------------------------ helpers

    async def _get_existing_code(self, teacher_id: str) -> PhoneVerificationCode | None:
        return await self.db.scalar(select(PhoneVerificationCode).where(PhoneVerificationCode.teacher_id == teacher_id))

    async def _get_daily_count(self, phone_number: str, date_key: str) -> PhoneVerificationDailyCount | None:
        return await self.db.scalar(
            select(PhoneVerificationDailyCount).where(
                PhoneVerificationDailyCount.phone_number == phone_number,
                PhoneVerificationDailyCount.date_key == date_key,
            )
        )
