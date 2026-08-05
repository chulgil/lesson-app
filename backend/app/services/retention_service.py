"""Retention analytics — 재구매율 + 이탈 위험 학생 (#1216).

At-risk detection composes signals that already exist in the codebase rather than
introducing a new churn model:

* absence pattern — ``attendance_scheduler_service`` criterion (14 days, 2+ absences)
* imminent expiry — ``subscription_expiry_service`` D-day SSOT + ``EXPIRING_THRESHOLD_DAYS``
* practice drop  — PracticeLog volume, recent window vs the preceding window

재구매율 follows docs/specs/analytics/event_instrumentation.md §5.2: 수강권에는 자동
갱신이 없으므로 "만료 후 N일 내 입금이 확인된 학생 / 만료된 학생" 으로 센다. Wire 필드명
``renewal_rate`` 은 기존 FE 계약을 유지하기 위한 것이고, 의미는 재구매율이다.
"""

from __future__ import annotations

from collections import defaultdict
from datetime import date, timedelta

from dateutil.relativedelta import relativedelta
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.analytics import (
    AtRiskStudentResponse,
    MonthlyRenewalTrendResponse,
    RetentionAnalyticsResponse,
    TenureDistributionResponse,
)
from app.services.attendance_scheduler_service import (
    ABSENCE_PATTERN_MIN_COUNT,
    ABSENCE_PATTERN_WINDOW_DAYS,
    ABSENCE_STATUSES,
)
from app.services.subscription_expiry_service import (
    EXPIRING_THRESHOLD_DAYS,
    compute_days_left,
    compute_today_kst,
)

# Practice volume is compared over two adjacent windows of this length. Reusing the
# absence window keeps both signals describing the same recent stretch of time.
PRACTICE_WINDOW_DAYS = ABSENCE_PATTERN_WINDOW_DAYS

# #1216 default — the project had no prior practice-decline threshold. A student is
# flagged once recent practice volume sits at least 30% below the preceding window
# (roughly two lost practice days a week), which is well clear of week-to-week noise.
PRACTICE_DROP_THRESHOLD_PERCENT = -30.0

# 재구매율 관측 창 N — event_instrumentation.md §5.2 기본값.
REPURCHASE_WINDOW_DAYS = 30

# 재구매율·추이 집계 구간 (최근 6개월).
RETENTION_TREND_MONTHS = 6

_DAYS_PER_MONTH = 30.44

# (라벨, 상한 개월수). 상한 None = 마지막 버킷. 라벨은 spec §4.6 고정값.
_TENURE_BUCKETS: tuple[tuple[str, int | None], ...] = (
    ("0-3개월", 3),
    ("3-6개월", 6),
    ("6-12개월", 12),
    ("12개월+", None),
)

_RISK_LEVEL_BY_SIGNAL_COUNT = {3: "high", 2: "medium", 1: "low"}
_RISK_SORT_ORDER = {"high": 0, "medium": 1, "low": 2}


