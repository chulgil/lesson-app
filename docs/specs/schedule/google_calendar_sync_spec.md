# Google Calendar 동기화 스펙

> 작성일: 2026-05-31
> 상태: 초안
> 관련 스펙: [schedule_master.md](schedule_master.md), [teacher_availability_spec.md](teacher_availability_spec.md)

---

## 1. 개요

### 1.1 문제 정의

선생님이 Lessonaza와 Google Calendar를 **이중으로 관리**하는 불편이 있다.

- 레슨 등록 시 앱과 Google Calendar에 각각 입력
- Google Calendar에서 개인 일정을 변경해도 Lessonaza 가용 시간에 반영되지 않음
- 이중 관리로 인한 일정 충돌 및 누락 위험

### 1.2 경쟁사 벤치마크

| 서비스 | 동기화 방식 | 특이사항 |
|--------|------------|---------|
| My Music Staff | 양방향 완전 동기화 | iCal + Google Calendar 모두 지원 |
| Fons | 단방향 push (Fons → Google) | FreeBusy 기반 차단 병행 |
| Calendly | 양방향 + FreeBusy 차단 | 다중 캘린더 연결 지원 |
| Acuity Scheduling | 단방향 push + FreeBusy | 캘린더 연동이 핵심 기능 |

### 1.3 동기화 방향 결정

**Lessonaza가 SSOT(Single Source of Truth)**임을 전제로 단계별 도입.

| 단계 | 방향 | 설명 |
|------|------|------|
| 1단계 | Lessonaza → Google (단방향 push) | 레슨 이벤트를 Google Calendar에 자동 반영 |
| 2단계 | Google → Lessonaza (FreeBusy 차단) | Google Calendar 이벤트를 가용시간 차단에 반영 |
| 3단계 | 양방향 완전 동기화 | Google에서 생성한 이벤트도 Lessonaza에 반영 |

> Apple Calendar (CalDAV)는 별도 스펙으로 분리. 본 스펙은 Google Calendar API v3 전용.

---

## 2. 범위

### 2.1 1단계: Lessonaza → Google Calendar (단방향 push)

**포함:**
- 레슨 생성 → Google Calendar 이벤트 자동 생성
- 레슨 수정 (시간, 장소, 노트) → Google Calendar 이벤트 자동 업데이트
- 레슨 삭제/취소 → Google Calendar 이벤트 자동 삭제 또는 색상 변경
- 레슨 상태 변경 (예정 → 완료/취소) → 이벤트 색상 자동 반영

**제외:**
- Google Calendar에서 직접 수정한 내용을 Lessonaza에 반영 (2단계)
- Apple Calendar, Outlook Calendar 연동 (별도 스펙)

### 2.2 2단계: Google Calendar → Lessonaza (FreeBusy 차단)

**포함:**
- Google Calendar의 기존 이벤트 조회 (FreeBusy API)
- 이벤트가 있는 시간대를 선생님 가용 시간에서 자동 차단
- 학생 예약 시 차단된 시간 필터링

**제외:**
- Google Calendar 이벤트의 세부 내용(제목, 설명) 읽기 (프라이버시)
- Google Calendar에서 직접 레슨 생성 (3단계)

### 2.3 3단계: 양방향 완전 동기화 (미래 계획)

- Google Calendar에서 직접 레슨 이벤트 생성 → Lessonaza에 반영
- 충돌 해결 정책: Lessonaza 우선 (SSOT 원칙)

---

## 3. Google Calendar API 사용

### 3.1 OAuth 2.0 인증

**Google Cloud Console 설정:**
```
1. 새 프로젝트 생성 (또는 기존 프로젝트 사용)
2. Google Calendar API 활성화
3. OAuth 2.0 클라이언트 ID 생성 (Web application 타입)
4. Authorized redirect URIs 등록:
   - https://api.lessonaza.com/integrations/google-calendar/callback
   - http://localhost:8000/integrations/google-calendar/callback (개발용)
```

**OAuth 2.0 스코프:**
```
# 읽기 + 쓰기 (1단계 push 용)
https://www.googleapis.com/auth/calendar

# 읽기 전용 (FreeBusy 조회 용, 2단계 전환 가능)
https://www.googleapis.com/auth/calendar.readonly
```

