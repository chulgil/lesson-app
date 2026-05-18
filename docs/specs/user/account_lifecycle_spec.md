# 계정 라이프사이클 스펙 — 가입 / 삭제 / 부모 동의 / 감사 로그

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🔴 CRITICAL (출시 전 — PIPA/GDPR 준수)
> 관련: [privacy_policy.md](../subscription/privacy_policy.md), [user_master.md](./user_master.md), [signup_spec.md](../web/signup_spec.md), [slug_lifecycle_spec.md](./slug_lifecycle_spec.md)

---

## 0. 개요

PIPA(개인정보보호법) / GDPR 준수를 위한 4대 인프라:

1. **역할 분리 + 가입** — 선생님/학생/학부모 별도 계정, signup_source 메타
2. **계정 삭제 API** — 사용자 권리 (잊혀질 권리)
3. **14세 미만 부모 동의 흐름** — 법정대리인 동의 (PIPA §22조의2)
4. **감사 로그 (AuditLog)** — 침해 사고 대응 의무

---

## 0.5. 역할 분리

### 0.5.1 역할 (`User.role`)

| 역할 | 가입 진입 | 권한 |
|---|---|---|
| `teacher` | `lessonaza.app/signup?role=teacher` (웹) / 앱 가입 화면 | 본인 프로필 편집, 학생 관리, 휴강 공지 |
| `student` | `lessonaza.app/signup?role=student` (웹) / 앱 가입 화면 | 선생님 검색, 본인 레슨/연습 기록 |
| `parent` | `lessonaza.app/signup?role=parent` (Year 1: 학생 흐름과 동일) | 자녀 프로필 관리, 결제 |
| `academy_owner` | 운영자 수동 발급 (Year 1) | 학원 단위 관리 |

### 0.5.2 별도 계정 원칙 (SSO 3-tuple unique)

- M4 가입은 **SSO 전용** (Google + Kakao. Apple 은 M5)
- `auth_identities(provider, provider_user_id, role)` **3-tuple unique** 제약
- 같은 IdP 계정으로 **다른 역할 별도 User 가능** (예: 같은 구글 계정 → 선생님 User + 학부모 User)
- 같은 IdP 계정 + 같은 역할로 두 번 가입 시도 → 기존 계정 로그인으로 처리
- 역할 전환은 별도 흐름 (Year 2 백로그)
- 데이터 모델: `User.role` enum, 가입 후 변경 불가 (운영자 수동만)
- 다른 IdP 자동 연동 없음 — 명시적 `/settings/linked-accounts` 메뉴로만 연동 (탈취 위험 차단)

### 0.5.3 signup_source 메타

```python
class User(Base):
    signup_source = Column(String(20), default="app")  # "app" | "web"
```

- `"app"`: lesson-app 모바일 가입 화면 (M5 SSO 전환 후)
- `"web"`: lessonaza.app/signup 가입 폼 (M4 SSO)

사용 목적: 분석/이벤트 트래킹만. 인증/권한에 영향 없음. 가입 채널 무관 동일 계정 사용.

---

## 1. 현황 진단 (2026-05-18)

| 항목 | 상태 |
|------|------|
| 약관/개인정보처리방침 화면 | ✅ `terms_agreement_screen.dart` |
| 14세 미만 자녀 프로필 정책 | ✅ `user_master.md §1.4` |
| 14세 미만 단일 경로 (자녀 프로필) | ❌ 미구현 |
| 자녀 본인 계정 + 부모 동의 (B) | 🟡 Year 2 백로그 |
| 계정 삭제 API | ❌ 미구현 |
| AuditLog 테이블 | ❌ 없음 |
| 법률 검토 | ❌ 미진행 |
| 웹 가입 흐름 (SSO + role + signup_source) | 🟡 M4 (signup_spec) |
| SSO IdP 연동 (`auth_identities` 3-tuple unique) | 🟡 M4 (signup_spec §4.2, §9.3) |
| 약관 버전 기록 (`terms_versions`) | 🟡 M4 (signup_spec §7) |
| Slug 휴면/회수 정책 | 🟡 M4 (slug_lifecycle_spec) |

---

## 2. 계정 삭제 API

