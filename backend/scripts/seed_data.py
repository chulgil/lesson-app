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

# Fixed UUIDs with seed- prefix so they are easy to identify
TEACHER_USER_ID = "seed-teacher-0001"
TEACHER_ID = "seed-teacher-prof-0001"
STUDENT1_USER_ID = "seed-student-user-0001"
STUDENT1_ID = "seed-student-0001"
STUDENT2_ID = "seed-student-0002"
STUDENT3_ID = "seed-student-0003"
STUDENT4_USER_ID = "seed-student-user-0004"
STUDENT4_ID = "seed-student-0004"
STUDENT5_USER_ID = "seed-student-user-0005"
STUDENT5_ID = "seed-student-0005"
PARENT_USER_ID = "seed-parent-0001"
PARENT_ID = "seed-parent-prof-0001"
MEMBERSHIP1_ID = "seed-membership-0001"
MEMBERSHIP2_ID = "seed-membership-0002"
MEMBERSHIP3_ID = "seed-membership-0003"
MEMBERSHIP4_ID = "seed-membership-0004"
MEMBERSHIP5_ID = "seed-membership-0005"

TEACHER_EMAIL = "minyeon@example.com"
STUDENT_EMAIL = "soyeon@example.com"
PARENT_EMAIL = "parent@example.com"
STUDENT4_EMAIL = "yujin@example.com"
STUDENT5_EMAIL = "haeun@example.com"

# Empty scenario accounts (user-only, no data)
EMPTY_TEACHER_USER_ID = "seed-teacher-empty-0001"
EMPTY_TEACHER_ID = "seed-teacher-prof-empty-0001"
EMPTY_TEACHER_EMAIL = "empty-teacher@example.com"
NEW_STUDENT_USER_ID = "seed-student-new-0001"
NEW_STUDENT_EMAIL = "new-student@example.com"
EMPTY_PARENT_USER_ID = "seed-parent-empty-0001"
EMPTY_PARENT_ID = "seed-parent-prof-empty-0001"
EMPTY_PARENT_EMAIL = "empty-parent@example.com"


