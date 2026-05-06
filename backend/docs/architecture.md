# Backend Architecture

> 마지막 업데이트: 2026-05-06

## 개요

음악 레슨/연습 관리 앱의 백엔드 API 서버. Flutter 프론트엔드와 REST API로 통신하며, 오프라인/Mock 중심 프론트 기능을 서버 기반 원격 repository 계약으로 전환한다.

---

## 기술 스택

| 항목 | 기술 | 버전 | 비고 |
|------|------|------|------|
| Framework | FastAPI | 0.115+ | async 지원 |
| ORM | SQLAlchemy | 2.0+ | async engine |
| Database | PostgreSQL | 17+ | Docker / codenavi 서버 |
| Schema | Pydantic | v2 | 요청/응답 직렬화 |
| Auth | 자체 JWT + OAuth2 | - | Google/Kakao/Apple, dev-login |
| i18n | 자체 구현 | - | ko, en, ja (확장 가능) |
| Migration | Alembic | 1.13+ | auto-generate |
| Package | UV | latest | 의존성 관리 |
| Runtime | Python | 3.12+ | - |
| File Storage | Vultr Object Storage | - | 녹음 파일 |
| Internal Jobs | APScheduler + internal API key | - | 자동화 job 및 수동 실행 API |
| Server | Nginx + uvicorn | - | 리버스 프록시 |

---

## 프로젝트 구조

```
backend/
├── app/
│   ├── main.py                       # FastAPI 엔트리포인트
│   ├── core/
│   │   ├── config.py                 # Pydantic BaseSettings (.env 로딩)
│   │   ├── database.py               # SQLAlchemy async engine/session
│   │   ├── security.py               # JWT 생성/검증, OAuth 클라이언트 (Google/Kakao/Apple)
│   │   ├── deps.py                   # 의존성 주입 (get_db, get_current_user, get_locale)
│   │   ├── exceptions.py             # 커스텀 예외 + 핸들러
│   │   ├── i18n.py                   # 다국어 미들웨어 + 번역 로더
│   │   └── storage.py                # Vultr Object Storage 클라이언트
│   │
│   ├── models/                       # SQLAlchemy ORM 모델 (28 files)
│   │   ├── base.py                   # Base, TimestampMixin, UUIDMixin
│   │   ├── user.py                   # User, OAuthAccount, TokenBlacklist
│   │   ├── teacher.py                # Teacher, Education, Career, Certificate
│   │   ├── student.py                # Student
│   │   ├── lesson.py                 # LessonClass, ClassMembership, Lesson, LessonRecording
│   │   ├── subscription.py           # Subscription, Usage, Template, Proposal
│   │   ├── payment.py                # Payment, TuitionSettings (레거시 상태 기록용, API 없음)
│   │   ├── practice.py               # Repertoire, Section, Recording, Note, Goal, Piece
│   │   ├── schedule.py               # Availability, Booking, LessonRequest
│   │   ├── schedule_ext.py           # ScheduleException, GroupClassSchedule, NoShow, ScheduleChange
│   │   ├── relationship.py           # TeacherStudentRelation, Follow
│   │   ├── parent.py                 # Parent, ParentChildRelation, ParentTeacherConnection
│   │   ├── settings.py               # teacher/subscription/proposal/notification settings
│   │   ├── policy.py                 # LessonPolicy, MakeupLesson, ScheduleConfirmationCard
│   │   └── request_event.py          # LessonRequest / subscription event log
│   │
│   ├── schemas/                      # Pydantic v2 요청/응답 스키마 (31 files)
│   │   ├── auth.py                   # TokenResponse, OAuthRequest
│   │   ├── user.py                   # UserRead, UserUpdate
│   │   ├── teacher.py                # TeacherRead, TeacherUpdate
│   │   ├── student.py                # StudentCreate, StudentRead, StudentUpdate
│   │   ├── lesson.py                 # LessonCreate, LessonRead, LessonUpdate
│   │   ├── subscription.py           # SubscriptionCreate, TemplateCreate, ProposalCreate
│   │   ├── practice.py               # RepertoireCreate, SectionCreate, RecordingUpload
│   │   ├── schedule.py               # AvailabilityUpdate, BookingCreate
│   │   ├── notification.py           # NotificationRead
│   │   ├── parent.py                 # ParentRead, ChildCreate
│   │   └── common.py                 # PaginatedResponse, ErrorResponse
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── __init__.py           # v1 라우터 통합
│   │       ├── auth.py               # /auth/*
│   │       ├── users.py              # /users/*
│   │       ├── teachers.py           # /teachers/*
│   │       ├── students.py           # /students/*
│   │       ├── memberships.py        # /memberships/*
│   │       ├── lessons.py            # /lessons/*
│   │       ├── subscriptions.py      # /subscriptions/*
│   │       ├── practice.py           # /practice/*
│   │       ├── practice_logs.py      # /practice-logs/*
│   │       ├── recordings.py         # /recordings/*
│   │       ├── schedule.py           # /schedule/*
│   │       ├── bookings.py           # /bookings/*
│   │       ├── relationships.py      # /relationships/*
│   │       ├── parents.py            # /parents/*
│   │       ├── notifications.py      # /notifications/*
│   │       ├── schedule_confirmations.py # /schedule/confirmation-cards/*
│   │       ├── schedule_exceptions.py    # /schedule-exceptions/*
│   │       ├── settings_api.py       # /settings/*
│   │       └── device_tokens.py      # /device-tokens/*
│   │
│   ├── services/                     # 비즈니스 로직 (36 files)
│   │   ├── auth_service.py           # OAuth + JWT
│   │   ├── lesson_service.py         # 레슨 CRUD + 상태 관리
│   │   ├── subscription_service.py   # 구독 + 차감 + 제안 워크플로우
│   │   ├── practice_service.py       # 연습 + 통계 + 스트릭
│   │   ├── recording_service.py      # 녹음 업로드/다운로드 (Object Storage)
│   │   ├── schedule_service.py       # 가용시간 + 예약
│   │   ├── notification_service.py   # 알림 생성 + 발송
│   │   ├── analytics_service.py      # 월간 통계 집계
│   │   ├── post_service.py           # 선생님/학원 피드
│   │   ├── lesson_policy_service.py  # 레슨 정책 CRUD
│   │
│   └── utils/
│       ├── datetime.py               # UTC ↔ 사용자 타임존 변환
│       ├── currency.py               # 통화 포맷팅 (KRW, USD, JPY)
│       └── pagination.py             # 페이지네이션 헬퍼
│
├── alembic/                          # DB 마이그레이션
│   ├── versions/                     # 마이그레이션 파일
│   ├── env.py
│   └── alembic.ini
│
├── tests/
│   ├── conftest.py                   # 테스트 DB, 클라이언트 fixture
│   ├── test_auth.py
│   ├── test_lessons.py
│   ├── test_subscriptions.py
│   ├── test_practice.py
│   └── test_backend_architecture_contract.py
│
├── pyproject.toml                    # UV 의존성 + 프로젝트 설정
├── .env.example                      # 환경변수 샘플
└── README.md
```

