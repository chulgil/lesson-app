# academy/teacher_absence_and_substitute_spec — 학원 강사 휴가·대강 운영

> 기준일: 2026-06-04
> 경로: `/teachers/{id}/absences`, `/coverage/queue`
> 마일스톤: AC-M5 (휴가 승인 MVP) / AC-M7 (대강 매칭 + 페이 분배)
> 선행: [../../schedule/teacher_vacation_mode.md](../../schedule/teacher_vacation_mode.md), [teacher_management_spec.md](teacher_management_spec.md), [teacher_cancellation_policy_spec.md](teacher_cancellation_policy_spec.md), [billing_settlement_spec.md §6](billing_settlement_spec.md), [academy_schedule_authority_spec.md](academy_schedule_authority_spec.md)
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` H#1

## 1. 배경 / 범위

### 1.1 개인 강사 휴가 vs 학원 소속 강사 휴가

[../../schedule/teacher_vacation_mode.md](../../schedule/teacher_vacation_mode.md) (#431) 는 **개인 강사**(학원 소속 X) 의 휴가 모드 정의:
- 강사 본인이 휴가 등록 → 자동 처리 (rollForward / freeCancel / makeupCredit)
- 다른 사람 승인 불필요

**학원 소속 강사**는 다음이 다르다:
- 학원장 사전 승인 필요 (학원 정책에 따라)
- 대강 강사 매칭이 가능 (학원 내 다른 강사 또는 외부 대강 풀)
- 페이 분배 정책 (휴가 강사 vs 대강 강사)
- 학원 마스터 스케줄 영향 (다른 강사 일정과 충돌 방지)
- 분쟁 처리 (학원장 ↔ 강사 ↔ 학부모)

본 스펙은 학원 컨텍스트의 강사 휴가/결근/대강 흐름을 정의한다.

### 1.2 휴가 사유 분류

| 유형 | 사전 통보 | 학원장 승인 | 페이 처리 |
|---|---|---|---|
| 정기 휴가 (개인 사유) | D-30 이상 | 필요 | 학원 정책 (유급 / 무급) |
| 병가 | 당일 가능 | 사후 확인 | 학원 정책 (유급 + 진단서) |
| 경조사 (결혼/장례) | D-7 이상 | 자동 승인 | 보통 유급 |
| 출장 (학원 일) | 학원장 지시 | (학원장이 등록) | 유급 |
| 무단 결근 | (없음) | 사후 페널티 | 무급 + 페널티 |

## 2. 데이터 모델

```python
class AcademyTeacherAbsence(Base):
    """학원 강사의 부재 신청/등록 (1 강사 × N 부재)."""
    id = Column(PK)
    academy_id = Column(FK)
    teacher_member_id = Column(FK academy_members)
    type = Column(Enum("vacation", "sick", "bereavement", "wedding", "training", "owner_assigned"))
    requested_at = Column(DateTime)
    requested_by_user_id = Column(FK users)              # 강사 본인 또는 학원장
    starts_at = Column(DateTime)
    ends_at = Column(DateTime)
    reason_note = Column(Text, nullable=True)
    attachment_url = Column(String, nullable=True)       # 진단서/사망진단서 등
    state = Column(Enum(
        "requested",        # 강사가 신청, 학원장 검토 중
        "approved",          # 학원장 승인
        "rejected",          # 학원장 거절
        "cancelled",         # 강사가 사전 취소
        "auto_logged",       # 학원장이 직접 등록 (당일 병가/무단결근)
    ))
    approved_at = Column(DateTime, nullable=True)
    approved_by_user_id = Column(FK users, nullable=True)
    rejected_reason = Column(Text, nullable=True)
    pay_treatment = Column(Enum("paid", "unpaid", "policy_default"), default="policy_default")
    coverage_strategy = Column(Enum(
        "internal_substitute",   # 학원 내 다른 강사가 대강
        "external_substitute",   # 외부 대강 풀
        "reschedule",            # 학생들 일정 재조정
        "free_cancel",           # 학생 무료 취소 (학원 손실)
        "makeup_credit",         # 보강 크레딧 적립
    ), nullable=True)