class RetentionService:
    """선생님 본인 학생에 한정한 재구매율·이탈 위험 집계."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_retention_analytics(self, teacher_id: str) -> RetentionAnalyticsResponse:
        """Return retention aggregates scoped to ``teacher_id``'s own students."""
        today = compute_today_kst()
        students = await self._active_students(teacher_id)
        trend_months = _trend_months(today)

        if not students:
            return RetentionAnalyticsResponse(
                renewal_rate=0.0,
                avg_subscription_months=0.0,
                at_risk_students=[],
                renewal_trend=[
                    MonthlyRenewalTrendResponse(month=month, expired=0, renewed=0) for month in trend_months
                ],
                tenure_distribution=[TenureDistributionResponse(label=label, count=0) for label, _ in _TENURE_BUCKETS],
            )

        # shortcut: 선생님 1명의 수강권 전량을 메모리에 올려 파이썬에서 집계한다. 천장은
        # 학생 수백 명 규모. 초과하면 만료/재구매를 SQL 집계로 승급.
        subscriptions = await self._subscriptions(list(students))

        at_risk = await self._build_at_risk(students, subscriptions, today)
        renewal_rate, renewal_trend = _repurchase_stats(subscriptions, today, trend_months)
        avg_months, tenure_distribution = _tenure_stats(students, subscriptions, today)

        return RetentionAnalyticsResponse(
            renewal_rate=renewal_rate,
            avg_subscription_months=avg_months,
            at_risk_students=at_risk,
            renewal_trend=renewal_trend,
            tenure_distribution=tenure_distribution,
        )

    async def _active_students(self, teacher_id: str) -> dict[str, str]:
        from app.models.student import Student

        rows = (
            await self.db.execute(
                select(Student.id, Student.name).where(
                    Student.teacher_id == teacher_id,
                    Student.is_active.is_(True),
                )
            )
        ).all()
        return {row.id: row.name for row in rows}

    async def _subscriptions(self, student_ids: list[str]) -> list:
        from app.models.subscription import Subscription

        return list(await self.db.scalars(select(Subscription).where(Subscription.student_id.in_(student_ids))))

    async def _build_at_risk(
        self,
        students: dict[str, str],
        subscriptions: list,
        today: date,
    ) -> list[AtRiskStudentResponse]:
        student_ids = list(students)
        absences = await self._absence_counts(student_ids, today)
        practice_drops = await self._practice_drop_percents(student_ids, today)
        last_lessons = await self._last_lesson_dates(student_ids, today)
        expiry_days = _days_until_expiry(subscriptions, today)

        at_risk: list[AtRiskStudentResponse] = []
        for student_id, name in students.items():
            days_left = expiry_days.get(student_id)
            drop_percent = practice_drops.get(student_id, 0.0)
            signals = (
                absences.get(student_id, 0) >= ABSENCE_PATTERN_MIN_COUNT,
                days_left is not None and days_left <= EXPIRING_THRESHOLD_DAYS,
                drop_percent <= PRACTICE_DROP_THRESHOLD_PERCENT,
            )
            fired = sum(signals)
            if not fired:
                continue
            at_risk.append(
                AtRiskStudentResponse(
                    student_id=student_id,
                    student_name=name,
                    days_until_expiry=days_left,
                    practice_drop_percent=round(drop_percent, 1),
                    last_lesson_date=last_lessons.get(student_id),
                    risk_level=_RISK_LEVEL_BY_SIGNAL_COUNT[fired],
                )
            )

        at_risk.sort(
            key=lambda item: (
                _RISK_SORT_ORDER[item.risk_level],
                item.days_until_expiry if item.days_until_expiry is not None else 10**6,
            )
        )
        return at_risk

    async def _absence_counts(self, student_ids: list[str], today: date) -> dict[str, int]:
        """Absences per student over the shared absence-pattern window."""
        from app.models.lesson import Lesson

        cutoff = today - timedelta(days=ABSENCE_PATTERN_WINDOW_DAYS)
        rows = (
            await self.db.execute(
                select(Lesson.student_id, func.count(Lesson.id))
                .where(
                    Lesson.student_id.in_(student_ids),
                    Lesson.status.in_([s.value for s in ABSENCE_STATUSES]),
                    Lesson.date >= cutoff,
                )
                .group_by(Lesson.student_id)
            )
        ).all()
        return {student_id: count for student_id, count in rows}

    async def _practice_drop_percents(self, student_ids: list[str], today: date) -> dict[str, float]:
        """Percent change of practice minutes, recent window vs the prior window."""
        from app.models.practice_log import PracticeLog

        recent_start = today - timedelta(days=PRACTICE_WINDOW_DAYS - 1)
        prior_start = today - timedelta(days=2 * PRACTICE_WINDOW_DAYS - 1)

        rows = (
            await self.db.execute(
                select(PracticeLog.student_id, PracticeLog.date, PracticeLog.total_minutes).where(
                    PracticeLog.student_id.in_(student_ids),
                    PracticeLog.date >= prior_start,
                    PracticeLog.date <= today,
                )
            )
        ).all()

        recent: dict[str, int] = defaultdict(int)
        prior: dict[str, int] = defaultdict(int)
        for student_id, log_date, minutes in rows:
            bucket = recent if log_date >= recent_start else prior
            bucket[student_id] += minutes or 0

        drops: dict[str, float] = {}
        for student_id in set(recent) | set(prior):
            before = prior.get(student_id, 0)
            if before <= 0:
                # 이전 창에 기록이 없으면 감소율을 정의할 수 없다 (0% 로 보고).
                drops[student_id] = 0.0
                continue
            drops[student_id] = (recent.get(student_id, 0) - before) / before * 100
        return drops

    async def _last_lesson_dates(self, student_ids: list[str], today: date) -> dict[str, date]:
        from app.models.lesson import Lesson

        rows = (
            await self.db.execute(
                select(Lesson.student_id, Lesson.date).where(
                    Lesson.student_id.in_(student_ids),
                    Lesson.date <= today,
                )
            )
        ).all()

        latest: dict[str, date] = {}
        for student_id, lesson_date in rows:
            current = latest.get(student_id)
            if current is None or lesson_date > current:
                latest[student_id] = lesson_date
        return latest


def _trend_months(today: date) -> list[date]:
    """First day of each month in the trailing ``RETENTION_TREND_MONTHS`` window."""
    first_of_month = today.replace(day=1)
    return [first_of_month - relativedelta(months=offset) for offset in reversed(range(RETENTION_TREND_MONTHS))]


