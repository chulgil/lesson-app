# academy/studio_utilization_spec — 학원 공간(방·시간) 활용도 분석

> 기준일: 2026-06-04
> 경로: `/studios`, `/studios/utilization`, `/studios/heatmap`
> 마일스톤: AC-M5 (공간 등록 MVP) / AC-M7 (Insight — 활용도 분석)
> 선행: [academy_schedule_authority_spec.md](academy_schedule_authority_spec.md), [dashboard_spec.md](dashboard_spec.md), [teacher_management_spec.md](teacher_management_spec.md), [recital_workflow_spec.md](recital_workflow_spec.md)
> 갭분석 input: 후속 후보 #2 (학원 자산 활용도 추적 부재 → 신규 모객 우선순위 / 공간 증설·축소 의사결정 불가)

## 1. 배경 / 범위

소규모 음악학원은 보통 방 2-5개 (피아노실, 합주실, 드럼실 등). 학원장은 다음 질문에 답할 도구 없음:

- "어느 방이 가장 비어 있나? → 신규 학생 어디로 받을까?"
- "어느 시간대가 한가한가? → 모객 광고 시간대 정조준"
- "어느 강사 페이 효율이 낮나? → 정책 변경 vs 강사 협의"
- "방 증설 가치 있나? → 신규 임대 의사결정 근거"
- "발표회 / 합주 등 비정규 사용 vs 정규 레슨 비중?"

본 스펙은 학원 공간 단위 운영 데이터를 학원장 의사결정 KPI 로 노출.

**원칙:**
- 학생 PII 노출 X (활용도 = 시간 × 방 점유 비율, 학생 개별 정보 X)
- 학원장이 공간을 직접 등록 (자동 감지 X)
- 시간대 분석은 학원 영업시간 기준 ([inbox_spec.md §11.2](inbox_spec.md))

## 2. 데이터 모델

```python
class AcademyStudio(Base):
    """학원 공간(방) 1개 = 1 행."""
    id = Column(PK)
    academy_id = Column(FK)
    name = Column(String)                                # "1번 방 (피아노)"
    short_label = Column(String, nullable=True)         # "P1" (UI 짧게 표시)
    type = Column(Enum(
        "piano",         # 피아노실
        "string",        # 현악기 (바이올린·첼로)
        "wind",          # 관악
        "drum",          # 드럼/타악
        "vocal",         # 보컬
        "ensemble",      # 합주
        "lounge",        # 대기실 (점유 미카운트)
        "other",
    ))
    capacity = Column(Integer, default=1)                # 동시 수용 (개인 레슨 = 1, 합주 = N)
    equipment = Column(JSON, default=list)               # ["upright_piano", "metronome", "mirror"]
    operating_hours = Column(JSON, nullable=True)        # null = 학원 기본값. 방별 override 가능
    area_sqm = Column(Float, nullable=True)             # 면적 (방 비교 시)
    monthly_rent_share = Column(Integer, default=0)      # 방별 임대료 배분 (수기 — ROI 계산)
    state = Column(Enum("active", "archived", "renovation"))
    created_at = Column(DateTime)


class AcademyStudioUsage(Base):
    """방별 시간 점유 1건. LessonBooking 또는 비정규 사용."""
    id = Column(PK)
    academy_id = Column(FK)
    studio_id = Column(FK)
    starts_at = Column(DateTime)
    ends_at = Column(DateTime)
    usage_type = Column(Enum(
        "lesson",          # 정규 레슨 (LessonBooking)
        "trial",           # 체험 레슨
        "makeup",          # 보강
        "rehearsal",       # 합주 연습
        "recital_prep",    # 발표회 리허설
        "self_practice",   # 학생 자율 연습 (학원 정책)
        "maintenance",     # 점검·청소
        "blocked",         # 학원장이 차단 (휴원 등)
    ))
    source_lesson_id = Column(FK lesson_bookings, nullable=True)
    source_recital_id = Column(FK recitals, nullable=True)
    booked_by_user_id = Column(FK users, nullable=True)
    teacher_member_id = Column(FK academy_members, nullable=True)
    student_count = Column(Integer, default=1)
    revenue = Column(Integer, default=0)                # 이 슬롯에서 발생한 매출 (정규 레슨만)

    __table_args__ = (
        Index("idx_studio_usage_time", "academy_id", "studio_id", "starts_at"),
    )
```

> `AcademyStudioUsage` 행은 `LessonBooking` 생성 시 자동 sync (트리거 또는 application). 합주·리허설·점검은 학원장이 별도 등록.

## 3. 공간 등록 (학원장)

`/studios/new`:

