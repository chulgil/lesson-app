# Backend Architecture Guardrails (Backend)

> 기준일: 2026-05-07

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

## 신규 계약 완료 상태 (요약)

- `POST /api/v1/notifications/broadcast`
- `POST /api/v1/lessons/bulk-cancel`
- `POST /api/v1/announcements` (+ 목록/휴강일 조회)
- `/api/v1/schedule/confirmation-cards` 계열 정렬
- 부모 자녀 프로필 API
- 연습 리퍼토리/노트/녹음 계약 엔드포인트

## 외부 저장소/캐시

- Redis: 현재 캐시/락 계층 후보. 기본 운영 의존성은 아님.
- Graph DB(예: pg_graph, Neo4j): 본 스펙에서는 도입하지 않음.
