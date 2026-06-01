# G2 #6 E3-H2 — 입금 확인 Undo (24h) 구현 가이드

> 이슈: #426 / 브랜치: `feat/426-payment-undo`
> Worktree: `/private/tmp/lesson-app-worktrees/g2-payment-undo`
> 추정 작업: 1-2일 (백엔드 + 프론트엔드 + 테스트)
> 의존: 없음 (가장 자족적, 가장 먼저 진행 권장)

---

## 1. 다음 세션 진입 명령

```
"/private/tmp/lesson-app-worktrees/g2-payment-undo 에서 G2 #6 입금 확인 Undo 코드 구현 진행. docs/specs/review/2026-06-01-teacher-e2e/g2-impl/01-payment-undo-impl.md 를 따라 진행"
```

해당 worktree에서:
```bash
cd /private/tmp/lesson-app-worktrees/g2-payment-undo
git pull origin main  # 최신 스펙 가져오기
```

---

## 2. 스펙 출처

- `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md` #6 항목
- `docs/specs/subscription/subscription_master.md` §3 보강 안내 박스 (24h Undo 정책)
- 정량 입증: `grep undoConfirmPayment` = 0건 (현재 미구현)

## 3. 구현 범위

### 3.1 백엔드

| 파일 (수정/신규) | 변경 |
|---|---|
| `backend/app/models/subscription.py` (수정 추정) | 필드 추가: `confirmedAt: DateTime?` (이미 있을 가능성 확인), `firstLessonConsumedAt: DateTime?` |
| `backend/app/services/subscription_service.py` (수정) | 메서드 추가: `undo_confirm_payment(subscription_id, teacher_id) -> Subscription` |
| `backend/app/api/v1/subscriptions.py` (수정 추정) | 엔드포인트 추가: `POST /api/v1/subscriptions/{id}/undo-confirm` |
| `backend/tests/test_subscription_undo_confirm.py` (신규) | 테스트 4개 |
| `backend/alembic/versions/` (신규 마이그레이션) | `firstLessonConsumedAt` 컬럼 추가 |

### 3.2 프론트엔드

| 파일 (수정/신규) | 변경 |
|---|---|
| `frontend/lib/features/subscription/data/repositories/subscription_repository.dart` (수정) | `undoConfirmPayment(id)` 메서드 추가 |
| `frontend/lib/features/subscription/presentation/screens/` (수정 — 입금 확인 화면) | 확인 직후 SnackBar 노출 (24h 안내 + [되돌리기] 액션) |
| `frontend/lib/core/l10n/app_strings.dart` (수정) | `paymentConfirmedSnackbar`, `undoLabel`, `undoSuccessSnackbar` |
| `frontend/test/features/subscription/` (신규) | 위젯 테스트 |

---

## 4. TDD 순서 (Red → Green → Refactor)

### Step 1: 백엔드 테스트 작성 (Red)

`backend/tests/test_subscription_undo_confirm.py`:

```python
async def test_undo_within_24h_success(db, teacher, student):
    sub = await create_subscription_and_confirm(teacher, student)
    # 시간 조작 23h 뒤
    with freeze_time(sub.confirmedAt + timedelta(hours=23)):
        result = await undo_confirm_payment(sub.id, teacher.id)
    assert result.paymentConfirmed is False
    assert result.status == "paymentRequested"
    # 자동 생성된 스케줄도 취소되었는지

async def test_undo_after_24h_fails(db, teacher, student):
    sub = await create_subscription_and_confirm(teacher, student)
    with freeze_time(sub.confirmedAt + timedelta(hours=25)):
        with pytest.raises(BusinessRuleError, match="24h 윈도우 초과"):
            await undo_confirm_payment(sub.id, teacher.id)

async def test_undo_after_first_lesson_consumed_fails(db, teacher, student):
    sub = await create_subscription_and_confirm(teacher, student)
    await consume_first_lesson(sub)  # firstLessonConsumedAt 설정
    with pytest.raises(BusinessRuleError, match="첫 레슨 차감 후 불가"):
        await undo_confirm_payment(sub.id, teacher.id)

async def test_undo_rolls_back_relationship_status(db, teacher, student):
    sub = await create_subscription_and_confirm(teacher, student)
    relation = await get_relation(teacher, student)
    assert relation.status == "active"
    await undo_confirm_payment(sub.id, teacher.id)
    relation = await get_relation(teacher, student)
    assert relation.status in ["trialBooked", "invitePending"]  # 이전 상태로
```

