# academy/teacher_offboarding_spec — 강사 퇴직 + 학생 인수인계

> 기준일: 2026-06-04
> 경로: `/teachers/{id}/offboarding`, `/students/handover/{id}`
> 마일스톤: AC-M5 (퇴직 신청 MVP) / AC-M7 (인수인계 정밀화)
> 선행: [teacher_management_spec.md](teacher_management_spec.md), [student_management_spec.md](student_management_spec.md), [academy_schedule_authority_spec.md](academy_schedule_authority_spec.md), [billing_settlement_spec.md §6](billing_settlement_spec.md), [teacher_absence_and_substitute_spec.md](teacher_absence_and_substitute_spec.md)
> 갭분석 input: 후속 후보 #1 (강사 이직 시 학생 데이터 인수인계 자동화 부재)
> 관련 정책: NFR-A-5 (학생 PII 권한 격리), [context_toggle_spec.md §6](context_toggle_spec.md)

## 1. 배경 / 범위

소규모 음악학원 강사는 평균 1-3년 재직 후 퇴직 (시장조사 추정). 퇴직 시 다음 문제가 학원의 가장 큰 리스크:

1. **학생 이탈** — 강사를 따라 학생이 학원을 떠나는 경우 (학원 → 강사 개인 교습 전환)
2. **데이터 인수인계 누락** — 후임 강사가 학생 진도/특성을 모름 → 첫 수업 품질 저하 → 학부모 불만
3. **분쟁** — 학생 명단·연락처를 강사가 외부로 가져가는 의심 → 법적 분쟁
4. **정산 미정리** — 마지막 페이·정산이 모호 → 강사 ↔ 학원장 분쟁

본 스펙은 강사 퇴직을 **명시적 워크플로우**로 만들어 학원 리스크를 최소화한다.

**범위:**
- 강사 퇴직 신청 + 학원장 승인 (또는 학원장이 해고)
- 인수인계 기간 (1-3개월) 정의 + 마일스톤
- 학생 후임 강사 매칭 (학부모 동의 포함)
- 노트/녹음 인수인계 (NFR-A-5 격리 하에서 — 후임 강사에게만 권한 이양)
- 학부모 안내 + 동의 절차
- 마지막 페이 정산 + 미수금 처리
- 강사 ↔ 학원 자산 (잠금, 카드, 키) 회수 체크리스트
- 퇴직 후 강사의 학생 접근 차단 (revocation)
- 분쟁 audit

**경계:**
- 노트/녹음 인수인계는 학원장이 후임 강사에게 권한을 명시 이양 — 자동 X
- 학생 데이터를 퇴직 강사 본인 디바이스에서 자동 삭제 X (앱 외부 통제 불가) — 정책 안내만
- 학원-강사 간 계약 종료 법적 절차는 앱 외부 (앱은 운영 보조)

## 2. 퇴직 유형

| 유형 | 신청자 | 사전 통보 | 인수인계 기간 | 페이 |
|---|---|---|---|---|
| 강사 자발 퇴직 | 강사 | D-30 권장 (학원 정책) | 30-90일 | 정상 |
| 학원장 해고 (성과·태도) | 학원장 | 사전 면담 → D-30 | 30일 (단축 가능) | 정책 |
| 즉시 해고 (중대 사유) | 학원장 | 없음 | 0-7일 | 정책 |
| 학원 폐업 | 학원장 | D-60 권장 | 60일 | 잔여 페이 + 보상 |
| 강사 사망/장기 입원 | 가족/시스템 | 없음 | 즉시 처리 | 정산 + 위로 |

## 3. 데이터 모델

