# slug_lifecycle_spec — 선생님 프로필 slug 휴면/회수 정책

> 기준일: 2026-05-19 (Option D 정렬)
> 우선: 🟡 HIGH (외부 공유 URL 보호 — Year 1 출시 전 정착 필요)
> 선행: [signup_spec.md](../web/signup_spec.md), [profile_spec.md](../web/profile_spec.md), [../profile/public_profile_content_spec.md](../profile/public_profile_content_spec.md), [account_lifecycle_spec.md](./account_lifecycle_spec.md)

## 1. 개요

선생님이 가입 시 선점하는 `profile_slug` 는 `profile.lessonaza.app/{slug}` URL 의 일부이며, 외부 SNS/카카오톡으로 공유된다. 따라서 **외부 공유 URL 보호** 와 **장기 미사용 자원 회수** 의 균형이 필요하다.

**참조 모델**: League of Legends 소환사명 휴면 정책 (12개월 미접속 → 풀에 반환).

### 1.1 책임

- slug 형식/예약어 검증
- 활동성(activity) 정의 + 측정
- 6/9/12개월 휴면 진입 알림
- 12개월 도달 시 dormant guide page 전환
- 13개월 도달 시 slug 풀 반환 + 3개월 cooldown
- 재선점 후 옛 콘텐츠 노출 차단

### 1.2 비책임

- 계정 삭제/복구 — `account_lifecycle_spec` 담당
- `TeacherProfile` 콘텐츠 관리 — `public_profile_content_spec` / `profile_spec` 담당
- 가입 시점 slug 발급 — `signup_spec` 담당

## 2. 성공 기준

- [SC-1] 활동 사용자(앱 로그인 OR 프로필 편집)는 무기한 slug 유지
- [SC-2] 12개월 미활동 사용자에게 6/9/12개월에 알림 3회 발송
- [SC-3] 13개월 도달 시 slug 풀 반환, 3개월 cooldown 후 재선점 가능
- [SC-4] 옛 사용자의 콘텐츠가 새 사용자에게 절대 노출되지 않음 (`TeacherProfile` 분리)
- [SC-5] 운영자는 침해/저작권 신고 시 slug 즉시 회수 가능
- [SC-6] slug 변경은 Year 1 동안 가입 후 60일 내 1회만 허용

## 3. slug 형식 / 예약어

### 3.1 형식 규칙

- 영문 소문자 (`a-z`) + 숫자 (`0-9`) + 하이픈 (`-`)
- 3~30자
- 하이픈 시작/끝 금지
- 연속 하이픈 (`--`) 금지
- 숫자만으로 구성 금지 (예: `12345`)

```python
SLUG_PATTERN = r"^(?![\d-]+$)[a-z0-9]+(-[a-z0-9]+)*$"
SLUG_MIN_LEN = 3
SLUG_MAX_LEN = 30
```

### 3.2 예약어 (`SlugReservedWord` 테이블)

| 카테고리 | 예시 |
|---|---|
| 시스템 경로 | `admin`, `api`, `www`, `terms`, `privacy`, `signup`, `login`, `verify-email`, `edit`, `static`, `well-known`, `assets`, `images` |
| 브랜드 | `lessonaza`, `lessonaza-app`, `lessonaza-official` |
| 욕설/비속어 | (별도 사전 — 운영자 관리) |
| 유명인 | 동명이인 분쟁 방지 정책 (사후 신고 처리) — 사전 차단은 안 함 |

```python
class SlugReservedWord(Base):
    __tablename__ = "slug_reserved_words"
    word = Column(String(50), primary_key=True)
    category = Column(String(20))  # "system" | "brand" | "vulgar" | "celebrity"
    created_at = Column(DateTime, server_default=func.now())
```

운영자가 관리자 페이지에서 추가/삭제. 시스템 경로 카테고리는 코드 deploy 시 시드 데이터로 자동 동기화.

## 4. slug 변경 정책

### 4.1 Year 1 정책 (보수적)

