# Backend Spec — Lessonaza API

> 작성일: 2026-03-16 | 업데이트: 2026-05-05 | 상태: Phase 1 완료 + 아키텍처 가드레일 보강

## 개요

FastAPI + PostgreSQL + 자체 JWT/OAuth 기반 백엔드 API.

| 항목 | 값 |
|------|-----|
| Framework | FastAPI 0.115+ (async) |
| ORM | SQLAlchemy 2.0 (asyncpg) |
| DB | PostgreSQL 17 |
| Auth | 자체 JWT + Google/Kakao/Apple OAuth + dev-login |
| Storage | Vultr Object Storage (S3-compatible) |
| Cache | Redis (planned) |
| Python | 3.12+ |
| Package | UV |

## 테이블 현황

**총 64개 테이블** (기존 43 + 신규 21)

### 기존 테이블 (43개, Migration 0001)

| 그룹 | 테이블 | 수 |
|------|--------|:--:|
| 사용자 | users, oauth_accounts, token_blacklist | 3 |
| 선생님 | teachers, teacher_educations, teacher_careers, teacher_certificates | 4 |
| 학생 | students | 1 |
| 레슨 | lesson_classes, class_memberships, lesson_locations, lessons, lesson_pieces, lesson_recordings | 6 |
| 수강권 | subscriptions, subscription_usages, subscription_templates, subscription_proposals | 4 |
| 결제 | payments, tuition_settings | 2 |
| 연습 | practice_repertoires, practice_sections, daily_practice_statuses, practice_recordings, practice_notes, practice_goals, practice_streaks, practice_items | 8 |
| 관계 | teacher_student_relations, follows | 2 |
| 스케줄 | teacher_availabilities, availability_time_slots, lesson_bookings, lesson_requests, group_classes | 5 |
| 알림 | notifications | 1 |
| 학부모 | parents, parent_child_relations, parent_teacher_connections | 3 |
| 정책 | lesson_policies, makeup_lessons, schedule_confirmation_cards | 3 |
| i18n | i18n_translations, supported_locales | 2 |
| 팁 | tip_templates | 1 |

### 신규 테이블 (21개, Migration 0002)

| 그룹 | 테이블 | 용도 |
|------|--------|------|
| 초대 | invites, connection_requests, connections | 초대 코드/QR, 연결 요청/수락, 연결 관리 |
| 게이미피케이션 | gamification_points, gamification_badges | 포인트 이력, 뱃지 수여 |
| 설정 | teacher_settings, subscription_settings, proposal_settings | 선생님/수강권/자동제안 설정 |
| 알림 설정 | notification_settings, parent_notification_settings | 관계별/학부모 알림 환경설정 |
| 피드백 | feedback_presets | 피드백 프리셋 관리 |
| 교육자료 | teaching_resources | YouTube/오디오/외부링크 교육자료 |
| 리뷰 | teacher_reviews | 선생님 리뷰/평점 |
| 스케줄 확장 | schedule_exceptions, group_class_schedules, group_class_bookings | 스케줄 예외, 그룹수업 세션/예약 |
| 노쇼/변경 | no_show_records, lesson_schedule_changes | 노쇼 기록, 일정 변경 요청 |
| 연습 | practice_logs | 일별 연습 기록 |

## API 엔드포인트 현황

**총 154개 엔드포인트** (기존 ~100 + 신규 ~54)

### 신규 라우터

| 라우터 | Prefix | 주요 기능 |
|--------|--------|-----------|
| invites | `/api/v1/invites` | 초대 CRUD, 연결 요청/응답, 연결 관리 |
| gamification | `/api/v1/gamification` | 학생 게이미피케이션 조회, 포인트 수여 |
| settings | `/api/v1/settings` | 선생님/수강권/제안/알림 설정, 피드백 프리셋, 교육자료 |
| reviews | `/api/v1/reviews` | 리뷰 CRUD, 리뷰 요약 |
| groups | `/api/v1/groups` | 그룹수업 스케줄/예약, 출석, 노쇼 기록 |
| practice-logs | `/api/v1/practice-logs` | 연습 기록 CRUD, 주간/월간 통계 |

## 아키텍처

```
app/
├── api/v1/          # 37개 라우터 파일
├── services/        # 36개 서비스 파일 (비즈니스 로직)
├── models/          # 28개 모델 파일 (64+ 테이블)
├── schemas/         # 31개 스키마 파일 (Pydantic v2)
├── core/            # config, database, deps, security, i18n, storage
├── jobs/            # 백그라운드 작업 (APScheduler KST 00:05)
├── utils/           # 헬퍼 유틸리티
└── main.py
```