async def seed(db: AsyncSession) -> None:
    """Insert all seed data inside a single transaction."""
    from app.models.lesson import Lesson, LessonClass, ClassMembership, LessonStatus
    from app.models.notification import Notification
    from app.models.parent import (
        Parent,
        ParentChildRelation,
        ParentPermission,
        ParentStatus,
        ParentTeacherConnection,
    )
    from app.models.policy import LessonPolicy
    from app.models.practice import PracticeGoal, PracticeRepertoire, PracticeSection, RangeType
    from app.models.relationship import RelationStatus, TeacherStudentRelation
    from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
    from app.models.student import (
        AgeGroup,
        ConnectionStatus,
        Student,
        StudentLevel,
        StudentStatus,
    )
    from app.models.subscription import (
        Subscription,
        SubscriptionStatus,
        SubscriptionTemplate,
        SubscriptionType,
        BillingType,
    )
    from app.models.teacher import Teacher, TeacherCareer, TeacherEducation
    from app.models.user import User, UserRole

    # ── Idempotency check ────────────────────────────────────────────
    existing = await db.scalar(select(User).where(User.email == TEACHER_EMAIL))
    if existing:
        print(f"Seed data already exists (found user {existing.email}). Skipping.")
        return

    now = datetime.now(UTC)
    today = date.today()

    # ── 1. Teacher user + profile ────────────────────────────────────
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
        instruments=["바이올린", "피아노"],
        introduction="서울대 음악과 졸업, 교향악단 경력의 바이올린 전문 강사입니다.",
        experience_years=5,
        lesson_areas=["서울 강남", "서울 서초"],
        lesson_types=["개인레슨", "그룹레슨"],
        fee_min=50000,
        fee_max=80000,
        fee_duration=60,
    )
    db.add(teacher)

    education = TeacherEducation(
        id="seed-edu-0001",
        teacher_id=TEACHER_ID,
        school="서울대학교",
        major="음악과 (바이올린 전공)",
        degree="학사",
        graduation_year=2020,
    )
    db.add(education)

    career = TeacherCareer(
        id="seed-career-0001",
        teacher_id=TEACHER_ID,
        organization="서울시립교향악단",
        position="제2바이올린 단원",
        start_year=2020,
        end_year=2023,
        description="정기 공연 및 교육 프로그램 참여",
    )
    db.add(career)

    # ── 2. Lesson Policy ─────────────────────────────────────────────
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

    # ── 3. Teacher Availability (Tue/Thu/Sat 10:00-18:00) ─────────────
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

    # ── 4. Subscription Templates ────────────────────────────────────
    template_pkg = SubscriptionTemplate(
        id="seed-tmpl-0001",
        teacher_id=TEACHER_ID,
        name="10레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=10,
        amount=700000,
        description="바이올린 개인레슨 10회 패키지 (회당 70,000원)",
    )
    template_monthly = SubscriptionTemplate(
        id="seed-tmpl-0002",
        teacher_id=TEACHER_ID,
        name="월간 4레슨",
        type=SubscriptionType.monthly,
        lessons_per_month=4,
        duration_months=1,
        amount=280000,
        description="매월 4회 정기 레슨 (회당 70,000원)",
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
    template_pkg4 = SubscriptionTemplate(
        id="seed-tmpl-0004",
        teacher_id=TEACHER_ID,
        name="4레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=4,
        amount=300000,
        description="바이올린 개인레슨 4회 패키지 (회당 75,000원)",
    )
    template_academy_monthly = SubscriptionTemplate(
        id="seed-tmpl-0005",
        teacher_id=TEACHER_ID,
        name="학원 월간 8레슨",
        type=SubscriptionType.monthly,
        lessons_per_month=8,
        duration_months=1,
        amount=480000,
        description="학원 그룹레슨 월 8회 (회당 60,000원)",
    )
    template_academy_pkg = SubscriptionTemplate(
        id="seed-tmpl-0006",
        teacher_id=TEACHER_ID,
        name="학원 20레슨 패키지",
        type=SubscriptionType.package,
        lessons_count=20,
        amount=1000000,
        description="학원 그룹레슨 20회 패키지 (회당 50,000원)",
    )
    db.add(template_pkg)
    db.add(template_monthly)
    db.add(template_pkg16)
    db.add(template_pkg4)
    db.add(template_academy_monthly)
    db.add(template_academy_pkg)

    # ── 5. Lesson Classes ───────────────────────────────────────────
    lesson_class = LessonClass(
        id="seed-class-0001",
        teacher_id=TEACHER_ID,
        name="개인레슨",
        sort_order=0,
    )
    lesson_class_academy = LessonClass(
        id="seed-class-0002",
        teacher_id=TEACHER_ID,
        name="행복음악학원",
        sort_order=1,
    )
    db.add(lesson_class)
    db.add(lesson_class_academy)

    # ── 6. Student users (connected accounts) ─────────────────────────
    student_user = User(
        id=STUDENT1_USER_ID,
        email=STUDENT_EMAIL,
        name="김소연",
        role=UserRole.student,
    )
    student4_user = User(
        id=STUDENT4_USER_ID,
        email=STUDENT4_EMAIL,
        name="최유진",
        role=UserRole.student,
    )
    student5_user = User(
        id=STUDENT5_USER_ID,
        email=STUDENT5_EMAIL,
        name="정하은",
        role=UserRole.student,
    )
    db.add(student_user)
    db.add(student4_user)
    db.add(student5_user)

    # ── 7. Students ──────────────────────────────────────────────────
    student1 = Student(
        id=STUDENT1_ID,
        user_id=STUDENT1_USER_ID,
        teacher_id=TEACHER_ID,
        name="김소연",
        instrument="바이올린",
        level=StudentLevel.intermediate,
        status=StudentStatus.active,
        age_group=AgeGroup.student,
        email=STUDENT_EMAIL,
        lessons_per_week=1,
        lesson_day="Monday",
        lesson_time="14:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )
    student2 = Student(
        id=STUDENT2_ID,
        teacher_id=TEACHER_ID,
        name="이준호",
        instrument="바이올린",
        level=StudentLevel.beginner,
        status=StudentStatus.active,
        age_group=AgeGroup.child,
        lessons_per_week=1,
        lesson_day="Wednesday",
        lesson_time="15:00",
        lesson_duration=60,
        monthly_fee=70000,
    )
    student3 = Student(
        id=STUDENT3_ID,
        teacher_id=TEACHER_ID,
        name="박서윤",
        instrument="바이올린",
        level=StudentLevel.elementary,
        status=StudentStatus.trial,
        age_group=AgeGroup.child,
        lessons_per_week=1,
        lesson_duration=45,
    )
    student4 = Student(
        id=STUDENT4_ID,
        user_id=STUDENT4_USER_ID,
        teacher_id=TEACHER_ID,
        name="최유진",
        instrument="바이올린",
        level=StudentLevel.beginner,
        status=StudentStatus.trial,
        age_group=AgeGroup.student,
        email=STUDENT4_EMAIL,
        lessons_per_week=1,
        lesson_duration=45,
        connection_status=ConnectionStatus.connected,
        connected_at=now,
    )
    student5 = Student(
        id=STUDENT5_ID,
        user_id=STUDENT5_USER_ID,
        teacher_id=TEACHER_ID,
        name="정하은",
        instrument="바이올린",
        level=StudentLevel.intermediate,
        status=StudentStatus.inactive,
        age_group=AgeGroup.student,
        email=STUDENT5_EMAIL,
        lessons_per_week=1,
        lesson_day="Friday",
        lesson_time="16:00",
        lesson_duration=60,
        monthly_fee=70000,
        connection_status=ConnectionStatus.connected,
        connected_at=now - timedelta(days=180),
    )
    db.add(student1)
    db.add(student2)
    db.add(student3)
    db.add(student4)
    db.add(student5)

    # ── 8. Class Memberships ─────────────────────────────────────────
    # 행복음악학원 (seed-class-0002): 김소연, 이준호, 최유진(active), 정하은(terminated)
    db.add(ClassMembership(
        id=MEMBERSHIP1_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT1_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP2_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT2_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP4_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT4_ID,
        instrument="바이올린",
    ))
    db.add(ClassMembership(
        id=MEMBERSHIP5_ID,
        lesson_class_id="seed-class-0002",
        student_id=STUDENT5_ID,
        instrument="바이올린",
        status=ClassMembership.MembershipStatus.terminated,
    ))
    # 개인레슨 (seed-class-0001): 박서윤
    db.add(ClassMembership(
        id=MEMBERSHIP3_ID,
        lesson_class_id="seed-class-0001",
        student_id=STUDENT3_ID,
        instrument="바이올린",
    ))

    # ── 9. Teacher-Student Relations ─────────────────────────────────
    for i, sid in enumerate(
        [STUDENT1_ID, STUDENT2_ID, STUDENT3_ID, STUDENT4_ID, STUDENT5_ID], 1
    ):
        db.add(TeacherStudentRelation(
            id=f"seed-rel-{i:04d}",
            teacher_id=TEACHER_ID,
            student_id=sid,
            status=RelationStatus.active,
            connected_at=now,
        ))

    # ── 10. Subscriptions ────────────────────────────────────────────
    # 김소연: 10레슨 패키지 (7/10 사용)
    sub1 = Subscription(
        id="seed-sub-0001",
        student_id=STUDENT1_ID,
        membership_id=MEMBERSHIP1_ID,
        type=SubscriptionType.package,
        total_lessons=10,
        used_lessons=7,
        start_date=today - timedelta(days=30),
        end_date=today + timedelta(days=60),
        amount=700000,
        status=SubscriptionStatus.active,
        billing_type=BillingType.perPackage,
    )
    # 이준호: 월간 4레슨 (1/4 사용)
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
    # 정하은: 만료된 패키지 (10/10 사용)
    sub_expired = Subscription(
        id="seed-sub-0003",
        student_id=STUDENT5_ID,
        membership_id=MEMBERSHIP5_ID,
        type=SubscriptionType.package,
        total_lessons=10,
        used_lessons=10,
        start_date=today - timedelta(days=120),
        end_date=today - timedelta(days=30),
        amount=700000,
        status=SubscriptionStatus.expired,
        billing_type=BillingType.perPackage,
    )
    db.add(sub1)
    db.add(sub2)
    db.add(sub_expired)

    # ── 11. Lessons ──────────────────────────────────────────────────
    # 김소연: 완료 2 + 예정 2 + 취소 1
    lesson_dates_soyeon = [
        (today - timedelta(days=14), LessonStatus.completed, "seed-lesson-0001"),
        (today - timedelta(days=7), LessonStatus.completed, "seed-lesson-0002"),
        (today + timedelta(days=7), LessonStatus.scheduled, "seed-lesson-0003"),
    ]
    for d, s, lid in lesson_dates_soyeon:
        lesson = Lesson(
            id=lid,
            student_id=STUDENT1_ID,
            teacher_id=TEACHER_ID,
            student_name="김소연",
            teacher_name="박미연",
            instrument="바이올린",
            date=d,
            start_time="14:00",
            duration=60,
            status=s,
        )
        if s == LessonStatus.completed:
            lesson.feedback = "음정이 많이 좋아졌어요. 비브라토 연습을 좀 더 해봅시다."
            lesson.key_points = ["음정 개선", "비브라토 연습"]
        db.add(lesson)

    # 김소연: 추가 예정 레슨
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

    # 김소연: 취소된 레슨
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

    # 이준호: 완료 1
    lesson_junho = Lesson(
        id="seed-lesson-0004",
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
    )
    db.add(lesson_junho)

    # 이준호: 예정 레슨
    db.add(Lesson(
        id="seed-lesson-0007",
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

    # ── 12. Practice (김소연) ────────────────────────────────────────
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

    # ── 13. Parent ───────────────────────────────────────────────────
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

    # ── 14. Notifications ────────────────────────────────────────────
    notifications = [
        Notification(
            id="seed-notif-0001",
            user_id=TEACHER_USER_ID,
            type="welcome",
            title="환영합니다!",
            body="Lessonaza에 오신 것을 환영합니다. 학생을 등록하고 레슨을 시작해보세요.",
        ),
        Notification(
            id="seed-notif-0002",
            user_id=TEACHER_USER_ID,
            type="lesson_reminder",
            title="레슨 리마인더",
            body="내일 14:00에 김소연 학생 레슨이 예정되어 있습니다.",
            data={"lesson_id": "seed-lesson-0003", "student_name": "김소연"},
        ),
        Notification(
            id="seed-notif-0003",
            user_id=STUDENT1_USER_ID,
            type="lesson_reminder",
            title="레슨 리마인더",
            body="내일 14:00에 박미연 선생님과 레슨이 예정되어 있습니다.",
            data={"lesson_id": "seed-lesson-0003", "teacher_name": "박미연"},
        ),
    ]
    for n in notifications:
        db.add(n)

    # ── 15. Empty scenario accounts (user + profile only, no data) ──
    # Empty teacher — no students, no lessons
    empty_teacher_user = User(
        id=EMPTY_TEACHER_USER_ID,
        email=EMPTY_TEACHER_EMAIL,
        name="김신규",
        role=UserRole.teacher,
    )
    db.add(empty_teacher_user)
    empty_teacher = Teacher(
        id=EMPTY_TEACHER_ID,
        user_id=EMPTY_TEACHER_USER_ID,
        instruments=["피아노"],
    )
    db.add(empty_teacher)

    # New student — user only, no teacher connection, no lessons
    new_student_user = User(
        id=NEW_STUDENT_USER_ID,
        email=NEW_STUDENT_EMAIL,
        name="이신규",
        role=UserRole.student,
    )
    db.add(new_student_user)

    # Empty parent — no children connected
    empty_parent_user = User(
        id=EMPTY_PARENT_USER_ID,
        email=EMPTY_PARENT_EMAIL,
        name="박신규",
        role=UserRole.parent,
    )
    db.add(empty_parent_user)
    empty_parent = Parent(
        id=EMPTY_PARENT_ID,
        user_id=EMPTY_PARENT_USER_ID,
        name="박신규",
        email=EMPTY_PARENT_EMAIL,
        status=ParentStatus.active,
    )
    db.add(empty_parent)

    await db.flush()
    print("Seed data inserted successfully!")
    print(f"  Teacher: {TEACHER_EMAIL} (박미연, 학생 5명)")
    print(f"  Teacher: {EMPTY_TEACHER_EMAIL} (김신규, 빈 계정)")
    print(f"  Student: {STUDENT_EMAIL} (김소연, 레슨/연습 있음)")
    print(f"  Student: {NEW_STUDENT_EMAIL} (이신규, 빈 계정)")
    print(f"  Parent:  {PARENT_EMAIL} (김정수, 자녀 등록됨)")
    print(f"  Parent:  {EMPTY_PARENT_EMAIL} (박신규, 자녀 없음)")


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
