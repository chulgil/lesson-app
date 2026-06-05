# academy/context_toggle_spec — 학원장 ↔ 강사 컨텍스트 토글

> 기준일: 2026-05-21
> 경로: `console.lessonaza.app` (학원장 모드) ↔ `lessonaza.app` 앱 (강사 모드)
> 마일스톤: AC-M2 (토글 UX·세션 격리·권한 매트릭스 확정)
> 선행: [README.md](README.md), [console_overview_spec.md](console_overview_spec.md) §6, [teacher_management_spec.md](teacher_management_spec.md) §8, [../auth/api_contract.md](../auth/api_contract.md), 옵시디언 `21-academy-요구사항.md` §3.1 R-AO-1/R-AO-3, FR-ACAPP-6

## 1. 범위

학원장 겸직 강사(학원장 본인이 학생도 가르치는 경우) 가 **학원장 모드 (콘솔)** 와 **내 강사 모드 (lesson-app)** 사이를 전환할 때의:

- 토글 UX (트리거·위치·확인 모달)
- JWT scope / active_context 재발급 흐름
- 권한 매트릭스 (모드별 허용·차단 엔드포인트)
- 세션 격리 원칙 (한 모드의 캐시·UI 잔재가 다른 모드에 보이지 않도록)
- 실수 방지 가드 (자동 권한 승격 금지)

본 스펙은 `console_overview_spec.md §6` 의 모델·UX 요약을 확장한다. 두 문서 차이:

| 문서 | 다루는 범위 |
|---|---|
| `console_overview_spec.md §6` | 토글의 존재·모델·기본 UX (요약) |
| `context_toggle_spec.md` (본 스펙) | 권한 매트릭스 전체·세션 격리·엣지 케이스·감사 |

## 2. 사용자 / 시나리오

### 2.1 컨텍스트 보유 패턴

| 패턴 | User.role | AcademyMember 행 | 토글 필요 |
|---|---|---|---|
| 일반 학원장 (운영만) | `academy_owner` | (academy_id, role=owner) 1행 | X — 콘솔만 사용 |
| 학원장 겸직 강사 | `academy_owner` | (academy_id, role=owner) + (academy_id, role=teacher) 2행 | **O — 본 스펙 대상** |
| 일반 강사 | `teacher` | (academy_id, role=teacher) 1행 | X — lesson-app 만 사용 |
| 학원 무소속 강사 | `teacher` | AcademyMember 행 없음 | X — lesson-app 만 사용 |

### 2.2 토글 트리거 시나리오

1. **콘솔에서 강사 모드로**: 학원장이 본인 학생의 레슨 노트 작성하러 가야 함
2. **lesson-app 에서 콘솔로**: 강사 모드에서 학생 추가 매칭 / 정산 확인 / 공지 발송 필요
3. **세션 만료 후 복귀**: 4시간 무활동 후 재로그인 — 직전 active_context 유지

## 3. 데이터 모델

### 3.1 JWT 페이로드

```json
{
  "user_id": 1,
  "active_context": "academy_owner",
  "academy_id": 42,
  "teacher_id": null,
  "exp": 1716268800,
  "iat": 1716254400
}
```

`active_context` 값:
- `"academy_owner"`: 콘솔 메뉴 접근, 학생 노트·녹음 차단
- `"teacher"`: lesson-app 풀 기능, 콘솔 메뉴 차단
- `"student"` / `"parent"`: 본 스펙 미적용

### 3.2 토글 가능 조건 (Backend 검증)

```python
def can_switch_context(user_id: int, target_context: str, academy_id: int) -> bool:
    """
    user 가 (academy_id, target_context) 권한을 보유한 AcademyMember 행을 가지는가?
    """
    role_map = {"academy_owner": "owner", "teacher": "teacher"}
    return AcademyMember.exists(
        user_id=user_id,
        academy_id=academy_id,
        role=role_map[target_context],
        access_revoked_at=None,
    )
```