> 최소 권한 원칙: 1단계는 `calendar` 전체 권한이 필요하나, 2단계 전용이면 `calendar.readonly`로 축소 가능.

**토큰 흐름:**
```
Flutter 앱
  → WebView로 OAuth 동의 화면 열기
  → 사용자 동의
  → Google이 authorization_code 반환
  → 백엔드 /callback 엔드포인트로 code 전달
  → 백엔드에서 access_token + refresh_token 교환
  → refresh_token을 AES-256 암호화 후 DB 저장
  → access_token은 메모리/캐시에만 보관 (만료 1시간)
```

### 3.2 이벤트 매핑

**Lessonaza Lesson → Google Calendar Event:**

| Lessonaza 필드 | Google Calendar 필드 | 예시 |
|---------------|---------------------|------|
| `student.name` + `instrument` | `summary` | "김지수 — 피아노 레슨" |
| `lesson.date` + `start_time` | `start.dateTime` | "2026-06-01T10:00:00+09:00" |
| `start_time` + `duration_minutes` | `end.dateTime` | "2026-06-01T11:00:00+09:00" |
| `lesson.location` | `location` | "강남구 역삼동 123" |
| `lesson.notes` | `description` | 레슨 메모 내용 |
| `lesson.id` | `extendedProperties.private.lessonaza_lesson_id` | "uuid-..." |
| `subscription.id` | `extendedProperties.private.lessonaza_subscription_id` | "uuid-..." |
| 타임존 | `start.timeZone` / `end.timeZone` | "Asia/Seoul" |

**summary 포맷:**
```
"{학생 이름} — {악기} 레슨"

# 예시
"김지수 — 피아노 레슨"
"박민준 — 바이올린 레슨"
"(그룹) 초급 피아노 — 3명"  # 그룹 레슨
```

### 3.3 색상 매핑

Google Calendar colorId 기준 (1–11):

| Lessonaza 상태 | colorId | 색상 이름 | 의미 |
|---------------|---------|---------|------|
| `scheduled` (예정) | 9 | Blueberry | 확정된 레슨 |
| `completed` (완료) | 10 | Sage | 완료된 레슨 |
| `cancelled` (취소) | 11 | Tomato | 취소된 레슨 |
| `no_show` (노쇼) | 6 | Tangerine | 노쇼 처리 |

---

## 4. 동기화 전략

### 4.1 단방향 Push (1단계)

**레슨 생성:**
```
lesson_service.create_lesson()
  → lesson DB 저장 (google_event_id = null)
  → GoogleCalendarService.create_event(lesson)
    → Google Calendar API: POST /calendars/{calendar_id}/events
    → 성공: lesson.google_event_id 업데이트
    → 실패: 동기화 실패 로그 기록, Lesson은 정상 생성 유지
           재시도 큐에 추가 (최대 3회 지수 백오프)
```

**레슨 수정:**
```
lesson_service.update_lesson()
  → lesson DB 업데이트
  → GoogleCalendarService.update_event(lesson)
    → google_event_id 없으면 create_event() 호출 (복구)
    → Google Calendar API: PATCH /calendars/{id}/events/{eventId}
    → 실패: 동기화 실패 로그, 재시도 큐 추가
```

**레슨 삭제/취소:**
```
lesson_service.delete_lesson() / cancel_lesson()
  → lesson DB 삭제 또는 상태 변경
  → GoogleCalendarService.delete_event(google_event_id)
    → 취소: 이벤트 색상만 변경 (삭제 아님, 히스토리 보존)
    → 삭제: Google Calendar API: DELETE /calendars/{id}/events/{eventId}
    → 실패: 로그만 기록 (이미 DB에서 삭제됨)
```

### 4.2 FreeBusy 기반 가용시간 차단 (2단계)

```
선생님이 "Google Calendar 연동" 설정에서 "개인 일정 차단" 활성화
  → 학생이 레슨 예약 시작
  → ScheduleService.get_available_slots(teacher_id, date)
    → GoogleCalendarService.get_busy_times(teacher_id, date_range)
      → Google Calendar API: POST /freeBusy
        {
          "timeMin": "2026-06-01T00:00:00+09:00",
          "timeMax": "2026-06-01T23:59:59+09:00",
          "items": [{"id": "calendar_id"}]
        }
      → busy 시간대 목록 반환
    → busy 시간과 겹치는 슬롯 필터링
  → 학생에게 가용 슬롯만 노출
```

