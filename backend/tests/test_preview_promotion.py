"""Preview 레슨 정식 전환 (subscription_required_spec §2.6.2, J16).

renewal_pending 으로 생성된 is_preview 레슨은:
- 새 수강권 발급(직접 발급 / 제안 입금확인) 시 → 재귀속 + preview 해제 + 회차 부여
- 갱신 제안 거절/취소 시 → 레슨 취소 (영구 preview 잔존 방지)
"""

import pytest
from httpx import AsyncClient


async def _issue_exhausted_with_preview(
    teacher, client: AsyncClient, auth_headers: dict, name: str
) -> tuple[str, str, str]:
    """total 1회 수강권 소진 + renewal_pending preview 레슨 1개 생성."""
    sid = await teacher.create_student(name)
    old_sub = await teacher.create_subscription(sid, total_lessons=1, amount=100000)

    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": sid,
            "date": "2026-09-01",
            "start_time": "09:00",
            "duration": 60,
            "subscription_id": old_sub,
        },
    )
    assert r.status_code == 201, r.text
    await teacher.complete_lesson(r.json()["id"])

    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": sid,
            "date": "2026-09-08",
            "start_time": "09:00",
            "duration": 60,
            "subscription_id": old_sub,
            "overflow_mode": "renewal_pending",
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["is_preview"] is True
    return sid, old_sub, r.json()["id"]


async def _get_lesson(client: AsyncClient, auth_headers: dict, lesson_id: str) -> dict:
    r = await client.get(f"/api/v1/lessons/{lesson_id}", headers=auth_headers)
    assert r.status_code == 200, r.text
    return r.json()


@pytest.mark.asyncio
async def test_direct_issue_promotes_preview(teacher, client: AsyncClient, auth_headers: dict):
    """미가입 [갱신 발급] 경로 — 직접 발급이 preview 를 정식 회차로 전환한다."""
    sid, _old, preview_id = await _issue_exhausted_with_preview(teacher, client, auth_headers, "직접갱신학생")

    new_sub = await teacher.create_subscription(sid, total_lessons=8, amount=320000)

    lesson = await _get_lesson(client, auth_headers, preview_id)
    assert lesson["is_preview"] is False
    assert lesson["subscription_id"] == new_sub
    assert lesson["session_number"] == 1


@pytest.mark.asyncio
async def test_confirm_proposal_promotes_preview(teacher, client: AsyncClient, auth_headers: dict):
    """갱신 제안 입금확인 경로 — 발급된 새 수강권으로 preview 전환."""
    sid, _old, preview_id = await _issue_exhausted_with_preview(teacher, client, auth_headers, "제안갱신학생")

    template_id = await teacher.create_template("갱신 8회권", lessons_count=8, amount=320000)
    proposal_id = await teacher.send_proposal(sid, template_id, is_renewal=True)

    # 테스트 단순화: authz 상 소유 교사도 respond 가능 — 입금 통보 상태로 전이 후 확인.
    r = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=auth_headers,
        json={"action": "notify_payment", "selected_template_id": template_id},
    )
    assert r.status_code == 200, r.text

    confirmed = await teacher.confirm_proposal(proposal_id)
    new_sub = confirmed["subscription_id"]
    assert new_sub

    lesson = await _get_lesson(client, auth_headers, preview_id)
    assert lesson["is_preview"] is False
    assert lesson["subscription_id"] == new_sub
    assert lesson["session_number"] == 1


@pytest.mark.asyncio
async def test_renewal_cancel_cancels_preview(teacher, client: AsyncClient, auth_headers: dict):
    """갱신 제안 취소 — preview 레슨을 취소해 영구 잔존을 막는다."""
    sid, _old, preview_id = await _issue_exhausted_with_preview(teacher, client, auth_headers, "갱신취소학생")

    template_id = await teacher.create_template("갱신취소 8회권", lessons_count=8, amount=320000)
    proposal_id = await teacher.send_proposal(sid, template_id, is_renewal=True)

    r = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=auth_headers,
        json={"action": "cancel"},
    )
    assert r.status_code == 200, r.text

    lesson = await _get_lesson(client, auth_headers, preview_id)
    assert lesson["status"] == "cancelled"
    assert lesson["is_preview"] is True, "취소된 preview 는 '정식이 된 적 없음' 마커를 유지한다"

@pytest.mark.asyncio
async def test_completing_preview_lesson_never_deducts(teacher, client: AsyncClient, auth_headers: dict):
    """critic 관찰 — 승격 전 preview 완료가 정규 카운터를 차감하면 안 된다.

    소진 수강권은 remaining<=0 bail 로 우연히 안전하지만, 보너스 확장으로
    remaining>0 이 된 뒤 preview 를 완료하면 오차감 경로가 열린다. is_preview
    명시 가드로 고정한다.
    """
    sid, old_sub, preview_id = await _issue_exhausted_with_preview(teacher, client, auth_headers, "프리뷰완료학생")

    # 보너스 레슨으로 수강권을 되살린다 (remaining > 0 상태 재현)
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": sid,
            "date": "2026-09-15",
            "start_time": "09:00",
            "duration": 60,
            "subscription_id": old_sub,
            "overflow_mode": "bonus",
        },
    )
    assert r.status_code == 201, r.text

    before = await client.get(f"/api/v1/subscriptions/{old_sub}", headers=auth_headers)
    used_before = before.json()["used_lessons"]

    # preview 레슨 완료 — 정규 카운터 불변이어야 한다
    await teacher.complete_lesson(preview_id)

    after = await client.get(f"/api/v1/subscriptions/{old_sub}", headers=auth_headers)
    assert after.json()["used_lessons"] == used_before, "preview 완료는 정규 차감을 발생시키지 않는다"
