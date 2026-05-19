# www_spec — 앱 소개 사이트

> 기준일: 2026-05-19 (v3 — Option D 정렬)
> 도메인: `lessonaza.app` (apex) / `www.lessonaza.app` (apex 로 301)
> 컨테이너: `ghost-www` (Ghost 5.x + MySQL 8)
> 선행: [README.md](README.md), `mybrain/10 Projects/레슨앱/17-www-profile-시장조사.md`, `18-www-profile-요구사항.md`

## 1. 개요

Lessonaza 앱(음악 레슨/연습 관리)의 공개 마케팅·콘텐츠 사이트.

**책임**:
- 신규 방문자에게 앱 가치 제안 + 다운로드 전환
- 블로그를 통한 SEO/오가닉 트래픽 확보
- 약관/개인정보 SSOT (lesson-app 이 링크/WebView 로 참조)
- 선생님 모집 채널

**비책임**:
- 사용자 인증/세션 관리 (lesson-app 백엔드가 담당)
- 결제 처리 (현재 무료, 향후 별도 시스템)
- 선생님별 개인 페이지 (`profile_spec.md` 참조)

## 2. 성공 기준

- [SC-1] 운영자가 코드 배포 없이 페이지/포스트를 5분 안에 게시
- [SC-2] LCP < 2.5s (3G), TTFB < 600ms — 모든 P0 페이지
- [SC-3] 약관 변경 → lesson-app WebView 에 즉시 반영 (< 5분)
- [SC-4] sitemap.xml, robots.txt, OG 메타 자동 생성
- [SC-5] 가용성 99.5%/월
- [SC-6] 백업 매일 + 복원 테스트 주 1회 자동화

## 3. 호스팅 / 도메인 / Docker

### 3.1 VPS

- **제공자: Vultr** (확정 2026-05-18)
- 인스턴스 타입: Vultr Cloud Compute Regular (2vCPU / 2GB RAM / 55GB SSD, $12/월) 또는 High Frequency (2vCPU / 2GB / 64GB NVMe, $18/월) — 운영자 선택
- OS: Ubuntu 22.04 LTS
- 리전: Seoul (Vultr 가용) 또는 Tokyo

### 3.2 DNS

```
A     lessonaza.app           → <web VPS IP>
A     www.lessonaza.app       → <web VPS IP>
A     profile.lessonaza.app   → <web VPS IP>
CNAME api.lessonaza.app       → (별도 API VPS DNS)
CNAME api-beta.lessonaza.app  → (별도 API VPS DNS)
```

### 3.3 docker-compose.yml (개요)

> Reverse proxy 는 **외부 Traefik** (`traefiknet` 외부 네트워크) 을 사용한다. backend (`api.lessonaza.app`) 와 동일한 Traefik 인스턴스를 공유하며, 컨테이너는 `traefik.*` 라벨로 라우팅을 선언한다.

