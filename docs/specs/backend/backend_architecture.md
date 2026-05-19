# Backend Architecture Guardrails (Backend)

> 기준일: 2026-05-18

## 배포 토폴로지 / 도메인 매트릭스

| 도메인 | 역할 | 호스트 | 환경 | 비고 |
|---|---|---|---|---|
| `api.lessonaza.app` | 백엔드 API (운영) | prod VPS | production | FastAPI, PostgreSQL 17 |
| `api-beta.lessonaza.app` | 백엔드 API (검증) | beta VPS | beta | prod 동일 토폴로지, 시드 데이터 포함 |
| `lessonaza.app` | 앱 소개 사이트 (www) | web VPS | production | Ghost 5.x (Docker, `ghost-www` 컨테이너) |
| `www.lessonaza.app` | apex 리다이렉트 | web VPS | production | Traefik redirect middleware → `lessonaza.app` 301 |
| `profile.lessonaza.app` | 선생님 프로필 사이트 | web VPS | production | Ghost 5.x (Docker, `ghost-profile` 컨테이너) — `lessonaza.app` 와 별도 인스턴스 |

**호스트 분리 원칙**: API 와 웹(www/profile) 은 **물리적으로 다른 VPS** 에 배포한다. 웹 사이트 트래픽/장애가 API 에 전파되지 않도록 격리한다.

