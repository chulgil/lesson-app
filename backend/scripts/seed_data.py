"""Seed data script for local development.

Idempotent — safe to run multiple times.
Checks for teacher email existence before inserting.

Usage:
    uv run python scripts/seed_data.py
"""

from __future__ import annotations

import asyncio
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# ── Fixed IDs with seed- prefix for easy identification ────────────────
TEACHER_USER_ID = "seed-teacher-0001"
TEACHER_ID = "seed-teacher-prof-0001"

STUDENT1_USER_ID = "seed-student-user-0001"  # 김소연
STUDENT1_ID = "seed-student-0001"
STUDENT2_USER_ID = "seed-student-user-0002"  # 이준호
STUDENT2_ID = "seed-student-0002"
STUDENT3_USER_ID = "seed-student-user-0003"  # 최유진
STUDENT3_ID = "seed-student-0003"
STUDENT4_USER_ID = "seed-student-user-0004"  # 박지호
STUDENT4_ID = "seed-student-0004"
STUDENT5_USER_ID = "seed-student-user-0005"  # 한지수
STUDENT5_ID = "seed-student-0005"
STUDENT6_USER_ID = "seed-student-user-0006"  # 정하은
STUDENT6_ID = "seed-student-0006"
STUDENT7_USER_ID = "seed-student-user-0007"  # 한지민
STUDENT7_ID = "seed-student-0007"
STUDENT8_USER_ID = "seed-student-user-0008"  # 윤서준
STUDENT8_ID = "seed-student-0008"

PARENT_USER_ID = "seed-parent-0001"
PARENT_ID = "seed-parent-prof-0001"

MEMBERSHIP1_ID = "seed-membership-0001"  # 김소연 → 행복음악학원
MEMBERSHIP2_ID = "seed-membership-0002"  # 이준호 → 행복음악학원
MEMBERSHIP3_ID = "seed-membership-0003"  # 최유진 → 개인레슨
MEMBERSHIP4_ID = "seed-membership-0004"  # 박지호 → 행복음악학원
MEMBERSHIP5_ID = "seed-membership-0005"  # 한지수 → 개인레슨
MEMBERSHIP6_ID = "seed-membership-0006"  # 정하은 → 행복음악학원
MEMBERSHIP7_ID = "seed-membership-0007"  # 한지민 → 개인레슨
MEMBERSHIP8_ID = "seed-membership-0008"  # 윤서준 → 행복음악학원

TEACHER_EMAIL = "minyeon@example.com"
STUDENT1_EMAIL = "soyeon@example.com"
STUDENT2_EMAIL = "junho@example.com"
STUDENT3_EMAIL = "yujin@example.com"
STUDENT4_EMAIL = "jiho@example.com"
STUDENT5_EMAIL = "jisu@example.com"
STUDENT6_EMAIL = "haeun@example.com"
STUDENT7_EMAIL = "jimin@example.com"
STUDENT8_EMAIL = "seojun@example.com"
PARENT_EMAIL = "parent@example.com"


