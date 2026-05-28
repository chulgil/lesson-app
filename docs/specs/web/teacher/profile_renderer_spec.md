# profile_renderer_spec — 선생님 프로필 렌더링 서버

> 기준일: 2026-05-19
> 도메인: `profile.lessonaza.app`
> 호스트: web VPS (`ghost-www` 와 동거)
> 선행: [profile_spec.md](profile_spec.md), [public_profile_content_spec.md](../profile/public_profile_content_spec.md), [README.md](README.md), [backend_architecture.md](../backend/backend_architecture.md)

## 1. 개요

`profile.lessonaza.app/{slug}` 요청을 처리하는 **경량 렌더링 서버**. Ghost 의존을 제거하고 (Option D) 백엔드 API 가 보유한 `TeacherProfile` 콘텐츠를 직접 HTML 로 렌더링한다.

### 1.1 책임

- `profile.lessonaza.app/{slug}` 페이지 HTML 렌더링 (SSR)
- `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json` 정적 서빙
- 백엔드 내부 API (`/internal/teachers/by-slug/{slug}`) 호출 + 메모리 캐시
- SEO 메타태그 (OG, Twitter Card, schema.org Person/MusicGroup)
- 휴면/회수 슬러그의 dormant guide / 404 페이지
- 인앱 딥링크 분기 (`?utm_source=...`)

### 1.2 비책임

- 콘텐츠 모델 정의 — [public_profile_content_spec.md](../profile/public_profile_content_spec.md)
- 인증 / 로그인 / 편집 — Edit UI 는 `lessonaza.app/edit` (별도 SPA / 백엔드 프록시)
- slug 정책 — [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md)
- 이미지 호스팅 — Vultr Object Storage 직접 서빙

## 2. 성공 기준

- [SC-1] `profile.lessonaza.app/{slug}` 응답 시간 p95 ≤ 200ms (캐시 미스 포함), p95 캐시 히트 ≤ 50ms
- [SC-2] 백엔드 장애 시에도 캐시 TTL 내에는 정상 응답 (그레이스풀 디그레이드)
- [SC-3] 모든 페이지에 OG/Twitter/schema.org 메타태그 자동 포함
- [SC-4] `/.well-known/*` 응답은 정적 파일, TTL 24h
- [SC-5] 내부 API 호출은 X-Internal-API-Token + IP 화이트리스트 이중 보호 — 토큰 하나만으로는 호출 불가
- [SC-6] 휴면/회수 슬러그는 명확한 안내 페이지 (200) — `404` 아님 (외부 링크 보호)
- [SC-7] CSP 헤더로 YouTube/Vimeo 외 임베드 차단
- [SC-8] profile-renderer 컨테이너 단독 재배포 가능 — 백엔드 / Ghost 와 독립

## 3. 토폴로지

```
              ┌────────────────────────┐
유저 ─HTTPS→  │ Traefik (web VPS, 외부) │
              └───────┬────────────────┘
                      │ Host: profile.lessonaza.app
                      ↓
              ┌────────────────────────┐
              │ profile-renderer       │   FastAPI + Jinja2
              │ (web VPS, 컨테이너)     │   ─ 메모리 캐시 (TTL 5분)
              └───────┬────────────────┘
                      │ HTTPS + X-Internal-API-Token
                      │ + IP 화이트리스트 (web VPS IP)
                      ↓
              ┌────────────────────────┐
              │ api.lessonaza.app       │   FastAPI (API VPS)
              │ /internal/teachers/...  │
              └────────────────────────┘
```

다른 호스트 (`lessonaza.app`, `www.lessonaza.app`) 의 Traefik 라우팅과 동일한 web VPS Traefik 인스턴스를 공유. backend Traefik 도 같은 외부 `traefiknet` 네트워크에 붙어 있으나, profile-renderer 는 **백엔드를 직접 호출하지 않고 Traefik 경유 HTTPS** 로 부른다 (네트워크 격리 + TLS 종단).

## 4. 기술 스택

| 영역 | 선택 | 비고 |
|---|---|---|
| 언어/런타임 | Python 3.12 | backend 와 동일 — 운영 도구 공유 |
| 웹 프레임워크 | FastAPI (slim) | uvicorn workers=2 |
| 템플릿 | Jinja2 | 마크다운 → HTML 은 `markdown-it-py` + `bleach` 화이트리스트 |
| HTTP 클라이언트 | `httpx` AsyncClient | keepalive + connection pool |
| 캐시 | 인메모리 (`cachetools.TTLCache`) | TTL 5분, max 1,000 entries |
| 정적 자산 | `StaticFiles` (`/.well-known/`, `/static/`) | |
| 로그 | `structlog` JSON | Traefik access log 와 별도 |
| 컨테이너 | Docker, slim Python image | |
| 배포 | docker compose (web VPS) | ghost-www / mysql-www 와 동일 호스트 |

