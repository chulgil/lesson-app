# academy/student_management_spec — 학생 관리

> 기준일: 2026-05-19
> 경로: `/students`, `/students/new`, `/students/waiting`, `/students/{id}`
> 마일스톤: AC-M2 (등록/매칭/대기 큐), AC-M5 (강사 변경, 노트 일시 접근)
> 선행: [console_overview_spec.md](console_overview_spec.md), [teacher_management_spec.md](teacher_management_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1, §3.3, §6.4

## 1. 범위

학원장(R-AO) 의 학생(R-AS) 관리:
- 학생 등록 (학부모/학생 초대 발송)
- 강사 자동 매칭 + 1클릭 확정
- 강사 재매칭 (사유 + AuditLog)
- 매칭 대기 큐
- 학생 노트 일시 접근 (분쟁 케이스, 2인 동의 + 90일)
- 학생 이탈 처리

원칙: 학원장은 **이름·연락처·등록 시점 정보만** 보유. 진도/노트/녹음/연습 기록은 비공개 (NFR-A-5).

## 2. 데이터 모델

```python
class AcademyStudent(Base):
    id = Column(PK)
    academy_id = Column(FK academies)
    student_user_id = Column(FK users)        # 학생 본인 (lesson-app 가입 후)
    parent_user_id = Column(FK users, nullable=True)  # 학부모 (대리 가입 시)
    teacher_member_id = Column(FK academy_members, nullable=True)  # 담당 강사
    name = Column(String, nullable=False)
    contact = Column(String)                  # 학부모 연락처
    instrument = Column(String)
    preferred_days = Column(JSON)             # ["월", "수"]
    preferred_time_start = Column(Time)
    preferred_time_end = Column(Time)
    status = Column(Enum("waiting", "matched", "active", "paused", "alumni"))
    registered_at = Column(DateTime)
    matched_at = Column(DateTime, nullable=True)
    invite_token = Column(String, nullable=True)  # 학부모/학생 가입 초대
    invite_sent_at = Column(DateTime, nullable=True)
    invite_accepted_at = Column(DateTime, nullable=True)
    public_consent = Column(Boolean, default=False)  # 학원 페이지 후기/영상 노출
    dropped_at = Column(DateTime, nullable=True)
    drop_reason = Column(Text, nullable=True)
```

UNIQUE 제약: `(academy_id, student_user_id)` — 한 학원에 같은 학생 1행.

```python
class StudentTeacherChange(Base):
    """강사 변경 이력 (R-AO-13 AuditLog)"""
    id = Column(PK)
    academy_student_id = Column(FK)
    from_teacher_member_id = Column(FK, nullable=True)
    to_teacher_member_id = Column(FK)
    reason = Column(Text, nullable=False)
    changed_by_user_id = Column(FK users)
    changed_at = Column(DateTime)
```

## 3. 학생 등록 (R-AO-11)

`POST /api/v1/academies/{id}/students`

폼 필드:
- 학생 이름 (필수)
- 학부모 이름 + 연락처 (필수)
- 학생 본인 이메일 또는 연락처 (선택 — 학부모 대리 가입 시 생략)
- 악기 (필수)
- 희망 요일 / 시간대
- 비고 (학원장 메모 — 학생/학부모 비공개)

```
1. 학원장: /students/new 폼 작성
2. POST /api/v1/academies/{id}/students
   → AcademyStudent 행 생성 (status='waiting', invite_token)
   → 학부모 카톡/이메일에 lesson-app 초대 링크 발송
3. 학부모 가입 → 자녀 등록 → AcademyStudent.student_user_id / parent_user_id 채워짐
4. (자동) 강사 매칭 추천 (§4) → 학원장이 1클릭 확정 → status='matched'
```

## 4. 강사 자동 매칭 (R-AO-12)

`GET /api/v1/academies/{id}/students/{student_id}/teacher-suggestions`

추천 알고리즘:
1. 강사의 악기 == 학생 악기
2. 강사의 가용 요일/시간이 학생 희망 시간과 겹침
3. 강사의 현재 학생 수 < 학원장 설정 상한 (기본 15명)
4. 강사의 `public_page_consent` 무관 (내부 매칭은 노출 동의와 별개)
5. 정렬: 매칭 시간대 겹침 비율 ↓ → 현재 학생 수 ↑

```json
[
  {
    "teacher_member_id": 7,
    "name": "이선생",
    "instrument": "피아노",
    "available_slots": ["월 16:00-17:00", "수 16:00-17:00"],
    "current_students": 12,
    "match_score": 0.92
  }
]
```

확정: `POST /api/v1/academies/{id}/students/{student_id}/match` `{teacher_member_id: 7}`
→ AcademyStudent.teacher_member_id + matched_at + status='matched'
→ 강사·학생·학부모에게 동시 알림 (lesson-app + 카톡)

## 5. 매칭 대기 큐 (R-AO-14)

`/students/waiting`

표시:
- `AcademyStudent.status='waiting'` 학생 목록
- 등록일 / 악기 / 희망 시간 / 대기 일수
- 가용 강사 0명일 때 "대기 사유: 강사 부족" 표시
- 강사 가용성 변화 (새 강사 입사, 기존 강사 학생 이탈) 시 자동 재추천 → 학원장 알림

대기 7일 초과 시 학원장에게 경고. 30일 초과 시 학생/학부모에게 "강사 매칭 지연 안내".

## 6. 학생 목록 / 상세

`GET /api/v1/academies/{id}/students?status=active|waiting|alumni`

```json
[
  {
    "id": 42,
    "name": "김학생",
    "instrument": "피아노",
    "teacher_name": "이선생",
    "weekly_lessons": 2,
    "attendance_rate": 0.92,
    "billing_status": "paid",
    "registered_at": "2026-02-10",
    "status": "active"
  }
]
```

테이블 컬럼: 이름 / 악기 / 강사 / 주간 레슨 / 출결률 / 청구 상태 / 등록일 / 상태 / 액션

**상세 화면 (`/students/{id}`)** 표시:
- 기본 정보 (이름, 학부모 연락처, 등록일, 악기, 희망 시간)
- 담당 강사 + 변경 이력
- 출결률 (집계만 — 개별 레슨 노트 X)
- 청구·수금 이력 (이 화면에서 청구서 PDF 다운로드 가능)
- 액션: "강사 변경" / "노트 일시 접근 요청" / "학생/학부모에게 메시지"

**금지**: 레슨 노트, 녹음, 연습 로그, 진도 차트 (NFR-A-5 / R-AS-4).

## 7. 강사 재매칭 (R-AO-13)

```
1. 학생 상세 → "강사 변경"
2. 사유 입력 (필수, 30자 이상) — 예: "학생 요청 — 시간대 변경 필요"
3. 신규 강사 선택 (§4 추천 알고리즘 재사용)
4. POST /api/v1/academies/{id}/students/{student_id}/change-teacher
   {to_teacher_member_id, reason}
5. 결과:
   - AcademyStudent.teacher_member_id 변경
   - StudentTeacherChange 행 추가 (AuditLog)
   - 이전 강사 / 신규 강사 / 학생 / 학부모 알림
   - 이전 강사: 학생 데이터 read-only 7일 (인수인계)
```

## 8. 학생 노트 일시 접근 (R-AO-23, §6.4) — AC-M5

분쟁/민원 케이스. **학원장 모드의 NFR-A-5 차단을 일시 해제**.

### 8.1 모델

```python
class StudentNoteAccessRequest(Base):
    id = Column(PK)
    academy_id = Column(FK)
    academy_student_id = Column(FK)
    requested_by_user_id = Column(FK users)  # 학원장
    reason = Column(Text, nullable=False)
    status = Column(Enum("pending", "granted", "denied", "revoked", "expired"))
    consent_required = Column(Integer, default=2)  # 3명 중 2명
    consents = relationship("StudentNoteAccessConsent")
    granted_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)  # granted_at + 90 days
    revoked_at = Column(DateTime, nullable=True)
    revoked_by_user_id = Column(FK users, nullable=True)
    revoke_reason = Column(Text, nullable=True)

class StudentNoteAccessConsent(Base):
    id = Column(PK)
    request_id = Column(FK)
    user_id = Column(FK users)  # 학생 / 학부모 / 강사
    role = Column(Enum("student", "parent", "teacher"))
    decision = Column(Enum("pending", "approved", "rejected"))
    decided_at = Column(DateTime, nullable=True)

class StudentNoteAccessLog(Base):
    """학원장이 토큰으로 노트 접근 시마다 기록"""
    id = Column(PK)
    request_id = Column(FK)
    accessed_endpoint = Column(String)  # /students/{id}/notes
    accessed_at = Column(DateTime)
    ip = Column(String)
```

### 8.2 흐름

```
1. 학원장 콘솔 → 학생 상세 → "노트 일시 접근 요청"
2. 사유 입력 (필수, 100자 이상) — "학부모 민원: 진도 의심"
3. POST /api/v1/academies/{id}/students/{student_id}/note-access-requests
   → StudentNoteAccessRequest 생성 (status='pending')
   → 학생 / 학부모 / 강사 3명에게 동의 요청 발송 (카톡 + lesson-app)
4. 각자 lesson-app 에서 "동의" / "거절" 1클릭
   → StudentNoteAccessConsent 갱신
5. 2명 'approved' 도달 시:
   - status='granted', granted_at, expires_at = +90일
   - 학원장에게 토큰 발급 알림
   - 모든 당사자에게 "노트 접근 허용됨 — 90일 유효" 알림
6. 학원장이 노트/녹음 엔드포인트 호출 시:
   - 토큰 검증 (request_id + 만료 체크)
   - StudentNoteAccessLog 기록 (모든 호출)
7. 회수:
   - 90일 후 자동 expires
   - 학생/학부모/강사 중 1명이라도 "회수 요청" → status='revoked' 즉시
   - 학원장 토큰 무효화 + 알림
```

### 8.3 차단된 엔드포인트의 일시 해제

[console_overview_spec.md §5.1](console_overview_spec.md) 차단 목록은 기본 403.
유효 토큰 보유 학원장의 호출은 다음 헤더 동반:

```
Authorization: Bearer {access_token}
X-Note-Access-Request-Id: 123
```

미들웨어 `current_academy_owner` 가 토큰 + 만료 확인 후 통과. 통과한 모든 호출은 AuditLog + `StudentNoteAccessLog` 이중 기록.

### 8.4 UX 강조

- 동의 요청 화면: "학원장이 분쟁 처리 사유로 노트 접근을 요청했습니다. 동의/거절을 선택해주세요."
- 회수 화면: 학생/학부모/강사 lesson-app 메인 알림 영역에 "노트 접근 권한 — 회수" 상시 노출
- 학원장 화면: 유효 토큰 보유 시 학생 상세 헤더에 "노트 접근 권한 — 잔여 65일" 배지 표시

## 9. 학생 이탈 (R-AS-6)

```
1. 학생/학부모: lesson-app → "학원 떠나기" 클릭
2. 학원장 콘솔 알림 "김학생 — 이번 달 말 이탈 예정 (사유: ...)"
3. 학원장이 회유 (선택) 또는 확정
4. 이탈일 도달:
   - AcademyStudent.status='alumni', dropped_at, drop_reason
   - 담당 강사 학생 수 -1
   - 학생 lesson-app 데이터 본인 보유 (학원이 소유 X)
   - 미수금 있으면 알림 발송 + 학원장 인박스
```

## 10. 권한 / 보안

- `Depends(current_academy_owner)` + academy_id 검증
- 학생/학부모 본인 정보 수정은 학생/학부모 lesson-app 에서 (학원장 권한 X)
- 노트/녹음/진도 엔드포인트는 §8 일시 접근 토큰 외 항상 403
- 학생/학부모/강사 가입 초대 토큰: 14일 유효. 만료 시 학원장 재발송.

## 11. 변경 이력

- 2026-05-19: 초안
