# url_unification_v4_spec — www / profile 단일 도메인 통합

> 기준일: 2026-05-21
> 상태: **신규 v4 (전환 스펙)** — 합의 후 v3 후행 스펙(profile_spec / profile_renderer_spec / www_spec / slug_lifecycle_spec / README) 본문 갱신 작업으로 분리
> 선행: [README.md](README.md), [teacher/profile_spec.md](teacher/profile_spec.md), [teacher/profile_renderer_spec.md](teacher/profile_renderer_spec.md), [www/www_spec.md](www/www_spec.md), [../user/slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md)
> 옵시디언: `mybrain/10 Projects/레슨앱/17-www-profile-시장조사.md` §8 (결론 표), `18-www-profile-요구사항.md` §11 (미해결 → 통합 합의 시 §13 신설)

## 1. 결론 우선

1. **단일 도메인 통합**: `profile.lessonaza.app/{slug}` → `lessonaza.app/teacher/{slug}` 로 이전. 마케팅·SEO·전환 funnel 일원화.
2. **엔티티별 prefix 채택**: `/teacher/{slug}` (선생님) + `/academy/{slug}` (학원, Year 2). 예약어 테이블·Ghost route 와 충돌 0. 의미 명확 + URL slug 키워드 SEO 미세 우위 + nested route 자연 확장.
3. **컨테이너는 분리 유지**: `ghost-www` ↔ `profile-renderer` 두 컨테이너 그대로. Traefik **path-based 라우팅** 으로 한 도메인 두 백엔드.
4. **격리 보존**: renderer 장애 → 마케팅 페이지 정상, ghost-www 장애 → 선생님 페이지 정상.
5. **subdomain 301 보존**: `profile.lessonaza.app/{slug}` 는 12개월 동안 `lessonaza.app/teacher/{slug}` 로 영구 리다이렉트 — 외부 백링크 / 카카오톡 캐시 / 검색 인덱스 손실 방지.
6. **`.well-known/*` 은 apex 가 직접 서빙**: Universal Link / App Link 의 `applinks.details[].paths` 를 `["/teacher/*"]` + (전환 기간) `/{slug}` legacy 로 이중 설정.
7. **첫 게시 검토·휴면·캐시 무효화 흐름은 v3 그대로**. URL 만 바뀐다 — 데이터 모델/상태 머신/인증 변경 없음.
8. **마이그레이션 4 단계**: T-0 라우팅 추가 → T+1 canonical 전환 → T+30 sitemap 재제출 → T+365 subdomain 폐기.

## 2. 배경 — 왜 v4 인가

v3 (Option D) 의 결정 기준은 **운영 비용 / 격리 / 디자인 자유도** 였다. **수익 / 마케팅** 축은 1차 평가 대상이 아니었다 (참조: `17-www-profile-시장조사.md` §3.3 결정 표).

재평가 결과:

| 축 | v3 (subdomain) | v4 (apex `/teacher/{slug}`) |
|---|---|---|
| 도메인 권위 (SEO) | profile.* 분리 — 콘텐츠 누적이 apex 권위에 직접 기여 X | apex 단일 — 선생님 페이지 = www 의 long-tail 콘텐츠 풀 |
| URL slug 키워드 | 도메인에 "profile" — 일반어 | path 에 `teacher` — 검색 의도와 매칭 (음악 교사) |
| 백링크 가치 | profile.* 와 apex 분산 | apex 누적 |
| 검색 노출 → 전환 funnel | search → profile.* → 별도 도메인 → 앱 CTA (1 hop) | search → apex/teacher/{slug} → 동일 도메인 내 blog/pricing cross-sell → 앱 CTA |
| 브랜드 인지 | "profile.lessonaza.app/...” = 디렉토리 인상 | "lessonaza.app/teacher/김철수" = 본 서비스 일부 |
| 카카오톡 / SNS 공유 | OG 카드는 동일하나 도메인 다름 | 단일 도메인, 인지 1회 누적 |
| Universal Link 비용 | renderer 가 `.well-known/*` 서빙 | apex 가 서빙 (renderer 가 path 로 직접) |
| 운영 격리 | 컨테이너 + 도메인 분리 | 컨테이너 분리 유지, 도메인만 통합 |
| 학원 확장 | 별도 subdomain 필요 | `/academy/{slug}` 자연 확장 |
| nested route | profile.lessonaza.app/{slug}/reviews 어색 | `/teacher/{slug}/reviews` 자연 |

