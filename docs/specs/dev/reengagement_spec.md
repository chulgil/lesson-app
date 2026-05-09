# 리인게이지먼트 스펙

> Gap #1 | 우선순위: 🔴 CRITICAL | 예상: 1주

## 목적

비활성 사용자 감지 + 재참여 알림 발송으로 D7/D30 리텐션 개선.

## 현재 상태

- User 모델에 `last_active_at` 없음
- 52개 알림 타입 중 비활성 사용자 타겟 0개
- InactivityDetector 없음

## 백엔드 구현

### 1. User 모델 필드 추가

`backend/app/models/user.py`에 추가:

```python
last_active_at: Mapped[datetime | None] = mapped_column(
    DateTime(timezone=True), nullable=True
)
```

### 2. 활동 추적 미들웨어

`backend/app/core/middleware.py`에 추가:

인증된 요청마다 `User.last_active_at = utcnow()` 업데이트.
성능: 매 요청이 아닌 마지막 업데이트 후 5분 이상 경과 시만 갱신.

```python
async def update_last_active(request: Request, call_next):
    response = await call_next(request)
    if hasattr(request.state, 'current_user'):
        user = request.state.current_user
        if user.last_active_at is None or (utcnow() - user.last_active_at).seconds > 300:
            # 비동기 백그라운드 업데이트
            await update_user_activity(user.id)
    return response
```

### 3. 비활성 사용자 감지 서비스

`backend/app/services/reengagement_service.py` (신규):

```python
async def find_inactive_users(db: AsyncSession, days: int) -> list[User]:
    """last_active_at이 N일 이전인 사용자 조회"""

async def send_reengagement_notifications(db: AsyncSession):
    """비활성 사용자에게 알림 발송
    - 7일: '이번 주 레슨을 정리해보세요'
    - 14일: '학생들이 기다리고 있어요'
    - 30일: '복귀 혜택을 확인하세요'
    """
```

### 4. 알림 타입 추가

기존 알림 시스템에 3개 타입 추가:
- `inactivity_reminder_7d`
- `inactivity_reminder_14d`
- `win_back_offer_30d`

### 5. APScheduler 작업

`backend/app/core/scheduler.py`에 일일 리인게이지먼트 체크 작업 등록:
- 매일 09:00 UTC 실행
- `send_reengagement_notifications()` 호출

### 6. Alembic 마이그레이션

`users` 테이블에 `last_active_at` 컬럼 추가.

## 수용 기준

- [ ] User.last_active_at 필드 추가 + 마이그레이션
- [ ] 인증 요청 시 자동 갱신 (5분 간격)
- [ ] 비활성 사용자 조회 서비스
- [ ] 리인게이지먼트 알림 3종 정의
- [ ] APScheduler 일일 작업 등록

## 영향 파일

- `backend/app/models/user.py` (필드 추가)
- `backend/app/services/reengagement_service.py` (신규)
- `backend/app/core/scheduler.py` (작업 추가)
- `backend/app/models/__init__.py`
- `alembic/versions/` (마이그레이션)
