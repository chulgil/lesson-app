# public_profile_content_spec — 공개 선생님 프로필 콘텐츠 SSOT

> 기준일: 2026-05-19
> 도메인: `profile.lessonaza.app/{slug}` 가 렌더링하는 콘텐츠
> 선행: [profile_spec.md](../web/profile_spec.md), [profile_renderer_spec.md](../web/profile_renderer_spec.md), [signup_spec.md](../web/signup_spec.md), [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md)
> 자매: [profile_master.md](profile_master.md) (인앱 프로필 탭), [teacher_profile_edit_spec.md](teacher_profile_edit_spec.md) (인앱 편집 UI)

## 1. 개요

`profile.lessonaza.app/{slug}` 로 외부에 공개되는 선생님 페이지의 **콘텐츠 모델 단일 진실 소스 (SSOT)**. 백엔드 `TeacherProfile` 테이블을 정의하고, Edit UI (lessonaza.app/edit), profile-renderer (profile.lessonaza.app), 인앱 프로필 미리보기가 모두 이 모델만 참조한다.

### 1.1 책임

- `TeacherProfile` 데이터 모델 정의 (Teacher 와 1:1 분리)
- 콘텐츠 필드 검증 규칙 (길이, 형식, 화이트리스트)
- 편집/공개 상태 머신 (`draft → review → public`)
- 외부 임베드 화이트리스트 (YouTube/Vimeo only)
- 운영자 첫 게시 검토 큐

### 1.2 비책임

- 렌더링 / HTML 출력 — [profile_renderer_spec.md](../web/profile_renderer_spec.md)
- slug 발급/회수 — [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md)
- 인앱 편집 UI — [teacher_profile_edit_spec.md](teacher_profile_edit_spec.md)
- 인앱 프로필 탭 — [profile_master.md](profile_master.md)
- 결제/계좌 — `profile_master.md` 및 subscription 도메인

## 2. 성공 기준

- [SC-1] `Teacher` 모델은 인증/매칭 SSOT, `TeacherProfile` 은 공개 콘텐츠 SSOT — 두 모델 1:1 분리 (`teacher_id UNIQUE`)
- [SC-2] 가입 트랜잭션에서 `Teacher` + `TeacherProfile` (빈 행) 동시 생성
- [SC-3] 콘텐츠 게시 흐름: `draft`(편집 중) → `review`(첫 게시 시 운영자 검토 큐) → `public`(공개) → `dormant`(휴면)
- [SC-4] 외부 영상 임베드는 YouTube + Vimeo 화이트리스트만, `provider + video_id` 정규화 저장 (URL 원문 저장 금지)
- [SC-5] 이미지는 Vultr Object Storage 만 사용, 외부 URL 직접 임베드 금지
- [SC-6] 콘텐츠 변경은 `last_edited_at` 갱신 + AuditLog 기록 — 휴면 활동성 측정에 사용
- [SC-7] 1차 게시(`status: draft → review`) 시 운영자 검토 큐에 진입, 통과 후에만 `public` 전환
- [SC-8] 운영자가 회수(slug 또는 콘텐츠)하면 즉시 `dormant` 또는 `archived` 로 전환

## 3. 데이터 모델

### 3.1 Teacher 모델 (불변 — 인증/매칭 SSOT)

`Teacher` 는 본 스펙에서 정의하지 않는다. 다만 본 스펙과의 경계를 명확히 한다.

| 필드 | 소유 | 비고 |
|---|---|---|
| `id`, `user_id`, `display_name`, `instruments` (매칭용 enum 배열) | Teacher | 인증/매칭 |
| `profile_slug`, `profile_url`, `profile_visibility` | Teacher | slug 정책 SSOT (slug_lifecycle_spec) |
| `dormant_*`, `slug_released_at`, `last_app_login_at` | Teacher | 휴면 트래킹 |
| **`ghost_page_id`** | ~~삭제~~ | Option D 전환으로 제거됨 |
| 본문, 갤러리, 영상, 자격, 경력, 요금 | **TeacherProfile** | 공개 콘텐츠 |