```yaml
services:
  ghost-www:
    image: ghost:5-alpine
    environment:
      url: https://lessonaza.app
      database__client: mysql
      database__connection__host: mysql-www
      database__connection__user: ghost
      database__connection__password: ${WWW_DB_PASSWORD}
      database__connection__database: ghost_www
      mail__transport: SMTP
      mail__options__host: smtp.gmail.com
      mail__options__port: 587
      mail__options__secure: "false"  # STARTTLS
      mail__options__auth__user: lessonaza@gmail.com
      mail__options__auth__pass: ${GMAIL_APP_PASSWORD}  # 16자 앱 비밀번호
      mail__from: '"Lessonaza" <lessonaza@gmail.com>'
    volumes:
      - /var/lib/ghost-www/content:/var/lib/ghost/content
    networks: [traefiknet, www_internal]
    labels:
      - "traefik.enable=true"
      - "traefik.backend=ghost-www"
      - "traefik.docker.network=traefiknet"
      - "traefik.frontend.rule=Host:lessonaza.app"
      - "traefik.port=2368"
    depends_on: [mysql-www]

  www-apex-redirect:
    image: traefik/whoami  # 빈 백엔드 — Traefik redirect middleware 만 사용
    networks: [traefiknet]
    labels:
      - "traefik.enable=true"
      - "traefik.backend=www-apex-redirect"
      - "traefik.docker.network=traefiknet"
      - "traefik.frontend.rule=Host:www.lessonaza.app"
      - "traefik.frontend.redirect.regex=^https?://www\\.lessonaza\\.app/(.*)$$"
      - "traefik.frontend.redirect.replacement=https://lessonaza.app/$$1"
      - "traefik.frontend.redirect.permanent=true"

  mysql-www:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: ${WWW_DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ghost_www
      MYSQL_USER: ghost
      MYSQL_PASSWORD: ${WWW_DB_PASSWORD}
    networks: [www_internal]
    volumes:
      - /var/lib/ghost-www/db:/var/lib/mysql

  profile-renderer:
    # (profile_renderer_spec.md 참조) — FastAPI + Jinja2 SSR
    # Traefik 라벨로 profile.lessonaza.app 라우팅
    # 백엔드 내부 API 호출 (X-Internal-API-Token + IP whitelist)
    # 별도 DB 없음. 메모리 캐시(TTLCache 5분)만 보유

  backup-cron:
    image: offen/docker-volume-backup
    environment:
      BACKUP_FILENAME: lessonaza-%Y%m%d.tar.gz
      BACKUP_CRON_EXPRESSION: "0 3 * * *"  # 03:00 KST
      AWS_S3_BUCKET_NAME: lessonaza-backups
      AWS_ENDPOINT: https://sgp1.vultrobjects.com  # Vultr Object Storage (Seoul/Singapore endpoint)
      AWS_ACCESS_KEY_ID: ${VULTR_OBJ_ACCESS_KEY}
      AWS_SECRET_ACCESS_KEY: ${VULTR_OBJ_SECRET_KEY}
    volumes:
      - /var/lib/ghost-www:/backup/ghost-www:ro

networks:
  traefiknet:
    external: true   # 호스트 단일 Traefik 인스턴스 공유 (backend 와 동일)
  www_internal:
    driver: bridge   # ghost-www ↔ mysql-www 격리
```

### 3.4 Traefik 라우팅 (개요)

| Host | 라벨 (frontend.rule) | 백엔드 | TLS |
|---|---|---|---|
| `lessonaza.app` | `Host:lessonaza.app` | `ghost-www:2368` | Let's Encrypt 자동 (Traefik certResolver) |
| `www.lessonaza.app` | `Host:www.lessonaza.app` + redirect middleware | (없음 — 301 to apex) | 자동 |
| `profile.lessonaza.app` | `Host:profile.lessonaza.app` | `profile-renderer:8000` | 자동 |
| `api.lessonaza.app` | `Host:api.lessonaza.app` | (별도 API VPS — 같은 traefik.toml 에 정의) | 자동 |

**보안 헤더 (HSTS/CSP/X-Frame-Options 등)** 는 호스트 Traefik 의 글로벌 `headers` middleware 에서 일괄 적용. 컨테이너 라벨로 override 가능.

## 4. 정보 구조 (IA)

```
lessonaza.app
├─ /                              랜딩 페이지 (P0)
├─ /features                      기능 소개 (P0)
│  ├─ /features/metronome
│  ├─ /features/tuner
│  ├─ /features/practice-journal
│  └─ /features/lesson-management
├─ /pricing                       요금제 (P1)
├─ /blog                          블로그 인덱스 (P0)
│  └─ /blog/{slug}                포스트 (P0)
├─ /teachers                      선생님 모집 (P1)
├─ /about                         회사 소개 (P1)
├─ /faq                           FAQ (P0)
├─ /contact                       문의 (P1)
├─ /terms                         이용약관 (P0, lesson-app SSOT)
└─ /privacy                       개인정보 처리방침 (P0, lesson-app SSOT)
```

## 5. 페이지 명세

### 5.1 랜딩 (`/`)

| 섹션 | 내용 | 디자인 |
|---|---|---|
| Hero | 한 줄 가치 제안 + 앱 다운로드 CTA (iOS/Android) + 폰 목업 | NotebookGlyph 음표 ♩ 모티프, Gaegu 폰트, 베이지 노트북 배경 |
| 핵심 기능 3~5개 | 메트로놈 / 튜너 / 연습 저널 / 레슨 관리 / 선생님 매칭 | 각 카드 ✓ ★ 등 NotebookGlyph |
| 사용 사례 | 학생 / 학부모 / 선생님 관점 1~2개씩 | 인용문 + 인물 일러스트 |
| Social proof | 사용자 수 / 후기 / 미디어 노출 | 카운터 + 후기 카드 |
| Final CTA | "지금 다운로드" + QR + 스토어 배지 | sticky 푸터에도 노출 |