**중요**: FreeBusy API는 이벤트 제목/내용은 반환하지 않음 (시간만). 선생님의 개인 정보 보호.

### 4.3 충돌 해결 정책

| 상황 | 처리 |
|------|------|
| Lessonaza에서 수정, Google에서도 수정 | Lessonaza 우선 (다음 sync 시 덮어씀) |
| Google에서 Lessonaza 이벤트 삭제 | Lessonaza에서 경고 알림, 자동 삭제 없음 |
| Google 캘린더 자체가 삭제됨 | 연동 해제 + 선생님에게 알림 |
| 이벤트 ID 불일치 (오래된 토큰) | google_event_id 재발급 후 재생성 |

### 4.4 배치 동기화 (수동 전체 동기화)

```
POST /integrations/google-calendar/sync
  → 연동된 선생님의 모든 upcoming 레슨 조회
  → google_event_id가 없는 레슨: create_event()
  → google_event_id가 있는 레슨: update_event() (최신 상태 동기화)
  → 결과 리포트 반환 {synced: N, failed: M, skipped: K}
```

---

## 5. 백엔드 설계

### 5.1 GoogleCalendarService

파일 위치: `backend/app/services/google_calendar_service.py`

```python
class GoogleCalendarService:
    """Google Calendar API 연동 서비스."""

    async def get_credentials(self, teacher_id: UUID) -> Credentials
    async def create_event(self, teacher_id: UUID, lesson: Lesson) -> str  # google_event_id 반환
    async def update_event(self, teacher_id: UUID, lesson: Lesson) -> None
    async def delete_event(self, teacher_id: UUID, google_event_id: str) -> None
    async def get_busy_times(self, teacher_id: UUID, time_min: datetime, time_max: datetime) -> list[BusyPeriod]
    async def list_calendars(self, teacher_id: UUID) -> list[CalendarInfo]
```

**의존성:** `google-api-python-client`, `google-auth-oauthlib`, `google-auth-httplib2`

### 5.2 DB 모델

**신규 테이블: `google_calendar_tokens`**

```sql
CREATE TABLE google_calendar_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id      UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    access_token    TEXT NOT NULL,          -- AES-256 암호화
    refresh_token   TEXT NOT NULL,          -- AES-256 암호화
    expires_at      TIMESTAMPTZ NOT NULL,
    calendar_id     TEXT NOT NULL,          -- 선택된 캘린더 ID (primary = 기본 캘린더)
    sync_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
    freebusy_enabled BOOLEAN NOT NULL DEFAULT FALSE,  -- 2단계 기능
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (teacher_id)
);
```

**기존 테이블 변경: `lessons`**

```sql
ALTER TABLE lessons
    ADD COLUMN google_event_id TEXT,        -- Google Calendar 이벤트 ID
    ADD COLUMN google_sync_status TEXT      -- 'synced' | 'pending' | 'failed' | null
        CHECK (google_sync_status IN ('synced', 'pending', 'failed'));

CREATE INDEX idx_lessons_google_event_id ON lessons(google_event_id)
    WHERE google_event_id IS NOT NULL;
```

### 5.3 API 엔드포인트

**통합 관리:**

| Method | Path | 설명 |
|--------|------|------|
| `POST` | `/integrations/google-calendar/connect` | OAuth 시작 (authorization URL 반환) |
| `GET` | `/integrations/google-calendar/callback` | OAuth 콜백 처리, 토큰 저장 |
| `DELETE` | `/integrations/google-calendar/disconnect` | 연동 해제, 토큰 완전 삭제 |
| `POST` | `/integrations/google-calendar/sync` | 수동 전체 동기화 실행 |
| `GET` | `/integrations/google-calendar/status` | 연동 상태 조회 |
| `GET` | `/integrations/google-calendar/calendars` | 선택 가능한 캘린더 목록 |
| `PATCH` | `/integrations/google-calendar/settings` | 캘린더 선택 + 설정 변경 |

