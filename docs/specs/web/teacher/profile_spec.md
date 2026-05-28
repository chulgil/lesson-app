# profile_spec — 선생님 프로필 사이트

> 기준일: 2026-05-19
> 도메인: `profile.lessonaza.app/{teacher_slug}`
> 컨테이너: `profile-renderer` (FastAPI + Jinja2 SSR) — `ghost-www` 와 별도 인스턴스
> 선행: [README.md](README.md), [www_spec.md](www_spec.md), [profile_renderer_spec.md](profile_renderer_spec.md), [../profile/public_profile_content_spec.md](../profile/public_profile_content_spec.md), `mybrain/10 Projects/레슨앱/17-www-profile-시장조사.md`, `18-www-profile-요구사항.md`

## 1. 개요

선생님 개인의 **공개 명함/포트폴리오** 페이지. 학생/학부모가 검색·SNS·카카오톡에서 접근 가능한 단일 URL 을 제공.

**책임**:
- 선생님 1명당 1 페이지 (`/{slug}`) — 소개·이력·갤러리·영상·연락 CTA
- 콘텐츠 SSOT 는 lesson-app 백엔드의 `TeacherProfile` 테이블
- 렌더링은 web VPS 의 `profile-renderer` 컨테이너가 백엔드 내부 API 를 호출해 SSR
- 페이지 → lesson-app 다운로드 + 해당 선생님 자동 매칭 (Deep Link)

**비책임**:
- 선생님 인증/세션 (lesson-app 백엔드)
- 결제 / 예약 (lesson-app 본 앱)
- 콘텐츠 편집 UI (lesson-app 인앱 화면 — `teacher_profile_edit_spec.md`)

**아키텍처 결정 (Option D)**:
Phase 1 의 Ghost CMS (`ghost-profile` + `mysql-profile`) 의존을 폐기하고, 백엔드가 보유한 `TeacherProfile` 을 SSOT 로 둔 직접 렌더링 방식을 채택. 운영 비용(≈600MB RAM) 절감 + 멀티테넌트 격리 우려 제거 + 콘텐츠 모델 자유도 확보. 상세 비교는 §3.3 참조.

## 2. 성공 기준

- [SC-1] 선생님이 lesson-app 인앱 편집 화면에서 5분 안에 프로필 작성·게시 (운영자 검토 후 공개)
- [SC-2] `profile.lessonaza.app/{slug}` 가 OG 카드로 카카오톡/페이스북 미리보기 정상 표시
- [SC-3] 페이지 LCP < 2.5s (3G), 캐시 히트시 p95 50ms (renderer 응답)
- [SC-4] 페이지 내 앱 다운로드 CTA → 설치 후 선생님 코드 자동 입력 → 매칭 (Universal Link / App Link)
- [SC-5] 휴면/회수된 slug 는 410 Gone 으로 응답 (slug_lifecycle_spec 연동)
- [SC-6] 첫 게시는 운영자 검토 큐 통과 후 공개. 검토 통과 이력 있는 선생님의 재게시는 직접 공개

## 3. URL 구조 / 콘텐츠 격리 전략

### 3.1 URL

- 페이지: `profile.lessonaza.app/{teacher_slug}`
- 인덱스: `profile.lessonaza.app/` → 운영자가 작성한 환영 페이지 또는 선생님 목록 (선택)
- 잘 알려진 경로: `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`, `/robots.txt`, `/sitemap.xml`
- 헬스체크: `/health` (내부)
- 어드민 경로 **없음** — 콘텐츠 편집은 모두 lesson-app 인앱 화면

### 3.2 slug 규칙

상세 정책은 [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md) 참조.

- 영문 소문자 + 숫자 + 하이픈, 3~30자
- 선생님이 **가입 시 본인 선점** (실시간 중복 체크, 운영자 승인 불필요)
- Year 1: 가입 후 **60일 내 1회 변경 허용**, slug 변경 시 90일 cooldown 적용
- 12개월 미활동 시 휴면 진입 → 13개월 회수 + 3개월 cooldown
- 운영자 즉시 회수 가능 (저작권/욕설/사기 신고)
- 예약어 (`SlugReservedWord` 테이블): `admin`, `api`, `www`, `terms`, `privacy`, `signup`, `login`, `verify-email`, `edit`, `static`, `well-known` 등