수익·마케팅 축에서 v4 가 우세. **운영 격리는 path 라우팅 + 분리 컨테이너로 동등 수준 보존 가능**.

## 3. URL 정책

### 3.1 신규 URL 형식

```
lessonaza.app/                       → ghost-www 홈
lessonaza.app/blog/...               → ghost-www
lessonaza.app/pricing                → ghost-www
lessonaza.app/about                  → ghost-www
lessonaza.app/terms                  → ghost-www (lesson-app WebView SSOT)
lessonaza.app/privacy                → ghost-www
lessonaza.app/teacher/{slug}         → profile-renderer (선생님 페이지)
lessonaza.app/teacher/{slug}/?utm=…  → profile-renderer (UTM 전파)
lessonaza.app/teacher                → profile-renderer (인덱스 / 검색 — 운영자가 정의)
lessonaza.app/academy/{slug}         → academy-renderer (Year 2, AC-M2 이후)
lessonaza.app/.well-known/*          → profile-renderer (Universal Link / App Link)
lessonaza.app/sitemap.xml            → ghost-www 통합 sitemap (sitemap-teachers.xml 참조)
lessonaza.app/robots.txt             → ghost-www
```

엔티티별 path prefix (`teacher/`, `academy/`) 는 Ghost route 와 절대 충돌하지 않음 — Ghost 페이지/포스트 slug 에 `teacher` / `academy` 단어가 포함되어도 prefix 자체가 다르므로 무관 (`/blog/teacher-interview` 같은 Ghost 포스트는 정상 동작).

향후 nested route 확장 가능:
- `/teacher/{slug}/reviews` — 후기 페이지
- `/teacher/{slug}/lessons` — 레슨 일정 공개
- `/teacher/{slug}/{post-slug}` — 선생님 개인 블로그 (Year 3 후보)

### 3.2 slug 접두사 회피 옵션 — 채택 근거

| 옵션 | 충돌 위험 | 길이 | 인지도 | 확장성 | nested route | 채택 |
|---|---|---|---|---|---|---|
| (A) **예약어 테이블 확장** (`/blog`, `/pricing`, ...) | 높음 — Ghost 가 새 페이지 추가할 때마다 동기화 필요. teacher 가 "blog" 가입 시 운영자 수동 차단 | 짧음 (slug 그대로) | 직관 | 약함 | 자연 | ❌ — 운영 부담 + race condition |
| (B) `@` 접두사 (`/@chulgil-piano`) | 0 | 1자 추가 | △ (SNS 사용자 친숙 / 일반 사용자 이메일 연상) | 약함 — 학원·스튜디오 추가 시 prefix 재설계 | 어색 (`/@slug/reviews`) | ❌ |
| (C) `/t/` 접두사 (`/t/chulgil-piano`) | 0 | 3자 추가 | 약함 — 약자 의미 즉시 안 보임 | 중간 (`/a/` 학원) | 자연 | ❌ |
| (D) **`/teacher/{slug}` + `/academy/{slug}` 접두사** | **0** | 9자 추가 | **강함 — 의미 직관** | **강함 — 엔티티별 prefix 자연 확장** | **자연** | **✅** |
| (E) renderer 우선 + 404 → ghost-www 폴백 | 중간 — Ghost slug 신규 추가 시 운영 검수 필요 | 짧음 | 직관 | 약함 | 자연 | ❌ — 운영 race condition + 디버깅 난이도 |
| (F) Ghost 서브디렉토리화 (`/info/*` 로 이전) | 0 | apex 가 선생님 우선 | 약함 — 기존 ghost-www URL SEO 손실 + 301 비용 | 강함 | 자연 | ❌ |