### 패턴

- **Service Layer**: 라우터 → 서비스 → DB. 비즈니스 로직은 서비스에만.
- **FK 컨벤션**: String(36) 기반, ORM relationship() 미사용, 서비스에서 수동 조인
- **UUID PK**: UUIDMixin (String(36), uuid4)
- **Timestamps**: TimestampMixin (created_at, updated_at)
- **Pagination**: PaginatedResponse[T] 제네릭 (page, size, total, pages)

### 아키텍처 가드레일

`backend/tests/test_backend_architecture_contract.py`가 다음 규칙을 자동 검증한다.

- API router는 DB query/mutation을 직접 수행하지 않고 service layer로 위임한다.
- API router는 SQLAlchemy query helper(`select`, `func`, `insert`, `update`, `delete`)를 직접 import하지 않는다.
- lower layer(`models`, `schemas`, `services`)는 `app.api`를 import하지 않는다.
- 현행 수강료 정책상 `/payments/*` 라우터를 만들지 않는다.

새 백엔드 기능은 다음 순서를 따른다.

1. 스펙/프론트 repository 계약 확인
2. 실패하는 계약 테스트 작성
3. service layer 구현
4. router는 schema validation + service 호출만 담당
5. `uv run pytest tests/test_backend_architecture_contract.py -q`로 계층 규칙 검증

## 다음 단계

### ~~우선순위 1: 레슨요청 → 수강권 통합 플로우 (GAP 6건)~~ ✅ 완료 (2026-05-04)

> 상세: [lesson_request_to_subscription_integration.md](lesson_request_to_subscription_integration.md)
> 테스트 6/6 PASS, 회귀 291/291 PASS

### 완료 항목 (2026-05-04 재검증)

| 항목 | 상태 | 비고 |
|------|------|------|
| ScheduleException API | ✅ 완료 | CRUD 4개 엔드포인트 노출 (`/schedule-exceptions`) |
| mypy 파이프라인 | ✅ 연결 | 점진적 strict, 베이스라인 120 에러/30 파일 |
| FCM Push Notification | ✅ 구현됨 | lazy init, 배포 시 `GOOGLE_APPLICATION_CREDENTIALS` 설정만 필요 |
| Subscription Expiry Dispatcher | ✅ 구현+연결 | APScheduler 00:05 KST 매일 실행, advisory lock |
| Auth (JWT + OAuth) | ✅ 완성 | 자체 JWT + Google/Kakao/Apple OAuth 2.0 |
| Backend Architecture Contract | ✅ 연결 | Router 직접 DB 접근 금지, `/payments/*` 금지, lower-layer API import 금지 |

### 알림 API 계약 (2026-05-05)

프론트 `RemoteNotificationRepository`와 백엔드 `/api/v1/notifications`는 다음 계약을 따른다.

| 기능 | 백엔드 기준 |
|------|-------------|
| 목록 | `GET /api/v1/notifications`, 현재 사용자 알림만 페이지네이션으로 반환 |
| 필터 | `is_read=true/false`, `type=<notificationType>` |
| 응답 필드 | `id`, `user_id`, `type`, `priority`, `title`, `body`, `data`, `created_at`, `scheduled_at`, `sent_at`, `read_at`, `is_read`, `is_push`, `is_in_app`, `action_url`, `action_label` |
| 미읽음 판단 | DB `notifications.read_at IS NULL` |
| 붉은 뱃지 | `GET /api/v1/notifications/unread-count`의 `count > 0` |
| 단건 읽음 | `PATCH /api/v1/notifications/{id}/read`, 현재 사용자 소유 알림만 허용, 기존 `read_at` 보존 |
| 전체 읽음 | `PATCH /api/v1/notifications/read-all`, 현재 사용자 미읽음 알림만 갱신 |

### 수강권 입금 상태 API 계약 (2026-05-05)

현행 정책은 앱 내 결제/PG가 아니라 선생님이 앱 밖에서 받은 수강료 입금 상태를 기록하는 것이다. 따라서 `/payments/*` 라우터는 만들지 않고, `Subscription`의 입금 상태 필드를 기준으로 관리한다.

| 기능 | 백엔드 기준 |
|------|-------------|
| 입금대기 목록 | `GET /api/v1/subscriptions?deposit_status=unpaid` |
| 입금 확인 필요 목록 | `GET /api/v1/subscriptions?deposit_status=needsConfirmation` |
| 입금 확인 완료 목록 | `GET /api/v1/subscriptions?deposit_status=confirmed` |
| 입금 상태 요약 | `GET /api/v1/subscriptions/deposits/summary?year=YYYY&month=M` |
| 학생/학부모 입금 알림 | `PATCH /api/v1/subscriptions/{subscription_id}/notify-payment` |
| 선생님 입금 확인 | `PATCH /api/v1/subscriptions/{subscription_id}/confirm-payment` |

