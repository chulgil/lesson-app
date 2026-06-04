# academy/recital_workflow_spec — 발표회 운영 워크플로우

> 기준일: 2026-06-04
> 경로: `/events/recitals`, `/events/recitals/{id}/program`, `/events/recitals/{id}/run`
> 마일스톤: AC-M7 (Insight — 발표회 시즌 운영)
> 선행: [student_management_spec.md](student_management_spec.md), [billing_settlement_spec.md](billing_settlement_spec.md), [announcements_spec.md](announcements_spec.md), [inbox_spec.md](inbox_spec.md)
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` M#10
> 시장조사 input: `.harness/research/academy_market_2026.md` (12월/6월 발표회 시즌 학원장 부담 최대 — 한국 음악학원 연중 핵심 이벤트)

## 1. 배경 / 범위

소규모 음악학원의 발표회는 연 1-2회 (보통 12월 / 6월) 학원 운영의 핵심 이벤트:
- 학원 정체성 / 학부모 만족도 / 학생 동기부여의 정점
- 학원장 운영 부담 매우 큼 (출연자 선정, 곡 배정, 의상, 공간 대관, 영상 촬영, 학부모 안내)
- 시즌 2-3개월 전부터 준비 시작 → 당일 → 사후 영상 배포까지 12-16주 워크플로우

현재 스펙은 발표회 관련 0건. 본 스펙은 학원장이 발표회를 단계별로 진행하는 통합 흐름 정의.

**범위:**
- 발표회 생성 + 기본 정보 (날짜·장소·예산)
- 출연자 결정 + 곡 배정 + 출연 순서
- 학부모 안내 (참가 동의서, 비용, 의상)
- 당일 운영 (체크인, 진행, 사진/영상)
- 사후 (영상 편집·배포, 후기 수집, 다음 발표회 인사이트)

**경계:**
- 영상 편집 자체는 학원장이 외부 도구 사용 — 앱은 업로드/배포만
- 공간 대관 결제는 앱 외부 (수기 기록만)
- 학원장이 발표회 전체를 비활성화/스킵 가능 (의무 X)

## 2. 발표회 단계 (4단계 워크플로우)

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ ① 기획  │→ │ ② 준비  │→ │ ③ 진행  │→ │ ④ 사후  │
│ 12주 전  │  │ 4주 전   │  │ 당일     │  │ 2주 내   │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

| 단계 | 핵심 결정 | 산출물 |
|---|---|---|
| ① 기획 | 날짜·장소·예산·테마·출연 대상 정책 | RecitalPlan |
| ② 준비 | 학생 참가 확정·곡 배정·출연 순서·학부모 안내 | RecitalProgram |
| ③ 진행 | 체크인·진행·문제 대응 | RecitalRunLog |
| ④ 사후 | 영상 배포·비용 정산·학부모 후기·인사이트 | RecitalRetrospective |

## 3. 데이터 모델

```python
class AcademyRecital(Base):
    """발표회 1건 (1 학원 × N 발표회)."""
    id = Column(PK)
    academy_id = Column(FK)
    title = Column(String)                              # "2026 겨울 발표회"
    season = Column(Enum("spring", "summer", "fall", "winter"))
    scheduled_at = Column(DateTime)                     # 발표회 시작 시각
    duration_minutes = Column(Integer, default=120)
    venue_type = Column(Enum("academy", "external_hall", "school", "online"))
    venue_name = Column(String, nullable=True)
    venue_address = Column(String, nullable=True)
    venue_capacity = Column(Integer, nullable=True)
    venue_rental_cost = Column(Integer, default=0)      # 학원장 수기 입력
    theme = Column(String, nullable=True)               # "동화 음악 여행"
    eligibility_policy = Column(Enum(
        "all_active",        # 활성 학생 전원 (선택권)
        "min_months",        # 등록 N개월 이상
        "owner_curated",     # 학원장 개별 선정
        "teacher_recommended", # 강사 추천
    ))
    eligibility_config = Column(JSON)                   # min_months: 3 등
    state = Column(Enum("draft", "planning", "preparing", "live", "wrapping", "completed", "cancelled"))
    created_at = Column(DateTime)
    cancelled_at = Column(DateTime, nullable=True)
    cancelled_reason = Column(String, nullable=True)