### 3.3 멀티테넌트 — Option D (Backend Direct Rendering)

**선택지 비교**:

| 옵션 | 격리 수준 | 콘텐츠 자유도 | 운영 비용 | 채택 |
|---|---|---|---|---|
| A. Ghost Author 역할 (네이티브) | 약함 — 다른 페이지 목록 노출 | 보통 (Ghost 에디터 종속) | 600MB RAM | ❌ |
| B. Custom Edit UI + Ghost Admin API 프록시 | 강함 | 보통 (Ghost 페이지 모델 종속) | 600MB RAM + 프록시 코드 | 이전 채택, 폐기 |
| C. 헤드리스 (Ghost 폐기, Astro 정적 빌드) | 강함 | 강함 | rebuild 파이프라인 필요 | ❌ — 잔존 Ghost 의존 및 캐시 정합성 부담 |
| **D. 백엔드 직접 렌더링 (FastAPI + Jinja2)** | **강함** | **강함** | **renderer 컨테이너 ~150MB** | **✅** |

**채택**: Option D. lesson-app 백엔드의 `TeacherProfile` 이 SSOT, web VPS 의 `profile-renderer` 가 내부 API 를 호출해 SSR. 자세한 렌더러 스펙은 [profile_renderer_spec.md](profile_renderer_spec.md), 콘텐츠 모델은 [public_profile_content_spec.md](../profile/public_profile_content_spec.md).

```
방문자 (브라우저)
  ↓ HTTPS
profile.lessonaza.app  (Traefik on web VPS)
  ↓
profile-renderer 컨테이너 (FastAPI + Jinja2, web VPS)
  ↓ HTTPS + X-Internal-API-Token + IP whitelist
api.lessonaza.app/internal/teacher-profiles/by-slug/{slug}  (백엔드, API VPS)
  ↓
PostgreSQL teacher_profiles
```

**격리 보증**:
- 콘텐츠는 PostgreSQL `teacher_profiles` 에만 저장 — Ghost/MySQL 의존 없음
- 백엔드 권한 체크: 편집 API 는 `current_user.teacher_id == profile.teacher_id` 강제. 다른 teacher_id 조작 시 403 + AuditLog
- renderer↔백엔드 내부 API: `X-Internal-API-Token` (32B hex) + 백엔드 ACL 의 web VPS IP whitelist 이중 보호
- renderer 는 백엔드의 공개 API 를 호출하지 않음 — 내부 전용 엔드포인트만 사용

### 3.4 콘텐츠 편집 분리

| 채널 | 위치 | 사용자 |
|---|---|---|
| 콘텐츠 편집 | lesson-app 인앱 화면 (`features/profile/teacher_profile_edit/`) | 선생님 본인 |
| 운영자 검토 큐 | lesson-app 내부 어드민 (또는 별도 백오피스 화면) | 운영자 |
| 공개 페이지 | `profile.lessonaza.app/{slug}` (읽기 전용) | 누구나 |

상세는 [teacher_profile_edit_spec.md](../profile/teacher_profile_edit_spec.md) (인앱 편집) 와 [public_profile_content_spec.md](../profile/public_profile_content_spec.md) (콘텐츠 모델/검토 흐름).

## 4. 데이터 모델

콘텐츠 SSOT 는 [public_profile_content_spec.md](../profile/public_profile_content_spec.md) 의 `TeacherProfile` 테이블. 본 스펙에서는 렌더링에 사용되는 표시 필드만 요약한다.