### 2.1 엔드포인트

```
DELETE /api/v1/users/me/data
```

### 2.2 요청

```json
{
  "confirmation": "DELETE",
  "reason": "string (optional)",
  "password_or_oauth_token": "..."
}
```

### 2.3 처리 흐름

```
1. 인증 재확인 (OAuth 재로그인 또는 패스워드)
2. 30일 grace period 설정 (User.deletion_requested_at)
3. 즉시: 로그아웃 + 모든 디바이스 세션 무효화
4. 30일 후 (배치): 영구 삭제 (cascade)
5. 30일 내 로그인 시도 → 복구 화면 노출 → 취소 가능
```

### 2.4 삭제 대상

| 대상 | 즉시 | 30일 후 | 보존 |
|------|------|---------|------|
| User 프로필 | 숨김 | 삭제 | — |
| 학생/레슨 데이터 | 비활성 | 삭제 | 익명화된 통계만 (집계용) |
| 결제/세금 기록 | — | 익명화 | 5년 (전자상거래법 §6) |
| AuditLog | — | — | 5년 (개인정보보호법 §29) |
| Hive 로컬 캐시 | 앱이 로그아웃 시 자동 초기화 | — | — |

### 2.5 복구

```
GET /api/v1/users/me/data/restore  # 30일 내, 인증 후
```

성공 시 `deletion_requested_at=null` 갱신, 정상 로그인 진행.

### 2.6 학원 소속 처리

학원 소유자(`role=academy_owner`)는 단독 삭제 불가:
1. 학원 데이터 이양 또는 학원 해산 절차 선행 필수
2. 강사 계정은 학원에서 분리 후 개인 계정으로 삭제 가능

---

## 3. 14세 미만 부모 동의 흐름

### 3.1 트리거 — 단일 경로 (자녀 프로필)

학생 회원가입 시 생년월일 입력 → 만 14세 미만 판정 → **자녀 프로필 경로 단일 안내**:

```
"14세 미만은 부모님 계정에 자녀 프로필로 추가됩니다.
 부모님이 가입 후 [자녀 추가] 메뉴를 사용해주세요."
  ↓
부모님 가입 화면으로 전환 (referrer = child birthday hint)
```

부모 계정에서 자녀 프로필 생성 시 PIPA §22조의2는 우회된다 — 자녀는 독립 계정 아닌 부모 소유 프로필이며 자녀 본인이 앱에 직접 데이터를 입력하지 않는다 (선생님·부모가 대신 기록).

### 3.2 부모 가입 후 자녀 추가 흐름

```
1. 부모 계정 생성 (만 14세 이상 본인 인증)
2. [내 학생 관리] → [자녀 프로필 추가]
3. 입력: 자녀 이름, 생년월일, 악기
4. 자녀 프로필 활성화 (부모 계정 종속)
   - 로그인 = 부모 계정으로만
   - 레슨 기록·노트는 부모가 열람/관리
```

### 3.3 만 14세 도달 시 전환 안내

매일 배치로 만 14세 도달 자녀 프로필 검색:
1. 부모 + 자녀에게 푸시 알림 — "자녀 본인 계정으로 전환할 수 있어요"
2. 자녀가 본인 계정 생성 후 데이터 이관 (부모 동의 1회)
3. 자녀 본인 계정 전환 후 부모는 보호자로 연결 유지 (열람 권한)

전환은 **선택**. 미전환 시 부모 프로필 계속 유지 가능.

### 3.4 `ParentalConsent` 테이블 (Year 2 대비)

현재 가입 흐름에서 사용 안 함. **Year 2에 "자녀 본인 계정" 경로 도입 시 활성화**.

```python
class ParentalConsent(Base):
    id: int
    child_user_id: int (FK)
    parent_email: str | None
    parent_phone: str | None
    consent_method: str  # "email" | "sms"
    consent_token_hash: str  # 매직 링크/코드 해시
    consented_at: datetime | None
    expires_at: datetime
    ip_address: str  # 동의 시 IP (증거 보존)
    user_agent: str
    revoked_at: datetime | None
```

테이블은 마이그레이션에 포함하되 §3.5 자녀 본인 전환 흐름에서만 사용. Year 1 가입에서는 레코드 생성 안 함.

