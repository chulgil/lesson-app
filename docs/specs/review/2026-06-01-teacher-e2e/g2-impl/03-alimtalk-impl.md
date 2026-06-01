# G2 #2 E2-C2 — 카카오 알림톡 5종 템플릿 구현 가이드

> 이슈: #423 / 브랜치: `feat/423-alimtalk`
> Worktree: `/private/tmp/lesson-app-worktrees/g2-alimtalk`
> 추정 작업: 2-3주 (백엔드 발신 큐 + 5종 트리거 + 폴백)
> **선행 작업 (외부, 사용자 처리 필요)**: 카카오 비즈니스 채널 등록 + 5종 템플릿 카카오 측 승인 (~1-2주 소요)

---

## 1. 다음 세션 진입 명령

```
"/private/tmp/lesson-app-worktrees/g2-alimtalk 에서 G2 #2 카카오 알림톡 코드 구현 진행. docs/specs/review/2026-06-01-teacher-e2e/g2-impl/03-alimtalk-impl.md 를 따라 진행"
```

---

## 2. 스펙 출처

- `docs/specs/notification/kakao_alimtalk_spec.md` (기존 + 본 작업으로 보강)
- `docs/specs/notification/alimtalk_templates.md` (320줄, 5종 템플릿 본문 + 정책)
- `docs/specs/subscription/subscription_master.md` §3 발송 트리거 안내

## 3. 선행 작업 (외부, 코드 작업 전 필수)

| # | 작업 | 담당 | 소요 |
|---|---|---|---|
| 1 | 카카오 비즈니스 계정 + 채널 등록 | 사용자 (사업자 정보) | 1-3일 |
| 2 | 알림톡 발신 프로필 발급 | 사용자 | 1주 |
| 3 | 5종 템플릿 카카오 측 승인 (LNZ_INVOICE / D1·D3·D7 / CONFIRM) | 사용자 + 알림톡 대행사 | 1-2주 |
| 4 | 발신 API 키 + 비용 정산 계좌 | 사용자 | 1일 |

> 위 1-4가 미완료 시 본 PR은 코드만 작성 + 통합 테스트는 mock으로 진행. 실 발신은 키 받은 후.

## 4. 구현 범위

### 4.1 백엔드 — 발신 모듈