```
┌──────────────────────────────────────────────┐
│ 공간 등록                                    │
├──────────────────────────────────────────────┤
│ 이름:      [1번 방 (피아노)            ]    │
│ 짧은 라벨: [P1] (스케줄 표시용)             │
│                                              │
│ 종류:      [▼ 피아노실]                     │
│ 동시 수용: [1] 명 (개인 레슨)               │
│                                              │
│ 장비 (체크):                                 │
│ [✓] 업라이트 피아노   [ ] 그랜드 피아노     │
│ [✓] 메트로놈          [✓] 거울             │
│ [ ] 녹음 장비         [ ] 보면대 2개        │
│                                              │
│ 운영 시간:                                   │
│ ● 학원 기본값 사용                          │
│ ○ 방별 override (예: 평일만 / 야간 차단)    │
│                                              │
│ 면적 (선택): [9] m²                          │
│ 월 임대료 배분 (수기): [200,000] 원         │
│                                              │
│         [등록]                              │
└──────────────────────────────────────────────┘
```

## 4. 활용도 분석

### 4.1 시간대 heatmap (`/studios/heatmap`)

```
┌─────────────────────────────────────────────────────┐
│ 활용도 heatmap (2026-05 기준)                       │
├─────────────────────────────────────────────────────┤
│        월  화  수  목  금  토  일                  │
│ 10:00  ▓▓  ▓▓  ▓░  ▓▓  ▓▓  ░░  ──                  │
│ 11:00  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ░░  ──                  │
│ 12:00  ▓░  ▓░  ▓░  ▓░  ▓░  ░░  ──                  │
│ 13:00  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ░░  ──                  │
│ 14:00  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ░░  ──                  │
│ 15:00  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ──                  │
│ 16:00  ██  ██  ██  ██  ██  ▓▓  ──                  │
│ 17:00  ██  ██  ██  ██  ██  ▓▓  ──                  │
│ 18:00  ██  ██  ██  ██  ██  ▓░  ──                  │
│ 19:00  ▓▓  ▓▓  ▓▓  ▓▓  ▓▓  ░░  ──                  │
│ 20:00  ▓░  ▓░  ▓░  ▓░  ▓░  ░░  ──                  │
│                                                     │
│ ░ 0-25%  ▓░ 25-50%  ▓▓ 50-75%  ██ 75-100%          │
│ ─ 영업시간 외                                       │
│                                                     │
│ 전체 평균 활용률: 64% (지난 달 58%, +6%p)          │
│                                                     │
│ [방 선택 ▼ 전체]  [기간 ▼ 이번 달]                │
└─────────────────────────────────────────────────────┘
```

**활용률 계산:** 슬롯 점유 시간 / (영업시간 × 방 수). 점심시간/대기실/maintenance 제외.

**인사이트 자동 생성:**
- "토요일 오전 (10-12) 활용률 10% — 모객 광고 우선순위"
- "평일 16-18시 100% — 신규 학생 받기 어려움 → 방 증설 검토"
- "수요일 오후 P3 방만 비어있음 — 강사 추가 채용 검토"

### 4.2 방별 활용률 + ROI

```
┌────────────────────────────────────────────────────┐
│ 방별 활용률 + ROI (이번 달)                       │
├────────────────────────────────────────────────────┤
│ 1번방 (피아노) P1                                 │
│   활용률 88% (192h / 220h)                        │
│   매출 ₩4,500,000  임대료 분배 ₩200,000           │
│   ROI 22.5배                                       │
│                                                    │
│ 2번방 (피아노) P2                                 │
│   활용률 75% (165h / 220h)                        │
│   매출 ₩3,800,000  임대료 ₩200,000                │
│   ROI 19배                                         │
│                                                    │
│ 3번방 (합주실)                                    │
│   활용률 35% (77h / 220h)  ⚠ 낮음                 │
│   매출 ₩1,200,000  임대료 ₩300,000                │
│   ROI 4배                                          │
│   [용도 변경 제안 →]                              │
└────────────────────────────────────────────────────┘
```

3번방 ROI 낮음 → 학원장 의사결정: 합주실을 개인 레슨실로 변경? 또는 합주 학생 모객 강화?

### 4.3 강사별 공간 점유 효율

```
┌────────────────────────────────────────────────────┐
│ 강사별 공간 점유 + 수익률                         │
├────────────────────────────────────────────────────┤
│ 김선생   주 25시간 사용  매출 ₩2,200,000          │
│   → 시간당 매출 ₩88,000  (학원 평균 ₩75,000)      │
│   → ★★★★★ 우수                                    │
│                                                    │
│ 박선생   주 18시간 사용  매출 ₩1,400,000          │
│   → 시간당 매출 ₩77,800                            │
│                                                    │
│ 최선생   주 12시간 사용  매출 ₩720,000            │
│   → 시간당 매출 ₩60,000  ⚠ 학원 평균 미달         │
│   [강사 페이 정책 검토] [학생 매칭 변경]          │
└────────────────────────────────────────────────────┘
```

