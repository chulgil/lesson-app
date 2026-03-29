"""Scenario: Schedule — availability, bookings, lesson requests.

Depends on: base/accounts
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from scripts.seeds.helpers import log_seed, upsert
from scripts.seeds.ids import (
    STUDENT1_ID,
    STUDENT1_USER_ID,
    STUDENT2_ID,
    STUDENT2_USER_ID,
    STUDENT3_USER_ID,
    TEACHER_ID,
    TEACHER_USER_ID,
)


async def seed_schedule(db: AsyncSession, *, reset: bool = False) -> None:
    """Create schedule test data: availability, bookings, requests."""
    from app.models.schedule import (
        AvailabilityTimeSlot,
        LessonBooking,
        LessonRequest,
        TeacherAvailability,
    )

    if reset:
        await db.execute(delete(AvailabilityTimeSlot))
        await db.execute(delete(TeacherAvailability).where(
            TeacherAvailability.teacher_id == TEACHER_USER_ID
        ))
        await db.execute(delete(LessonBooking).where(
            LessonBooking.teacher_id == TEACHER_USER_ID
        ))
        await db.execute(delete(LessonRequest).where(
            LessonRequest.teacher_id == TEACHER_ID
        ))
        await db.flush()

    print("[Scenario] 스케줄 데이터 생성...")

    now = datetime.now(UTC)
    today = date.today()

    # ── Teacher availability: 월/수/금 ────────────────────────────────
    availability_data = [
        (0, "14:00", "20:00"),  # 월
        (2, "14:00", "20:00"),  # 수
        (4, "10:00", "18:00"),  # 금
    ]
    avail_count = 0
    for day_of_week, start, end in availability_data:
        avail = TeacherAvailability(
            id=f"seed-avail-{day_of_week:02d}",
            teacher_id=TEACHER_USER_ID,
            day_of_week=day_of_week,
        )
        existing = await db.get(TeacherAvailability, avail.id)
        if not existing:
            db.add(avail)
            await db.flush()
            ts = AvailabilityTimeSlot(
                id=f"seed-slot-{day_of_week:02d}-01",
                availability_id=avail.id,
                start_time=start,
                end_time=end,
            )
            db.add(ts)
            avail_count += 1
    await db.flush()
    log_seed("가용시간", avail_count, "월/수/금")

    # ── Bookings ──────────────────────────────────────────────────────
    # 다음 월요일에 예약 2건
    next_monday = today + timedelta(days=(7 - today.weekday()) % 7 or 7)

    bookings = [
        ("seed-booking-0001", STUDENT1_USER_ID, next_monday, "14:00", 60, "바이올린", "approved"),
        ("seed-booking-0002", STUDENT2_USER_ID, next_monday, "15:30", 60, "바이올린", "pending"),
    ]
    booking_count = 0
    for bid, sid, sdate, stime, dur, inst, bstatus in bookings:
        existing = await db.get(LessonBooking, bid)
        if not existing:
            db.add(LessonBooking(
                id=bid, teacher_id=TEACHER_USER_ID, student_id=sid,
                lesson_type="regular", scheduled_date=sdate,
                scheduled_time=stime, duration=dur,
                instrument=inst, status=bstatus,
            ))
            booking_count += 1
    await db.flush()
    log_seed("부킹", booking_count, f"다음 월요일 {next_monday}")

    # ── Lesson requests ───────────────────────────────────────────────
    requests = [
        ("seed-request-0001", STUDENT1_USER_ID, "pending", "regular", "바이올린"),
        ("seed-request-0002", STUDENT1_USER_ID, "pending", "regular", "바이올린"),
        ("seed-request-0003", STUDENT2_USER_ID, "proposalSent", "trial", "바이올린"),
        ("seed-request-0004", STUDENT3_USER_ID, "declined", "trial", "플루트"),
        ("seed-request-0005", STUDENT1_USER_ID, "expired", "regular", "바이올린"),
    ]
    req_count = 0
    for rid, sid, rstatus, rtype, inst in requests:
        existing = await db.get(LessonRequest, rid)
        if not existing:
            db.add(LessonRequest(
                id=rid, student_id=sid, teacher_id=TEACHER_ID,
                status=rstatus, request_type=rtype, instrument=inst,
                expires_at=now + timedelta(days=7),
                created_at=now - timedelta(days=2),
            ))
            req_count += 1
    await db.flush()
    log_seed("레슨 요청", req_count, "pending 2, proposalSent 1, declined 1, expired 1")