**상태 응답 예시:**
```json
{
  "connected": true,
  "calendar_id": "primary",
  "calendar_name": "cglee@gmail.com",
  "sync_enabled": true,
  "freebusy_enabled": false,
  "last_synced_at": "2026-05-31T10:00:00+09:00",
  "pending_sync_count": 0
}
```

### 5.4 토큰 갱신 처리

```python
async def get_credentials(self, teacher_id: UUID) -> Credentials:
    token = await db.get(GoogleCalendarToken, teacher_id=teacher_id)
    credentials = Credentials(
        token=decrypt(token.access_token),
        refresh_token=decrypt(token.refresh_token),
        ...
    )
    if credentials.expired:
        credentials.refresh(Request())
        # 갱신된 access_token DB 업데이트
        await db.update(token, access_token=encrypt(credentials.token))
    return credentials
```

---

## 6. 프론트엔드 설계

### 6.1 연동 설정 화면

**위치:** 프로필/설정 탭 > "외부 서비스 연동" 섹션

**연동 전 상태:**
```
[Google Calendar]  ─── [연동하기]
Google 계정으로 레슨 일정을 자동 동기화합니다.
```

**연동 중 (OAuth WebView):**
```
WebView로 Google 동의 화면 표시
→ 동의 완료 시 딥링크로 앱으로 복귀
→ 성공/실패 Snackbar 표시
```

**연동 후 상태:**
```
[Google Calendar]  ─── [연동됨 ✓]
cglee@gmail.com
캘린더: 내 캘린더 ▼  (드롭다운으로 캘린더 선택)

☑ 레슨 일정을 Google Calendar에 자동 저장
☐ Google Calendar 개인 일정으로 예약 차단 (2단계)

[동기화 범위] 오늘부터 ▼
[수동 동기화]  [연동 해제]
```

**동기화 범위 옵션:**
- 오늘부터 (기본)
- 이번 달부터
- 3개월 전부터 (과거 레슨 포함)

### 6.2 레슨 상세에서 표시

**동기화 성공 시:**
```
레슨 상세 카드 우측 상단: 작은 Google Calendar 아이콘 (회색)
```

**동기화 실패 시:**
```
레슨 카드에 경고 아이콘 (⚠️)
탭 시: "Google Calendar 동기화 실패. [재시도]"
```

**파일 위치:**
- 설정 화면: `features/profile/presentation/screens/integrations_settings_page.dart`
- Google Calendar 설정: `features/profile/presentation/screens/google_calendar_settings_page.dart`
- 레슨 카드 배지: `features/lesson/presentation/widgets/google_sync_badge.dart`

---

## 7. 보안

### 7.1 토큰 암호화

```python
# AES-256-GCM 암호화 (app/utils/encryption.py)
# KEY는 환경변수 GOOGLE_TOKEN_ENCRYPTION_KEY에서 로드
def encrypt_token(plaintext: str) -> str: ...
def decrypt_token(ciphertext: str) -> str: ...
```

- `GOOGLE_TOKEN_ENCRYPTION_KEY`: 32바이트 랜덤 키, `.env`에 저장, git 추적 금지
- access_token, refresh_token 모두 암호화 저장
- 로그에 토큰 값 절대 출력 금지

### 7.2 OAuth 보안 모범 사례

- **PKCE 사용**: 모바일 환경에서 `code_verifier` 생성 (RFC 7636)
- **state 파라미터**: CSRF 방지용 랜덤 토큰 (세션당 1회 사용)
- **토큰 범위 최소화**: 필요한 스코프만 요청
- **연동 해제 시 완전 삭제**: `revoke_token()` 호출 + DB에서 삭제

### 7.3 데이터 최소화

- FreeBusy API만 사용할 경우 이벤트 제목/내용 조회 안 함
- Google Calendar 이벤트 데이터는 서버에 캐시하지 않음
- `extendedProperties`에만 Lessonaza 식별자 저장

---

## 8. 에러 처리

