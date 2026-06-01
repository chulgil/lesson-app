# 프론트엔드-백엔드 갭 분석 리포트

> 작성일: 2026-05-09
> 최근 백엔드/프론트 연결 재검토: 2026-06-01

> 최신 상태 반영 주석: 이 문서는 2026-06-01 검증 기준으로 갱신되었습니다.
> 2026-06-01 기준 API 경로 critical/high 즉시 실패 항목은 없음으로 확인됩니다.
> 분석 범위: Frontend Remote Repository ↔ Backend API Router 정합성

---

## Executive Summary

| 항목 | 값 |
|------|-----|
| 분석 대상 | lesson-app 프론트엔드-백엔드 구현 상태 |
| 분석일 | 2026-06-01 |
| 전체 Repository 수 | 40개 |
| Remote 구현 완료 | 35개 (87.5%) |
| Mock-only/정책상 보류 | 5개 (12.5%) |
| 백엔드 API 라우터 | 19개, 120+ 엔드포인트 |
| API 경로 불일치 | 0건 |

### Value Delivered

| 관점 | 내용 |
|------|------|
| **Problem** | 프론트엔드 Remote Repository가 백엔드 API와 실제로 연동 가능한지 불명확 |
| **Solution** | 40개 Repository × 120+ Backend Endpoint 전수 대조 |
| **Function/UX Effect** | API 경로 불일치 없음, 백엔드 API가 있는 주요 mock fallback provider를 Remote로 연결 |
| **Core Value** | 베타 출시 전 Remote 전환 시 런타임 에러 사전 방지 |

---

## 1. 백엔드 인프라 상태

| 항목 | 상태 | 상세 |
|------|:----:|------|
| FastAPI 앱 | ✅ | `main.py` + lifespan, CORS, 예외핸들러 |
| Docker 배포 | ✅ | docker-compose (dev/beta/prod) 3벌 |
| DB 모델 | ✅ | 65개 테이블, PostgreSQL 17 |
| Alembic 마이그레이션 | ✅ | 4개 마이그레이션 (체인 정상) |
| Pydantic 스키마 | ✅ | 133개 클래스 |
| 서비스 레이어 | ✅ | 19개 서비스 (라우터 1:1 매핑) |
| API 라우터 | ✅ | 19개, 120+ 엔드포인트 |
| 테스트 | ✅ | 21개 테스트 파일 + 시나리오 프레임워크 |
| 환경 설정 | ✅ | `.env.example`은 PostgreSQL 기준으로 정리됨 |

**결론: 백엔드는 구조적으로 완성되어 있음. 실행 가능한 상태.**

---

## 2. Repository 구현 상태 매트릭스

### 2-1. Remote 구현 완료 (34개) — `USE_MOCK=false` 시 Remote 동작