class AcademyAbsencePolicy(Base):
    """학원 단위 부재 정책 (1 학원 = 1 행)."""
    academy_id = Column(FK, PK)
    vacation_advance_days = Column(Integer, default=30)
    vacation_max_days_per_year = Column(Integer, default=15)
    sick_advance_hours = Column(Integer, default=0)              # 당일 통보 허용
    bereavement_paid_days = Column(Integer, default=5)
    no_show_penalty_amount = Column(Integer, default=100000)     # 무단 결근 페널티 (학원 정책)
    no_show_penalty_strikes = Column(Integer, default=3)          # N회 누적 시 추가 조치
    default_coverage_strategy = Column(Enum(...), default="internal_substitute")
    substitute_pay_pct = Column(Float, default=0.6)              # 대강 강사가 받는 비율
    absent_teacher_pay_pct = Column(Float, default=0.4)          # 휴가 강사 잔여 비율 (유급 시)


class AcademyLessonCoverage(Base):
    """대강 1건 = 1 레슨 × 1 대강 강사."""
    id = Column(PK)
    absence_id = Column(FK)
    original_lesson_id = Column(FK lesson_bookings)
    original_teacher_member_id = Column(FK academy_members)
    substitute_teacher_member_id = Column(FK academy_members, nullable=True)  # 외부면 NULL + name 필드
    substitute_external_name = Column(String, nullable=True)      # 외부 대강 강사명 (FK 없음)
    state = Column(Enum(
        "matching",          # 대강 강사 찾는 중
        "offered",           # 후보에게 제안됨
        "confirmed",         # 대강 강사 수락
        "declined",          # 후보 거절
        "completed",         # 대강 완료
        "no_show",           # 대강 강사도 결근
    ))
    offered_at = Column(DateTime, nullable=True)
    confirmed_at = Column(DateTime, nullable=True)
    pay_amount = Column(Integer, nullable=True)                   # 대강 보수 (수기 또는 자동)
    parent_notified_at = Column(DateTime, nullable=True)
    parent_acknowledged_at = Column(DateTime, nullable=True)


class AcademyTeacherAbsenceQuota(Base):
    """강사별 연간 부재 사용량 (1 강사 × 연도 = 1 행)."""
    academy_id = Column(FK, PK1)
    teacher_member_id = Column(FK, PK2)
    year = Column(Integer, PK3)
    vacation_days_used = Column(Integer, default=0)
    sick_days_used = Column(Integer, default=0)
    no_show_strikes = Column(Integer, default=0)
    last_updated_at = Column(DateTime)
```

## 3. 강사 휴가 신청 → 학원장 승인 흐름

### 3.1 강사 lesson-app UX

```
┌──────────────────────────────────────────────┐
│ 휴가 신청                                    │
├──────────────────────────────────────────────┤
│ 종류: [▼ 정기 휴가]                          │
│ 시작: [2026-07-15]                          │
│ 종료: [2026-07-20] (6일)                    │
│ 사유: [가족 여행                       ]    │
│ 첨부: [+ 파일] (필요 시)                    │
│                                              │
│ ⓘ 휴가 한도: 9/15일 (올해 6일 사용 가능)   │
│ ⓘ 학원장 승인 필요. 평균 응답 D-2.         │
│                                              │
│         [취소]   [신청 제출]                 │
└──────────────────────────────────────────────┘
```

검증:
- D-30 이상 사전 통보 (정기 휴가)
- 연간 한도 초과 시 경고
- 동일 기간 중복 신청 차단

### 3.2 학원장 콘솔 알림 + 검토

학원장 대시보드 Action Box 에 "이선생 휴가 신청 (7/15-7/20) 검토 필요" → `/teachers/{id}/absences/{id}` 진입.

```
┌──────────────────────────────────────────────────────┐
│ 이선생 휴가 신청                                    │
├──────────────────────────────────────────────────────┤
│ 종류: 정기 휴가                                     │
│ 기간: 7/15 ~ 7/20 (6일)                            │
│ 사유: 가족 여행                                     │
│                                                      │
│ 영향 레슨: 23건 (학생 16명)                         │
│ 다른 강사 일정 충돌: 없음                            │
│                                                      │
│ 처리 방안:                                          │
│ ● 내부 대강 (김선생 / 박선생 가용)                  │
│ ○ 외부 대강 풀                                      │
│ ○ 학생들 일정 재조정                                │
│ ○ 무료 취소 (학원 손실 ₩460,000)                   │
│ ○ 보강 크레딧 적립                                  │
│                                                      │
│ 페이 처리: ● 유급  ○ 무급  ○ 학원 정책 기본        │
│                                                      │
│         [거절]   [승인 + 대강 매칭 시작]            │
└──────────────────────────────────────────────────────┘
```

### 3.3 승인 처리

```
POST /api/v1/academies/{id}/teacher-absences/{id}/approve
{
  coverage_strategy: "internal_substitute",
  pay_treatment: "paid",
}

