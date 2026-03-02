"""API v1 router – aggregates all domain routers."""

from fastapi import APIRouter

from app.api.v1 import (
    auth,
    bookings,
    lessons,
    notifications,
    parents,
    practice,
    recordings,
    relationships,
    schedule,
    students,
    subscriptions,
    teachers,
    users,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(teachers.router, prefix="/teachers", tags=["teachers"])
api_router.include_router(students.router, prefix="/students", tags=["students"])
api_router.include_router(lessons.router, prefix="/lessons", tags=["lessons"])
api_router.include_router(subscriptions.router, prefix="/subscriptions", tags=["subscriptions"])
api_router.include_router(practice.router, prefix="/practice", tags=["practice"])
api_router.include_router(recordings.router, prefix="/recordings", tags=["recordings"])
api_router.include_router(schedule.router, prefix="/schedule", tags=["schedule"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(parents.router, prefix="/parents", tags=["parents"])
api_router.include_router(relationships.router, tags=["relationships"])