### 3.3 ContextSwitchLog (감사용 — 신설)

```python
class ContextSwitchLog(Base):
    """학원장 ↔ 강사 모드 전환 감사. 노트 일시 접근 (R-AO-23) 의 사전 검증용."""
    id = Column(PK)
    user_id = Column(FK users)
    academy_id = Column(FK academies)
    from_context = Column(Enum("academy_owner", "teacher"))
    to_context = Column(Enum("academy_owner", "teacher"))
    switched_at = Column(DateTime, default=func.now())
    ip = Column(String(45))
    user_agent = Column(String(500))
    triggered_by = Column(Enum("user", "session_resume"), default="user")
```

조회 권한: 본인 + 운영자 어드민만. 학원장이 자기 자신 로그 조회 가능 (투명성).

## 4. 토글 API

### 4.1 컨텍스트 전환

```
POST /api/v1/auth/context/switch
Authorization: Bearer <current_jwt>
Content-Type: application/json

{
  "target_context": "teacher",   // or "academy_owner"
  "academy_id": 42
}
```

성공 응답:
```json
{
  "access_token": "<new_jwt>",
  "active_context": "teacher",
  "academy_id": 42,
  "teacher_id": 7,
  "redirect_url": "https://lessonaza.app/today"   // 또는 console URL
}
```

실패 응답 (권한 없음):
```json
{
  "error": "FORBIDDEN_CONTEXT_SWITCH",
  "message": "해당 학원의 강사 권한이 없습니다.",
  "available_contexts": ["academy_owner"]
}
```

### 4.2 현재 활성 컨텍스트 조회

```
GET /api/v1/auth/context
→ {
  "user_id": 1,
  "active_context": "academy_owner",
  "academy_id": 42,
  "available_contexts": [
    {"context": "academy_owner", "academy_id": 42, "label": "강남리듬 학원장"},
    {"context": "teacher",       "academy_id": 42, "label": "강남리듬 강사"}
  ]
}
```

프런트는 이 응답으로 헤더 토글 UI 의 표시 여부와 옵션 라벨을 결정.

## 5. UX

### 5.1 콘솔 → lesson-app 전환

```
┌─────────────────────────────────────────────────┐
│ 강남리듬 ▼   👤 김원장 [학원장 모드 ▼]  🔔  ⚙️ │
│                       └─ 학원장 모드           │
│                       └─ 내 강사 모드로 전환  │   ← 클릭
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 강사 모드로 전환하시겠습니까?                   │
│                                                  │
│ • 학원 운영 메뉴는 보이지 않습니다.             │
│ • 본인이 가르치는 학생의 레슨 노트·녹음에        │
│   접근할 수 있습니다.                            │
│ • 학생 개별 정보 접근은 감사 로그에 기록됩니다. │
│                                                  │
│         [취소]   [강사 모드로 전환]              │
└─────────────────────────────────────────────────┘
```

확인 클릭 → POST `/api/v1/auth/context/switch` → 새 JWT 수신 → SessionStorage 갱신 → `https://lessonaza.app/today` 로 redirect.

### 5.2 lesson-app → 콘솔 전환

```
lesson-app 상단 더 보기 메뉴 (학원장 겸직만 표시):
┌─────────────────────┐
│ 내 강사 모드        │
├─────────────────────┤
│ 학원장 모드로 전환 │ ← 클릭
└─────────────────────┘
```

확인 모달 → POST `/api/v1/auth/context/switch` → 새 JWT → 콘솔 URL deep link.

### 5.3 UX 가드

- **명시적 클릭 필수** — 자동 권한 승격 금지 (실수 방지)
- **확인 모달 의무** — "전환" 버튼이 즉시 active 되지 않도록 1초 대기 + 모드 차이 안내 (특히 강사 → 학원장은 학원 운영 권한 부여라 신중)
- **현재 모드 시각 표시** — 헤더 컬러 + 라벨 (학원장 모드: navy / 강사 모드: green) 로 의도치 않은 행동 예방
- **딥링크 보호** — 콘솔 URL 에 강사 모드 JWT 로 직접 접근 시 자동 로그인 페이지 → 모드 전환 안내