처리:
1. AcademyTeacherAbsence.state='approved'
2. coverage_strategy 에 따라 §4 대강 매칭 또는 §5 학생 처리
3. 강사에게 알림 (LNZ_ABSENCE_APPROVED)
4. AcademyTeacherAbsenceQuota.vacation_days_used += 6
```

거절 시 사유 필수 + 강사에게 알림. 강사가 일정 조정 후 재신청 가능.

### 3.4 당일 병가 (긴급)

강사가 당일 아침 lesson-app 에서:

```
┌──────────────────────────────────────────────┐
│ 긴급 결근 통보                              │
├──────────────────────────────────────────────┤
│ 사유: ● 병가  ○ 가족 응급  ○ 기타        │
│ 첨부: [진단서 사진] (사후 24h 내 첨부)     │
│ 메모: [열이 39도까지 올라서 ...]           │
│                                              │
│ ⚠ 오늘 영향 레슨: 6건                       │
│ ⚠ 학원장이 즉시 대강을 찾습니다.            │
│                                              │
│         [긴급 통보 보내기]                  │
└──────────────────────────────────────────────┘
```

처리:
1. AcademyTeacherAbsence state='requested', type='sick'
2. 학원장에게 즉시 카톡 + 푸시 (LNZ_TEACHER_EMERGENCY_ABSENCE)
3. 학원장 1탭 승인 → §4 긴급 대강 매칭
4. 사후 진단서 첨부 (24h 내 미첨부 시 학원장 확인 필요)

## 4. 대강 강사 매칭

### 4.1 내부 대강 매칭 알고리즘

학원 내 다른 강사 후보 자동 산출. 매칭 점수 (0-100):

| 신호 | 가중치 | 산출 |
|---|---|---|
| 같은 악기 자격 | 40 | 같은 instruments 보유 시 만점 |
| 해당 시간 가용 | 30 | TeacherAvailability + 기존 booking 충돌 없음 |
| 최근 1개월 대강 빈도 | 15 | 적게 한 강사 우대 (공평성) |
| 같은 학생 가르친 적 있음 | 10 | 학생과 라포 유지 |
| 강사 본인 대강 의향 토글 | 5 | "대강 가능" 토글 ON 강사 우대 |

상위 3명을 학원장에게 제안:

```
┌──────────────────────────────────────────────────────┐
│ 대강 강사 후보 (7/15-7/20 23건)                     │
├──────────────────────────────────────────────────────┤
│ 1. 김선생  점수 87  (가용 100%, 같은 악기, 라포)    │
│ 2. 박선생  점수 72  (가용 70%, 같은 악기)           │
│ 3. 최선생  점수 58  (가용 50%, 다른 악기 - 일부 가능)│
│                                                      │
│ [김선생에게 일괄 제안]  [개별 레슨별로 다른 강사]   │
└──────────────────────────────────────────────────────┘
```

### 4.2 후보 강사 수락 흐름

학원장이 김선생에게 일괄 제안 → 김선생 lesson-app:

```
┌──────────────────────────────────────────────┐
│ 이선생 대강 요청                            │
├──────────────────────────────────────────────┤
│ 기간: 7/15 ~ 7/20 (6일)                    │
│ 레슨: 23건                                  │
│ 대강 보수: 학원 정책 기준                   │
│   (수강료의 60% = ₩276,000 예상)            │
│                                              │
│ 본인 일정과 충돌:                            │
│ • 7/16 14:00 본인 학생 충돌 — 자동 제외     │
│                                              │
│ 수락 가능 레슨: 21건                        │
│                                              │
│         [거절]   [21건 모두 수락]           │
│         [레슨별로 선택 ▼]                    │
└──────────────────────────────────────────────┘
```

### 4.3 외부 대강 풀

학원에 외부 대강 강사 풀이 등록되어 있으면 (학원 정책 — 자격 검증 사전 완료) 학원장이 외부 강사 이름 + 연락처 수기 입력 → `substitute_external_name` 저장. 외부 강사 페이는 학원장이 외부 송금 (앱은 마킹만).

### 4.4 학부모 알림 (대강 확정 후)

```
[Lessonaza] 알림
김지민 학생의 7/16(목) 16:00 피아노 레슨
이선생 → 김선생 (대강)
사유: 강사 휴가
[일정 확인]  [질문]
```

학부모 acknowledged 클릭 → `parent_acknowledged_at`. 미클릭 시 24h 후 카톡 재발송.

### 4.5 학부모 거부 옵션

학부모가 "다른 강사 대신 보강을 원합니다" 선택 → 해당 레슨만 `coverage_strategy='makeup_credit'` 으로 변경. 보강 크레딧 1회 자동 적립 ([../../subscription/makeup_credit_spec.md](../../subscription/makeup_credit_spec.md)).

## 5. 대강 외 처리 옵션

### 5.1 일정 재조정 (reschedule)

학원장이 영향 학생에게 새 일정 옵션 제안. [teacher_cancellation_policy_spec.md](teacher_cancellation_policy_spec.md) 의 12h 정책 적용. 학생이 동의 시 재예약, 거부 시 보강 크레딧.

### 5.2 무료 취소 (free_cancel)

학원 손실 감수. `LessonBooking.status='cancelled'` + 학원 정책에 따라 학부모 청구 차감. 학원 매출 ↓.

### 5.3 보강 크레딧 (makeup_credit)

각 영향 학생에게 보강 크레딧 1회 적립. 학생이 추후 사용. ([makeup_credit_spec.md](../../subscription/makeup_credit_spec.md) §4.1)

## 6. 페이 분배

### 6.1 정책 (학원 단위)

`AcademyAbsencePolicy`:
- `absent_teacher_pay_pct=0.4`: 휴가 강사가 받는 비율 (유급 시 — 학원 정책)
- `substitute_pay_pct=0.6`: 대강 강사가 받는 비율
- 합산 = 1.0 (원래 강사 페이의 100%) — 학원 손실 없음

### 6.2 실제 정산 처리

월말 정산 시 ([billing_settlement_spec.md §6](billing_settlement_spec.md)):

```
원래 이선생 5월 페이 (23건 휴가 영향):
  - 휴가 처리되지 않았다면: ₩460,000
  - 휴가 처리 (유급 40%): ₩184,000
  
