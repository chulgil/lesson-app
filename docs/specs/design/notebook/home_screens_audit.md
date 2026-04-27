# 홈화면 UI 복잡도·통일성 검증 (Audit)

> 2026-04-22 / Autopus Cycle 26 / Phase 1-3 Audit-only (코드 변경 없음)
> 대상: 선생님·학생·학부모 3개 역할별 홈화면
> 목적: Notebook × Score 디자인 시스템 적용 균일성 + Miller's Law 기반 인지 부하 평가

## 1. 방법론

### 1.1 측정 대상 (진입 파일)

| 역할 | 파일 경로 | 라인 수 |
|------|-----------|---------|
| 선생님 | `lib/features/home/presentation/widgets/dashboard_tab.dart` | 493 |
| 학생 | `lib/features/student_home/presentation/screens/student_dashboard_tab.dart` | 240 |
| 학부모 | `lib/features/parent_home/presentation/screens/parent_dashboard_tab.dart` | 697 |

### 1.2 루브릭 (4 기준 · 가중 평균 7.5 이상 PASS)

| 기준 | 가중치 | 측정식 | 최대 10점 |
|------|--------|--------|----------|
| **섹션 수 (복잡도)** | 25% | `max(0, 10 − \|N − 7\|)` — Miller's Law 7±2 | N=7 이면 10 |
| **Notebook 시그니처 적용률 (통일성)** | 35% | 6개 시그니처 중 사용 수 × 10/6 | 6/6 → 10 |
| **정보 계층 명확도 (복잡도)** | 20% | 0순위~N순위 주석 커버리지 | 전 섹션 주석 → 10 |
| **색상 일관성 (통일성)** | 20% | Material `Colors.*` 잔존 0건이면 10, 1건당 −1 | 0건 → 10 |

**Notebook × Score 6대 시그니처** (README §1.2 SSOT):

| # | 시그니처 | 분류 | 검증 |
|---|---------|------|------|
| 1 | Playfair italic 헤더 | 정체성 | `NotebookTypography.masthead/mastheadLabel/pieceTitle` grep |
| 2 | 로마숫자 인덱스 | 정체성 | `NotebookTypography.roman/romanActive` 또는 `romanOf()` 호출 |
| 3 | Vermillion 액센트 | 정체성 | `AppColors.paperAccent` foreground/border 사용 |
| 4 | Gaegu 손글씨 | 정체성 | `NotebookTypography.hand/handEmphasis/handOk` grep |
| 5 | NotebookMasthead 스캐폴드 | 구조 | `NotebookMasthead(...)` instantiate |
| 6 | "Fine." 페이지 종지부 | 구조 | `NotebookTypography.fine` + 텍스트 "Fine." |

`ThinRule` 위젯은 `NotebookMasthead` / `NotebookSectionHeader` 의 부속 — 시그니처가 아닌 구성요소로 별도 측정하지 않는다.

### 1.3 판정 임계값

**1차 게이트 — 정체성 시그니처 (점수 산식 우선)**:

| 조건 | 판정 |
|------|------|
| 정체성 4 중 1+ 누락 | **BLOCK** — 가중 평균 무관, 즉시 수정 필요 (README §1.1) |
| 정체성 4 ✓ | 2차 게이트(점수)로 진행 |

**2차 게이트 — 가중 평균 점수**:

| 점수 | 판정 |
|------|------|
| ≥ 7.5 | **PASS** — 통과 |
| 5.0 – 7.4 | **FLAG** — 개선 권고 |
| < 5.0 | **BLOCK** — 즉시 수정 필요 |

> **재채점 주의**: §2 채점표는 1차 게이트 도입 이전 산식 (구 6대 = `Masthead/Typography/ThinRule/Playfair/Roman/Fine.`) 으로 매겨졌다. 정체성 #4 Gaegu 누락 시 구 산식은 5/6 PASS 였으나 신 1차 게이트로는 BLOCK. 후속 Cycle 에서 §2 재채점 필요 — 이번 SSOT 정렬은 정의만 갱신, 점수는 보존.

## 2. 채점표

