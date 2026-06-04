# academy/temporary_delegation_spec — 학원장 임시 권한 위임

> 기준일: 2026-06-04
> 경로: `/settings/delegation`, `/delegation/audit`
> 마일스톤: AC-M5 (위임 MVP) / AC-M6 (강사 매니저 역할)
> 선행: [context_toggle_spec.md](context_toggle_spec.md), [console_overview_spec.md §5](console_overview_spec.md), [teacher_management_spec.md](teacher_management_spec.md), [inbox_spec.md §11.5](inbox_spec.md)
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` H#5

## 1. 배경 / 범위

소규모 음악학원장은 1인 운영이라 출장·병가·발표회·휴가 시 학원 운영이 멈춤. [context_toggle_spec.md §6](context_toggle_spec.md) 의 권한 매트릭스는 `active_context='teacher'` 모드에서 학원 운영 메뉴를 **완전 차단**한다. 본 스펙은 이 차단 원칙의 **명시적 제한적 예외**를 정의한다.

**핵심 원칙:**

| 원칙 | 의미 |
|---|---|
| 영구 권한 부여 금지 | 학원장 = 학원장만. 위임은 항상 **시간 제한** |
| 부분 권한 | 위임 항목별 토글 (청구만 / 정산만 / 공지만). 전체 위임 금지 |
| 학원장 명시 동의 | 위임 시작 시 학원장 비밀번호 재입력 |
| 자동 종료 | 위임 만료일 도달 또는 학원장 콘솔 로그인 자동 감지 시 즉시 종료 |
| 모든 위임 audit 영구 | 분쟁 시 "위임 받은 자가 무엇을 했나" 100% 추적 |
| NFR-A-5 학생 PII 차단 유지 | 위임 받은 강사도 학생 노트/녹음은 차단 |

## 2. 위임 종류

### 2.1 권한 항목 (학원장이 항목별 토글)

| 항목 | 허용 액션 | 차단 액션 |
|---|---|---|
| `billing.collect` | 수금 1클릭 마킹, 미수금 리마인더 발송 | 청구서 금액 수정, 신규 발행 |
| `billing.settle` | 강사 정산 미리보기 (수정 불가) | 정산 확정, 강사 송금 마킹 |
| `inbox.reply` | 문의 답변 작성 + 발송 | 학부모 PII 수정, 학생 등록 |
| `announcement.send` | 사전 등록된 템플릿 공지 발송 | 신규 템플릿 작성, 일괄 휴원 |
| `schedule.bulk_change` | 단일 일정 변경 | 일괄 휴원, 학원 운영 시간 변경 |
| `dashboard.view_only` | 대시보드 KPI 열람 (액션 없음) | — (열람만) |
| `student.contact` | 학부모 연락처 조회 (학생 노트 X) | 학생 노트, 녹음, 진도 |

### 2.2 위임 시나리오 (현실 예시)

| 시나리오 | 권한 조합 | 기간 |
|---|---|---|
| 출장 3일 | `inbox.reply` + `dashboard.view_only` | 3일 |
| 병가 1주 | `inbox.reply` + `billing.collect` + `dashboard.view_only` | 7일 |
| 발표회 운영 (당일) | `announcement.send` + `inbox.reply` | 1일 |
| 휴가 2주 | 전체 항목 + 강사 매니저 역할 | 14일 |
| 정기 매니저 (선임 강사) | `inbox.reply` + `billing.collect` 영구 (단 7일마다 갱신) | 7일 회전 |

## 3. 데이터 모델

```python
class AcademyDelegation(Base):
    """학원장 → 위임받는 자 임시 권한 (학원 1개당 동시 1개만)."""
    id = Column(PK)
    academy_id = Column(FK)
    delegator_user_id = Column(FK users)                    # 학원장 본인
    delegatee_member_id = Column(FK academy_members)         # 위임 받는 강사
    permissions = Column(JSON)                               # ["billing.collect", "inbox.reply", ...]
    starts_at = Column(DateTime)                             # 위임 시작 시각
    ends_at = Column(DateTime)                               # 위임 만료 시각 (필수)
    reason = Column(Enum("trip", "sick", "vacation", "event", "other"))
    reason_note = Column(String, nullable=True)
    state = Column(Enum("scheduled", "active", "expired", "revoked", "auto_ended"))
    revoked_at = Column(DateTime, nullable=True)
    revoked_by_user_id = Column(FK users, nullable=True)     # 학원장 본인 또는 시스템
    revoked_reason = Column(Enum(
        "owner_returned",      # 학원장 콘솔 로그인 감지
        "owner_manual",        # 학원장이 수기 종료
        "expired",             # 만료일 도달
        "delegatee_declined",  # 위임 받는 자가 거절
    ), nullable=True)
    requires_password_at_start = Column(Boolean, default=True)
    notification_template_id = Column(String, default="delegation_v1")

    __table_args__ = (
        Index("idx_delegation_academy_state", "academy_id", "state"),
        # 동시 1개만: state in (scheduled, active) 행 unique academy_id
    )