```python
class AcademyTeacherOffboarding(Base):
    """강사 퇴직 1건 (1 강사 × 1 활성 퇴직)."""
    id = Column(PK)
    academy_id = Column(FK)
    teacher_member_id = Column(FK academy_members)
    type = Column(Enum("voluntary", "dismissed", "immediate_dismiss", "academy_closure", "incapacity"))
    initiated_by_user_id = Column(FK users)             # 강사 본인 또는 학원장 또는 시스템
    initiated_at = Column(DateTime)
    notice_date = Column(Date)                           # 퇴직 통보일
    last_working_date = Column(Date)                     # 마지막 근무일
    handover_starts_at = Column(Date)                    # 인수인계 시작
    handover_ends_at = Column(Date)                      # 인수인계 종료 (last_working_date 이전)
    state = Column(Enum(
        "requested",         # 신청됨, 학원장 검토 중
        "approved",          # 학원장 승인 → 인수인계 시작
        "rejected",          # 학원장 거절 (드물게 — 강사 자발 퇴직 거절 불가, 일정 협의만)
        "handover",          # 인수인계 진행 중
        "completed",         # 마지막 근무일 도달 + 모든 인수인계 완료
        "cancelled",         # 강사가 사전 철회 (학원장 동의 시)
    ))
    reason_note = Column(Text, nullable=True)
    decision_note = Column(Text, nullable=True)          # 학원장 결정 메모
    final_pay_amount = Column(Integer, nullable=True)    # 마지막 정산
    final_pay_paid_at = Column(DateTime, nullable=True)
    non_compete_signed_at = Column(DateTime, nullable=True)  # 학원장 정책 시 (학원법상 강제력 약함 — 동의서 형식)
    data_takeout_signed_at = Column(DateTime, nullable=True) # "본인 디바이스의 학원 데이터 삭제" 동의
    assets_returned_at = Column(DateTime, nullable=True)


class AcademyStudentHandover(Base):
    """학생 인수인계 1건 (퇴직 1건 × N 학생)."""
    id = Column(PK)
    offboarding_id = Column(FK)
    academy_student_id = Column(FK)
    new_teacher_member_id = Column(FK academy_members, nullable=True)  # 후임. NULL = 미정
    state = Column(Enum(
        "pending_assignment",   # 후임 미정
        "proposed",              # 후임 제안 (학부모 동의 대기)
        "parent_consented",      # 학부모 동의
        "parent_declined",       # 학부모 거절 (다른 강사 또는 학원 떠남)
        "completed",             # 인수 수업 1회 진행 완료
        "student_left",          # 학생이 강사 따라 학원 떠남
    ))
    proposed_at = Column(DateTime, nullable=True)
    parent_response_at = Column(DateTime, nullable=True)
    first_lesson_with_new_teacher_at = Column(DateTime, nullable=True)
    completion_confirmed_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)


class AcademyTeacherKnowledgeTransfer(Base):
    """학생별 인수인계 메모 (퇴직 강사 → 후임 강사). NFR-A-5 격리 예외."""
    id = Column(PK)
    handover_id = Column(FK)
    written_by_user_id = Column(FK users)                 # 퇴직 강사
    written_at = Column(DateTime)
    summary = Column(Text)                                # 요약 (학생 특성/진도/주의사항)
    suggested_pieces = Column(JSON)                       # 다음 곡 추천
    suggested_approach = Column(Text, nullable=True)      # 교습 방법 메모
    confidential_notes = Column(Text, nullable=True)      # 학원장 + 후임 강사만 (학부모 X)
    new_teacher_acknowledged_at = Column(DateTime, nullable=True)


class AcademyOffboardingAssetChecklist(Base):
    """자산 회수 체크리스트 (학원 정책)."""
    offboarding_id = Column(FK, PK1)
    item_key = Column(String, PK2)                        # "studio_key", "access_card", "ipad" 등
    item_label = Column(String)
    returned_at = Column(DateTime, nullable=True)
    confirmed_by_user_id = Column(FK users, nullable=True)
    note = Column(Text, nullable=True)
```

## 4. ① 퇴직 신청 흐름

### 4.1 강사 자발 퇴직 신청 (lesson-app)

```
┌──────────────────────────────────────────────┐
│ 퇴직 신청                                    │
├──────────────────────────────────────────────┤
│ ⚠ 학원장에게 신청서가 전달됩니다.            │
│                                              │
│ 마지막 근무 희망일: [2026-08-31]            │
│ (현재 06-04 — 88일 후)                       │
│                                              │
│ 인수인계 기간 희망: [▼ 60일 (권장)]         │
│                                              │
│ 사유: [▼ 개인 사정]                          │
│ 메모: [                                    ] │
│       [                                    ] │
│                                              │
│ 본인 담당 학생: 18명                        │
│ 인수인계 후보 강사: 김선생, 박선생 (학원 내) │
│                                              │
│ 동의 항목:                                   │
│ [✓] 학원 자산 (스튜디오 키 등) 마지막 근무일 │
│     반환                                     │
│ [✓] 학생 연락처/노트를 본인 디바이스에서    │
│     마지막 근무일 후 30일 내 삭제           │
│ [ ] 경업금지 (1년 / 동일 도시 내) — 학원장  │
│     정책 시 강제 표시                        │
│                                              │
│         [취소]  [퇴직 신청서 제출]          │
└──────────────────────────────────────────────┘
```