- 가입 후 **60일 이내 1회 한정** 변경 허용
- 변경 시 옛 slug 는 즉시 풀 반환 (cooldown 없음 — 본인 변경)
- 60일 이후 변경 = 운영자 수동 처리 (사업 사유 검토)

### 4.2 Year 2 백로그

- 검토 기준: 사용자 요청 누적 시
- 옵션 A: 연 1회 자유 변경
- 옵션 B: 변경 시 옛 slug → 3개월 cooldown (휴면 회수와 동일)

## 5. 활동성 정의

### 5.1 활동 기준 (둘 중 하나)

- `last_app_login_at` — 앱에서 로그인 (모든 디바이스)
- `last_profile_edit_at` — 인앱 편집 화면에서 프로필 수정 (`TeacherProfile` 변경)

둘 중 최신값을 `User.last_activity_at` 으로 갱신. 단순 페이지 조회는 제외 (편집권자만 활동으로 카운트).

### 5.2 측정 방법

- 앱 로그인 시 백엔드가 `User.last_app_login_at = now()` 갱신
- 프로필 PUT 시 `User.last_activity_at = now()` 갱신
- 매일 배치: 두 값 중 최신값을 `last_activity_at` 에 reconcile (idempotent)

### 5.3 비활동 측정

```
inactive_days = (now - last_activity_at).days
```

## 6. 휴면 진입 일정

```
T+0       가입 / 마지막 활동
T+180일   휴면 알림 1 (6개월)
T+270일   휴면 알림 2 (9개월) + 만료 경고
T+365일   휴면 진입 (12개월) → dormant guide page
T+395일   30일 grace (1개월 유예) — 로그인하면 즉시 복구
T+395일   slug 풀 반환 + 3개월 cooldown 시작
T+485일   slug 재선점 가능 (FCFS)
```

### 6.1 알림 1 (6개월, T+180)

- 채널: 이메일 (가입 이메일)
- 제목: "[Lessonaza] 6개월간 미접속 — 프로필이 곧 휴면 상태가 돼요"
- 본문 요약: "지금 로그인하면 프로필이 유지돼요. 1년 이상 미접속 시 프로필 주소가 다른 분께 이전될 수 있어요"
- CTA: "로그인하기" (모바일 → 앱 딥링크, 데스크탑 → 웹 로그인)
- 기록: `User.dormant_notice_6m_at = now()`

### 6.2 알림 2 (9개월, T+270)

- 동일 채널, 더 강한 경고 톤
- 제목: "[Lessonaza] 곧 프로필 주소가 회수돼요 — 3개월 남음"
- 본문: 휴면 일정표 명시 (12개월 → 휴면, 13개월 → 회수)
- 기록: `User.dormant_notice_9m_at = now()`

### 6.3 휴면 진입 (12개월, T+365)

- `Teacher.dormant_entered_at = now()` 설정
- `Teacher.profile_visibility = "dormant"` + `TeacherProfile.status = "dormant"` 전환
- 백엔드가 `POST /internal/cache/invalidate {slug}` 호출 → renderer 캐시 즉시 제거
- `profile.lessonaza.app/{slug}` 요청 시 renderer 가 410 Gone 응답 + **dormant guide page** 표시:

```
┌──────────────────────────────────────┐
│  ♩ Lessonaza                          │
│                                       │
│  이 프로필은 잠시 휴면 상태예요         │
│                                       │
│  선생님이 30일 안에 로그인하면           │
│  프로필이 복구돼요.                    │
│                                       │
│  ─── 5선 ───                           │
│                                       │
│  다른 선생님 찾기 →                    │
│  앱 다운로드 →                         │
└──────────────────────────────────────┘
```

- 알림 3 발송: "[Lessonaza] 프로필이 휴면 상태로 전환됐어요 — 30일 안에 로그인하면 복구돼요"

### 6.4 Slug 회수 (13개월, T+395)

- `Teacher.slug_released_at = now()` 설정
- `Teacher.profile_slug = NULL` 처리
- `TeacherProfile` 은 **유지** (status="archived", `slug` 컬럼은 `archived-{teacher_id}-{uuid}` 로 rename). 다음 단계 (T+485) 까지 보존.
- `SlugHistory` 레코드 갱신: `released_at = now()`, `release_reason = "dormant"`, `cooldown_until = now() + 90d`