### 5.2 기능 소개 (`/features/*`)

각 기능별 1페이지. 공통 구조:
- 헤더 (기능명, 한 줄 설명)
- 스크린샷 3~5장 (lesson-app 실제 화면)
- 사용 방법 단계 (3~5스텝)
- 관련 블로그 포스트 링크
- "이 기능을 써보려면 다운로드"

### 5.3 가격 (`/pricing`)

- 현재: 모든 기능 무료
- 향후: 무료 / 프리미엄 / 팀 (선생님용) 3티어 (P2)
- 표 형식, 기능별 비교

### 5.4 블로그 (`/blog`)

- Ghost 표준 블로그 — 인덱스, 태그, 작성자
- 카테고리 후보: 연습 방법, 악기별 가이드, 선생님 인터뷰, 공지
- RSS feed: `lessonaza.app/rss/`

### 5.5 선생님 가입 랜딩 (`/teachers`)

> 상세 흐름: [signup_spec.md](signup_spec.md)

**Year 1 정책 변경 (2026-05-18)**: 운영자 검토를 거치는 "모집 신청 폼" 모델 폐기. `/teachers` 페이지는 **선생님 가입 1차 채널**로 직접 진입한다.

**페이지 구성**:
- 가치 제안 ("앱 미설치도 가능, 프로필을 외부에 공유")
- 혜택 (수강생 매칭, 일정 관리, 정산 · 무료 프로필 페이지)
- 사용 사례 (선생님 인터뷰 — `profile.lessonaza.app/{slug}` 링크)
- 가입 CTA → `lessonaza.app/signup?role=teacher` (이메일+비번 폼 없음, SSO 버튼만)

**SSO 버튼 (M4)**:
- [구글로 계속하기] — 글로벌 + 개발자 친화
- [카카오로 계속하기] — 한국 시장 90%+
- ~~[Apple로 계속하기]~~ — **M5** (iOS 앱 출시와 함께 추가, App Store §4.8)

**가입 후 흐름 (SSO)**:
1. SSO 버튼 클릭 → IdP 동의 화면
2. IdP 콜백 → 백엔드가 `signup_session_token` 발급 (이메일 검증은 IdP가 완료)
3. `/signup/complete?role=teacher` 페이지: 표시 이름(prefilled) + slug 선점 + 분야 태그 + 약관 동의
4. `POST /auth/signup/complete` → User + Teacher + TeacherProfile 자동 초기화 (status="draft")
5. lesson-app 인앱 편집 화면 진입 → 작성 → 운영자 첫 검토 통과 → 외부 공유 (카카오톡/SNS)

**비채택**:
- ~~운영자 검토 큐 (recruitment_applications 테이블)~~ — 모든 가입자는 즉시 활성화
- ~~별도 모집 신청 폼~~ — 가입 폼이 곧 모집 폼
- ~~이메일+비밀번호 가입~~ — SSO 전용 (signup_spec §3, §1.3)
- ~~이메일 인증 토큰~~ — IdP가 검증 (`email_verified=true` / 카카오 `is_email_valid=true`)

**악용 방지**:
- IdP 이메일 검증 강제 (Google `email_verified`, Kakao `is_email_valid` + `email_needs_agreement=false`)
- IdP state 토큰 (32B random) + Google PKCE — CSRF/Replay 차단
- reCAPTCHA v3 + Rate limit (signup_spec §10)
- 가입 후 콘텐츠 검수는 사후 모더레이션 (운영자 신고/모니터링)
- 슬러그 회수 정책 ([slug_lifecycle_spec](../user/slug_lifecycle_spec.md))으로 부적절 콘텐츠 즉시 차단 가능

### 5.6 약관 (`/terms`), 개인정보 (`/privacy`)

- **SSOT**: 본 페이지가 단일 진실 소스
- lesson-app 은 WebView 로 이 URL 로딩 (`features/legal/`)
- 변경 시 운영자 + 법무 검수 (Notion 체크리스트 통과 후 게시)
- 기존 `docs/specs/subscription/privacy_policy.md` 의 내용을 본 페이지로 이관 (가정 5번 후속)

