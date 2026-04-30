# Subscription Domain Audit — 2026-04-28

> Phase 1D · Subscription/Notification 백엔드 점검
> 기준 SSOT: `docs/specs/student/enrollment_management_ux_spec.md` §3.4 + `docs/specs/subscription/*` + 커밋 `11fb106e`(Phase 5a) / `2994b31b`(Phase 5b)

## 1. SSOT 위치

| 영역 | SSOT | 비고 |
|---|---|---|
| 만료 자동 알림 (D-14/D-7/D-1/D-0) | **프론트** `subscription_expiry_notification_service.dart` + `subscription_expiry_reminder_settings.dart` | 백엔드 미구현 — 클라이언트 단독 스케줄러 |
| 만료 알림 사용자 설정 | **프론트 Hive** `subscription_expiry_reminder_settings` 키 | 백엔드 `subscription_settings` 컬럼은 coarse-grained only |
| 수강권 만료/임박 상태 (`expiringSoon`/`expired`) | **백엔드** `Subscription.status` enum | 자동 전이 로직은 부재 (수동 PATCH 만 존재) |
| 수강권 잔여 계산 (`remainingLessons`, `daysUntilExpiration`) | **프론트 derived** | 백엔드는 `total_lessons`/`used_lessons`/`end_date` 만 저장, 산출 필드 없음 |

판정: Phase 5a/5b 는 **클라이언트 전용** 구현. 백엔드는 알림 영속/푸시 기반은 있으나 **수강권 만료 트리거 자체가 없음**.

## 2. 점검 매트릭스

| # | 요구사항 (스펙 §) | 프론트 코드 | 백엔드 endpoint | 백엔드 model | 판정 |
|---|---|---|---|---|---|
| 1 | §3.4 D-14/D-7/D-1/D-0 자동 알림 트리거 | `subscription_expiry_notification_service.dart:38-80` (로컬 스케줄러) | **없음** | — | **MISSING** |
| 2 | §3.4 만료일 도달 시 server-side push (멀티디바이스/앱종료 상태) | — (Local Notification 만 사용) | `notifications.py` (read 만, send 없음) `scheduler.py` (attendance 만) | `Notification` 모델 OK | **MISSING** |
| 3 | §3.4 D-7 push, D-1 push, D-0 push 발송 | client local notification | **없음** | — | **MISSING** |
| 4 | §3.4 master toggle + D-14/D-7/D-1/D-0 개별 토글 영속 | `subscription_expiry_providers.dart` Hive 키 `subscription_expiry_reminder_settings` | **없음** | `subscription_settings.renewal_alert_days` (단일 int) | **FAIL** (coarse vs 4-axis fine) |
| 5 | §3.4 다기기 동기화 | — | **없음** (디바이스 로컬만) | — | **MISSING** |
| 6 | `Subscription.status` 자동 전이 (active → expiringSoon → expired) | — (status enum 정의됨) | `PATCH /subscriptions/{id}/status` 수동만 | `Subscription.status` enum OK | **MISSING** (자동 전이 로직 없음) |
| 7 | `subscription_expiring` 알림 type 발송 | — | seed_data 에는 example 존재, 런타임 발송 코드 없음 | `Notification.type=subscription_expiring` 허용 (free string) | **MISSING** |
| 8 | renewal_alert_threshold(잔여횟수) / renewal_alert_days(D-day) 활용 | — | 컬럼만 존재, 읽는 서비스 없음 | `subscription_settings` 컬럼 정의됨 | **STALE** (컬럼만 있고 미사용) |
| 9 | `SubscriptionRenewalService` (renewal_spec.md §2) 갱신 트리거 | 일부 frontend 로직 | **없음** | — | **MISSING** |
| 10 | 수강권 잔여횟수 계산 (`remainingLessons`) | frontend computed | `total_lessons - used_lessons` 응답에 없음 | model 에 `total_lessons` / `used_lessons` 만 | **FAIL** (서버 응답에 derived 없음, 클라이언트 계산 의존) |
| 11 | `Subscription.amount_paid` / 미수금 추적 | `subscription_master.md` 언급 | 없음 | 없음 | **MISSING** |
| 12 | 통합 cron/scheduler 컨테이너 | — | `scheduler.py` endpoint 만 4개 (attendance 한정). docker-compose 에 cron 컨테이너 없음 | — | **MISSING** |

## 3. 갭 상세

### P0 — 데이터/기능 일관성 차단

