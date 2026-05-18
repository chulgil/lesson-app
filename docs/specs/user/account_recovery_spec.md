# 계정 복구 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟡 MEDIUM (출시 후 6개월)
> 관련: [account_lifecycle_spec.md](./account_lifecycle_spec.md), [auth_master.md](./auth_master.md)

---

## 0. 개요

OAuth (카카오/구글/Apple) 로그인 차단 시 복구 경로. 단일 OAuth 의존 → 계정 잠금 = 전체 데이터 손실 위험.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| 1차 인증 (OAuth) | ✅ 카카오/구글/Apple |
| 복구 이메일 등록 | ❌ |
| 복구 전화번호 | ❌ |
| 백업 코드 (Pro 전용) | ❌ |
| 세션 관리 화면 | ❌ |
| 의심 로그인 알림 | ❌ |

---

## 2. 복구 경로 (점진 도입)

### 2.1 경로 비교

| 경로 | 사용 시점 | 신뢰도 | 도입 |
|------|----------|--------|------|
| 1. 복구 이메일 (매직 링크) | OAuth 잠김, 이메일 접근 가능 | 🟢 높음 | **Phase 1 (출시 시)** — 일반 사용자 90% 케이스 해결 |
| 2. 백업 코드 (10개 일회용) | 이메일도 잠김, Pro 사용자 | 🟢 높음 | **Phase 2 (Pro 전용)** — 무료 사용자 노출 X |
| 3. 신분증 + 고객지원 (수동) | 1, 2 모두 불가 | 🟡 중간 (운영 부담) | Phase 1 (수동 운영) |

**점진 도입 원칙**: 가입 시점에 복잡한 보안 설정을 강제하면 이탈한다. 매직 링크 1단계로 90% 케이스를 해결하고, 백업 코드는 Pro 사용자(이미 결제 동기 있는 사람)에게만 노출.

---

## 3. 복구 이메일 (1차)

### 3.1 등록 — 선택 (Skip 가능)

가입 직후 안내 화면:
```
회원가입 완료 → "복구 이메일 등록 (선택)" 화면
  ↓
[건너뛰기] OR [이메일 입력]
  ↓ (입력 시)
이메일 입력 → 인증 링크 발송 → 클릭 확인 → 등록 완료
```

OAuth로 받은 이메일과 **다른** 이메일을 강력 권장 (카카오 잠기면 카카오 이메일도 동시에 못 받음).

### 3.1.1 미설정 시 보안 뱃지

복구 이메일 미등록 시 설정 → 보안 화면 상단에 🟡 보안 뱃지 표시:
```
"복구 이메일이 없어요. 로그인 차단 시 계정 복구가 어려울 수 있어요."
[지금 설정하기]
```

뱃지는 사용자 인지 부담 최소화 — 잠금 시점이 아닌 평시에 점진적으로 유도.

### 3.2 복구 흐름

```
로그인 화면 → "다른 방법으로 로그인" → 이메일 입력
  ↓
15분 유효 매직 링크 발송
  ↓
링크 클릭 → 임시 세션 발급 (24시간)
  ↓
이 세션에서 OAuth 연동 변경 가능 (예: 카카오 → 구글)
```

### 3.3 보안

- 매직 링크 토큰: 256-bit, 단일 사용, 15분 만료
- 24시간 임시 세션: 일반 작업 가능, 결제는 OAuth 재인증 필요
- 발송 횟수 제한: 동일 이메일 5분에 3회, 일일 10회

---

## 4. 백업 코드 (2차) — Pro 전용 기능

> Phase 2 — Pro 사용자에게만 노출. 무료 사용자는 매직 링크 + 신분증 경로로 충분 (잠금 사용자 0.5% 이하 가정).

### 4.1 생성

설정 → 보안 → "백업 코드 받기" (Pro 사용자만 메뉴 노출):
- 10개 일회용 코드 (`XXXX-YYYY-ZZZZ` 형식, 12자리)
- 화면 캡처 + PDF 다운로드 제공
- 한 번 표시 후 다시 보기 불가 (재생성 가능)

### 4.2 저장