class AcademyDelegationAction(Base):
    """위임 기간 동안 delegatee 가 수행한 액션 로그 (audit)."""
    id = Column(PK)
    delegation_id = Column(FK)
    performed_at = Column(DateTime, default=func.now())
    performed_by_user_id = Column(FK users)
    permission_used = Column(String)                          # "billing.collect" 등
    endpoint = Column(String)                                 # "POST /billing/payments/..."
    target_resource_id = Column(String, nullable=True)
    request_summary = Column(JSON)                            # 요청 핵심 (PII 제외)
    response_status = Column(Integer)
    owner_reviewed_at = Column(DateTime, nullable=True)       # 학원장이 사후 검토 완료
```

## 4. 위임 시작 흐름

### 4.1 학원장 화면 (`/settings/delegation/new`)

```
┌──────────────────────────────────────────────┐
│ 임시 권한 위임                              │
├──────────────────────────────────────────────┤
│ 받는 사람 (강사):  [▼ 이선생 (수석 강사)] │
│ 사유:              [▼ 출장]                 │
│ 기간:              [2026-06-10] ~ [06-12]   │
│ 위임 권한 (체크):                            │
│   [✓] 학부모 문의 답변                       │
│   [✓] 수금 1클릭 마킹                        │
│   [ ] 강사 정산 미리보기                     │
│   [ ] 공지 발송 (사전 템플릿)                │
│   [ ] 단일 일정 변경                         │
│   [✓] 대시보드 KPI 열람                      │
│   [ ] 학부모 연락처 조회                     │
│                                              │
│ ⚠ 학생 노트/녹음은 위임할 수 없습니다.     │
│                                              │
│ 비고: [        출장 중 응대 부탁드립니다 ] │
│                                              │
│        [취소]  [학원장 비밀번호로 확정]    │
└──────────────────────────────────────────────┘
```

### 4.2 확정 처리

```
POST /api/v1/academies/{id}/delegations
{
  delegatee_member_id, permissions[], starts_at, ends_at, reason, reason_note,
  password  # 학원장 재인증
}

1. 비밀번호 재검증 (4xx if 불일치)
2. 동시 위임 행 검사 (academy_id state in scheduled/active) → 409 if 존재
3. delegatee_member_id 의 role 검증 (teacher / owner_substitute 만 허용)
4. AcademyDelegation 행 생성 (state='scheduled' if starts_at > now else 'active')
5. delegatee 에게 알림 (lesson-app 인박스 + 카톡 LNZ_DELEGATION_RECEIVED)
6. 학원장 모든 활성 세션에 알림 "위임이 시작됩니다 ({end})"
7. AuditLog (delegation 생성)
```

### 4.3 위임 받는 자 동의 화면 (lesson-app)

```
┌──────────────────────────────────────────────┐
│ 학원장이 임시 권한을 위임했습니다           │
├──────────────────────────────────────────────┤
│ 학원장: 김원장                              │
│ 기간: 2026-06-10 ~ 06-12 (3일)              │
│ 사유: 출장                                   │
│ 비고: 출장 중 응대 부탁드립니다             │
│                                              │
│ 위임 권한:                                   │
│ • 학부모 문의 답변                           │
│ • 수금 1클릭 마킹                            │
│ • 대시보드 열람                              │
│                                              │
│ 모든 액션은 audit 기록되며                  │
│ 학원장이 복귀 후 검토합니다.                 │
│                                              │
│          [거절]  [수락하고 시작]            │
└──────────────────────────────────────────────┘
```

거절 시 `revoked_at` + `revoked_reason='delegatee_declined'` 기록 + 학원장에게 알림 ("이선생이 위임을 거절했습니다").

## 5. 위임 활성 기간 — 권한 부여 + 차단

### 5.1 JWT 처리

위임 받는 자가 lesson-app 사용 중에도 위임된 학원 운영 메뉴 접근 가능. JWT 페이로드 확장:

```json
{
  "user_id": 7,
  "active_context": "teacher",
  "academy_id": 42,
  "teacher_id": 12,
  "delegation_id": 88,
  "delegated_permissions": ["billing.collect", "inbox.reply", "dashboard.view_only"],
  "delegation_ends_at": 1718064000
}
```

[context_toggle_spec.md §6.2](context_toggle_spec.md) teacher 모드 차단 매트릭스에 위임 권한이 있으면 예외 허용. 차단 응답:
- 권한 없음 + 위임 안 됨 → 기존 `FORBIDDEN_TEACHER_SCOPE`
- 권한 없음 + 위임 만료 → 신규 `FORBIDDEN_DELEGATION_EXPIRED`

### 5.2 위임 받는 자 UX 표시

lesson-app 상단 배지 (눈에 띄게):

```
┌────────────────────────────────────────────┐
│ 🔵 위임 모드 (06-12 18:00 까지)  [상세] │
└────────────────────────────────────────────┘
```

콘솔 진입 시 헤더 색상 변경 (학원장 navy → delegation orange) — 본인이 학원장 권한이 아님을 시각적으로 인지.

### 5.3 학생 PII 차단 (NFR-A-5 유지)

위임 받은 강사도 본인이 가르치지 않는 학생의 노트/녹음 접근 차단. 위임은 "운영 액션" 만 허용 — "학생 개별 데이터" 차단 그대로.

### 5.4 모든 액션 audit

위임 활성 중 모든 API 호출은 자동으로 `AcademyDelegationAction` 행 생성. middleware 에서 처리:

```python
@app.middleware("http")
async def log_delegation_action(request, call_next):
    response = await call_next(request)
    delegation_id = request.state.delegation_id
    if delegation_id and request.method in ("POST", "PATCH", "PUT", "DELETE"):
        await log_action(
            delegation_id=delegation_id,
            performed_by_user_id=request.state.user_id,
            permission_used=request.state.permission_used,
            endpoint=f"{request.method} {request.url.path}",
            request_summary=summarize_request(request),
            response_status=response.status_code,
        )
    return response