### 5.7 FAQ (`/faq`)

- Ghost 페이지 1개 + Accordion (커스텀 테마 컴포넌트)
- 카테고리: 일반, 계정, 결제, 선생님, 학생, 부모, 기술 지원

## 6. SEO / 메타데이터

| 항목 | 규칙 |
|---|---|
| `<title>` | 페이지별 고유, 60자 이내 |
| `<meta name="description">` | 페이지별 고유, 155자 이내 |
| Open Graph | `og:title`, `og:description`, `og:image` (1200×630), `og:url`, `og:type` |
| Twitter Card | `summary_large_image` |
| `sitemap.xml` | Ghost 자동 생성 (`/sitemap.xml`) |
| `robots.txt` | `Allow: /`, `Sitemap: https://lessonaza.app/sitemap.xml` |
| `schema.org` | `Organization` (홈), `Article` (블로그), `FAQPage` (FAQ) |
| Canonical | 모든 페이지 self-canonical |
| `hreflang` | Phase 1 한국어만, Phase 2 `ko` / `en` |

## 7. 디자인 시스템

- **컨셉**: Notebook × Score (lesson-app `docs/specs/design/notebook/README.md` 참조)
- **컬러 토큰** (lesson-app `core/theme/app_colors.dart` 와 동기):
  - Background: `#FBF7F0` (notebook paper)
  - Primary ink: `#1A1A1A`
  - Accent: `#D97757` (스코어 액센트)
  - Secondary: `#A8B8C8` (악보 5선 연한 회색)
- **폰트**:
  - 시그니처 영역: Gaegu (제목, NotebookGlyph 일러스트)
  - 본문: Pretendard
- **NotebookGlyph 활용**: 히어로 ♩ 𝄞, 기능 카드 ✓ ★, 빈 상태 ○
- **금지**: 시그니처 영역에 일반 emoji (🎵 🎶) 사용 (lesson-app 정책과 동일)
- **테마**: Ghost 테마를 fork 하여 `lessonaza-notebook` 으로 커스텀 (handlebars + CSS)

## 8. 분석 / 추적

| 도구 | 용도 | 비용 |
|---|---|---|
| **GA4** (확정 2026-05-18) | 페이지 뷰, 전환율, UTM, 사용자 행동 분석 | $0 |
| Google Search Console | 검색 키워드, 인덱싱 | $0 |
| UTM 파라미터 | 광고/SNS 출처 추적 | $0 |
| 앱 설치 추적 | Firebase Dynamic Links → Firebase Analytics | $0 |

**GA4 동의 처리**: PIPA 준수를 위해 첫 방문 시 쿠키 동의 배너 표시 (Ghost 테마 커스텀). 동의 전에는 GA4 스크립트 로드 금지.

## 9. 배포 / CI

- **저장소**: 별도 Git 리포지토리 (`lesson-app-web` 또는 lesson-app submodule). 결정은 운영자 합의.
- **배포 흐름**:
  1. 운영자가 Git push (테마/Traefik 라벨 변경 시) 또는 Ghost 어드민 직접 편집 (콘텐츠 변경 시)
  2. GitHub Actions: 테마 변경 시 web VPS 로 SCP + `docker compose restart ghost-www`
  3. 콘텐츠 변경은 Ghost 어드민에서 즉시 반영 (배포 불필요)
- **마이그레이션**: Ghost 5.x → 6.x 업그레이드 시 스테이징 컨테이너 검증 후 본 컨테이너 교체

## 10. 운영

| 항목 | 정책 |
|---|---|
| 어드민 계정 | 운영자 1명 (Owner), 백업 운영자 1명 (Administrator) |
| 2FA | 필수 (Ghost 5.x Authenticator) |
| 백업 | 매일 03:00 KST → Vultr Object Storage (S3 호환, $5/월 250GB), 30일 보관 |
| 복원 테스트 | 주 1회 자동 (스테이징 컨테이너 복원 → 헬스체크 → 알림) |
| 보안 패치 | Watchtower 자동 또는 매주 수동 (`docker compose pull && up -d`) |
| 모니터링 | Uptime Kuma (5분 간격, /health 페이지) → Slack 알림 |
| 로그 | Traefik access log + Ghost log, 90일 보관 |