```python
class BackupCode(Base):
    id: int
    user_id: int (FK User)
    code_hash: str  # bcrypt(code)
    used: bool = False
    used_at: datetime | None
    created_at: datetime
```

코드 자체는 저장하지 않음 — 해시만. 재발급 시 기존 미사용 코드 무효화.

### 4.3 사용 흐름

```
로그인 화면 → "백업 코드로 로그인" → 이메일 + 코드 입력
  ↓
백엔드: bcrypt 검증 → 매치 시 used=True 표시 → 임시 세션 발급
  ↓
3개 미만 남으면 알림 "백업 코드 3개 남았어요. 재발급하세요"
```

### 4.4 보안

- bcrypt cost 12
- 무차별 대입 방지: 동일 이메일 5분에 5회 실패 시 30분 차단
- 사용 시 이메일 알림 (의심 로그인 감지)

---

## 5. 신분증 복구 (3차)

### 5.1 트리거

1, 2 모두 불가 + 사용자가 고객지원에 요청.

### 5.2 절차

```
1. 사용자: 고객지원 이메일 → 계정 복구 신청 + 신분증 사진 (앞면)
2. 운영자: 가입 시 입력한 이름/생년월일과 대조
3. 일치하면: 임시 매직 링크 발송 (1회용, 1시간 유효)
4. 사용자: 로그인 후 OAuth 재연동
5. 운영자: 24시간 내 신분증 이미지 삭제
```

### 5.3 보안 / 운영

- 운영자 접근은 AuditLog 기록 (`pii_access`)
- 신분증 사본 24시간 후 자동 삭제 (S3 lifecycle)
- 결제 변경은 추가 인증 (휴대폰 SMS)

---

## 6. 세션 관리

### 6.1 활성 세션 화면

설정 → 보안 → "내 기기 및 세션":

```
┌──────────────────────────────────┐
│ 활성 세션 (3대)                    │
├──────────────────────────────────┤
│ 📱 iPhone 15 — 서울 (현재)         │
│    마지막 활동: 방금 전             │
│                                  │
│ 📱 iPad Air — 서울                │
│    마지막 활동: 2시간 전 [로그아웃]  │
│                                  │
│ 💻 Chrome on macOS — 부산         │
│    마지막 활동: 어제 [로그아웃]      │
└──────────────────────────────────┘

[모든 다른 세션 로그아웃]
```

### 6.2 세션 엔티티

```python
class Session(Base):
    id: int
    user_id: int (FK User)
    session_token_hash: str  # bcrypt
    device_name: str  # "iPhone 15"
    user_agent: str
    ip_address: str
    location_city: str | None  # GeoIP
    created_at: datetime
    last_active_at: datetime  # 세션별 마지막 활동 (User.last_active_at과 별개)
    revoked_at: datetime | None
```

> **`last_active_at` 명명 주의**: 본 스펙의 `Session.last_active_at`은 디바이스 세션별 활동 시각. 비활성 사용자 감지에 쓰이는 `User.last_active_at`은 [reengagement_spec.md §3.1](../notification/reengagement_spec.md)이 SSOT. 두 필드는 다른 엔티티에 속하며 갱신 규칙도 다르다 (Session은 모든 요청 시 갱신, User는 의미 있는 행동만).

### 6.3 의심 로그인 알림

조건 (OR):
- 새 국가/도시에서 로그인
- 마지막 활동 30일+ 후 로그인
- 동시 활성 세션 5개 초과

알림: 이메일 + 푸시 — "낯선 곳에서 로그인이 감지됐어요. 본인이 아니면 즉시 로그아웃하세요."

---

## 7. 백엔드 API

```
POST /api/v1/auth/recover/email            # 매직 링크 발송
POST /api/v1/auth/recover/email/verify     # 토큰 검증 + 임시 세션 발급
POST /api/v1/auth/backup-codes/generate    # 백업 코드 10개 생성
POST /api/v1/auth/backup-codes/verify      # 백업 코드 로그인
GET  /api/v1/auth/sessions                 # 활성 세션 목록
POST /api/v1/auth/sessions/{id}/revoke     # 특정 세션 로그아웃
POST /api/v1/auth/sessions/revoke-others   # 현재 외 모두 로그아웃
PUT  /api/v1/users/me/recovery-email       # 복구 이메일 변경
```