## 6. 권한 매트릭스

### 6.1 active_context = "academy_owner" (콘솔)

| 카테고리 | 허용 | 차단 |
|---|---|---|
| 학원 운영 | `/api/v1/academies/{id}/*` | — |
| 강사 관리 | `/api/v1/academies/{id}/teachers/*` | — |
| 학생 집계 | `/api/v1/academies/{id}/students/*` (집계만) | — |
| 청구·정산 | `/api/v1/academies/{id}/billing/*`, `/settlement/*` | — |
| 통계 | `/api/v1/academies/{id}/stats/*` | — |
| 학생 노트 | — | `GET /students/{id}/notes` (FORBIDDEN_ACADEMY_OWNER_SCOPE) |
| 학생 녹음 | — | `GET /students/{id}/recordings` |
| 레슨 노트 | — | `GET /lessons/{id}/notes` |
| 연습 기록 | — | `GET /practice-logs/{user_id}` |
| 일시 접근 | 2인 동의 + 90일 ([student_management_spec.md](student_management_spec.md)) | 기본 차단 |

### 6.2 active_context = "teacher" (lesson-app)

| 카테고리 | 허용 | 차단 |
|---|---|---|
| 본인 학생 | `/api/v1/teachers/{me}/students/*` | 타 강사 학생 |
| 본인 레슨 | `/api/v1/teachers/{me}/lessons/*` | 타 강사 레슨 |
| 본인 노트·녹음 | `/api/v1/lessons/{id}/notes` (본인 담당만) | 타 강사 레슨 노트 |
| 학원 정보 (읽기) | `/api/v1/academies/{id}` (소속 학원) | 다른 학원 |
| 강사 페이 정산 (본인) | `/api/v1/academies/{id}/teachers/{me}/payouts` | 타 강사 페이 |
| 학원 운영 | — | `/api/v1/academies/{id}/students/*` (집계) |
| 강사 초대 | — | `/api/v1/academies/{id}/teachers/invite` |
| 청구·정산 발행 | — | `/api/v1/academies/{id}/billing/*` |
| 공지 발송 | — | `/api/v1/academies/{id}/announcements` (학원장 전용) |

### 6.3 차단 응답 표준

```json
{
  "error": "FORBIDDEN_ACADEMY_OWNER_SCOPE",  // 학원장 모드에서 학생 개별 접근 차단
  "message": "학원장은 학생 개별 진도/노트에 접근할 수 없습니다.",
  "audit_id": "audit_2026_05_21_abc123",
  "remediation": "노트 일시 접근을 신청하려면 /students/{id}/access-request 사용"
}

{
  "error": "FORBIDDEN_TEACHER_SCOPE",        // 강사 모드에서 학원 운영 접근 차단
  "message": "강사는 학원 운영 메뉴에 접근할 수 없습니다.",
  "audit_id": "...",
  "remediation": "학원장 모드로 전환 후 다시 시도하세요."
}

{
  "error": "FORBIDDEN_NOT_YOUR_STUDENT",     // 강사 모드 + 본인 매칭이 아닌 학생 접근
  "message": "본인이 담당하지 않는 학생입니다.",
  "audit_id": "...",
  "remediation": "학원장에게 매칭을 요청하거나, 학원장 모드로 전환 후 다시 시도하세요."
}
```

모든 차단 호출은 `AuditLog` 기록 (user_id, active_context, endpoint, target_resource_id, timestamp).

## 7. 세션 격리

### 7.1 격리 원칙