---

## 레이어 아키텍처

```
┌─────────────────────────────────┐
│  API Layer (api/v1/)            │  FastAPI 라우터 + 의존성 주입
│  - Request validation           │  Pydantic v2 스키마
│  - Auth middleware              │  JWT 검증
├─────────────────────────────────┤
│  Service Layer (services/)      │  비즈니스 로직
│  - Transaction management       │  get_db dependency commit/rollback
│  - Cross-domain orchestration   │  예: 레슨 완료 → 구독 차감 → 알림
├─────────────────────────────────┤
│  Model Layer (models/)          │  SQLAlchemy ORM
│  - Table definitions            │  Mapped columns + relationships
│  - Query helpers                │  자주 쓰는 필터 조합
├─────────────────────────────────┤
│  Database                       │  PostgreSQL 17 (async)
│  - Alembic migrations           │  스키마 버전 관리
│  - Connection pooling           │  asyncpg 드라이버
└─────────────────────────────────┘
```

### 의존성 흐름

```
Router → Service → Model → Database
  ↓         ↓
Schema    Schema (Pydantic v2)
```

- **Router**: HTTP 요청 수신, 스키마 검증, 서비스 호출. DB query/mutation 직접 수행 금지
- **Service**: 트랜잭션 관리, 비즈니스 규칙, 여러 모델 조합
- **Model**: DB 테이블 매핑, 관계 정의
- **Schema**: 요청/응답 직렬화, 필드 검증