### 3.2 TeacherProfile 모델 (신규)

```python
class TeacherProfile(Base):
    __tablename__ = "teacher_profiles"

    id         = Column(Integer, primary_key=True)
    teacher_id = Column(
        Integer,
        ForeignKey("teachers.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # ── 상태 머신 ───────────────────────────
    status        = Column(String(20), default="draft", nullable=False)
                    # draft | review | public | dormant | archived
    review_state  = Column(String(20), nullable=True)
                    # pending | approved | rejected (status=review 일 때만)
    review_notes  = Column(Text, nullable=True)   # 운영자 검토 메모

    # ── 헤드/요약 ───────────────────────────
    headline           = Column(String(200), nullable=True)  # 한 줄 소개
    bio_long           = Column(Text, nullable=True)         # 본문 (Markdown, 화이트리스트)
    profile_image_url  = Column(String(500), nullable=True)  # Vultr URL (필수)

    # ── 매칭 보조 (TeacherProfile 측에서 공개용 표현) ──
    instruments        = Column(JSON, default=list)  # ["violin", "piano"]
    teaching_areas     = Column(JSON, default=list)  # ["서울 강남", "온라인"]
    experience_years   = Column(Integer, nullable=True)

    # ── 자격 / 경력 ─────────────────────────
    education  = Column(JSON, default=list)
                # [{school, period, degree}]
    awards     = Column(JSON, default=list)
                # [{name, year, rank}]
    career     = Column(JSON, default=list)
                # [{org, role, period}]

    # ── 레슨 정보 ───────────────────────────
    lesson_rates         = Column(JSON, default=list)
                          # [{duration_min, price, note}]
    available_times_note = Column(Text, nullable=True)
                          # 공개용 자유 텍스트 (실제 가용시간은 인앱 SSOT)
    lesson_location_type = Column(String(20), nullable=True)
                          # online | offline | both
    lesson_locations     = Column(JSON, default=list)
                          # [{type, address_masked, note}]

    # ── 갤러리 / 영상 ───────────────────────
    gallery_images = Column(JSON, default=list)
                    # [{url, caption, order}] — url 은 Vultr 호스트만
    video_embeds   = Column(JSON, default=list)
                    # [{provider, video_id, title}] — YouTube/Vimeo 화이트리스트

    # ── 연락 / 외부 ─────────────────────────
    contact_methods = Column(JSON, default=list)
                     # [{type, value_masked, visibility}]
    external_links  = Column(JSON, default=list)
                     # [{label, url}] — http(s) 화이트리스트

    # ── 메타 ────────────────────────────────
    last_edited_at        = Column(DateTime, nullable=True)
    first_published_at    = Column(DateTime, nullable=True)
    last_published_at     = Column(DateTime, nullable=True)
    view_count            = Column(Integer, default=0)

    __table_args__ = (
        Index("ix_teacher_profile_status", "status"),
    )
```

### 3.3 인덱스 / 제약

- `teacher_id` UNIQUE — Teacher 1:1
- `status` 인덱스 — 운영자 검토 큐 (`status='review' AND review_state='pending'`) 조회
- FK `ON DELETE CASCADE` — Teacher 삭제 시 콘텐츠 동시 삭제 (저장된 이미지는 별도 가비지 컬렉션)

### 3.4 별도 보존되는 데이터

- 콘텐츠 변경 이력: `AuditLog` 테이블 (`entity_type='teacher_profile'`, `action='edit|publish|revoke'`)
- 운영자 검토 처리 이력: `AuditLog` (`action='profile_review_approved|rejected'`)
- 회수된 콘텐츠 보관: `status='archived'` + (옵션) `archived_at` 컬럼 추가 후 1년 보존

## 4. 상태 머신

