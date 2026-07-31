"""FastAPI application entry point."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings, validate_runtime_configuration
from app.core.exceptions import register_exception_handlers
from app.core.i18n import LocaleMiddleware
from app.core.security_headers import (
    SecurityHeadersMiddleware,  # noqa: F401  add_middleware 에서 사용 — ruff 가 데코레이터 인자 detect 못함.
)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan: startup and shutdown hooks."""
    validate_runtime_configuration()

    # Startup: import all models to register with Base.metadata
    import app.models  # type: ignore[assignment]  # noqa: F401

    # Plan C Phase 6a/6c — start APScheduler. Disabled when TESTING flag is set
    # so pytest doesn't spawn a background event loop.
    from app.core.config import settings as _settings
    from app.core.scheduler import (
        register_daily_kst_job,
        register_interval_job,
        shutdown_scheduler,
        start_scheduler,
    )
    from app.jobs.subscription_expiry_job import JOB_ID, run_subscription_expiry_job

    scheduler_enabled = not getattr(_settings, "TESTING", False)
    if scheduler_enabled:
        # KST 00:05 daily — subscription expiry status transition + notification dispatch
        register_daily_kst_job(run_subscription_expiry_job, job_id=JOB_ID, hour=0, minute=5)

        # KST 09:00 daily — payment reminder jobs (#424). One registered job per D+N
        # so scheduler logs surface a clear entry for each cycle.
        from app.jobs.payment_reminder_jobs import (
            JOB_ID_D1,
            JOB_ID_D3,
            JOB_ID_D7,
            run_payment_reminder_d1,
            run_payment_reminder_d3,
            run_payment_reminder_d7_final,
        )

        register_daily_kst_job(run_payment_reminder_d1, job_id=JOB_ID_D1, hour=9, minute=0)
        register_daily_kst_job(run_payment_reminder_d3, job_id=JOB_ID_D3, hour=9, minute=1)
        register_daily_kst_job(run_payment_reminder_d7_final, job_id=JOB_ID_D7, hour=9, minute=2)

        # KST 08:05 daily — vacation return announcements (#4 H-001 §6.3).
        # Runs *before* the payment reminders to keep mid-morning fan-outs
        # batched within the same alimtalk send window.
        from app.jobs.vacation_return_jobs import (
            JOB_ID as JOB_ID_VAC_RETURN,
        )
        from app.jobs.vacation_return_jobs import (
            run_vacation_return_announcement,
        )

        register_daily_kst_job(
            run_vacation_return_announcement,
            job_id=JOB_ID_VAC_RETURN,
            hour=8,
            minute=5,
        )

        # Hourly — schedule-change 72h expiry + 24h reminder + 60h approaching (#692).
        from app.jobs.schedule_change_expiry_jobs import (
            JOB_ID_EXPIRY,
            run_schedule_change_expiry_job,
        )

        register_interval_job(
            run_schedule_change_expiry_job,
            job_id=JOB_ID_EXPIRY,
            hours=1,
        )

        # 그룹 수업 리마인더 (P2-2). 전일은 저녁에 (다음날 일정을 확인하는 시간대),
        # 당일은 아침에 보낸다.
        from app.jobs.group_lesson_reminder_jobs import (
            JOB_ID_DAY_BEFORE,
            JOB_ID_DAY_OF,
            run_group_lesson_reminder_day_before,
            run_group_lesson_reminder_day_of,
        )

        register_daily_kst_job(
            run_group_lesson_reminder_day_before,
            job_id=JOB_ID_DAY_BEFORE,
            hour=20,
            minute=0,
        )
        register_daily_kst_job(
            run_group_lesson_reminder_day_of,
            job_id=JOB_ID_DAY_OF,
            hour=8,
            minute=0,
        )

        start_scheduler()

    yield

    if scheduler_enabled:
        shutdown_scheduler()
    # Shutdown: dispose engine connection pool
    from app.core.database import engine

    await engine.dispose()


app = FastAPI(
    title="Lessonaza API",
    version="0.1.0",
    description="Lessonaza — Music lesson & practice management API (lessonaza.app)",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware — allow_methods / allow_headers 를 명시적으로 화이트리스트한다.
# wildcard ``*`` 는 allow_credentials=True 와 결합하면 일부 브라우저에서 CORS spec 위반으로
# 차단되거나, custom request header (예: ``X-Internal-API-Key``) 가 prefli ght 에서 누락된다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=[
        "Accept",
        "Accept-Language",
        "Authorization",
        "Content-Type",
        "X-Internal-API-Key",
        "X-Requested-With",
        "X-Forwarded-For",
    ],
)

# 응답 기본 보안 헤더 — clickjacking / MIME sniffing / referrer 누설 차단.
# CORS 이후에 추가해 preflight 응답에도 헤더가 부착되도록 한다.
app.add_middleware(SecurityHeadersMiddleware)

# Locale middleware (reads Accept-Language header)
app.add_middleware(LocaleMiddleware)

# Custom exception handlers
register_exception_handlers(app)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


# Mount API v1 router
from app.api.v1 import api_router  # noqa: E402

app.include_router(api_router, prefix="/api/v1")
