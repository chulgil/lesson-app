"""API v1 router – aggregates all domain routers."""

from fastapi import APIRouter

from app.api.v1 import (
    academies,
    academy_announcements,
    academy_billing,
    academy_context,
    academy_governance,
    address,
    ai_notes,
    analytics,
    announcements,
    app_billing,
    app_version,
    auth,
    availability,
    bookings,
    device_tokens,
    gamification,
    groups,
    help,
    invite_landing,
    invites,
    lesson_policies,
    lesson_requests,
    lesson_summaries,
    lessons,
    locations,
    makeup_credits,
    manual_teachers,
    memberships,
    notifications,
    parents,
    posts,
    practice,
    practice_logs,
    practice_loop_stats,
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
    student_summary,
    students,
    subscription_settings,
    subscriptions,
    teachers,
    users,
    vacations,
)

api_router = APIRouter()

api_router.include_router(academies.router, prefix="/academies", tags=["academies"])
api_router.include_router(
    academies.public_router,
    prefix="/public/academies/invites",
    tags=["academies-public"],
)
api_router.include_router(
    academy_governance.router,
    prefix="/academies",
    tags=["academies-governance"],
)
api_router.include_router(
    academy_billing.router,
    prefix="/academies",
    tags=["academies-billing"],
)
api_router.include_router(
    academy_announcements.router,
    prefix="/academies",
    tags=["academies-announcements"],
)
api_router.include_router(
    academy_context.router,
    prefix="/auth",
    tags=["academy-context"],
)
api_router.include_router(address.router, prefix="/address", tags=["address"])
api_router.include_router(app_version.router, prefix="/app/version", tags=["app-version"])
api_router.include_router(app_billing.router, prefix="/me/billing", tags=["billing"])
api_router.include_router(app_billing.router, prefix="/app/billing", tags=["billing"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(teachers.router, prefix="/teachers", tags=["teachers"])
api_router.include_router(students.router, prefix="/students", tags=["students"])
api_router.include_router(lessons.router, prefix="/lessons", tags=["lessons"])
api_router.include_router(lesson_summaries.router, prefix="/lesson-summaries", tags=["lesson-summaries"])
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
api_router.include_router(announcements.router, prefix="/announcements", tags=["announcements"])
api_router.include_router(parents.router, prefix="/parents", tags=["parents"])
api_router.include_router(posts.router, prefix="/posts", tags=["posts"])
api_router.include_router(relationships.router, tags=["relationships"])
api_router.include_router(invites.router, prefix="/invites", tags=["invites"])
api_router.include_router(invite_landing.router, tags=["invites-public"])
api_router.include_router(gamification.router, prefix="/gamification", tags=["gamification"])
api_router.include_router(settings_api.router, prefix="/settings", tags=["settings"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
api_router.include_router(groups.router, prefix="/groups", tags=["groups"])
api_router.include_router(help.router, prefix="/help", tags=["help"])
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
api_router.include_router(
    vacations.router,
    prefix="/teacher/vacation",
    tags=["vacation"],
)
api_router.include_router(
    makeup_credits.student_router,
    prefix="/students/me/makeup-credits",
    tags=["makeup-credits"],
)
api_router.include_router(
    makeup_credits.teacher_router,
    prefix="/teachers/me/makeup-credits",
    tags=["makeup-credits"],
)
api_router.include_router(
    student_summary.router,
    tags=["public-sharing"],
)
api_router.include_router(
    practice_loop_stats.student_router,
    prefix="/students/me/practice-loop-stats",
    tags=["practice-loop-stats"],
)
api_router.include_router(
    practice_loop_stats.teacher_router,
    prefix="/teachers/me/practice-loop-stats",
    tags=["practice-loop-stats"],
)