## 11. 보안

- HSTS, CSP, X-Frame-Options, X-Content-Type-Options 헤더 (Traefik 글로벌 headers middleware 에서 설정)
- TLS 1.3 (Traefik certResolver, Let's Encrypt 자동 발급/갱신)
- 어드민 경로(`/ghost`) IP 화이트리스트 (선택, 운영자 IP 고정 시)
- Ghost 어드민 2FA 필수
- 폼 입력값 → 백엔드 API 로 전송, www DB 에 저장 금지
- DB 비밀번호: `.env` 파일 (git ignore), 백업에서 마스킹

## 12. 마일스톤 (M1 + M2)

| 단계 | 작업 | 기간 |
|---|---|---|
| M1.1 | VPS 셋업, Docker, Traefik 라벨/네트워크 연결, 도메인 DNS | 2일 |
| M1.2 | ghost-www 컨테이너 + MySQL + 초기 어드민 가입 + TLS | 1일 |
| M1.3 | Lessonaza-notebook 테마 1차 (랜딩, 기본 페이지 레이아웃) | 3일 |
| M1.4 | 약관/개인정보/FAQ 페이지 (기존 lesson-app 콘텐츠 이관) | 2일 |
| M1.5 | 백업 자동화 + Uptime Kuma | 2일 |
| **M1 종료** | **약관 변경 → lesson-app WebView 반영 확인** | **2주** |
| M2.1 | 랜딩 본 콘텐츠 + 히어로/CTA 디자인 확정 | 3일 |
| M2.2 | 기능 소개 4페이지 (메트로놈/튜너/저널/관리) | 4일 |
| M2.3 | 블로그 첫 5개 포스트 | 3일 |
| M2.4 | 선생님 모집 페이지 + 폼 | 2일 |
| M2.5 | SEO (sitemap, schema.org, OG 검증) + Plausible 연결 | 2일 |
| **M2 종료** | **공개 발표** | **+2주 = 누적 4주** |

## 13. 의존성

- `Teacher.profile_url` 백엔드 컬럼 — M4 (lesson-app 측 작업)
- 약관/개인정보 콘텐츠 — `docs/specs/subscription/privacy_policy.md` 이관 (M1.4)
- 도메인 소유권 확인 — M1.1 선행
- VPS 결제 수단 — M1.1 선행

## 14. 미해결 질문 (사용자 확인 필요)

확정 (2026-05-18):
- [x] VPS 공급자: **Vultr** (Cloud Compute Regular or High Frequency)
- [x] 백업 스토리지: **Vultr Object Storage** (S3 호환, $5/월)
- [x] 메일 발송: **Gmail SMTP** (`lessonaza@gmail.com` + 앱 비밀번호, 500/일 트랜잭션만)
- [x] Analytics: **GA4** (PIPA 쿠키 동의 배너 포함)

확정 (2026-05-18 v2):
- [x] 선생님 모집 폼 — 폐기. `/teachers` 는 가입 1차 채널 ([signup_spec](signup_spec.md), [slug_lifecycle_spec](../user/slug_lifecycle_spec.md))
- [x] 권한 격리 — Option D (백엔드 직접 렌더링 + TeacherProfile SSOT + profile-renderer 컨테이너) — [profile_spec §3](profile_spec.md)

미정:
- [ ] 테마 저장소 — lesson-app monorepo vs 별도 리포지토리
- [ ] Newsletter 발송 (Phase 2 이후) — Mailgun $35/월 vs Buttondown vs 자체 발송 차단
- [ ] 첫 시범 선생님 — M3.4 (profile_spec §13)

## 15. 변경 이력

- 2026-05-18: 초안 (Ghost self-host Docker 분리 전략 확정)
- 2026-05-18 (v2): 선생님 모집 폼 폐기 → `/teachers` 가입 1차 채널로 전환. [signup_spec.md](signup_spec.md) 신설.
- 2026-05-19 (v3): Option D 채택 — `ghost-profile` / `mysql-profile` 컨테이너 제거, `profile-renderer` (FastAPI + Jinja2 SSR) 추가. TeacherProfile 1:1 분리 모델 적용 ([profile_spec.md](profile_spec.md)).