상태 판별은 `payment_confirmed`와 `paid_at`만 사용한다. `payment_confirmed=false && paid_at=null`은 `unpaid`, `payment_confirmed=false && paid_at!=null`은 `needsConfirmation`, `payment_confirmed=true`는 `confirmed`이다.

### 선생님 공지 시스템 API 계약 (2026-05-07, v3)

> 상세 스펙: [bulk_teacher_actions_spec.md](../student/bulk_teacher_actions_spec.md) §4

| 기능 | 엔드포인트 | 설명 |
|------|-----------|------|
| 공지 생성 | `POST /api/v1/announcements` | 휴강/일반 공지 → 전체 활성 학생 알림 + 휴강일 마킹 |
| 공지 목록 | `GET /api/v1/announcements` | 선생님의 공지 목록 |
| 휴강일 조회 | `GET /api/v1/announcements/day-offs` | 기간별 휴강일 목록 (스케줄 표시용) |

**공지 생성 요청/응답:**
- Request: `{ teacher_id, type("dayOff"|"general"), dates?[], message }`
- Response: `{ id, notified_count, affected_lessons[{student_id, student_name, instrument, start_time, session_number}] }`
- 휴강 타입: 해당 날짜에 수업 있는 학생 목록을 `affected_lessons`로 반환 (레슨 자동 취소 안 함)
- 일반 타입: 전체 활성 학생에게 알림만

**v3 변경: v2의 `POST /lessons/bulk-cancel`은 제거됨. 공지와 레슨 취소가 분리됨.**

### 주소 검색 API 계약 (2026-05-07)

> 상세 스펙: [lesson_location_management_spec.md](../schedule/lesson_location_management_spec.md) §16

프론트엔드는 외부 주소 API(카카오/구글)를 **직접 호출하지 않는다**. 우리 서버가 외부 API를 래핑하여 프론트에게 통일된 응답을 제공한다. 백엔드에서 외부 API 키를 관리하므로 프론트에 키 노출 없음.

| 기능 | 엔드포인트 | 설명 |
|------|-----------|------|
| 주소 검색 | `GET /api/v1/address/search` | 키워드 기반 주소 검색 (도로명/지번) |
| 좌표 → 주소 | `GET /api/v1/address/reverse-geocode` | 좌표 기반 주소 조회 (향후) |

**주소 검색 요청/응답:**
- Request: `GET /api/v1/address/search?query=역삼동+123&page=1&size=10`
- Response:
```json
{
  "results": [
    {
      "postal_code": "06241",
      "address": "서울특별시 강남구 역삼동 123-45",
      "road_address": "서울특별시 강남구 테헤란로 123",
      "district": "강남구 역삼동",
      "latitude": 37.5012,
      "longitude": 127.0396
    }
  ],
  "total_count": 1,
  "page": 1
}
```

**백엔드 아키텍처 (의존성 주입):**
```
[Frontend]
    │
    └── GET /api/v1/address/search?query=...
              │
[Backend: AddressRouter]
    │
    └── AddressService.search(query)
              │
    ┌─── AddressProvider (interface) ───┐
    │                                   │
    ├── KakaoAddressProvider (한국 기본)  │  ← KAKAO_REST_API_KEY 환경변수
    ├── NaverAddressProvider (한국 대안)  │  ← NAVER_CLIENT_ID/SECRET
    └── GoogleAddressProvider (글로벌)   │  ← GOOGLE_MAPS_API_KEY
```

- `AddressProvider`: 추상 인터페이스 (`search(query) → List<AddressResult>`)
- 환경변수로 활성 provider 선택: `ADDRESS_PROVIDER=kakao` (기본)
- 한 provider 실패 시 다음 provider로 fallback (kakao → google)
- API 키는 `.env`에서 관리, 프론트에 노출 안 함

**환경변수:**
```
ADDRESS_PROVIDER=kakao          # kakao | naver | google
KAKAO_REST_API_KEY=xxx          # 카카오 REST API 키
NAVER_CLIENT_ID=xxx             # 네이버 Client ID (대안)
NAVER_CLIENT_SECRET=xxx         # 네이버 Client Secret
GOOGLE_MAPS_API_KEY=xxx         # 구글 Maps API 키 (글로벌)
```

### 이동시간 자동 측정 API 계약 (2026-05-07)