| # | 도메인 | Repository | Mock | Remote | 비고 |
|---|--------|-----------|:----:|:------:|------|
| 1 | Auth | AuthRepository | — | ✅ | OAuth, JWT refresh |
| 2 | Students | StudentRepository | ✅ | ✅ | CRUD + status |
| 3 | Lessons | LessonRepository | ✅ | ✅ | CRUD + status |
| 4 | Lessons | FeedbackPresetRepository | ✅ | ✅ | settings 경로 |
| 5 | Lessons | TeachingResourceRepository | ✅ | ✅ | settings 경로. tags는 `teaching_resource_tags`로 정규화 |
| 6 | Practice | PracticeRepository | ✅ | ✅ | — |
| 7 | Practice | PracticeGoalRepository | ✅ | ✅ | |
| 8 | Practice | PracticeStatsRepository | ✅ | ✅ | |
| 9 | Practice | RecordingRepository | ✅ | ✅ | multipart upload. 목록은 `section_id`와 `repertoire_id` 필터를 모두 지원하고 `server_url`, `recorded_at`, `storage_status`, `type` alias를 제공 |
| 10 | Subscription | SubscriptionRepository | ✅ | ✅ | |
| 11 | Subscription | SubscriptionProposalRepository | ✅ | ✅ | |
| 12 | Subscription | SubscriptionTemplateRepository | ✅ | ✅ | |
| 13 | Subscription | ProposalSettingsRepository | ✅ | ✅ | |
| 14 | Schedule | TeacherAvailabilityRepository | ✅ | ✅ | |
| 15 | Schedule | BookingRepository | ✅ | ✅ | |
| 16 | Schedule | LessonRequestRepository | ✅ | ✅ | |
| 17 | Schedule | GroupClassBookingRepository | ✅ | ✅ | — |
| 18 | Notification | NotificationRepository | — | ✅ | mock시 null 반환 |
| 19 | Relationship | TeacherStudentRelationRepository | ✅ | ✅ | `GET /relationships?teacher_id=&student_id=&status=&is_manually_registered=` 서버 필터로 teacher/student/status/manual 목록과 pair lookup 대체 가능 |
| 20 | Follow | FollowRepository | ✅ | ✅ | |
| 21 | Parent | ParentRepository | ✅ | ✅ | |
| 22 | Gamification | GamificationRepository | ✅ | ✅ | |
| 23 | Onboarding | TeacherProfileRepository | ✅ | ✅ | |
| 24 | Search | TeacherRepository | ✅ | ✅ | |
| 25 | Search | TeacherSearchRepository | ✅ | ✅ | |
| 26 | Settings | SettingsRepository | ✅ | ✅ | |
| 27 | Student | LocationRepository | ✅ | ✅ | `/locations` CRUD/list/default/deactivate/reactivate 지원. class-scoped location은 `LessonClass.teacher_id` 소유권을 검증 |
| 28 | Practice | RecordingFeedbackRepository | ✅ | ✅ | `/recordings/{recording_id}/feedback` CRUD. `RecordingFeedbackList` provider가 repository를 통해 원격 조회/작성 |
| 29 | Practice | PracticeItemRepository | ✅ | ✅ | `/practice/items` CRUD/filter/action API 연결 |
| 30 | Practice | PracticeNoteRepository | ✅ | ✅ | `/practice/sections/{section_id}/notes`, `/practice/notes/{note_id}` 연결 |
| 31 | Schedule | ScheduleConfirmationCardRepository | ✅ | ✅ | `/schedule/confirmation-cards` 목록/생성/상태 변경 연결 |
| 32 | Parent | ChildProfileRepository | ✅ | ✅ | `/parents/*/child-profiles` CRUD와 teacher connect/disconnect 연결 |
| 33 | Student | TeacherAnnouncementRepository | ✅ | ✅ | `/announcements`, `/announcements/day-offs` 연결. update/delete는 백엔드 API 부재로 미지원 |
| 34 | Lesson | TipTemplateRepository | ✅ | ✅ | `/settings/tip-templates` CRUD/usage 연결 |
| 35 | Lesson | FeedbackTemplateRepository | ✅ | ✅ | `/settings/feedback-templates` CRUD/usage 연결 |

### 2-2. Mock-only 또는 정책상 Remote 보류

| # | 도메인 | Repository | 백엔드 API | 긴급도 | 비고 |
|---|--------|-----------|:----------:|:------:|------|
| 27 | Payment | PaymentRepository | ❌ | LOW | "No remote API yet" |
| 28 | Piece | PieceRepository | ❌ | LOW | "No remote API yet" |
| 29 | Practice | PracticeRepertoireRepository | ✅ 있음 | MEDIUM | `/practice/repertoires`, `/practice/sections` API는 있으나 Hive 녹음 파일 관리와 섹션 동기화 경계가 남아 별도 전환 필요 |
| 40 | Subscription | SubscriptionSettingsRepository | ✅ 있음 | LOW | 백엔드 `/subscription-settings` flat CRUD와 frontend remote class 존재. Provider 미연결 상태이며, write는 현재 teacher profile 소유권으로 제한 |

### 2-3. 2026-05-06 백엔드 mock replacement 재검토

프론트 mock을 전면 대체하려면 백엔드는 화면 전용 API보다 재사용 가능한 도메인 API를 제공해야 한다. 현재 기준 핵심 원칙은 다음과 같다.

| 원칙 | 백엔드 API 기준 |
|------|----------------|
| 선생님 개인 라이브러리 | `/settings/*` 아래 teacher-scoped CRUD로 제공한다. 예: feedback presets, teaching resources, tip templates |
| 수강권 회차별 상태 | `/subscriptions/{subscription_id}/events`를 SSOT로 사용하고, 목록/배지는 `/subscriptions/schedule-change-events/pending`으로 제공한다 |
| 수강료/결제 | 앱 내 PG 결제가 아니라 선생님이 확인하는 무통장입금 상태값이므로 `/subscriptions/*`의 deposit/payment state API로 제공한다 |
| 연습/곡/레퍼토리 | student-scoped library + section/note/recording API로 제공한다. 화면별 mock shape가 아니라 `student_id`, `repertoire_id`, `section_id`를 기준으로 재사용한다 |

