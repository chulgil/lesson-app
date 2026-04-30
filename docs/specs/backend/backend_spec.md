# Backend Spec — Lessonaza API

> 작성일: 2026-03-16 | 갱신: 2026-04-28 | 상태: Phase 1 완료, audit 후속 patch 필요
> 갱신 사유: 프론트 80+ 커밋 진척 vs 백엔드 정체. audit 결과 `audit/2026-04-28/SUMMARY.md` 참조.

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
| 노쇼/변경 | no_show_records, request_events, lesson_schedule_changes (legacy) | 노쇼 기록, 레슨 신청 이벤트(SSOT), 일정 변경 요청(deprecated, Phase 4 drop 예정) |
| 연습 | practice_logs | 일별 연습 기록 |

## API 엔드포인트 현황

**총 209개 엔드포인트** (2026-04-28 기준, +55 신규)

### 신규 라우터 (Migration 0002 전후)

| 라우터 | Prefix | 주요 기능 |
|--------|--------|-----------|
| invites | `/api/v1/invites` | 초대 CRUD, 연결 요청/응답, 연결 관리 |
| gamification | `/api/v1/gamification` | 학생 게이미피케이션 조회, 포인트 수여 |
| settings_api | `/api/v1/settings` | 선생님/수강권/제안/알림 설정, 피드백 프리셋, 교육자료 |
| reviews | `/api/v1/reviews` | 리뷰 CRUD, 리뷰 요약 |
| groups | `/api/v1/groups` | 그룹수업 스케줄/예약, 출석, 노쇼 기록 |
| practice_logs | `/api/v1/practice-logs` | 연습 기록 CRUD, 주간/월간 통계 |

### 추가 라우터 (3/16 spec 미반영분)

| 라우터 | Prefix | 주요 기능 |
|--------|--------|-----------|
| ai_notes | `/api/v1/ai-notes` | Whisper STT + GPT 레슨 노트 자동 생성 |
| device_tokens | `/api/v1/device-tokens` | FCM 디바이스 토큰 등록/해지 |
| locations | `/api/v1/locations` | 레슨 장소 CRUD |
| parents | `/api/v1/parents` | 학부모-자녀 관계 |
| profile_images | `/api/v1/profile-images` | 프로필 이미지 업로드 |
| scheduler | `/api/v1/scheduler` | 출석 자동화 스케줄러 (만료 알림 cron 미존재) |

### 라우터별 endpoint 카운트

총 27 라우터 (2026-04-30 +1: `request_events`), 분포는 `audit/2026-04-28/_inventory.md` 참조.

### Plan A SSOT 라우터 (2026-04-30 Phase 3-1)

| 라우터 | Prefix | 주요 기능 |
|--------|--------|-----------|
| request_events | `/api/v1/schedule` | 레슨 신청 이벤트 (chat history) CRUD: `lesson-requests/{id}/events` POST·GET, `request-events/{id}` GET·PATCH. 27 event_type × 2 schedule_change_type. 프론트 Hive `RequestEvent` (typeId 131) 와 1:1 매핑. |

## 아키텍처

```
app/
├── api/v1/          # 26개 라우터 (엔드포인트 정의, 209 endpoints)
├── services/        # 18개 서비스 (비즈니스 로직)
├── models/          # 23개 모델 파일 (64+ 테이블, alembic 0006+ 추가분)
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

## 다음 단계 (2026-04-28 audit 우선순위 반영)

### P0 — 즉시 차단 갭 (audit SUMMARY §3)

1. [ ] **Schedule** `get_available_slots` → ScheduleException + booking overlap + travel_time 통합
2. [x] **Schedule/Lesson** `request_events` 테이블 신설 + `lesson_schedule_changes` 정리 (RequestEvent SSOT) — 2026-04-30 Phase 3-1 완료. 라우터 4개(`POST/GET/PATCH /api/v1/schedule/{lesson-requests/{id}/events,request-events/{id}}`), 서비스, 마이그레이션 `add_request_events` + `backup_lsc_legacy` 적용. Phase 4 에서 `lesson_schedule_changes` 제거 예정 (>= 2026-05-14).
3. [ ] **Lesson** `BookingStatus`/`NoShowPolicy` enum 정렬 (alembic 마이그레이션)
4. [ ] **Subscription** `subscription_expiry_service` cron + `Subscription.status` 자동 전이

### P1 — 기능 차단 갭 (audit SUMMARY §4)

5. [ ] `LessonScheduleChange` HTTP 라우터 연결
6. [ ] `LessonService.create()` pieces 무시 버그 수정
7. [ ] `MakeupLesson` endpoint 신설 + `scheduled_lesson_id` 컬럼 추가
8. [ ] `ScheduleConfirmationCard` endpoint 신설
9. [ ] `GET /students/summary` 신설 (RosterSummary 카운트 집계)
10. [ ] Phase 5b 4-axis 토글 ↔ subscription_settings 컬럼 정렬

### 인프라 (audit SUMMARY §6)

11. [ ] Frontend Remote Repository 연결 (Mock → Remote 전환)
12. [ ] Supabase Auth 실제 연동 테스트
13. [ ] Redis 캐시 레이어 추가
14. [ ] docker-compose 에 cron 컨테이너 추가 (scheduler 확장)
15. [ ] Analytics 라우터 추가 (집계 쿼리)

> 상세 갭 + 권장 조치 + 후속 plan 분기는 `audit/2026-04-28/SUMMARY.md` 참조.