- **JWT 분리**: 토글 시 이전 JWT 즉시 만료 (서버 측 revocation list), 새 JWT 1개만 유효
- **클라이언트 캐시 분리**: 콘솔과 lesson-app 은 별도 도메인 → 쿠키·LocalStorage 자동 분리
- **인메모리 상태 초기화**: 토글 redirect 후 새 페이지 로드 — Riverpod/Provider 캐시 자동 소멸
- **알림 채널 분리**: active_context 별로 푸시 알림 토큰 분리 (학원장 모드 알림이 강사 모드 화면에 안 보이도록)

### 7.2 동시 세션 정책

같은 user 가 두 모드에 **동시 로그인 금지** — 토글 시 이전 모드 JWT 강제 만료.

이유:
- 실수로 학원장 모드 창에서 학생 노트 조회 시도 → 차단되지만 감사 로그 누적
- 두 모드 동시 운영은 사용자 혼란 야기 (어느 창에서 무엇을 했는지)

예외: 학원 2개 이상 소유 학원장 — 학원별로 별도 세션 허용 (academy_id 가 다르면 다른 컨텍스트).

### 7.3 토글 직후 알림

```
┌─────────────────────────────────────────────────┐
│ ✓ 강사 모드로 전환되었습니다.                   │
│   본인이 담당하는 학생만 조회됩니다.            │
└─────────────────────────────────────────────────┘
```

3초 자동 dismiss, dismiss 후 일반 lesson-app 홈으로 진입.

## 8. 엣지 케이스

### 8.1 학원장 권한 상실 (퇴직·해고)

- `AcademyMember.role=owner` 행이 `access_revoked_at` 설정됨
- 다음 토글 시 `available_contexts` 에서 `academy_owner` 제거
- 이미 발급된 학원장 JWT 는 revocation list 에 추가 (즉시 만료)

### 8.2 강사 자격 박탈 (학원장이 본인 강사 자격 제거)

희귀 케이스이지만 가능: 학원장이 본인을 강사 역할에서 제외 → AcademyMember role=teacher 행 alumni 전환.
- 이후 `available_contexts` 에 teacher 미포함
- 토글 시도 시 403 + "강사 자격이 없습니다"

### 8.3 학원 2개 이상 소유

- `GET /api/v1/auth/context` 응답에 `available_contexts` 배열로 각 학원의 owner/teacher 행 모두 반환
- 콘솔 헤더 토글 메뉴에 학원별로 그룹핑
- JWT 의 `academy_id` 는 항상 활성 학원 1개만 — 학원 간 전환도 같은 API 사용

### 8.4 세션 만료 후 복귀

- 4시간 무활동 → 401 → 로그인 페이지
- 재로그인 시 직전 `active_context` 자동 복원 (편의)
- 직전 컨텍스트 권한이 그동안 박탈됐으면 기본 컨텍스트 (`academy_owner` 우선) 로 fallback + 안내

## 9. 감사 (AuditLog 통합)

| 이벤트 | 기록 위치 | 보존 |
|---|---|---|
| 컨텍스트 전환 | `ContextSwitchLog` (본 스펙 §3.3) | 영구 (학원 운영 분쟁 증거) |
| 권한 차단 응답 | `AuditLog` | 1년 |
| 노트 일시 접근 신청·승인·회수 | `AuditLog` ([student_management_spec.md](student_management_spec.md)) | 영구 |

학원장은 본인 `ContextSwitchLog` 조회 가능. 운영자 어드민은 분쟁 시 전체 조회.

## 10. 테스트 시나리오