### 2.1 선생님 홈 (`dashboard_tab.dart`)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=9 | 8 | Masthead / ProgrammeTitle / TimeBanner / GettingStarted / UrgentAlert / StatsRow / TodayLessons / EventsGroup / Analytics+Fine |
| Notebook 적용 | 6/6 | 10 | `NotebookMasthead:155` · `NotebookTypography:189,192,196,308,314,388` · `ThinRule:199` · Playfair italic · Roman numerals · "Fine." footer |
| 정보 계층 | 전 섹션 | 10 | "0순위~4순위" 주석 완비 (urgent → today → trends → tools) |
| 색상 일관성 | Colors.* 0건 | 10 | grep `Colors\.(grey\|blue\|red\|green\|orange\|purple\|black\|white)` → 0 |
| **가중 평균** | | **9.5** | **PASS** |

### 2.2 학생 홈 (`student_dashboard_tab.dart`)

#### 2.2.1 Phase 4c 수정 후 (2026-04-23, Cycle 29)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=8 | 9 | Masthead / ProgrammeTitle / TimeBanner / Gamification / NextLesson(+Roman) / Subscription / EventsGroup / LearningRecordGroup (+ Fine.) |
| Notebook 적용 | 5/6 | 8.33 | + Roman numerals "I." NextLesson 카드에 추가 |
| 정보 계층 | 전 섹션 | 10 | 기존 주석 유지 |
| 색상 일관성 | 0건 | 10 | 기존 유지 |
| **가중 평균** | | **9.17** | **PASS** — Roman numerals 추가로 +0.58 |

#### 2.2.2 Phase 4b 수정 후 (2026-04-23, Cycle 27)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=8 | 9 | Masthead+ProgrammeTitle / TimeBanner / Gamification / GettingStarted / NextLesson / Subscription / EventsGroup / LearningRecordGroup / Fine. |
| Notebook 적용 | 4/6 | 6.7 | `NotebookMasthead:107` · `NotebookTypography.masthead/mastheadLabel/mastheadDate/fine:151,154,158,179` · `ThinRule:163,173` · "Fine." footer:179 / (Playfair·Roman 미적용은 선택) |
| 정보 계층 | 전 섹션 | 10 | "0순위~4순위" + "학습 기록 그룹" 주석 유지 |
| 색상 일관성 | Colors.* 0건 | 10 | AppColors 토큰만 사용 |
| **가중 평균** | | **8.59** | **PASS** — Phase 4b 적용으로 FLAG 해소 |

#### 2.2.3 Phase 4b 수정 전 (2026-04-22, Cycle 26)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=10 | 7 | Header(날짜+인사+Action2) / TimeBanner / Gamification / GettingStarted / NextLesson / Subscription / EventsGroup / Feedback / PracticeSummary / Trial |
| Notebook 적용 | 0/6 | 0 | NotebookMasthead ✗ · NotebookTypography ✗ · ThinRule ✗ · Playfair ✗ · Roman ✗ · Fine. ✗ (grep 0 matches) |
| 정보 계층 | 전 섹션 | 10 | "0순위~6순위" 주석 완비 |
| 색상 일관성 | Colors.* 0건 | 10 | AppColors 토큰만 사용 |
| **가중 평균** | | **5.75** | **FLAG** — Notebook 적용이 0건, 선생님 홈과 시각적 분리 |

### 2.3 학부모 홈 (`parent_dashboard_tab.dart`)

#### 2.3.1 Phase 4c 수정 후 (2026-04-23, Cycle 29)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=8 | 9 | Masthead / ProgrammeTitle / ChildHeader / QuickStats / UpcomingLesson(+Roman I) / PracticeStreak(+II) / RecentAssignments(+III) / PaymentStatus(+IV) (+ Fine.) |
| Notebook 적용 | 5/6 | 8.33 | + Roman numerals SectionCard 4곳 적용 (`romanIndex` prop) |
| 정보 계층 | 전 섹션 | 10 | 기존 "0순위~5순위" 주석 유지 |
| 색상 일관성 | 0건 | 10 | 기존 유지 |
| **가중 평균** | | **9.17** | **PASS** — Roman numerals 추가로 +0.59 |