검증:
- 학원 정책상 사전 통보 기간 (예: D-30) 미만 시 경고
- 본인이 진행 중인 발표회 / 미완료 인수인계 있으면 경고
- 학원장에게 즉시 알림 (LNZ_TEACHER_OFFBOARDING_REQUEST)

### 4.2 학원장 콘솔 검토

```
┌──────────────────────────────────────────────────────┐
│ 이선생 퇴직 신청                                    │
├──────────────────────────────────────────────────────┤
│ 사유: 개인 사정                                     │
│ 메모: 이사로 인한 통근 불가                         │
│ 희망 마지막일: 2026-08-31 (88일 후)                │
│ 인수인계 기간: 60일                                 │
│                                                      │
│ 영향:                                               │
│ • 담당 학생: 18명 (인수인계 매칭 필요)              │
│ • 진행 중 발표회: 1건 (8/30 — 마지막일 1일 전 종료)│
│ • 미수금: 0건                                       │
│                                                      │
│ 학원장 결정:                                        │
│ ● 승인 (희망일 그대로)                              │
│ ○ 일정 조정 협의 요청 ([           ])              │
│ ○ 거절 (자발 퇴직은 거절 불가 — 일정 협의만 가능)  │
│                                                      │
│ 페이 처리: ● 정상  ○ 단축 (사유: [        ])      │
│                                                      │
│ 메모: [면담 결과 ...]                                │
│                                                      │
│         [면담 일정 잡기]  [승인 + 인수인계 시작]   │
└──────────────────────────────────────────────────────┘
```

### 4.3 학원장 주도 해고

학원장이 강사 상세 → "해고 절차 시작" → 본인이 type='dismissed' 또는 'immediate_dismiss' 등록. 강사에게 통보 알림 + 면담 일정 자동 제안.

해고 시 추가 검증:
- 사유 필수 (성과 / 태도 / 학부모 컴플레인 / 중대 위반)
- 중대 사유 (즉시 해고) 는 audit 영구 보존 (분쟁 대비)
- 학원장 본인 + 운영자 어드민 알림 (해고 비율 모니터링)

## 5. ② 인수인계 기간 (handover state)

### 5.1 학생별 후임 강사 매칭

학원장이 `/students/handover/{offboarding_id}` 진입:

```
┌──────────────────────────────────────────────────────┐
│ 이선생 학생 인수인계 (18명)                         │
├──────────────────────────────────────────────────────┤
│ 김지민 (피아노 5학년 / 등록 2024-09)                │
│   후임 후보: ▼ [김선생 (가용 ★★★ / 라포 ★★)]    │
│   학부모 동의: 대기                                  │
│   [학부모에게 제안]                                  │
│                                                      │
│ 박지수 (바이올린 4학년 / 등록 2025-03)              │
│   후임 후보: ▼ [없음 — 외부 채용 필요]              │
│   상태: 모집 중                                      │
│   [채용 시작]                                        │
│                                                      │
│ 이지호 (피아노 3학년)                               │
│   후임 후보: ▼ [박선생]                             │
│   학부모 동의: ✓ 6/8 동의                           │
│   첫 수업: 7/5 16:00 (예정)                         │
│ ...                                                  │
└──────────────────────────────────────────────────────┘
```

매칭 알고리즘 ([teacher_absence_and_substitute_spec.md §4.1](teacher_absence_and_substitute_spec.md)) 재사용 + 인수인계 특화 신호:
- 같은 악기 자격 (40)
- 가용 슬롯 충분 (30)
- 라포 — 같은 학생 가르친 적 있음 (15) 또는 학원 내 같은 강사 (대기실 등에서 본 적)
- 학생 학년/연령 경험 (10)
- 후임 강사 본인 수락 (5)

### 5.2 학부모 동의 흐름

학원장이 "학부모에게 제안" → 학부모 lesson-app:

```
┌──────────────────────────────────────────────┐
│ 강사 변경 안내                              │
├──────────────────────────────────────────────┤
│ 김지민 학생의 피아노 담당 강사가            │
│ 변경됩니다.                                  │
│                                              │
│ 사유: 이선생 퇴직 (2026-08-31)              │
│ 후임: 김선생                                │
│   • 같은 학원 강사 (3년 차)                 │
│   • 담당 학생 수: 12명                      │
│   • 자격: 클래식 피아노 전공                │
│   [김선생 프로필 보기]                       │
│                                              │
│ 첫 수업 예정: 2026-07-05 16:00              │
│   (현재 6/4 — 변경 전 적응 기간 4주)        │
│                                              │
│ 학원장 메시지:                              │
│ "이선생의 교습 방향을 김선생에게            │
│  자세히 전달했습니다. 안심하셔도 됩니다."   │
│                                              │
│ ● 동의합니다                                │
│ ○ 다른 강사로 부탁드립니다                  │
│ ○ 학원 등록을 종료합니다                    │
│                                              │
│           [제출]                            │
└──────────────────────────────────────────────┘
```

학부모 거절 시:
- "다른 강사" → 학원장에게 알림, 재매칭
- "등록 종료" → 학생 상태 alumni 마킹 + 학부모 후속 안내 (퇴직 강사 따라 외부 갈 위험 → 학원장에게 추적 권장)

### 5.3 노트/녹음 인수인계 (NFR-A-5 격리 하)

기본 원칙: 강사는 본인 담당 학생의 노트만 작성/열람 ([context_toggle_spec.md §6](context_toggle_spec.md)). 후임 강사는 학생을 인계받기 전 노트 열람 불가.

**인수인계 권한 이양 흐름:**

```
1. 학부모 동의 (§5.2 parent_consented)
   ↓
2. 학원장이 후임 강사에게 "인수인계 권한 부여" 클릭
   ↓
3. 후임 강사 lesson-app 에 "김지민 학생 인수인계 메모 작성 권한 부여됨" 알림
   ↓
4. 퇴직 강사가 AcademyTeacherKnowledgeTransfer 작성:
   - 요약 (학생 특성, 진도, 주의사항)
   - 다음 곡 추천
   - 교습 방법 메모
   - confidential_notes (학원장 + 후임만)
   ↓
5. 후임 강사가 인수인계 메모 + 학생 노트 (퇴직 강사 작성) 열람 가능
   - 첫 수업 시각 24h 전부터 열람
   - 첫 수업 후 영구 권한 (해당 학생 담당)
   ↓
6. 퇴직 강사는 first_lesson_with_new_teacher_at 시점에 해당 학생 노트 read-only 전환
   - 마지막 근무일까지 read-only 유지
   - 마지막 근무일 이후 학생 노트 접근 차단 (NFR-A-5)
```

### 5.4 인수인계 첫 수업 (with both teachers — 옵션)

학원장이 "이중 출석" 토글 — 첫 수업에 퇴직 강사 + 후임 강사 둘 다 참석 (학원장 정책 — 라포 전환 부드럽게). 학부모에게 사전 안내.

페이 처리: 첫 수업은 양쪽 50/50 (학원 정책) 또는 후임 100% (학원 정책).

### 5.5 인수인계 진행 추적

학원장 대시보드 Action Box:
- "이선생 퇴직 D-45 / 학생 18명 중 12명 후임 매칭 완료"
- 미매칭 학생은 빨강 강조 → 클릭 시 매칭 화면

매칭 완료 % 가 마지막일 D-7 까지 100% 미만이면 학원장 긴급 알림 ("D-7 까지 후임 미정 학생 N명 — 외부 채용 또는 학생 양해 필요").

## 6. ③ 마지막 페이 정산

### 6.1 마지막 근무일 도래 (cron 매일 00:00)

```python
def process_offboarding_on_last_day():
    for offboarding in db.query(AcademyTeacherOffboarding).filter(
        state='handover',
        last_working_date=today,
    ):
        # 1. 마지막 페이 계산
        period_year, period_month = today.year, today.month
        last_pay = calculate_final_pay(offboarding)

        # 2. AcademySettlement 행 생성 (final flag)
        settlement = AcademySettlement(
            academy_id=offboarding.academy_id,
            teacher_member_id=offboarding.teacher_member_id,
            period_year=period_year,
            period_month=period_month,
            calculated_amount=last_pay,
            status='draft',
            breakdown={
                'is_final_settlement': True,
                'offboarding_id': offboarding.id,
                ...
            }
        )

        # 3. 학원장 알림
        notify_owner(
            "이선생 마지막 근무일. 최종 정산 명세 검토 + 송금 필요"
        )

        # 4. state 변경 (완료 전 마지막 단계)
        offboarding.state = 'completed' if all_handovers_done(offboarding) else 'handover'
```