| 에러 상황 | 대응 방식 |
|----------|----------|
| OAuth 토큰 만료 (access_token) | `google-auth` 라이브러리의 자동 refresh 사용 |
| refresh_token 만료/무효 | 재인증 요청 알림 + 연동 상태 `expired`로 변경 |
| API 할당량 초과 (429) | 지수 백오프 재시도 (1s → 2s → 4s, 최대 3회) |
| 이벤트 생성 실패 | Lesson은 정상 생성 유지, `google_sync_status = 'failed'`, 재시도 큐 추가 |
| Google Calendar 이벤트가 삭제됨 | `google_event_id` null 처리, 다음 sync에서 재생성 |
| 선택한 캘린더가 삭제됨 | 연동 해제 + 선생님에게 푸시 알림 |
| 네트워크 타임아웃 | 3초 타임아웃, 실패 시 비동기 재시도 |

**동기화 실패 허용 원칙:**
> Google Calendar 동기화 실패는 Lessonaza 핵심 기능(레슨 관리)을 차단하지 않는다.
> 실패는 로그에 기록하고 배경에서 재시도한다.

---

## 9. 테스트 계획

### 9.1 단위 테스트

- `GoogleCalendarService` 메서드별 mock API 테스트
- 토큰 암호화/복호화 검증
- 이벤트 매핑 함수 (Lesson → Google Event) 검증

### 9.2 통합 시나리오 테스트

```python
@pytest.mark.asyncio
async def test_gc_lesson_sync_full_cycle(teacher: TeacherActions):
    """레슨 생성 → Google 이벤트 확인 → 수정 → 삭제 전체 사이클."""
    # 1. Google Calendar 연동 활성화 (mock OAuth)
    await teacher.connect_google_calendar(mock_token=MOCK_GOOGLE_TOKEN)

    # 2. 레슨 생성 → Google 이벤트 자동 생성 확인
    lesson_id = await teacher.create_lesson(student_id=..., date="2026-06-01")
    lesson = await teacher.get_lesson(lesson_id)
    assert lesson.google_event_id is not None
    assert lesson.google_sync_status == "synced"

    # 3. 레슨 수정 → Google 이벤트 업데이트 확인
    await teacher.update_lesson(lesson_id, notes="수정된 노트")
    # mock API call 검증

    # 4. 레슨 삭제 → Google 이벤트 삭제 확인
    await teacher.delete_lesson(lesson_id)
    # mock API: DELETE 호출 검증
```

### 9.3 에러 시나리오

- OAuth 토큰 만료 후 자동 갱신 테스트
- API 할당량 초과 시 재시도 로직 테스트
- Google Calendar 응답 없을 때 Lesson 정상 생성 확인

---

## 10. 구현 단계

| 단계 | 범위 | 예상 공수 | 선행 조건 |
|------|------|----------|----------|
| **1** | Google Cloud 프로젝트 설정 + OAuth 앱 등록 | 1일 | — |
| **2** | DB 모델 (GoogleCalendarToken, Lesson 필드 추가) + 마이그레이션 | 1일 | — |
| **3** | `GoogleCalendarService` 구현 + 단위 테스트 | 3일 | 2단계 완료 |
| **4** | OAuth API 엔드포인트 (connect/callback/disconnect/status) | 2일 | 3단계 완료 |
| **5** | 레슨 CRUD 훅 (생성/수정/삭제 시 자동 동기화) | 2일 | 3, 4단계 완료 |
| **6** | 프론트엔드 연동 설정 화면 | 3일 | 4단계 완료 |
| **7** | 레슨 카드 동기화 배지 + 에러 표시 | 1일 | 5단계 완료 |
| **8** | 통합 시나리오 테스트 + 베타 배포 | 3일 | 6, 7단계 완료 |
| **2단계** | FreeBusy 기반 가용시간 차단 | 1주 | 1단계 안정화 후 |

**총 1단계 공수:** 약 3주 (백엔드 1.5주 + 프론트엔드 1주 + QA 0.5주)

---

## 11. 관련 스펙 / 변경 이력

### 관련 스펙

- [schedule_master.md](schedule_master.md) — 슬롯 기반 예약 시스템 (SSOT)
- [teacher_availability_spec.md](teacher_availability_spec.md) — 선생님 가용시간 관리
- `docs/specs/integrations/` — 외부 서비스 연동 (신규 생성 예정)

### 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| 2026-05-31 | v0.1 | 초안 작성 (1단계 + 2단계 설계) |