이번 재검토에서 추가된 백엔드 API:

| Repository | 추가 API | 남은 작업 |
|------------|----------|-----------|
| TipTemplateRepository | `GET /settings/tip-templates`, `POST /settings/tip-templates`, `GET /settings/tip-templates/{id}`, `PUT /settings/tip-templates/{id}`, `PATCH /settings/tip-templates/{id}/usage`, `DELETE /settings/tip-templates/{id}` | 완료: 프론트 `RemoteTipTemplateRepository` 추가 및 provider 연결 |
| FeedbackTemplateRepository | `GET /settings/feedback-templates`, `POST /settings/feedback-templates`, `GET /settings/feedback-templates/{id}`, `PUT /settings/feedback-templates/{id}`, `PATCH /settings/feedback-templates/{id}/usage`, `DELETE /settings/feedback-templates/{id}` | 완료: 프론트 `RemoteFeedbackTemplateRepository` 추가 및 provider 연결 |
| TeachingResourceRepository | `GET /settings/teaching-resources?tag=&query=`, `POST /settings/teaching-resources`, `GET /settings/teaching-resources/{id}`, `PUT /settings/teaching-resources/{id}`, `DELETE /settings/teaching-resources/{id}` | 프론트 remote repository의 `getByIds`는 아직 전체 목록 조회 후 client-side filter. 필요 시 batch endpoint 추가 |
| PracticeItemRepository | `GET /practice/items?lesson_id=&student_id=&date_from=&date_to=`, `GET /practice/items/incomplete`, `GET /practice/items/awaiting-feedback`, `POST /practice/items`, `GET /practice/items/{id}`, `PUT /practice/items/{id}`, `DELETE /practice/items/{id}`, `PATCH /practice/items/{id}/complete`, `PATCH /practice/items/{id}/like`, `PATCH /practice/items/{id}/practice-count/increment`, `PATCH /practice/items/{id}/practice-count/decrement` | 완료: 프론트 `RemotePracticeItemRepository` 추가 및 provider 연결 |
| RecordingFeedback provider | `GET /recordings/{recording_id}/feedback`, `POST /recordings/{recording_id}/feedback`, `PUT /recordings/{recording_id}/feedback/{feedback_id}`, `DELETE /recordings/{recording_id}/feedback/{feedback_id}` | 완료. 프론트 `RecordingFeedbackList`가 `RecordingFeedbackRepository`를 통해 remote/mock 모드를 전환한다. 응답 필드는 `id`, `recordingId`, `teacherId`, `content`, `createdAt` |
| Parent membership/class reads | `GET /memberships?student_id={linkedChildId}`, `GET /lessons-classes/{classId}` | 학부모 결제/수강권 화면이 자녀 subscription API와 같은 권한 모델로 membership/class read를 재사용 가능. mutation은 teacher-only 유지 |
| FollowRepository filtered lookup | `GET /follows?follower_id=&following_id=&target_type=&direction=following|followers` | 프론트 `RemoteFollowRepository`가 전체 목록 조회 후 client-side filter/count 하던 흐름을 서버 필터로 대체 가능 |
| TeacherStudentRelationRepository filtered lookup | `GET /relationships?teacher_id=&student_id=&status=&is_manually_registered=` | 프론트 `RemoteTeacherStudentRelationRepository`와 mock repository의 teacher/student/status/manual 필터 및 teacher-student pair lookup을 서버 필터로 대체 가능 |
| RequestEvent cancellation parity | `lessonCancellationConfirmed`, `cancellationCreditRefunded` event type 저장 지원 | 프론트 schedule/subscription event enum 29개와 백엔드 PostgreSQL enum을 정렬 |
| ScheduleConfirmationCardRepository | `GET/POST/PATCH /schedule/confirmation-cards*` 응답에 `teacher_name`, `suggested_day`, `suggested_time`, `lesson_duration`, `suggested_day2/3`, `suggested_time2/3` 제공. 기존 `suggestedDay*`/`lessonDuration` alias 유지 | 완료: 프론트 `RemoteScheduleConfirmationCardRepository` 추가 및 provider 연결 |
| Subscription session events | `GET /subscriptions/schedule-change-events/pending`, 기존 `GET/POST /subscriptions/{id}/events` | 프론트 `subscriptionSessionEventsProvider`, `pendingScheduleChangeRequestsProvider` remote 연결 |
| Analytics monthly trend | 기존 `GET /analytics/monthly-stats?month=YYYY-MM`의 `lesson_trend`를 선택 월 포함 6개월 월별 배열로 확장 | 프론트 `RemoteAnalyticsRepository`가 mock의 6개월 trend chart를 백엔드 응답으로 대체 가능. 기존 `test_contract.py` 일부 기대값은 단일 월/빈 배열 기준이라 갱신 필요 |