**Lore-rejected**: Astro 헤드리스 — Ghost 의존 잔존 + 정적 빌드 캐시 불일치 위험으로 동적 SSR 선택.
**Lore-rejected**: Caddy + 백엔드 직접 SSR — 인프라 단순화는 되나 SEO/캐시/CSP 튜닝이 백엔드 코드 강결합되어 배포 단위가 거대해짐.

## 5. 환경 변수

| 키 | 예시 | 비고 |
|---|---|---|
| `API_BASE_URL` | `https://api.lessonaza.app` | 백엔드 호출 |
| `INTERNAL_API_TOKEN` | 32B random hex | X-Internal-API-Token 헤더 |
| `CACHE_TTL_SECONDS` | `300` | 5분 |
| `CACHE_MAX_ENTRIES` | `1000` | LRU |
| `WWW_BASE_URL` | `https://lessonaza.app` | 푸터/네비/CTA |
| `APP_STORE_URL` | `https://apps.apple.com/app/idXXX` | "앱 다운로드" CTA |
| `PLAY_STORE_URL` | `https://play.google.com/store/apps/details?id=...` | |
| `SENTRY_DSN` | (옵션) | 에러 트래킹 |

`INTERNAL_API_TOKEN` 은 백엔드와 web VPS Vault 에서 동시 관리. 1회 노출 시 백엔드 + renderer 양쪽 즉시 회전.

## 6. 내부 API 계약

호출: `GET /api/v1/internal/teachers/by-slug/{slug}` → API VPS 백엔드

### 6.1 요청

```
GET /api/v1/internal/teachers/by-slug/jiwon-lee HTTP/1.1
Host: api.lessonaza.app
X-Internal-API-Token: <32B hex>
X-Forwarded-For: <web VPS IP>  # Traefik 가 자동 첨부
```

백엔드는:
1. IP 화이트리스트 확인 (web VPS IP — 환경변수)
2. X-Internal-API-Token 비교 (상수 시간 비교)
3. 둘 다 통과 시에만 응답

### 6.2 응답 (200 OK)

```json
{
  "teacher": {
    "display_name": "이지원",
    "profile_slug": "jiwon-lee",
    "profile_visibility": "public"
  },
  "profile": {
    "status": "public",
    "headline": "...",
    "bio_long_html": "<p>...</p>",
    "profile_image_url": "https://...",
    "instruments": ["violin"],
    "teaching_areas": [...],
    "education": [...],
    "awards": [...],
    "career": [...],
    "lesson_rates": [...],
    "lesson_location_type": "both",
    "lesson_locations": [...],
    "available_times_note": "...",
    "gallery_images": [...],
    "video_embeds": [{"provider":"youtube","video_id":"...","title":"..."}],
    "contact_methods": [...],
    "external_links": [...],
    "last_published_at": "2026-05-10T03:12:00Z"
  },
  "_meta": {
    "etag": "W/\"...\"",
    "cache_until": "2026-05-19T03:17:00Z"
  }
}
```

`bio_long_html` 은 백엔드가 마크다운 → 화이트리스트 HTML 로 변환해서 제공. renderer 는 추가 sanitize 없이 그대로 임베드. **백엔드가 SSOT 의 화이트리스트도 소유** (renderer 와 sanitize 로직 분기 방지).

### 6.3 응답 (휴면)

```json
{
  "teacher": {
    "display_name": "이지원",
    "profile_slug": "jiwon-lee",
    "profile_visibility": "dormant"
  },
  "profile": {
    "status": "dormant"
  }
}
```

renderer 는 dormant guide page 렌더링.

### 6.4 응답 (404)

- slug 미존재 (재선점 가능 cooldown 포함)
- `status='draft'` 또는 `status='archived'`
- `Teacher` 가 존재하지만 `profile_slug = NULL` (회수 직후)

→ 404 응답. renderer 는 친근한 404 페이지 표시.

## 7. 캐시 전략

### 7.1 메모리 캐시

- `cachetools.TTLCache(maxsize=1000, ttl=300)`
- key: `slug`
- value: 백엔드 응답 dict 통째

캐시 적중 시 백엔드 호출 생략.

### 7.2 무효화

다음 시점에 캐시 무효화 필요:
- 선생님이 publish/unpublish
- 운영자 검토 승인/거부
- 운영자 slug 회수
- 휴면 진입 배치

**구현**: 백엔드는 위 트랜잭션 직후 renderer 의 `POST /internal/cache/invalidate` 를 호출 (X-Internal-API-Token).

```
POST /internal/cache/invalidate HTTP/1.1
Host: profile.lessonaza.app
X-Internal-API-Token: <token>

{"slugs": ["jiwon-lee", "..."]}
```

