# Patch Plan C — Subscription Expiry Cron + Status 자동 전이

> 작성일: 2026-04-28 · 적응 품질 모드: **ultra** (cron 인프라 + 알림 발송 + 결제 영향)
> 대상 갭: **P0-6** (`subscription_expiry_service` 부재) + **P0-7** (`Subscription.status` 자동 전이 부재)
> 부수: P1-9 (4-axis 토글 ↔ 단일 int 비호환), STALE-#18 (`renewal_alert_days/threshold` 미사용), G4 (derived 응답 필드 부재)
> baseline: `SUMMARY.md` §3, `subscription.md` §3 G1~G7

---

## 1. Goal

- `Subscription.status` 가 `end_date` 기준으로 **자동 전이** (active → expiringSoon → expired)
- 만료 D-14/D-7/D-1/D-0 시점에 **서버 발화** in-app + push 알림 (디바이스 종료/멀티디바이스 시에도 보장)
- Phase 5b 4-axis 토글을 백엔드 SSOT 로 미러링 (다기기 동기화)
- `subscription_settings.renewal_alert_days/threshold` 를 비즈니스 로직에 연결 (#18 위반 해소)
- Frontend derived 계산 (`remainingLessons`, `daysUntilExpiration`) 를 백엔드 응답으로 단일화

**Non-goal**: SubscriptionRenewalService (자동 갱신 트리거) — 별도 plan 으로 분리. 본 plan 은 만료 알림과 상태 전이까지.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Cron Trigger (Phase 1 결정 — APScheduler in-process 권장)       │
│  - 매일 00:05 KST (= 15:05 UTC)                                 │
│  - 호출: SubscriptionExpiryService.run_daily_check()            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  SubscriptionExpiryService  (app/services/)                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. scan_active_subscriptions(today)                     │   │
│  │    SELECT * FROM subscriptions                          │   │
│  │      WHERE status IN ('active','expiringSoon')          │   │
│  │      AND end_date IS NOT NULL                           │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ 2. compute_offset(end_date - today)                     │   │
│  │    → 14, 7, 1, 0, -N                                    │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ 3. transition_status(sub, days_left)                    │   │
│  │    days_left ≤ 7   → expiringSoon                       │   │
│  │    days_left < 0   → expired                            │   │
│  │    (idempotent — 이미 같은 status 면 skip)              │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ 4. should_notify(offset, settings)                      │   │
│  │    settings = SubscriptionSettings (teacher 단위)       │   │
│  │    offset ∈ {14,7,1,0} ∩ enabled axes                   │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ 5. dispatch(sub, offset)                                │   │
│  │    NotificationService.create_and_send(                 │   │
│  │      user_id=teacher_id (+ student_id, parent_id),      │   │
│  │      notification_type='subscription_expiring',         │   │
│  │      data={subId, daysLeft, remainingLessons})          │   │
│  │    → DB insert + FCM push                               │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ 6. dedup_guard                                          │   │
│  │    SubscriptionExpiryNotificationLog 테이블로           │   │
│  │    (subscription_id, offset_days, sent_date) UNIQUE     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Persistence                                                     │
│  - subscriptions.status (UPDATE)                                │
│  - notifications (INSERT, type='subscription_expiring')         │
│  - subscription_expiry_notification_log (INSERT — dedup)        │
│  - FCM push via DeviceTokenService + FcmService                 │
└─────────────────────────────────────────────────────────────────┘

[수동 트리거 / 테스트용]
POST /scheduler/subscription/expiry-check
POST /scheduler/subscription/run-all
```

**Boring 결정**: `attendance_scheduler` 와 동일한 service + scheduler endpoint 패턴을 그대로 차용. 새 인프라 도입 최소화.

---

## 3. Phase 분해 (TDD)

### Phase 1 — Cron 인프라 결정 (사용자 승인 필요)

> **DECISION POINT**: 인프라 옵션 3종 — 사용자 명시 승인 후 Phase 2 착수.

| 옵션 | 장점 | 단점 | 권장 |
|------|------|------|------|
| **A. APScheduler in-process** | 새 컨테이너/의존성 0, FastAPI lifespan 에 통합, attendance_scheduler 도 같이 내재화 | 앱 인스턴스 N개 시 N회 발화 위험 (lock 필요). 앱 재시작 시 1회 누락 가능 | **권장 (Boring)** |
| B. docker-compose 별도 cron 컨테이너 | 인스턴스 격리, 단순 cron 표현식 | docker-compose.beta/prod 양쪽 수정, 운영 가이드 추가 | 옵션 A flake 시 폴백 |
| C. Celery + Redis | 분산 안전, retry/backoff | Redis 의존성 신규, 운영 복잡도 급증 | **금지** (Boring 위반) |

**옵션 A 채택 시 작업**:
- `app/core/scheduler.py` 신설 — APScheduler `AsyncIOScheduler` lifespan 통합
- 단일 인스턴스 보장: PostgreSQL advisory lock (`pg_try_advisory_lock`) 으로 동시 실행 방지
- attendance_scheduler 도 같은 스케줄러에 등록 (인프라 통합)

**산출물**: `app/core/scheduler.py`, `main.py` lifespan 수정, `pyproject.toml` 에 `apscheduler ^3.10` 추가

**[병렬 가능 task 없음]** — 인프라 결정 단일 의존.

**예상 시간**: 4h (조사 1h + 결정 + 구현 2h + 부하 테스트 1h)

---

### Phase 2 — SubscriptionExpiryService (계산 + status 전이)

`app/services/subscription_expiry_service.py` 신설.

**핵심 책임**:
1. 활성 수강권 스캔 (status ∈ {active, expiringSoon}, end_date NOT NULL)
2. `days_left = end_date - today_kst` 계산
3. status 전이 (idempotent):
   - `0 ≤ days_left ≤ 7` → `expiringSoon`
   - `days_left < 0` → `expired`
   - 동일 status 면 UPDATE skip
4. `(subscription, days_left)` 튜플 반환 — Phase 3 가 알림 발송 판단

**테스트 우선 (TDD)** — 테스트는 Phase 6 참조. 본 Phase 는 다음 단위 테스트 선행:
- `test_compute_days_left_kst_boundary` — UTC/KST 경계 (자정 ±1h)
- `test_transition_status_idempotent` — 두 번 호출 시 UPDATE 1회만
- `test_status_active_to_expiring_at_7d`
- `test_status_expiring_to_expired_at_0d`

**[병렬 가능 task]**:
- `[병렬-A]` `app/services/subscription_expiry_service.py` 골격 + 단위 테스트
- `[병렬-B]` `app/schemas/subscription.py` 에 `SubscriptionResponse.remaining_lessons` / `days_until_expiration` 추가 (Phase 5 사전 준비)

**예상 시간**: 6h

---

### Phase 3 — Notification 발송 통합 (in-app + push)

**전제**: `NotificationService.create_and_send()` 이미 in-app DB insert + FCM push 모두 처리 (검증 완료, line 98-152).

**작업**:
1. `subscription_expiry_service.py` 에 `dispatch_notifications()` 메서드 추가
2. 알림 수신자 결정:
   - **선생님**: `subscription.membership_id` → `class_membership.teacher_id` 조회
   - **학생**: `subscription.student_id` (User 매핑)
   - **학부모**: `parent_relationship` 조회 후 `notify_parent` flag 체크
3. dedup guard — 신규 테이블 `subscription_expiry_notification_log`:
   ```
   id (uuid), subscription_id, offset_days (int), sent_date (date),
   recipient_user_id, created_at
   UNIQUE (subscription_id, offset_days, sent_date, recipient_user_id)
   ```
4. notification payload:
   ```python
   notification_type="subscription_expiring"
   priority=NotificationPriority.high if days_left ≤ 1 else .normal
   title=f"수강권 만료 D-{days_left}"
   body=f"{student_name} 수강권이 {days_left}일 후 만료됩니다"
   data={subscriptionId, daysLeft, remainingLessons}
   action_url=f"/subscriptions/{sub.id}"
   ```

**[병렬 가능 task]**:
- `[병렬-A]` `dispatch_notifications` 구현 + recipient 결정 로직
- `[병렬-B]` Alembic migration `0007_subscription_expiry_notification_log.py`
- `[병렬-C]` `notification_type='subscription_expiring'` 의 i18n 라벨 등록 (`app/models/i18n.py`)

**예상 시간**: 8h

---

### Phase 4 — subscription_settings 4-axis 컬럼 + 프론트 매핑

**모델 변경** (alembic reversible):
```python
class SubscriptionSettings:
    # 기존 (보존, deprecation 표시)
    renewal_alert_days: int = 7        # @deprecated — Phase 4 후 미사용
    renewal_alert_threshold: int = 2   # 잔여횟수 기반 알림 (Phase 5 별도)

    # 신규
    expiry_reminder_enabled: bool = True       # master toggle
    remind_at_d14: bool = True
    remind_at_d7: bool = True
    remind_at_d1: bool = True
    remind_at_d0: bool = True
```

**대안 (사용자 결정 필요)**:
- 옵션 X: **4 컬럼 추가** (위 안) — 쿼리 단순, 인덱스 가능, ALTER 1회
- 옵션 Y: **JSON 컬럼 `expiry_reminder_offsets: list[int]`** — 향후 D-3, D-2 추가 시 마이그레이션 불필요
- **권장**: 옵션 X (Boring, 정적 enum 4개). 향후 새 offset 은 spec 변경 + 컬럼 추가 1회로 처리.

**Migration 작업** (`0008_subscription_settings_4axis.py`):
1. ADD COLUMN expiry_reminder_enabled, remind_at_d14, d7, d1, d0 (기본값 TRUE)
2. 기존 데이터 백필: `renewal_alert_days=7` 인 row 는 d7=TRUE, d14=FALSE 로 추정 매핑
   - **Lore-constraint**: 정확한 매핑 불가능 (단일 값 → 4 axis 비단사) — 안전한 default 채택 (모두 TRUE)
3. downgrade: 4 컬럼 DROP, `renewal_alert_days` 보존

**API 변경**:
- `GET /settings/subscription` → 4-axis 필드 응답
- `PATCH /settings/subscription` → 4-axis 필드 수신
- 프론트 `subscription_expiry_providers.dart` 의 Hive 키를 백엔드 호출로 교체 (Hive 는 캐시 only)

**[병렬 가능 task]**:
- `[병렬-A]` Alembic migration
- `[병렬-B]` `SubscriptionSettings` model + schema 갱신
- `[병렬-C]` `settings_api.py` 엔드포인트 4-axis 노출
- `[병렬-D]` Frontend `SubscriptionExpiryReminderSettings` ↔ API DTO 매핑

**예상 시간**: 10h

---

### Phase 5 — Derived 필드 백엔드 계산

**현재 문제**: 프론트가 `remainingLessons = totalLessons - usedLessons`, `daysUntilExpiration = endDate.diff(now)` 단독 계산. 정책 변경 (보너스, 5주, NoShow 차감) 시 다중 소비자(teacher app, parent app, web) 분기.

**작업**:
1. `SubscriptionResponse` schema 에 신규 필드 (computed):
   - `remaining_lessons: int | None` — `total_lessons - used_lessons + bonus_count`
   - `days_until_expiration: int | None` — `(end_date - today_kst).days`
   - `is_expired: bool` — `days_until_expiration < 0`
   - `is_expiring_soon: bool` — `0 ≤ days_until_expiration ≤ 7`
2. `SubscriptionService.list_subscriptions / get_subscription` 응답 직전에 computed 필드 채움
3. Frontend `Subscription` entity 의 derived getter 를 backend 응답으로 교체 (없으면 fallback 유지 — 무중단 전환)

**[병렬 가능 task]**:
- `[병렬-A]` Backend schema + service computed 필드
- `[병렬-B]` Frontend entity 의 backend-first derived 패치 (transitional)

**예상 시간**: 5h

---

### Phase 6 — 검증 (e2e + 부하)

**시나리오 e2e** (`tests/test_subscription_expiry_e2e.py`):
1. **D-14 정확 발화** — `freezegun` 으로 today 고정, end_date = today+14 인 sub 생성 → run check → notification 1건 + status=active 유지
2. **D-7 status 전이** — end_date=today+7 → status active→expiringSoon 전이 + notification 1건
3. **D-1 high priority** — end_date=today+1 → notification priority=high
4. **D-0 expired 전이** — end_date=today → status expiringSoon→ (D+1 시점 expired)
5. **dedup** — 같은 날 두 번 run → notification 1건만
6. **disabled axis** — `remind_at_d7=FALSE` 인 teacher 의 sub → D-7 발화 skip
7. **multi-recipient** — 학생 + 학부모 각각 device_token 보유 시 2 push
8. **status idempotent** — 이미 expiringSoon 인 sub 재처리 → UPDATE skip

**부하 시나리오**:
- 1000개 활성 수강권 → run check 실행 시간 < 5s
- N+1 쿼리 부재 검증 (`selectinload` 또는 batched IN)

**프론트 회귀**:
- Hive 캐시 ↔ 백엔드 응답 일치 확인 (settings 화면)
- 디바이스 OFF 시뮬레이션 — beta 서버에 직접 sub 등록 후 D-7 시각 도달 시 push 수신 확인

**[병렬 가능 task]**:
- `[병렬-A]` e2e 시나리오 1~5 (시간 기반)
- `[병렬-B]` e2e 시나리오 6~8 (설정/recipient)
- `[병렬-C]` 부하 테스트 + N+1 점검
- `[병렬-D]` Frontend 회귀

**예상 시간**: 8h

---

## 4. 의존성 / 리스크 / 롤백

### 의존성

| 의존 | 종류 | 상태 |
|---|---|---|
| `NotificationService.create_and_send` | 기존 활용 | ✅ 사용 가능 |
| `DeviceTokenService` + `FcmService` | 기존 활용 | ✅ 사용 가능 |
| `SubscriptionSettings` model | Phase 4 에서 확장 | ⚠️ 마이그레이션 |
| Cron 인프라 | Phase 1 신규 | 🔴 사용자 결정 필요 |
| KST 타임존 처리 | `app/core/timezone.py` 존재 여부 확인 필요 | ⚠️ 미확인 |

### 리스크

1. **APScheduler 다중 인스턴스 발화 (HIGH)** — 옵션 A 채택 시 lock 필수. PostgreSQL advisory lock + dedup table 의 이중 방어. 운영 인스턴스 수평 확장 시 재검증.
2. **시간대 경계 (HIGH)** — UTC vs KST. `end_date` 는 date 타입이라 timezone 미보유. cron 실행 시각 KST 자정 직후 = UTC 15:05 로 명시 고정. `today_kst = datetime.now(ZoneInfo("Asia/Seoul")).date()`.
3. **알림 중복 (MEDIUM)** — dedup table 의 UNIQUE 제약 + INSERT ON CONFLICT DO NOTHING 패턴 필수.
4. **`renewal_alert_days` 백필 부정확 (LOW)** — 단일 int → 4-axis 비단사. 안전한 default(모두 TRUE) 적용. 사용자 영향: 알림 더 많이 받음 (안전 측). PR 노트로 공지.
5. **status 전이 → 결제 트리거 (UNKNOWN)** — `status=expired` 가 다른 서비스(자동 갱신, 결제 차단)에 영향 주는지 grep 으로 확인 필요. 영향 있으면 별도 회귀.
6. **부하 (MEDIUM)** — 활성 sub 수만큼 N+1 risk. `selectinload(Subscription.membership)` + `parent_relationship` 사전 로드.

### 롤백

- Phase 1 (cron): scheduler 등록 라인만 주석 → 즉시 비활성. APScheduler 의존성은 dormant.
- Phase 2-3 (service + dispatch): cron 비활성으로 자동 호출 차단. 수동 endpoint 만 노출.
- Phase 4 (alembic): `alembic downgrade -1` — 4 컬럼 DROP, `renewal_alert_days` 보존. **사전에 prod DB 백업 필수**.
- Phase 5 (derived): API 응답에 추가만 — 기존 필드 보존, 프론트는 fallback 유지로 무중단.

---

## 5. 평가 기준 (rubric, 합격선 7.5)

| 기준 | 가중 | 합격 | 평가 방법 |
|------|-----:|-----:|----------|
| 완성도 | 40% | 8/10 | P0-6, P0-7, P1-9, STALE-#18, G4 5건 모두 해소. spec §3.4 "in-app + push 서버 보장" 충족 |
| 견고성 | 30% | 8/10 | e2e 8 시나리오 + 부하 1000건 + dedup UNIQUE 제약 + status 전이 idempotent |
| 일관성 | 20% | 9/10 | attendance_scheduler 패턴 100% 차용. 도메인 린터 (subscription_expiry_service.py 단수형 service 접미사) 준수 |
| 간결성 | 10% | 8/10 | service 단일 파일 ≤400줄. APScheduler 단일 lifespan hook. 신규 의존성 1개 (apscheduler) |

**무조건 FAIL 조건**:
- 어느 e2e 시나리오든 실패
- KST/UTC 경계 테스트 누락
- 부하 테스트 5s 초과

---

## 6. TDD 테스트 예시

### 예시 1 — status 전이 idempotent (Phase 2)

```python
# tests/services/test_subscription_expiry_service.py
import pytest
from datetime import date, timedelta
from freezegun import freeze_time

from app.models.subscription import Subscription, SubscriptionStatus
from app.services.subscription_expiry_service import SubscriptionExpiryService


@pytest.mark.asyncio
@freeze_time("2026-05-01 15:30:00")  # UTC = 2026-05-02 00:30 KST
async def test_status_transition_active_to_expiring_at_d7(db, teacher_factory, student_factory):
    """수강권 만료 7일 전 → status active→expiringSoon 자동 전이."""
    teacher = await teacher_factory()
    student = await student_factory(teacher_id=teacher.id)
    sub = Subscription(
        student_id=student.id,
        membership_id="m1",
        type="package",
        end_date=date(2026, 5, 9),  # KST today=05-02, +7 days
        status=SubscriptionStatus.active,
        total_lessons=8,
        used_lessons=2,
    )
    db.add(sub); await db.flush()

    service = SubscriptionExpiryService(db)
    result = await service.run_daily_check()

    await db.refresh(sub)
    assert sub.status == SubscriptionStatus.expiringSoon
    assert result["transitions"] == 1

    # idempotent — 두 번째 실행 시 UPDATE 없음
    result2 = await service.run_daily_check()
    assert result2["transitions"] == 0
```

### 예시 2 — D-7 알림 dedup (Phase 3)

```python
@pytest.mark.asyncio
@freeze_time("2026-05-01 15:30:00")
async def test_d7_notification_dedup_same_day(db, teacher_factory, student_factory, device_token_factory):
    """같은 날 두 번 실행해도 D-7 알림은 1건만 발송."""
    teacher = await teacher_factory()
    student = await student_factory(teacher_id=teacher.id)
    await device_token_factory(user_id=teacher.id)
    sub = Subscription(
        student_id=student.id,
        membership_id="m1",
        type="package",
        end_date=date(2026, 5, 9),
        status=SubscriptionStatus.active,
    )
    db.add(sub); await db.flush()

    service = SubscriptionExpiryService(db)
    r1 = await service.run_daily_check()
    r2 = await service.run_daily_check()

    assert r1["notifications_sent"] == 1
    assert r2["notifications_sent"] == 0  # dedup

    from app.models.notification import Notification
    notifs = (await db.scalars(
        select(Notification).where(Notification.type == "subscription_expiring")
    )).all()
    assert len(notifs) == 1
    assert notifs[0].data["daysLeft"] == 7
```

---

## 7. 사용자 결정 필요 (Unknowns)

> Phase 1 착수 전 다음 4건 명시 승인 필요:

1. **Cron 인프라**: APScheduler in-process (옵션 A) vs docker-compose 별도 cron 컨테이너 (옵션 B)?
   - 권장: A (Boring). 단, 운영 인스턴스 수평 확장 계획 있으면 B.
2. **`subscription_settings` 스키마**: 4 컬럼 (옵션 X) vs JSON 컬럼 (옵션 Y)?
   - 권장: X (Boring, 정적 4 axis).
3. **`renewal_alert_days` deprecation**: Phase 4 에서 컬럼 즉시 DROP vs 6개월 grace period 보존?
   - 권장: 보존 (다른 서비스 grep 결과 미사용 확인 후 다음 라운드 DROP).
4. **알림 수신자 범위**: 선생님만 vs 선생님+학생 vs 선생님+학생+학부모?
   - spec §3.4 명시 부재 — 사용자 결정. 권장: 학생 본인 + 학부모 (notify_parent flag 존중). 선생님은 dashboard 뱃지만.

---

## 8. Phase 요약 + 추정 시간

| Phase | 시간 | 의존 |
|------|-----:|------|
| 1. Cron 인프라 결정 | 4h | 사용자 승인 |
| 2. SubscriptionExpiryService (계산 + status) | 6h | Phase 1 |
| 3. Notification 발송 + dedup | 8h | Phase 2, alembic |
| 4. subscription_settings 4-axis | 10h | alembic, frontend 동시 |
| 5. Derived 필드 응답 | 5h | Phase 2 산식 재사용 |
| 6. 검증 (e2e + 부하) | 8h | Phase 1-5 모두 |
| **합계** | **41h** | (≈ 5 영업일, ultra 모드) |

병렬 가능 task 활용 시 실효 단축 ≈ 32h (4 영업일).

---

## 9. 후속 plan (out-of-scope)

- **SubscriptionRenewalService** — 만료 D-3 시점 자동 갱신 제안 (renewal_spec.md §2). 본 plan 의 cron 인프라 위에 service 추가만 필요.
- **`subscription_settings.renewal_alert_threshold`** (잔여횟수 기반 알림) — 본 plan 은 D-day 기반만 처리. 잔여횟수 기반 알림은 별도 service.
- **`amount_paid` / 미수금 추적** (subscription_master.md G6) — 결제 도메인 plan 으로 분리.
- **DEPLOY.md cron 운영 가이드** — Phase 1 옵션 결정 후 작성. attendance_scheduler 와 통합 문서화.

---

## 10. 참조

- baseline: `docs/specs/backend/audit/2026-04-28/SUMMARY.md` §3, §6
- baseline: `docs/specs/backend/audit/2026-04-28/subscription.md` §3 G1~G7
- spec SSOT: `docs/specs/student/enrollment_management_ux_spec.md` §3.4
- 패턴 참조: `app/services/attendance_scheduler_service.py`, `app/api/v1/scheduler.py`
- 관련 plan: `_A_request_event_ssot.md` (Schedule), `_B_lesson_enum_align.md` (Lesson) — 본 plan 과 cron 인프라 공유 가능

> **Lore-directive (작업 시 trailer 추가)**: APScheduler in-process 채택 — Boring 우선
> **Lore-rejected**: Celery + Redis — 신규 인프라 의존성 과대, attendance_scheduler 도 동일 부담
> **Lore-constraint**: KST 자정 기준 D-day 산정 — `end_date` 는 date 타입, `datetime.now(ZoneInfo("Asia/Seoul")).date()` 단일 진원지