### 6.5 Cooldown (16개월, T+395 ~ T+485)

- 누구도 해당 slug 선점 불가
- `GET /slug/check?slug=...` → "최근 회수된 주소예요. 3개월 후 사용 가능"
- 이유: 옛 사용자가 늦게 복구 요청 가능성 + 외부 링크 잔존 보호

### 6.6 재선점 가능 (T+485 이후)

- FCFS (선착순)
- 새 사용자가 가입 시 해당 slug 선택 가능
- 옛 `TeacherProfile` 은 **새 사용자에게 절대 이관 안 됨**:
  - 옛 프로필은 `status="archived"` + `slug="archived-{teacher_id}-{uuid}"` 로 영구 보관
  - 새 사용자는 신규 `TeacherProfile` 발급 (status=draft)
  - 외부에서 옛 URL 접근 시 새 사용자 프로필 표시 (콘텐츠는 새것)

## 7. 복구 흐름

### 7.1 휴면 진입 전 (T-180 ~ T+365)

- 로그인 또는 프로필 편집 1회 → `last_activity_at` 갱신 → 휴면 시계 리셋
- 알림 메일 클릭 → 인앱/웹 로그인 → 즉시 복구
- 백엔드: `dormant_notice_*_at` 필드는 보존 (감사용)

### 7.2 휴면 ~ 회수 전 (T+365 ~ T+395, 30일 grace)

- 로그인 시도 → "프로필이 휴면 상태예요. 복구하시겠어요?" 모달
- 복구 동의 → `dormant_entered_at = NULL`, `Teacher.profile_visibility = "public"`, `TeacherProfile.status = "public"` (첫 승인 이력 있을 경우. 없으면 status=draft 로 되돌리고 재검토)
- 백엔드가 renderer 캐시 무효화 webhook 호출
- 백엔드 AuditLog: `profile_restored`

### 7.3 회수 후 (T+395 이후)

- slug 자체는 회수됨 → 옛 URL 접근 시 cooldown 또는 새 사용자 페이지 노출
- 옛 사용자는 로그인 가능하나 새 slug 선택 필요 (가입 직후처럼)
- 운영자 수동 처리로 옛 slug 복구 = **불가** (정책상 거부)

## 8. 운영자 회수 (즉시)

### 8.1 사유

- 저작권 침해 신고 (1차 신고만으로 즉시 회수, 분쟁 시 사후 검토)
- 욕설/혐오/사기 콘텐츠
- 동명이인 분쟁 (운영자 판단)
- 미인증/허위 계정 적발

### 8.2 처리

```
1. 운영자 → POST /api/v1/admin/teachers/{id}/revoke-slug
   { "reason": "...", "cooldown_days": 365 }
2. 백엔드:
   - Teacher.profile_slug = NULL
   - SlugHistory.released_at = now, release_reason = "admin_revoked"
   - SlugHistory.cooldown_until = now + N days (기본 365일 — 분쟁 슬러그는 1년)
   - TeacherProfile.status = "archived" + slug rename
   - renderer 캐시 무효화 webhook 호출
   - AuditLog: slug_revoked_by_admin
3. 알림 메일: "[Lessonaza] 프로필 주소 회수 안내"
```

## 9. 데이터 모델

### 9.1 SlugHistory

```python
class SlugHistory(Base):
    __tablename__ = "slug_history"
    id = Column(Integer, primary_key=True)
    slug = Column(String(30), nullable=False, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id"))
    assigned_at = Column(DateTime, server_default=func.now())
    released_at = Column(DateTime, nullable=True)
    release_reason = Column(
        String(50), nullable=True
    )  # "user_changed" | "dormant" | "admin_revoked" | "account_deleted"
    cooldown_until = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)  # 운영자 메모
```

- 같은 slug가 여러 row 가능 (재선점 이력)
- 활성 row: `released_at IS NULL` (현재 보유자)
- `GET /slug/check` 시 cooldown 검사: `cooldown_until > now`인 row 있으면 차단