### 자동 아키텍처 계약

`backend/tests/test_backend_architecture_contract.py`는 다음 규칙을 강제한다.

- API router는 `select`, `func`, `insert`, `update`, `delete` 같은 SQLAlchemy query helper를 직접 import하지 않는다.
- API router는 `db.get/scalar/scalars/execute/add/delete/flush/refresh`를 직접 호출하지 않는다.
- `models`, `schemas`, `services`는 `app.api` 계층을 import하지 않는다.
- `schemas`는 `app.models` 계층을 import하지 않는다. API 계약은 Pydantic 필드와 validator로 표현하고, ORM enum/모델 변환은 service/model 계층에서 처리한다.
- `app.models`에 등록된 테이블은 Alembic active migration에서 생성/변경 이력이 있어야 한다. 테스트 fixture의 `Base.metadata.create_all`은 migration 누락을 숨길 수 있으므로, 새 모델을 추가할 때 migration contract test를 함께 둔다.
- PostgreSQL native enum을 쓰는 모델 enum 값이 늘어나면 Alembic migration과 enum contract test를 함께 추가한다. SQLite 테스트 DB는 enum type 누락을 드러내지 못하므로, `ALTER TYPE` 또는 enum 재생성 패턴을 migration source 계약으로 검증한다.
- DB 무결성 보강은 `backend/docs/db_integrity_inventory.json`을 기준으로 진행한다. 아직 FK/비즈니스 제약을 걸지 못한 컬럼은 이 인벤토리에 등록하고, 마이그레이션으로 해소하면 해당 항목을 제거한다. `backend/tests/test_db_integrity_inventory.py`가 인벤토리의 테이블/컬럼 오타와 회차별 시간변경 원격 계약 상태를 검증한다.
- 현행 수강료 정책상 `/api/v1/payments` 라우터를 만들지 않는다.
- 모든 router decorator는 `status_code`를 명시해야 한다. 기본 200을 쓰는 경우에도 API 문서와 프론트 원격 계약을 위해 `status.HTTP_200_OK`를 적는다.
- OpenAPI `operationId`는 전체 API에서 유일해야 한다. 동일한 함수명을 여러 라우터에서 쓰거나 레거시/신규 경로를 병행 노출할 때는 명시적 `operation_id`를 지정한다.
- `/api/v1`의 non-204 2xx 응답은 OpenAPI response schema를 가져야 한다. 프론트 호환성 때문에 여러 shape를 반환하는 레거시 endpoint도 Pydantic union schema로 명시한다.
- `/api/v1` operation은 공개 allowlist를 제외하고 OpenAPI security 요구사항을 가져야 한다.
  - 공개 allowlist: `POST /auth/oauth/{provider}`, `POST /auth/dev-login`, `POST /auth/token/refresh`, `GET /users/supported-locales`
  - 내부 자동화 API: `/scheduler/*`는 사용자 JWT가 아니라 `X-Internal-API-Key` 헤더와 `INTERNAL_API_KEY` 환경변수로 보호한다.
- `production`/`beta` 환경에서는 FastAPI lifespan 시작 시 runtime configuration을 검증한다. 배포 환경은 `JWT_SECRET_KEY`와 `INTERNAL_API_KEY`를 32자 이상 secret으로 설정해야 한다.

기능 추가 전후에 다음 명령으로 검증한다.

```bash
cd backend && uv run pytest tests/test_backend_architecture_contract.py -q
```

### 도메인 경계

