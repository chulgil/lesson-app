# academy/student_retention_signals_spec — 학생 이탈 조기 신호 + 위험 플래그

> 기준일: 2026-06-04
> 경로: `/students/at-risk`, `/students/{id}/risk-history`
> 마일스톤: AC-M5 (위험 점수 MVP) / AC-M7 (코호트 분석)
> 선행: [student_management_spec.md §9](student_management_spec.md), [teacher_management_spec.md](teacher_management_spec.md), [dashboard_spec.md §3.6](dashboard_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1 R-AO-22
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` H#2 (학생 이탈 조기 신호 부재)

## 1. 배경 / 범위

[student_management_spec.md §9 학생 이탈](student_management_spec.md) 은 **이미 이탈 의사를 표명한 학생**의 처리 흐름을 정의한다. 본 스펙은 **이탈 의사 표명 전 단계**의 조기 신호를 감지하고 학원장이 개입할 시점을 제공한다.

소규모 음악학원의 이탈 패턴 (시장조사 기반):
- 학생/학부모는 보통 1-2개월 동안 점차 결석 → 결국 "다음 달부터 안 다닐게요" 1회 통보
- 강사는 학생이 흥미를 잃은 신호를 가장 먼저 감지하지만 학원장과 공유 채널 부재
- 학원장이 알아챘을 때는 이미 늦음

**본 스펙 범위:**
- 위험 점수(0-100) 자동 산출 (출석/진도/컴플레인/강사 플래그)
- 강사 → 학원장 위험 플래그 채널 (NFR-A-5 권한 격리 하에서)
- 임계치 자동 알림
- 학원장 개입 액션 (수기 — 자동 조치 없음)
- 이탈 후 retrospective + 코호트 분석

**경계:** 본 스펙은 **신호 감지 + 알림**까지만 책임진다. 학원장이 학생에게 직접 연락하거나 강사 매칭 변경 같은 액션은 기존 흐름 ([student_management_spec.md](student_management_spec.md), [teacher_management_spec.md](teacher_management_spec.md)) 으로 이어진다.

## 2. 데이터 모델

```python
class AcademyStudentRiskSignal(Base):
    """학생별 위험 신호 누적. 한 학생당 신호 종류별 1행 + 점수 누적."""
    id = Column(PK)
    academy_id = Column(FK)
    academy_student_id = Column(FK)
    signal_type = Column(Enum(
        "attendance_drop",      # 출석률 임계치 미달
        "progress_stagnation",  # 진도 N주 정체
        "complaint_repeated",   # 학부모 컴플레인 N회
        "teacher_flag",         # 강사가 명시적 플래그
        "payment_late",         # 미수금 N일
        "lesson_cancel_repeat", # 학생 사유 취소 N회
    ))
    severity = Column(Integer)              # 1-10 (계산 가중치)
    raised_at = Column(DateTime)
    raised_by_user_id = Column(FK, nullable=True)  # 강사 플래그는 강사, 그 외는 시스템
    raised_by_source = Column(Enum("system", "teacher", "owner"))
    context = Column(JSON)                  # signal_type 별 컨텍스트 (예: 출석률 X%)
    resolved_at = Column(DateTime, nullable=True)
    resolved_by_user_id = Column(FK, nullable=True)
    resolved_action = Column(Enum(
        "teacher_changed",
        "schedule_changed",
        "discount_offered",
        "parent_contacted",
        "lessons_paused",
        "false_alarm",
        "student_left",         # 결국 이탈
    ), nullable=True)
    note = Column(Text, nullable=True)


class AcademyStudentRiskScore(Base):
    """현재 위험 점수 (1 학생 = 1 행, daily 재계산)."""
    academy_id = Column(FK, PK1)
    academy_student_id = Column(FK, PK2)
    score = Column(Integer)                 # 0-100
    band = Column(Enum("safe", "watch", "at_risk", "critical"))
    last_calculated_at = Column(DateTime)
    signal_summary = Column(JSON)           # {signal_type: count, ...}
    owner_acknowledged_at = Column(DateTime, nullable=True)  # 학원장 확인 시각
```

## 3. 위험 점수 산출

### 3.1 신호별 가중치

| 신호 | 트리거 | severity | 점수 기여 |
|---|---|---|---|
| attendance_drop | 최근 4주 출석률 < 70% (학원 평균 대비 -20%p) | 8 | +25 |
| attendance_drop (강) | 최근 4주 출석률 < 50% | 10 | +40 |
| progress_stagnation | 같은 곡/단계 6주 이상 정체 (lesson_note 분석) | 5 | +15 |
| complaint_repeated | 학부모 inquiry "강사/수업 불만족" 2회+ 3개월 내 | 7 | +20 |
| teacher_flag | 강사가 명시적으로 "이 학생 위험" 토글 | 9 | +30 |
| payment_late | 미수금 14일+ (한 달) | 6 | +15 |
| payment_late (반복) | 미수금 패턴 2개월 연속 | 8 | +25 |
| lesson_cancel_repeat | 학생 사유 취소 3회+ 1개월 | 6 | +20 |

**점수 합산:** 활성 신호 (resolved_at IS NULL) 의 기여 합 → cap 100.

**감쇠:** 신호별 raised_at 후 28일 경과 시 기여 50% 감쇠 (학원장 액션 없이도 자연 해소 가정). 56일 후 0.

### 3.2 밴드 분류

| 점수 | 밴드 | 학원장 표시 |
|---|---|---|
| 0-19 | safe | 표시 안 함 |
| 20-39 | watch | `/students` 리스트에 ⚠ 아이콘 |
| 40-69 | at_risk | 대시보드 Action Box "위험 학생 N명" + 알림 |
| 70-100 | critical | 학원장 푸시 + 카톡 알림 (24h 응답 필수) |

### 3.3 재계산 주기

- 매일 01:00 KST 배치 (전체 학생 점수 갱신)
- 강사 플래그 / 학부모 컴플레인 등 즉시 트리거 신호는 실시간 재계산
- API: `POST /api/v1/academies/{id}/students/{id}/risk/recalculate` (수동 강제)

## 4. 강사 → 학원장 위험 플래그 채널

### 4.1 배경

NFR-A-5 권한 격리 원칙: 강사가 학원장에게 학생 노트 상세를 노출하면 위반. 그러나 "이 학생 이탈 위험" 같은 **메타 신호**는 권한 격리 예외로 허용 — 학원 운영 안전망 우선.

### 4.2 강사 lesson-app UX

학생 상세 화면 우상단 "위험 플래그" 토글 (강사 권한):

```
┌────────────────────────────────────────┐
│ 김지민 (피아노 · 5학년)     [⚠ 플래그]│
├────────────────────────────────────────┤
│ 다음 레슨: 5/8 16:00                   │
│ 이번 달 출석: 3/4회                    │
│                                        │
│ [노트]  [녹음]  [진도]                 │
└────────────────────────────────────────┘
```

플래그 클릭 시 모달:

```
┌────────────────────────────────────────┐
│ 위험 신호 보내기                       │
├────────────────────────────────────────┤
│ 사유 (학원장에게 공유됨):              │
│ ○ 흥미 저하 / 의욕 없음                │
│ ○ 진도 정체 / 어려워함                 │
│ ○ 학부모와 갈등                        │
│ ○ 가정 사정 (이사·전학 가능)           │
│ ○ 기타: [             ]                │
│                                        │
│ 강사 메모 (학원장만 열람):             │
│ [                                ]     │
│                                        │
│ ⚠ 학생 노트/녹음은 공유되지 않습니다. │
│   사유 + 메모만 학원장에게 전달됩니다.│
│                                        │
│             [취소]  [플래그 보내기]   │
└────────────────────────────────────────┘
```

### 4.3 학원장 수신

`AcademyStudentRiskSignal` (signal_type=teacher_flag) 행 생성 + 학원장 알림. 사유 + 강사 메모만 표시. 학생 노트/녹음 차단 유지.

### 4.4 강사 보호 (실수 방지)

- 플래그 후 24h 이내 강사가 취소 가능 ("잘못 눌렀어요")
- 학원장 확인 전까지는 강사 메모 수정 가능
- 학원장 확인 후 강사 메모 잠금 (수정 불가) — audit 보존

## 5. 학원장 화면

### 5.1 `/students/at-risk` 위험 학생 리스트

```
┌──────────────────────────────────────────────────────┐
│ 위험 학생 (총 8명)               [정렬: 점수↓]      │
├──────────────────────────────────────────────────────┤
│ 🔴 김지민  78점  critical  강사 플래그+출석↓        │
│   이선생 / 피아노 / 5학년 / 2024-09 등록            │
│   [상세 보기]  [학원장 메모]  [강사와 상의]         │
├──────────────────────────────────────────────────────┤
│ 🟠 박지수  52점  at_risk   진도 정체+컴플레인       │
│   김선생 / 바이올린 / 4학년 / 2025-03 등록          │
│   [상세 보기]  ...                                   │
└──────────────────────────────────────────────────────┘
```

행 클릭 → 학생 상세 페이지 (NFR-A-5 하에 노출 가능한 정보만: 신호 종류, 점수 추이, 학원장 액션 이력).

### 5.2 학생 위험 상세

```
┌──────────────────────────────────────────────────────┐
│ 김지민 - 위험 점수 78 (critical)                    │
├──────────────────────────────────────────────────────┤
│ 점수 추이 (12주):                                   │
│ 20 ─────── 35 ─── 52 ─── 78 ←                       │
│                                                      │
│ 활성 신호:                                          │
│ • 강사 플래그 (이선생, 5/2): 흥미 저하 + 메모       │
│ • 출석 저조: 최근 4주 50% (학원 평균 93%)            │
│ • 학부모 컴플레인 2회 (4/15, 5/1)                   │
│                                                      │
│ 학원장 액션 이력:                                   │
│ • 5/3 학원장 메모 추가                              │
│ • (이전 액션 없음)                                  │
│                                                      │
│ [학원장 메모 추가]  [강사와 상의 요청]              │
│ [할인 제안 (수기)]  [수업 일시 중단 (수기)]         │
│ [학부모 직접 연락 (외부)]  [false_alarm 해결]      │
└──────────────────────────────────────────────────────┘
```

**원칙:** 모든 액션은 **수기 마킹** — 앱이 학부모에게 자동 발송하거나 강사를 자동 변경하지 않는다. 학원장이 외부 (전화/카톡) 에서 액션 후 앱에 결과 마킹.

### 5.3 액션 결과 마킹

각 액션 종료 시 학원장이 `resolved_action` 마킹:
- teacher_changed: 강사 변경했음
- schedule_changed: 수업 일정 변경했음
- discount_offered: 할인 제안했음
- parent_contacted: 학부모와 직접 통화/만남
- lessons_paused: 수업 일시 중단
- false_alarm: 잘못된 신호였음
- student_left: 결국 이탈

`AcademyStudentRiskSignal.resolved_at` + `resolved_by_user_id` 기록. 다음 위험 점수 재계산 시 감쇠.

## 6. 알림

| 시점 | 채널 | 대상 |
|---|---|---|
| 학생 점수 → critical 진입 | 콘솔 푸시 + 카톡 알림톡 | 학원장 |
| 학생 점수 → at_risk 진입 | 콘솔 알림 | 학원장 |
| 강사 플래그 즉시 | 콘솔 알림 + 카톡 | 학원장 |
| critical 24h 응답 없음 | 카톡 재알림 (escalation) | 학원장 |
| 위험 신호 해소 (학원장 액션 후 점수 < 20) | 콘솔 알림 (긍정) | 학원장 |

알림톡 템플릿 (사전 등록):
- `LNZ_STUDENT_RISK_CRITICAL`: "[Lessonaza] {academy} {student} 학생의 이탈 위험이 높습니다. 콘솔에서 확인 → {url}"
- `LNZ_TEACHER_RISK_FLAG`: "[Lessonaza] {teacher} 강사가 {student} 학생에 위험 플래그를 보냈습니다."

## 7. 이탈 후 Retrospective

학생이 `status=alumni` 로 변경되면 자동으로 retrospective 카드 생성:

```
┌──────────────────────────────────────────────────────┐
│ 이탈 회고 - 김지민 (2024-09 등록 ~ 2026-05 이탈)    │
├──────────────────────────────────────────────────────┤
│ 재학: 8개월 / LTV: ₩2,400,000                       │
│ 마지막 위험 점수: 89                                │
│                                                      │
│ 시그널 타임라인:                                    │
│ 2026-03  강사 플래그 (흥미 저하)                    │
│ 2026-04  출석 저조 시작                             │
│ 2026-05  컴플레인 1회 → 이탈 통보                   │
│                                                      │
│ 학원장 액션 이력:                                   │
│ 2026-03  학원장 메모만 추가, 외부 액션 없음         │
│                                                      │
│ ⓘ 강사 플래그 후 학원장 액션이 부족했습니다.       │
│   다음 강사 플래그는 24h 이내 응답 권장.            │
└──────────────────────────────────────────────────────┘
```

학원장이 "회고 닫기" 또는 "패턴 인사이트 보기" → §8 코호트 분석.

## 8. 코호트 분석 (AC-M7)

`/students/retention-cohort`:

- 등록월 코호트별 12개월 재학률 (chart)
- 위험 신호 유형별 이탈 전환률
- 강사별 이탈률 (teacher_management_spec.md teacher 상세에도 노출)
- 악기/연령별 이탈 패턴

학원장이 의사결정에 사용:
- "3월 등록 학생 이탈률이 높음 — 그 시점 강사 매칭 정책 점검"
- "피아노보다 바이올린 학생 6개월 이탈률 2배 — 입문 커리큘럼 점검"

PII 없이 집계만. 코호트 클릭 시 학생 리스트는 이름만 (노트/녹음 X).

## 9. 권한 / 보안

- `Depends(current_academy_owner)` 전체
- 강사 플래그 채널은 강사 권한 (`Depends(current_teacher)`) + 본인 담당 학생만
- 위험 점수 / 신호 / retrospective 모두 `AuditLog` 기록
- 강사 메모는 학원장 + 강사 본인만 열람 (다른 강사 차단)

## 10. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 신호 데이터 부족 (신규 등록 4주 미만) | 점수 계산 안 함 (band=safe 표시) |
| 강사가 같은 학생에 플래그 연속 2회 | 두 번째는 첫 번째 업데이트로 처리 (별도 행 X) |
| 학원장이 위험 학생 무시 (60일 acknowledged_at 없음) | 학원장에게 escalation 알림 + retrospective 잠금 (학원 운영 안전망) |
| critical 학생이 자연 회복 (학원장 액션 없이 점수 < 20) | false_alarm 으로 자동 마킹 + 알림 |

## 11. 비기능 (NFR)

- 위험 점수 계산은 학생당 < 100ms (배치 처리 1000명 학원 < 2분)
- 강사 플래그 → 학원장 알림 < 30초
- 코호트 분석은 캐시 TTL 1h

## 12. 변경 이력

- 2026-06-04: 초안 (갭분석 H#2 응답: 학생 이탈 조기 신호 부재 해소. 신호 6종 + 점수 산출 + 강사→학원장 플래그 채널 + 학원장 수기 액션 매트릭스 + retrospective + 코호트 분석)