**G1. 백엔드 수강권 만료 알림 부재 (스펙 §3.4 정면 위반)**
- 영향: 앱 종료 상태 또는 다른 디바이스에서는 D-7/D-1/D-0 알림 자체가 발생하지 않음. 로컬 스케줄러는 디바이스가 살아있어야 발화.
- 현 상태: `attendance_scheduler_service.py` 패턴은 있는데 `subscription_expiry_scheduler_service.py` 가 부재.
- 권장: ① `app/services/subscription_expiry_service.py` 신설 — 매일 1회 활성 수강권 스캔하여 D-14/D-7/D-1/D-0 매칭 시 `notification_service.create_and_send()` 호출. ② `scheduler.py` 에 `POST /scheduler/subscription/expiry-check` endpoint 추가 (attendance 패턴 그대로). ③ 외부 cron(systemd/k8s CronJob/GitHub Action) 으로 hourly 또는 daily 호출.

**G2. `Subscription.status` 자동 전이 부재**
- 영향: `expiringSoon`/`expired` 상태는 enum 에 정의되어 있으나 시간 흐름에 따라 자동 전이되지 않음. 프론트의 D-day 계산은 `endDate` 만 신뢰하고 status 는 stale.
- 권장: G1 의 expiry-check 작업이 status 전이도 함께 수행 (`end_date - today ≤ 7일` → `expiringSoon`, `end_date < today` → `expired`).

### P1 — 기능 정합성

**G3. Phase 5b 사용자 설정 백엔드 미러링 부재**
- 영향: 디바이스 교체/재설치 시 D-14/D-7/D-1/D-0 토글 설정 손실. 다기기 운영 불가.
- 현 상태: `subscription_settings` 테이블이 `renewal_alert_days: int = 7` (단일 값) + `enable_push_notification: bool` 만 보유. Phase 5b 의 4-axis (`remindAtD14/D7/D1/D0`) + master 와 모델이 다름.
- 권장: `subscription_settings` 에 `expiry_reminder_enabled: bool`, `remind_at_d14/d7/d1/d0: bool` 4 컬럼 추가 (Alembic migration 필요). 또는 JSON 컬럼 `expiry_reminder_offsets: list[int]` 단일화. 프론트 Hive ↔ 백엔드 양방향 sync.

**G4. 잔여횟수/만료까지 일수 derived 응답 부재**
- 영향: 모든 클라이언트가 직접 계산. 정책 변경(보너스, 5주 정책) 시 다중 소비자 분기.
- 권장: `SubscriptionResponse` 에 `remaining_lessons`, `days_until_expiration` 응답 필드 추가 (서비스 단계에서 산출).

**G5. `subscription_settings.renewal_alert_threshold/days` 미사용 (STALE)**
- 영향: 설정 컬럼만 존재하고 비즈니스 로직에서 읽지 않음. design-principles.md "설정 필드 = 로직 사용" 위반 (#18 패턴).
- 권장: G1 expiry-check 에서 teacher 별 `renewal_alert_threshold/days` 를 읽어 트리거 조건에 반영. 또는 컬럼 deprecation.

### P2 — 정합성/운영

**G6. cron/scheduler 운영 인프라 부재**
- `docker-compose.beta.yml` / `docker-compose.prod.yml` 에 cron 서비스 또는 외부 호출 문서 없음.
- 권장: `DEPLOY.md` 에 cron 호출 예시 추가, beta 에서 systemd timer 또는 k8s CronJob 명시. attendance_scheduler 도 동일 문제 공유 — 통합 운영 문서 필요.

**G7. `subscription_expiring` 알림 발송 코드 부재**
- 알림 type 은 seed_data 에 example 만, 런타임 생성 path 없음. G1 으로 해결.

## 4. 결론

- **총 점검 항목**: 12
- **PASS**: 0
- **FAIL**: 2 (G3, G4)
- **MISSING**: 8 (G1, G2, G6, G7 등)
- **STALE**: 1 (G5)
- **PASS 후보**: `Notification` 모델 자체 / `subscriptions` CRUD endpoint / proposal lifecycle (5a/5b 무관 영역은 OK)

**판정**: Phase 5a/5b 는 spec §3.4 "**서버 보장 알림**" 요건의 **약 30%만 구현됨** — 디바이스 로컬 스케줄러로 대체. 다기기/앱종료 시나리오에서 알림 누락 확정. Status Triage Phase 5a 완료 표기는 클라이언트 한정의 부분 완료이며, 백엔드 SSOT 와는 격차가 큼.

**후속 patch plan 권장 여부**: **YES (P0)**
- Plan 분기: ① `subscription_expiry_service` 신설 + `scheduler.py` endpoint 추가, ② `subscription_settings` 마이그레이션 (4-axis offset 컬럼), ③ `SubscriptionResponse` derived 필드 확장, ④ cron 운영 가이드 (`DEPLOY.md`).
- 의존성: attendance_scheduler 와 동일한 cron 호출 인프라 공유 — 통합 설계 권장.