- 수강권 입금 상태는 `/subscriptions/*`에서 `payment_confirmed`, `paid_at`, `payment_confirmed_at`으로 관리한다.
- `payments` / `tuition_settings` 모델은 레거시 상태 기록용이며 현행 API surface가 아니다.
- 선생님/학원 수강료는 앱 밖 무통장입금/현금으로 처리한다. PG, 카드, 정산, 영수증, 자동 입금 매칭은 구현 대상이 아니다.
- 향후 Lessonaza 앱 사용료 과금은 별도 스펙과 별도 모델/라우터로 분리한다.
- 수강권 회차별 시간변경은 `/subscriptions/{subscription_id}/events`의 `RequestEvent`가 원격 SSOT다. 단일 회차는 `session_number`, 변경 범위는 `schedule_change_type`으로 식별하고, 변경/수락/거절/역제안은 `scheduleChanged`, `scheduleChangeProposed`, `scheduleChangeAccepted`, `scheduleChangeRejected`, `scheduleChangeCountered` 이벤트로 기록한다. 배지/목록은 `GET /subscriptions/schedule-change-events/pending`에서 현재 사용자가 응답해야 하는 최신 회차 이벤트만 반환한다. `/schedule-changes` 라우트는 레거시 일정 변경 표면이므로 수강권 상세 화면의 회차별 변경 계약을 확장할 때는 우선 subscription event API를 확장한다.
- 프론트 mock 대체 API는 화면별 mock shape를 그대로 복제하지 않는다. teacher/student/subscription scoped 도메인 API로 제공하고, 프론트 remote repository가 그 API를 조합한다. 선생님 개인 라이브러리는 `/settings/*` 아래에 둔다. 예: `feedback-presets`, `teaching-resources`, `tip-templates`.
- 정규화가 필요한 반복 값은 JSON 배열로 저장하지 않는다. 검색/필터/중복 제약이 필요한 태그는 별도 테이블로 분리한다. 예: 장문 피드백 템플릿은 `feedback_templates`와 `feedback_template_tags`로 저장하고, API 응답에서 `tags: list[str]`로 조립한다.

### DB 무결성 baseline

현재 모델은 `subscriptions`, `subscription_usages`, `subscription_templates`, `subscription_proposals`, `request_events.subscription_id`처럼 최근 보강된 수강권 핵심 FK는 갖추고 있다. 반면 오래된 학생/레슨/연습/부모/알림 도메인은 `String(36)` 식별자와 service-level ownership check에 의존하는 곳이 남아 있다.

보강 순서는 다음을 기준으로 한다.

1. 접근권한의 기준이 되는 관계 테이블: `students`, `teacher_student_relations`, `parent_child_relations`
2. 수강권과 연결되는 레슨/멤버십 테이블: `lesson_classes`, `class_memberships`, `lessons`
3. 원격 mock 제거와 직접 연결되는 연습/알림/스케줄 테이블: `practice_*`, `notifications`, `teacher_availabilities`
4. 데이터 정리가 필요한 레거시 상태 기록: `payments`, `tuition_settings`, standalone lesson rows

각 단계는 `db_integrity_inventory.json`의 항목을 하나 이상 제거하는 마이그레이션과 metadata contract test를 함께 포함해야 한다. 데이터 정리가 필요한 nullable legacy 컬럼은 먼저 orphan audit query와 backfill 정책을 문서화한 뒤 FK를 적용한다.

---

## 설정 관리

### 환경변수 (.env)

```bash
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/lessonaza
DATABASE_ECHO=false

# JWT
JWT_SECRET_KEY=your-secret-key
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# OAuth - Google
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx

# OAuth - Kakao
KAKAO_CLIENT_ID=xxx
KAKAO_CLIENT_SECRET=xxx

# OAuth - Apple
APPLE_CLIENT_ID=com.lessonapp.app
APPLE_TEAM_ID=xxx
APPLE_KEY_ID=xxx
APPLE_PRIVATE_KEY_PATH=./keys/AuthKey_xxx.p8

# i18n
DEFAULT_LOCALE=ko
SUPPORTED_LOCALES=["ko","en","ja"]

# Vultr Object Storage
VULTR_STORAGE_ENDPOINT=https://sgp1.vultrobjects.com
VULTR_STORAGE_ACCESS_KEY=xxx
VULTR_STORAGE_SECRET_KEY=xxx
VULTR_STORAGE_BUCKET=lesson-app-recordings

# Server
CORS_ORIGINS=["http://localhost:3000"]
INTERNAL_API_KEY=generate-with-openssl-rand-hex-32
```

### Config 클래스

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    database_url: str
    database_echo: bool = False

    # JWT
    jwt_secret_key: str
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 30

    # OAuth - Google
    google_client_id: str
    google_client_secret: str

    # OAuth - Kakao
    kakao_client_id: str
    kakao_client_secret: str

    # OAuth - Apple
    apple_client_id: str          # Bundle ID (com.lessonapp.app)
    apple_team_id: str
    apple_key_id: str
    apple_private_key_path: str   # .p8 파일 경로

    # i18n
    default_locale: str = "ko"
    supported_locales: list[str] = ["ko", "en", "ja"]

    # Storage
    vultr_storage_endpoint: str
    vultr_storage_access_key: str
    vultr_storage_secret_key: str
    vultr_storage_bucket: str = "lesson-app-recordings"

    # CORS
    cors_origins: list[str] = ["http://localhost:3000"]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