다음 우선순위:

1. `PracticeRepertoireRepository`: Hive 녹음 파일 관리와 서버 section/repertoire API의 동기화 경계를 정한다.
2. `PieceRepository`: `practice_pieces`, `student_practice_pieces` 기반 API는 일부 있지만 프론트 계약 전체를 대체하려면 library CRUD/search + student repertoire assignment/progress API를 하나로 정렬해야 한다.
3. `PaymentRepository`: 앱 내 결제가 아니므로 별도 PG API가 아니라 `/subscriptions` 입금 상태와 사용 이력으로 대체할지, legacy repository를 제거할지 결정해야 한다.

정규화 판단:

| 영역 | 판단 |
|------|------|
| `FeedbackTemplate.tags` | JSON 배열 저장 대신 `feedback_template_tags(template_id, tag)`로 정규화. 태그 검색/필터와 `(template_id, tag)` 중복 방지에 필요 |
| `TipTemplate.instrument` | 단일 nullable scope라 별도 테이블 불필요. 다중 악기 지원이 필요해질 때 `tip_template_instruments`로 분리 |
| `TeachingResource.tags` | JSON 배열 저장 대신 `teaching_resource_tags(resource_id, tag)`로 정규화. 교수 자료 라이브러리는 tag/query 필터가 필요한 반복 metadata이고 `(resource_id, tag)` 중복 방지가 필요 |
| `PracticeItem.resourceIds` | JSON 배열 저장 대신 `practice_item_resources(item_id, resource_id)`로 정규화. 연습 항목과 교수 자료는 다대다 관계이고 삭제 cascade/중복 방지가 필요 |
| `RecordingFeedback` | `recording_feedbacks(recording_id, teacher_id, content)` 테이블로 분리. `practice_recordings.id` 기준 재사용 CRUD를 제공하고, 작성자는 teacher profile id로 저장한다 |
| Redis / GraphDB | PostgreSQL 17을 SSOT로 유지. Redis는 TTL 캐시/락/큐에만 사용 후보. GraphDB는 현재 관계 깊이에서 불필요하며 PostgreSQL FK/인덱스/recursive CTE 우선 |

---

## 3. API 경로 검증 (CRITICAL/High)

### 3-1. Practice Logs/그룹 예약/수강권 운영 API

현재 상태: **문제 항목 없음(해결 완료)**

| 도메인 | 상태 | 비고 |
|--------|:----:|------|
| Practice Logs | ✅ | 계약 경로 정렬 완료 (`/practice-logs`) |
| Group Booking | ✅ | 계약 경로 정렬 완료 (`/groups/...`) |
| Subscription 운영 | ✅ | `use-reschedule`, `status`, `usage` GET/POST, 필터 query 제공 |

**근거 테스트**: `backend/tests/test_frontend_remote_gap_contract.py`, `backend/tests/test_schedule.py`  
**요약**: API 경로 미스매치로 인한 Remote 즉시 실패 이슈는 현재 없음.

---

## 4. 백엔드에만 존재하는 엔드포인트 (프론트 미사용)