```
            ┌────────┐ 첫 게시 요청   ┌──────┐  운영자 승인  ┌──────┐
가입 직후 → │ draft  │ ──────────→  │review│ ────────────→ │public│
            └───┬────┘               └──┬───┘                └──┬───┘
                │ 본인 비공개 복귀         │ 운영자 반려              │ 12mo 무활동
                │ ←─────────────────      │                          │ (slug_lifecycle_spec)
                │                        ↓                          ↓
                │                    (draft 복귀)               ┌────────┐
                │                                                │dormant │
                │                                                └───┬────┘
                │ 본인 비공개 토글 (이미 1회 통과 후)               │ 운영자 회수
                └──────────────────────────────────────────────→ │     ↓
                                                                  │ ┌────────┐
                                                                  └→│archived│
                                                                    └────────┘
```

| 전이 | 권한 | 트리거 |
|---|---|---|
| 가입 → draft | 시스템 | `signup/complete` 트랜잭션에서 빈 `TeacherProfile` 행 생성 |
| draft → review | 본인 | `POST /teachers/me/profile/publish` (첫 게시) |
| review → public | 운영자 | `POST /admin/profile-reviews/{id}/approve` |
| review → draft | 운영자 | `POST /admin/profile-reviews/{id}/reject` + `review_notes` |
| public → draft | 본인 | `POST /teachers/me/profile/unpublish` (이후 본인 재게시는 운영자 검토 없이 가능 — 첫 게시만 검토) |
| public → dormant | 시스템 | slug_lifecycle_spec §6 휴면 진입 배치 |
| public/dormant → archived | 운영자 | slug 회수 (slug_lifecycle_spec §8) |
| draft → public (2회차+) | 본인 | `publish` (재게시) — 이미 첫 게시 검토 통과 이력 있음 |

**검토 1회 원칙**: 운영자 검토는 **최초 1회만**. 이미 승인 이력이 있으면 본인 publish 만으로 `public` 으로 직행.

## 5. 콘텐츠 검증 규칙

### 5.1 텍스트 필드

| 필드 | 길이 | 형식 |
|---|---|---|
| `headline` | 1~200자 | 평문 (개행 X, HTML X) |
| `bio_long` | 0~10,000자 | Markdown 화이트리스트 (§5.2) |
| `available_times_note` | 0~2,000자 | 평문 (개행 허용) |
| `education[*].school` | 1~100자 | 평문 |
| `awards[*].name` | 1~200자 | 평문 |
| `career[*].org` | 1~100자 | 평문 |
| `lesson_rates[*].note` | 0~200자 | 평문 |
| `lesson_locations[*].note` | 0~200자 | 평문 |
| `contact_methods[*].value_masked` | 0~200자 | 평문 (서버에서 추가 마스킹) |
| `external_links[*].label` | 1~50자 | 평문 |

### 5.2 Markdown 화이트리스트 (`bio_long`)

