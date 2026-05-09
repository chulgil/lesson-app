# 계정 삭제 API + AuditLog 스펙

> Gap #2 | 우선순위: 🔴 CRITICAL | 예상: 1주

## 목적

GDPR/PIPA 법적 준수를 위한 계정 삭제 API 및 감사 로그 인프라 구축.

## 현재 상태

- 약관 동의 화면 존재 (terms_agreement_screen.dart)
- Student 모델에 birth_date, age_group 필드 존재
- DELETE /users/me 엔드포인트 없음
- AuditLog 테이블 없음

## 백엔드 구현

### 1. AuditLog 모델

`backend/app/models/audit_log.py` (신규):

```python
class AuditAction(str, enum.Enum):
    ACCOUNT_DELETE_REQUESTED = "account_delete_requested"
    ACCOUNT_DELETED = "account_deleted"
    DATA_EXPORT_REQUESTED = "data_export_requested"
    LOGIN = "login"
    LOGOUT = "logout"
    ROLE_CHANGED = "role_changed"
    SETTINGS_CHANGED = "settings_changed"

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    action: Mapped[str] = mapped_column(String(50), nullable=False)
    details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

### 2. 계정 삭제 엔드포인트

`backend/app/api/v1/users.py`에 추가:

```
DELETE /api/v1/users/me
```

처리 흐름:
1. 현재 사용자 확인 (JWT)
2. AuditLog 기록 (account_delete_requested)
3. User.is_active = False (소프트 삭제)
4. User.email → 해시 처리 (복구 불가)
5. 관련 데이터 소프트 삭제:
   - Teacher/Student 프로필 비활성화
   - OAuth 계정 삭제
   - DeviceToken 삭제
   - 토큰 블랙리스트에 모든 토큰 추가
6. 30일 후 하드 삭제 (별도 스케줄러, 이 PR 범위 밖)

응답: `204 No Content`

### 3. AuditLog 서비스

`backend/app/services/audit_log_service.py` (신규):

```python
async def log_action(
    db: AsyncSession,
    user_id: str,
    action: AuditAction,
    details: dict | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> AuditLog:
```

### 4. Alembic 마이그레이션

`audit_logs` 테이블 생성.

## 프론트엔드 구현

### 설정 > 계정 삭제 화면

`frontend/lib/features/settings/presentation/screens/account_deletion_screen.dart` (신규):

- "계정 삭제" 버튼 (빨간색)
- 확인 다이얼로그: "정말 삭제하시겠습니까? 30일 후 모든 데이터가 영구 삭제됩니다."
- "삭제" 확인 시 DELETE /api/v1/users/me 호출
- 성공 시 로컬 데이터 정리 + 로그인 화면으로 이동

### 설정 화면에 진입점 추가

`settings_screen.dart`에 "계정 삭제" 메뉴 항목 추가 (맨 하단, 빨간 텍스트).

## 수용 기준

- [ ] DELETE /api/v1/users/me 엔드포인트 동작
- [ ] AuditLog에 삭제 요청 기록
- [ ] 사용자 데이터 소프트 삭제 (is_active=False, email 해시)
- [ ] 프론트엔드 계정 삭제 화면 + 확인 다이얼로그
- [ ] 삭제 후 로그인 화면 이동

## 영향 파일

**백엔드:**
- `backend/app/models/audit_log.py` (신규)
- `backend/app/services/audit_log_service.py` (신규)
- `backend/app/api/v1/users.py` (DELETE 추가)
- `backend/app/models/__init__.py` (import 추가)
- `alembic/versions/` (마이그레이션)

**프론트엔드:**
- `frontend/lib/features/settings/presentation/screens/account_deletion_screen.dart` (신규)
- `frontend/lib/features/settings/presentation/screens/settings_screen.dart` (메뉴 추가)