김선생 (대강 21건):
  - 대강 보수 (60%): ₩252,000
  
이선생 미처리 2건 (김선생이 충돌로 못한 것):
  - 외부 대강 또는 무료 취소
  - 외부 대강 ₩24,000 → 외부 강사
```

각 강사 명세서 ([billing_settlement_spec.md §6.4](billing_settlement_spec.md)) 에 대강 내역 별도 표시.

### 6.3 무급 휴가

`pay_treatment='unpaid'` 시 휴가 강사 페이 0. 대강 강사가 100% 수령. 학원 손실 없음.

## 7. 무단 결근 처리

### 7.1 감지

레슨 시작 시각 15분 후에도 강사 출근 체크 없음 + 학생 도착 알림 → 학원장에게 긴급 알림 (LNZ_TEACHER_NO_SHOW).

학원장이 강사에게 즉시 카톡 → 응답 없으면 §3.4 긴급 결근 흐름 또는 `type='no_show'` 자동 등록.

### 7.2 페널티 (학원 정책)

- `AcademyTeacherAbsenceQuota.no_show_strikes += 1`
- 페널티 금액 학원 정책 (`no_show_penalty_amount`)
- 다음 정산에서 차감
- N회 누적 시 (`no_show_penalty_strikes`) 추가 조치 (학원장 결정 — 면담/계약 종료)

### 7.3 분쟁 audit

무단 결근 → 강사 이의 제기 가능 (예: "학원장에게 전날 연락했는데 못 봤다"). 학원장이 audit 검토 후 페널티 조정/취소.

## 8. 학원 마스터 스케줄 영향

[academy_schedule_authority_spec.md](academy_schedule_authority_spec.md) 의 마스터 스케줄 뷰에 휴가 표시:

- 휴가 강사의 해당 기간 모든 슬롯 → 회색 / "휴가" 라벨
- 대강 확정 슬롯 → 노란색 / "대강: {강사명}" 라벨
- 충돌 가능성 자동 감지 + 학원장 알림

## 9. 권한 / 보안

- 강사 휴가 신청: `Depends(current_teacher)` + academy_member 본인 검증
- 학원장 승인/거절: `Depends(current_academy_owner)`
- 대강 매칭 / 페이 분배: 학원장 전용 + AuditLog
- 강사 본인 quota 조회: 본인 + 학원장
- 첨부 (진단서) 는 학원장 + 운영자 어드민만 (다른 강사 차단)

## 10. 알림 / 카톡 템플릿

| 템플릿 | 시점 | 본문 요약 |
|---|---|---|
| `LNZ_ABSENCE_REQUESTED` | §3.2 학원장 검토 | "{teacher} 휴가 신청 검토 필요" |
| `LNZ_ABSENCE_APPROVED` | §3.3 강사 알림 | "{owner} 학원장이 휴가 승인" |
| `LNZ_ABSENCE_REJECTED` | 강사 알림 | "휴가 거절: {reason}" |
| `LNZ_TEACHER_EMERGENCY_ABSENCE` | §3.4 학원장 즉시 | "{teacher} 긴급 결근 통보 — 대강 매칭 필요" |
| `LNZ_COVERAGE_OFFERED` | §4.2 후보 강사 | "이선생 대강 요청 N건" |
| `LNZ_COVERAGE_CONFIRMED_PARENT` | §4.4 학부모 | "{student} 레슨 대강 안내" |
| `LNZ_TEACHER_NO_SHOW` | §7.1 학원장 긴급 | "{teacher} 무단 결근 의심 — 즉시 확인" |

## 11. 비기능

- 긴급 결근 알림 < 30초 (학원장에게)
- 대강 매칭 알고리즘: 학원 강사 20명 기준 < 500ms
- 학부모 일괄 알림 < 1분 (영향 학생 50명)

## 12. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 대강 후보 0명 (모두 충돌/거절) | 학원장에게 알림 → 외부 대강 또는 무료 취소 선택 |
| 대강 강사도 결근 | `state='no_show'` + 2차 대강 매칭 자동 시작 |
| 학부모가 대강 거부 → 보강 크레딧으로 전환 | 자동 처리 + 학원장 알림 (학원 손실 추적) |
| 휴가 신청 후 강사가 사전 취소 | `state='cancelled'` + 대강 강사들에게 알림 |
| 강사가 휴가 도중 복귀 (예: 가족 응급 해결) | 잔여 휴가일 환불 (quota 차감 복구) |

## 13. 변경 이력

- 2026-06-04: 초안 (갭분석 H#1 응답: 학원 강사 휴가/대강 부재 해소. #431 개인 강사 휴가 모드와 분리 + 학원 컨텍스트 추가 — 학원장 승인 / 내부 대강 매칭 알고리즘 / 페이 분배 정책 / 학부모 알림 + 거부 옵션 / 무단 결근 페널티 / 마스터 스케줄 영향. 모든 페이는 학원 단위 정책 + 송금 수기)