| ID | 케이스 | 기대 |
|---|---|---|
| CT-01 | 학원장만 보유 user 가 토글 메뉴 호출 | 메뉴 미표시 (`available_contexts` 1개) |
| CT-02 | 학원장 겸직 강사 → 강사 모드 토글 → 학생 노트 조회 | 200 + 본인 담당 학생만 |
| CT-03 | 학원장 겸직 강사 → 강사 모드 → 타 강사 학생 노트 조회 | 403 FORBIDDEN_TEACHER_SCOPE |
| CT-04 | 학원장 모드에서 학생 노트 직접 호출 | 403 FORBIDDEN_ACADEMY_OWNER_SCOPE + AuditLog |
| CT-05 | 학원장 모드 JWT 로 콘솔 외 도메인 학생 노트 시도 (브라우저 직접 URL) | 403 + 학원장 모드 안내 |
| CT-06 | 강사 자격 박탈 후 토글 시도 | 403 + `available_contexts` 갱신 |
| CT-07 | 학원 2개 소유 학원장 → 학원 B의 강사 모드로 직접 토글 | 200 + 학원 B 컨텍스트 |
| CT-08 | 동시 로그인 (학원장 모드 + 강사 모드 다른 브라우저) | 후자가 전자 JWT 만료 |
| CT-09 | 토글 직후 이전 JWT 로 API 호출 | 401 (revocation list 적용) |
| CT-10 | 4시간 만료 후 재로그인 → 직전 active_context 복원 | 200 + 같은 모드로 진입 |

## 11. 변경 이력

