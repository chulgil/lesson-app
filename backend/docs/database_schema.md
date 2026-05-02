# Database Schema

> 마지막 업데이트: 2026-03-02

PostgreSQL 17 · `lessonaza` 데이터베이스 · Alembic 관리 스키마

---

## 테이블 요약 (37개)

| # | 테이블 | 설명 | 주요 FK |
|---|--------|------|---------|
| 1 | `users` | 인증 사용자 | - |
| 2 | `oauth_accounts` | 소셜 로그인 | → users |
| 3 | `token_blacklist` | 토큰 블랙리스트 | → users |
| 4 | `teachers` | 선생님 프로필 | → users |
| 5 | `teacher_educations` | 학력 | → teachers |
| 6 | `teacher_careers` | 경력 | → teachers |
| 7 | `teacher_certificates` | 자격증 | → teachers |
| 8 | `students` | 학생 | → users (nullable) |
| 9 | `lesson_classes` | 클래스/소속 | → teachers |
| 10 | `class_memberships` | 학생-클래스 | → lesson_classes, students |
| 11 | `lesson_locations` | 레슨 장소 | → lesson_classes |
| 12 | `lessons` | 레슨 | → students, teachers |
| 13 | `lesson_pieces` | 레슨 곡목 | → lessons |
| 14 | `lesson_recordings` | 레슨 녹음 | → lessons |
| 15 | `subscriptions` | 수강권 | → students, class_memberships |
| 16 | `subscription_usages` | 수강권 사용 기록 | → subscriptions |
| 17 | `subscription_templates` | 수강권 템플릿 | → teachers |
| 18 | `subscription_proposals` | 수강권 제안 | → teachers, students, templates |
| 19 | `payments` | 레거시 입금 상태 기록 | → students |
| 20 | `tuition_settings` | 수업료 설정 | → students |
| 21 | `practice_repertoires` | 연습 레퍼토리 | → students |
| 22 | `practice_sections` | 연습 섹션 | → practice_repertoires |
| 23 | `daily_practice_statuses` | 날짜별 완료 | → practice_sections |
| 24 | `practice_recordings` | 연습 녹음 | → practice_sections |
| 25 | `practice_notes` | 연습 노트 | → practice_sections |
| 26 | `practice_goals` | 연습 목표 | → students |
| 27 | `practice_streaks` | 연습 스트릭 | → students |
| 28 | `practice_items` | 연습 과제 | → lessons, students, teachers |
| 29 | `teacher_student_relations` | 선생님-학생 관계 | → teachers, students |
| 30 | `teacher_availabilities` | 가용 시간 | → teachers |
| 31 | `availability_time_slots` | 시간 슬롯 | → teacher_availabilities |
| 32 | `lesson_bookings` | 예약 | → teachers, students |
| 33 | `notifications` | 알림 | → users |
| 34 | `parents` | 학부모 | → users |
| 35 | `parent_child_relations` | 학부모-자녀 | → parents, students |
| 36 | `parent_teacher_connections` | 학부모-선생님 | → parents, teachers |
| 37 | `follows` | 팔로우 | → users |
| 38 | `lesson_requests` | 레슨 요청 | → students, teachers |
| 39 | `group_classes` | 그룹 클래스 | → teachers |
| 40 | `tip_templates` | 팁 템플릿 | → teachers |
| 41 | `lesson_policies` | 레슨 정책 | → teachers |
| 42 | `makeup_lessons` | 보강 | → students, teachers, lessons |
| 43 | `schedule_confirmation_cards` | 스케줄 확인 | → students, teachers |
| 44 | `i18n_translations` | 다국어 번역 | - |
| 45 | `supported_locales` | 지원 로케일 | - |

---

## 공통 규칙

- **PK**: `VARCHAR(36)` UUID v4
- **타임스탬프**: UTC `TIMESTAMPTZ`, `created_at` + `updated_at`
- **삭제**: Soft delete (`is_active` 또는 `is_archived`)
- **문자열**: PostgreSQL 기본 UTF-8 인코딩
- **금액**: `INT` (최소 통화 단위 — KRW: 원, USD: 센트, JPY: 엔)
- **인덱스 네이밍**: `idx_{table}_{column}`

---

## 1. 인증/사용자

### users

