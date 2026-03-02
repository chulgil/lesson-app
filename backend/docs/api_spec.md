# REST API Specification

> 마지막 업데이트: 2026-03-02

모든 경로는 `/api/v1` 접두어. `[Auth]` = JWT 인증 필요.

응답 형식: `application/json` · 시간: UTC ISO 8601 · 페이지네이션: `?page=1&size=20`

---

## 공통

### 필수 요청 헤더

| 헤더 | 값 | 설명 |
|------|-----|------|
| `Authorization` | `Bearer {token}` | JWT 인증 (Auth 제외) |
| `Accept-Language` | `ko` \| `en` \| `ja` | 서버 생성 메시지 언어 (알림, 에러) |
| `Content-Type` | `application/json` | 요청 본문 형식 |

> `Accept-Language`가 없으면 사용자 DB 설정의 `locale` 사용, 그것도 없으면 기본 `ko`.

### 응답 형식

**성공 (단일):**
```json
{
  "id": "uuid",
  "name": "...",
  ...
}
```

**성공 (목록/페이지네이션):**
```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "size": 20,
  "pages": 5
}
```

**에러:**
```json
{
  "detail": "Error message",
  "code": "error_code"
}
```

### 공통 쿼리 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `page` | int | 페이지 번호 (기본: 1) |
| `size` | int | 페이지 크기 (기본: 20, 최대: 100) |
| `sort` | string | 정렬 필드 (예: `-created_at`) |

---

## 1. Auth (4 endpoints)

### POST /auth/oauth/{provider}
소셜 로그인 (Google/Kakao/Apple)

| 항목 | 값 |
|------|-----|
| Auth | 없음 |
| Path | `provider`: `google` \| `kakao` \| `apple` |

**Request (Google/Kakao):**
```json
{
  "code": "authorization_code",
  "redirect_uri": "com.lessonapp://oauth/callback",
  "locale": "ko",
  "country": "KR",
  "timezone": "Asia/Seoul"
}
```

**Request (Apple):**
```json
{
  "identity_token": "eyJraWQiOiJXNldjT...",
  "authorization_code": "c1234567890...",
  "user": {
    "name": { "firstName": "길동", "lastName": "홍" },
    "email": "user@example.com"
  },
  "locale": "ko",
  "country": "KR",
  "timezone": "Asia/Seoul"
}
```
> `user` 필드는 Apple 최초 로그인 시에만 존재. `locale`/`country`/`timezone`은 옵션 (기기 설정 기반).

**Response (200):**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "홍길동",
    "role": "teacher",
    "profile_image_url": "https://...",
    "locale": "ko",
    "country": "KR",
    "timezone": "Asia/Seoul"
  }
}
```

---

### POST /auth/token/refresh
Access 토큰 갱신

**Request:**
```json
{ "refresh_token": "eyJ..." }
```

**Response (200):**
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer"
}
```

---

### POST /auth/logout
로그아웃 (Refresh 토큰 무효화)

| Auth | `[Auth]` |

**Request:**
```json
{ "refresh_token": "eyJ..." }
```

**Response (200):**
```json
{ "message": "Logged out successfully" }
```

---

### GET /auth/me
현재 사용자 정보