| 필드 | 타입 | 노출 |
|---|---|---|
| `slug` | VARCHAR(30) | URL |
| `headline` | VARCHAR(200) | 상단 타이틀, OG title |
| `profile_image_url` | VARCHAR(500) | 메인 사진 (Vultr Object Storage) |
| `bio_long` | TEXT (markdown) | 본문 — 백엔드가 sanitize 후 `bio_long_html` 동시 저장 |
| `bio_long_html` | TEXT (HTML) | renderer 가 그대로 렌더 (whitelist 통과본) |
| `instruments` | JSON | 악기 칩 (예: `["violin", "viola"]`) |
| `education` | JSON | 학력 리스트 `[{school, period, note}]` |
| `awards` | JSON | 수상 리스트 |
| `career` | JSON | 경력 리스트 |
| `lesson_rates` | JSON | 가격대 `[{level, duration_min, price_krw, note}]` |
| `gallery_images` | JSON | 최대 12장 `[{url, alt, sort}]` |
| `video_embeds` | JSON | 최대 6개 `[{provider, video_id, title}]`, provider ∈ {youtube, vimeo} |
| `contact_methods` | JSON | 마스킹 정책 적용 (스펙 §5) |
| `lesson_areas` | JSON | `["강남", "온라인", "출장"]` |
| `teacher_code` | VARCHAR(10) | Universal Link/QR 용 (`T-XXXX`) |
| `status` | enum | `draft` / `review` / `public` / `dormant` / `archived` |
| `seo_title`, `seo_description` | VARCHAR | OG/SEO 오버라이드 (없으면 기본값) |
| `og_image_url` | VARCHAR | 공유 카드 (없으면 profile_image_url 사용) |

`status != public` 이면 renderer 는 410 Gone (휴면/회수) 또는 404 (초안/검토중) 응답.

## 5. 페이지 템플릿 — Notebook × Score

### 5.1 레이아웃 (모바일 우선)

```
┌──────────────────────────────────────────┐
│  [Notebook 종이 배경, 옅은 가로선]            │
│                                          │
│  ♩ Lessonaza                  [앱 받기]    │  ← sticky 헤더
│                                          │
│  [선생님 사진 — 원형 보더]                    │
│                                          │
│  ★ 이지원 바이올린 선생님                     │
│  서울 강남 · 클래식 · 5년 경력                │
│                                          │
│  ─── 5선 구분선 (악보 모티프) ───              │
│                                          │
│  [자기소개 본문 — Markdown 렌더, Pretendard]  │
│                                          │
│  📍 레슨 위치 — 강남, 온라인                  │
│  💰 가격대 — 5만원~ / 30분 (기본/심화 표기)   │
│  🎼 분야 — 클래식, 재즈                       │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [이력 — 학력 / 경력 / 수상 리스트]            │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [갤러리 — 이미지 그리드 (최대 12, lazy load)] │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [영상 — YouTube/Vimeo 임베드 (최대 6)]      │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ♥ 이 선생님과 레슨하고 싶다면?         │  │
│  │ ① 앱 다운로드  ② 선생님 코드 입력      │  │
│  │ [QR 코드]   T-A8K2  [복사]            │  │
│  │ [App Store] [Google Play]              │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [연락 — 마스킹된 contact_methods 표시]       │
│                                          │
│  ⓒ Lessonaza · 약관 · 개인정보             │  ← 푸터
└──────────────────────────────────────────┘
```

### 5.2 페이지 섹션 (렌더 순서)

1. sticky 헤더 (로고 + 앱 받기 CTA)
2. 히어로 (프로필 사진 + headline + 위치/분야 메타)
3. 5선 구분선
4. 본문 (`bio_long_html` 그대로 삽입)
5. 메타 칩 (악기 / 위치 / 가격대 / 분야)
6. 5선 구분선
7. 이력 (학력 + 경력 + 수상)
8. 5선 구분선
9. 갤러리 (12장 그리드, lazy load, alt 필수)
10. 5선 구분선
11. 영상 (YouTube/Vimeo 임베드, lazy iframe, CSP whitelist 통과)
12. 5선 구분선
13. 앱 다운로드 카드 (QR + 스토어 버튼 + teacher_code 복사)
14. 5선 구분선
15. 연락 (마스킹된 contact_methods)
16. 푸터

