# 선생님 추천 루프 스펙

> Gap #4 | 우선순위: 🟠 HIGH | 예상: 1주

## 목적

선생님→선생님 추천 경로를 열어 바이럴 계수 확대.

## 현재 상태

- 초대 시스템: 선생님→학생/학부모만
- `referral`, `TeacherReferral` 검색 → 0건
- 추천 보상 시스템 없음

## 백엔드 구현

### 1. TeacherReferral 모델

`backend/app/models/referral.py` (신규):

```python
class ReferralStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    REWARDED = "rewarded"
    EXPIRED = "expired"

class TeacherReferral(Base):
    __tablename__ = "teacher_referrals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    referrer_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id"))
    referred_teacher_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("teachers.id"))
    referral_code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=ReferralStatus.PENDING)
    reward_type: Mapped[str | None] = mapped_column(String(50))  # pro_1month, etc.
    rewarded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

### 2. Teacher 모델 필드 추가

`backend/app/models/teacher.py`에 추가:

```python
referral_code: Mapped[str | None] = mapped_column(String(20), unique=True)
```

### 3. API 엔드포인트

```
GET    /api/v1/referrals/my-code         → 내 추천 코드 조회 (없으면 자동 생성)
GET    /api/v1/referrals/stats           → 추천 통계 (총 추천, 완료, 보상)
POST   /api/v1/referrals/apply           → 추천 코드 적용 (가입 시)
GET    /api/v1/referrals/history         → 추천 이력 목록
```

### 4. 추천 서비스

`backend/app/services/referral_service.py` (신규):

- `get_or_create_referral_code(teacher_id)`: 추천 코드 조회/생성
- `apply_referral_code(new_teacher_id, code)`: 코드 적용
- `check_and_reward(referrer_id)`: 5명 추천 달성 시 Pro 1개월 보상
- `get_referral_stats(teacher_id)`: 통계 조회

### 5. 보상 정책

| 추천 수 | 보상 |
|---------|------|
| 1명 | 감사 알림 |
| 3명 | Pro 2주 무료 |
| 5명 | Pro 1개월 무료 |
| 10명 | Pro 3개월 무료 |

## 수용 기준

- [ ] TeacherReferral 모델 + 마이그레이션
- [ ] Teacher.referral_code 필드 추가
- [ ] 추천 코드 CRUD API
- [ ] 보상 정책 로직

## 영향 파일

- `backend/app/models/referral.py` (신규)
- `backend/app/models/teacher.py` (필드 추가)
- `backend/app/services/referral_service.py` (신규)
- `backend/app/api/v1/referrals.py` (신규)
- `backend/app/models/__init__.py`
- `alembic/versions/` (마이그레이션)