### 6.2 최종 정산 명세 (학원장)

```
┌──────────────────────────────────────────────────────┐
│ 이선생 최종 정산 (2026-08)                          │
├──────────────────────────────────────────────────────┤
│ 8월 정상 페이:        ₩1,800,000                    │
│ 인수인계 첫 수업 (50%): +₩200,000                   │
│ 미사용 휴가 보상:     +₩300,000 (학원 정책)         │
│ 자산 미반환 차감:     -₩50,000 (스튜디오 키 분실)   │
│ 미수금 분담:          -₩100,000 (학원 정책)         │
│ ─────────────────────────────────────────────────── │
│ 최종 송금액:          ₩2,150,000                    │
│                                                      │
│ [수정]  [강사 서명 요청]                            │
│                                                      │
│ ⚠ 강사 서명 후 송금 처리 + state='completed'        │
└──────────────────────────────────────────────────────┘
```

강사가 서명 후 (`AcademySettlement.teacher_acknowledged_at`) 학원장이 외부 송금 → "송금 완료" 클릭 → `final_pay_paid_at` + `state='completed'`.

### 6.3 분쟁 (강사가 정산 이의)

강사가 `teacher_dispute_note` 작성 → 학원장 검토 → 조정 → 재서명. ([billing_settlement_spec.md §6.7](billing_settlement_spec.md) audit trail 와 동일)

미합의 시 운영자 어드민 또는 외부 노무 자문 (앱 외부) — 앱은 audit 보존만.

## 7. 자산 회수 체크리스트

학원 정책으로 사전 등록된 자산 항목 (예: `studio_key`, `access_card`, `ipad`, `instruction_book`):

```
┌──────────────────────────────────────────────┐
│ 자산 회수 체크리스트 - 이선생                │
├──────────────────────────────────────────────┤
│ [✓] 스튜디오 키 (8/31 회수)                 │
│ [✓] 출입카드 (8/31 회수)                    │
│ [ ] iPad #3 — 마지막 근무일 미반환          │
│     사유: 분실 → ₩50,000 차감 (§6.2)        │
│ [✓] 교재 (5권)                              │
│                                              │
│ 마지막 근무일까지 미반환 항목은            │
│ 최종 정산에서 차감됩니다.                    │
└──────────────────────────────────────────────┘
```

## 8. 퇴직 후 강사 권한 차단

### 8.1 즉시 차단 (`state='completed'` 도달 시)

- 강사 JWT 즉시 revocation
- AcademyMember.access_revoked_at 기록
- 모든 학생 노트/녹음 접근 차단 (강사 lesson-app 진입 시 "더 이상 이 학원에 소속되어 있지 않습니다" 안내)
- 학원 카톡 채널 관리자 권한 회수 (학원장 수기 처리 — 카카오 자체 권한)

### 8.2 lesson-app 잔존 데이터

강사 본인 디바이스의 lesson-app 캐시 (오프라인 모드 데이터, Hive 캐시) 는 다음 진입 시 자동 무효화:
- 401 응답 받으면 학원 관련 캐시 모두 wipe
- 학생 노트 / 연락처 / 녹음 모두 삭제
- 사용자에게 "퇴직 처리로 인해 학원 데이터가 삭제되었습니다" 안내

### 8.3 본인 디바이스 외부 백업

앱은 통제 불가. 다음으로 보호:
- 신청서 §4.1 의 동의 항목 "마지막 근무일 후 30일 내 삭제"
- 분쟁 시 audit + 동의서가 증거 (앱 외부 법적 절차 보조)

## 9. 학부모 안내 (자동 일괄)

### 9.1 퇴직 발표 시점 (학원장 결정)

학원장이 퇴직 공지 시점을 선택:
- 모든 인수인계 매칭 완료 후 (권장)
- 일부 미매칭 상태에서도 발표 (마지막 근무일 D-30 같은 정책)

발표 시 모든 학부모에게 카톡:
- "이선생이 8/31 퇴직합니다. 자녀의 후임 강사는 추후 개별 안내드립니다."
- 학원장 메시지 첨부 (감사 + 안심)

### 9.2 학부모 추적 (퇴직 강사 따라 외부 가는지)

§5.2 에서 "등록 종료" 선택한 학생의 사유 분석:
- 단순 학원 떠남 vs 퇴직 강사 따라 외부
- 학원장이 사후 인터뷰 (선택) → AuditLog