### 3.5 Year 2 백로그 — 자녀 본인 계정 경로

시장 검증 후 검토. 도입 조건: 만 10~13세 자녀가 직접 앱 사용하고 싶다는 사용자 요청 누적 시.

```
[Year 2 도입 시 흐름]
1. 자녀 화면: 부모 이메일 OR 휴대폰 번호 입력
2. 시스템: 부모에게 동의 요청 발송
   - 이메일: 매직 링크 (24시간 유효)
   - SMS: 6자리 인증 코드 (10분 유효)
3. 부모: 링크/코드 클릭 → 동의 화면
   - 자녀 이름 확인
   - 수집 정보 안내
   - "동의합니다" 체크
4. 시스템: ParentalConsent 레코드 생성
5. 자녀 계정 활성화

[동의 철회 API]
DELETE /api/v1/parental-consents/{id}  # Year 2 활성화 시 노출
1. revoked_at 갱신
2. 자녀 계정 즉시 비활성 (30일 grace)
3. 자녀에게 푸시 알림
```

---

## 4. AuditLog 테이블

### 4.1 스키마

```python
class AuditLog(Base):
    id: int
    user_id: int | None  # 행위자 (시스템 작업은 null)
    target_user_id: int | None  # 대상자 (있는 경우)
    action: str  # 아래 §4.2 enum
    metadata: dict  # JSON
    ip_address: str
    user_agent: str
    created_at: datetime (index=True)
```

### 4.2 기록 대상 액션

| 카테고리 | 액션 |
|---------|------|
| 인증 | `login_success`, `login_failed`, `logout`, `oauth_link`, `oauth_unlink`, `password_reset` |
| 계정 | `account_deletion_requested`, `account_restored`, `account_deleted_permanent` |
| 권한 | `role_changed`, `permission_granted`, `permission_revoked` |
| 개인정보 | `pii_access` (조회), `pii_export`, `parental_consent_granted/revoked` |
| 결제 | `payment_method_added/removed`, `subscription_purchased/cancelled` |
| 보안 | `2fa_enabled/disabled`, `session_revoked`, `suspicious_activity_detected` |

### 4.3 보존 정책

- 보존 기간: **5년** (개인정보보호법 §29 안전성 확보조치)
- 저장소: 별도 DB 또는 append-only 테이블 (수정 불가)
- 백업: 주 1회 별도 스토리지 (S3 immutable bucket 권장)

### 4.4 접근 권한

| 역할 | 권한 |
|------|------|
| 사용자 본인 | 자기 `target_user_id` 로그만 조회 |
| 운영자 | 침해 사고 대응 시에만 (요청 로그도 AuditLog에 기록) |
| 자동 시스템 | 쓰기 전용 |

### 4.5 API

```
GET  /api/v1/users/me/audit-logs?since=2026-01-01  # 본인 로그 조회
POST /api/v1/admin/audit-logs/query                # 운영자 (감사 사유 필수)
```

---

## 5. 프론트엔드 UI

### 5.1 설정 → 계정 → 데이터 관리

```
┌─────────────────────────────────┐
│ 데이터 관리                      │
├─────────────────────────────────┤
│ ▸ 내 데이터 내보내기 (JSON)      │
│ ▸ 로그인 기록 보기               │
│ ▸ 부모 동의 관리 (자녀가 있을 시) │
│ ▸ 계정 삭제                      │  ← 빨간색
└─────────────────────────────────┘
```

### 5.2 계정 삭제 확인 다이얼로그

3단계 확인:
1. 결과 안내 (30일 후 영구 삭제, 학원 소속 시 차단 등)
2. 재인증 (OAuth 재로그인)
3. 텍스트 `DELETE` 직접 입력

---

## 6. 데이터 내보내기 (GDPR Article 20 — 데이터 이동권)

### 6.1 엔드포인트

```
POST /api/v1/users/me/data-export
GET  /api/v1/users/me/data-export/{job_id}
```

비동기 job. 완료 시 이메일로 다운로드 링크 (24시간 유효).

### 6.2 포함 데이터