### Step 2: 백엔드 구현 (Green)

`subscription_service.py`:

```python
async def undo_confirm_payment(
    db: AsyncSession,
    subscription_id: UUID,
    teacher_id: UUID,
) -> Subscription:
    sub = await get_subscription_or_raise(db, subscription_id, teacher_id)
    if not sub.paymentConfirmed:
        raise BusinessRuleError("입금 미확인 상태에서는 Undo 불가")
    if sub.firstLessonConsumedAt is not None:
        raise BusinessRuleError("첫 레슨 차감 후 불가")
    if (datetime.utcnow() - sub.confirmedAt) > timedelta(hours=24):
        raise BusinessRuleError("24h 윈도우 초과")

    # 1) 수강권 회수
    sub.paymentConfirmed = False
    sub.status = SubscriptionStatus.paymentRequested
    sub.confirmedAt = None

    # 2) 관계 롤백 (이전 상태로)
    relation = await get_relation_by_subscription(db, sub.id)
    relation.status = sub.previousRelationStatus or RelationshipStatus.trialBooked

    # 3) 자동 생성된 스케줄 취소
    auto_lessons = await get_auto_generated_lessons(db, sub.id)
    for lesson in auto_lessons:
        lesson.status = LessonStatus.cancelled

    await db.commit()
    return sub
```

### Step 3: API 엔드포인트

```python
@router.post("/{subscription_id}/undo-confirm", response_model=SubscriptionResponse)
async def undo_confirm_payment_endpoint(
    subscription_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await subscription_service.undo_confirm_payment(
        db, subscription_id, current_user.id
    )
```

### Step 4: 마이그레이션

```python
# alembic/versions/XXXX_add_first_lesson_consumed_at.py
op.add_column(
    'subscriptions',
    sa.Column('first_lesson_consumed_at', sa.DateTime(), nullable=True)
)
```

### Step 5: 프론트엔드

`subscription_repository.dart`:

```dart
Future<Subscription> undoConfirmPayment(String subscriptionId) async {
  final response = await _dio.post('/api/v1/subscriptions/$subscriptionId/undo-confirm');
  return Subscription.fromJson(response.data);
}
```

입금 확인 화면 (해당 screens/payment_confirm_screen.dart 또는 동등):

```dart
// 입금 확인 직후 SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    duration: const Duration(seconds: 8),
    content: Text(AppStrings.paymentConfirmedSnackbar),  // "입금 확인 완료. 24시간 내 되돌릴 수 있습니다."
    action: SnackBarAction(
      label: AppStrings.undoLabel,  // "되돌리기"
      onPressed: () async {
        await ref.read(subscriptionProvider.notifier).undoConfirmPayment(sub.id);
      },
    ),
  ),
);
```

### Step 6: 프론트엔드 테스트

```dart
testWidgets('입금 확인 SnackBar 노출 후 되돌리기 1탭', (tester) async {
  // mockRepository.undoConfirmPayment 호출 확인
});
```

---

## 5. 검증 게이트 (verification.md)

PR 머지 전 필수:

```bash
# 백엔드
cd backend && uv run pytest tests/test_subscription_undo_confirm.py -v
# 전체 회귀
cd backend && uv run pytest --tb=short
# 마이그레이션
cd backend && uv run alembic upgrade head && uv run alembic downgrade -1 && uv run alembic upgrade head

# 프론트엔드
cd frontend && flutter analyze
cd frontend && flutter test
```

Red-Green-Refactor 사이클 입증: 새 테스트 추가 → 일단 fail (RED) → 구현 → pass (GREEN).

---

## 6. PR 정보

- 제목: `feat(subscription): 입금 확인 24h Undo 윈도우 #426`
- Closes: #426
- Lore-directive: `24시간 윈도우 + 첫 레슨 차감 발생 시 불가 정책 채택`
- Lore-rejected: `무제한 Undo — 회계 정합성 무너짐`
- Lore-rejected: `Undo 즉시 환불 처리 — 외부 송금 모델에서 환불은 앱 외부`

---

## 7. 위험 요소

| 위험 | 완화 |
|---|---|
| 자동 생성 스케줄 식별 (autogenerated flag) | 기존 Subscription → Lessons 관계 확인 필요 |
| RelationshipStatus 롤백의 "이전 상태" 추적 | `previousRelationStatus` 필드 없으면 기본 trialBooked |
| 동시성 (선생님이 동시에 클릭) | DB 트랜잭션 + paymentConfirmed 체크 |