무효화 호출 실패 시 별도 재시도 큐 (rq / Celery 도입 전까지는 백엔드 in-process 재시도 3회).

### 7.3 그레이스풀 디그레이드

백엔드 5xx 또는 타임아웃 시:
- 캐시에 stale 값이 있으면 stale 응답 (TTL 만료 후에도 최대 60분간 stale 허용)
- 캐시 없음 → 503 + 친근한 안내 페이지

stale 응답에는 `X-Origin-Stale: true` 헤더 부착.

### 7.4 HTTP 캐시 헤더

| 경로 | Cache-Control |
|---|---|
| `/{slug}` (public) | `public, max-age=60, s-maxage=300, stale-while-revalidate=600` |
| `/{slug}` (dormant) | `public, max-age=60` |
| `/{slug}` (404) | `public, max-age=30` |
| `/.well-known/*` | `public, max-age=86400` |

`ETag` 는 백엔드 응답의 `_meta.etag` 그대로 전파.

## 8. 보안

### 8.1 외부 → renderer

- HTTPS 강제 (HSTS `max-age=31536000; includeSubDomains`)
- CSP:
  ```
  default-src 'self';
  img-src 'self' https://*.vultrobjects.com data:;
  script-src 'self' https://www.youtube.com https://player.vimeo.com;
  frame-src https://www.youtube.com https://player.vimeo.com;
  style-src 'self' 'unsafe-inline';
  font-src 'self' data:;
  connect-src 'self';
  ```
- X-Frame-Options: `SAMEORIGIN`
- X-Content-Type-Options: `nosniff`
- Referrer-Policy: `strict-origin-when-cross-origin`

### 8.2 renderer → 백엔드

- HTTPS + X-Internal-API-Token + IP 화이트리스트 이중 보호
- 토큰만 노출되어도 IP 화이트리스트가 막음
- web VPS IP 변경 시 백엔드 환경변수 즉시 갱신

### 8.3 입력

- slug 검증: 백엔드와 동일 정규식 (`^[a-z0-9]+(-[a-z0-9]+)*$`, 3~30자)
- 길이/포맷 위반은 백엔드 호출 없이 즉시 400
- 경로 트래버설 (`/../`) 방어는 FastAPI 가 처리

### 8.4 운영

- Rate limit: IP 당 RPS 30, burst 60 (Traefik 미들웨어)
- 로그에 PII 미포함 (slug 는 공개 정보이므로 OK)
- Sentry 전파 시 요청 본문 / 헤더 필터링

## 9. 페이지 구성

### 9.1 라우트

| Path | 응답 |
|---|---|
| `GET /` | 302 → `WWW_BASE_URL` (apex 안내) |
| `GET /{slug}` | 프로필 페이지 / dormant guide / 404 |
| `GET /.well-known/apple-app-site-association` | 정적 JSON |
| `GET /.well-known/assetlinks.json` | 정적 JSON |
| `GET /robots.txt` | 정적 (sitemap 링크 포함) |
| `GET /sitemap.xml` | 동적 (백엔드 `/internal/teachers/sitemap` 캐시) |
| `GET /health` | 200 (Uptime Kuma) |
| `POST /internal/cache/invalidate` | 백엔드만 호출 (X-Internal-API-Token) |

### 9.2 프로필 페이지 섹션

(상세 디자인은 [profile_spec.md §6](profile_spec.md) 참조 — Notebook × Score 시그니처)

1. Masthead — 사진 + 이름 + 한 줄 소개 + 5선 구분선 모티프
2. 핵심 정보 — 악기, 활동 지역, 경력
3. 본문 (`bio_long_html`)
4. 자격 / 학력 / 경력
5. 레슨 요금 / 위치
6. 갤러리 (lightbox)
7. 영상 (YouTube/Vimeo iframe, lazy load)
8. 연락처 / 외부 링크
9. CTA — "Lessonaza 앱으로 레슨 문의" (인앱 딥링크 + 스토어 폴백)
10. Footer — www 링크, 약관, 휴면 정책 안내

### 9.3 SEO

```html
<title>{display_name} — {instrument} 선생님 | Lessonaza</title>
<meta name="description" content="{headline}">
<link rel="canonical" href="https://profile.lessonaza.app/{slug}">

<meta property="og:type" content="profile">
<meta property="og:title" content="{display_name} — {instrument} 선생님">
<meta property="og:description" content="{headline}">
<meta property="og:image" content="{profile_image_url}">
<meta property="og:url" content="https://profile.lessonaza.app/{slug}">

<meta name="twitter:card" content="summary_large_image">

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Person",
  "name": "{display_name}",
  "image": "{profile_image_url}",
  "url": "https://profile.lessonaza.app/{slug}",
  "jobTitle": "{instrument} 선생님",
  "description": "{headline}",
  "knowsAbout": [...instruments...],
  "alumniOf": [...education...]
}
</script>
```