→ **(D) `/teacher/{slug}` 채택**. URL 9자 증가 비용 < (의미 명확성 + 학원 확장 자연성 + nested route 확장성 + SEO 키워드) 이득.

**참조 사례**:
- LinkedIn: `linkedin.com/in/{user}` / `linkedin.com/company/{org}`
- GitHub: `github.com/orgs/{org}` / `github.com/users/{user}`
- Reddit: `reddit.com/r/{sub}` / `reddit.com/u/{user}`

### 3.3 학원 도메인 통합 (Year 2)

| 형식 | 의도 |
|---|---|
| `/teacher/{slug}` | 선생님 — v4 (즉시 채택) |
| `/academy/{slug}` | 학원 공개페이지 — Year 2 AC-M2 시 v3 의 `academy.lessonaza.app/{slug}` 통합 |
| `console.lessonaza.app` | 학원장 콘솔 — 별도 도메인 / 컨테이너 영구 유지 (인증 SPA, Cookie scope 격리) |

v4 시점에서 `/teacher/`, `/academy/` prefix 를 **동시에 라우팅 예약**. `/academy/*` 는 AC-M2 까지 `404` 또는 ghost-www 안내 페이지로 응답. 미리 예약하면 학원 통합 시 라우팅 변경 없이 콘텐츠만 활성화.

`/parent/{slug}` (학부모 공개 페이지) 는 현재 비계획 — 필요 시 동일 패턴으로 자연 확장.

### 3.4 slug 형식 / 예약어 변동

- slug 형식 정규식: 변경 없음 (`^(?![\d-]+$)[a-z0-9]+(-[a-z0-9]+)*$`, 3~30자)
- 예약어 카테고리: "system" 항목 (`admin`, `api`, `www`, ...) 은 v4 에서 **사실상 불필요** — `/teacher/` prefix 가 분리하므로 teacher slug 가 `admin` 이어도 `/teacher/admin` 으로 안전. 단 마케팅·법무 사유로 `lessonaza`, `admin`, `support`, `official` 등은 별도 차단 권장 (사칭/혼동 방지).
- v3 `slug_lifecycle_spec §3.2` 의 시스템 경로 카테고리는 v4 합의 후 "brand" / "support" 카테고리로 재분류 — 전환 기간 (subdomain 유효 동안) 은 그대로 유지.

## 4. 토폴로지

### 4.1 v4 라우팅 다이어그램

```
                ┌─────────────────────────────┐
유저 ─HTTPS→    │ Traefik (web VPS, 외부)      │
                └────────┬────────────────────┘
                         │ Host: lessonaza.app
                         │
       ┌─────────────────┴───────────────────────────┐
       │                                              │
       │ PathPrefix("/teacher")                       │
       │ | PathPrefix("/academy") (예약, Year 2)       │ 그 외 모든 path
       │ | PathPrefix("/.well-known")                  │
       ↓                                              ↓
┌────────────────┐                          ┌──────────────────┐
│ profile-       │                          │ ghost-www        │
│ renderer       │   FastAPI + Jinja2       │ Ghost 5.x        │
│ (web VPS)      │   메모리 캐시 TTL 5분     │ MySQL 8 (별도)    │
└────────┬───────┘                          └──────────────────┘
         │ HTTPS + X-Internal-API-Token
         │ + IP whitelist
         ↓
┌────────────────────────┐
│ api.lessonaza.app       │
│ /internal/teachers/...  │
└────────────────────────┘
```

`www.lessonaza.app` → `lessonaza.app` 301 redirect (기존 정책 유지).