학원장 의사결정:
- 김선생에게 시간 더 배정 (수익률 높음)
- 최선생 매칭 학생 점검 또는 강사 교육 지원

## 5. 빈 슬롯 발견 + 모객 우선순위

`/studios/empty-slots`:

```
┌────────────────────────────────────────────────────┐
│ 빈 슬롯 우선순위 (모객 → 매출 증가 잠재)          │
├────────────────────────────────────────────────────┤
│ 1. 토요일 10:00-12:00 (2시간 × 전체 방 4)         │
│    예상 매출/주: ₩400,000 → 월 ₩1,600,000        │
│    [광고 ▶ 이 시간대 강조]                        │
│                                                    │
│ 2. 평일 12:00-13:00 (1시간 × 활용도 30%)         │
│    예상 매출/주: ₩200,000                          │
│    제안: "직장인 점심 레슨" 광고 카피             │
│                                                    │
│ 3. 일요일 (휴무) — 영업 검토?                     │
│    잠재: ₩1,200,000/월 (가설)                     │
│    [영업일 추가 검토 →]                           │
└────────────────────────────────────────────────────┘
```

학원장이 1번 클릭 → [acquisition_tracking_spec.md](acquisition_tracking_spec.md) 추적 링크 자동 생성 ("토요일 오전 광고 — 5월" 라벨).

## 6. 비정규 사용 등록 (학원장)

학원장이 합주 연습 / 발표회 리허설 / 점검 시간을 직접 블록:

```
POST /api/v1/academies/{id}/studios/{id}/block
{
  starts_at, ends_at,
  usage_type: "rehearsal" | "maintenance" | "blocked",
  note: "5/20 발표회 리허설",
  student_count: 12  # (rehearsal 시 합주 학생 수)
}
```

블록된 시간은 활용도 계산에 포함 (점유로 카운트). `usage_type='maintenance'` 는 분모에서 제외 (점검 시간은 영업 외).

## 7. 대시보드 위젯 ([dashboard_spec.md §3.4](dashboard_spec.md) 추가)

학원장 대시보드 §3.4 경영 KPI 에 5번째 카드 추가 (사용자가 보강 시):

| 카드 | 값 | 계산 | 클릭 시 |
|---|---|---|---|
| **공간 활용률** | 64% (▲6%p) | 전체 방 평균 점유율 | `/studios/heatmap` |

## 8. 신규 학생 등록 시 자동 슬롯 제안

학원장이 신규 학생 등록 시 [student_management_spec.md](student_management_spec.md) `/students/new` 폼에 "추천 슬롯" 자동 표시:

- 학생 학년/연령 + 가족 가용 시간 입력
- 알고리즘이 비어있는 슬롯 중 상위 3건 제안
- 강사 매칭 점수와 결합

→ 학원장이 슬롯 충돌 없이 빠르게 등록.

## 9. 권한 / 보안

- 공간 등록/수정: `Depends(current_academy_owner)`
- 활용도 분석: 학원장 + 위임 매니저 (대시보드 열람 권한)
- 강사별 점유: 학원장 본인만 (강사 본인은 본인 시간만 조회)
- 학생 PII 노출 X — 슬롯 점유 = 시간 + 방 + 강사 (학생 이름 표시 X. 클릭 시 [academy_schedule_authority_spec.md §8](academy_schedule_authority_spec.md) 마스터 스케줄 이동)

## 10. 비기능

- heatmap 렌더링 < 1s (방 5 × 시간 14 × 요일 7 = 490 cell)
- 활용률 계산 캐시 TTL 1h
- 모객 우선순위 추천 = 학원당 < 200ms

## 11. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 방 등록 0개 (학원장이 미설정) | 활용도 화면 "방을 먼저 등록하세요" + 위저드 |
| 방 데이터 부족 (3주 미만) | "데이터가 더 필요합니다 (N주 후 분석 가능)" |
| 방 archive 후 잔존 활용 데이터 | 분석에서 제외, 과거 통계는 보존 (archive 마킹) |
| 강사 시간당 매출 계산 시 분모 0 (사용 시간 0) | "데이터 없음" 표시 |

## 12. 변경 이력

- 2026-06-04: 초안 (후속 후보 #2 응답: 공간 회전율 분석 부재 해소. 방 등록 + 활용도 heatmap + 방별 ROI + 강사별 효율 + 빈 슬롯 모객 우선순위 + 신규 학생 자동 슬롯 제안. 학원장 의사결정 도구 — 방 증설/축소, 강사 매칭 조정, 모객 광고 시간대 정조준)
