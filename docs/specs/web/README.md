# Web Properties — www / profile

> 기준일: 2026-05-18
> 옵시디언 선행 문서: `mybrain/10 Projects/레슨앱/17-www-profile-시장조사.md`, `18-www-profile-요구사항.md`

Lessonaza 의 두 공개 웹 사이트 스펙을 모은 디렉토리.

## 스펙 인덱스

| 파일 | 범위 |
|---|---|
| [www_spec.md](www_spec.md) | 앱 소개 사이트 (`lessonaza.app`) — 마케팅, 블로그, 약관, 선생님 모집 |
| [profile_spec.md](profile_spec.md) | 선생님 프로필 사이트 (`profile.lessonaza.app/{slug}`) — 선생님 개인 페이지 |

## 도메인 매트릭스

| 도메인 | 사이트 | 컨테이너 | 어드민 경로 |
|---|---|---|---|
| `lessonaza.app` (apex) | www | `ghost-www` | `lessonaza.app/ghost` |
| `www.lessonaza.app` | → apex 리다이렉트 | (Caddy 301) | - |
| `profile.lessonaza.app` | profile | `ghost-profile` | `profile.lessonaza.app/ghost` |
| `api.lessonaza.app` | 백엔드 prod | (별도 VPS) | - |
| `api-beta.lessonaza.app` | 백엔드 beta | (별도 VPS) | - |

## Docker 토폴로지 (web VPS)

```
신규 VPS (Ubuntu 22.04, 2vCPU/2GB, 40GB SSD)
│
├─ docker compose
│  ├─ caddy            (reverse proxy, TLS 자동 갱신, 도메인 라우팅)
│  │  ├─ lessonaza.app          → ghost-www:2368
│  │  ├─ www.lessonaza.app      → 301 lessonaza.app
│  │  └─ profile.lessonaza.app  → ghost-profile:2368
│  ├─ ghost-www        (Ghost 5.x)
│  ├─ mysql-www        (MySQL 8, ghost-www 전용)
│  ├─ ghost-profile    (Ghost 5.x)
│  ├─ mysql-profile    (MySQL 8, ghost-profile 전용)
│  └─ backup-cron      (rclone → Backblaze B2, 매일 03:00 KST)
│
└─ volumes
   ├─ /var/lib/ghost-www/{content,db}
   └─ /var/lib/ghost-profile/{content,db}
```

**핵심 격리 원칙**:
- `ghost-www` 와 `ghost-profile` 은 컨테이너 + DB 인스턴스 분리
- 어드민 계정/권한 모델 분리 (운영자 vs 선생님)
- 백업 디렉토리 분리 (`/backup/www/`, `/backup/profile/`)
- 한 쪽 장애가 다른 쪽 가용성에 영향 주지 않음

## 디자인 시스템 적용

웹 사이트는 lesson-app 의 **"Notebook × Score" 디자인 컨셉**을 외부 채널에 확장한다.

- 시그니처 영역(랜딩, 프로필 메인, 빈 상태): NotebookGlyph 메타포 — 30개 글리프(♩ 𝄞 ✓ ★ ♥ 등) 활용한 일러스트/아이콘
- 일반 UI(폼, 네비, 푸터): Material 아이콘 허용
- 디자인 토큰: lesson-app `core/theme/app_colors.dart` / `app_typography.dart` 와 동일한 팔레트 (CSS 변수로 이식)
- 폰트: Gaegu (시그니처 영역), Pretendard (본문)
- 상세: `docs/specs/design/notebook/README.md`

## 보안 / 운영

- TLS: Caddy 자동 발급/갱신 (Let's Encrypt)
- 어드민 2FA 필수
- 백업: 매일 → Vultr Object Storage (S3 호환, 30일 보관), 주 1회 자동 복원 테스트
- 메일: Gmail SMTP (`lessonaza@gmail.com` + App Password, 500/일 한도, 트랜잭션 메일 전용)
- Analytics: GA4 (쿠키 동의 배너 필수)
- 모니터링: Uptime Kuma (self-host) + Slack 알림
- 보안 패치: Watchtower 또는 매주 수동 `docker compose pull && up -d`
- 로그 보관: 90일 (Caddy access log + Ghost log)

## lesson-app 백엔드와의 계약

| 백엔드 변경 | 위치 | 마일스톤 |
|---|---|---|
| `Teacher.profile_url` 컬럼 추가 (nullable, 절대 URL) | `backend/app/models/teacher.py` | M4 |
| 약관/개인정보 화면 → WebView (`WWW_BASE_URL/terms`) | `frontend/lib/features/legal/` | M4 |
| Universal Link / App Link — `profile.lessonaza.app/*` | iOS `apple-app-site-association`, Android `assetlinks.json` | M4 |
| 선생님 모집 폼 수신 엔드포인트 (선택) | `POST /api/v1/recruitment/applications` | M2 (선택) |

## 변경 이력

- 2026-05-18: 초안 작성 (Ghost self-host Docker 분리 전략 확정)
