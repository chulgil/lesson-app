# Backend Spec — Lessonaza API

> 작성일: 2026-03-16 | 상태: Phase 1 완료

## 개요

FastAPI + PostgreSQL + Supabase Auth 기반 백엔드 API.

| 항목 | 값 |
|------|-----|
| Framework | FastAPI 0.115+ (async) |
| ORM | SQLAlchemy 2.0 (asyncpg) |
| DB | PostgreSQL 17 |
| Auth | Supabase Auth (Google/Kakao/Apple OAuth) |
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
├── api/v1/          # 19개 라우터 (엔드포인트 정의)
├── services/        # 18개 서비스 (비즈니스 로직)
├── models/          # 14개 모델 파일 (64 테이블)
├── schemas/         # 17개 스키마 파일 (Pydantic v2)
├── core/            # config, database, deps, security, i18n, storage
└── main.py
```

### 패턴

- **Service Layer**: 라우터 → 서비스 → DB. 비즈니스 로직은 서비스에만.
- **FK 컨벤션**: String(36) 기반, ORM relationship() 미사용, 서비스에서 수동 조인
- **UUID PK**: UUIDMixin (String(36), uuid4)
- **Timestamps**: TimestampMixin (created_at, updated_at)
- **Pagination**: PaginatedResponse[T] 제네릭 (page, size, total, pages)

## 다음 단계

1. [ ] 기존 schedule 라우터의 exception 스텁을 새 ScheduleException 모델로 연결
2. [ ] Analytics 라우터 추가 (집계 쿼리)
3. [ ] Frontend Remote Repository 연결 (Mock → Remote 전환)
4. [ ] Supabase Auth 실제 연동 테스트
5. [ ] Redis 캐시 레이어 추가
6. [ ] FCM Push Notification 연동
7. [ ] Subscription Expiry Dispatcher 스케줄러 진입점 연결 (D-7/D-1 알림, 만료 30일 후 expired→past 자동 전환)

## 결제 라우터 정책 (CRITICAL — 작업 전 필독)

**`payments` 라우터는 PG 연동 미진행이 정책상 의도된 상태**. 수동 입금확인 워크플로우만 제공한다.

| 구분 | 상태 |
|------|------|
| PG SDK (Toss / Portone / 카카오페이 / 이니시스) | **미채택** |
| Webhook (PG → 서버) | **없음** |
| 카드 토큰화 / PCI-DSS | **없음** |
| 자동 입금 매칭 | **없음** |
| 영수증 발행 / 정산 / 에스크로 | **없음** |
| 수동 워크플로우 API (student-confirm / teacher-confirm / teacher-reject / refund / overdue / remind) | **유지** |

**상세 정책**: [`docs/specs/subscription/payment_architecture.md`](../subscription/payment_architecture.md) — 현행 정책 + 미래 PG 도입 시 양방향 정산 설계 요건 SSOT.

PG 도입을 결정하면 [`payment_architecture.md`](../subscription/payment_architecture.md) §3 "미래 — PG 도입 시 신규 설계 요건"의 미정 항목(정산 주기 / 수수료 모델 / 사업자 구분 / 환불 흐름 / 에스크로 / PG 선택)을 먼저 답한 뒤 별도 Phase 로 진행.