`profile.lessonaza.app/{slug}` → `lessonaza.app/teacher/{slug}` 301 redirect (v4 신설, 마이그레이션 §8).

### 4.2 Traefik 라우팅 라벨

#### profile-renderer

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=traefiknet"
  - "traefik.backend=profile-renderer"
  - "traefik.frontend.rule=Host:lessonaza.app;PathPrefix:/teacher,/academy,/.well-known"
  - "traefik.frontend.priority=20"   # ghost-www 보다 우선
  - "traefik.port=8000"
```

`/academy` 는 v4 시점에 라우팅만 예약 (Year 2 AC-M2 활성). 활성 전에는 profile-renderer 가 안내 페이지 (`AC-M2 이후 오픈 예정`) 또는 404 응답.

#### ghost-www

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=traefiknet"
  - "traefik.backend=ghost-www"
  - "traefik.frontend.rule=Host:lessonaza.app"
  - "traefik.frontend.priority=10"   # 폴백
  - "traefik.port=2368"
```

#### subdomain 301 (전환 기간)

```yaml
# 별도 redirector 컨테이너 또는 Traefik middleware
labels:
  - "traefik.enable=true"
  - "traefik.frontend.rule=Host:profile.lessonaza.app"
  - "traefik.frontend.redirect.regex=^https?://profile\\.lessonaza\\.app/(.+)"
  - "traefik.frontend.redirect.replacement=https://lessonaza.app/teacher/$$1"
  - "traefik.frontend.redirect.permanent=true"
```

> Traefik v1 `frontend.rule` 문법 기준 (web VPS 현재 버전). v2 마이그레이션 시 동일 의미의 router rule 로 변환 (`PathPrefix(\`/teacher\`)` 등). 검증 항목 §8.4 참조.

### 4.3 컨테이너 단일 / 분리 비교

| 항목 | 단일 컨테이너 (renderer 가 ghost embed) | 분리 (채택) |
|---|---|---|
| 격리 | renderer 죽으면 마케팅도 죽음 | 독립 |
| 배포 | 한쪽 빌드가 다른 쪽 영향 | 독립 배포 |
| RAM | 한 인스턴스 RAM 합산 | 분리 (ghost-www ≈400MB / renderer ≈80MB) |
| Ghost 의존 | 동일 | 동일 |
| 채택 | ❌ | ✅ |

## 5. 콘텐츠 / 데이터 모델

**변경 없음**.

- `TeacherProfile` 테이블 그대로 (백엔드 PostgreSQL SSOT)
- 5-state 상태 머신 (`draft → review → public → dormant → archived`) 그대로
- 첫 게시 검토 큐 그대로
- 휴면 / 회수 / cooldown 그대로
- bleach 화이트리스트 sanitization 백엔드 책임 그대로
- 캐시 무효화 webhook (`POST /internal/cache/invalidate {slug}`) 그대로 — renderer 엔드포인트 URL 만 내부 path 변경 없음

## 6. 메타 / SEO

### 6.1 canonical URL

v4 시점부터 모든 페이지의 `<link rel="canonical">` 은 `https://lessonaza.app/teacher/{slug}`.

전환 기간 동안 `profile.lessonaza.app/{slug}` 는 **301 redirect** 만 응답 — HTML 생성 안 함 (search engine 인덱스 정리 가속).

### 6.2 OG / Twitter / schema.org

`og:url`, `og:image`, twitter card 메타는 모두 apex URL.

```html
<link rel="canonical" href="https://lessonaza.app/teacher/chulgil-piano">
<meta property="og:url" content="https://lessonaza.app/teacher/chulgil-piano">
<meta property="og:type" content="profile">
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Person",
  "url": "https://lessonaza.app/teacher/chulgil-piano",
  ...
}
</script>
```

### 6.3 sitemap 통합