| Auth | `[Auth]` |

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "홍길동",
  "role": "teacher",
  "profile_image_url": "https://...",
  "locale": "ko",
  "country": "KR",
  "timezone": "Asia/Seoul",
  "currency": "KRW",
  "created_at": "2026-03-02T12:00:00Z"
}
```

---

## 2. Users (3 endpoints)

### GET /users/me `[Auth]`
내 프로필 (= GET /auth/me와 동일)

### PUT /users/me `[Auth]`
프로필 수정

**Request:**
```json
{
  "name": "홍길동",
  "phone": "010-1234-5678",
  "profile_image_url": "https://..."
}
```

### PUT /users/me/role `[Auth]`
역할 설정 (온보딩)

**Request:**
```json
{ "role": "teacher" }
```

### PUT /users/me/locale `[Auth]`
로케일/국가 설정

**Request:**
```json
{
  "locale": "en",
  "country": "US",
  "timezone": "America/New_York",
  "currency": "USD"
}
```

### GET /users/supported-locales
지원 로케일 목록 (인증 불필요)

**Response (200):**
```json
{
  "locales": [
    { "locale": "ko", "language_name": "한국어", "native_name": "한국어", "default_country": "KR" },
    { "locale": "en", "language_name": "English", "native_name": "English", "default_country": "US" },
    { "locale": "ja", "language_name": "日本語", "native_name": "日本語", "default_country": "JP" }
  ]
}
```

---

## 3. Teachers (5 endpoints)

### GET /teachers `[Auth]`
선생님 목록 (검색/탐색)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `instrument` | string | 악기 필터 |
| `area` | string | 지역 필터 |
| `q` | string | 이름/소개 검색 |

### GET /teachers/{id} `[Auth]`
선생님 상세 프로필

### PUT /teachers/{id} `[Auth]`
선생님 프로필 수정 (본인만)

**Request:**
```json
{
  "instruments": ["violin", "viola"],
  "introduction": "바이올린 레슨 10년 경력...",
  "experience_years": 10,
  "lesson_types": ["inPerson", "online"],
  "fee_min": 50000,
  "fee_max": 100000,
  "teaching_style": "기초부터 탄탄하게"
}
```

### GET /teachers/{id}/students `[Auth]`
선생님의 학생 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `status` | string | 학생 상태 필터 |
| `class_id` | string | 클래스 필터 |

### GET /teachers/{id}/dashboard `[Auth]`
선생님 대시보드 데이터

**Response (200):**
```json
{
  "total_students": 15,
  "active_students": 12,
  "today_lessons": 4,
  "week_lessons": 12,
  "unpaid_count": 3,
  "upcoming_lessons": [...]
}
```

---

## 4. Students (6 endpoints)

### GET /students `[Auth]`
학생 목록 (선생님: 자기 학생, 학부모: 자녀)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `status` | string | `active` \| `trial` \| `paused` \| `inactive` |
| `class_id` | string | 클래스 필터 |
| `q` | string | 이름 검색 |

### POST /students `[Auth: Teacher]`
학생 등록

**Request:**
```json
{
  "name": "김학생",
  "instrument": "violin",
  "level": "beginner",
  "phone": "010-1111-2222",
  "parent_phone": "010-3333-4444",
  "lesson_class_id": "uuid",
  "monthly_fee": 200000,
  "lessons_per_week": 1
}
```

### GET /students/{id} `[Auth]`
학생 상세

### PUT /students/{id} `[Auth: Teacher]`
학생 정보 수정

### DELETE /students/{id} `[Auth: Teacher]`
학생 삭제 (soft delete)

### GET /students/{id}/stats `[Auth]`
학생 통계

**Response (200):**
```json
{
  "total_lessons": 48,
  "completed_lessons": 42,
  "attendance_rate": 87.5,
  "practice_streak": 7,
  "total_practice_minutes": 1250,
  "repertoire_count": 5
}
```

---

## 5. Lesson Classes (8 endpoints)

### GET /lesson-classes `[Auth: Teacher]`
클래스 목록

### POST /lesson-classes `[Auth: Teacher]`
클래스 생성

**Request:**
```json
{
  "name": "행복 음악학원",
  "type": "academy",
  "payment_type": "organization",
  "contact_person": "원장님",
  "contact_phone": "02-1234-5678",
  "address": "서울시 강남구..."
}
```

### GET /lesson-classes/{id} `[Auth: Teacher]`
클래스 상세

### PUT /lesson-classes/{id} `[Auth: Teacher]`
클래스 수정

### DELETE /lesson-classes/{id} `[Auth: Teacher]`
클래스 삭제 (아카이브)

### POST /lesson-classes/{id}/memberships `[Auth: Teacher]`
학생 소속 추가

**Request:**
```json
{
  "student_id": "uuid",
  "instrument": "violin",
  "monthly_fee": 200000,
  "lessons_per_week": 1,
  "lesson_day": "Mon",
  "lesson_time": "14:00"
}
```

### PUT /lesson-classes/{classId}/memberships/{membershipId} `[Auth: Teacher]`
소속 수정

### DELETE /lesson-classes/{classId}/memberships/{membershipId} `[Auth: Teacher]`
소속 해제

---

## 6. Lessons (8 endpoints)

### GET /lessons `[Auth]`
레슨 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 필터 |
| `date` | string | 날짜 (YYYY-MM-DD) |
| `date_from` | string | 시작일 |
| `date_to` | string | 종료일 |
| `status` | string | 상태 필터 |

### POST /lessons `[Auth: Teacher]`
레슨 등록

**Request:**
```json
{
  "student_id": "uuid",
  "instrument": "violin",
  "date": "2026-03-05",
  "start_time": "14:00",
  "duration": 60,
  "pieces": [
    { "name": "Concerto in A minor", "composer": "Vivaldi", "movement": "1st" }
  ],
  "location_name": "행복 음악학원"
}
```

### GET /lessons/{id} `[Auth]`
레슨 상세

### PUT /lessons/{id} `[Auth: Teacher]`
레슨 수정

### PATCH /lessons/{id}/status `[Auth: Teacher]`
레슨 상태 변경

**Request:**
```json
{
  "status": "completed"
}
```

### PUT /lessons/{id}/feedback `[Auth: Teacher]`
레슨 피드백 작성

**Request:**
```json
{
  "feedback": "오늘 비브라토 연습 잘 했어요.",
  "key_points": ["비브라토 속도 조절", "보잉 안정화"],
  "practice_tips": "매일 비브라토 연습 10분씩"
}
```

### GET /lessons/upcoming `[Auth]`
다가오는 레슨 (limit 기본: 10)

### GET /lessons/recent `[Auth]`
최근 완료 레슨 (limit 기본: 10)

---

## 7. Practice (15 endpoints)

### Repertoires (6)

#### GET /practice/repertoires `[Auth]`
레퍼토리 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 ID (필수) |
| `include_archived` | bool | 아카이브 포함 |
| `date` | string | 특정 날짜 활성 레퍼토리 |

#### POST /practice/repertoires `[Auth]`
레퍼토리 생성

**Request:**
```json
{
  "student_id": "uuid",
  "name": "비발디 협주곡",
  "start_date": "2026-03-01",
  "end_date": "2026-04-30",
  "sections": [
    {
      "piece_name": "Concerto in A minor - 1st movement",
      "range_type": "measure",
      "start_measure": 1,
      "end_measure": 30,
      "is_repeat": true
    }
  ]
}
```

#### GET /practice/repertoires/{id} `[Auth]`
레퍼토리 상세 (섹션 포함)

#### PUT /practice/repertoires/{id} `[Auth]`
레퍼토리 수정

#### DELETE /practice/repertoires/{id} `[Auth]`
레퍼토리 삭제 (아카이브)

#### GET /practice/repertoires/date/{date} `[Auth]`
특정 날짜 활성 레퍼토리 (student_id 필수)

### Sections (5)

#### POST /practice/sections `[Auth]`
섹션 추가

**Request:**
```json
{
  "repertoire_id": "uuid",
  "piece_name": "Concerto in A minor",
  "range_type": "measure",
  "start_measure": 31,
  "end_measure": 60,
  "is_repeat": false
}
```

#### PUT /practice/sections/{id} `[Auth]`
섹션 수정

#### DELETE /practice/sections/{id} `[Auth]`
섹션 삭제

#### PATCH /practice/sections/{id}/complete `[Auth]`
섹션 완료 토글

**Request:**
```json
{
  "date": "2026-03-02",
  "is_completed": true
}
```

#### POST /practice/sections/{id}/notes `[Auth]`
연습 노트 추가

**Request:**
```json
{ "content": "3번째 마디 리듬 주의" }
```

### Stats (4)

#### GET /practice/goals `[Auth]`
연습 목표 조회 (student_id 필수)

#### PUT /practice/goals `[Auth]`
연습 목표 설정

**Request:**
```json
{
  "student_id": "uuid",
  "daily_time_minutes": 30,
  "daily_section_count": 3,
  "weekly_time_minutes": 150,
  "weekly_day_count": 5
}
```

#### GET /practice/streak `[Auth]`
연습 스트릭 조회 (student_id 필수)

#### GET /practice/stats `[Auth]`
연습 통계

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 ID (필수) |
| `year` | int | 연도 |
| `month` | int | 월 |

**Response (200):**
```json
{
  "total_practice_minutes": 450,
  "total_practice_days": 18,
  "completed_sections": 25,
  "current_streak": 7,
  "longest_streak": 14,
  "daily_stats": {
    "2026-03-01": { "minutes": 25, "sections_completed": 3 },
    "2026-03-02": { "minutes": 30, "sections_completed": 4 }
  }
}
```

---

## 8. Practice Items (5 endpoints)

### GET /practice-items `[Auth]`
연습 과제 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 필터 |
| `lesson_id` | string | 레슨 필터 |
| `is_completed` | bool | 완료 필터 |

### POST /practice-items `[Auth: Teacher]`
연습 과제 할당

**Request:**
```json
{
  "lesson_id": "uuid",
  "student_id": "uuid",
  "type": "repertoire",
  "title": "비발디 1악장 1-30마디",
  "priority": "must",
  "repertoire_id": "uuid",
  "section_id": "uuid"
}
```

### PUT /practice-items/{id} `[Auth: Teacher]`
과제 수정

### PATCH /practice-items/{id}/complete `[Auth: Student]`
과제 완료 토글

**Request:**
```json
{ "is_completed": true }
```

### PATCH /practice-items/{id}/like `[Auth: Teacher]`
과제 좋아요 토글

---

## 9. Recordings (7 endpoints)

### POST /recordings/upload `[Auth]`
녹음 파일 업로드

**Content-Type:** `multipart/form-data`

| 필드 | 타입 | 설명 |
|------|------|------|
| `file` | File | 녹음 파일 (m4a, wav, mp3) |
| `section_id` | string | 연습 섹션 ID |
| `duration_seconds` | int | 녹음 시간 |
| `bpm` | int | 메트로놈 BPM (옵션) |

**Response (201):**
```json
{
  "id": "uuid",
  "section_id": "uuid",
  "file_url": "https://storage.../recordings/uuid.m4a",
  "duration_seconds": 120,
  "bpm": 80,
  "created_at": "2026-03-02T12:00:00Z"
}
```

### GET /recordings/{id} `[Auth]`
녹음 메타데이터

### GET /recordings/{id}/download `[Auth]`
녹음 파일 다운로드 (presigned URL)

**Response (200):**
```json
{
  "download_url": "https://storage.../recordings/uuid.m4a?signature=...",
  "expires_at": "2026-03-02T13:00:00Z"
}
```

### DELETE /recordings/{id} `[Auth]`
녹음 삭제

### GET /recordings `[Auth]`
녹음 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `section_id` | string | 섹션 필터 |
| `student_id` | string | 학생 필터 |

### PATCH /recordings/{id}/representative `[Auth]`
대표 녹음 설정

**Request:**
```json
{ "is_representative": true }
```

### POST /recordings/{id}/share `[Auth]`
녹음 공유 링크 생성

**Response (200):**
```json
{
  "share_url": "https://api.lesson-app.com/shared/recordings/uuid",
  "expires_at": "2026-03-09T12:00:00Z"
}
```

---

## 10. Subscriptions (14 endpoints)

### Subscriptions (6)

#### GET /subscriptions `[Auth]`
수강권 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 필터 |
| `membership_id` | string | 소속 필터 |
| `status` | string | 상태 필터 |

#### POST /subscriptions `[Auth: Teacher]`
수강권 생성

**Request:**
```json
{
  "student_id": "uuid",
  "membership_id": "uuid",
  "type": "package",
  "total_lessons": 8,
  "amount": 400000,
  "start_date": "2026-03-01"
}
```

#### GET /subscriptions/{id} `[Auth]`
수강권 상세 (사용 이력 포함)

#### PUT /subscriptions/{id} `[Auth: Teacher]`
수강권 수정

#### PATCH /subscriptions/{id}/use-lesson `[Auth: Teacher]`
레슨 차감

**Request:**
```json
{
  "lesson_id": "uuid",
  "type": "lesson"
}
```

#### PATCH /subscriptions/{id}/confirm-payment `[Auth: Teacher]`
결제 확인

**Request:**
```json
{
  "payment_method": "bankTransfer"
}
```

### Templates (4)

#### GET /subscription-templates `[Auth: Teacher]`
템플릿 목록

#### POST /subscription-templates `[Auth: Teacher]`
템플릿 생성

**Request:**
```json
{
  "name": "기본 8회 패키지",
  "type": "package",
  "lessons_count": 8,
  "amount": 400000,
  "description": "2개월 기준 주 1회"
}
```

#### PUT /subscription-templates/{id} `[Auth: Teacher]`
템플릿 수정

#### DELETE /subscription-templates/{id} `[Auth: Teacher]`
템플릿 비활성화

### Proposals (4)

#### GET /subscription-proposals `[Auth]`
제안 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 필터 |
| `status` | string | 상태 필터 |

#### POST /subscription-proposals `[Auth: Teacher]`
수강권 제안

**Request:**
```json
{
  "student_id": "uuid",
  "template_id": "uuid",
  "message": "지난 체험 레슨 잘 하셨어요! 정규 수강권을 제안드립니다.",
  "template_ids": ["uuid1", "uuid2"],
  "recommended_template_id": "uuid1"
}
```

#### PATCH /subscription-proposals/{id}/respond `[Auth: Student]`
제안 응답 (수락/거절)

**Request (수락):**
```json
{
  "action": "accept",
  "selected_template_id": "uuid1"
}
```

**Request (거절):**
```json
{
  "action": "reject",
  "rejection_reason": "시간이 안 맞아요"
}
```

#### PATCH /subscription-proposals/{id}/confirm `[Auth: Teacher]`
결제 확인 후 수강권 확정

---

## 11. Schedule (7 endpoints)

### GET /schedule/availability `[Auth: Teacher]`
가용 시간 조회

### PUT /schedule/availability `[Auth: Teacher]`
가용 시간 설정

**Request:**
```json
{
  "availabilities": [
    {
      "day_of_week": 1,
      "time_slots": [
        { "start_time": "10:00", "end_time": "12:00" },
        { "start_time": "14:00", "end_time": "18:00" }
      ]
    },
    {
      "day_of_week": 3,
      "time_slots": [
        { "start_time": "10:00", "end_time": "18:00" }
      ]
    }
  ]
}
```

### GET /schedule/weekly `[Auth: Teacher]`
주간 스케줄 (가용시간 + 예약 통합)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `week_start` | string | 주 시작일 (YYYY-MM-DD) |

### GET /schedule/slots `[Auth]`
예약 가능 슬롯 조회

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `teacher_id` | string | 선생님 ID (필수) |
| `date` | string | 날짜 (필수) |
| `duration` | int | 레슨 시간 (기본: 60) |

**Response (200):**
```json
{
  "date": "2026-03-05",
  "slots": [
    { "start_time": "10:00", "end_time": "11:00", "status": "available" },
    { "start_time": "11:00", "end_time": "12:00", "status": "booked" },
    { "start_time": "14:00", "end_time": "15:00", "status": "available" }
  ]
}
```

### POST /schedule/exceptions `[Auth: Teacher]`
시간 예외 추가 (휴일/추가 오픈)

**Request:**
```json
{
  "date": "2026-03-10",
  "type": "holiday",
  "reason": "개인 사정"
}
```

### PUT /schedule/exceptions/{id} `[Auth: Teacher]`
예외 수정

### DELETE /schedule/exceptions/{id} `[Auth: Teacher]`
예외 삭제

---

## 12. Bookings (9 endpoints)

### GET /bookings `[Auth]`
예약 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `teacher_id` | string | 선생님 필터 |
| `student_id` | string | 학생 필터 |
| `status` | string | 상태 필터 |
| `date_from` | string | 시작일 |
| `date_to` | string | 종료일 |

### POST /bookings `[Auth]`
예약 요청

**Request:**
```json
{
  "teacher_id": "uuid",
  "lesson_type": "trial",
  "scheduled_date": "2026-03-10",
  "scheduled_time": "14:00",
  "duration": 60,
  "instrument": "violin",
  "notes": "체험 레슨 신청합니다"
}
```

### GET /bookings/{id} `[Auth]`
예약 상세

### PATCH /bookings/{id}/approve `[Auth: Teacher]`
예약 승인

### PATCH /bookings/{id}/reject `[Auth: Teacher]`
예약 거절

**Request:**
```json
{ "reason": "해당 시간 불가합니다" }
```

### PATCH /bookings/{id}/cancel `[Auth]`
예약 취소

**Request:**
```json
{ "reason": "개인 사정" }
```

### POST /bookings/{id}/change-request `[Auth]`
예약 변경 요청

**Request:**
```json
{
  "new_date": "2026-03-12",
  "new_time": "15:00",
  "reason": "시간 변경 요청"
}
```

### GET /bookings/makeup `[Auth]`
보강 레슨 목록

### POST /bookings/makeup `[Auth: Teacher]`
보강 레슨 생성

**Request:**
```json
{
  "student_id": "uuid",
  "original_lesson_id": "uuid",
  "scheduled_date": "2026-03-15",
  "scheduled_time": "16:00",
  "reason": "지난주 결석 보강"
}
```

---

## 13. Relationships (6 endpoints)

### POST /relationships/invite `[Auth: Teacher]`
학생 연결 초대

**Request:**
```json
{
  "student_id": "uuid",
  "method": "sms"
}
```

### POST /relationships/connect `[Auth: Student]`
연결 수락 (초대 코드)

**Request:**
```json
{ "invite_code": "ABC123" }
```

### GET /relationships `[Auth]`
내 연결 목록

### PATCH /relationships/{id}/status `[Auth]`
연결 상태 변경

**Request:**
```json
{ "status": "disconnected" }
```

### POST /follows `[Auth]`
팔로우

**Request:**
```json
{
  "following_id": "uuid",
  "target_type": "teacher"
}
```

### DELETE /follows/{id} `[Auth]`
언팔로우

---

## 14. Parents (6 endpoints)

### GET /parents/me `[Auth: Parent]`
학부모 프로필

### PUT /parents/me `[Auth: Parent]`
프로필 수정

### GET /parents/me/children `[Auth: Parent]`
자녀 목록

### POST /parents/me/children `[Auth: Parent]`
자녀 연결

**Request:**
```json
{
  "invite_code": "XYZ789"
}
```

### GET /parents/me/children/{studentId}/lessons `[Auth: Parent]`
자녀 레슨 조회

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `date_from` | string | 시작일 |
| `date_to` | string | 종료일 |

### GET /parents/me/children/{studentId}/practice `[Auth: Parent]`
자녀 연습 현황

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `year` | int | 연도 |
| `month` | int | 월 |

---

## 15. Notifications (4 endpoints)

### GET /notifications `[Auth]`
알림 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `is_read` | bool | 읽음 필터 |
| `type` | string | 알림 타입 필터 |

### PATCH /notifications/{id}/read `[Auth]`
알림 읽음 처리

### PATCH /notifications/read-all `[Auth]`
모든 알림 읽음 처리

### GET /notifications/unread-count `[Auth]`
읽지 않은 알림 수

**Response (200):**
```json
{ "count": 5 }
```

---

## 16. Payments (8 endpoints)

### GET /payments `[Auth]`
결제 목록

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `student_id` | string | 학생 필터 |
| `status` | string | 상태 필터 |
| `date_from` | string | 시작일 |
| `date_to` | string | 종료일 |

### POST /payments `[Auth: Teacher]`
결제 생성

**Request:**
```json
{
  "student_id": "uuid",
  "amount": 200000,
  "due_date": "2026-03-10",
  "lesson_count": 4,
  "period_start": "2026-03-01",
  "period_end": "2026-03-31"
}
```

### GET /payments/{id} `[Auth]`
결제 상세

### PUT /payments/{id} `[Auth: Teacher]`
결제 수정

### PATCH /payments/{id}/confirm `[Auth: Teacher]`
결제 확인 (선생님)

### PATCH /payments/{id}/student-confirm `[Auth: Student/Parent]`
결제 확인 (학생/학부모)

### GET /payments/summary `[Auth: Teacher]`
결제 요약 (대시보드)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `year` | int | 연도 |
| `month` | int | 월 |

**Response (200):**
```json
{
  "total_received": 2400000,
  "total_pending": 600000,
  "total_overdue": 200000,
  "paid_students": 10,
  "unpaid_students": 3,
  "overdue_students": 1
}
```

### DELETE /payments/{id} `[Auth: Teacher]`
결제 취소

---

## 17. Migration (2 endpoints)

### POST /migration/upload `[Auth]`
Hive 데이터 일괄 업로드 (마이그레이션용)

**Request:**
```json
{
  "students": [...],
  "lessons": [...],
  "subscriptions": [...],
  "practice_repertoires": [...],
  "practice_sections": [...],
  "recordings_metadata": [...]
}
```

**Response (200):**
```json
{
  "imported": {
    "students": 15,
    "lessons": 120,
    "subscriptions": 15,
    "practice_repertoires": 30,
    "practice_sections": 90,
    "recordings": 45
  },
  "id_mappings": {
    "students": { "old_uuid": "new_uuid", ... },
    "lessons": { "old_uuid": "new_uuid", ... }
  }
}
```

### GET /migration/status `[Auth]`
마이그레이션 상태 조회

---

## 엔드포인트 총 개수

| 도메인 | 개수 |
|--------|------|
| Auth | 4 |
| Users | 5 |
| Teachers | 5 |
| Students | 6 |
| Lesson Classes | 8 |
| Lessons | 8 |
| Practice | 15 |
| Practice Items | 5 |
| Recordings | 7 |
| Subscriptions | 14 |
| Schedule | 7 |
| Bookings | 9 |
| Relationships | 6 |
| Parents | 6 |
| Notifications | 4 |
| Payments | 8 |
| Migration | 2 |
| **Total** | **119** |

---

## HTTP 상태 코드

| 코드 | 의미 | 사용 |
|------|------|------|
| 200 | OK | 조회, 수정 성공 |
| 201 | Created | 생성 성공 |
| 204 | No Content | 삭제 성공 |
| 400 | Bad Request | 요청 형식 오류 |
| 401 | Unauthorized | 인증 필요/실패 |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스 없음 |
| 409 | Conflict | 중복/충돌 |
| 422 | Unprocessable Entity | 검증 실패 |
| 429 | Too Many Requests | Rate limit 초과 |
| 500 | Internal Server Error | 서버 오류 |