### 5.3 NotebookGlyph 사용 (시그니처 영역)

- 헤더 로고: ♩
- 이름 앞: ★
- 후기/연락 섹션: ♥
- 5선 구분선: 악보 5선 5px 간격 (SVG, `core/widgets/notebook` 시그니처 정책 참조)
- 작은 메타 인디케이터 (📍 💰 🎼) 는 유니코드 허용 (시그니처 영역 외 일반 인디케이터)

### 5.4 색상

- 배경: `#FBF7F0` (notebook paper)
- 5선: `#D4D0C8` (옅은 회색)
- 텍스트 본문: `#1A1A1A`
- 강조(이름, CTA): `#D97757` (스코어 액센트)
- 사진 보더: `#1A1A1A` 2px

### 5.5 폰트

- 시그니처 (선생님 이름, 섹션 헤더, CTA): Gaegu
- 본문: Pretendard

### 5.6 영상 임베드 보안

- 허용 provider: YouTube (`youtube.com/embed/{id}`) + Vimeo (`player.vimeo.com/video/{id}`) 만
- CSP: `frame-src` 에 두 도메인만 허용
- iframe sandbox 속성으로 권한 제한 (`allow-scripts allow-same-origin allow-presentation`)
- `loading="lazy"` + intersection observer 로 뷰포트 진입 시점에만 로드

## 6. lesson-app 연계

### 6.1 백엔드 변경 (요약)

상세 endpoint 와 모델은 [backend_architecture.md](../backend/backend_architecture.md) §API + [public_profile_content_spec.md](../profile/public_profile_content_spec.md) §7 참조.

| 변경 | 위치 | 마일스톤 |
|---|---|---|
| `teacher_profiles` 테이블 + Alembic 마이그레이션 | `backend/app/models/teacher_profile.py` | M4 |
| 인앱 편집 API (9 endpoints) | `backend/app/api/v1/teacher_profile_edit.py` | M4 |
| 운영자 검토 큐 API (3 endpoints) | `backend/app/api/v1/admin_profile_review.py` | M4 |
| 내부 API `GET /internal/teacher-profiles/by-slug/{slug}` | `backend/app/api/internal/teacher_profile_public.py` | M4 |
| 캐시 무효화 webhook `POST /internal/cache/invalidate` 호출 | publish/unpublish/review/revoke/dormant 시점 | M4 |
| `Teacher.profile_visibility`, `profile_slug` 컬럼 (1:1 매핑 보조) | `backend/app/models/teacher.py` + Alembic | M4 |

### 6.2 앱 내 통합

| 변경 | 위치 |
|---|---|
| 선생님 본인이 자기 프로필 미리보기 (앱 내 WebView) | `frontend/lib/features/profile/teacher_profile_edit/` |
| 선생님 상세 화면에 "공식 프로필 보기" 버튼 (status=public 일 때만) | `frontend/lib/features/student/presentation/screens/teacher_detail_page.dart` |
| 버튼 탭 → 외부 브라우저 또는 인앱 WebView | `url_launcher` |
| Deep Link 처리: `profile.lessonaza.app/{slug}` → 앱 설치 시 자동 매칭 | `frontend/lib/core/deep_link/` |

### 6.3 Deep Link (Universal Link / App Link)

- iOS: `apple-app-site-association` 파일을 `profile.lessonaza.app/.well-known/apple-app-site-association` 에 호스팅
- Android: `assetlinks.json` 을 `profile.lessonaza.app/.well-known/assetlinks.json` 에 호스팅
- profile-renderer 가 `/.well-known/*` 라우트를 직접 서빙 (FastAPI StaticFiles 또는 명시 라우트)
- 앱 미설치 시: 프로필 페이지 노출 + 스토어 CTA
- 앱 설치 시: 앱 열기 + slug 또는 teacher_code 로 자동 검색

### 6.4 선생님 코드 자동 입력