허용:
- 단락, 개행
- 볼드 (`**`), 이탤릭 (`*`), 인라인 코드 (\`)
- 헤딩 H2~H3 (H1 금지 — 페이지 제목 충돌)
- 순서/비순서 목록
- 링크 (`[text](url)`) — `url` 은 §5.4 화이트리스트
- 이미지 (`![alt](url)`) — `url` 은 Vultr Object Storage 호스트만

금지:
- 원시 HTML 태그
- iframe / script / style
- `javascript:` / `data:` URI
- 외부 이미지 직접 임베드 (CDN 이슈 + 콘텐츠 무결성)

서버는 [bleach](https://bleach.readthedocs.io) 또는 동등 라이브러리로 화이트리스트 외 토큰 제거 후 저장.

### 5.3 영상 임베드 (`video_embeds[*]`)

화이트리스트 프로바이더: **YouTube, Vimeo** (M4 출시 범위).

입력은 URL 또는 짧은 ID 모두 허용하되, **저장은 항상 정규화된 `{provider, video_id, title}` 형태**:

| Provider | 허용 입력 패턴 | 저장 |
|---|---|---|
| YouTube | `https://www.youtube.com/watch?v=XYZ`, `https://youtu.be/XYZ`, `XYZ` (11자 ID) | `{"provider":"youtube","video_id":"XYZ","title":"..."}` |
| Vimeo | `https://vimeo.com/123456`, `123456` (숫자 ID) | `{"provider":"vimeo","video_id":"123456","title":"..."}` |

`title` 은 선생님이 입력 (50자 이내, 평문). 영상 1개당 1행. 최대 6개.

URL 자체는 저장하지 않는다 — provider 의 도메인 변경/딥링크 변경에 대응하기 위해 정규화 필수. 렌더링 시 profile-renderer 가 `{provider, video_id}` 로 임베드 URL 재조립.

### 5.4 외부 링크 (`external_links[*]`)

- `url` 은 `https://` 만 허용 (`http://`, `javascript:`, `data:` 금지)
- 도메인 화이트리스트 없음 (자유 입력) — 단 길이 ≤ 500자
- 운영자 검토에서 악성 도메인 차단

### 5.5 이미지 업로드 (`profile_image_url`, `gallery_images[*].url`)

- 업로드 엔드포인트: `POST /api/v1/teachers/me/profile/images` (별도 절차)
- 저장: Vultr Object Storage (S3 호환)
- 저장 URL 패턴: `https://<bucket>.<region>.vultrobjects.com/teacher-profiles/{teacher_id}/{uuid}.{ext}`
- 외부 호스트 URL 을 직접 `profile_image_url` 에 넣는 시도는 거부 (도메인 검사)
- 확장자: `.jpg`, `.jpeg`, `.png`, `.webp` 만
- 파일 크기: 5MB 이하
- 갤러리 이미지 최대 12장

### 5.6 연락처 (`contact_methods[*]`)

| `type` | 형식 | 마스킹 |
|---|---|---|
| `email` | 이메일 | 가운데 일부 마스킹 (e.g., `ji***@gmail.com`) |
| `phone` | 010-XXXX-XXXX | 가운데 4자리 마스킹 |
| `kakao_openchat` | URL | 마스킹 없음 (선생님이 공개 의도로 등록) |
| `instagram` | 핸들 | 마스킹 없음 |

`visibility`:
- `public`: 페이지에 그대로 표시 (마스킹 적용 후)
- `on_request`: 페이지에 "연락 요청" 버튼만 표시, 실제 값은 인앱 메시지 또는 운영 채널 경유 (M5+)
- `private`: 페이지에 표시 안 함 (선생님 본인만 인앱에서 확인)

Year 1 출시 범위에서는 `public` + `private` 만 지원. `on_request` 는 백로그.

## 6. 운영자 첫 게시 검토

### 6.1 검토 큐 진입

본인이 `POST /teachers/me/profile/publish` 호출:
1. `status='draft'` 검증
2. 필수 필드 검증 (§6.3)
3. 콘텐츠 화이트리스트 위반 검증 (§5)
4. 통과 시 `status='review'`, `review_state='pending'` 으로 전환
5. `AuditLog: profile_first_publish_requested`
6. 운영자 슬랙 알림 (`#ops-profile-review`)

### 6.2 운영자 처리

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/admin/profile-reviews?state=pending` | 큐 목록 |
| GET | `/api/v1/admin/profile-reviews/{teacher_id}` | 검토 대상 콘텐츠 + diff |
| POST | `/api/v1/admin/profile-reviews/{teacher_id}/approve` | `status='public'`, `review_state='approved'`, `first_published_at=now` |
| POST | `/api/v1/admin/profile-reviews/{teacher_id}/reject` | `status='draft'`, `review_state='rejected'`, `review_notes='...'` + 이메일 |

운영자 처리 SLA: **영업일 24시간 이내**. SLA 초과 큐는 운영 대시보드에 강조.

### 6.3 첫 게시 필수 필드

- `profile_image_url` (NOT NULL)
- `headline` (1자 이상)
- `bio_long` (50자 이상)
- `instruments` (1개 이상)

위 4개 미충족 시 412 Precondition Failed + 누락 필드 목록 반환. 운영자 큐에 진입하지 않는다.

### 6.4 검토 기준 가이드 (운영자용)

- 욕설/혐오/사기 콘텐츠 — 즉시 reject
- 자격/경력 허위 의심 — reject + 증빙 요청 (`review_notes`)
- 동명이인 분쟁 — slug 이슈는 별도 (slug_lifecycle_spec §8)
- 외부 링크 악성 도메인 — reject
- 이미지 저작권 문제 의심 — reject

상세 가이드는 운영자 메뉴얼 (별도 문서).

## 7. API (콘텐츠 SSOT 관점)

본 스펙은 **계약**만 정의. HTTP/JSON 직렬화 상세는 OpenAPI 스키마 참조.

### 7.1 본인용 (인앱 + Edit UI 공통)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/teachers/me/profile` | `TeacherProfile` 조회 |
| PUT | `/api/v1/teachers/me/profile` | 부분 업데이트 (필드 단위 patch 허용) |
| POST | `/api/v1/teachers/me/profile/publish` | `draft → review` (첫 게시) 또는 `draft → public` (재게시) |
| POST | `/api/v1/teachers/me/profile/unpublish` | `public → draft` (비공개 복귀) |
| POST | `/api/v1/teachers/me/profile/images` | 이미지 업로드 → Vultr |
| DELETE | `/api/v1/teachers/me/profile/images/{image_id}` | 갤러리 이미지 삭제 |
| POST | `/api/v1/teachers/me/profile/preview` | 미공개 상태 미리보기 토큰 발급 (Edit UI 에서 사용) |

### 7.2 운영자용

§6.2 참조.

### 7.3 내부 (profile-renderer 전용)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/internal/teachers/by-slug/{slug}` | profile-renderer 가 호출 (X-Internal-API-Token + IP 화이트리스트) |

응답은 `TeacherProfile` + 일부 `Teacher` 필드 (`display_name`, `profile_slug`, `profile_visibility`) 조합.
`status='public'` (또는 `dormant` 의 dormant guide page) 이외에는 404.

상세 헤더/캐시 규칙: [profile_renderer_spec.md](../web/profile_renderer_spec.md).

## 8. 가입 시 초기화

`signup/complete` 트랜잭션:

```python
async def complete_signup(session, payload):
    user      = await create_user(session, payload)
    identity  = await create_auth_identity(session, user, payload)
    teacher   = await create_teacher(session, user, payload)        # profile_slug 포함
    profile   = TeacherProfile(
        teacher_id=teacher.id,
        status="draft",
        instruments=payload.lesson_genres,
    )
    session.add(profile)
    await record_terms(session, user, payload)
    await record_slug_history(session, teacher, payload)
    await session.commit()
```

빈 `TeacherProfile(status='draft')` 행을 미리 만들어 두므로, Edit UI 는 항상 `GET /teachers/me/profile` 으로 200 응답을 받을 수 있다.

## 9. 인앱 미리보기 / 외부 페이지 분리

| 채널 | 사용처 | 노출 |
|---|---|---|
| `GET /teachers/me/profile` | Edit UI, 인앱 ProfilePreviewScreen | draft 포함 전체 |
| `POST /preview` 토큰 + profile-renderer | Edit UI 의 "미리보기" 버튼, 게시 전 검토 | draft/review 도 가능 (서명 토큰) |
| `profile.lessonaza.app/{slug}` | 외부 공개 | `status='public'` 또는 `status='dormant'` (휴면 guide page) |

인앱 ProfilePreviewScreen ([profile_master.md](profile_master.md) §3) 은 외부 페이지의 시각적 모사가 아니라 **본인 데이터 미리보기** 이므로 본 스펙 모델을 그대로 조회. 외부와의 픽셀 일치는 보장하지 않는다.

## 10. 마이그레이션 (Option B → Option D)

기존 Option B 운영 데이터가 있는 경우(M4 베타 단계에서 Ghost Page 발급한 선생님):

1. `teacher_profiles` 테이블 생성 (Alembic 마이그레이션)
2. 모든 Teacher row 에 대해 빈 `TeacherProfile(status='draft')` 행 백필
3. Ghost Page 데이터를 best-effort 로 매핑:
   - Ghost `title` → `headline` (200자 초과 시 잘림)
   - Ghost `excerpt` → `headline` 보강 (둘 다 있으면 `title` 우선)
   - Ghost `feature_image` → `profile_image_url`
   - Ghost `html` → 단순 텍스트 추출 → `bio_long` (Markdown 변환은 best-effort, 검수 필요)
4. 매핑된 행은 `status='draft'` 유지 — 선생님이 직접 검토 후 publish
5. `Teacher.ghost_page_id` 컬럼 drop (별도 마이그레이션)
6. Ghost Page 콘텐츠는 Ghost DB 백업으로 30일 보관 후 폐기

베타 단계 진입 전이면 마이그레이션 불필요 — 모델 생성만.

## 11. API 구현 현황 (2026-05-31)

> 본 섹션은 `TeacherProfile` 전체 플로우 중 현재 완료된 백엔드 엔드포인트와 미구현 항목을 추적한다.

### 11.1 백엔드 구현 현황

| 항목 | 상태 | 비고 |
|------|:----:|------|
| `GET /api/v1/teachers/public/{id}` | ✅ 완료 | 인증 불필요, 민감정보 제외 — `backend/app/api/v1/teachers.py` |
| `TeacherPublicProfileResponse` 스키마 | ✅ 완료 | `name`, `instruments`, `introduction`, `education`, `career` 등 — `backend/app/schemas/teacher.py` |
| `GET /api/v1/internal/teachers/by-slug/{slug}` | ❌ 미구현 | profile-renderer 전용 내부 API — M4.A8 |
| slug 기반 공개 조회 | ❌ 미구현 | `Teacher.profile_slug` 필드 마이그레이션 + `by-slug` 라우트 필요 |
| `TeacherProfile` 테이블 (`teacher_profiles`) | ❌ 미구현 | Alembic 마이그레이션 — M4.A1 |
| 상태 머신 (publish/unpublish/preview) | ❌ 미구현 | M4.A6 |
| 캐시 무효화 webhook (`POST /internal/cache/invalidate`) | ❌ 미구현 | publish/unpublish 시점 — M4.A8 이후 |

> **참고**: 현재 구현된 `GET /api/v1/teachers/public/{id}` 는 `Teacher` 테이블을 직접 조회한다. 향후 `TeacherProfile` 테이블이 생성되면 이 엔드포인트의 응답 소스를 `TeacherProfile` 로 전환하거나, §7.3의 내부 API(`by-slug`)와 역할을 분리한다.

### 11.2 프론트엔드 / 웹 구현 현황

| 항목 | 상태 | 비고 |
|------|:----:|------|
| 웹 프로필 페이지 (`profile.lessonaza.app/{slug}`) | ❌ 미구현 | profile-renderer (FastAPI + Jinja2 SSR) — M4.R3 |
| Open Graph 메타 태그 | ❌ 미구현 | M4.R5 |
| 체험 레슨 CTA + 딥링크 | ❌ 미구현 | M4.8 |
| 인앱 "프로필 링크 복사" 버튼 | ❌ 미구현 | QuestBoard 완료 보상 연동 |
| slug 기반 짧은 URL | ❌ 미구현 | `Teacher.slug` 마이그레이션 선행 필요 |

## 12. 웹 페이지 구현 사양 (프론트엔드)

> 렌더링 상세(HTML/CSS/Jinja2)는 [profile_renderer_spec.md](../web/teacher/profile_renderer_spec.md), 페이지 디자인은 [profile_spec.md](../web/teacher/profile_spec.md) 참조. 본 섹션은 콘텐츠 모델 관점의 **프론트엔드 구현 계약**을 정의한다.

### 12.1 Open Graph / SNS 공유

선생님이 카카오톡·인스타그램·페이스북에 프로필 링크를 공유할 때 미리보기가 표시되어야 한다.

```html
<meta property="og:title" content="{display_name} — {instrument} 선생님" />
<meta property="og:description" content="{headline}" />
<meta property="og:image" content="{og_image_url 또는 profile_image_url}" />
<meta property="og:url" content="https://profile.lessonaza.app/{slug}" />
<meta property="og:type" content="profile" />
<meta name="twitter:card" content="summary_large_image" />
```

**카카오톡 특화 요건**:
- `og:image` 크기: 최소 200×200px, 권장 600×314px (1.91:1 비율)
- 카카오 스크래퍼가 이미지를 캐시하므로, 선생님이 프로필 이미지를 변경할 때 카카오 공유 디버거(https://developers.kakao.com/tool/clear/og) 캐시 초기화 안내 필요
- `og:description` 이 없으면 카카오 미리보기에 빈 영역이 표시됨 — `headline` 이 없으면 `bio_long` 앞 80자로 fallback

**폴백 우선순위**:
1. `seo_title` / `seo_description` (선생님이 별도 입력한 경우)
2. `display_name + instrument + headline`
3. `bio_long` 앞 155자 (meta description), 앞 80자 (OG description)

> 상세 메타태그 구현은 [profile_renderer_spec.md §9.3](../web/teacher/profile_renderer_spec.md) 참조.

### 12.2 체험 레슨 CTA

공개 프로필 페이지 하단에 "체험 레슨 신청" / "레슨 문의" CTA 버튼을 배치한다.

**앱 설치 여부에 따른 분기**:

| 상황 | 동작 |
|------|------|
| 앱 설치됨 (Universal Link / App Link 처리) | 딥링크 `lessonaza://teacher/{slug}` → 앱 내 해당 선생님 상세 화면 |
| 앱 미설치 | 프로필 페이지 노출 + 1.5초 후 스토어 CTA (App Store / Play Store) |
| 대안 (웹 직접 예약, Year 2 후보) | 이름 + 전화번호 입력 폼 → 선생님에게 앱 알림 전송 |

**선생님 코드 자동 입력 흐름** (Year 1):
1. 페이지 내 QR 코드 또는 "코드 복사" 버튼 — `T-XXXX` 형식 클립보드 복사
2. 앱 가입 화면에서 클립보드의 `T-XXXX` 감지 시 자동 입력 제안
3. 경로: `frontend/lib/features/auth/onboarding/`

CTA 위치: 페이지 내 sticky 헤더 ("앱 받기") + 하단 CTA 카드 두 곳 모두 배치.

> Deep Link 구현 상세: [profile_spec.md §6.3](../web/teacher/profile_spec.md) 및 [profile_renderer_spec.md §10](../web/teacher/profile_renderer_spec.md).

### 12.3 퀘스트 보드 연동

인앱 QuestBoardCard 와 공개 프로필의 활성화를 다음과 같이 연결한다.

| 조건 | 상태 | 인앱 UI |
|------|------|---------|
| 소개글(`bio_long`) 미작성 | 웹 프로필 비활성 | QuestBoard — "소개글 작성" 퀘스트 표시 |
| 소개글 50자+ 작성 완료 + 운영자 검토 통과 (`status=public`) | 웹 프로필 활성 | 프로필 상세 화면에 "웹 프로필 링크 복사" 버튼 노출 |

**URL 형식 (slug 구현 전까지)**:
- `https://profile.lessonaza.app/{teacher_slug}` — Teacher.profile_slug 기준
- slug 미발급 선생님: `https://profile.lessonaza.app/t/{teacher_id}` (임시, slug 전환 전)

**인앱 구현 위치**:
- QuestBoardCard: `frontend/lib/features/gamification/` (또는 `features/profile/`)
- "웹 프로필 링크 복사" 버튼: `frontend/lib/features/profile/presentation/screens/` 내 선생님 프로필 상세 화면
- 링크 복사 시 클립보드 + 토스트 "카카오톡·인스타그램에 공유해 학생을 모집하세요"

## 13. 마일스톤

| 단계 | 범위 | 상태 |
|------|------|:----:|
| 1 — M4.A1~A3 | `TeacherProfile` 모델 + Alembic 마이그레이션 + `/teachers/me/profile` CRUD | ❌ 미구현 |
| 2 — M4.A4~A9 | 이미지/영상 업로드, 상태 머신, 운영자 검토 큐, 내부 API | ❌ 미구현 |
| 3 — M4.R1~R5 | profile-renderer 컨테이너 + SSR + OG 메타 태그 | ❌ 미구현 |
| 4 — M4.R6~R12 | `/.well-known/*`, CSP, 캐시 무효화, sitemap, Lighthouse | ❌ 미구현 |
| 5 — M4.8 | 인앱 "공식 프로필 보기" 버튼 + WebView + teacher_code 클립보드 자동 입력 | ❌ 미구현 |
| 6 — M4.7 | Deep Link (Universal Link / App Link) | ❌ 미구현 |
| 7 — 백로그 | slug 기반 짧은 URL (`Teacher.slug` 마이그레이션) | ❌ 미구현 |
| 0 — 선행 완료 | `GET /api/v1/teachers/public/{id}` + `TeacherPublicProfileResponse` | ✅ 완료 |

> 기존 M4.A1~A9 세부 작업은 단계 1·2에 포함됨. 백엔드 마일스톤 상세는 §§M4.A1~A9 (하단 참조).

### 백엔드 마일스톤 세부

| 단계 | 작업 |
|---|---|
| M4.A1 | `teacher_profiles` Alembic 마이그레이션 + 모델 |
| M4.A2 | `signup/complete` 트랜잭션에 빈 행 생성 추가 |
| M4.A3 | `/teachers/me/profile` CRUD (검증 화이트리스트 포함) |
| M4.A4 | 이미지 업로드 (Vultr) + 갤러리 |
| M4.A5 | YouTube/Vimeo 정규화 파서 + 화이트리스트 |
| M4.A6 | 상태 머신 (publish/unpublish/preview) |
| M4.A7 | 운영자 검토 큐 (`/admin/profile-reviews`) + 슬랙 알림 |
| M4.A8 | `/internal/teachers/by-slug/{slug}` (profile-renderer 용) |
| M4.A9 | Option B → Option D 마이그레이션 (베타 데이터 있을 경우만) |

## 14. 미해결 질문

- [ ] `contact_methods.on_request` 의 익명 메시징 채널 — Year 1 SMS 미도입 환경에서 운영 가능성
- [ ] 운영자 검토 큐의 우선순위 SLA — 24h 일괄 vs 신규/문제 콘텐츠 분리
- [ ] 영상 임베드 화이트리스트 확장 — Naver TV, SoundCloud (Year 2)
- [ ] 콘텐츠 변경 시 재검토 트리거 — 본문 80% 이상 교체 시 재검토 큐 진입 여부
- [ ] `GET /api/v1/teachers/public/{id}` 응답 소스 전환 — `Teacher` 테이블 직접 조회 → `TeacherProfile` 전환 시점 (M4.A1 완료 후)
- [ ] 체험 레슨 웹 직접 예약 — Year 2 범위 확정 필요 (이름+전화번호 입력 → 선생님 앱 알림)
- [ ] 카카오 OG 캐시 초기화 — 자동화 가능 여부 (카카오 API 활용 vs 선생님 수동 안내)

## 15. 변경 이력

- 2026-05-19 v1: 초안 — Option D 전환에 따라 Ghost Page 의존 제거, `TeacherProfile` 1:1 분리, 첫 게시 운영자 검토 큐, YouTube/Vimeo 화이트리스트 + 정규화 저장 채택
- 2026-05-31 v2: 프론트엔드 구현 사양 보완 — §11 API 구현 현황 추가 (`GET /api/v1/teachers/public/{id}` 완료 확인), §12 웹 페이지 구현 사양 (OG 메타 태그·체험 레슨 CTA·퀘스트 보드 연동), §13 구현 단계 통합 업데이트