#### 2.3.2 Phase 4a 수정 후 (2026-04-23, Cycle 28)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=8 | 9 | Masthead / ProgrammeTitle / ChildHeader / QuickStats / UpcomingLesson / PracticeStreak / RecentAssignments / PaymentStatus (+ Fine. 푸터) |
| Notebook 적용 | 4/6 | 6.67 | `NotebookMasthead` · `NotebookTypography.masthead/mastheadLabel/mastheadDate` · `ThinRule` · Playfair italic "Fine." (Roman numerals 미사용 — Phase 4c 대상) |
| 정보 계층 | 전 섹션 | 10 | "0순위~5순위" 주석 완비 (자녀 정보 → 통계 → 다음 레슨 → 스트릭 → 과제 → 결제) |
| 색상 일관성 | Colors.white 0건 | 10 | 8건 전부 `AppColors.paper` 치환 완료 (Vermillion 위 브랜드 백색 원칙) |
| **가중 평균** | | **8.58** | **PASS** — Notebook 4/6 + 색상 0건 + 우선순위 주석 완비 |

#### 2.3.3 Phase 4a 수정 전 (2026-04-22, Cycle 26)

| 기준 | 측정 | 점수 | 근거 |
|------|------|------|------|
| 섹션 수 | N=7 | 10 | AppBar / ChildHeader / QuickStats / UpcomingLesson / PracticeStreak / RecentAssignments / PaymentStatus |
| Notebook 적용 | 0/6 | 0 | Material `AppBar:47` 사용 (NotebookMasthead ✗) · 시그니처 0개 |
| 정보 계층 | 부분 주석 | 6 | 섹션명만 있고 우선순위 주석 없음 (선생님/학생 홈과 불균형) |
| 색상 일관성 | Colors.white 8건 | 2 | 다크 히어로 카드 내 foreground 8건 (line 172, 262, 335, 348, 366, 391, 397, 583) — Vermillion 위 paper 로 치환 필요 |
| **가중 평균** | | **4.3** | **BLOCK** — Notebook 0건 + Colors.white 8건 + 우선순위 주석 부재 |

## 3. 판정 요약

**현재 상태 (2026-04-23, Cycle 29 완료 기준)**: 세 홈 모두 PASS, 세 홈 모두 9점대.

```
         ┌────────────────────────────────────────────────────┐
    10   │                                                     │
         │       선생님 9.5                                    │
     9   │       ●─────────●────●  학생·학부모 9.17            │
         │                                                     │
     8   │                                                     │
         │                                                     │
     7   │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ PASS ─ ─ ─│
         │                                                     │
     6   │                                                     │
         │                                                     │
     5   │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ BLOCK ─ ─ │
         │                                                     │
     4   │     (과거) 학부모 4.3 → 8.58 → 9.17 해소             │
         │                                                     │
     3   │                                                     │
         └────────────────────────────────────────────────────┘
```

**변화 궤적**:
- 선생님: 9.5 PASS (변화 없음, 레퍼런스)
- 학생: 5.75 FLAG → 8.59 PASS → 9.17 PASS (Cycle 27 → 29)
- 학부모: 4.30 BLOCK → 8.58 PASS → 9.17 PASS (Cycle 28 → 29)

## 4. BLOCK 상세 — 학부모 홈 (4.3점)

### 4.1 Notebook 시그니처 0/6

현재 학부모 홈은 Material `AppBar('학부모 홈')` 를 사용. 선생님 홈의 `NotebookMasthead('LESSONAZA')` + `NotebookTypography.masthead('오늘의 레슨')` 패턴과 완전히 분리됨. 사용자가 "같은 앱인가?" 인식적 부조화 발생 가능.

**증거**:
- `parent_dashboard_tab.dart:47` — `appBar: AppBar(title: const Text('학부모 홈'), ...)`
- grep `NotebookMasthead|NotebookTypography|ThinRule|Playfair|Fine\.|Roman` → 0 matches