- 페이지 내 QR 코드: `lessonaza://signup?teacher_code=T-A8K2`
- "코드 복사" 버튼: 클립보드 복사 + 토스트 "앱 설치 후 가입 화면에서 붙여넣기"
- 앱 가입 화면: 클립보드에 `T-XXXX` 형식 감지 시 자동 입력 제안 (`frontend/lib/features/auth/onboarding/`)

## 7. SEO / Open Graph

| 항목 | 값 |
|---|---|
| `<title>` | `seo_title` (없으면 "{headline} — Lessonaza") |
| `<meta description>` | `seo_description` (없으면 `bio_long` 첫 155자) |
| `og:title` | title |
| `og:description` | description |
| `og:image` | `og_image_url` (없으면 `profile_image_url` 1200×630 변형) |
| `og:url` | canonical (`https://profile.lessonaza.app/{slug}`) |
| `og:type` | `profile` |
| `twitter:card` | `summary_large_image` |
| `schema.org` | `Person` + `MusicGroup` (선택) + `Service` (레슨) JSON-LD |
| `sitemap.xml` | status=public 인 모든 slug, 백엔드가 생성 → renderer 가 캐시 |
| `robots.txt` | 모든 봇 허용, sitemap.xml 명시 |

콘텐츠 필수 필드 (profile_image_url, headline, bio_long 50자+, instruments 1개+) 미충족 시 `status=draft` 강제 — public 전환 불가.

## 8. 운영 정책

| 항목 | 정책 |
|---|---|
| 신규 선생님 가입 | 1) `lessonaza.app/signup?role=teacher` 진입 → SSO (구글/카카오) 인증 → 2) `/signup/complete` 에서 slug 본인 선점 + 약관 동의 → 3) 백엔드가 User + Teacher 생성 + `TeacherProfile` (status=draft) 초기화 → 4) lesson-app 인앱 편집 화면 진입 → 5) 작성 후 "검토 요청" → 6) 운영자 첫 승인 후 status=public + `Teacher.profile_visibility=public` (신호: signup_spec §5.1) |
| 첫 게시 검토 | 운영자가 검토 큐에서 승인/반려. 승인되면 status=public + `review_state=approved_at` 기록 |
| 재게시 | 첫 승인 이력이 있는 선생님은 편집 후 직접 public 전환 (운영자 검토 우회). 약관 위반 신고 시 운영자가 강제 unpublish 가능 |
| slug 변경 | Year 1: 가입 후 60일 내 1회 허용. 60일 이후 운영자 수동 (slug_lifecycle_spec §4) |
| 콘텐츠 가이드라인 | 욕설/광고/저작권 침해 금지. 1차 경고 → 2차 강제 unpublish → 3차 권한 회수 + slug 회수 |
| 비공개 모드 | 선생님 휴직/일시 중단 시 인앱에서 `status=draft` 로 되돌리기 → 외부 접근 410. 콘텐츠 자체는 보존 |
| 페이지 삭제 | 선생님 탈퇴 시 `status=archived` + `archived_at` 기록. 90일 후 운영자 hard delete |
| 휴면 | 12개월 미접속 → `status=dormant`, 13개월 회수 + 3개월 cooldown (slug_lifecycle_spec §6) |

## 9. 캐시 / 성능

- profile-renderer in-memory cache: `cachetools.TTLCache(maxsize=1000, ttl=300)` (5분)
- 캐시 키: slug
- 백엔드가 publish/unpublish/review/revoke/dormant 시점에 `POST /internal/cache/invalidate {slug}` 호출 → renderer 가 해당 slug 즉시 제거
- 캐시 미스 시 백엔드 내부 API 호출 (X-Internal-API-Token + IP whitelist)
- p95: 캐시 히트 50ms, 캐시 미스 200ms (renderer 응답 기준)
- LCP < 2.5s (3G) — Vultr Object Storage CDN + lazy gallery/video

## 10. 보안