---

## 8. AuditLog 연동

`account_lifecycle_spec.md` AuditLog에 다음 액션 추가:

- `recovery_email_set` / `recovery_email_changed`
- `backup_codes_generated` / `backup_code_used`
- `oauth_relinked` (복구 후 OAuth 재연동)
- `session_revoked` / `suspicious_login_detected`

---

## 9. UI

### 9.1 보안 설정 화면

```
보안
├─ 복구 이메일      example@email.com  [변경]   (또는 🟡 "설정 권장")
├─ 백업 코드        Pro 전용 — 7개 남음 [재발급]
├─ 활성 세션        3대 활성          [관리]
└─ 로그인 알림      이메일 + 푸시      [설정]
```

무료 사용자는 백업 코드 메뉴를 Pro 업셀 카드로 노출:
```
🔒 백업 코드 (Pro 전용)
이메일도 잠겼을 때를 대비한 일회용 코드
[Pro 업그레이드]
```

### 9.2 첫 가입 가이드 — 선택형

```
회원가입 완료
  ↓
복구 설정 안내 (skip 가능)
  ↓
1) 복구 이메일 등록 (선택, 권장)
   - [지금 설정] OR [나중에]
   - "나중에" 선택 시 보안 뱃지로 평시 유도 (§3.1.1)
  ↓
시작
```

목표: 가입 후 첫 실행 시간 30초 이내. 보안 설정은 평시에 점진적으로.

---

## 10. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `recoveryEmailTitle` | 복구 이메일 |
| `recoveryEmailHint` | 로그인할 수 없을 때 사용할 이메일 |
| `backupCodesTitle` | 백업 코드 |
| `backupCodesSubtitle` | 이메일도 잠겼을 때 사용 |
| `backupCodesWarning` | 이 코드를 다른 사람이 보지 못하게 보관하세요 |
| `sessionsTitle` | 내 기기 및 세션 |
| `sessionRevokeOthers` | 현재 외 모두 로그아웃 |
| `suspiciousLoginTitle` | 낯선 곳에서 로그인 감지 |
| `suspiciousLoginBody` | {location}에서 {device}로 로그인됐어요. 본인이 아니면 즉시 로그아웃하세요. |

---

## 11. 검증

| 시점 | 검증 |
|------|------|
| QA | 카카오 차단 → 이메일 복구 시뮬레이션 |
| QA | 백업 코드 10개 모두 사용 후 11번째 거부 확인 |
| 출시 후 1개월 | 복구 요청 비율 추적 (목표: <0.5%) |
| 분기 | 신분증 복구 운영 시간 측정 (목표: 평균 24시간 이내) |

---

## 12. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | 복구 이메일 필수 등록 (초안) | 단일 OAuth 의존은 잠금 시 데이터 손실 |
| 2026-05-18 | **복구 이메일 선택으로 변경 + 백업 코드 Pro 전용** | UX/기획 재검증: 가입 직후 강제 보안 설정은 이탈 유발. 일반 잠금 케이스는 매직 링크로 90% 해결됨. 백업 코드는 결제 동기 있는 Pro 사용자에게만 가치 있음. 점진 도입으로 가입 마찰 최소화 |
| 2026-05-18 | 백업 코드 10개 일회용 | 산업 표준 (Google/GitHub) |
| 2026-05-18 | 신분증 복구는 수동 (자동 X) | OCR 신뢰도 부족 + 운영 부담 < 사고 비용 |
| 2026-05-18 | 매직 링크 15분 만료 | 짧을수록 안전, 너무 짧으면 사용성 X |
| 2026-05-18 | 의심 로그인 정의 = 새 국가/30일+/5+세션 | 일반 사용자 false-positive 최소 |

---

## 13. 관련 문서

- [account_lifecycle_spec.md](./account_lifecycle_spec.md) — AuditLog
- [auth_master.md](./auth_master.md) — OAuth 흐름
- [customer_support_spec.md](../support/customer_support_spec.md) — 신분증 복구 운영