async def seed(db: AsyncSession) -> None:
    """Insert all seed data inside a single transaction."""
    from app.models.lesson import Lesson, LessonClass, ClassMembership, LessonStatus
    from app.models.notification import Notification, NotificationPriority
    from app.models.parent import (
        Parent,
        ParentChildRelation,
        ParentPermission,
        ParentStatus,
        ParentTeacherConnection,
    )
    from app.models.policy import LessonPolicy
    from app.models.practice import (
        PracticeGoal,
        PracticeRepertoire,
        PracticeSection,
        PracticeStreak,
        RangeType,
    )
    from app.models.relationship import (
        Follow,
        FollowTargetType,
        RelationStatus,
        TeacherStudentRelation,
    )
    from app.models.schedule import (
        AvailabilityTimeSlot,
        BookingLessonType,
        BookingStatus,
        LessonBooking,
        LessonRequest,
        RequestStatus,
        RequestTiming,
        TeacherAvailability,
    )
    from app.models.student import (
        AgeGroup,
        ConnectionStatus,
        Student,
        StudentLevel,
        StudentStatus,
    )
    from app.models.subscription import (
        BillingType,
        ProposalPaymentStatus,
        ProposalStatus,
        Subscription,
        SubscriptionProposal,
        SubscriptionStatus,
        SubscriptionTemplate,
        SubscriptionType,
        SubscriptionUsage,
        UsageType,
    )
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    # ── Idempotency check ────────────────────────────────────────────
    existing = await db.scalar(select(User).where(User.email == TEACHER_EMAIL))
    if existing:
        print(f"Seed data already exists (found user {existing.email}). Skipping.")
        return

    now = datetime.now(UTC)
    today = date.today()

    # ═══════════════════════════════════════════════════════════════════
    # 1. Teacher user + profile
    # ═══════════════════════════════════════════════════════════════════
    teacher_user = User(
        id=TEACHER_USER_ID,
        email=TEACHER_EMAIL,
        name="박미연",
        role=UserRole.teacher,
    )
    db.add(teacher_user)

    teacher = Teacher(
        id=TEACHER_ID,
        user_id=TEACHER_USER_ID,
        instruments=["바이올린"],
    )
    db.add(teacher)

    # NOTE: No education, career, fee, or lesson area data seeded.
    # Teachers should fill in their profile through the app.

    # ═══════════════════════════════════════════════════════════════════
    # 2. Lesson Policy
    # ═══════════════════════════════════════════════════════════════════
    policy = LessonPolicy(
        id="seed-policy-0001",
        teacher_id=TEACHER_ID,
        cancellation_deadline_hours=24,
        late_cancel_deducts_lesson=True,
        no_show_deducts_lesson=True,
        reschedule_allowed=True,
        reschedule_deadline_hours=24,
        max_reschedule_per_subscription=2,
        makeup_expiry_days=30,
        notes="레슨 24시간 전까지 취소/변경 가능합니다.",
    )
    db.add(policy)

    # ═══════════════════════════════════════════════════════════════════
    # 3. Teacher Availability (Tue/Thu/Sat 10:00-18:00)
    # ═══════════════════════════════════════════════════════════════════
    for day in [1, 3, 5]:  # Tuesday, Thursday, Saturday
        avail_id = f"seed-avail-{day}"
        avail = TeacherAvailability(
            id=avail_id,
            teacher_id=TEACHER_ID,
            day_of_week=day,
        )
        db.add(avail)
        slot = AvailabilityTimeSlot(
            id=f"seed-slot-{day}",
            availability_id=avail_id,
            start_time="10:00",
            end_time="18:00",
            is_available=True,
        )
        db.add(slot)

    # ═══════════════════════════════════════════════════════════════════
    # 4. Subscription Templates (4개: 4회/8회/16회 패키지 + 월 4회)
    # ═══════════════════════════════════════════════════════════════════
    template_pkg4 = SubscriptionTemplate(
        id="seed-tmpl-0001",
        teacher_id=TEACHER_ID,
        name="4레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=4,
        amount=300000,
        description="바이올린 개인레슨 4회 패키지 (회당 75,000원)",
    )
    template_pkg8 = SubscriptionTemplate(
        id="seed-tmpl-0002",
        teacher_id=TEACHER_ID,
        name="8레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=8,
        amount=560000,
        description="바이올린 개인레슨 8회 패키지 (회당 70,000원)",
    )
    template_pkg16 = SubscriptionTemplate(
        id="seed-tmpl-0003",
        teacher_id=TEACHER_ID,
        name="16레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=16,
        amount=1040000,
        description="바이올린 개인레슨 16회 패키지 (회당 65,000원)",
    )
    template_monthly = SubscriptionTemplate(
        id="seed-tmpl-0004",
        teacher_id=TEACHER_ID,
        name="월간 4레슨",
        type=SubscriptionType.monthly,
        lessons_per_month=4,
        duration_months=1,
        amount=280000,
        description="매월 4회 정기 레슨 (회당 70,000원)",
    )
    db.add(template_pkg4)
    db.add(template_pkg8)
    db.add(template_pkg16)
    db.add(template_monthly)

    # ═══════════════════════════════════════════════════════════════════
    # 5. Lesson Classes (행복음악학원 + 개인레슨)
    # ═══════════════════════════════════════════════════════════════════
    lesson_class_academy = LessonClass(
        id="seed-class-0001",
        teacher_id=TEACHER_ID,
        name="행복음악학원",
        sort_order=0,
    )
    lesson_class_private = LessonClass(
        id="seed-class-0002",
        teacher_id=TEACHER_ID,
        name="개인레슨",
        sort_order=1,
    )
    db.add(lesson_class_academy)
    db.add(lesson_class_private)

    # ═══════════════════════════════════════════════════════════════════
    # 6. Student users (all 8 have login accounts)
    # ═══════════════════════════════════════════════════════════════════
    student1_user = User(
        id=STUDENT1_USER_ID,
        email=STUDENT1_EMAIL,
        name="김소연",
        role=UserRole.student,
    )
    student2_user = User(
        id=STUDENT2_USER_ID,
        email=STUDENT2_EMAIL,
        name="이준호",
        role=UserRole.student,
    )
    student3_user = User(
        id=STUDENT3_USER_ID,
        email=STUDENT3_EMAIL,
        name="최유진",
        role=UserRole.student,
    )
    student4_user = User(
        id=STUDENT4_USER_ID,
        email=STUDENT4_EMAIL,
        name="박지호",
        role=UserRole.student,
    )
    student5_user = User(
        id=STUDENT5_USER_ID,
        email=STUDENT5_EMAIL,
        name="한지수",
        role=UserRole.student,
    )
    student6_user = User(
        id=STUDENT6_USER_ID,
        email=STUDENT6_EMAIL,
        name="정하은",
        role=UserRole.student,
    )
    student7_user = User(
        id=STUDENT7_USER_ID,
        email=STUDENT7_EMAIL,
        name="한지민",
        role=UserRole.student,
    )
    student8_user = User(
        id=STUDENT8_USER_ID,
        email=STUDENT8_EMAIL,
        name="윤서준",
        role=UserRole.student,
    )
    db.add(student1_user)
    db.add(student2_user)
    db.add(student3_user)
    db.add(student4_user)
    db.add(student5_user)
    db.add(student6_user)
    db.add(student7_user)
    db.add(student8_user)

    # ═══════════════════════════════════════════════════════════════════
    # 7. Students (teacher-side profiles)
    # ═══════════════════════════════════════════════════════════════════

    # ① 김소연 — intermediate, active, 풍부한 데이터
    student1 = Student(
        id=STUDENT1_ID,
        user_id=STUDENT1_USER_ID,
        teacher_id=TEACHER_ID,
        name="김소연",
        instrument="바이올린",
        level=StudentLevel.intermediate,
        status=StudentStatus.active,
        age_group=AgeGroup.student,
        email=STUDENT1_EMAIL,
        lessons_per_week=1,
        lesson_day="Monday",
        lesson_time="14:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )

    # ② 이준호 — beginner, active, 보통 데이터
    student2 = Student(
        id=STUDENT2_ID,
        user_id=STUDENT2_USER_ID,
        teacher_id=TEACHER_ID,
        name="이준호",
        instrument="바이올린",
        level=StudentLevel.beginner,
        status=StudentStatus.active,
        age_group=AgeGroup.child,
        email=STUDENT2_EMAIL,
        lessons_per_week=1,
        lesson_day="Wednesday",
        lesson_time="15:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )

    # ③ 최유진 — beginner, trial, 최소 데이터
    student3 = Student(
        id=STUDENT3_ID,
        user_id=STUDENT3_USER_ID,
        teacher_id=TEACHER_ID,
        name="최유진",
        instrument="플루트",
        level=StudentLevel.beginner,
        status=StudentStatus.trial,
        age_group=AgeGroup.student,
        email=STUDENT3_EMAIL,
        lessons_per_week=1,
        lesson_duration=45,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )

    # ④ 박지호 — intermediate, active, 첼로
    student4 = Student(
        id=STUDENT4_ID,
        user_id=STUDENT4_USER_ID,
        teacher_id=TEACHER_ID,
        name="박지호",
        instrument="첼로",
        level=StudentLevel.intermediate,
        status=StudentStatus.active,
        age_group=AgeGroup.adult,
        email=STUDENT4_EMAIL,
        lessons_per_week=2,
        lesson_day="Tuesday",
        lesson_time="16:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )

    # ⑤ 한지수 — advanced, inactive, 바이올린
    student5 = Student(
        id=STUDENT5_ID,
        user_id=STUDENT5_USER_ID,
        teacher_id=TEACHER_ID,
        name="한지수",
        instrument="바이올린",
        level=StudentLevel.advanced,
        status=StudentStatus.inactive,
        age_group=AgeGroup.adult,
        email=STUDENT5_EMAIL,
        lessons_per_week=1,
        lesson_day="Thursday",
        lesson_time="17:00",
        lesson_duration=60,
        monthly_fee=80000,
        connection_status=ConnectionStatus.connected,
        connected_at=now - timedelta(days=60),
    )

    # ⑥ 정하은 — beginner, paused, 클라리넷
    student6 = Student(
        id=STUDENT6_ID,
        user_id=STUDENT6_USER_ID,
        teacher_id=TEACHER_ID,
        name="정하은",
        instrument="클라리넷",
        level=StudentLevel.beginner,
        status=StudentStatus.paused,
        age_group=AgeGroup.student,
        email=STUDENT6_EMAIL,
        lessons_per_week=1,
        lesson_day="Friday",
        lesson_time="14:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now - timedelta(days=30),
        break_reason="시험 기간 휴식",
        expected_return_date=today + timedelta(days=14),
    )

    # ⑦ 한지민 — beginner, inactive, 피아노
    student7 = Student(
        id=STUDENT7_ID,
        user_id=STUDENT7_USER_ID,
        teacher_id=TEACHER_ID,
        name="한지민",
        instrument="피아노",
        level=StudentLevel.beginner,
        status=StudentStatus.inactive,
        age_group=AgeGroup.child,
        email=STUDENT7_EMAIL,
        lessons_per_week=1,
        lesson_duration=45,
        connection_status=ConnectionStatus.connected,
        connected_at=now - timedelta(days=90),
    )

    # ⑧ 윤서준 — beginner, inactive, 첼로
    student8 = Student(
        id=STUDENT8_ID,
        user_id=STUDENT8_USER_ID,
        teacher_id=TEACHER_ID,
        name="윤서준",
        instrument="첼로",
        level=StudentLevel.beginner,
        status=StudentStatus.inactive,
        age_group=AgeGroup.child,
        email=STUDENT8_EMAIL,
        lessons_per_week=1,
        lesson_duration=60,
        connection_status=ConnectionStatus.connected,
        connected_at=now - timedelta(days=120),
    )

    db.add(student1)
    db.add(student2)
    db.add(student3)
    db.add(student4)
    db.add(student5)
    db.add(student6)
    db.add(student7)
    db.add(student8)

    # ═══════════════════════════════════════════════════════════════════
    # 8. Class Memberships
    # ═══════════════════════════════════════════════════════════════════
    # 행복음악학원: 김소연, 이준호, 박지호, 정하은, 윤서준
    db.add(ClassMembership(
        id=MEMBERSHIP1_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT1_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP2_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT2_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP4_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT4_ID,
        instrument="첼로",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP6_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT6_ID,
        instrument="클라리넷",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP8_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT8_ID,
        instrument="첼로",
    ))
    # 개인레슨: 최유진, 한지수, 한지민
    db.add(ClassMembership(
        id=MEMBERSHIP3_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT3_ID,
        instrument="플루트",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP5_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT5_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP7_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT7_ID,
        instrument="피아노",
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 9. Teacher-Student Relations (all 8)
    # ═══════════════════════════════════════════════════════════════════
    all_student_ids = [
        STUDENT1_ID, STUDENT2_ID, STUDENT3_ID, STUDENT4_ID,
        STUDENT5_ID, STUDENT6_ID, STUDENT7_ID, STUDENT8_ID,
    ]
    for i, sid in enumerate(all_student_ids, 1):
        db.add(TeacherStudentRelation(
            id=f"seed-rel-{i:04d}",
            teacher_id=TEACHER_ID,
            student_id=sid,
            status=RelationStatus.active,
            connected_at=now,
        ))

    # ═══════════════════════════════════════════════════════════════════
    # 10. Subscriptions (8 total: 2 existing + 6 new)
    # ═══════════════════════════════════════════════════════════════════

    # 김소연: package 10회 중 5회 사용 (active)
    sub1 = Subscription(
        id="seed-sub-0001",
        student_id=STUDENT1_ID,
        membership_id=MEMBERSHIP1_ID,
        type=SubscriptionType.package,
        total_lessons=10,
        used_lessons=5,
        start_date=today - timedelta(days=30),
        end_date=today + timedelta(days=60),
        amount=700000,
        status=SubscriptionStatus.active,
        billing_type=BillingType.perPackage,
    )

    # 이준호: monthly 4회/월, 1회 사용 (active)
    sub2 = Subscription(
        id="seed-sub-0002",
        student_id=STUDENT2_ID,
        membership_id=MEMBERSHIP2_ID,
        type=SubscriptionType.monthly,
        total_lessons=4,
        used_lessons=1,
        lessons_per_month=4,
        start_date=today.replace(day=1),
        end_date=(today.replace(day=1) + timedelta(days=32)).replace(day=1) - timedelta(days=1),
        amount=280000,
        status=SubscriptionStatus.active,
        billing_type=BillingType.monthly,
    )

    # 한지수: package 8회 중 2회 사용 (active — proposal 확정 수강권)
    sub3 = Subscription(
        id="seed-sub-0003",
        student_id=STUDENT5_ID,
        membership_id=MEMBERSHIP5_ID,
        type=SubscriptionType.package,
        total_lessons=8,
        used_lessons=2,
        start_date=today - timedelta(days=15),
        end_date=today + timedelta(days=75),
        amount=560000,
        status=SubscriptionStatus.active,
        billing_type=BillingType.perPackage,
    )

    # 김소연: package 4회 만료 (expired — 이전 히스토리)
    sub4 = Subscription(
        id="seed-sub-0004",
        student_id=STUDENT1_ID,
        membership_id=MEMBERSHIP1_ID,
        type=SubscriptionType.package,
        total_lessons=4,
        used_lessons=4,
        start_date=today - timedelta(days=120),
        end_date=today - timedelta(days=31),
        amount=300000,
        status=SubscriptionStatus.expired,
        billing_type=BillingType.perPackage,
    )

    # 이준호: trial 1회 만료 (expired — 체험 완료)
    sub5 = Subscription(
        id="seed-sub-0005",
        student_id=STUDENT2_ID,
        membership_id=MEMBERSHIP2_ID,
        type=SubscriptionType.trial,
        total_lessons=1,
        used_lessons=1,
        start_date=today - timedelta(days=60),
        end_date=today - timedelta(days=30),
        amount=0,
        status=SubscriptionStatus.expired,
    )

    # 박지호: package 8회 중 7회 사용 (expiringSoon)
    sub6 = Subscription(
        id="seed-sub-0006",
        student_id=STUDENT4_ID,
        membership_id=MEMBERSHIP4_ID,
        type=SubscriptionType.package,
        total_lessons=8,
        used_lessons=7,
        start_date=today - timedelta(days=45),
        end_date=today + timedelta(days=15),
        amount=560000,
        status=SubscriptionStatus.expiringSoon,
        billing_type=BillingType.perPackage,
    )

    # 최유진: trial 1회 (active — 체험 대기)
    sub7 = Subscription(
        id="seed-sub-0007",
        student_id=STUDENT3_ID,
        membership_id=MEMBERSHIP3_ID,
        type=SubscriptionType.trial,
        total_lessons=1,
        used_lessons=0,
        start_date=today,
        end_date=today + timedelta(days=30),
        amount=0,
        status=SubscriptionStatus.active,
    )

    # 정하은: package 4회 중 1회 사용 (active — 미수금)
    sub8 = Subscription(
        id="seed-sub-0008",
        student_id=STUDENT6_ID,
        membership_id=MEMBERSHIP6_ID,
        type=SubscriptionType.package,
        total_lessons=4,
        used_lessons=1,
        start_date=today - timedelta(days=10),
        end_date=today + timedelta(days=80),
        amount=300000,
        status=SubscriptionStatus.active,
        billing_type=BillingType.perPackage,
        payment_confirmed=False,
    )

    db.add(sub1)
    db.add(sub2)
    db.add(sub3)
    db.add(sub4)
    db.add(sub5)
    db.add(sub6)
    db.add(sub7)
    db.add(sub8)

    # ═══════════════════════════════════════════════════════════════════
    # 11. Subscription Usages
    # ═══════════════════════════════════════════════════════════════════

    # ── 김소연 sub1: 5 usages (3 lessons + 1 cancelled + 1 no-show) ──
    soyeon_usage_data = [
        ("seed-usage-0001", "seed-lesson-0001", today - timedelta(days=21)),
        ("seed-usage-0002", "seed-lesson-0002", today - timedelta(days=14)),
        ("seed-usage-0003", "seed-lesson-0003", today - timedelta(days=7)),
        ("seed-usage-0004", "seed-lesson-0006", today - timedelta(days=3)),  # cancelled
    ]
    for uid, lid, used_at_date in soyeon_usage_data:
        db.add(SubscriptionUsage(
            id=uid,
            subscription_id="seed-sub-0001",
            lesson_id=lid,
            used_at=datetime.combine(used_at_date, datetime.min.time()).replace(tzinfo=UTC),
            teacher_name="박미연",
            instrument="바이올린",
            type=UsageType.lesson if uid != "seed-usage-0004" else UsageType.cancellationPenalty,
        ))
    # 5th usage: manual adjustment
    db.add(SubscriptionUsage(
        id="seed-usage-0005",
        subscription_id="seed-sub-0001",
        used_at=datetime.combine(today - timedelta(days=10), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="바이올린",
        type=UsageType.noShow,
    ))

    # ── 이준호 sub2: 1 usage (1 completed lesson) ──
    db.add(SubscriptionUsage(
        id="seed-usage-0006",
        subscription_id="seed-sub-0002",
        lesson_id="seed-lesson-0007",
        used_at=datetime.combine(today - timedelta(days=5), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="바이올린",
        type=UsageType.lesson,
    ))

    # ── 한지수 sub3: 2 usages (historical) ──
    db.add(SubscriptionUsage(
        id="seed-usage-0007",
        subscription_id="seed-sub-0003",
        used_at=datetime.combine(today - timedelta(days=12), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="바이올린",
        type=UsageType.lesson,
    ))
    db.add(SubscriptionUsage(
        id="seed-usage-0008",
        subscription_id="seed-sub-0003",
        used_at=datetime.combine(today - timedelta(days=5), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="바이올린",
        type=UsageType.lesson,
    ))

    # ── 김소연 sub4 (expired): 4 usages ──
    for i, days_ago in enumerate([110, 100, 90, 80], start=9):
        db.add(SubscriptionUsage(
            id=f"seed-usage-{i:04d}",
            subscription_id="seed-sub-0004",
            used_at=datetime.combine(today - timedelta(days=days_ago), datetime.min.time()).replace(tzinfo=UTC),
            teacher_name="박미연",
            instrument="바이올린",
            type=UsageType.lesson,
        ))

    # ── 이준호 sub5 (trial expired): 1 usage ──
    db.add(SubscriptionUsage(
        id="seed-usage-0013",
        subscription_id="seed-sub-0005",
        used_at=datetime.combine(today - timedelta(days=55), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="바이올린",
        type=UsageType.lesson,
    ))

    # ── 박지호 sub6 (expiringSoon): 7 usages (6 lessons + 1 cancellation) ──
    jiho_lesson_dates = [
        today - timedelta(days=40),
        today - timedelta(days=35),
        today - timedelta(days=28),
        today - timedelta(days=21),
        today - timedelta(days=14),
        today - timedelta(days=7),
    ]
    for i, d in enumerate(jiho_lesson_dates, start=14):
        db.add(SubscriptionUsage(
            id=f"seed-usage-{i:04d}",
            subscription_id="seed-sub-0006",
            lesson_id=f"seed-lesson-{(i - 14 + 10):04d}",
            used_at=datetime.combine(d, datetime.min.time()).replace(tzinfo=UTC),
            teacher_name="박미연",
            instrument="첼로",
            type=UsageType.lesson,
        ))
    db.add(SubscriptionUsage(
        id="seed-usage-0020",
        subscription_id="seed-sub-0006",
        lesson_id="seed-lesson-0016",
        used_at=datetime.combine(today - timedelta(days=1), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="첼로",
        type=UsageType.cancellationPenalty,
    ))

    # ── 정하은 sub8: 1 usage ──
    db.add(SubscriptionUsage(
        id="seed-usage-0021",
        subscription_id="seed-sub-0008",
        lesson_id="seed-lesson-0018",
        used_at=datetime.combine(today - timedelta(days=5), datetime.min.time()).replace(tzinfo=UTC),
        teacher_name="박미연",
        instrument="클라리넷",
        type=UsageType.lesson,
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 12. Lessons (19 total: 9 existing + 10 new)
    # ═══════════════════════════════════════════════════════════════════

    # ── 김소연 (6 lessons) ──
    # completed -21d
    db.add(Lesson(
        id="seed-lesson-0001",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today - timedelta(days=21),
        start_time="14:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="기본기가 안정되고 있어요. 스케일 연습을 꾸준히 해주세요.",
        key_points=["스케일 연습", "자세 교정"],
    ))
    # completed -14d
    db.add(Lesson(
        id="seed-lesson-0002",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today - timedelta(days=14),
        start_time="14:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="음정이 많이 좋아졌어요. 비브라토 연습을 좀 더 해봅시다.",
        key_points=["음정 개선", "비브라토 연습"],
    ))
    # completed -7d
    db.add(Lesson(
        id="seed-lesson-0003",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today - timedelta(days=7),
        start_time="14:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="샤콘느 도입부 완성도가 높아졌습니다. 전개부로 넘어갑시다.",
        key_points=["샤콘느 도입부 완성", "전개부 시작"],
    ))
    # scheduled +7d
    db.add(Lesson(
        id="seed-lesson-0004",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today + timedelta(days=7),
        start_time="14:00",
        duration=60,
        status=LessonStatus.scheduled,
    ))
    # scheduled +14d
    db.add(Lesson(
        id="seed-lesson-0005",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today + timedelta(days=14),
        start_time="14:00",
        duration=60,
        status=LessonStatus.scheduled,
    ))
    # cancelled -3d
    db.add(Lesson(
        id="seed-lesson-0006",
        student_id=STUDENT1_ID,
        teacher_id=TEACHER_ID,
        student_name="김소연",
        teacher_name="박미연",
        instrument="바이올린",
        date=today - timedelta(days=3),
        start_time="14:00",
        duration=60,
        status=LessonStatus.cancelled,
    ))

    # ── 이준호 (2 lessons) ──
    # completed -5d
    db.add(Lesson(
        id="seed-lesson-0007",
        student_id=STUDENT2_ID,
        teacher_id=TEACHER_ID,
        student_name="이준호",
        teacher_name="박미연",
        instrument="바이올린",
        date=today - timedelta(days=5),
        start_time="15:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="활 잡는 자세가 좋아지고 있어요. 다음 시간에 D장조 스케일 연습합시다.",
    ))
    # scheduled +2d
    db.add(Lesson(
        id="seed-lesson-0008",
        student_id=STUDENT2_ID,
        teacher_id=TEACHER_ID,
        student_name="이준호",
        teacher_name="박미연",
        instrument="바이올린",
        date=today + timedelta(days=2),
        start_time="15:00",
        duration=60,
        status=LessonStatus.scheduled,
    ))

    # ── 최유진 (1 lesson — 체험) ──
    # scheduled +5d
    db.add(Lesson(
        id="seed-lesson-0009",
        student_id=STUDENT3_ID,
        teacher_id=TEACHER_ID,
        student_name="최유진",
        teacher_name="박미연",
        instrument="플루트",
        date=today + timedelta(days=5),
        start_time="11:00",
        duration=45,
        status=LessonStatus.scheduled,
    ))

    # ── 박지호 (8 lessons) ──
    # completed -40d
    db.add(Lesson(
        id="seed-lesson-0010",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=40),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="첼로 기본 자세가 안정되어가고 있습니다. 활 압력 조절에 주의하세요.",
        key_points=["기본 자세", "활 압력"],
    ))
    # completed -35d
    db.add(Lesson(
        id="seed-lesson-0011",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=35),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="C장조 스케일이 안정적입니다. 다음 시간에 G장조 시작합시다.",
        key_points=["C장조 스케일", "음정 안정"],
    ))
    # completed -28d
    db.add(Lesson(
        id="seed-lesson-0012",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=28),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="G장조 스케일 진행이 좋습니다. 셋째줄 음정에 집중해주세요.",
        key_points=["G장조 스케일", "3포지션"],
    ))
    # completed -21d
    db.add(Lesson(
        id="seed-lesson-0013",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=21),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="에튀드 1번 완성도가 높아졌습니다. 다이나믹 표현을 더 연습합시다.",
        key_points=["에튀드 완성", "다이나믹"],
    ))
    # completed -14d
    db.add(Lesson(
        id="seed-lesson-0014",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=14),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="비브라토 기초가 자리잡고 있어요. 느린 템포에서 꾸준히 연습하세요.",
        key_points=["비브라토 기초", "느린 템포 연습"],
    ))
    # completed -7d
    db.add(Lesson(
        id="seed-lesson-0015",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=7),
        start_time="16:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="소나타 1악장 전반부 연습 잘 해왔습니다.",
        key_points=["소나타 1악장", "전반부 완성"],
    ))
    # cancelled -1d
    db.add(Lesson(
        id="seed-lesson-0016",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today - timedelta(days=1),
        start_time="16:00",
        duration=60,
        status=LessonStatus.cancelled,
    ))
    # scheduled +4d
    db.add(Lesson(
        id="seed-lesson-0017",
        student_id=STUDENT4_ID,
        teacher_id=TEACHER_ID,
        student_name="박지호",
        teacher_name="박미연",
        instrument="첼로",
        date=today + timedelta(days=4),
        start_time="16:00",
        duration=60,
        status=LessonStatus.scheduled,
    ))

    # ── 정하은 (2 lessons) ──
    # completed -5d
    db.add(Lesson(
        id="seed-lesson-0018",
        student_id=STUDENT6_ID,
        teacher_id=TEACHER_ID,
        student_name="정하은",
        teacher_name="박미연",
        instrument="클라리넷",
        date=today - timedelta(days=5),
        start_time="14:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="앙부슈어가 좋아지고 있어요. 호흡 연습을 더 해봅시다.",
        key_points=["앙부슈어", "호흡 연습"],
    ))
    # scheduled +3d
    db.add(Lesson(
        id="seed-lesson-0019",
        student_id=STUDENT6_ID,
        teacher_id=TEACHER_ID,
        student_name="정하은",
        teacher_name="박미연",
        instrument="클라리넷",
        date=today + timedelta(days=3),
        start_time="14:00",
        duration=60,
        status=LessonStatus.scheduled,
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 13. Subscription Proposals (7)
    # ═══════════════════════════════════════════════════════════════════

    # pending — auto, 김소연 (수강권 갱신 자동 제안)
    db.add(SubscriptionProposal(
        id="seed-proposal-0001",
        teacher_id=TEACHER_ID,
        student_id=STUDENT1_ID,
        template_id="seed-tmpl-0002",
        message="수강권이 곧 소진됩니다. 8레슨 패키지로 갱신해 주세요.",
        status=ProposalStatus.pending,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now + timedelta(days=7),
        is_auto_proposal=True,
        created_at=now - timedelta(days=1),
    ))

    # pending — auto, 박지호 (수강권 만료 임박)
    db.add(SubscriptionProposal(
        id="seed-proposal-0002",
        teacher_id=TEACHER_ID,
        student_id=STUDENT4_ID,
        template_id="seed-tmpl-0001",
        message="수강권이 1회 남았습니다. 4레슨 패키지로 갱신해 주세요.",
        status=ProposalStatus.pending,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now + timedelta(days=7),
        is_auto_proposal=True,
        created_at=now - timedelta(hours=12),
    ))

    # pending — manual, 이준호
    db.add(SubscriptionProposal(
        id="seed-proposal-0003",
        teacher_id=TEACHER_ID,
        student_id=STUDENT2_ID,
        template_id="seed-tmpl-0002",
        message="체험 레슨 이후 정규 수강을 추천드립니다.",
        status=ProposalStatus.pending,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now + timedelta(days=14),
        is_auto_proposal=False,
        created_at=now - timedelta(days=2),
    ))

    # pending — manual, 한지민
    db.add(SubscriptionProposal(
        id="seed-proposal-0004",
        teacher_id=TEACHER_ID,
        student_id=STUDENT7_ID,
        template_id="seed-tmpl-0001",
        message="피아노 레슨을 시작해 보시겠어요?",
        status=ProposalStatus.pending,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now + timedelta(days=14),
        is_auto_proposal=False,
        created_at=now - timedelta(days=3),
    ))

    # paymentNotified — 정하은
    db.add(SubscriptionProposal(
        id="seed-proposal-0005",
        teacher_id=TEACHER_ID,
        student_id=STUDENT6_ID,
        template_id="seed-tmpl-0002",
        message="클라리넷 8레슨 패키지를 제안합니다.",
        status=ProposalStatus.paymentNotified,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now + timedelta(days=5),
        payment_notified_at=now - timedelta(days=2),
        is_auto_proposal=False,
        created_at=now - timedelta(days=4),
    ))

    # confirmed — 한지수 (sub3과 연결)
    db.add(SubscriptionProposal(
        id="seed-proposal-0006",
        teacher_id=TEACHER_ID,
        student_id=STUDENT5_ID,
        template_id="seed-tmpl-0002",
        message="바이올린 8레슨 패키지를 제안합니다.",
        status=ProposalStatus.confirmed,
        payment_status=ProposalPaymentStatus.completed,
        expires_at=now - timedelta(days=5),
        confirmed_at=now - timedelta(days=10),
        subscription_id="seed-sub-0003",
        is_auto_proposal=False,
        created_at=now - timedelta(days=20),
    ))

    # rejected — 윤서준
    db.add(SubscriptionProposal(
        id="seed-proposal-0007",
        teacher_id=TEACHER_ID,
        student_id=STUDENT8_ID,
        template_id="seed-tmpl-0001",
        message="첼로 4레슨 패키지를 제안합니다.",
        status=ProposalStatus.rejected,
        payment_status=ProposalPaymentStatus.pending,
        expires_at=now - timedelta(days=3),
        rejected_at=now - timedelta(days=5),
        rejection_reason="다른 선생님 수업을 받기로 했습니다.",
        is_auto_proposal=False,
        created_at=now - timedelta(days=15),
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 14. Lesson Requests (5)
    # ═══════════════════════════════════════════════════════════════════

    # pending — 한지민
    db.add(LessonRequest(
        id="seed-request-0001",
        student_id=STUDENT7_ID,
        teacher_id=TEACHER_ID,
        message="피아노 개인레슨 받고 싶습니다. 기초부터 배우고 싶어요.",
        preferred_timing=RequestTiming.nextWeek,
        status=RequestStatus.pending,
        expires_at=now + timedelta(days=7),
        created_at=now - timedelta(days=1),
    ))

    # pending — 윤서준
    db.add(LessonRequest(
        id="seed-request-0002",
        student_id=STUDENT8_ID,
        teacher_id=TEACHER_ID,
        message="첼로 레슨을 다시 시작하고 싶습니다.",
        preferred_timing=RequestTiming.afterConsultation,
        status=RequestStatus.pending,
        expires_at=now + timedelta(days=7),
        created_at=now - timedelta(hours=6),
    ))

    # proposalSent — 한지수 (proposal-0006와 연결)
    db.add(LessonRequest(
        id="seed-request-0003",
        student_id=STUDENT5_ID,
        teacher_id=TEACHER_ID,
        message="바이올린 레슨을 다시 시작하고 싶습니다.",
        preferred_timing=RequestTiming.nextMonth,
        status=RequestStatus.proposalSent,
        expires_at=now + timedelta(days=14),
        proposal_id="seed-proposal-0006",
        status_updated_at=now - timedelta(days=20),
        created_at=now - timedelta(days=25),
    ))

    # declined — 한지민 (이전 요청)
    db.add(LessonRequest(
        id="seed-request-0004",
        student_id=STUDENT7_ID,
        teacher_id=TEACHER_ID,
        message="피아노 그룹 레슨 문의드립니다.",
        preferred_timing=RequestTiming.nextWeek,
        status=RequestStatus.declined,
        expires_at=now - timedelta(days=7),
        decline_reason="현재 그룹 레슨은 모집이 마감되었습니다.",
        status_updated_at=now - timedelta(days=14),
        created_at=now - timedelta(days=21),
    ))

    # expired — 윤서준 (이전 요청)
    db.add(LessonRequest(
        id="seed-request-0005",
        student_id=STUDENT8_ID,
        teacher_id=TEACHER_ID,
        message="첼로 체험 레슨 받아볼 수 있을까요?",
        preferred_timing=RequestTiming.nextWeek,
        status=RequestStatus.expired,
        expires_at=now - timedelta(days=1),
        created_at=now - timedelta(days=30),
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 15. Lesson Bookings (2)
    # ═══════════════════════════════════════════════════════════════════

    # 최유진 — 체험예약 (pending)
    db.add(LessonBooking(
        id="seed-booking-0001",
        teacher_id=TEACHER_ID,
        student_id=STUDENT3_ID,
        lesson_type=BookingLessonType.trial,
        scheduled_date=today + timedelta(days=5),
        scheduled_time="11:00",
        duration=45,
        instrument="플루트",
        status=BookingStatus.pending,
        notes="플루트 체험 레슨 희망",
    ))

    # 박지호 — 정규예약 (approved)
    db.add(LessonBooking(
        id="seed-booking-0002",
        teacher_id=TEACHER_ID,
        student_id=STUDENT4_ID,
        lesson_type=BookingLessonType.regular,
        scheduled_date=today + timedelta(days=4),
        scheduled_time="16:00",
        duration=60,
        instrument="첼로",
        status=BookingStatus.approved,
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 16. Practice
    # ═══════════════════════════════════════════════════════════════════

    # ── 김소연 (existing) ──
    repertoire = PracticeRepertoire(
        id="seed-rep-0001",
        student_id=STUDENT1_ID,
        name="바흐 파르티타 2번",
        description="BWV 1004 — 샤콘느 중심 연습",
        start_date=today - timedelta(days=30),
        is_default=True,
    )
    db.add(repertoire)

    section1 = PracticeSection(
        id="seed-sec-0001",
        repertoire_id="seed-rep-0001",
        piece_name="샤콘느",
        range_type=RangeType.measures,
        start_measure=1,
        end_measure=32,
        section_name="도입부",
        sort_order=0,
        start_date=today - timedelta(days=30),
    )
    section2 = PracticeSection(
        id="seed-sec-0002",
        repertoire_id="seed-rep-0001",
        piece_name="샤콘느",
        range_type=RangeType.measures,
        start_measure=33,
        end_measure=64,
        section_name="전개부",
        sort_order=1,
        start_date=today - timedelta(days=14),
    )
    db.add(section1)
    db.add(section2)

    goal = PracticeGoal(
        id="seed-goal-0001",
        student_id=STUDENT1_ID,
        daily_time_minutes=30,
        daily_section_count=2,
        weekly_time_minutes=150,
        weekly_day_count=5,
    )
    db.add(goal)

    streak = PracticeStreak(
        id="seed-streak-0001",
        student_id=STUDENT1_ID,
        current_streak=5,
        longest_streak=12,
        last_practice_date=today - timedelta(days=1),
        total_practice_days=28,
    )
    db.add(streak)

    # ── 이준호 (new) ──
    repertoire2 = PracticeRepertoire(
        id="seed-rep-0002",
        student_id=STUDENT2_ID,
        name="스즈키 바이올린 교본 1권",
        description="기초 교본 — 작은 별 변주곡 중심",
        start_date=today - timedelta(days=20),
        is_default=True,
    )
    db.add(repertoire2)

    section3 = PracticeSection(
        id="seed-sec-0003",
        repertoire_id="seed-rep-0002",
        piece_name="작은 별 변주곡",
        range_type=RangeType.full,
        start_measure=1,
        end_measure=16,
        section_name="테마",
        sort_order=0,
        start_date=today - timedelta(days=20),
    )
    db.add(section3)

    goal2 = PracticeGoal(
        id="seed-goal-0002",
        student_id=STUDENT2_ID,
        daily_time_minutes=20,
        daily_section_count=1,
        weekly_time_minutes=100,
        weekly_day_count=5,
    )
    db.add(goal2)

    streak2 = PracticeStreak(
        id="seed-streak-0002",
        student_id=STUDENT2_ID,
        current_streak=3,
        longest_streak=7,
        last_practice_date=today - timedelta(days=1),
        total_practice_days=15,
    )
    db.add(streak2)

    # ═══════════════════════════════════════════════════════════════════
    # 17. Parent
    # ═══════════════════════════════════════════════════════════════════
    parent_user = User(
        id=PARENT_USER_ID,
        email=PARENT_EMAIL,
        name="김정수",
        role=UserRole.parent,
    )
    db.add(parent_user)

    parent = Parent(
        id=PARENT_ID,
        user_id=PARENT_USER_ID,
        name="김정수",
        email=PARENT_EMAIL,
        phone="010-9876-5432",
        status=ParentStatus.active,
    )
    db.add(parent)

    parent_child = ParentChildRelation(
        id="seed-pcr-0001",
        parent_id=PARENT_ID,
        student_id=STUDENT1_ID,
        permission=ParentPermission.fullAccess,
    )
    db.add(parent_child)

    parent_teacher = ParentTeacherConnection(
        id="seed-ptc-0001",
        parent_id=PARENT_ID,
        teacher_id=TEACHER_ID,
        student_id=STUDENT1_ID,
        permission=ParentPermission.viewOnly,
    )
    db.add(parent_teacher)

    # ═══════════════════════════════════════════════════════════════════
    # 18. Notifications (8)
    # ═══════════════════════════════════════════════════════════════════

    # Teacher: 레슨요청 (unread)
    db.add(Notification(
        id="seed-notif-0001",
        user_id=TEACHER_USER_ID,
        type="lesson_request",
        priority=NotificationPriority.high,
        title="새 레슨 요청",
        body="한지민 학생이 피아노 개인레슨을 요청했습니다.",
        data={"request_id": "seed-request-0001", "student_name": "한지민"},
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(days=1),
    ))

    # Teacher: 입금알림 (read)
    db.add(Notification(
        id="seed-notif-0002",
        user_id=TEACHER_USER_ID,
        type="payment_received",
        priority=NotificationPriority.normal,
        title="입금 확인",
        body="한지수 학생의 8레슨 패키지 수강료 560,000원이 입금되었습니다.",
        data={"subscription_id": "seed-sub-0003", "student_name": "한지수"},
        read_at=now - timedelta(days=8),
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(days=9),
    ))

    # Teacher: 수강권만료 (unread)
    db.add(Notification(
        id="seed-notif-0003",
        user_id=TEACHER_USER_ID,
        type="subscription_expiring",
        priority=NotificationPriority.high,
        title="수강권 만료 임박",
        body="박지호 학생의 8레슨 패키지가 1회 남았습니다.",
        data={"subscription_id": "seed-sub-0006", "student_name": "박지호"},
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(hours=6),
    ))

    # Teacher: 레슨리마인더 (read)
    db.add(Notification(
        id="seed-notif-0004",
        user_id=TEACHER_USER_ID,
        type="lesson_reminder",
        priority=NotificationPriority.normal,
        title="내일 레슨 알림",
        body="내일 이준호 학생 레슨이 15:00에 예정되어 있습니다.",
        data={"lesson_id": "seed-lesson-0008", "student_name": "이준호"},
        read_at=now - timedelta(hours=2),
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(hours=12),
    ))

    # Student: 제안수신 — 김소연 (unread)
    db.add(Notification(
        id="seed-notif-0005",
        user_id=STUDENT1_USER_ID,
        type="proposal_received",
        priority=NotificationPriority.high,
        title="수강권 제안",
        body="박미연 선생님이 8레슨 패키지를 제안했습니다.",
        data={"proposal_id": "seed-proposal-0001", "teacher_name": "박미연"},
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(days=1),
    ))

    # Student: 레슨리마인더 — 이준호 (read)
    db.add(Notification(
        id="seed-notif-0006",
        user_id=STUDENT2_USER_ID,
        type="lesson_reminder",
        priority=NotificationPriority.normal,
        title="내일 레슨 알림",
        body="내일 박미연 선생님과 바이올린 레슨이 15:00에 예정되어 있습니다.",
        data={"lesson_id": "seed-lesson-0008", "teacher_name": "박미연"},
        read_at=now - timedelta(hours=1),
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(hours=12),
    ))

    # Parent: 자녀레슨완료 — 김정수 (unread)
    db.add(Notification(
        id="seed-notif-0007",
        user_id=PARENT_USER_ID,
        type="child_lesson_completed",
        priority=NotificationPriority.normal,
        title="자녀 레슨 완료",
        body="김소연의 바이올린 레슨이 완료되었습니다. 피드백을 확인해 보세요.",
        data={"lesson_id": "seed-lesson-0003", "student_name": "김소연"},
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(days=7),
    ))

    # Student: 레슨취소알림 — 박지호 (unread)
    db.add(Notification(
        id="seed-notif-0008",
        user_id=STUDENT4_USER_ID,
        type="lesson_cancelled",
        priority=NotificationPriority.high,
        title="레슨 취소 알림",
        body="어제 예정된 첼로 레슨이 취소되었습니다.",
        data={"lesson_id": "seed-lesson-0016", "teacher_name": "박미연"},
        is_push=True,
        is_in_app=True,
        created_at=now - timedelta(days=1),
    ))

    # ═══════════════════════════════════════════════════════════════════
    # 19. Follows (6)
    # ═══════════════════════════════════════════════════════════════════

    # Student → Teacher
    db.add(Follow(
        id="seed-follow-0001",
        follower_id=STUDENT1_USER_ID,
        following_id=TEACHER_USER_ID,
        target_type=FollowTargetType.teacher,
        notification_enabled=True,
        created_at=now - timedelta(days=30),
    ))
    db.add(Follow(
        id="seed-follow-0002",
        follower_id=STUDENT2_USER_ID,
        following_id=TEACHER_USER_ID,
        target_type=FollowTargetType.teacher,
        notification_enabled=True,
        created_at=now - timedelta(days=25),
    ))
    db.add(Follow(
        id="seed-follow-0003",
        follower_id=STUDENT4_USER_ID,
        following_id=TEACHER_USER_ID,
        target_type=FollowTargetType.teacher,
        notification_enabled=True,
        created_at=now - timedelta(days=45),
    ))

    # Parent → Teacher
    db.add(Follow(
        id="seed-follow-0004",
        follower_id=PARENT_USER_ID,
        following_id=TEACHER_USER_ID,
        target_type=FollowTargetType.teacher,
        notification_enabled=True,
        created_at=now - timedelta(days=28),
    ))

    # Student → Academy (행복음악학원 = seed-class-0001)
    db.add(Follow(
        id="seed-follow-0005",
        follower_id=STUDENT1_USER_ID,
        following_id="seed-class-0001",
        target_type=FollowTargetType.academy,
        notification_enabled=True,
        created_at=now - timedelta(days=30),
    ))
    db.add(Follow(
        id="seed-follow-0006",
        follower_id=STUDENT2_USER_ID,
        following_id="seed-class-0001",
        target_type=FollowTargetType.academy,
        notification_enabled=True,
        created_at=now - timedelta(days=25),
    ))

    await db.flush()
    print("Seed data inserted successfully!")
    print(f"  Teacher:  {TEACHER_EMAIL} (박미연, 학생 8명)")
    print(f"  Student:  {STUDENT1_EMAIL} (김소연, 레슨 6 + 연습)")
    print(f"  Student:  {STUDENT2_EMAIL} (이준호, 레슨 2 + 연습)")
    print(f"  Student:  {STUDENT3_EMAIL} (최유진, 체험 레슨 1)")
    print(f"  Student:  {STUDENT4_EMAIL} (박지호, 레슨 8)")
    print(f"  Student:  {STUDENT5_EMAIL} (한지수, inactive)")
    print(f"  Student:  {STUDENT6_EMAIL} (정하은, 레슨 2, paused)")
    print(f"  Student:  {STUDENT7_EMAIL} (한지민, inactive)")
    print(f"  Student:  {STUDENT8_EMAIL} (윤서준, inactive)")
    print(f"  Parent:   {PARENT_EMAIL} (김정수, 자녀: 김소연)")
    print(f"  Subscriptions: 8 (active 4, expired 2, expiringSoon 1, active-unpaid 1)")
    print(f"  Proposals: 7 (pending 4, paymentNotified 1, confirmed 1, rejected 1)")
    print(f"  Requests: 5 (pending 2, proposalSent 1, declined 1, expired 1)")
    print(f"  Lessons: 19 | Bookings: 2 | Notifications: 8 | Follows: 6")


async def main() -> None:
    """Entry point — connect to DB and run seed."""
    from app.core.database import AsyncSessionLocal

    async with AsyncSessionLocal() as session:
        try:
            await seed(session)
            await session.commit()
        except Exception:
            await session.rollback()
            raise


if __name__ == "__main__":
    asyncio.run(main())