class AcademyRecitalParticipation(Base):
    """학생별 참가 여부 (1 발표회 × N 학생)."""
    id = Column(PK)
    recital_id = Column(FK)
    academy_student_id = Column(FK)
    invited_at = Column(DateTime, nullable=True)
    parent_consent_at = Column(DateTime, nullable=True)   # 학부모 동의 시각
    state = Column(Enum(
        "invited",       # 학원장이 초대
        "accepted",      # 학부모 동의
        "declined",      # 학부모 불참 의사
        "tentative",     # 검토 중
        "withdrawn",     # 동의 후 철회
    ))
    decline_reason = Column(String, nullable=True)
    fee_amount = Column(Integer, default=0)               # 출연료 (학원 정책)
    fee_paid_at = Column(DateTime, nullable=True)
    costume_size = Column(String, nullable=True)          # 의상 사이즈 (학원 일괄 시)
    notes = Column(Text, nullable=True)


class AcademyRecitalProgram(Base):
    """프로그램 (출연 순서 1행 = 학생 1명 × 곡)."""
    id = Column(PK)
    recital_id = Column(FK)
    participation_id = Column(FK)
    program_order = Column(Integer)                       # 출연 순서 (1부터)
    piece_title = Column(String)                          # "쇼팽 - 녹턴 Op.9 No.2"
    piece_composer = Column(String, nullable=True)
    piece_duration_seconds = Column(Integer)              # 예상 연주 시간
    accompaniment = Column(Enum("solo", "duo", "ensemble", "with_teacher", "with_track"), default="solo")
    accompanist_member_id = Column(FK academy_members, nullable=True)
    notes_for_student = Column(Text, nullable=True)       # 강사 메모
    backstage_arrival_time = Column(Time, nullable=True)  # 무대 뒤 도착 시각


class AcademyRecitalRunLog(Base):
    """당일 운영 로그 (이벤트 단위)."""
    id = Column(PK)
    recital_id = Column(FK)
    occurred_at = Column(DateTime)
    event_type = Column(Enum(
        "check_in",          # 학생 체크인
        "stage_start",       # 무대 시작
        "stage_end",
        "program_skip",      # 학생 불참
        "incident",          # 사건 (학생 부상/장비 문제 등)
        "intermission_start",
        "intermission_end",
    ))
    program_id = Column(FK, nullable=True)
    note = Column(Text, nullable=True)
    recorded_by_user_id = Column(FK users)


class AcademyRecitalRecording(Base):
    """녹화 영상 (학생당 1개 또는 전체 1개)."""
    id = Column(PK)
    recital_id = Column(FK)
    scope = Column(Enum("full", "per_student"))
    program_id = Column(FK, nullable=True)                 # scope=per_student 일 때
    upload_status = Column(Enum("pending", "uploading", "available", "failed"))
    storage_url = Column(String, nullable=True)            # S3 signed URL
    file_size_bytes = Column(BigInteger, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    uploaded_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)           # 학부모 다운로드 만료
    download_count = Column(Integer, default=0)