`lessonaza.app/sitemap.xml` 은 ghost-www 가 서빙 (Ghost 기본 sitemap). profile-renderer 가 별도 `sitemap-teachers.xml` 을 제공 → ghost-www 의 sitemap-index 가 reference.

```xml
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap><loc>https://lessonaza.app/sitemap-pages.xml</loc></sitemap>
  <sitemap><loc>https://lessonaza.app/sitemap-posts.xml</loc></sitemap>
  <sitemap><loc>https://lessonaza.app/sitemap-teachers.xml</loc></sitemap>
</sitemapindex>
```

`sitemap-teachers.xml` 의 모든 URL 은 `https://lessonaza.app/teacher/{slug}`. (Year 2 AC-M2 이후 `sitemap-academies.xml` 추가)

### 6.4 robots.txt

ghost-www 가 서빙. profile path 별도 disallow 없음 (인덱스 허용).

```
User-agent: *
Allow: /
Sitemap: https://lessonaza.app/sitemap.xml
```

## 7. 보안 / CSP

### 7.1 Cookie scope

ghost-www 와 renderer 가 같은 apex 도메인 공유 → cookie 격리 필요:

- `ghost-www` 의 Ghost Admin cookie: `Path=/ghost` 로 제한 (Ghost 기본값)
- renderer 는 **인증 cookie 발급 안 함** (읽기 전용 SSR)
- 향후 renderer 가 cookie 가 필요해지면 `Path=/teacher` (또는 `/academy`) 로 제한

### 7.2 CSP

renderer 응답의 CSP 헤더는 v3 그대로. ghost-www 의 CSP 와 충돌 없음 (다른 path).

### 7.3 X-Frame-Options

`SAMEORIGIN` — 같은 apex 라 `lessonaza.app` 페이지 안에서 `/teacher/{slug}` iframe 임베드 가능.

## 8. 마이그레이션

### 8.1 단계

| T | 작업 | 가역성 |
|---|---|---|
| **T-0 (시작)** | `lessonaza.app/teacher/*` + `/.well-known/*` Traefik 라우팅 추가 (priority 20). `/academy/*` 는 안내 페이지 라우팅 예약. renderer 가 두 호스트 (`profile.lessonaza.app` + `lessonaza.app`) 동시 응답. canonical 은 아직 profile.* | 완전 가역 |
| **T+1d** | renderer 의 canonical / og:url / schema.org URL 을 apex (`lessonaza.app/teacher/{slug}`) 로 전환 | 가역 (canonical 만 되돌림) |
| **T+2d** | sitemap-teachers.xml 의 모든 URL apex 로 갱신. Google Search Console / Naver Webmaster 에 새 sitemap 제출 | 가역 |
| **T+7d** | `profile.lessonaza.app/{slug}` → `lessonaza.app/teacher/{slug}` 301 redirect 활성. renderer 는 profile.* host 처리 중단 | 가역 (Traefik 라우팅만 되돌림) |
| **T+30d** | Google Search Console 인덱스 마이그레이션 진척 확인 (≥80% apex URL 인덱스). 미진척 시 추가 30일 모니터링 | — |
| **T+90d** | 카카오톡 OG 캐시 / Naver 검색 인덱스 안정화 검증 | — |
| **T+365d** | `profile.lessonaza.app` DNS A 레코드 제거 + Traefik 설정 정리 | **비가역** — 신중 |

### 8.2 롤백 기준

다음 신호 발견 시 즉시 단계 되돌림:
- Google Search Console 에서 apex URL 인덱스 60% 미만 (T+30d 기준)
- 카카오톡 미리보기에서 apex URL 의 OG 카드 실패 (T+14d 기준 샘플 5건 중 2건 이상)
- renderer p95 응답 시간 > 200ms (path 라우팅 오버헤드 검증)

### 8.3 검증 체크리스트

