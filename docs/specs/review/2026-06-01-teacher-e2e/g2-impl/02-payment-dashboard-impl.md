# G2 #3 E2-C1 — 입금 미확인 대시보드 + 자동 리마인드 구현 가이드

> 이슈: #424 / 브랜치: `feat/424-payment-dashboard`
> Worktree: `/private/tmp/lesson-app-worktrees/g2-payment-dashboard`
> 추정 작업: 3-5일 (백엔드 + 프론트엔드 + cron + 푸시)
> 의존: 선생님 측 푸시는 즉시 가능, 학생 측 알림톡은 #423 (#2 E2-C2) 완료 후 결합

---

## 1. 다음 세션 진입 명령

```
"/private/tmp/lesson-app-worktrees/g2-payment-dashboard 에서 G2 #3 입금 대시보드 코드 구현 진행. docs/specs/review/2026-06-01-teacher-e2e/g2-impl/02-payment-dashboard-impl.md 를 따라 진행"
```

---

## 2. 스펙 출처

- `docs/specs/subscription/payment_tracking_dashboard.md` (319줄, 본 작업의 master 스펙)
- `docs/specs/home/home_master.md` 입금 대기 카드 정의
- `docs/specs/notification/notification_master.md` 선생님 측 푸시 3종

## 3. 구현 범위

### 3.1 백엔드 (집계 + cron + 푸시)

| 파일 | 변경 유형 | 변경 |
|---|---|---|
| `backend/app/api/v1/subscriptions.py` | 수정 | `GET /api/v1/subscriptions/payments/pending` — 선생님별 paymentRequested/paymentNotified 집계 |
| `backend/app/services/payment_tracking_service.py` | **신규** | `get_pending_payments(teacher_id) -> List[PendingPayment]`, `mark_reminder_sent(sub_id, d)` |
| `backend/app/jobs/payment_reminder_jobs.py` | **신규** | cron 3종: `notify_teacher_d1`, `notify_teacher_d3`, `notify_teacher_d7_final` (매일 09:00) |
| `backend/app/services/fcm_service.py` | 수정 | 신규 알림 키 등록: `payment.pending_d1/d3/d7_final` |
| `backend/app/models/subscription.py` | 수정 | `reminderD1SentAt`, `reminderD3SentAt`, `reminderD7SentAt` 필드 추가 (멱등성) |
| `backend/alembic/versions/` | 신규 | 위 3 필드 마이그레이션 |
| `backend/tests/test_payment_tracking.py` | 신규 | 집계·cron·푸시 테스트 |

### 3.2 프론트엔드

| 파일 | 변경 유형 | 변경 |
|---|---|---|
| `frontend/lib/features/home/presentation/widgets/payment_pending_card.dart` | **신규** | "입금 대기 N건" 카드 (Notebook × Score 스타일) |
| `frontend/lib/features/home/presentation/screens/home_screen.dart` 등 | 수정 | 카드 추가 |
| `frontend/lib/features/subscription/presentation/screens/payment_pending_list_screen.dart` | **신규** | 학생별 D+N + 1탭 재발송·확인 |
| `frontend/lib/features/subscription/data/repositories/subscription_repository.dart` | 수정 | `getPendingPayments() -> List<PendingPayment>` |
| `frontend/lib/features/subscription/presentation/providers/payment_tracking_provider.dart` | **신규** | Riverpod AsyncNotifier |
| `frontend/lib/core/l10n/app_strings.dart` | 수정 | 신규 문자열 |

---

## 4. 작업 순서 (TDD)

### Step 1: 백엔드 — 집계 API (단순)

`payment_tracking_service.py`:

```python
@dataclass
class PendingPayment:
    subscription_id: UUID
    student_id: UUID
    student_name: str
    amount: int
    proposed_at: datetime
    days_pending: int  # D+N
    last_reminder_d: int | None  # 마지막 발송된 리마인드 (1, 3, 7)
    status: str  # paymentRequested or paymentNotified

async def get_pending_payments(db, teacher_id: UUID) -> List[PendingPayment]:
    """선생님의 입금 대기 수강권 집계."""
    rows = await db.execute(
        select(Subscription)
        .where(Subscription.teacher_id == teacher_id)
        .where(Subscription.status.in_(["paymentRequested", "paymentNotified"]))
        .options(joinedload(Subscription.student))
    )
    # days_pending 계산 + 매핑
```