```

## 4. ① 기획 단계 (12주 전)

### 4.1 발표회 생성 (`/events/recitals/new`)

```
┌──────────────────────────────────────────────┐
│ 발표회 만들기                                │
├──────────────────────────────────────────────┤
│ 제목:        [2026 겨울 발표회             ]│
│ 시즌:        [▼ 겨울]                       │
│ 날짜·시각:   [2026-12-21 14:00]            │
│ 예상 길이:   [120] 분                        │
│                                              │
│ 장소:                                        │
│   ○ 학원                                    │
│   ● 외부 홀  이름: [강남아트홀         ]   │
│              주소: [서울 강남구 ...     ]   │
│              수용: [80] 석                  │
│              대관비: [800,000] 원           │
│   ○ 학교 강당  ○ 온라인 (Zoom)            │
│                                              │
│ 테마: [동화 음악 여행                  ]    │
│                                              │
│ 출연 대상 정책:                              │
│   ○ 활성 학생 전원 (선택권 부여)            │
│   ● 등록 [3]개월 이상 학생                 │
│   ○ 학원장 개별 선정                        │
│   ○ 강사 추천                               │
│                                              │
│         [기획 저장 (planning 상태)]         │
└──────────────────────────────────────────────┘
```

### 4.2 출연 대상 자동 산출

`eligibility_policy` 적용:
- `all_active`: 모든 `AcademyStudent.status='active'`
- `min_months`: 등록 후 N 개월 이상 학생
- `owner_curated`: 학원장이 화면에서 체크
- `teacher_recommended`: 강사가 본인 학생 중 추천 → 학원장 승인

대상 리스트 미리보기 + "초대장 발송" → §5 준비 단계 진입.

## 5. ② 준비 단계 (4-12주 전)

### 5.1 학부모 초대장 발송

```
POST /api/v1/academies/{id}/recitals/{id}/invite
{ student_ids: [...] }

→ 각 학부모에게 카톡 알림톡 (LNZ_RECITAL_INVITE):
  "[Lessonaza] 2026 겨울 발표회 초대장
  일시: 2026-12-21 14:00
  장소: 강남아트홀
  출연료: ₩30,000
  [참가 동의서 작성]"

→ AcademyRecitalParticipation 행 state='invited'
```

### 5.2 학부모 동의 흐름 (lesson-app)

```
┌──────────────────────────────────────────────┐
│ 2026 겨울 발표회 초대                       │
├──────────────────────────────────────────────┤
│ 일시: 2026-12-21 14:00                      │
│ 장소: 강남아트홀                            │
│ 예상 길이: 2시간                            │
│ 출연료: ₩30,000 (별도 청구)                │
│                                              │
│ 의상: 학원에서 일괄 대여 (개별 사이즈 입력)│
│ 가족 좌석: 학생 1명당 4석                  │
│                                              │
│ ○ 참가합니다                                │
│ ○ 참가하지 않습니다 (사유: [         ])    │
│ ○ 검토 중 (12/1까지 답변)                  │
│                                              │
│ 의상 사이즈: [▼ M (140cm)]                 │
│                                              │
│             [제출]                          │
└──────────────────────────────────────────────┘
```

제출 → `parent_consent_at` 기록. state 변경 (`accepted` / `declined` / `tentative`).

### 5.3 곡 배정 (학원장 + 강사 협업)

학원장 화면 `/events/recitals/{id}/program`:

```
┌────────────────────────────────────────────────┐
│ 곡 배정 (참가 확정 28명)        총 합계: 95분  │
├────────────────────────────────────────────────┤
│ 김지민 (피아노 5학년 / 이선생)              │
│   곡: [쇼팽 녹턴 Op.9 No.2          ]  4:30 │
│   반주: [▼ 솔로]                            │
│   강사 메모: [기교 가다듬기            ]    │
│                                              │
│ 박지수 (바이올린 4학년 / 김선생)            │
│   곡: [모차르트 바이올린 소나타 ...]   6:00 │
│   반주: [▼ 학원장 김원장]                   │
│   ...                                        │
└────────────────────────────────────────────────┘
```

강사가 본인 담당 학생의 곡 제안 → 학원장 승인. 곡 충돌 (같은 곡 2명+) 자동 알림.

### 5.4 출연 순서 결정

학원장이 드래그 또는 자동 정렬 옵션:
- 학년 오름차순 (저학년 먼저, 무대 적응)
- 곡 시간 → 짧은 곡 → 긴 곡 (관객 집중)
- 악기 묶음 (피아노 → 바이올린 → 합주)
- 강사 묶음 (같은 강사 학생끼리)

`program_order` 자동 갱신. `backstage_arrival_time` 자동 계산 (출연 30분 전 도착 권장).

### 5.5 의상 일괄 발주 (학원장 수기)

학원장이 의상 사이즈별 집계 → 외부 의상 업체 발주 (앱 외부). 화면에 사이즈별 집계 표:

| 사이즈 | 인원 | 학생 명단 |
|---|---|---|
| S (130cm) | 4 | ... |
| M (140cm) | 12 | ... |
| L (150cm) | 8 | ... |
| XL (160cm) | 4 | ... |

### 5.6 출연료 청구 (billing 연동)

학원장이 "출연료 일괄 청구" 클릭 → 참가 확정 학생 28명에게 별도 invoice 생성 ([billing_settlement_spec.md](billing_settlement_spec.md) `extra_amount` 항목으로 추가). 수금 후 §6 진행.

### 5.7 학부모 추가 안내 발송 (1주 전)

`/events/recitals/{id}/reminder`:

```
[Lessonaza] 2026 겨울 발표회 안내

