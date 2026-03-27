"""Scenario action helpers — wrap raw API calls into single-line operations.

Usage in tests:
    async def test_my_scenario(teacher: TeacherActions):
        student_id = await teacher.create_student("김학생", instrument="violin")
        lesson_id = await teacher.create_lesson(student_id, date="2026-03-20")
        await teacher.complete_lesson(lesson_id)
        await teacher.write_feedback(lesson_id, feedback="잘 했어요!")
"""

from __future__ import annotations

from httpx import AsyncClient


class TeacherActions:
    """High-level actions a teacher performs in the app."""

    def __init__(self, client: AsyncClient, headers: dict[str, str]) -> None:
        self.client = client
        self.headers = headers
        self._base = "/api/v1"

    # -- Profile & Settings --------------------------------------------------

    async def get_profile(self) -> dict:
        r = await self.client.get(f"{self._base}/users/me", headers=self.headers)
        assert r.status_code == 200, f"get_profile failed: {r.status_code} {r.text}"
        return r.json()

    async def get_my_teacher_profile(self) -> dict:
        """Get teacher's own profile (creates teacher record if needed)."""
        r = await self.client.get(
            f"{self._base}/teachers/me/profile",
            headers=self.headers,
        )
        assert r.status_code == 200, f"get_my_teacher_profile failed: {r.status_code} {r.text}"
        return r.json()

    async def update_teacher_profile(self, teacher_id: str, **kwargs) -> dict:
        """Update teacher profile fields (bank_accounts, instruments, etc.)."""
        r = await self.client.put(
            f"{self._base}/teachers/{teacher_id}",
            headers=self.headers,
            json=kwargs,
        )
        assert r.status_code == 200, f"update_teacher_profile failed: {r.status_code} {r.text}"
        return r.json()

    async def get_settings(self) -> dict:
        r = await self.client.get(f"{self._base}/settings/teacher", headers=self.headers)
        assert r.status_code == 200
        return r.json()

    async def update_settings(self, **kwargs) -> dict:
        r = await self.client.put(
            f"{self._base}/settings/teacher", headers=self.headers, json=kwargs
        )
        assert r.status_code == 200
        return r.json()

    async def get_dashboard(self, teacher_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/teachers/{teacher_id}/dashboard", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Students -------------------------------------------------------------

    async def create_student(
        self, name: str, *, instrument: str = "violin", level: str = "beginner", **kwargs
    ) -> str:
        """Create a student and return the student ID."""
        payload = {"name": name, "instrument": instrument, "level": level, **kwargs}
        r = await self.client.post(
            f"{self._base}/students", headers=self.headers, json=payload
        )
        assert r.status_code == 201, f"create_student failed: {r.status_code} {r.text}"
        return r.json()["id"]

    async def list_students(self, **params) -> dict:
        r = await self.client.get(
            f"{self._base}/students", headers=self.headers, params=params
        )
        assert r.status_code == 200
        return r.json()

    async def get_student(self, student_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/students/{student_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Lessons --------------------------------------------------------------

    async def create_lesson(
        self,
        student_id: str,
        *,
        date: str = "2026-03-20",
        start_time: str = "14:00",
        duration: int = 60,
        instrument: str | None = None,
        pieces: list[dict] | None = None,
        location_name: str | None = None,
    ) -> str:
        """Create a lesson and return the lesson ID."""
        payload: dict = {
            "student_id": student_id,
            "date": date,
            "start_time": start_time,
            "duration": duration,
        }
        if instrument:
            payload["instrument"] = instrument
        if pieces:
            payload["pieces"] = pieces
        if location_name:
            payload["location_name"] = location_name
        r = await self.client.post(
            f"{self._base}/lessons", headers=self.headers, json=payload
        )
        assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
        return r.json()["id"]

    async def get_lesson(self, lesson_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/lessons/{lesson_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def complete_lesson(self, lesson_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/lessons/{lesson_id}/status",
            headers=self.headers,
            json={"status": "completed"},
        )
        assert r.status_code == 200
        return r.json()

    async def cancel_lesson(self, lesson_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/lessons/{lesson_id}/status",
            headers=self.headers,
            json={"status": "cancelled"},
        )
        assert r.status_code == 200
        return r.json()

    async def mark_no_show(self, lesson_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/lessons/{lesson_id}/status",
            headers=self.headers,
            json={"status": "noShow"},
        )
        assert r.status_code == 200
        return r.json()

    async def write_feedback(
        self,
        lesson_id: str,
        *,
        feedback: str = "",
        key_points: list[str] | None = None,
        practice_tips: str | None = None,
    ) -> dict:
        payload: dict = {"feedback": feedback}
        if key_points:
            payload["key_points"] = key_points
        if practice_tips:
            payload["practice_tips"] = practice_tips
        r = await self.client.put(
            f"{self._base}/lessons/{lesson_id}/feedback",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 200
        return r.json()

    async def list_upcoming_lessons(self) -> list:
        r = await self.client.get(
            f"{self._base}/lessons/upcoming", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def list_recent_lessons(self) -> list:
        r = await self.client.get(
            f"{self._base}/lessons/recent", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Subscriptions --------------------------------------------------------

    async def create_template(
        self, name: str, *, lessons_count: int, amount: int, type: str = "package", **kwargs
    ) -> str:
        payload = {"name": name, "type": type, "lessons_count": lessons_count, "amount": amount, **kwargs}
        r = await self.client.post(
            f"{self._base}/subscriptions-templates", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def create_subscription(
        self, student_id: str, *, total_lessons: int, amount: int, **kwargs
    ) -> str:
        payload = {
            "student_id": student_id,
            "type": "package",
            "total_lessons": total_lessons,
            "amount": amount,
            **kwargs,
        }
        r = await self.client.post(
            f"{self._base}/subscriptions", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def get_subscription(self, sub_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/subscriptions/{sub_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def use_lesson(self, sub_id: str, lesson_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/subscriptions/{sub_id}/use-lesson",
            headers=self.headers,
            json={"lesson_id": lesson_id},
        )
        assert r.status_code == 200
        return r.json()

    async def confirm_payment(self, sub_id: str, method: str = "bankTransfer") -> dict:
        r = await self.client.patch(
            f"{self._base}/subscriptions/{sub_id}/confirm-payment",
            headers=self.headers,
            json={"payment_method": method},
        )
        assert r.status_code == 200
        return r.json()

    async def send_proposal(self, student_id: str, template_id: str, **kwargs) -> str:
        payload = {
            "student_id": student_id,
            "template_id": template_id,
            "template_ids": [template_id],
            "recommended_template_id": template_id,
            **kwargs,
        }
        r = await self.client.post(
            f"{self._base}/subscriptions-proposals", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def confirm_proposal(self, proposal_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/subscriptions-proposals/{proposal_id}/confirm",
            headers=self.headers,
            json={},
        )
        assert r.status_code == 200
        return r.json()

    # -- Invites & Connections ------------------------------------------------

    async def create_invite(self, **kwargs) -> dict:
        r = await self.client.post(
            f"{self._base}/invites/", headers=self.headers, json=kwargs
        )
        assert r.status_code == 201
        return r.json()

    async def list_pending_requests(self) -> dict:
        r = await self.client.get(
            f"{self._base}/invites/connection-requests/pending", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def accept_connection(self, request_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/invites/connection-requests/{request_id}/respond",
            headers=self.headers,
            json={"action": "accept"},
        )
        assert r.status_code == 200
        return r.json()

    async def reject_connection(self, request_id: str, reason: str = "") -> dict:
        r = await self.client.patch(
            f"{self._base}/invites/connection-requests/{request_id}/respond",
            headers=self.headers,
            json={"action": "reject", "rejection_reason": reason},
        )
        assert r.status_code == 200
        return r.json()

    async def list_connections(self) -> dict:
        r = await self.client.get(
            f"{self._base}/invites/connections", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Bookings -------------------------------------------------------------

    async def approve_booking(self, booking_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/bookings/{booking_id}/approve", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def reject_booking(self, booking_id: str, reason: str = "") -> dict:
        r = await self.client.patch(
            f"{self._base}/bookings/{booking_id}/reject",
            headers=self.headers,
            json={"reason": reason},
        )
        assert r.status_code == 200
        return r.json()

    # -- Unified Lesson Requests -----------------------------------------------

    async def list_lesson_requests(self, teacher_id: str, **params) -> dict:
        """List lesson requests for this teacher."""
        r = await self.client.get(
            f"{self._base}/schedule/lesson-requests",
            headers=self.headers,
            params={"teacher_id": teacher_id, **params},
        )
        assert r.status_code == 200
        return r.json()

    async def approve_lesson_request(self, request_id: str) -> dict:
        """Approve a student's lesson request."""
        r = await self.client.patch(
            f"{self._base}/schedule/lesson-requests/{request_id}/status",
            headers=self.headers,
            json={"status": "approved"},
        )
        assert r.status_code == 200, f"approve_lesson_request failed: {r.status_code} {r.text}"
        return r.json()

    async def reject_lesson_request(self, request_id: str, reason: str = "") -> dict:
        """Reject a student's lesson request with an optional reason."""
        r = await self.client.patch(
            f"{self._base}/schedule/lesson-requests/{request_id}/status",
            headers=self.headers,
            json={"status": "rejected", "decline_reason": reason},
        )
        assert r.status_code == 200, f"reject_lesson_request failed: {r.status_code} {r.text}"
        return r.json()

    async def get_lesson_request(self, request_id: str) -> dict:
        """Get a single lesson request."""
        r = await self.client.get(
            f"{self._base}/schedule/lesson-requests/{request_id}",
            headers=self.headers,
        )
        assert r.status_code == 200
        return r.json()

    async def update_lesson_request_status(
        self,
        request_id: str,
        status: str,
        *,
        decline_reason: str | None = None,
        proposal_id: str | None = None,
    ) -> dict:
        """Update lesson request status (teacher action)."""
        payload: dict = {"status": status}
        if decline_reason is not None:
            payload["decline_reason"] = decline_reason
        if proposal_id is not None:
            payload["proposal_id"] = proposal_id
        r = await self.client.patch(
            f"{self._base}/schedule/lesson-requests/{request_id}/status",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 200, f"update_lesson_request_status failed: {r.status_code} {r.text}"
        return r.json()

    async def propose_alternatives(
        self,
        request_id: str,
        slots: list[dict],
        *,
        message: str | None = None,
    ) -> dict:
        """Teacher proposes alternative time slots (max 3)."""
        payload: dict = {"slots": slots}
        if message is not None:
            payload["message"] = message
        r = await self.client.post(
            f"{self._base}/schedule/lesson-requests/{request_id}/propose-alternatives",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 200, f"propose_alternatives failed: {r.status_code} {r.text}"
        return r.json()

    # -- Group Classes --------------------------------------------------------

    async def create_group_schedule(
        self,
        group_class_id: str,
        *,
        start_time: str,
        end_time: str,
        max_capacity: int,
        waitlist_capacity: int | None = None,
    ) -> str:
        payload: dict = {
            "group_class_id": group_class_id,
            "start_time": start_time,
            "end_time": end_time,
            "max_capacity": max_capacity,
        }
        if waitlist_capacity is not None:
            payload["waitlist_capacity"] = waitlist_capacity
        r = await self.client.post(
            f"{self._base}/groups/schedules", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def book_group_student(self, schedule_id: str, student_id: str) -> dict:
        r = await self.client.post(
            f"{self._base}/groups/bookings",
            headers=self.headers,
            json={"schedule_id": schedule_id, "student_id": student_id},
        )
        return r.json()

    async def cancel_group_booking(self, booking_id: str, reason: str = "") -> dict:
        r = await self.client.patch(
            f"{self._base}/groups/bookings/{booking_id}/cancel",
            headers=self.headers,
            params={"reason": reason},
        )
        assert r.status_code == 200
        return r.json()

    async def mark_group_attendance(self, booking_id: str, attended: bool = True) -> dict:
        r = await self.client.patch(
            f"{self._base}/groups/bookings/{booking_id}/attendance",
            headers=self.headers,
            json={"attended": attended},
        )
        assert r.status_code == 200
        return r.json()

    # -- Practice -------------------------------------------------------------

    async def create_repertoire(self, student_id: str, name: str, **kwargs) -> str:
        payload = {"student_id": student_id, "name": name, "start_date": "2026-03-01", **kwargs}
        r = await self.client.post(
            f"{self._base}/practice/repertoires", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def create_practice_log(
        self, student_id: str, date: str, total_minutes: int, **kwargs
    ) -> str:
        payload = {"date": date, "total_minutes": total_minutes, **kwargs}
        r = await self.client.post(
            f"{self._base}/practice-logs/",
            headers=self.headers,
            params={"student_id": student_id},
            json=payload,
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def get_practice_stats(self, student_id: str, year: int, month: int) -> dict:
        r = await self.client.get(
            f"{self._base}/practice-logs/stats",
            headers=self.headers,
            params={"student_id": student_id, "year": year, "month": month},
        )
        assert r.status_code == 200
        return r.json()

    # -- Gamification ---------------------------------------------------------

    async def award_points(
        self, student_id: str, points: int, point_type: str, description: str
    ) -> dict:
        r = await self.client.post(
            f"{self._base}/gamification/points",
            headers=self.headers,
            json={
                "student_id": student_id,
                "points": points,
                "type": point_type,
                "description": description,
            },
        )
        assert r.status_code == 201
        return r.json()

    async def get_gamification(self, student_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/gamification/{student_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Feedback Presets & Resources -----------------------------------------

    async def create_feedback_preset(self, text: str, sort_order: int = 0) -> str:
        r = await self.client.post(
            f"{self._base}/settings/feedback-presets",
            headers=self.headers,
            json={"text": text, "sort_order": sort_order},
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def create_teaching_resource(self, title: str, **kwargs) -> str:
        payload = {"type": "youtube", "title": title, **kwargs}
        r = await self.client.post(
            f"{self._base}/settings/teaching-resources",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 201
        return r.json()["id"]

    # -- No-Show Records ------------------------------------------------------

    async def record_no_show(
        self, lesson_id: str, student_id: str, date: str, policy: str = "deductCredit", credits: int = 1
    ) -> dict:
        r = await self.client.post(
            f"{self._base}/groups/no-shows",
            headers=self.headers,
            json={
                "lesson_id": lesson_id,
                "student_id": student_id,
                "lesson_date": date,
                "applied_policy": policy,
                "deducted_credits": credits,
            },
        )
        assert r.status_code == 201
        return r.json()

    # -- Reviews --------------------------------------------------------------

    async def get_review_summary(self, teacher_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/reviews/{teacher_id}/summary", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    async def list_reviews(self, teacher_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/reviews/{teacher_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()


class StudentActions:
    """High-level actions a student performs in the app."""

    def __init__(self, client: AsyncClient, headers: dict[str, str]) -> None:
        self.client = client
        self.headers = headers
        self._base = "/api/v1"

    async def get_profile(self) -> dict:
        r = await self.client.get(f"{self._base}/users/me", headers=self.headers)
        assert r.status_code == 200
        return r.json()

    async def send_connection_request(
        self, target_id: str, method: str = "inAppSearch", **kwargs
    ) -> str:
        payload = {"target_id": target_id, "method": method, **kwargs}
        r = await self.client.post(
            f"{self._base}/invites/connection-requests",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def book_trial(
        self,
        teacher_id: str,
        *,
        date: str = "2026-03-25",
        time: str = "10:00",
        duration: int = 30,
        instrument: str = "violin",
    ) -> str:
        r = await self.client.post(
            f"{self._base}/bookings",
            headers=self.headers,
            json={
                "teacher_id": teacher_id,
                "lesson_type": "trial",
                "scheduled_date": date,
                "scheduled_time": time,
                "duration": duration,
                "instrument": instrument,
            },
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def accept_proposal(self, proposal_id: str, template_id: str) -> dict:
        r = await self.client.patch(
            f"{self._base}/subscriptions-proposals/{proposal_id}/respond",
            headers=self.headers,
            json={"action": "accept", "selected_template_id": template_id},
        )
        assert r.status_code == 200
        return r.json()

    async def reject_proposal(self, proposal_id: str, reason: str = "") -> dict:
        r = await self.client.patch(
            f"{self._base}/subscriptions-proposals/{proposal_id}/respond",
            headers=self.headers,
            json={"action": "reject", "rejection_reason": reason},
        )
        assert r.status_code == 200
        return r.json()

    async def write_review(
        self, teacher_id: str, rating: int, content: str = "", **kwargs
    ) -> str:
        payload = {"teacher_id": teacher_id, "rating": rating, "content": content, **kwargs}
        r = await self.client.post(
            f"{self._base}/reviews/", headers=self.headers, json=payload
        )
        assert r.status_code == 201
        return r.json()["id"]

    async def get_practice_logs(self, student_id: str, year: int, month: int) -> list:
        r = await self.client.get(
            f"{self._base}/practice-logs/",
            headers=self.headers,
            params={"student_id": student_id, "year": year, "month": month},
        )
        assert r.status_code == 200
        return r.json()

    async def get_gamification(self, student_id: str) -> dict:
        r = await self.client.get(
            f"{self._base}/gamification/{student_id}", headers=self.headers
        )
        assert r.status_code == 200
        return r.json()

    # -- Unified Lesson Requests -----------------------------------------------

    async def create_lesson_request(
        self,
        teacher_id: str,
        *,
        request_type: str = "trial",
        instrument: str = "violin",
        goal: str = "hobby",
        experience_level: str = "beginner",
        preferred_day: int | None = None,
        preferred_time: str | None = None,
        preferred_duration: int = 60,
        message: str | None = None,
        is_returning_student: bool = False,
    ) -> str:
        """Create a unified lesson request and return its ID."""
        payload: dict = {
            "teacher_id": teacher_id,
            "request_type": request_type,
            "instrument": instrument,
            "goal": goal,
            "experience_level": experience_level,
            "preferred_duration": preferred_duration,
            "is_returning_student": is_returning_student,
        }
        if preferred_day is not None:
            payload["preferred_day"] = preferred_day
        if preferred_time is not None:
            payload["preferred_time"] = preferred_time
        if message is not None:
            payload["message"] = message
        r = await self.client.post(
            f"{self._base}/schedule/lesson-requests",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 201, f"create_lesson_request failed: {r.status_code} {r.text}"
        return r.json()["id"]

    async def get_lesson_request(self, request_id: str) -> dict:
        """Get a single lesson request."""
        r = await self.client.get(
            f"{self._base}/schedule/lesson-requests/{request_id}",
            headers=self.headers,
        )
        assert r.status_code == 200
        return r.json()

    async def list_my_lesson_requests(self, student_id: str) -> dict:
        """List lesson requests sent by this student."""
        r = await self.client.get(
            f"{self._base}/schedule/lesson-requests",
            headers=self.headers,
            params={"student_id": student_id},
        )
        assert r.status_code == 200
        return r.json()

    async def accept_alternative(
        self,
        request_id: str,
        selected_slot_index: int,
        *,
        message: str | None = None,
    ) -> dict:
        """Student accepts one of the teacher's proposed alternative slots."""
        payload: dict = {"selected_slot_index": selected_slot_index}
        if message is not None:
            payload["message"] = message
        r = await self.client.post(
            f"{self._base}/schedule/lesson-requests/{request_id}/accept-alternative",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 200, f"accept_alternative failed: {r.status_code} {r.text}"
        return r.json()

    async def counter_propose(
        self,
        request_id: str,
        slot: dict,
        *,
        message: str | None = None,
    ) -> dict:
        """Student counter-proposes a different time slot."""
        payload: dict = {"slots": [slot]}
        if message is not None:
            payload["message"] = message
        r = await self.client.post(
            f"{self._base}/schedule/lesson-requests/{request_id}/counter-propose",
            headers=self.headers,
            json=payload,
        )
        assert r.status_code == 200, f"counter_propose failed: {r.status_code} {r.text}"
        return r.json()