| 파일 | 변경 유형 | 변경 |
|---|---|---|
| `backend/app/services/alimtalk_service.py` | **신규** | 5종 템플릿 발송 함수 + 폴백 로직 |
| `backend/app/core/alimtalk_client.py` | **신규** | 카카오 알림톡 대행사 API 클라이언트 (HTTP) |
| `backend/app/models/alimtalk_log.py` | **신규** | 발송 로그 모델 (멱등성·재시도) |
| `backend/app/jobs/alimtalk_retry_job.py` | **신규** | 실패 발송 재시도 cron |
| `backend/app/services/subscription_service.py` | 수정 | E1 송신 직후 LNZ_INVOICE 트리거 |
| `backend/app/services/payment_tracking_service.py` | 수정 | D+1/3/7 cron 에서 학생 측 LNZ_PAYMENT_REMINDER 트리거 (#424 와 결합) |
| `backend/app/jobs/payment_reminder_jobs.py` | 수정 (#424 의존) | 학생 측 알림톡 통합 |
| `backend/app/api/v1/alimtalk.py` | **신규** | 발송 이력 조회·재발송 API (테스트·운영 용) |
| `backend/tests/test_alimtalk_service.py` | 신규 | 5종 템플릿 + 폴백 + 멱등성 테스트 |
| `backend/alembic/versions/` | 신규 | alimtalk_logs 테이블 |
| `backend/.env.example` | 수정 | `ALIMTALK_API_KEY`, `ALIMTALK_SENDER_PROFILE` 추가 |

### 4.2 프론트엔드

| 파일 | 변경 유형 | 변경 |
|---|---|---|
| `frontend/lib/features/subscription/presentation/screens/proposal_compose_screen.dart` 등 | 수정 | 송신 직후 "카톡 알림톡 발송됨" 표시 |
| `frontend/lib/features/subscription/presentation/widgets/alimtalk_status_badge.dart` | **신규** | 발송 상태 표시 (발송 / 전송 실패) |

---

## 5. 작업 순서 (TDD + Mock 우선)

### Step 1: 발송 클라이언트 (mock)

`alimtalk_client.py`:

```python
class AlimTalkClient(Protocol):
    async def send(
        self,
        template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkResult: ...

class KakaoAlimTalkClient:
    async def send(self, template_id, recipient_phone, variables):
        # HTTP POST 알림톡 대행사 API
        ...

class MockAlimTalkClient:  # 테스트·로컬 개발용
    def __init__(self):
        self.sent_logs = []
    async def send(self, template_id, recipient_phone, variables):
        self.sent_logs.append((template_id, recipient_phone, variables))
        return AlimTalkResult(success=True, message_id="mock-123")
```

### Step 2: 발송 서비스

`alimtalk_service.py`:

```python
class AlimTalkService:
    def __init__(self, client: AlimTalkClient, db: AsyncSession):
        self.client = client
        self.db = db

    async def send_invoice(self, subscription: Subscription) -> None:
        """LNZ_INVOICE 발송 (E1 송신 직후)."""
        variables = {
            "student_name": subscription.student.name,
            "teacher_name": subscription.teacher.name,
            "amount": format_won(subscription.amount),
            "lesson_count": str(subscription.totalLessons),
            "bank_account": subscription.teacher.bankAccount,
            "expires_at": format_date(subscription.expiresAt),
        }
        await self._send_with_log(
            template_id="LNZ_INVOICE",
            recipient_phone=subscription.student.phone,
            variables=variables,
            subscription_id=subscription.id,
        )

    async def send_payment_reminder(self, sub: Subscription, d_day: int) -> None:
        """LNZ_PAYMENT_REMINDER_D1/D3/D7 발송."""
        template_id = f"LNZ_PAYMENT_REMINDER_D{d_day}"
        ...

    async def send_payment_confirm(self, sub: Subscription) -> None:
        """LNZ_PAYMENT_CONFIRM 발송 (E3 확인 직후)."""
        ...

    async def _send_with_log(self, ...):
        # 멱등성: 같은 subscription_id + template_id 이미 발송됨 체크
        existing = await self.db.execute(
            select(AlimTalkLog)
            .where(AlimTalkLog.subscription_id == subscription_id)
            .where(AlimTalkLog.template_id == template_id)
        )
        if existing.scalar_one_or_none():
            return  # 이미 발송, skip

        # 발송 시간 체크 (08:00-20:00, D+7 예외)
        if not in_send_window():
            schedule_for_morning(...)
            return

        # 실제 발송
        result = await self.client.send(template_id, recipient_phone, variables)
        log = AlimTalkLog(
            subscription_id=subscription_id,
            template_id=template_id,
            sent_at=datetime.utcnow(),
            success=result.success,
            message_id=result.message_id,
            error=result.error,
        )
        self.db.add(log)
        await self.db.commit()

        if not result.success:
            await self._fallback_to_push(...)
```

### Step 3: 트리거 연결

`subscription_service.py` 의 제안 송신 후:

```python
# E1 — 수강권 제안 송신 직후
subscription = await create_subscription_proposal(...)
await alimtalk_service.send_invoice(subscription)
```

`payment_tracking_service.py` 의 cron 에서:

```python
# D+1 cron
for sub in pending_subscriptions_d1:
    await alimtalk_service.send_payment_reminder(sub, d_day=1)
    # + 선생님 측 푸시 (#424)
```

`subscription_service.confirm_payment` 직후:

```python
# E3 — 입금 확인 직후
sub.paymentConfirmed = True
...
await alimtalk_service.send_payment_confirm(sub)
```

### Step 4: 폴백 로직

```python
async def _fallback_to_push(self, sub: Subscription, original_template: str):
    """알림톡 실패 시 앱 푸시로 폴백."""
    await fcm_service.send_to_student(
        sub.student_id,
        type=f"alimtalk_fallback.{original_template}",
        ...
    )
```

### Step 5: 발송 시간 체크

```python
def in_send_window() -> bool:
    """08:00-20:00 KST 발송 가능."""
    now_kst = datetime.now(KST)
    return 8 <= now_kst.hour < 20

def schedule_for_morning(template_id, recipient_phone, variables, ...):
    """20:00 이후면 다음날 09:00 으로 예약."""
    ...
```

### Step 6: 멱등성·재시도

`alimtalk_retry_job.py`:

```python
async def retry_failed_alimtalks():
    """실패한 알림톡 재시도 (최대 3회)."""
    failed = await db.execute(
        select(AlimTalkLog)
        .where(AlimTalkLog.success.is_(False))
        .where(AlimTalkLog.retry_count < 3)
        .where(AlimTalkLog.sent_at > datetime.utcnow() - timedelta(hours=24))
    )
    for log in failed:
        # 재시도
        ...
```

---

## 6. 테스트 케이스

```python
async def test_send_invoice_success(db, mock_client):
    sub = await create_subscription_proposal(...)
    service = AlimTalkService(mock_client, db)
    await service.send_invoice(sub)
    assert len(mock_client.sent_logs) == 1
    assert mock_client.sent_logs[0][0] == "LNZ_INVOICE"
    # DB 로그 확인
    logs = await db.execute(select(AlimTalkLog).where(...))
    assert logs.scalar_one().success is True

async def test_invoice_idempotency(db, mock_client):
    """같은 수강권에 LNZ_INVOICE 두 번 호출 → 한 번만 발송."""
    sub = await create_subscription_proposal(...)
    service = AlimTalkService(mock_client, db)
    await service.send_invoice(sub)
    await service.send_invoice(sub)
    assert len(mock_client.sent_logs) == 1

async def test_send_window_blocks_at_night(db, mock_client, freezer):
    """22:00 발송 시도 → 다음날 09:00 예약."""
    freezer.move_to("2026-06-01 22:00")
    ...

async def test_failure_falls_back_to_push(db, mock_client):
    """알림톡 실패 → 앱 푸시 폴백."""
    mock_client.next_failure = True
    await service.send_invoice(sub)
    # FCM 호출 확인
```

---

## 7. 환경 설정 (.env)

```bash
# 알림톡 대행사 API (예: 알리고, 카카오비즈니스, 솔루션박스)
ALIMTALK_API_BASE_URL=https://...
ALIMTALK_API_KEY=...
ALIMTALK_SENDER_PROFILE=...
ALIMTALK_USE_MOCK=false  # true 면 MockAlimTalkClient 사용 (로컬 개발)
```

---

## 8. 검증 게이트

```bash
# 백엔드
cd backend && uv run pytest tests/test_alimtalk_service.py -v
cd backend && uv run pytest --tb=short

# 마이그레이션
cd backend && uv run alembic upgrade head

# 통합 테스트 (mock client)
ALIMTALK_USE_MOCK=true uv run pytest tests/integration/

# 실 발신 테스트 (사업자 등록 후)
# 베타 환경에서 실제 발신 1회 확인
```

---

## 9. PR 정보

- 제목: `feat(notification): 카카오 알림톡 5종 템플릿 + 발신 큐 #423`
- Closes: #423
- Lore-directive: `알림톡 발신 시간 08:00-20:00 KST (D+7 만료 직전 예외)`
- Lore-directive: `발송 멱등성 — (subscription_id, template_id) 유일성 보장`
- Lore-directive: `폴백 체인 — 알림톡 → 앱 푸시 → SMS`
- Lore-constraint: `5종 템플릿 모두 카카오 측 사전 승인 필요`
- Lore-rejected: `직접 카카오톡 API 호출 — 사업자 인증 + 발송 큐 + 비용 관리 위해 대행사(알리고/솔박/카비) 경유`
- Lore-rejected: `자유 텍스트 발송 — 카카오는 사전 승인된 템플릿만 알림톡 허용`

---

## 10. 위험 요소

| 위험 | 완화 |
|---|---|
| 카카오 측 템플릿 거절 | 90자·변수 위치 등 가이드 준수, alimtalk_templates.md 참조 |
| 대행사 API 다운 | 폴백 (앱 푸시 → SMS) + 재시도 큐 |
| 비용 폭증 | 발송 로그 + 일별 통계 + 알림 |
| 동의 철회 (수신 거부) | 학생 측 수신 거부 플래그 + 발송 전 체크 |
| 운영 DB 마이그레이션 | alimtalk_logs 테이블 추가만, 기존 데이터 영향 없음 |