휴면/404 페이지는 `noindex, nofollow` 메타.

### 9.4 dormant guide page

[slug_lifecycle_spec §6.3](../user/slug_lifecycle_spec.md) 의 화면 사양을 따른다.
- 200 응답 (외부 링크가 끊겼다고 오해되지 않도록 의도적으로 200)
- `noindex` 메타
- "다른 선생님 찾기" + "앱 다운로드" CTA

### 9.5 404 page

- 404 응답
- "이 주소는 사용되지 않거나 곧 새 사용자에게 배정될 수 있어요"
- "선생님 찾기" → `WWW_BASE_URL/teachers`

## 10. 인앱 딥링크 / 앱링크

### 10.1 Universal Link (iOS)

`/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAMID.app.lessonaza",
      "paths": ["/*"]
    }]
  }
}
```

`profile.lessonaza.app/jiwon-lee` 를 iOS Safari 가 인식하면 앱 설치 시 자동 앱 오픈.

### 10.2 App Link (Android)

`/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "app.lessonaza",
    "sha256_cert_fingerprints": ["..."]
  }
}]
```

### 10.3 페이지 내 deep-link CTA

```
앱으로 보기 → lessonaza://teacher/{slug}
             ↓ (앱 미설치 시 1.5s 후 스토어 폴백)
앱 설치 → App Store / Play Store
```

JavaScript 기반 deferred deep link (Firebase Dynamic Links 미사용 — 비용 + 의존 회피).

## 11. 운영 / 배포

### 11.1 docker compose 배치

[README.md §Docker 토폴로지](README.md) 의 web VPS stack 에 추가:

```yaml
profile-renderer:
  image: lessonaza/profile-renderer:${RENDERER_TAG}
  restart: unless-stopped
  env_file: .env.renderer
  networks:
    - traefiknet
  labels:
    - traefik.enable=true
    - traefik.frontend.rule=Host:profile.lessonaza.app
    - traefik.port=8000
    - traefik.docker.network=traefiknet
```

- DB 컨테이너 없음 (백엔드만 의존)
- 별도 MySQL 인스턴스 없음

### 11.2 배포 흐름

1. `backend/profile-renderer/` 디렉토리에 코드 + Dockerfile + 템플릿
2. GitHub Actions 이미지 빌드 → GHCR push
3. web VPS 에서 `docker compose pull profile-renderer && docker compose up -d profile-renderer`
4. Uptime Kuma 헬스체크 (`/health`)

### 11.3 모니터링

- Uptime Kuma: `/health` 60초 간격
- Sentry: 5xx 알림 → 슬랙 `#ops`
- Traefik access log: 90일 보관
- 캐시 적중률: 일 1회 운영 대시보드 수집

## 12. 마일스톤

| 단계 | 작업 |
|---|---|
| M4.R1 | FastAPI + Jinja2 기본 골격 + `/health` |
| M4.R2 | `/internal/teachers/by-slug` 호출 + 메모리 캐시 |
| M4.R3 | `/{slug}` 프로필 페이지 SSR + 마크다운 화이트리스트 HTML |
| M4.R4 | dormant guide / 404 페이지 |
| M4.R5 | OG / Twitter Card / schema.org 메타 |
| M4.R6 | `/.well-known/*` 정적 서빙 |
| M4.R7 | CSP / 보안 헤더 |
| M4.R8 | 캐시 무효화 엔드포인트 (`POST /internal/cache/invalidate`) |
| M4.R9 | sitemap.xml + robots.txt |
| M4.R10 | docker compose + Traefik 라벨 + 배포 |
| M4.R11 | Sentry / Uptime Kuma |
| M4.R12 | Lighthouse / 부하 테스트 (p95 200ms 검증) |

## 13. 미해결 질문

- [ ] 캐시 백엔드 — 메모리 단일 인스턴스가 부하 증가 시 한계. Redis 도입 시점은?
- [ ] sitemap 갱신 주기 — 백엔드 일괄 vs 변경 시 즉시
- [ ] AB 테스트 / 분석 — GA4 vs PostHog (쿠키 동의 정책과 묶음)
- [ ] 다국어 — `profile.lessonaza.app/{slug}?lang=en` 지원 시점 (Year 2)

## 14. 변경 이력

- 2026-05-19 v1: 초안 — Option D 전환에 따라 Ghost 제거, FastAPI + Jinja2 경량 렌더러로 대체. 내부 토큰 + IP 화이트리스트 이중 보호 + 메모리 캐시 5분 TTL 채택.