### Step 2: cron 작업

`payment_reminder_jobs.py`:

```python
async def notify_teacher_d1():
    """D+1 푸시 — 매일 09:00."""
    targets = await get_subscriptions_pending_for_d(1)  # 어제 제안된 + reminderD1SentAt is None
    for sub in targets:
        await fcm.send_to_teacher(
            sub.teacher_id,
            type="payment.pending_d1",
            data={"subscription_id": str(sub.id), "student_name": sub.student.name},
        )
        sub.reminderD1SentAt = datetime.utcnow()
    await db.commit()
```

`notify_teacher_d3`, `notify_teacher_d7_final` 동일 패턴.

### Step 3: 스케줄러 등록

cron 진입점은 `backend/app/jobs/` 의 기존 패턴 확인 후 등록. APScheduler 또는 cron expression.

### Step 4: 프론트엔드 — 홈 카드

`payment_pending_card.dart`:

```dart
class PaymentPendingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(paymentPendingCountProvider);
    return pending.when(
      data: (count) => count == 0
          ? const SizedBox.shrink()
          : Card(
              child: ListTile(
                title: Text('${AppStrings.paymentPendingLabel}: $count건'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => context.go('/payments/pending'),
              ),
            ),
      loading: () => const SkeletonCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### Step 5: 입금 대기 리스트 화면

학생별 카드 + D+N 표시 + 액션 3종:
- [재발송] (LNZ_PAYMENT_REMINDER 재발송 — #423 의존, 일단 인앱 push만)
- [입금 확인] (E3 진입)
- [회수] (제안 취소)

### Step 6: 테스트

```python
async def test_pending_payments_aggregation(db, teacher):
    # 3개 수강권 (각각 paymentRequested 상태, 다른 날짜)
    ...
    pending = await get_pending_payments(db, teacher.id)
    assert len(pending) == 3
    assert pending[0].days_pending == 3

async def test_reminder_idempotency(db):
    """D+1 cron이 두 번 돌아도 푸시는 한 번만."""
    await notify_teacher_d1()
    # FCM 호출 count = 1
    await notify_teacher_d1()
    # FCM 호출 count = 여전히 1
```

---

## 5. 위젯 스모크 테스트

ux-rules.md HARD-GATE 준수 — `PaymentPendingCard` 는 top-level widget 이므로 smoke test 필수:

```dart
testWidgets('PaymentPendingCard renders without crash', (tester) async {
  await tester.pumpWidget(MaterialApp(home: PaymentPendingCard()));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

---

## 6. 검증 게이트

```bash
# 백엔드
cd backend && uv run pytest tests/test_payment_tracking.py -v
cd backend && uv run pytest --tb=short  # 회귀

# cron 수동 트리거 테스트 (개발 환경)
cd backend && uv run python -m app.jobs.payment_reminder_jobs

# 프론트엔드
cd frontend && flutter analyze
cd frontend && flutter test
```

---

## 7. PR 정보

- 제목: `feat(payment): 선생님 입금 대기 대시보드 + D+1/3/7 자동 리마인드 #424`
- Closes: #424
- Lore-directive: `선생님 측 푸시 3종 (payment.pending_d1/d3/d7_final) 채택`
- Lore-constraint: `cron 발송 멱등성 — reminderD*SentAt 필드로 중복 발송 방지`
- 비고: 학생 측 알림톡(LNZ_PAYMENT_REMINDER_*)은 #423 완료 후 결합. 본 PR은 선생님 측만.

---

## 8. 의존 관계 (다음 단계)

#423 (알림톡) 완료 후 통합 PR:
- `payment_reminder_jobs.py` 의 cron 에서 알림톡 발송 추가
- 학생 측 LNZ_PAYMENT_REMINDER_D1/D3/D7 자동 발송
- 폴백 정책 (알림톡 실패 → 앱 푸시)