- [ ] Traefik priority 라벨이 `/teacher/{slug}` 를 ghost-www 보다 우선 처리 (curl 검증)
- [ ] `/.well-known/apple-app-site-association` 가 apex 에서 200 응답, `paths` 에 `/teacher/*` 포함
- [ ] iOS Universal Link 가 apex URL 로 앱 오픈 — 디바이스 테스트
- [ ] Android App Link 동일 검증
- [ ] `profile.lessonaza.app/{slug}` 301 응답 + Location 헤더 정확 (`lessonaza.app/teacher/{slug}`)
- [ ] redirect chain 깊이 1 (multi-hop 금지)
- [ ] 카카오톡 디버거 (`developers.kakao.com/tool/clear/og`) 로 OG 캐시 갱신 확인
- [ ] Ghost 페이지 URL 중 `/teacher` 또는 `/academy` 시작 page 가 없음 — Ghost Admin 검수 (있다면 Ghost slug 변경 필요)
- [ ] sitemap-teachers.xml 응답 시 ETag 정상
- [ ] `/academy/*` 라우팅이 안내 페이지 또는 404 응답 (Year 2 활성 전)

### 8.4 Traefik 버전 확인

- web VPS 현재 Traefik 버전 확인 (`docker exec traefik traefik version`)
- v1 → v2 마이그레이션 사이라면 v4 작업 전 v2 우선 완료 권장 (라우팅 문법 안정화)

## 9. 영향 받는 후행 스펙

| 스펙 | 수정 항목 |
|---|---|
| [README.md](README.md) | 도메인 매트릭스에 v4 컬럼 추가 — `lessonaza.app/teacher/{slug}` 행 + `/academy/{slug}` (Year 2). Docker 토폴로지에 path 라우팅 다이어그램 추가 |
| [teacher/profile_spec.md](teacher/profile_spec.md) | §3.1 URL 을 `lessonaza.app/teacher/{slug}` 로 갱신. §3.3 멀티테넌트 절에 v4 라우팅 명시. 변경 이력에 v4 항목 |
| [teacher/profile_renderer_spec.md](teacher/profile_renderer_spec.md) | §3 토폴로지 다이어그램 갱신. §11.1 Traefik 라벨에 `PathPrefix:/teacher,/academy,/.well-known` + priority 20. §9.1 라우트 표에 apex host + `/teacher/{slug}` path 추가 |
| [www/www_spec.md](www/www_spec.md) | §3.3 Traefik 라벨에 priority 10 명시. sitemap-index 가 sitemap-teachers.xml 참조하도록 §SEO 갱신 |
| [../user/slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md) | §3.1 URL 미리보기를 `lessonaza.app/teacher/{slug}` 로 변경. §3.2 예약어 절에 v4 전환 완료 후 "system" 카테고리 정리 + "brand/support" 재분류 명시 |
| [../user/teacher_registration.md](../user/teacher_registration.md) | 가입 화면 안내 텍스트 "내 프로필 주소" 부분을 `lessonaza.app/teacher/{slug}` 로 미리보기 변경 |
| [../profile/public_profile_content_spec.md](../profile/public_profile_content_spec.md) | SEO 메타 절의 canonical URL 예시 갱신 (`lessonaza.app/teacher/{slug}`) |
| `web/academy/` (예정) | AC-M2 작업 시 `/academy/{slug}` 라우팅 / sitemap-academies.xml / canonical 정책을 본 v4 스펙 §3.3 패턴에 맞춰 작성 |

위 후행 작업은 본 v4 스펙 **합의 후** 별도 PR / 작업으로 분리.

## 10. 옵시디언 동기화

| 파일 | 갱신 항목 |
|---|---|
| `17-www-profile-시장조사.md` | §8 결론 표에 "v4 (apex `/teacher/{slug}` + `/academy/{slug}` 통합)" 행 추가. 결정 사유에 수익·마케팅 축 명시 |
| `18-www-profile-요구사항.md` | §11 미해결 항목 중 "통합 vs 분리" → "v4 통합 확정" 으로 이동. 새 §14 (v4 결정) 추가 |
| `19-www-profile-가입-slug정책.md` | §13 v2 vs v3 비교 표 옆에 v4 컬럼 추가. slug 엔티티 prefix (`/teacher/` + `/academy/`) 정책을 §3.x 신설 |