### 9.2 SlugReservedWord (§3.2 참조)

### 9.3 Teacher 모델 확장 필드 (signup_spec §7.2 참조)

```python
last_app_login_at: DateTime | None
last_activity_at: DateTime  # default = func.now(), index=True
dormant_notice_6m_at: DateTime | None
dormant_notice_9m_at: DateTime | None
dormant_entered_at: DateTime | None
slug_released_at: DateTime | None
```

## 10. 백엔드 배치 잡

### 10.1 일일 배치 (KST 03:00)

```
1. SELECT * FROM users WHERE last_activity_at < now - 180d
   AND dormant_notice_6m_at IS NULL
   → 알림 1 발송 + dormant_notice_6m_at = now

2. SELECT * FROM users WHERE last_activity_at < now - 270d
   AND dormant_notice_9m_at IS NULL
   → 알림 2 발송 + dormant_notice_9m_at = now

3. SELECT * FROM users WHERE last_activity_at < now - 365d
   AND dormant_entered_at IS NULL
   → 휴면 진입 (Teacher.profile_visibility="dormant", TeacherProfile.status="dormant", renderer 캐시 무효화, 알림 3)

4. SELECT * FROM users WHERE dormant_entered_at < now - 30d
   AND slug_released_at IS NULL
   → slug 회수 (SlugHistory.released_at=now, cooldown_until=now+90d, TeacherProfile.status="archived" + slug rename)
```

배치 실패 시 재시도 (idempotent — 멱등성 보장).

### 10.2 모니터링

- 알림 발송 성공률 90%+ 보증
- 휴면 진입/회수 일일 통계 운영자 대시보드
- Slack 알림: 휴면 진입 1건, 회수 1건 발생 시 발생

## 11. UX 텍스트 (한국어)

| 키 | 한국어 |
|---|---|
| `slugCheckAvailable` | "사용 가능한 주소입니다" |
| `slugCheckTaken` | "이미 사용 중인 주소입니다" |
| `slugCheckCooldown` | "최근 회수된 주소예요. {N}일 후 사용 가능합니다" |
| `slugCheckReserved` | "사용할 수 없는 예약어입니다" |
| `slugCheckFormat` | "영문 소문자, 숫자, 하이픈만 사용 가능 (3~30자)" |
| `dormantNotice6mTitle` | "6개월간 미접속 — 곧 휴면 상태로 전환돼요" |
| `dormantNotice9mTitle` | "3개월 후 프로필 주소가 회수돼요" |
| `dormantEnteredTitle` | "프로필이 휴면 상태로 전환됐어요" |
| `dormantPageTitle` | "이 프로필은 잠시 휴면 상태예요" |
| `dormantPageBody` | "선생님이 30일 안에 로그인하면 복구돼요." |
| `slugRestoredSuccess` | "프로필이 복구되었어요" |
| `slugRevokedByAdmin` | "프로필 주소가 회수되었어요. 사유: {reason}" |

## 12. 미해결 질문

- [ ] 알림 채널 다원화 — SMS 추가 발송 (Year 2 SMS 인증 도입 시)
- [ ] 휴면 임계값 12개월 — 시장 검증 후 9개월 vs 18개월 조정 가능성
- [ ] 옛 `TeacherProfile` (status="archived") 영구 보관 — DB row + Vultr Object Storage 이미지 비용 vs 보존 의무 균형. 5년 후 자동 hard delete?
- [ ] dormant guide page 디자인 — Notebook × Score 시그니처 적용 범위

## 13. 변경 이력

- 2026-05-18: 초안 — LOL 방식 휴면 정책 (12mo + 1mo grace + 3mo cooldown), Year 1 slug 변경 60일 내 1회, Option B 권한 격리 전제
- 2026-05-19: Option D 정렬 — Ghost Page 폐기, `TeacherProfile` 상태 전환(`public`/`dormant`/`archived`)로 동등 동작 대체. 휴면/회수/관리자 회수 시 백엔드가 renderer 캐시 무효화 webhook 호출. 예약어 `ghost` 제거.