학원 보호 정책 (해당 학원에 명시 동의 시):
- 강사 경업금지 조항 (한국 학원법상 강제력 약함 — 동의서 형식)
- 학생 follow 행위 의심 시 강사 평판에 기록 (다른 학원 채용 시 참고)

## 10. 강사 평가 + 평판 기록

### 10.1 퇴직 시 학원장 평가

```
┌──────────────────────────────────────────────┐
│ 이선생 퇴직 평가                            │
├──────────────────────────────────────────────┤
│ 종합: ★★★★☆ (5점 만점 4점)                 │
│                                              │
│ 교습 품질:     [★★★★★]                     │
│ 학부모 만족:   [★★★★☆]                     │
│ 동료 협업:     [★★★★☆]                     │
│ 시간 약속:     [★★★☆☆]                     │
│ 인수인계 협조: [★★★★★]                     │
│                                              │
│ 다음 학원에서 재채용 가능? [예 / 아니오]     │
│ 메모: [...]                                  │
└──────────────────────────────────────────────┘
```

### 10.2 운영자 어드민 평판 DB

(시스템 전체 — 학원 간 강사 이동 추적)

- 강사가 다른 학원에 신규 채용 시 이전 학원 평가 조회 가능 (강사 동의 필수)
- 즉시 해고 / 분쟁 강사는 별도 플래그
- 강사 본인이 본인 평판 조회 가능 + 이의 제기

## 11. 권한 / 보안

- 퇴직 신청: 강사 본인 (`Depends(current_teacher)`) 또는 학원장
- 학원장 승인/일정 조정: `Depends(current_academy_owner)`
- 학생 인수인계 매칭: 학원장 + 후임 강사 수락
- 노트 권한 이양: 학원장만 명시 트리거
- 최종 정산: 학원장 + 강사 서명
- 평판 DB: 운영자 어드민 + 강사 본인 + 채용 시도 학원장 (강사 동의 필요)

## 12. 알림 / 카톡 템플릿

| 템플릿 | 시점 | 본문 요약 |
|---|---|---|
| `LNZ_TEACHER_OFFBOARDING_REQUEST` | §4.1 학원장 | "{teacher} 퇴직 신청 검토 필요" |
| `LNZ_TEACHER_OFFBOARDING_APPROVED` | §4.2 강사 | "{owner} 퇴직 승인. 인수인계 시작" |
| `LNZ_HANDOVER_PROPOSED_PARENT` | §5.2 학부모 | 후임 강사 안내 + 동의 요청 |
| `LNZ_HANDOVER_FIRST_LESSON` | §5.4 학부모 | 첫 수업 안내 |
| `LNZ_OFFBOARDING_FAREWELL` | §9.1 모든 학부모 | 학원장 작성 감사 메시지 |
| `LNZ_OFFBOARDING_FINAL_PAY` | §6.2 강사 | 최종 정산 명세 + 서명 요청 |

## 13. 비기능

- 학생 18명 인수인계 매칭 알고리즘 < 1초
- 노트 권한 이양 처리 < 500ms (양쪽 강사 즉시 반영)
- 학부모 일괄 알림 < 1분 (학원 100명 기준)

## 14. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 학원 내 후임 강사 0명 (모두 가용 슬롯 부족) | 외부 채용 필요 → 학원장 모객 시작 |
| 학부모 거절 후 학원 떠남 → 강사 따라 외부 의심 | 학원장에게 사후 인터뷰 권장 + 평판 DB 플래그 |
| 마지막 근무일 D-7 까지 후임 미정 학생 다수 | 학원장 긴급 알림 + 일정 연장 권유 |
| 강사가 인수인계 메모 작성 거부 | 학원장 ↔ 강사 분쟁 → 최종 페이 차감 정책 |
| 강사가 마지막 근무일 후에도 학원 학생에게 카톡 (앱 외부) | 학원장 신고 → 평판 DB 플래그 + 법적 자문 (앱 외부) |

## 15. 변경 이력

- 2026-06-04: 초안 (후속 후보 #1 응답: 강사 이직 시 학생 데이터 인수인계 흐름. 퇴직 5유형 + 학원장 승인/협의 + 학생별 후임 매칭 + NFR-A-5 권한 이양 흐름 + 노트 인수인계 메모 + 자산 회수 체크리스트 + 최종 정산 + 강사 권한 차단 + 평판 DB)