def _days_until_expiry(subscriptions: list, today: date) -> dict[str, int]:
    """Days left on each student's soonest-expiring live subscription.

    Uses the subscription-expiry D-day SSOT so "임박" here means the same thing as the
    ``active -> expiringSoon`` transition.
    """
    from app.services.announcement_service import ACTIVE_SUBSCRIPTION_STATUSES

    soonest: dict[str, int] = {}
    for sub in subscriptions:
        if sub.status not in ACTIVE_SUBSCRIPTION_STATUSES:
            continue
        days_left = compute_days_left(sub, today_kst=today)
        if days_left is None or days_left < 0:
            continue
        current = soonest.get(sub.student_id)
        if current is None or days_left < current:
            soonest[sub.student_id] = days_left
    return soonest


def _confirmed_payment_at(sub) -> date | None:
    """입금 확인 시점 — 앱이 관측 가능한 유일한 결제 신호 (§5.2)."""
    if not sub.payment_confirmed:
        return None
    confirmed = sub.payment_confirmed_at or sub.paid_at
    return confirmed.date() if confirmed is not None else None


def _repurchase_stats(
    subscriptions: list, today: date, trend_months: list[date]
) -> tuple[float, list[MonthlyRenewalTrendResponse]]:
    """재구매율 + 월별 만료/재구매 추이 (§5.2).

    만료 시점은 ``end_date`` 를 사용한다. 횟수 소진(exhausted)에는 별도 타임스탬프가
    없어 소진 시각을 복원할 수 없다 — 문서화된 한계.
    """
    from app.models.subscription import SubscriptionStatus

    window_start = trend_months[0]
    expiries: list[tuple[str, date]] = []
    for sub in subscriptions:
        if sub.status == SubscriptionStatus.cancelled or not sub.payment_confirmed:
            continue
        end_date = sub.end_date
        if end_date is None or not (window_start <= end_date <= today):
            continue
        expiries.append((sub.student_id, end_date))

    payments_by_student: dict[str, list[date]] = defaultdict(list)
    for sub in subscriptions:
        confirmed_on = _confirmed_payment_at(sub)
        if confirmed_on is not None:
            payments_by_student[sub.student_id].append(confirmed_on)

    def _repurchased(student_id: str, expired_on: date) -> bool:
        deadline = expired_on + timedelta(days=REPURCHASE_WINDOW_DAYS)
        return any(expired_on < paid_on <= deadline for paid_on in payments_by_student.get(student_id, []))

    expired_students: set[str] = set()
    renewed_students: set[str] = set()
    monthly_expired: dict[tuple[int, int], set[str]] = defaultdict(set)
    monthly_renewed: dict[tuple[int, int], set[str]] = defaultdict(set)

    for student_id, expired_on in expiries:
        key = (expired_on.year, expired_on.month)
        expired_students.add(student_id)
        monthly_expired[key].add(student_id)
        if _repurchased(student_id, expired_on):
            renewed_students.add(student_id)
            monthly_renewed[key].add(student_id)

    # 만료 건이 없으면 비율을 정의할 수 없다 — 0.0 으로 보고한다.
    rate = len(renewed_students) / len(expired_students) if expired_students else 0.0

    trend = [
        MonthlyRenewalTrendResponse(
            month=month,
            expired=len(monthly_expired.get((month.year, month.month), ())),
            renewed=len(monthly_renewed.get((month.year, month.month), ())),
        )
        for month in trend_months
    ]
    return rate, trend


def _tenure_stats(
    students: dict[str, str], subscriptions: list, today: date
) -> tuple[float, list[TenureDistributionResponse]]:
    """평균 재적 개월수 + 재적 기간 분포 (첫 수강권 시작일 기준)."""
    first_start: dict[str, date] = {}
    for sub in subscriptions:
        if sub.student_id not in students or sub.start_date is None:
            continue
        current = first_start.get(sub.student_id)
        if current is None or sub.start_date < current:
            first_start[sub.student_id] = sub.start_date

    tenures = [max((today - started).days, 0) / _DAYS_PER_MONTH for started in first_start.values()]
    # 수강권 이력이 없는 학생은 재적 기간을 알 수 없어 분포에서 제외한다.
    avg_months = sum(tenures) / len(tenures) if tenures else 0.0

    counts = dict.fromkeys((label for label, _ in _TENURE_BUCKETS), 0)
    for months in tenures:
        for label, upper in _TENURE_BUCKETS:
            if upper is None or months < upper:
                counts[label] += 1
                break

    return round(avg_months, 1), [
        TenureDistributionResponse(label=label, count=counts[label]) for label, _ in _TENURE_BUCKETS
    ]