- TLS 1.3, HSTS, CSP — 자세한 헤더 정책은 [profile_renderer_spec.md](profile_renderer_spec.md) §8
- 내부 API: X-Internal-API-Token (32B hex, 90일 회전) + IP whitelist (web VPS IP) 이중 보호
- Markdown sanitize: 백엔드가 `bleach` 화이트리스트로 `bio_long` → `bio_long_html` 변환. iframe/script/H1 금지
- 영상 임베드: provider 화이트리스트 + ID 정규식 검증 (백엔드 입력 검증)
- 가입은 SSO 전용 (구글/카카오, M4) — 상세: [signup_spec.md](signup_spec.md)
- 백업: PostgreSQL 일일 백업 + Vultr Object Storage (이미지) 일일 백업, 30일 보관

## 11. 마일스톤 (M4)

| 단계 | 작업 | 기간 |
|---|---|---|
| M4.1 | 백엔드 `TeacherProfile` 모델 + Alembic 마이그레이션 + sanitize 파이프라인 | 2일 |
| M4.2 | 인앱 편집 API (9 endpoints) + 운영자 검토 큐 API (3 endpoints) | 4일 |
| M4.3 | 내부 API `GET /internal/teacher-profiles/by-slug/{slug}` + 인증 토큰/IP 화이트리스트 | 1일 |
| M4.4 | profile-renderer 컨테이너 (FastAPI + Jinja2 + 캐시 + sitemap/robots) | 4일 |
| M4.5 | 페이지 템플릿 — Notebook × Score 적용 + 갤러리/영상 렌더 | 4일 |
| M4.6 | Vultr Object Storage 업로드 흐름 (인앱 → 백엔드 presigned URL) | 2일 |
| M4.7 | Deep Link (Universal Link / App Link) + `.well-known` 정적 서빙 | 2일 |
| M4.8 | 앱 내 "공식 프로필" 버튼 + WebView + teacher_code 클립보드 자동 입력 | 2일 |
| M4.9 | E2E 검증 (편집 → 검토 → 게시 → 외부 클릭 → 앱 설치 → 매칭) | 2일 |
| **M4 종료** | **lesson-app 통합 완료, 시범 선생님 3명 운영** | **약 4주** |

## 12. 미해결 질문

- [ ] 시범 선생님 3명 — 누구? (M4.5 종료 시점)
- [ ] 인덱스 페이지 (`profile.lessonaza.app/`) — 환영 페이지 vs 선생님 디렉토리 vs 404
- [ ] 선생님 페이지 통계 (조회수, 외부 유입) — 선생님 본인 노출 시점 (M4 vs M5)
- [ ] 영상 임베드 외 콘텐츠 (PDF 악보 샘플 등) — Phase 2 백로그 후보
- [ ] 검색 인덱싱 우선순위 — sitemap 갱신 주기 (실시간 vs 일 1회)

## 13. 변경 이력

- 2026-05-18: 초안 (Ghost 별도 인스턴스 + Author 권한 + Phase 2 헤드리스 전환 계획)
- 2026-05-18 (v2): Option B 채택 — Custom Edit UI + Ghost Admin API 백엔드 프록시. Author 권한 모델 폐기. slug 자동 발급 + 휴면 정책 분리 ([slug_lifecycle_spec](../user/slug_lifecycle_spec.md)).
- 2026-05-19 (v3): **Option D 채택** — Ghost (`ghost-profile` + `mysql-profile`) 폐기. `TeacherProfile` 1:1 분리 모델 SSOT + `profile-renderer` (FastAPI + Jinja2 SSR). D-Rich 콘텐츠 모델 (Markdown bio + gallery 12 + video embeds 6). YouTube/Vimeo whitelist. 운영자 첫 게시 검토 + 재게시 직접 공개. 내부 토큰 + IP whitelist 이중 인증, 메모리 캐시 5분 TTL. 상세 콘텐츠 모델은 [public_profile_content_spec.md](../profile/public_profile_content_spec.md), 렌더러는 [profile_renderer_spec.md](profile_renderer_spec.md).
