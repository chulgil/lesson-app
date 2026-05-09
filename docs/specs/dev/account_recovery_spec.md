# 계정 복구 + 세션 관리 스펙

> Gap #9 | 우선순위: 🟡 MEDIUM | 예상: 1주

## 목적

폰 분실 + OAuth 계정 잊음 시 영구 잠금 방지. 다중 기기 세션 관리.

## 현재 상태

- OAuth 전용 인증 (Google/Kakao/Apple)
- TokenBlacklist로 로그아웃 시 토큰 무효화
- 복구 코드/이메일 복구 없음
- 다중 기기 세션 관리 없음

## 백엔드 구현

### 1. RecoveryCode 모델

`backend/app/models/recovery.py` (신규):

```python
class RecoveryCode(Base):
    __tablename__ = "recovery_codes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

### 2. UserSession 모델

`backend/app/models/user_session.py` (신규):

```python
class UserSession(Base):
    __tablename__ = "user_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    device_name: Mapped[str | None] = mapped_column(String(200))
    device_type: Mapped[str | None] = mapped_column(String(50))  # ios, android, web
    ip_address: Mapped[str | None] = mapped_column(String(45))
    last_active_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

### 3. API 엔드포인트

```
POST   /api/v1/auth/recovery-codes/generate    → 복구 코드 10개 생성
POST   /api/v1/auth/recovery-codes/verify       → 복구 코드로 인증
GET    /api/v1/auth/sessions                     → 활성 세션 목록
DELETE /api/v1/auth/sessions/{session_id}        → 특정 세션 로그아웃
DELETE /api/v1/auth/sessions                     → 모든 세션 로그아웃 (현재 제외)
```

### 4. 복구 코드 서비스

`backend/app/services/recovery_service.py` (신규):

- `generate_codes(user_id)`: 10개 랜덤 코드 생성, bcrypt 해시 저장, 평문 반환
- `verify_code(user_id, code)`: 코드 검증, 사용 처리, JWT 발급

### 5. 세션 서비스

`backend/app/services/session_service.py` (신규):

- `create_session(user_id, device_info)`: 로그인 시 세션 생성
- `list_sessions(user_id)`: 활성 세션 목록
- `revoke_session(session_id)`: 특정 세션 무효화
- `revoke_all_except(user_id, current_session_id)`: 다른 세션 모두 무효화

## 수용 기준

- [ ] RecoveryCode, UserSession 모델 + 마이그레이션
- [ ] 복구 코드 생성/검증 API
- [ ] 세션 목록/삭제 API
- [ ] 로그인 시 세션 자동 생성

## 영향 파일

- `backend/app/models/recovery.py` (신규)
- `backend/app/models/user_session.py` (신규)
- `backend/app/services/recovery_service.py` (신규)
- `backend/app/services/session_service.py` (신규)
- `backend/app/api/v1/auth.py` (엔드포인트 추가)
- `backend/app/models/__init__.py`
- `alembic/versions/` (마이그레이션)
