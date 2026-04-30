# Backend Endpoint Inventory Snapshot

> 생성: 2026-04-28
> 출처: `grep -cE '@router\.(get|post|put|patch|delete)' backend/app/api/v1/*.py`

## 라우터별 endpoint 수

| Router | Endpoints |
|--------|----------:|
| ai_notes | 2 |
| auth | 6 |
| bookings | 9 |
| device_tokens | 2 |
| gamification | 2 |
| groups | 15 |
| invites | 8 |
| lesson_requests | 10 |
| **lessons** | **20** |
| locations | 7 |
| notifications | 4 |
| parents | 6 |
| payments | 3 |
| practice | 15 |
| practice_logs | 8 |
| profile_images | 2 |
| recordings | 7 |
| relationships | 7 |
| reviews | 5 |
| schedule | 7 |
| scheduler | 4 |
| settings_api | 16 |
| **students** | **10** |
| **subscriptions** | **18** |
| teachers | 10 |
| users | 6 |
| **합계** | **209** |

## 모델·테이블 (backend/app/models/*.py)

base, device_token, gamification, i18n, invite, lesson, notification,
parent, payment, policy, practice, practice_log, recording, relationship,
review, schedule, schedule_ext, settings, student, subscription, teacher,
tip, user (총 23 모델 파일)

## SSOT 비교 — backend_spec.md (3/16 기준)

| 항목 | spec | 실제 | 갭 |
|------|------|------|----|
| Endpoints | 154 | **209** | +55 |
| 라우터 | 19 | 26 | +7 |
| 테이블 | 64 | TBD (alembic 추적) | TBD |

→ **결론**: backend_spec.md 자체가 stale. Phase 2에서 갱신 필요.

## 마이그레이션 (alembic versions/)

`20260316_0000_0002_add_missing_tables.py` 이후로:
- `0003_timestamp_to_timestamptz`
- `0004_add_onboarding_completed`
- `0005_frontend_backend_alignment`
- `0006_add_background_image_fields`
- `d91e939737d0_add_bank_accounts_column_to_teachers`
- `e34fbc3ccb63_frontend_backend_schema_alignment_phase2`
- `20260404_1100_add_reschedule_deadline_hours`

→ 7건 추가 마이그레이션 (3/16 spec 미반영)

## 점검 우선순위 매핑

| Phase | 도메인 | 라우터 | 모델 | 스펙 |
|-------|--------|--------|------|------|
| 1A | Schedule | schedule, bookings, lesson_requests, scheduler | schedule, schedule_ext | schedule_master, schedule_views_ux, chat_guide_message, schedule_confirmation_card, travel_time |
| 1B | Lesson | lessons | lesson | lesson_master §13.2 |
| 1C | Student | students | student | enrollment_management_ux |
| 1D | Subscription | subscriptions, notifications | subscription, notification | (5a/5b in enrollment_management_ux) |