> 상세 스펙: [lesson_location_management_spec.md](../schedule/lesson_location_management_spec.md) §12

| 기능 | 엔드포인트 | 설명 |
|------|-----------|------|
| 이동시간 추정 | `GET /api/v1/travel-time/estimate` | 출발지-도착지 주소 기반 이동시간 자동 측정 |

**요청:** `?origin_address=서울시+강남구+역삼동&destination_address=서울시+서초구+반포동`
**응답:** `{ estimated_minutes: 25, source: "kakao", distance_km: 8.3 }`
**실패 시:** `{ estimated_minutes: null, source: "unavailable", distance_km: null }` (200 OK, 에러 아님)

**백엔드 아키텍처 (주소 검색과 동일 의존성 주입 패턴):**
```
[Frontend]
    │
    └── GET /api/v1/travel-time/estimate?...
              │
[Backend: TravelTimeRouter]
    │
    └── TravelTimeService.estimate(origin, destination)
              │
    ┌─── DirectionsProvider (interface) ───┐
    │                                      │
    ├── KakaoDirectionsProvider (한국 기본)  │  ← KAKAO_REST_API_KEY
    ├── NaverDirectionsProvider (한국 대안)  │  ← NAVER_CLIENT_ID/SECRET
    └── GoogleDirectionsProvider (글로벌)   │  ← GOOGLE_MAPS_API_KEY
```

**처리 로직:**
1. 캐시 확인 (동일 출발지-도착지, 24시간 유효)
2. 활성 DirectionsProvider로 호출 (환경변수 `DIRECTIONS_PROVIDER=kakao`)
3. 실패 시 → fallback chain (kakao → google)
4. 모두 실패 → `estimated_minutes: null` 반환 (200 OK, 에러 아님)
5. 5분 단위 올림 (23분 → 25분)

**환경변수 (주소 검색과 동일 키 공유):**
```
DIRECTIONS_PROVIDER=kakao       # kakao | naver | google
# KAKAO_REST_API_KEY 하나로 주소 검색 + 길찾기 모두 가능
# 별도 키 불필요 (카카오 REST API 키 = 통합 키)
```

> 주소 검색(`AddressProvider`) + 이동시간(`DirectionsProvider`)은 **동일 외부 API 키**를 공유.
> 카카오 REST API 키 1개로 주소 검색(Local API) + 길찾기(Mobility API) 모두 호출 가능.

### 향후 항목

1. [ ] Frontend Remote Repository 연결 (Mock → Remote 전환) — 프론트엔드 작업
2. [ ] mypy 에러 점진 해소 (120개 → 0) — 품질
3. [ ] Analytics 라우터 추가 (집계 쿼리) — MVP 이후
4. [ ] Redis 캐시 레이어 — 트래픽 증가 시

## 결제 경계 정책 (CRITICAL — 작업 전 필독)

현행 수강료 흐름은 **선생님/학원 ↔ 학생/학부모 무통장입금**이다. 앱은 수강권 제안, 입금 완료 표시, 수강권 확정 상태만 기록한다.

**`payments` 라우터는 현행 구현 대상이 아니다.** `/payments/*`, `payment_service`, 독립 결제 스키마를 새로 만들지 않는다. 수강권 입금 상태는 `/subscriptions/*` 흐름의 `SubscriptionProposal` / `Subscription` 상태로 처리한다.

| 구분 | 상태 |
|------|------|
| 선생님/학원 수강료 | **앱 밖 무통장입금 / 현금 등 외부 결제** |
| 현행 백엔드 API | **`/subscriptions/*` 중심 상태 기록** |
| `/payments/*` 라우터 | **정의하지 않음 / 구현 금지** |
| PG SDK (Toss / Portone / 카카오페이 / 이니시스) | **미채택** |
| Webhook (PG → 서버) | **없음** |
| 카드 토큰화 / PCI-DSS | **없음** |
| 자동 입금 매칭 | **없음** |
| 영수증 발행 / 정산 / 에스크로 | **없음** |
| 앱관리자 사용료 과금 | **향후 별도 스펙 완료 후 구현** |

**상세 정책**: [`docs/specs/subscription/payment_architecture.md`](../subscription/payment_architecture.md) — 현행 무통장입금 정책 + 미래 앱 사용료 과금 경계 SSOT.

향후 결제가 필요해지는 경우는 Lessonaza 앱관리자가 선생님/학생/학부모/학원에게 사용료를 받는 구조에 한정한다. 이때는 `payment_architecture.md` §3에 따라 별도 앱 사용료 결제 스펙을 먼저 작성하고, 현행 수강권/입금 상태 기록과 물리적으로 분리한다.