## 11. 마일스톤 / 비용

| 단계 | 작업 | 비용 추정 |
|---|---|---|
| M-W1 | Traefik 라우팅 (path priority) 코드 작성 + 로컬 검증 | 0.5d |
| M-W2 | renderer canonical / og:url / schema.org URL 전환 | 0.5d |
| M-W3 | sitemap-teachers.xml 추가 + ghost-www sitemap-index 연결 | 0.5d |
| M-W4 | subdomain 301 Traefik middleware | 0.5d |
| M-W5 | iOS Universal Link / Android App Link 디바이스 테스트 | 1d |
| M-W6 | Search Console / Naver Webmaster 인덱스 마이그레이션 모니터링 | 30d (백그라운드) |
| M-W7 | T+365 subdomain DNS / Traefik 정리 | 0.5d |

총 신규 작업 ≈ 3.5d (Search Console 모니터링 제외).

## 12. 미해결 / 후속 검토

- [ ] 학원 (`/academy/{slug}`) 활성 시점 — Year 2 AC-M2 확정 후 본 v4 스펙 §3.3 패턴 적용
- [ ] 다국어 (`lessonaza.app/en/teacher/{slug}`) — v5 후보
- [ ] `/teacher/` prefix 가 한국어 검색 노출에 미치는 영향 — Naver 검색 패턴 사전 조사 (영문 path 가 검색 키워드와 매칭되는지)
- [ ] renderer 가 apex 의 사용자 쿠키를 절대 읽지 않도록 코드 가드 — pytest 회귀 추가
- [ ] 카카오톡 OG 캐시 강제 갱신 자동화 (선생님 publish 시 운영자 dashboard 에 디버거 링크 노출)

## 13. Lore (커밋 trailer 후보)

본 v4 채택 커밋에 첨부할 trailer:

```
Lore-directive: profile 도메인을 apex 로 통합 (`lessonaza.app/teacher/{slug}`) 채택 — 수익·마케팅 funnel 일원화
Lore-directive: slug 충돌 회피는 `/teacher/` + `/academy/` 엔티티 prefix 로 — depth 1 비용으로 의미 명확성 + 학원 확장성 + nested route 자연성 확보 (LinkedIn /in/, GitHub /orgs/, Reddit /r/ 패턴)
Lore-directive: 컨테이너 분리 유지 (ghost-www / profile-renderer) — Traefik path priority 라우팅 (renderer 20 / ghost 10) 으로 격리 보존
Lore-constraint: subdomain `profile.lessonaza.app` 은 12개월 301 redirect 보존 — 백링크/카카오톡 OG 캐시/검색 인덱스 손실 방지
Lore-rejected: `@` 접두사 (`/@chulgil-piano`) — 학원·스튜디오 확장 시 prefix 재설계 필요, nested route 어색 (`/@slug/reviews`), 한국 사용자 인지도 약함
Lore-rejected: 예약어 테이블 확장 — Ghost 페이지 추가마다 동기화 필요, race condition 위험
Lore-rejected: renderer 우선 + 404 폴백 — Ghost 신규 slug 추가 시 운영 race + 디버깅 난이도
Lore-rejected: Ghost 서브디렉토리화 (`/info/*`) — 기존 ghost-www URL SEO 손실 + 301 비용
```

## 14. 변경 이력

- 2026-05-21 v4 초안: subdomain → apex 통합. `/teacher/` + `/academy/` 엔티티 prefix 채택 (depth 1 비용으로 의미 명확 + 확장 자연 + nested route 보존). Traefik path priority 라우팅 (renderer 20 / ghost 10). 컨테이너 분리 유지.