settings = Settings()
```

---

## 핵심 패턴

### 1. Async DB 세션

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

engine = create_async_engine(settings.database_url, echo=settings.database_echo)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

### 2. 의존성 주입

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_jwt(token)
    user = await db.get(User, payload["sub"])
    if not user:
        raise HTTPException(401, "User not found")
    return user

async def get_current_teacher(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Teacher:
    if user.role != UserRole.teacher:
        raise HTTPException(403, "Teacher access required")
    teacher = await db.scalar(select(Teacher).where(Teacher.user_id == user.id))
    return teacher
```

### 3. Pydantic v2 스키마

```python
from pydantic import BaseModel, ConfigDict
from datetime import datetime

class StudentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    instrument: str
    level: StudentLevel
    status: StudentStatus
    created_at: datetime

class StudentCreate(BaseModel):
    name: str
    instrument: str
    level: StudentLevel = StudentLevel.beginner
    phone: str | None = None
```

### 4. 페이지네이션

```python
class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    size: int
    pages: int
```

### 5. 에러 핸들링

```python
class AppException(Exception):
    def __init__(self, status_code: int, detail: str, code: str = "error"):
        self.status_code = status_code
        self.detail = detail
        self.code = code

# 커스텀 예외
class NotFoundError(AppException):
    def __init__(self, resource: str, id: str):
        super().__init__(404, f"{resource} not found: {id}", "not_found")

class ForbiddenError(AppException):
    def __init__(self, message: str = "Forbidden"):
        super().__init__(403, message, "forbidden")
```

---

## 타임존 규칙

| 구분 | 시간대 | 비고 |
|------|--------|------|
| DB 저장 | UTC | `DATETIME` 컬럼 |
| API 응답 | UTC (ISO 8601) | 클라이언트가 변환 |
| 서버 로직 | UTC | 비교/계산 |
| 프론트엔드 표시 | 사용자 타임존 | `user.timezone` 기반 변환 |

> **다국어 환경**: KST 고정이 아닌 사용자별 `timezone` 필드(IANA) 기반으로 변환.
> DB는 항상 UTC 저장, API는 항상 UTC 응답, 변환은 클라이언트 담당.

---

## 다국어 (i18n) 설계

### 아키텍처 원칙

1. **UI 번역은 프론트엔드** 담당 (Flutter `intl` / `flutter_localizations`)
2. **서버 측 번역**은 알림 메시지, 이메일, 푸시 알림 등 서버가 생성하는 텍스트만 담당
3. **사용자 데이터** (레슨 피드백, 연습 노트 등)는 번역하지 않음 — 원문 그대로 저장

### 서버 i18n 범위

| 항목 | 번역 주체 | 저장 위치 |
|------|----------|----------|
| 앱 UI 문자열 | Flutter (클라이언트) | `frontend/lib/l10n/` |
| 푸시 알림 | 백엔드 | `i18n_translations` 테이블 |
| 이메일 템플릿 | 백엔드 | `i18n_translations` 테이블 |
| 시스템 에러 메시지 | 백엔드 | `i18n_translations` 테이블 |
| Enum 라벨 (API) | 백엔드 | `i18n_translations` 테이블 |
| 사용자 입력 (피드백 등) | 없음 (원문) | 각 도메인 테이블 |

### Accept-Language 미들웨어

```python
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class LocaleMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # 1. Accept-Language 헤더에서 locale 추출
        accept_lang = request.headers.get("Accept-Language", "ko")
        locale = parse_accept_language(accept_lang)

        # 2. 지원하는 locale인지 확인, 아니면 기본값
        if locale not in settings.supported_locales:
            locale = settings.default_locale

        # 3. request.state에 저장 → 이후 핸들러에서 사용
        request.state.locale = locale
        response = await call_next(request)
        response.headers["Content-Language"] = locale
        return response

def parse_accept_language(header: str) -> str:
    """Accept-Language 헤더 파싱. 예: 'ko-KR,ko;q=0.9,en;q=0.8' → 'ko'"""
    for part in header.split(","):
        lang = part.split(";")[0].strip().split("-")[0]
        if lang in settings.supported_locales:
            return lang
    return settings.default_locale
```