```sql
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('teacher', 'student', 'parent') DEFAULT NULL,
    profile_image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- i18n / localization
    locale VARCHAR(10) NOT NULL DEFAULT 'ko' COMMENT 'IETF BCP 47: ko, en, ja, ko-KR, en-US',
    country VARCHAR(2) NOT NULL DEFAULT 'KR' COMMENT 'ISO 3166-1 alpha-2: KR, US, JP',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Seoul' COMMENT 'IANA timezone ID',
    currency VARCHAR(3) NOT NULL DEFAULT 'KRW' COMMENT 'ISO 4217: KRW, USD, JPY',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE INDEX uk_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### oauth_accounts

```sql
CREATE TABLE oauth_accounts (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    provider ENUM('google', 'kakao', 'apple') NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    provider_email VARCHAR(255),
    provider_name VARCHAR(100) COMMENT 'Apple: 첫 로그인 때만 제공되는 이름 저장',
    is_private_email BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Apple Hide My Email 여부',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_oauth_provider_user (provider, provider_user_id),
    INDEX idx_oauth_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### token_blacklist

```sql
CREATE TABLE token_blacklist (
    id CHAR(36) PRIMARY KEY,
    jti VARCHAR(255) NOT NULL,
    user_id CHAR(36) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_token_jti (jti),
    INDEX idx_token_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 2. 선생님

### teachers

```sql
CREATE TABLE teachers (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    instruments JSON NOT NULL DEFAULT ('[]'),
    introduction TEXT,
    experience_years INT,
    lesson_areas JSON,
    lesson_types JSON,
    fee_min INT,
    fee_max INT,
    fee_duration INT DEFAULT 60,
    teaching_style TEXT,
    specialties JSON,
    portfolio_video_urls JSON,
    bank_name VARCHAR(50),
    account_number VARCHAR(50),
    account_holder VARCHAR(50),
    is_phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_number VARCHAR(20),
    phone_verified_at DATETIME,
    visibility_settings JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_teachers_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### teacher_educations

```sql
CREATE TABLE teacher_educations (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    school VARCHAR(200) NOT NULL,
    major VARCHAR(100),
    degree VARCHAR(50),
    graduation_year INT,
    sort_order INT NOT NULL DEFAULT 0,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_education_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### teacher_careers

```sql
CREATE TABLE teacher_careers (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    organization VARCHAR(200) NOT NULL,
    position VARCHAR(100),
    start_year INT NOT NULL,
    end_year INT,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_career_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### teacher_certificates

```sql
CREATE TABLE teacher_certificates (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    type ENUM('musicTeacher', 'cultureArtsEducator', 'schoolTeacher',
              'conservatory', 'degree', 'performance', 'other') NOT NULL,
    name VARCHAR(200) NOT NULL,
    issuing_body VARCHAR(200),
    issue_date DATE,
    certificate_number VARCHAR(100),
    image_url TEXT,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    submitted_at DATETIME,
    reviewed_at DATETIME,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_certificate_teacher (teacher_id),
    INDEX idx_certificate_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 3. 학생

### students

```sql
CREATE TABLE students (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36),
    teacher_id CHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    instrument VARCHAR(50) NOT NULL DEFAULT '',
    level ENUM('beginner', 'elementary', 'intermediate', 'advanced') NOT NULL DEFAULT 'beginner',
    status ENUM('trial', 'active', 'paused', 'inactive') NOT NULL DEFAULT 'active',
    phone VARCHAR(20),
    parent_phone VARCHAR(20),
    parent_name VARCHAR(100),
    email VARCHAR(255),
    birth_date DATE,
    age_group ENUM('child', 'student', 'adult'),
    profile_image_url TEXT,
    profile_color VARCHAR(7) DEFAULT '#6B5B95',
    monthly_fee INT NOT NULL DEFAULT 0,
    lessons_per_week INT NOT NULL DEFAULT 1,
    lesson_day VARCHAR(10),
    lesson_time VARCHAR(5),
    lesson_duration INT NOT NULL DEFAULT 60,
    connection_status ENUM('offline', 'inviteSent', 'inviteReceived', 'connected', 'disconnected')
        NOT NULL DEFAULT 'offline',
    connected_at DATETIME,
    practice_level ENUM('newStudent', 'excellent', 'average', 'poor', 'onBreak'),
    break_reason TEXT,
    expected_return_date DATE,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_students_user_id (user_id),
    INDEX idx_students_teacher_id (teacher_id),
    INDEX idx_students_status (status),
    INDEX idx_students_connection (connection_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 4. 클래스/소속

### lesson_classes

```sql
CREATE TABLE lesson_classes (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    type ENUM('academy', 'private') NOT NULL DEFAULT 'private',
    payment_type ENUM('organization', 'parent') NOT NULL DEFAULT 'parent',
    contact_person VARCHAR(100),
    contact_phone VARCHAR(20),
    address TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_class_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### class_memberships

```sql
CREATE TABLE class_memberships (
    id CHAR(36) PRIMARY KEY,
    lesson_class_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    instrument VARCHAR(50) NOT NULL DEFAULT '',
    status ENUM('trial', 'active', 'paused', 'terminated') NOT NULL DEFAULT 'active',
    level VARCHAR(50),
    monthly_fee INT NOT NULL DEFAULT 0,
    lessons_per_week INT NOT NULL DEFAULT 1,
    lesson_day VARCHAR(10),
    lesson_time VARCHAR(5),
    lesson_duration INT NOT NULL DEFAULT 60,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (lesson_class_id) REFERENCES lesson_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_membership_class (lesson_class_id),
    INDEX idx_membership_student (student_id),
    UNIQUE INDEX uk_membership_class_student (lesson_class_id, student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_locations

```sql
CREATE TABLE lesson_locations (
    id CHAR(36) PRIMARY KEY,
    lesson_class_id CHAR(36),
    name VARCHAR(200) NOT NULL,
    type ENUM('academyRoom', 'teacherStudio', 'studentHome', 'externalPlace', 'online')
        NOT NULL DEFAULT 'teacherStudio',
    address TEXT,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    online_platform VARCHAR(100),
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (lesson_class_id) REFERENCES lesson_classes(id) ON DELETE SET NULL,
    INDEX idx_location_class (lesson_class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 5. 레슨

### lessons

```sql
CREATE TABLE lessons (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    teacher_id CHAR(36),
    student_name VARCHAR(100) NOT NULL,
    teacher_name VARCHAR(100),
    instrument VARCHAR(50) NOT NULL DEFAULT '',
    date DATE NOT NULL,
    start_time VARCHAR(5) NOT NULL,
    duration INT NOT NULL DEFAULT 60,
    status ENUM('scheduled', 'completed', 'cancelled', 'cancelledByStudentAdvance',
                'cancelledByStudentLate', 'cancelledByTeacher', 'cancelledMutual',
                'noShow', 'studentAbsent', 'reschedulePending') NOT NULL DEFAULT 'scheduled',
    feedback TEXT,
    key_points JSON,
    practice_tips TEXT,
    location_name VARCHAR(200),
    location_address TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
    INDEX idx_lesson_student (student_id),
    INDEX idx_lesson_teacher (teacher_id),
    INDEX idx_lesson_date (date),
    INDEX idx_lesson_status (status),
    INDEX idx_lesson_teacher_date (teacher_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_pieces

```sql
CREATE TABLE lesson_pieces (
    id CHAR(36) PRIMARY KEY,
    lesson_id CHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    composer VARCHAR(100),
    opus VARCHAR(50),
    movement VARCHAR(50),
    notes TEXT,
    sort_order INT NOT NULL DEFAULT 0,

    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    INDEX idx_piece_lesson (lesson_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_recordings

```sql
CREATE TABLE lesson_recordings (
    id CHAR(36) PRIMARY KEY,
    lesson_id CHAR(36) NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT,
    duration INT NOT NULL DEFAULT 0,
    recorded_at DATETIME NOT NULL,
    transcription TEXT,
    ai_summary TEXT,

    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    INDEX idx_lesson_rec_lesson (lesson_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. 수강권

### subscriptions

```sql
CREATE TABLE subscriptions (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    membership_id CHAR(36) NOT NULL,
    type ENUM('trial', 'monthly', 'package') NOT NULL,
    total_lessons INT,
    used_lessons INT NOT NULL DEFAULT 0,
    start_date DATE,
    end_date DATE,
    amount INT NOT NULL DEFAULT 0,
    status ENUM('active', 'expiringSoon', 'expired', 'paused') NOT NULL DEFAULT 'active',
    lessons_per_month INT,
    bonus_count INT NOT NULL DEFAULT 0,
    billing_type ENUM('perPackage', 'monthly'),
    billing_day INT,
    fifth_week_policy ENUM('skip', 'bonus', 'deduct', 'optional'),
    bonus_reason TEXT,
    total_reschedule_allowance INT NOT NULL DEFAULT 2,
    used_reschedule_count INT NOT NULL DEFAULT 0,
    payment_confirmed BOOLEAN NOT NULL DEFAULT TRUE,
    payment_method ENUM('cash', 'bankTransfer', 'card', 'other'),
    paid_at DATETIME,
    payment_confirmed_at DATETIME,
    discount_amount INT,
    discount_reason TEXT,
    original_amount INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (membership_id) REFERENCES class_memberships(id) ON DELETE CASCADE,
    INDEX idx_sub_student (student_id),
    INDEX idx_sub_membership (membership_id),
    INDEX idx_sub_status (status),
    INDEX idx_sub_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### subscription_usages

```sql
CREATE TABLE subscription_usages (
    id CHAR(36) PRIMARY KEY,
    subscription_id CHAR(36) NOT NULL,
    lesson_id CHAR(36),
    used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    teacher_name VARCHAR(100),
    instrument VARCHAR(50),
    type ENUM('lesson', 'noShow', 'cancellationPenalty', 'reschedule', 'bonus', 'manual')
        NOT NULL DEFAULT 'lesson',

    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE SET NULL,
    INDEX idx_usage_subscription (subscription_id),
    INDEX idx_usage_date (used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### subscription_templates

```sql
CREATE TABLE subscription_templates (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    type ENUM('trial', 'monthly', 'package') NOT NULL,
    lessons_count INT,
    lessons_per_month INT,
    duration_months INT,
    amount INT NOT NULL DEFAULT 0,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_template_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### subscription_proposals

```sql
CREATE TABLE subscription_proposals (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    template_id CHAR(36),
    message TEXT,
    status ENUM('pending', 'paymentNotified', 'confirmed', 'rejected', 'expired', 'cancelled')
        NOT NULL DEFAULT 'pending',
    payment_status ENUM('pending', 'completed') NOT NULL DEFAULT 'pending',
    expires_at DATETIME NOT NULL,
    payment_notified_at DATETIME,
    confirmed_at DATETIME,
    rejected_at DATETIME,
    subscription_id CHAR(36),
    rejection_reason TEXT,
    academy_id CHAR(36),
    discount_amount INT,
    discount_reason TEXT,
    template_ids JSON,
    recommended_template_id CHAR(36),
    selected_template_id CHAR(36),
    is_auto_proposal BOOLEAN NOT NULL DEFAULT FALSE,
    is_app_transition BOOLEAN NOT NULL DEFAULT FALSE,
    lesson_request_id CHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES subscription_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    FOREIGN KEY (lesson_request_id) REFERENCES lesson_requests(id) ON DELETE SET NULL,
    INDEX idx_proposal_teacher (teacher_id),
    INDEX idx_proposal_student (student_id),
    INDEX idx_proposal_status (status),
    INDEX idx_proposal_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 7. 입금 상태 기록

### payments

레거시 테이블이다. 현행 백엔드는 독립 `/payments/*` API를 제공하지 않으며, 수강권 입금 상태는 `subscriptions` / `subscription_proposals` 흐름에서 기록한다. 앱관리자 사용료 과금은 향후 별도 스펙 완료 후 분리된 모델/API로 설계한다.

```sql
CREATE TABLE payments (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    type ENUM('trial', 'regular') NOT NULL DEFAULT 'regular',
    amount INT NOT NULL DEFAULT 0,
    status ENUM('pending', 'paid', 'confirmed', 'overdue', 'cancelled', 'refunded')
        NOT NULL DEFAULT 'pending',
    method ENUM('cash', 'bankTransfer', 'card', 'other'),
    payment_date DATE,
    due_date DATE,
    description TEXT,
    receipt_number VARCHAR(100),
    lesson_count INT NOT NULL DEFAULT 0,
    period_start DATE,
    period_end DATE,
    week_start INT,
    week_end INT,
    student_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    student_confirmed_at DATETIME,
    billing_target_type ENUM('student', 'parent') NOT NULL DEFAULT 'student',
    billing_target_id CHAR(36),
    billing_target_name VARCHAR(100),
    paid_at DATETIME,
    paid_by CHAR(36),
    confirmed_at DATETIME,
    confirmed_by CHAR(36),
    parent_notified BOOLEAN NOT NULL DEFAULT FALSE,
    parent_notified_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_payment_student (student_id),
    INDEX idx_payment_status (status),
    INDEX idx_payment_due_date (due_date),
    INDEX idx_payment_period (period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### tuition_settings

```sql
CREATE TABLE tuition_settings (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    monthly_fee INT NOT NULL DEFAULT 0,
    lesson_fee INT NOT NULL DEFAULT 0,
    is_monthly_billing BOOLEAN NOT NULL DEFAULT TRUE,
    lessons_per_month INT NOT NULL DEFAULT 4,
    billing_day INT NOT NULL DEFAULT 1,
    preferred_method ENUM('cash', 'bankTransfer', 'card', 'other'),
    bank_account VARCHAR(100),
    notes TEXT,
    last_payment_date DATE,
    next_due_date DATE,
    default_billing_target ENUM('student', 'parent') NOT NULL DEFAULT 'student',
    default_billing_parent_id CHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_tuition_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 8. 연습

### practice_repertoires

```sql
CREATE TABLE practice_repertoires (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    archived_at DATETIME,
    sort_order INT,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_repertoire_student (student_id),
    INDEX idx_repertoire_dates (student_id, start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_sections

```sql
CREATE TABLE practice_sections (
    id CHAR(36) PRIMARY KEY,
    repertoire_id CHAR(36) NOT NULL,
    piece_name VARCHAR(200) NOT NULL,
    range_type ENUM('full', 'line', 'measure') NOT NULL DEFAULT 'full',
    start_measure INT NOT NULL DEFAULT 1,
    end_measure INT NOT NULL DEFAULT 1,
    start_line INT,
    end_line INT,
    section_name VARCHAR(200),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    is_repeat BOOLEAN NOT NULL DEFAULT FALSE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    repeat_count INT,
    daily_repeat_counts JSON,
    start_date DATE,
    end_date DATE,
    practice_count INT NOT NULL DEFAULT 0,
    total_practice_seconds INT NOT NULL DEFAULT 0,
    target_practice_seconds INT,
    sort_order INT,
    last_practiced_at DATETIME,
    completed_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (repertoire_id) REFERENCES practice_repertoires(id) ON DELETE CASCADE,
    INDEX idx_section_repertoire (repertoire_id),
    INDEX idx_section_completed (is_completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### daily_practice_statuses

```sql
CREATE TABLE daily_practice_statuses (
    id CHAR(36) PRIMARY KEY,
    section_id CHAR(36) NOT NULL,
    date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at DATETIME,

    FOREIGN KEY (section_id) REFERENCES practice_sections(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_daily_section_date (section_id, date),
    INDEX idx_daily_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_recordings

```sql
CREATE TABLE practice_recordings (
    id CHAR(36) PRIMARY KEY,
    section_id CHAR(36) NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT,
    duration_seconds INT NOT NULL DEFAULT 0,
    bpm INT,
    is_representative BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (section_id) REFERENCES practice_sections(id) ON DELETE CASCADE,
    INDEX idx_practice_rec_section (section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_notes

```sql
CREATE TABLE practice_notes (
    id CHAR(36) PRIMARY KEY,
    section_id CHAR(36) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (section_id) REFERENCES practice_sections(id) ON DELETE CASCADE,
    INDEX idx_note_section (section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_goals

```sql
CREATE TABLE practice_goals (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    daily_time_minutes INT NOT NULL DEFAULT 30,
    daily_section_count INT NOT NULL DEFAULT 3,
    weekly_time_minutes INT NOT NULL DEFAULT 150,
    weekly_day_count INT NOT NULL DEFAULT 5,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_goal_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_streaks

```sql
CREATE TABLE practice_streaks (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_practice_date DATE,
    total_practice_days INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_streak_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### practice_items

```sql
CREATE TABLE practice_items (
    id CHAR(36) PRIMARY KEY,
    lesson_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    teacher_id CHAR(36) NOT NULL,
    type ENUM('repertoire', 'technique', 'theory', 'custom') NOT NULL DEFAULT 'repertoire',
    title VARCHAR(200) NOT NULL,
    description TEXT,
    repertoire_id CHAR(36),
    section_id CHAR(36),
    priority ENUM('must', 'should', 'could') NOT NULL DEFAULT 'should',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    practice_count INT NOT NULL DEFAULT 0,
    completed_at DATETIME,
    has_like BOOLEAN NOT NULL DEFAULT FALSE,
    liked_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (repertoire_id) REFERENCES practice_repertoires(id) ON DELETE SET NULL,
    FOREIGN KEY (section_id) REFERENCES practice_sections(id) ON DELETE SET NULL,
    INDEX idx_item_lesson (lesson_id),
    INDEX idx_item_student (student_id),
    INDEX idx_item_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 9. 관계/연결

### teacher_student_relations

```sql
CREATE TABLE teacher_student_relations (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    status ENUM('pending', 'active', 'inactive', 'disconnected') NOT NULL DEFAULT 'pending',
    connected_at DATETIME,
    disconnected_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_relation_teacher_student (teacher_id, student_id),
    INDEX idx_relation_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### follows

```sql
CREATE TABLE follows (
    id CHAR(36) PRIMARY KEY,
    follower_id CHAR(36) NOT NULL,
    following_id CHAR(36) NOT NULL,
    target_type ENUM('teacher', 'academy') NOT NULL DEFAULT 'teacher',
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_follow (follower_id, following_id),
    INDEX idx_follow_following (following_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 10. 스케줄/예약

### teacher_availabilities

```sql
CREATE TABLE teacher_availabilities (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    day_of_week INT NOT NULL COMMENT '1=Mon, 7=Sun',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_avail_teacher_day (teacher_id, day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### availability_time_slots

```sql
CREATE TABLE availability_time_slots (
    id CHAR(36) PRIMARY KEY,
    availability_id CHAR(36) NOT NULL,
    start_time VARCHAR(5) NOT NULL COMMENT 'HH:mm',
    end_time VARCHAR(5) NOT NULL COMMENT 'HH:mm',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    FOREIGN KEY (availability_id) REFERENCES teacher_availabilities(id) ON DELETE CASCADE,
    INDEX idx_slot_availability (availability_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_bookings

```sql
CREATE TABLE lesson_bookings (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    lesson_type ENUM('trial', 'regular', 'oneTime') NOT NULL DEFAULT 'regular',
    scheduled_date DATE NOT NULL,
    scheduled_time VARCHAR(5) NOT NULL COMMENT 'HH:mm',
    duration INT NOT NULL DEFAULT 60,
    instrument VARCHAR(50),
    location_id CHAR(36),
    status ENUM('pending', 'approved', 'rejected', 'cancelled', 'completed', 'noShow')
        NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES lesson_locations(id) ON DELETE SET NULL,
    INDEX idx_booking_teacher (teacher_id),
    INDEX idx_booking_student (student_id),
    INDEX idx_booking_date (scheduled_date),
    INDEX idx_booking_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_requests

```sql
CREATE TABLE lesson_requests (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    teacher_id CHAR(36) NOT NULL,
    message TEXT,
    preferred_timing ENUM('nextWeek', 'nextMonth', 'afterConsultation') NOT NULL DEFAULT 'afterConsultation',
    keep_previous_schedule BOOLEAN NOT NULL DEFAULT FALSE,
    previous_lesson_day INT,
    previous_lesson_time VARCHAR(5),
    previous_lesson_duration INT,
    status ENUM('pending', 'proposalSent', 'accepted', 'declined', 'expired', 'cancelled')
        NOT NULL DEFAULT 'pending',
    expires_at DATETIME NOT NULL,
    proposal_id CHAR(36),
    decline_reason TEXT,
    status_updated_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (proposal_id) REFERENCES subscription_proposals(id) ON DELETE SET NULL,
    INDEX idx_request_student (student_id),
    INDEX idx_request_teacher (teacher_id),
    INDEX idx_request_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### group_classes

```sql
CREATE TABLE group_classes (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    organization_id CHAR(36),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    type ENUM('regular', 'dropIn') NOT NULL DEFAULT 'regular',
    max_capacity INT NOT NULL DEFAULT 10,
    waitlist_capacity INT,
    duration_minutes INT NOT NULL DEFAULT 60,
    booking_deadline_minutes INT NOT NULL DEFAULT 60,
    cancel_deadline_minutes INT NOT NULL DEFAULT 1440,
    no_show_policy ENUM('deduct', 'noDeduct') NOT NULL DEFAULT 'deduct',
    max_no_show_count INT,
    repeat_days JSON COMMENT '[1,3,5] for Mon/Wed/Fri',
    repeat_time VARCHAR(5) COMMENT 'HH:mm',
    instrument VARCHAR(50),
    price_per_session INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_group_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 11. 알림

### notifications

```sql
CREATE TABLE notifications (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    type VARCHAR(50) NOT NULL,
    priority ENUM('low', 'normal', 'high', 'urgent') NOT NULL DEFAULT 'normal',
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSON,
    scheduled_at DATETIME,
    sent_at DATETIME,
    read_at DATETIME,
    is_push BOOLEAN NOT NULL DEFAULT TRUE,
    is_in_app BOOLEAN NOT NULL DEFAULT TRUE,
    action_url TEXT,
    action_label VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notif_user (user_id),
    INDEX idx_notif_read (user_id, read_at),
    INDEX idx_notif_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 12. 학부모

### parents

```sql
CREATE TABLE parents (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    profile_image_url TEXT,
    profile_color VARCHAR(7) DEFAULT '#6B5B95',
    status ENUM('pending', 'active', 'inactive') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_parent_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### parent_child_relations

```sql
CREATE TABLE parent_child_relations (
    id CHAR(36) PRIMARY KEY,
    parent_id CHAR(36) NOT NULL,
    student_id CHAR(36) NOT NULL,
    permission ENUM('viewOnly', 'managePayments', 'manageLessons', 'fullAccess')
        NOT NULL DEFAULT 'viewOnly',
    connected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_parent_child (parent_id, student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### parent_teacher_connections

```sql
CREATE TABLE parent_teacher_connections (
    id CHAR(36) PRIMARY KEY,
    parent_id CHAR(36) NOT NULL,
    teacher_id CHAR(36) NOT NULL,
    student_id CHAR(36),
    permission ENUM('viewOnly', 'managePayments', 'manageLessons', 'fullAccess')
        NOT NULL DEFAULT 'viewOnly',
    connected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    UNIQUE INDEX uk_parent_teacher (parent_id, teacher_id),
    INDEX idx_ptc_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 13. 기타

### tip_templates

```sql
CREATE TABLE tip_templates (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    content TEXT NOT NULL,
    category ENUM('technique', 'musicality', 'practice', 'mindset', 'general')
        NOT NULL DEFAULT 'general',
    instrument VARCHAR(50),
    usage_count INT NOT NULL DEFAULT 0,
    last_used_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_tip_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### lesson_policies

```sql
CREATE TABLE lesson_policies (
    id CHAR(36) PRIMARY KEY,
    teacher_id CHAR(36) NOT NULL,
    cancellation_deadline_hours INT NOT NULL DEFAULT 24,
    late_cancel_deducts_lesson BOOLEAN NOT NULL DEFAULT TRUE,
    no_show_deducts_lesson BOOLEAN NOT NULL DEFAULT TRUE,
    max_no_show_count INT,
    reschedule_allowed BOOLEAN NOT NULL DEFAULT TRUE,
    reschedule_deadline_hours INT NOT NULL DEFAULT 24,
    max_reschedule_per_subscription INT NOT NULL DEFAULT 2,
    makeup_expiry_days INT NOT NULL DEFAULT 30,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    UNIQUE INDEX uk_policy_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### makeup_lessons

```sql
CREATE TABLE makeup_lessons (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    teacher_id CHAR(36) NOT NULL,
    original_lesson_id CHAR(36),
    reason TEXT,
    status ENUM('pending', 'scheduled', 'completed', 'expired', 'cancelled')
        NOT NULL DEFAULT 'pending',
    scheduled_date DATE,
    scheduled_time VARCHAR(5),
    expires_at DATE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (original_lesson_id) REFERENCES lessons(id) ON DELETE SET NULL,
    INDEX idx_makeup_student (student_id),
    INDEX idx_makeup_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### schedule_confirmation_cards

```sql
CREATE TABLE schedule_confirmation_cards (
    id CHAR(36) PRIMARY KEY,
    student_id CHAR(36) NOT NULL,
    teacher_id CHAR(36) NOT NULL,
    subscription_id CHAR(36),
    title VARCHAR(200) NOT NULL,
    message TEXT,
    status ENUM('pending', 'confirmed', 'rejected', 'expired') NOT NULL DEFAULT 'pending',
    proposed_day VARCHAR(10),
    proposed_time VARCHAR(5),
    proposed_duration INT,
    response_message TEXT,
    responded_at DATETIME,
    expires_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    INDEX idx_scc_student (student_id),
    INDEX idx_scc_teacher (teacher_id),
    INDEX idx_scc_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 14. 다국어 (i18n)

### i18n_translations

서버 측 번역 문자열 관리. 알림 메시지, 이메일 템플릿, 시스템 메시지 등.

```sql
CREATE TABLE i18n_translations (
    id CHAR(36) PRIMARY KEY,
    `key` VARCHAR(200) NOT NULL COMMENT 'dot notation: notification.lesson_booked.title',
    locale VARCHAR(10) NOT NULL COMMENT 'ko, en, ja',
    value TEXT NOT NULL,
    context VARCHAR(100) COMMENT 'notification, email, system, enum_label',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE INDEX uk_translation_key_locale (`key`, locale),
    INDEX idx_translation_context (context)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**사용 예:**

| key | locale | value |
|-----|--------|-------|
| `notification.lesson_booked.title` | `ko` | `레슨이 예약되었습니다` |
| `notification.lesson_booked.title` | `en` | `Lesson has been booked` |
| `notification.lesson_booked.title` | `ja` | `レッスンが予約されました` |
| `notification.lesson_booked.body` | `ko` | `{student_name}님의 {date} {time} 레슨이 예약되었습니다.` |
| `notification.lesson_booked.body` | `en` | `Lesson for {student_name} has been booked on {date} at {time}.` |
| `enum.student_level.beginner` | `ko` | `초급` |
| `enum.student_level.beginner` | `en` | `Beginner` |
| `enum.student_level.beginner` | `ja` | `初級` |

### supported_locales

지원 로케일 및 국가 설정.

```sql
CREATE TABLE supported_locales (
    locale VARCHAR(10) PRIMARY KEY COMMENT 'ko, en, ja',
    language_name VARCHAR(50) NOT NULL COMMENT '한국어, English, 日本語',
    native_name VARCHAR(50) NOT NULL COMMENT '한국어, English, 日本語',
    default_country VARCHAR(2) NOT NULL COMMENT 'KR, US, JP',
    default_timezone VARCHAR(50) NOT NULL COMMENT 'Asia/Seoul, America/New_York, Asia/Tokyo',
    default_currency VARCHAR(3) NOT NULL COMMENT 'KRW, USD, JPY',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**초기 데이터:**

```sql
INSERT INTO supported_locales VALUES
('ko', '한국어', '한국어', 'KR', 'Asia/Seoul', 'KRW', TRUE, 1),
('en', 'English', 'English', 'US', 'America/New_York', 'USD', TRUE, 2),
('ja', '日本語', '日本語', 'JP', 'Asia/Tokyo', 'JPY', TRUE, 3);
```

---

## 인덱스 요약

### Composite Indexes (성능 최적화)

| 테이블 | 인덱스 | 용도 |
|--------|--------|------|
| lessons | `(teacher_id, date)` | 선생님별 날짜 조회 |
| practice_repertoires | `(student_id, start_date, end_date)` | 학생별 기간 조회 |
| daily_practice_statuses | `(section_id, date)` UNIQUE | 섹션별 날짜 유일 |
| notifications | `(user_id, read_at)` | 읽지 않은 알림 조회 |
| payments | `(period_start, period_end)` | 레거시 기간별 입금 상태 조회 |

### FK Cascade 규칙

| 부모 삭제 시 | 동작 | 대상 |
|-------------|------|------|
| users 삭제 | CASCADE | oauth_accounts, token_blacklist |
| teachers 삭제 | CASCADE | students, lesson_classes, templates, etc. |
| students 삭제 | CASCADE | lessons, subscriptions, practice, etc. |
| lessons 삭제 | CASCADE | lesson_pieces, lesson_recordings, practice_items |
| practice_repertoires 삭제 | CASCADE | practice_sections |
| practice_sections 삭제 | CASCADE | recordings, notes, daily_statuses |

---

## ER Diagram (텍스트)

```
users ─┬── oauth_accounts
       ├── teachers ─┬── students
       │             ├── lesson_classes ── class_memberships ── subscriptions
       │             ├── subscription_templates ── subscription_proposals
       │             ├── teacher_availabilities ── time_slots
       │             ├── lesson_policies
       │             ├── group_classes
       │             └── tip_templates
       ├── parents ─┬── parent_child_relations ── students
       │            └── parent_teacher_connections
       └── notifications

students ─┬── lessons ─┬── lesson_pieces
           │            ├── lesson_recordings
           │            └── practice_items
           ├── practice_repertoires ── practice_sections ─┬── practice_recordings
           │                                               ├── daily_practice_statuses
           │                                               └── practice_notes
           ├── practice_goals
           ├── practice_streaks
           ├── payments
           ├── lesson_bookings
           └── lesson_requests
```