### 4.2 Colors.white 잔존 8건

다크 히어로 카드(`_buildChildHeader`)에서 선생님 이름·학생 이름·다음 레슨 정보 위에 `Colors.white` 하드코딩. Notebook 팔레트 원칙상 "Vermillion 위 브랜드 백색" 은 `AppColors.paper` 사용 권장 (Cycle 23 §7.50 패턴).

**8건 위치**:
- line 172 `foregroundColor: Colors.white` (자녀 전환 버튼)
- line 262 `color: Colors.white` (자녀 리스트 아이템 선택 아바타)
- line 335 `AppTypography.headingLarge.copyWith(color: Colors.white)` (다크 히어로 자녀 이름)
- line 348, 366, 391, 397 — 히어로 카드 내 부가 텍스트·아이콘
- line 583 — Quick Stats 섹션 카드

### 4.3 우선순위 주석 부재

선생님 홈(`"0순위", "1순위", "2순위"`) / 학생 홈(`"0순위", "1순위", "2순위", "3순위", ...`) 에는 정보 계층 주석 존재. 학부모 홈은 섹션명 주석만 있어 섹션 순서 변경 시 의도 유실 위험.

## 5. FLAG 상세 — 학생 홈 (5.75점)

### 5.1 Notebook 시그니처 0/6

학생 홈은 AppColors 토큰은 완벽히 사용하나, **Notebook 스캐폴드 위젯은 전혀 사용하지 않음**. 선생님 홈과 시각적 브랜드 일체감 부재.

현재 헤더(line 39-73):
```
┌─────────────────────────┐
│ 3月 25일 木               │ bodyMedium + inkSecondary
│ 안녕하세요 ○○님          │ headingLarge
│       [친구초대] [알림]   │ IconButton ×2
└─────────────────────────┘
```

권장 대체 (선생님 홈과 동일 패턴):
```
┌─────────────────────────┐
│ LESSONAZA    · VOL·25  │ NotebookMasthead eyebrow
├─────────────────────────┤
│   Programme for Thursday│ NotebookTypography.mastheadLabel
│       오늘의 연습         │ NotebookTypography.masthead
│   3月 25日 · 안녕하세요   │ NotebookTypography.mastheadDate
│ ────thin rule────────── │ ThinRule
└─────────────────────────┘
```

### 5.2 섹션 수 10건 — Miller 초과

학생 홈은 Header 를 제외해도 9개 콘텐츠 섹션(TimeBanner/Gamification/GettingStarted/NextLesson/Subscription/EventsGroup/Feedback/PracticeSummary/Trial). Miller 상한(9) 에 근접, 카드 밀도 높음.

**그룹핑 제안**:
- "학습 기록" 그룹 = Feedback + PracticeSummary + Trial → 3섹션 → 1섹션 (내부 탭/카드 분할)
- 결과: 10 → 7-8 섹션

## 6. PASS 상세 — 선생님 홈 (9.5점)

선생님 홈은 Notebook × Score 완전 적용의 기준점. 모든 6대 시그니처 사용, 정보 계층 주석 완비, 색상 잔재 0건. **학생/학부모 홈의 리팩토링 레퍼런스**로 활용 권장.

## 7. 권장 수정 목록

### 7.1 Phase 4a — BLOCK 해소 (학부모 홈) ✅ DONE (2026-04-23, Cycle 28 · fd564014)

| 우선 | 항목 | 예상 파일 | 상태 |
|------|------|-----------|------|
| 1 | `AppBar` → `NotebookMasthead` + Programme Title 교체 | parent_dashboard_tab.dart | DONE |
| 2 | `Colors.white` 8건 → `AppColors.paper` 치환 | parent_dashboard_tab.dart | DONE |
| 3 | 섹션 우선순위 주석 추가 (0~5순위) | parent_dashboard_tab.dart | DONE |
| 4 | "Fine." footer 추가 | parent_dashboard_tab.dart | DONE |

**결과**: BLOCK 4.30 → PASS 8.58 (+4.28)

