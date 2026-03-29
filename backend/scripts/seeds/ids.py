"""Fixed seed IDs — single source of truth.

All seed data uses these IDs. dev-login resolves to these IDs
when matching email addresses, ensuring consistency.
"""

# ── Users ────────────────────────────────────────────────────────────
TEACHER_USER_ID = "seed-teacher-0001"
STUDENT1_USER_ID = "seed-student-user-0001"  # 김소연
STUDENT2_USER_ID = "seed-student-user-0002"  # 이준호
STUDENT3_USER_ID = "seed-student-user-0003"  # 최유진
STUDENT4_USER_ID = "seed-student-user-0004"  # 박지호
STUDENT5_USER_ID = "seed-student-user-0005"  # 한지수
STUDENT6_USER_ID = "seed-student-user-0006"  # 정하은
STUDENT7_USER_ID = "seed-student-user-0007"  # 한지민
STUDENT8_USER_ID = "seed-student-user-0008"  # 윤서준
PARENT_USER_ID = "seed-parent-user-0001"

# ── Profiles ─────────────────────────────────────────────────────────
TEACHER_ID = "seed-teacher-prof-0001"
STUDENT1_ID = "seed-student-0001"
STUDENT2_ID = "seed-student-0002"
STUDENT3_ID = "seed-student-0003"
STUDENT4_ID = "seed-student-0004"
STUDENT5_ID = "seed-student-0005"
STUDENT6_ID = "seed-student-0006"
STUDENT7_ID = "seed-student-0007"
STUDENT8_ID = "seed-student-0008"
PARENT_ID = "seed-parent-0001"

# ── Emails ───────────────────────────────────────────────────────────
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

# ── Email → ID mapping (used by dev-login) ───────────────────────────
SEED_ACCOUNTS = {
    TEACHER_EMAIL: {"user_id": TEACHER_USER_ID, "role": "teacher", "name": "박미연"},
    STUDENT1_EMAIL: {"user_id": STUDENT1_USER_ID, "role": "student", "name": "김소연"},
    STUDENT2_EMAIL: {"user_id": STUDENT2_USER_ID, "role": "student", "name": "이준호"},
    STUDENT3_EMAIL: {"user_id": STUDENT3_USER_ID, "role": "student", "name": "최유진"},
    STUDENT4_EMAIL: {"user_id": STUDENT4_USER_ID, "role": "student", "name": "박지호"},
    STUDENT5_EMAIL: {"user_id": STUDENT5_USER_ID, "role": "student", "name": "한지수"},
    STUDENT6_EMAIL: {"user_id": STUDENT6_USER_ID, "role": "student", "name": "정하은"},
    STUDENT7_EMAIL: {"user_id": STUDENT7_USER_ID, "role": "student", "name": "한지민"},
    STUDENT8_EMAIL: {"user_id": STUDENT8_USER_ID, "role": "student", "name": "윤서준"},
    PARENT_EMAIL: {"user_id": PARENT_USER_ID, "role": "parent", "name": "김정수"},
}