### 번역 서비스

```python
class TranslationService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self._cache: dict[str, dict[str, str]] = {}  # locale -> {key: value}

    async def get(self, key: str, locale: str, **kwargs) -> str:
        """번역 문자열 반환. kwargs로 템플릿 변수 치환."""
        translation = await self._get_from_cache_or_db(key, locale)
        if not translation:
            # Fallback: ko → en → key 자체
            translation = await self._get_from_cache_or_db(key, "ko")
        if not translation:
            return key
        return translation.format(**kwargs) if kwargs else translation

    # Example usage in notification service:
    # await t.get("notification.lesson_booked.title", user.locale)
    # await t.get("notification.lesson_booked.body", user.locale,
    #             student_name="김학생", date="3/5", time="14:00")
```

### 통화 처리

| 국가 | 통화 | 최소 단위 | 금액 저장 | 표시 |
|------|------|----------|----------|------|
| KR | KRW | 1원 | `200000` | ₩200,000 |
| US | USD | 1센트 | `5000` (= $50.00) | $50.00 |
| JP | JPY | 1엔 | `5000` | ¥5,000 |

```python
from decimal import Decimal

def format_currency(amount: int, currency: str) -> str:
    """금액을 통화별 표시 형식으로 변환."""
    formats = {
        "KRW": (0, "₩", ","),   # 소수점 없음
        "USD": (2, "$", ","),   # 소수점 2자리
        "JPY": (0, "¥", ","),   # 소수점 없음
    }
    decimals, symbol, sep = formats.get(currency, (2, "", ","))
    if decimals > 0:
        value = Decimal(amount) / (10 ** decimals)
        return f"{symbol}{value:,.{decimals}f}"
    return f"{symbol}{amount:,}"
```

### 지원 로케일 (Phase 1)

| 로케일 | 언어 | 국가 | 타임존 | 통화 | 상태 |
|--------|------|------|--------|------|------|
| `ko` | 한국어 | KR | Asia/Seoul | KRW | 출시 시 |
| `en` | English | US | America/New_York | USD | Phase 2 |
| `ja` | 日本語 | JP | Asia/Tokyo | JPY | Phase 3 |

---

## 의존성 (pyproject.toml)

```toml
[project]
name = "lesson-app-backend"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "sqlalchemy[asyncio]>=2.0.36",
    "asyncmy>=0.2.9",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.6.0",
    "alembic>=1.14.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
    "httpx>=0.28.0",
    "python-multipart>=0.0.12",
    "boto3>=1.35.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.28.0",
    "mypy>=1.13.0",
    "ruff>=0.8.0",
]
```

---

## 프론트엔드 매핑

Flutter Repository 인터페이스와 백엔드 API의 1:1 매핑:

| Flutter Repository | Backend API | Service |
|-------------------|-------------|---------|
| `LessonRepository` | `/api/v1/lessons/*` | `LessonService` |
| `StudentRepository` | `/api/v1/students/*` | (CRUD only) |
| `SubscriptionRepository` | `/api/v1/subscriptions/*` | `SubscriptionService` |
| `PracticeRepository` | `/api/v1/practice/*` | `PracticeService` |
| `RecordingRepository` | `/api/v1/recordings/*` | `RecordingService` |
| `ScheduleRepository` | `/api/v1/schedule/*` | `ScheduleService` |
| `NotificationRepository` | `/api/v1/notifications/*` | `NotificationService` |
| `PaymentRepository` | - | 현행 구현 대상 아님. 수강료 입금 상태는 `SubscriptionRepository`/`/api/v1/subscriptions/*` 흐름에서 기록 |

→ 상세 엔드포인트: [api_spec.md](api_spec.md)
→ DB 스키마: [database_schema.md](database_schema.md)
→ 인증 플로우: [auth_flow.md](auth_flow.md)
→ 배포 가이드: [deployment.md](deployment.md)
→ 마이그레이션: [migration_strategy.md](migration_strategy.md)