- 프로필, 학생, 레슨, 노트, 연습 기록, 알림 이력, 결제 영수증
- JSON 형식 + 첨부 파일은 zip 묶음

---

## 7. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `accountDeletionTitle` | 계정 삭제 |
| `accountDeletionWarning` | 삭제 요청 후 30일 안에 로그인하면 계정을 복구할 수 있어요 |
| `accountDeletionConfirmInput` | "DELETE"를 입력하여 확인하세요 |
| `under14ChildProfileTitle` | 14세 미만은 부모님 계정에서 관리해요 |
| `under14ChildProfileBody` | 부모님이 가입하신 후 [자녀 추가] 메뉴로 추가해주세요 |
| `childAccountTransitionTitle` | 자녀 본인 계정으로 전환할 수 있어요 |
| `parentalConsentRequestTitle` | (Year 2) 부모님 동의가 필요해요 |
| `parentalConsentEmailBody` | (Year 2) 자녀가 Lessonaza에 가입하려고 합니다. 동의하시려면 아래 링크를 누르세요. |
| `dataExportTitle` | 내 데이터 내보내기 |
| `dataExportSuccess` | 다운로드 링크를 이메일로 보내드렸어요 |
| `auditLogTitle` | 로그인 기록 |

---

## 8. 법률 검토 체크리스트

| 항목 | 담당 | 상태 |
|------|------|------|
| IT 전문 변호사 검토 (50만원 예산) | 외부 | ❌ 출시 전 필수 |
| PIPA §22조의2 (만 14세 동의) | 본 스펙 §3 | ✅ 흐름 정의 |
| PIPA §15 (목적 외 이용 금지) | privacy_policy.md | ✅ |
| PIPA §29 (안전성 확보) | 본 스펙 §4 AuditLog | ✅ 흐름 정의 |
| GDPR Article 17 (잊혀질 권리) | 본 스펙 §2 | ✅ |
| GDPR Article 20 (데이터 이동권) | 본 스펙 §6 | ✅ |
| 전자상거래법 §6 (거래 기록 보존) | 본 스펙 §2.4 | ✅ |
| 개인정보 영향 평가 (PIA) | 외부 | ❌ 출시 후 |

---

## 9. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | 30일 grace period 채택 | 일반적 SaaS 관행, 실수 복구 가능성 |
| 2026-05-18 | 학원 소유자 단독 삭제 차단 | 학원 데이터 분쟁 방지 |
| 2026-05-18 | 자녀 프로필을 권장 경로(A)로 | 부모 동의 흐름 복잡도 회피 + PIPA 우회 효과 |
| 2026-05-18 | **단일 경로(자녀 프로필) — B/C 제거** | UX/기획 재검증: 가입 화면 A/B/C 분기는 14세 미만 사용자 100% 이탈. 90% 케이스(부모가 학생을 대신 관리)를 깔끔히 처리하고 자녀 본인 계정(B)은 시장 검증 후 Year 2 도입 |
| 2026-05-18 | ParentalConsent 테이블은 Year 2 대비 보존 | 마이그레이션 부담 < Year 2 재설계 부담. 가입 흐름에서만 분리 |
| 2026-05-18 | AuditLog 5년 보존 | 개인정보보호법 §29 + 분쟁 대응 충분 기간 |
| 2026-05-18 | 데이터 내보내기 비동기 잡 | 큰 데이터(수년치 레슨 노트) 대응 |

---

## 10. 관련 문서

- [privacy_policy.md](../subscription/privacy_policy.md) — 법적 고지 본문
- [terms_of_service.md](../subscription/terms_of_service.md) — 이용약관
- [user_master.md](./user_master.md) — 14세 미만 자녀 프로필 정책
- [account_recovery_spec.md](./account_recovery_spec.md) — 삭제와 구분되는 계정 복구
- [event_tracking_spec.md](../analytics/event_tracking_spec.md) — `account_deleted` 이벤트
- [signup_spec.md](../web/signup_spec.md) — 가입 흐름 (선생님/학생/학부모, 이메일 인증, 약관 버전)
- [slug_lifecycle_spec.md](./slug_lifecycle_spec.md) — 선생님 slug 휴면/회수 정책 (12mo + 1mo + 3mo cooldown)