**Docker 컨테이너 분리**: web VPS 내부에서 `ghost-www` 와 `ghost-profile` 은 **별도 컨테이너 + 별도 MySQL 인스턴스** 로 분리한다. 사이트 한 쪽 장애가 다른 쪽에 영향을 주지 않도록 한다. **Traefik** (외부 `traefiknet` 네트워크, backend `api.lessonaza.app` 와 단일 인스턴스 공유) 이 도메인별 라우팅과 TLS 자동 갱신(Let's Encrypt) 을 담당한다.

상세 토폴로지·운영 정책: `docs/specs/web/README.md`, `docs/specs/web/www_spec.md`, `docs/specs/web/profile_spec.md`.

## 환경 변수 / API Base URL 컨벤션

| 키 | prod | beta | 로컬 |
|---|---|---|---|
| `API_BASE_URL` | `https://api.lessonaza.app` | `https://api-beta.lessonaza.app` | `http://localhost:8000` |
| `WWW_BASE_URL` | `https://lessonaza.app` | `https://lessonaza.app` (공유) | `http://localhost:2368` |
| `PROFILE_BASE_URL` | `https://profile.lessonaza.app` | `https://profile.lessonaza.app` (공유) | `http://localhost:2369` |

- 백엔드 코드 내에서 외부 도메인을 하드코딩하지 않는다. 항상 `EnvironmentConfig` 또는 `settings` 에서 읽는다.
- 약관/개인정보 URL 은 `WWW_BASE_URL + /terms`, `WWW_BASE_URL + /privacy` 로 조합한다.
- 선생님 프로필 URL 은 `Teacher.profile_url` 컬럼에 절대 URL 로 저장한다 (nullable).

## 계층 구조

- **Router Layer** (`backend/app/api/v1/*`)
  - HTTP 입출력/권한 검사/스키마 바인딩만 담당.
- **Service Layer** (`backend/app/services/*`)
  - 트랜잭션, 권한, 정책, 이벤트/알림 생성, 부수효과 처리.
- **Repository/Model Layer** (`backend/app/models/*`)
  - 영속성 모델과 관계/제약만 정의.
- **Schema Layer** (`backend/app/schemas/*`)
  - API 입출력 계약(검증/직렬화).

## 운영 DB

- **PostgreSQL 17** (런타임 SSOT)
- 테스트는 격리된 SQLite 파일 기반 Async Engine 사용
  - `backend/tests/conftest.py`

## 아키텍처 가드레일

- Router가 SQLAlchemy query 직접 수행 금지 (`select`, `insert`, `update`, `delete` 등은 서비스에서만 사용)
- 하위 계층이 API 계층 import 금지
- 공통 규칙은 `backend/tests/test_backend_architecture_contract.py`로 검증
- 비즈니스 정책상 `/api/v1/payments` 라우터 미생성 유지
  - 수강료 입금 상태는 `/subscriptions`에서 관리

## 알림/메시지 영역 정합성

- 읽지 않음: `notifications.read_at IS NULL`
- `GET /api/v1/notifications/unread-count`는 동일 규칙으로 계산
- `generalAnnouncement`는 교사/학생/부모 공통 알림으로 처리되며, 인앱 알림 가시성 필터에 포함됨
- 선생님 공지 API (`/api/v1/announcements*`)는 인증 주체에서 `teacher_id`를 유추해 동작하도록 보완
- 휴강 공지는 `teacher_announcements + teacher_announcement_dates` 정규화 조인 테이블 기반으로 저장
- 결제/과금 범위는 `/subscriptions` 기반의 수동 수강료 입금 상태로 제한한다.
  - `/api/v1/payments` 계열 라우트는 앱 결제/PG 라우트로 간주하여 현재 미노출 상태를 유지한다.

## 신규 계약 완료 상태 (요약)

- `POST /api/v1/notifications/broadcast`
- `POST /api/v1/lessons/bulk-cancel`
- `POST /api/v1/announcements` (+ 목록/휴강일 조회)
- `/api/v1/schedule/confirmation-cards` 계열 정렬
- 부모 자녀 프로필 API
- 연습 리퍼토리/노트/녹음 계약 엔드포인트

## 웹 가입 / 프로필 / Slug 계약 (M4 — SSO-only)

> 상세: [signup_spec.md](../web/signup_spec.md), [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md), [profile_spec.md](../web/profile_spec.md)
>
> M4 가입은 **SSO 전용** (Google + Kakao). 이메일+비밀번호 가입 없음. Apple SSO 는 M5 (iOS 앱 출시 시점).

### 인증 / 가입 (SSO)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/auth/oauth/google/authorize?role=...` | 구글 OAuth URL 생성 + state 발급 (PKCE) |
| GET | `/api/v1/auth/oauth/kakao/authorize?role=...` | 카카오 OAuth URL 생성 + state 발급 |
| POST | `/api/v1/auth/oauth/google/callback` | 구글 콜백 (code+state) → 기존 User 로그인 또는 `signup_session_token` 발급 |
| POST | `/api/v1/auth/oauth/kakao/callback` | 카카오 콜백 + 이메일 동의 누락 시 가입 거부 |
| POST | `/api/v1/auth/signup/complete` | 약관 동의 + 역할별 추가 정보 → User/Teacher/Ghost Page 생성 |
| POST | `/api/v1/auth/logout` | 세션 종료 |
| GET | `/api/v1/users/me/linked-accounts` | 본인 연동 IdP 목록 |
| POST | `/api/v1/users/me/linked-accounts/{provider}` | 추가 IdP 연동 (본 계정 로그인 상태) |
| DELETE | `/api/v1/users/me/linked-accounts/{provider}` | 연동 해제 (최소 1개 IdP 유지 강제) |

운영자 SSO 는 **별도 IdP 키** + `admin.lessonaza.app` 서브도메인 + Google Workspace 도메인 제한 (`@lessonaza.app`) + 2FA. 일반 사용자 SSO 풀과 분리.

### 선생님 본인 프로필 (Option B — Custom Edit UI + Ghost Admin API 백엔드 프록시)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/teachers/me/profile` | 본인 Ghost Page 데이터 + Teacher 매핑 조회 |
| PUT | `/api/v1/teachers/me/profile` | 본인 Ghost Page 수정 (백엔드가 ghost_page_id 강제 셋) |
| POST | `/api/v1/teachers/me/profile/publish` | draft → published 전환 |
| POST | `/api/v1/teachers/me/profile/images` | 이미지 업로드 (Vultr Object Storage, S3 호환) |
| POST | `/api/v1/teachers/me/profile/preview` | 게시 전 미리보기 토큰 발급 |
| GET | `/api/v1/teachers/me/profile/slug/check?slug=...` | slug 가용성 확인 (형식/예약어/cooldown) |
| PUT | `/api/v1/teachers/me/profile/slug` | slug 변경 (Year 1: 가입 후 60일 내 1회만) |

### 운영자 slug 관리

| Method | Path | 책임 |
|---|---|---|
| POST | `/api/v1/admin/teachers/{id}/revoke-slug` | 운영자 즉시 회수 + cooldown 설정 + AuditLog |
| GET | `/api/v1/admin/slug-reserved-words` | 예약어 목록 조회 |
| POST | `/api/v1/admin/slug-reserved-words` | 예약어 추가 |

### Teacher 모델 확장 필드 (M4)

```python
class Teacher(Base):
    # 기존 ...
    # 프로필 매핑 (Ghost SSOT)
    profile_slug = Column(String(30), unique=True, nullable=True)
    ghost_page_id = Column(String(50), unique=True, nullable=True)
    profile_url = Column(String(500), nullable=True)
    profile_visibility = Column(String(20), default="draft")  # draft|public|members|dormant
    # 휴면 트래킹 (slug_lifecycle_spec)
    dormant_notice_6m_at = Column(DateTime, nullable=True)
    dormant_notice_9m_at = Column(DateTime, nullable=True)
    dormant_entered_at = Column(DateTime, nullable=True)
    slug_released_at = Column(DateTime, nullable=True)
```

### User 모델 확장 필드 (M4)

```python
class User(Base):
    # 기존 ...
    role = Column(Enum("teacher", "student", "parent", "academy_owner"), nullable=False)
    signup_source = Column(String(20), default="app")  # "app" | "web"
    email_verified_at = Column(DateTime, nullable=True)  # SSO 콜백 시 즉시 셋
    terms_version_agreed = Column(String(20), nullable=False)
    privacy_version_agreed = Column(String(20), nullable=False)
    marketing_consent = Column(Boolean, default=False)
    last_activity_at = Column(DateTime, default=func.now(), index=True)
    last_app_login_at = Column(DateTime, nullable=True)
    # password_hash 는 M4 에 nullable, M5(앱 SSO 전환 후) 에 drop 예정
```

### 신규 테이블 (M4)

- `auth_identities` — SSO IdP 연동 (provider, provider_user_id, user_id). **3-tuple unique** (provider + provider_user_id + User.role) — 같은 IdP 계정으로 선생님 + 학부모 별도 User 허용
- `terms_versions` — 약관/개인정보 동의 증거 (버전 + IP + UA)
- `slug_history` — slug 선점/회수 이력 (cooldown 추적)
- `slug_reserved_words` — 예약어 사전 (운영자 관리)

`email_verification_tokens` 는 **신설하지 않음** (SSO-only — IdP가 이메일 검증).

### 권한 격리 원칙 (Option B)

- Ghost Admin API 키는 **백엔드만 보관** — 클라이언트 노출 금지
- 모든 `/teachers/me/profile/*` 는 `Depends(require_teacher)` + `ghost_page_id = current_teacher.ghost_page_id` 강제
- 다른 선생님 페이지 ID 조작 시도 → 403 + AuditLog 기록
- Ghost 어드민 UI (`/ghost`) 는 운영자 전용 (선생님 노출 안 함)

## 외부 저장소/캐시

- Redis: 현재 캐시/락 계층 후보. 기본 운영 의존성은 아님.
- Graph DB(예: pg_graph, Neo4j): 본 스펙에서는 도입하지 않음.
- **Vultr Object Storage**: 프로필 이미지 + 백업 (S3 호환, 30일 보관)
- **Gmail SMTP**: 트랜잭션 메일 (App Password, 500/일 한도 — Year 2 SendGrid 전환 검토)
