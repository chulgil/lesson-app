# academy/teacher_management_spec — 강사 관리

> 기준일: 2026-05-19
> 경로: `/teachers`, `/teachers/invite`, `/teachers/{id}`
> 마일스톤: AC-M2 (초대/수락/노출 동의), AC-M5 (퇴사·이관)
> 선행: [console_overview_spec.md](console_overview_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1, §3.2, §6.5

## 1. 범위

학원장(R-AO) 의 강사(R-AT) 관리:
- 강사 초대 (이메일/카톡)
- 강사 가입 수락 흐름
- 강사 목록 / 상세
- 학원 페이지 노출 동의
- 강사 퇴사 + 학생 일괄 이관

## 2. 데이터 모델

```python
class AcademyMember(Base):
    id = Column(PK)
    academy_id = Column(FK academies)
    user_id = Column(FK users, nullable=True)         # accept 전에는 NULL
    role = Column(Enum("owner", "teacher", "alumni"), nullable=False)
    joined_at = Column(DateTime)
    access_revoked_at = Column(DateTime, nullable=True)
    public_page_consent = Column(Boolean, default=False)  # R-AT-3
    invited_by = Column(FK users, nullable=True)
    invitee_email = Column(String, nullable=True)         # 초대 발송 대상
    invitee_kakao_id = Column(String, nullable=True)      # 카톡 ID (선택)
    invite_token = Column(String, nullable=True, unique=True)
    invite_sent_at = Column(DateTime, nullable=True)
    invite_accepted_at = Column(DateTime, nullable=True)
    invite_rejected_at = Column(DateTime, nullable=True)  # §3.6
    invite_resend_count = Column(Integer, default=0)      # §3.4 rate limit 추적
    invite_last_resent_at = Column(DateTime, nullable=True)
    onboarding_until = Column(DateTime, nullable=True)    # 수습 강사 (academy_schedule_authority_spec.md)
```

UNIQUE 제약:
- `(academy_id, user_id, role)` where `user_id IS NOT NULL` — 같은 user 가 한 학원에서 owner + teacher 두 행 보유 가능 (학원장 겸직)
- `(academy_id, invitee_email)` where `invite_accepted_at IS NULL AND invite_rejected_at IS NULL` — 동일 invitee 동시 초대 1건만 (§3.2)

## 3. 강사 초대 흐름 (R-AO-7, R-AT-1)

### 3.1 정상 흐름

```
1. 학원장: /teachers/invite
   → 이메일 또는 카톡 ID 입력 + 메시지 (선택)
2. POST /api/v1/academies/{id}/teachers/invite
   → AcademyMember 임시 행 생성 (role=teacher, invite_token, invite_sent_at)
   → 이메일/카톡 발송 (deep link: lessonaza.app/academy/accept?token=...)
3. 강사:
   a) lesson-app 미설치 → www.lessonaza.app → SSO 가입 (role=teacher)
   b) lesson-app 설치 → 자동 로그인
4. accept 화면:
   - 학원 이름·소개 표시
   - "이중 권한 명시" 안내 (정확한 워딩: §3.3)
   - 학원 페이지 노출 여부 선택 (기본 **OFF**, §3.5)
   - "가입 수락" / "거절" 버튼
5. POST /api/v1/academies/{id}/teachers/accept?token=...
   → AcademyMember.user_id 설정 + invite_accepted_at + public_page_consent
   → 학원장에게 알림
```

### 3.2 초대 토큰 정책

| 항목 | 값 |
|---|---|
| 유효 기간 | **7일** (`invite_sent_at + 7 days`) |
| 토큰 형식 | URL-safe random 32 bytes (base64) |
| 1회용 | accept 또는 reject 즉시 무효화 |
| 만료 시 응답 | 410 GONE + 사유 메시지 |
| 동일 초대 동시 다발 | UNIQUE `(academy_id, invitee_email, accepted_at=NULL)` — 중복 발송 차단 |

### 3.3 안내 메시지 (accept 화면 표준 워딩)

```
강남리듬 학원이 강사로 초대했습니다.

[가입 시 권한 안내]
• 본인이 담당하는 학생의 레슨 노트·녹음·연습 기록에 접근 가능합니다.
• 학원장은 학생 개별 진도/노트에 접근할 수 없습니다 (분쟁 시 2인 동의 + 90일 일시 접근).
• 본인의 강사 페이 정산 명세를 직접 확인할 수 있습니다.
• 학원 운영 메뉴 (학생 매칭·청구·정산 발행) 는 학원장 전용입니다.

[학원 공개 페이지 노출]
□ 학원 공개 페이지에 내 이름·악기·소개를 표시합니다.
   (기본 OFF — 가입 후 lesson-app 설정에서 언제든 변경 가능)
```

### 3.4 재발송 흐름 (R-AO-7)

```
조건:
- 강사가 7일 내 미수락 → 학원장 콘솔 강사 목록에 "초대 만료 임박" 배지
- 7일 경과 → "만료" 상태로 표시 + "재발송" 버튼 활성

API:
POST /api/v1/academies/{id}/teachers/invite/{member_id}/resend
→ 기존 invite_token 무효화 + 새 토큰 발급 + invite_sent_at 갱신
→ 이메일/카톡 재발송

Rate limit:
- 동일 invitee 24시간 내 최대 3회 재발송
- 초과 시 429 + "내일 다시 시도하세요"
```

### 3.5 노출 동의 기본 OFF (R-AT-3)

- accept 화면 체크박스 기본 **OFF**
- 강사 가입 후 본인이 lesson-app 설정 → "공개 노출 동의" 토글로 변경
- `AcademyMember.public_page_consent=true` 인 강사만 `academy.lessonaza.app/{slug}` 강사 목록에 표시
- **학원장은 강사 본인의 동의 토글을 직접 변경할 수 없다** (R-AT-3 핵심 보호)
- 미동의 강사 노출 요청은 학원장이 강사에게 직접 메시지 (lesson-app 인박스)

### 3.6 거절 흐름

```
강사가 accept 화면에서 "거절" 클릭
→ POST /api/v1/academies/{id}/teachers/reject?token=...
→ AcademyMember.invite_rejected_at = now
→ 학원장에게 알림 ("이선생이 초대를 거절했습니다")

재초대 가능 여부:
- 거절 후 30일 cool-down — 같은 invitee 에게 새 초대 발송 불가
- 30일 경과 후 학원장이 명시적으로 재초대 가능 (자동 재시도 금지)
- 강사 본인이 학원장에게 직접 연락하면 즉시 재초대 가능 (cool-down 면제 플래그)
```

### 3.7 만료 토큰 클릭 UX

만료된 링크 클릭 시:

```
이 초대 링크는 만료되었습니다 (7일 경과).

학원장에게 재발송을 요청해주세요.
[학원장에게 알림 보내기] [닫기]
```

"학원장에게 알림 보내기" 클릭 → 학원장 콘솔에 "이선생이 만료된 링크를 클릭했습니다 — 재발송이 필요합니다" 알림. 학원장이 §3.4 재발송 흐름 진행.

## 4. 강사 목록 (R-AO-8)

`GET /api/v1/academies/{id}/teachers?status=active|alumni|pending`

```json
[
  {
    "id": 7,
    "name": "이선생",
    "instruments": ["피아노"],
    "students_count": 12,
    "weekly_lessons": 24,
    "attendance_rate": 0.96,
    "joined_at": "2026-01-15",
    "public_page_consent": true,
    "status": "active"
  }
]
```

테이블 컬럼: 이름 / 악기 / 학생 수 / 주간 레슨 / 출결률 / 등록일 / 공개 동의 / 상태 / 액션

## 5. 강사 상세 (R-AO-8, R-AO-22)

`GET /api/v1/academies/{id}/teachers/{teacher_id}`

표시:
- 기본 정보 (이름, 악기, 등록일, 학원 페이지 노출 여부)
- 담당 학생 N명 (이름 + 상태만 — 진도/노트 X)
- 이번 달 출근율 / 대강 횟수 / 신규 매칭 기여
- 매출 기여 (학생별 수강료 합계 — 미수금 포함)
- 액션: "퇴사 처리" / "학생 재매칭" / "강사에게 메시지"

## 6. 강사 퇴사 / 학생 이관 (R-AO-9, R-AT-7, §6.5)

### 6.1 학원장 처리 (즉시)

```
1. 강사 상세 → "퇴사 처리"
2. 학생 이관 표 UI:
   ┌──────────────────────────────────────┐
   │ 학생       | 신규 강사   | 사유      │
   ├──────────────────────────────────────┤
   │ 김학생     | [드롭다운▼] | [______] │
   │ 박학생     | [드롭다운▼] | [______] │
   └──────────────────────────────────────┘
   (가용 강사 자동 추천 — 악기·요일·시간 매칭)
3. "확정" → POST /api/v1/academies/{id}/teachers/{teacher_id}/offboard
   {
     "reassignments": [{student_id: 1, new_teacher_id: 8, reason: "..."}],
     "effective_date": "immediate"
   }
4. 결과:
   - 신규 강사에게 학생 데이터 (노트·일정) 인수 (read-write)
   - 퇴사 강사 본인 학생 데이터 → read-only 7일 (인수인계용)
   - 7일 후 AcademyMember.role=alumni + access_revoked_at
   - 학생/학부모/강사에게 알림 발송
```

### 6.2 강사 자발적 탈퇴

```
1. 강사: lesson-app → "학원 탈퇴" 클릭
2. 30일 통보 자동 시작
3. 학원장 콘솔 알림 "이선생 30일 후 탈퇴 예정 — 학생 재매칭 필요"
4. 학원장이 6.1 흐름 진행
5. 30일 경과 시 자동 alumni 전환 (재매칭 미완료 시 학생은 waiting 큐로)
```

## 7. 학원 페이지 노출 동의 (R-AT-3)

- 가입 수락 시 기본 OFF
- 강사 본인 lesson-app 또는 콘솔 (강사 모드) 에서 토글
- `AcademyMember.public_page_consent=true` 인 강사만 `academy.lessonaza.app/{slug}` 강사 목록에 노출
- 동의 강사: 이름 + 악기 + 간단 소개 + 개인 프로필 페이지 링크 (있을 때)

## 8. 학원장 겸직 강사 (R-AO-1)

가입 시 학원장이 본인을 강사로 추가:

```
POST /api/v1/academies/{id}/teachers/self-add
→ AcademyMember 행 추가 (user_id=current_user, role=teacher)
→ 학원장 모드 콘솔 강사 목록에 본인 표시 (학생 매칭 가능)
→ 본인이 가르치는 학생의 노트는 "내 강사 모드" 에서만 접근 가능
```

## 9. 알림 / 커뮤니케이션 (R-AO-10, R-AT-4)

- 강사 매칭 알림: 강사 lesson-app 인앱 + 카톡 (강사가 알림 차단 시 학원장에게 경고)
- 학원 공지: `POST /api/v1/academies/{id}/announcements?audience=teachers` → 모든 강사 lesson-app 알림
- 강사 → 학원장 직접 메시지: lesson-app 인박스 (이 콘솔 인박스는 학부모용)

## 10. 권한 / 보안

- `Depends(current_academy_owner)` + academy_id 검증
- 강사 자발 탈퇴는 `Depends(current_teacher)` + 본인 academy_member_id 검증
- 강사 정보 수정 (개인 프로필) 은 학원장 권한 X — 강사 본인 lesson-app 에서만
- 퇴사 처리는 AuditLog 기록 (R-AO-9 사유 포함)

## 11. 변경 이력

- 2026-05-19: 초안
- 2026-05-21: §3 초대 흐름 보강 (AC-M2 진입 준비). §3.2 토큰 정책 (7일 + 1회용 + UNIQUE 동시 초대 차단), §3.3 안내 메시지 표준 워딩 (이중 권한 명시), §3.4 재발송 흐름 (24시간 3회 rate limit), §3.5 노출 동의 기본 OFF (학원장 직접 변경 불가), §3.6 거절 흐름 (30일 cool-down), §3.7 만료 토큰 UX. §2 데이터 모델에 `invitee_email`, `invitee_kakao_id`, `invite_rejected_at`, `invite_resend_count`, `invite_last_resent_at`, `onboarding_until` 필드 추가 + UNIQUE 제약 동시 초대 1건만으로 강화.