- 2026-05-21: 초안. README.md §3차 분리·노출 정책 결정 + 6차 lesson-app/web 분담 결정 후속. 권한 매트릭스 (§6), 세션 격리 (§7), 엣지 케이스 (§8), 감사 (§9), 테스트 (§10) 신설. `console_overview_spec.md §6` 의 요약을 확장하는 위치.
- 2026-06-04: §6 권한 매트릭스 BE 구현. `backend/app/core/context_deps.py` 의 `require_owner_context` / `require_teacher_context` dependency 로 router-level 격리. 적용: 콘솔 owner — `academy_billing`, `academy_governance`. lesson-app teacher — `recordings`, `practice_logs`, `ai_notes`, `lesson_summaries`. 차단 응답은 §6.3 표준 (`FORBIDDEN_TEACHER_SCOPE` / `FORBIDDEN_ACADEMY_OWNER_SCOPE`). active_context 미지정 토큰 (AC-M1 호환) 은 통과 — 기존 `assert_owner` / `get_current_teacher` 가 권한 강제. 회귀 테스트 8건 (`test_context_permission_matrix.py`). 향후 학원 차원 announcements 엔드포인트 / 학생 access-request 라우트는 신설 시 동일 패턴 적용.
- 2026-06-04 (2): `academies.py` endpoint 단위 적용. owner-only 7개 endpoint (`PATCH /{id}`, `POST /members/{id}/revoke`, `POST /{id}/students`, `PATCH /students/{id}`, `POST /{id}/invites`, `GET /{id}/invites`, `POST /invites/{id}/revoke`) 에 `dependencies=[Depends(require_owner_context)]` 부착. 공용 endpoint (학원 생성/조회/내 학원 목록/멤버 목록/내 동의/초대 수락·거절) 는 라우터 일괄 적용 부적합으로 제외. 강사 모드에서 본인 학생만 보여야 할 `GET /{id}/students` 와 `GET /students/{id}` 는 서비스 단 필터링 필요 (별도 작업). 회귀 테스트 8건 추가 — 누적 16건.
- 2026-06-04 (3): `GET /{id}/students` + `GET /students/{id}` 강사 모드 격리. `academy_service.list_students` 에 `teacher_user_id_filter` 추가 — `AcademyMember(user_id, role=teacher, academy_id)` join 으로 본인 매칭 학생만 반환. `get_student` endpoint 는 강사 모드 + 본인 매칭 아닌 학생 → 403 + `FORBIDDEN_NOT_YOUR_STUDENT` (신규 차단 코드, §6.3 표준 준수). list 는 200 + 필터링된 결과 (정보 누출 없음). 회귀 테스트 6건 추가 — 누적 22건. 권한 매트릭스 (§6) BE 구현 완료.
- 2026-06-04 (4): §9 AuditLog 통합. `ContextAccessDenialLog` 모델 신설 (`backend/app/models/academy_governance.py`) + Alembic migration (`ac_m2_context_denial_log`, revises `ac_m1_group_c_billing`). 차단 응답 detail.audit_id 가 본 행의 id 와 일치하도록 `context_deps.record_access_denial` 헬퍼 신설 — 메인 db 세션에 add + commit 하여 후속 rollback 무관 보존. 컬럼: user_id, active_context, academy_id?, denial_code, endpoint_path, http_method, target_resource_id?, denied_at. 3개 인덱스 (user/academy/code × time). 적용: `require_owner_context`, `require_teacher_context`, `get_student` FORBIDDEN_NOT_YOUR_STUDENT. 보존 정책: 1년 (cleanup 작업은 별도). 회귀 테스트 5건 추가 — 누적 27건. §6, §9 BE 구현 완료.
- 2026-06-05: §9 학원장 본인 audit 조회 endpoint 추가. `GET /api/v1/academies/{id}/access-denials/me` — 본인 학원 관련 권한 차단 audit 조회 (transparency). ContextSwitchLog `/me` endpoint 와 동일 패턴 + 동일 권한 (멤버 + owner_context). schemas: `ContextAccessDenialLogResponse` / `ListResponse`. service: `AcademyGovernanceService.list_access_denials_for_user(user_id, academy_id?, limit)`. router-level `require_owner_context` 가 teacher 모드 차단 (학원장 모드여야 audit 조회). 회귀 테스트 4건 (본인 audit만 + 다른 학원/user 제외 + 비멤버 403 + teacher 모드 차단). 미해결: 학원 무관 차단(예: recordings) 의 본인 조회 endpoint, 운영자 어드민 전체 조회.
- 2026-06-05 (2): §9 학원 무관 본인 audit 조회 endpoint 추가. `GET /api/v1/auth/me/access-denials?denial_code=&limit=` — 본인 차단 audit 전체 (학원 관련 + 학원 무관 recordings/practice_logs 등 포함). 권한: 인증만 — active_context 무관 (본인 데이터는 모드 무관). service 메서드에 `denial_code` 옵션 필터 추가. 회귀 테스트 5건 (학원 무관 포함 + 다른 user 제외 + denial_code 필터 + 인증 필요 + teacher 모드도 통과). §9 transparency 양면 (학원 단위 + 사용자 단위) 모두 구현 완료.
- 2026-06-05 (3): §7.2 동시 세션 revocation 구현. `create_access_token` 에 jti 자동 부여 (refresh 와 동일 패턴, `uuid4`). `get_current_user` 에 `TokenBlacklist.jti` 체크 추가 — 매칭 시 401, jti 없는 레거시 토큰은 통과 (호환). `switch_context` service 가 `current_jti` 인자를 받아 토글 직후 이전 토큰 jti 를 `TokenBlacklist` 에 add + flush. endpoint 의 `_extract_context_from_token` 헬퍼를 4튜플로 확장. 회귀 테스트 4건 (이전 JWT → 401 + 새 JWT → 200 / blacklist 기록 / 레거시 통과 / 자동 jti). CT-08, CT-09 시나리오 커버.
- 2026-06-05 (4): §8.4 직전 active_context 자동 복원 구현. `AcademyContextService.restore_last_context(user_id)` 신설 — 별도 컬럼 없이 `ContextSwitchLog` 의 가장 최근 행으로 (active_context, academy_id, teacher_id) 복원. 박탈 시 fallback (owner 우선 → teacher → None). `auth_service` 의 3개 토큰 발급 지점 (oauth_login, dev_login, refresh_token) 에 적용. 회귀 테스트 4건 (refresh 복원 / 강사 박탈 시 owner fallback / 멤버십 0개 시 active_context 미설정 / dev_login 복원). CT-10 시나리오 커버. §6, §7.2, §8.4, §9 BE 구현 완료.