| 백엔드 라우터 | 엔드포인트 | 프론트엔드 Remote |
|-------------|-----------|:---------------:|
| users.py | `/users/me`, `/users/me/role`, `/users/me/locale`, `/users/me/onboarding-complete` | ❌ |
| teachers.py | `/teachers/{id}/students`, `/teachers/{id}/dashboard`, `/teachers/me/dashboard`, `GET /teachers/public/{id}` | ❌ (공개 프로필 API — 인증 불필요, 민감정보 제외) |
| students.py | `/students/{id}/stats`, `/students/me/profile` | ❌ |
| lessons.py | `/lessons/upcoming`, `/lessons/recent`, `/lessons/{id}/feedback` | ❌ |
| practice.py | `/practice/repertoires/*`, `/practice/sections/*` | ⚠️ (일부는 PracticeNote Remote가 사용, Repertoire는 별도 전환 필요) |
| schedule.py | `/schedule/weekly` | ❌ |
| bookings.py | `/bookings/makeup`, `/bookings/{id}/change-request` | ❌ |
| reviews.py | 전체 (`/reviews/*`) | ❌ |
| invites.py | 전체 (`/invites/*`) | ✅ (RemoteInviteRepository 연결) |
| groups.py | 전체 (`/groups/*`) | ⚠️ (일부 경로는 프론트 계약 미사용) |
| settings.py | `/settings/subscription`, `/settings/notification/{target_user_id}` | ❌ |

---

## 5. 우선순위별 액션 플랜

### P0: 즉시 수정 (Remote 전환 시 크래시) — ✅ 완료 (2026-03-19)

| # | 작업 | 상태 | 수정 내용 |
|---|------|:----:|----------|
| 1 | Practice Logs 경로 통일 | ✅ | `/practice/logs` → `/practice-logs` (9곳), `/practice/weekly` → `/practice-logs/weekly` |
| 2 | Group Booking 경로 통일 | ✅ | `/schedule/group-bookings` → `/groups/bookings` (13곳) + `getBookingsForSchedule` → `/groups/schedules/{id}/bookings` |
| 3 | Subscription 누락 엔드포인트 | ✅ | `use-reschedule`, `status`, `usage` (GET/POST) 4개 엔드포인트 + 서비스 + 스키마 추가 |
| 4 | Group Booking 누락 엔드포인트 | ✅ | `list`, `get`, `promote`, `auto-cancel-waitlist`, `batch-attendance`, `deduct` 6개 엔드포인트 추가 |

### P1: 베타 출시 전 필수

| # | 작업 | 비고 |
|---|------|------|
| 4 | PracticeRepertoireRepository Remote 전환 설계 | 백엔드 `/practice/repertoires`는 있으나 Hive 녹음/섹션 동기화 경계 확정 필요 |
| 5 | PieceRepository Remote 전환 설계 | 백엔드 `/practice/pieces`와 프론트 화면 계약 정렬 필요 |

### P2: 베타 이후

| # | 작업 | 비고 |
|---|------|------|
| 9 | PaymentRepository Remote 구현 | 앱 결제 표면이 아니라 선생님 수동 입금 상태 관리로 유지. 별도 PG API는 보류 |
| 10 | ScheduleConfirmationCardRepository Remote 구현 | 완료 |
| 11 | PracticeNoteRepository 통합 | 완료 |
| 12 | LocationRepository Remote 검증 | 레슨 장소 관리는 `/locations`로 지원. 프론트 synthetic location id(`student_home_*`, `academy_default` 등)는 실제 location lookup 또는 membership location 선택 UI로 정리 필요 |
| 13 | SubscriptionSettingsRepository Provider 연결 또는 삭제 | 백엔드 API와 remote class는 존재. Provider 미연결 상태 해소 |
| 14 | `.env.example` PostgreSQL 정합성 점검 | 완료 |

---

## 6. 검증 수치

```
총 Repository:            40개
Remote 구현 완료:          35개 (87.5%)
Mock-only/정책상 보류:      5개 (12.5%)
API 경로 일치:             35/35 Remote (100%)
API 경로 불일치:            0건
백엔드 전용 엔드포인트:     ~30개 (프론트 미사용)
Provider 미연결 Repository: SubscriptionSettings, PracticeRepertoire, Piece, Payment 등 정책/설계 보류 항목
```

---

## 7. 결론

**백엔드는 구조적으로 완성 (19 라우터, 120+ 엔드포인트, 65 DB 모델)**이며, 프론트엔드 주요 Remote Repository는 35개까지 연결되어 **87.5% 전환 완료** 상태입니다.

현재는 경로 불일치로 인한 `Remote` 전환 차단은 없음.  
잔여 과제는 결제 정책 정리와 PracticeRepertoire/Piece의 동기화 경계 설계입니다.