```

## 6. 위임 종료 흐름

### 6.1 자동 종료 트리거

| 트리거 | 처리 |
|---|---|
| `ends_at` 도달 | 자동 만료. `state='expired'`. delegatee 다음 API 호출 시 401 + 안내 |
| 학원장 콘솔 로그인 | `revoked_reason='owner_returned'` + 자동 종료. 학원장에게 "위임이 자동 종료되었습니다" 알림 |
| 학원장 수기 종료 | `/settings/delegation/{id}/revoke` → `revoked_reason='owner_manual'` |
| delegatee 자체 종료 | "더 이상 위임 불필요" → `revoked_reason='delegatee_declined'` |

### 6.2 자동 종료 시 데이터 처리

- 진행 중 액션 (예: 답변 작성 중) → 저장 후 알림 "위임 종료. 작성 중인 내용은 학원장 검토 큐로 이동"
- delegatee 의 JWT 즉시 만료 (revocation list 추가)
- delegatee lesson-app 헤더 배지 제거 + "위임 종료" 알림

### 6.3 학원장 복귀 자동 감지

학원장이 다음 중 하나라도 수행하면 위임 자동 종료:
- 콘솔 로그인 (web)
- lesson-app 학원장 모드 토글
- 카톡 알림톡에서 "복귀" 키워드 회신

학원장이 부재 시작 시 "복귀 자동 감지를 사용하시겠습니까?" 토글 (기본 ON).

## 7. 학원장 사후 검토

### 7.1 검토 큐 (`/delegation/audit`)

학원장 복귀 후 자동 알림:

```
[Lessonaza] 위임 기간 동안 12건의 액션이 있었습니다.
• 수금 처리: 5건 (₩900,000)
• 학부모 문의 답변: 6건
• 공지 발송: 1건
[검토하기]
```

검토 화면:

```
┌──────────────────────────────────────────────────┐
│ 위임 검토 - 이선생 (2026-06-10 ~ 06-12)         │
├──────────────────────────────────────────────────┤
│ 액션 12건 중 0건 검토 완료                      │
│ ─────────────────────────────────────────────── │
│ 06-10 14:30  수금 1클릭   김지민 ₩200,000  [✓] │
│ 06-10 15:45  수금 1클릭   박지수 ₩180,000  [✓] │
│ 06-11 09:00  문의 답변    이학부모 (가입)  [보기]│
│ 06-11 13:20  공지 발송    "6월 발표회 안내"[보기]│
│ ...                                              │
│                                                  │
│ [전체 승인] [선택 승인] [이의 제기]             │
└──────────────────────────────────────────────────┘
```

각 행 클릭 → 상세 (요청 본문 / 응답 결과 / 영향 학생). 학원장이 이의 제기 시 delegatee 에게 알림 + 향후 위임 시 경고 표시.

### 7.2 액션 되돌리기 (가능 한도)

- 수금 마킹 → revert (잘못 마킹된 경우)
- 답변 발송 → revert 불가 (이미 학부모 수신). 다음 답변에 정정만 가능
- 공지 발송 → revert 불가
- 단일 일정 변경 → 7일 이내 revert

## 8. 위임 매니저 역할 (AC-M6 — 영구 위임 패턴)

수석 강사가 매월 반복적으로 학원장 부재 시 대신 처리하는 경우, "매니저" 역할을 부여:

```python
class AcademyMember(Base):
    # ... 기존 ...
    delegate_role = Column(Enum("none", "trusted_substitute"), default="none")
    delegate_role_granted_at = Column(DateTime, nullable=True)
    default_delegation_permissions = Column(JSON, nullable=True)