내일 (12/20)
- 의상 사이즈 체크하셨나요?
- 가족 좌석 4매 발급 (예약 필요)
- 도착 시간: 13:30 (체크인)

[좌석 예약]  [질문]
```

## 6. ③ 진행 단계 (당일)

### 6.1 체크인 (`/events/recitals/{id}/run`)

학원장 또는 강사가 학생 체크인. 모바일 우선:

```
┌────────────────────────────────────────────┐
│ 체크인 (28명 중 24명 도착)                │
├────────────────────────────────────────────┤
│ ✓ 김지민  13:25 도착                       │
│ ✓ 박지수  13:30 도착                       │
│ ✗ 이지호  미도착 (출연 4번째, 14:18)       │
│ ✓ 한지원  13:32 도착                       │
│ ...                                        │
│                                            │
│ [학부모에게 도착 안내 보내기 (미도착자)] │
└────────────────────────────────────────────┘
```

체크인 = `AcademyRecitalRunLog` event_type='check_in' 행. 미도착자에게 자동 카톡 1회.

### 6.2 진행 중 이벤트

각 무대 시작/종료 시각 기록 (자동). 일정 vs 실제 비교 표시. 지연 누적 시 학원장 알림 (예: "10분 지연 누적").

문제 발생 시 (학생 부상, 마이크 고장) `incident` 이벤트 + 메모.

### 6.3 학원장 진행 모드 (휴대폰)

학원장이 무대 옆에서 휴대폰 가로 모드:

```
┌─────────────────────────────────────────────────────┐
│ 진행 중                                              │
├─────────────────────────────────────────────────────┤
│ 현재: 5/28  김지민  쇼팽 녹턴 Op.9 No.2 (4:30)     │
│                                                     │
│ ▶ [무대 종료]  [다음]  [건너뛰기]  [지연]        │
│                                                     │
│ 다음: 6/28  박지수  모차르트 (6:00) 13:45 시작 예정 │
│                                                     │
│ 무대 뒤: 김지민(현), 박지수(대기), 이지호(미도착) │
└─────────────────────────────────────────────────────┘
```

큰 버튼 + 한 손 조작. 무대 뒤 학생 상태 한눈에.

## 7. ④ 사후 단계 (2주 내)

### 7.1 영상 업로드 (학원장)

`/events/recitals/{id}/recordings/upload`:

- 전체 영상 1개 업로드 (full)
- 또는 학생별 segment 업로드 (per_student) — 시간이 더 걸리지만 학부모 가치 높음
- 외부 편집 도구 (Premiere, DaVinci) 사용 → 결과 파일 업로드만

업로드 후 `upload_status='available'`. signed URL 생성 (TTL 30일).

### 7.2 학부모 영상 배포

각 학부모에게 카톡 알림 (LNZ_RECITAL_RECORDING_READY):
- "발표회 영상 준비 완료. 30일 내 다운로드"
- lesson-app deep link → 본인 자녀 영상 또는 전체 영상

다운로드 시 `download_count` 증가. PII 보호: 다른 학생의 영상은 일반 학부모 접근 차단 (per_student 영상은 본인 자녀만).

### 7.3 비용 정산

학원장이 발표회 결산:
- 출연료 수입 (학생 28명 × ₩30,000 = ₩840,000)
- 대관비 지출 (₩800,000)
- 의상 대여 지출 (₩200,000)
- 영상 편집 외주 (₩300,000)
- 합계: -₩460,000 (적자)

학원장이 다음 발표회 가격 정책 의사결정 input.

### 7.4 학부모 후기 수집

발표회 종료 7일 후 학부모에게 카톡 (LNZ_RECITAL_FEEDBACK):
- "발표회 어떠셨나요? 한 마디 부탁드립니다"
- 5점 평가 + 자유 메모

수집된 후기는 학원장만 열람 (학생 PII 차단).

### 7.5 인사이트 (다음 발표회 계획)

`/events/recitals/{id}/retrospective`:

- 참가 학생 / 미참가 학생 비교 (LTV·재학 기간 차이 → "발표회 참가자가 6개월 후 재학률 15%p 높음" 같은 인사이트)
- 강사별 참가율
- 곡 시간 합계 → 예상 vs 실제 진행 시간
- 학부모 평균 평점
- 후기 키워드 분석 (긍정/부정)
- 비용 / 매출
- 다음 발표회 권장 (시즌 가산, 의상 정책 변경 등)

## 8. 알림 / 카톡 템플릿

사전 등록:

| 템플릿 | 시점 | 본문 요약 |
|---|---|---|
| `LNZ_RECITAL_INVITE` | §5.1 초대 | 일시·장소·출연료·참가 동의서 링크 |
| `LNZ_RECITAL_REMINDER_1WK` | 1주 전 | 의상·좌석·도착 시간 |
| `LNZ_RECITAL_REMINDER_1DAY` | 전날 | 도착 시간·주차 안내 |
| `LNZ_RECITAL_NOSHOW_ALERT` | §6.1 미도착 | "{student} 학생 미도착 — 도착 예정 알려주세요" |
| `LNZ_RECITAL_RECORDING_READY` | §7.2 영상 배포 | 다운로드 링크·만료일 |
| `LNZ_RECITAL_FEEDBACK_REQUEST` | §7.4 7일 후 | 후기 요청 |

## 9. 권한 / 보안

- 발표회 CRUD: `Depends(current_academy_owner)`
- 곡 배정: 학원장 또는 본인 담당 학생만 강사 가능
- 체크인: 학원장 + 강사 + 학원장 위임 매니저
- 영상 업로드: 학원장 + 위임 매니저
- 영상 다운로드: 학부모 본인 (자녀 + 전체 영상) + 강사 (본인 학생만)
- 학부모 후기: 학원장 + 운영자 어드민 (분쟁 시)

## 10. 비기능

- 진행 모드 (모바일 가로) 반응 < 200ms (학원장 진행 중 조작)
- 영상 업로드: 최대 5GB 단일 파일, multipart upload, 백그라운드 처리
- signed URL TTL 30일, 5회 갱신 가능 (학부모 외부 백업 권장 안내)

## 11. 실패 / 예외

| 상황 | 처리 |
|---|---|
| 발표회 당일 취소 (천재지변) | `state='cancelled'` + 학부모 일괄 알림 + 출연료 환불 안내 |
| 학생 당일 부상 | `program_skip` 이벤트 + 다음 학생 자동 진행 |
| 영상 업로드 실패 (5GB 초과) | 분할 권장 + 학원장 알림 |
| 학부모 동의 미응답 (D-7) | 학원장에게 미응답 명단 알림 + 카톡 재발송 |
| 학원장 진행 중 인터넷 끊김 | 모바일 offline 모드 — 로컬 저장 후 복귀 시 sync |

## 12. 변경 이력

- 2026-06-04: 초안 (갭분석 M#10 + 시장조사 시즌 핵심 이벤트 응답. 4단계 워크플로우 + 학부모 동의 + 곡 배정 + 진행 모드 (모바일 가로) + 영상 배포 + 재무 결산 + 인사이트. 영상 편집은 외부 도구 의존)
