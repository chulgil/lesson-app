"""API v1 router – aggregates all domain routers."""

from fastapi import APIRouter

from app.api.v1 import (
    ai_notes,
    analytics,
    auth,
    availability,
    bookings,
    device_tokens,
    gamification,
    groups,
    invites,
    lesson_policies,
    lesson_requests,
    lessons,
    locations,
    manual_teachers,
    memberships,
    notifications,
    parents,
    posts,
    practice,
    practice_logs,
    profile_images,
    recordings,
    relationships,
    request_events,
    reviews,
    schedule,
    schedule_changes,
    schedule_confirmations,
    schedule_exceptions,
    scheduler,
    settings_api,
    students,
    subscription_settings,
    subscriptions,
    teachers,
    users,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(teachers.router, prefix="/teachers", tags=["teachers"])
api_router.include_router(students.router, prefix="/students", tags=["students"])
api_router.include_router(lessons.router, prefix="/lessons", tags=["lessons"])
api_router.include_router(memberships.router, prefix="/memberships", tags=["memberships"])
api_router.include_router(subscriptions.router, prefix="/subscriptions", tags=["subscriptions"])
api_router.include_router(subscription_settings.router, prefix="/subscription-settings", tags=["subscription-settings"])
api_router.include_router(lesson_policies.router, prefix="/lesson-policies", tags=["lesson-policies"])
api_router.include_router(manual_teachers.router, prefix="/manual-teachers", tags=["manual-teachers"])
api_router.include_router(practice.router, prefix="/practice", tags=["practice"])
api_router.include_router(practice_logs.router, prefix="/practice-logs", tags=["practice-logs"])
api_router.include_router(recordings.router, prefix="/recordings", tags=["recordings"])
api_router.include_router(schedule.router, prefix="/schedule", tags=["schedule"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(parents.router, prefix="/parents", tags=["parents"])
api_router.include_router(posts.router, prefix="/posts", tags=["posts"])
api_router.include_router(relationships.router, tags=["relationships"])
api_router.include_router(invites.router, prefix="/invites", tags=["invites"])
api_router.include_router(gamification.router, prefix="/gamification", tags=["gamification"])
api_router.include_router(settings_api.router, prefix="/settings", tags=["settings"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
api_router.include_router(groups.router, prefix="/groups", tags=["groups"])
api_router.include_router(locations.router, prefix="/locations", tags=["locations"])
api_router.include_router(lesson_requests.router, prefix="/schedule/lesson-requests", tags=["lesson-requests"])
api_router.include_router(
    request_events.router,
    prefix="/schedule/lesson-requests/{request_id}/events",
    tags=["request-events"],
)
api_router.include_router(profile_images.router, prefix="/profile-images", tags=["profile-images"])
api_router.include_router(ai_notes.router, prefix="/ai-notes", tags=["ai-notes"])
api_router.include_router(device_tokens.router, prefix="/device-tokens", tags=["device-tokens"])
api_router.include_router(scheduler.router, prefix="/scheduler", tags=["scheduler"])
api_router.include_router(
    schedule_changes.router,
    prefix="/schedule/lesson-schedule-changes",
    tags=["schedule-changes"],
)
api_router.include_router(
    schedule_confirmations.router,
    prefix="/schedule/confirmation-cards",
    tags=["schedule-confirmations"],
)
api_router.include_router(
    schedule_exceptions.router,
    prefix="/schedule-exceptions",
    tags=["schedule-exceptions"],
)
api_router.include_router(
    availability.router,
    prefix="/availability",
    tags=["availability"],
)
