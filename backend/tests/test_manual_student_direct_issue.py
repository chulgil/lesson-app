"""미가입(수기) 학생 즉시발급 특칙 회귀 고정 (subscription_required_spec §2.7).

J4 조사 결과: 직접 발급(``SubscriptionService.create``)은 확인 카드를 만들지
않고(카드는 제안 입금확인 경로 전용), 알림도 ``student.user_id`` 게이트로
미가입 학생에게 발송되지 않는다 — 이미 스펙과 일치. 이 테스트는 그 동작이
회귀로 깨지지 않게 고정한다 (AC-5.2).
"""

import pytest
from sqlalchemy import func, select


@pytest.mark.asyncio
async def test_direct_issue_for_manual_student_skips_card_and_notification(teacher, client, auth_headers, db_session):
    from app.models.notification import Notification
    from app.models.policy import ScheduleConfirmationCard

    sid = await teacher.create_student("수기발급학생")

    cards_before = await db_session.scalar(select(func.count(ScheduleConfirmationCard.id)))
    notifs_before = await db_session.scalar(select(func.count(Notification.id)))

    sub_id = await teacher.create_subscription(sid, total_lessons=8, amount=400000)
    assert sub_id

    cards_after = await db_session.scalar(select(func.count(ScheduleConfirmationCard.id)))
    notifs_after = await db_session.scalar(select(func.count(Notification.id)))

    assert cards_after == cards_before, "직접 발급은 확인 카드를 만들지 않는다 (§2.7 스케줄 확정 특칙)"
    assert notifs_after == notifs_before, "미가입 학생(user 미연결)에게 알림 발송 0건 (§2.7 알림 없음)"