```

`trusted_substitute` 역할이 있는 강사에게 학원장이 위임 시:
- 비밀번호 재입력 1회 (그 강사에 대해 최초 1회만, 향후 생략)
- 기본 권한 자동 채워짐
- 위임 기간 자동 7일 갱신 옵션 (학원장이 종료할 때까지)

단 영구 권한 부여는 여전히 금지. 7일 만료 시마다 학원장 알림 ("이선생 매니저 권한 갱신 D-1").

## 9. 분쟁 / 책임 경계

### 9.1 위임 받은 자의 책임

- 모든 액션은 audit 기록되며 학원장 검토 대상
- 위임 권한 외 액션 시도 시 403 + audit 기록 → 학원장 알림 ("권한 외 시도")
- 학원장 사후 이의 제기 시 사유 메모 + 향후 위임 시 경고

### 9.2 학원장의 책임

- 위임 종료 30일 후에도 audit 미검토 시 자동 "전체 승인" 처리 (delegatee 보호 — 학원장 무한 검토 차단)
- 학원장 본인이 부재 중 일어난 일에 대한 운영 책임은 학원장 본인

### 9.3 학부모 입장

- 위임 받은 자가 답변 시 학부모에게 "현재 학원장 부재. 이선생 대신 답변 드립니다." 자동 prefix 옵션
- 답변 본문에 위임자 이름 노출 (혼란 방지)

## 10. 알림 / 카톡 템플릿

사전 등록:

| 템플릿 ID | 시점 | 본문 |
|---|---|---|
| `LNZ_DELEGATION_RECEIVED` | delegatee 수신 | "[Lessonaza] {owner} 학원장이 권한을 위임했습니다. lesson-app 에서 확인." |
| `LNZ_DELEGATION_ACCEPTED` | delegator 학원장에게 | "{delegatee} 강사가 위임을 수락했습니다." |
| `LNZ_DELEGATION_DECLINED` | delegator | "{delegatee} 강사가 위임을 거절했습니다." |
| `LNZ_DELEGATION_EXPIRING` | 만료 24h 전 양쪽 | "위임이 {end_at} 만료됩니다." |
| `LNZ_DELEGATION_OWNER_RETURNED` | delegatee | "학원장 복귀로 위임이 종료되었습니다." |
| `LNZ_DELEGATION_AUDIT_READY` | 학원장 복귀 시 | "위임 기간 액션 N건 검토 대기" |

## 11. 권한 / 보안

- 모든 위임 액션은 `AcademyDelegation` + `AcademyDelegationAction` 영구 보존
- 비밀번호 재인증은 학원장 본인 IP/디바이스 검증과 함께 (다른 디바이스에서 위임 시도 시 2FA)
- 동시 위임 1개 제한 (한 학원당)
- delegate_role 변경은 학원장 본인만 (위임 받은 자가 본인 권한 확장 불가)

## 12. 실패 / 예외

| 상황 | 처리 |
|---|---|
| delegatee 가 학원 떠남 (퇴직) | 즉시 모든 위임 종료 + 학원장 긴급 알림 |
| 학원장 복귀 자동 감지 false positive (학원장이 잠깐 본 것) | 학원장이 "위임 계속" 다이얼로그 선택 가능 |
| 위임 기간 중 학원장이 활동했음 (이중 작업) | 양쪽 action 모두 audit. 충돌 시 학원장 마지막 변경 우선 |
| delegatee 가 위임 기간 중 본인 권한도 사용 | 두 권한 분리 audit. delegation 권한 사용 시 별도 컬럼 표시 |

## 13. 변경 이력

- 2026-06-04: 초안 (갭분석 H#5 응답: 출장/병가 시 학원 운영 멈춤 해소. 시간 제한 + 부분 권한 + 학원장 비밀번호 재인증 + 모든 액션 audit + 학원장 자동 종료 감지 + 매니저 영구 패턴 옵션. NFR-A-5 학생 PII 차단 원칙 유지)