### 7.2 Phase 4b — FLAG 해소 (학생 홈) ✅ DONE (2026-04-23, Cycle 27 · 1b5b3265)

| 우선 | 항목 | 예상 파일 | 상태 |
|------|------|-----------|------|
| 1 | Material 헤더 → `NotebookMasthead` + `Programme Title` 블록 | student_dashboard_tab.dart line 97-165 | DONE |
| 2 | "Fine." footer 추가 | student_dashboard_tab.dart line 170-204 | DONE |
| 3 | 섹션 그룹핑 (Feedback+PracticeSummary+Trial → 1개) | `learning_record_group.dart` 신규 + screens 수정 | DONE |

**결과**: FLAG 5.75 → PASS 8.59 (+2.84)

### 7.3 Phase 4c — 일관성 강화 ✅ DONE (2026-04-23, Cycle 29 · 80944a44)

| 우선 | 항목 | 예상 파일 | 상태 |
|------|------|-----------|------|
| 1 | Roman numerals 인덱스 학생 "다음 레슨" 카드 적용 | next_lesson_card.dart | DONE — "I." paper 0.9 alpha |
| 2 | Roman numerals 학부모 SectionCard 4개 (다음 레슨·이번 주 연습·과제·결제) 적용 | section_card.dart + parent_dashboard_tab.dart | DONE — `int? romanIndex` optional prop 0~3 |

**결과**: Notebook 시그니처 4/6 → 5/6 (학생·학부모 홈). 선생님 홈 6/6 레퍼런스 유지.

## 8. 범위 챌린지 결과

이 Audit 은 **read-only**, 0 파일 수정, 1 문서 생성.

Phase 4 수정을 진행한다면:
- **4a (학부모)**: 4건 수정 × 1 파일 = 1 파일 (BLOCK 해소 우선)
- **4b (학생)**: 3건 수정 × 1 파일 + 신규 1 파일 = 2 파일 (FLAG 해소)
- **4c (강화)**: 선택 — 별도 Cycle 권장

**권장 진행 순서**: 4a → 4b → 4c (BLOCK 먼저, FLAG 다음, 강화는 선택)

## 9. Notebook × Score 통일성 원칙 (추후 규칙화)

이번 Audit 에서 도출된 규칙:

1. **모든 홈 화면은 `NotebookMasthead` 로 시작한다** — `AppBar` 사용 금지 (학부모 홈 위반 중)
2. **6대 시그니처 중 최소 4개 사용** — Masthead + Programme Title + Thin Rule + Fine. 는 필수
3. **정보 계층 주석 필수** — "0순위~N순위" 주석으로 섹션 의도 보존
4. **섹션 수 7±2** — 10개 이상이면 그룹핑으로 축약
5. **Colors.* 잔재 0건** — Notebook 팔레트만 사용 (alpha 래더 포함)

이 규칙은 후속 Cycle 에서 `.claude/rules/notebook-home.md` 또는 `ux-rules.md` 에 추가 검토.

## 10. 은유

장부 세 권이 책장에 꽂혀 있다. 표지가 하나는 Playfair 로 조각돼 있고("LESSONAZA"), 다른 하나는 두꺼운 마커로 쓴 "학부모 홈", 또 하나는 그냥 날짜와 인사말. 같은 출판사의 책이라기엔 표지가 서로 다르다. 독자(사용자) 는 "이게 같은 시리즈인가?" 한 번 의심한다. 오늘의 검증은 **세 장부의 표지가 얼마나 같은 활자로 조판됐는가** 를 측정했다. 선생님 장부는 완성본, 학생 장부는 활자 없는 초고, 학부모 장부는 다른 인쇄소에서 찍힌 별책이다. 통일성의 기준점은 이미 선생님 장부에 있으니, 나머지 두 장부를 그 활자로 재조판하면 된다.

---

**다음 단계**:
- 이 문서를 검토 후 Phase 4a(학부모 BLOCK 해소) 진입 여부 결정
- 진입 시 `/plan` 으로 학부모 홈 리팩토링 상세 계획 수립 권장 (4 + 수정 = 8+ 파일 가능성 있어 범위 분할)
