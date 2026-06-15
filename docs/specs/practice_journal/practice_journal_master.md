# 연습장(Practice Journal) 마스터 스펙

> 마지막 업데이트: 2026-06-15
> 구현 상태: [기획] 스펙 확정 — 미구현 (착수 대기)
> 확정 결정(2026-06-15): 인장색 기존 잉크 재사용 · birthdate 스키마 미변경(표준 톤+부모 override) · 출시 P1(연습장) 우선 · 평가는 연결상태 적응(선생님 과제한정/자가 검인)
> 분류: 신규 도메인 `features/practice_journal/` · 리텐션/인게이지먼트
> 디자인 컨셉: Notebook×Score 정합 (`docs/specs/design/notebook/README.md`)

---

## 1. 개요

**한 줄 요약**: 학생·부모·선생님 세 사람이 각자의 **인장(도장)**을 찍어 한 장의 **연습장**을 함께 완성하고, 곡을 끝내면 그 기록이 **완성본(책)**으로 제본되는 삼자(三者) 연결 의식.

**목적**: 기존 게이미피케이션(점수/뱃지/스트릭)과 **중복되지 않는** 새로운 지속-사용 동력을 만든다. 저쪽이 "점수"라면 이쪽은 **사람의 진짜 흔적**이다. 매일 열 이유(일일 도장)와 계속할 이유(곡이 책이 된다)를 한 줄로 잇는다.

**대상**: 일일 활성 — 자녀(연습), 부모(주간 확인), 선생님(레슨 시 검사).

---

## 2. 배경 — 시장조사 근거와 차별화 전략

습관관리 앱의 표준 리텐션 장치(스트릭, 포인트, 레벨, 뱃지, 리더보드, 챌린지, 마일스톤/리인게이지먼트 알림)는 **이미 본 앱에 구현되어 있다**(`gamification`, `notification` 도메인). 따라서 이 스펙은 표준 장치를 추가하지 않는다. 대신 시장조사에서 식별한 **차세대 패턴 중 ① 노트×악보 미학에 맞고 ② 미성년에 안전하고 ③ 법적으로 차별화되는 것**만 고유 메커니즘으로 재해석한다.

### 차용한 패턴과 재해석

| 시장 패턴 (원전) | 본 스펙의 재해석 | 클론 회피 |
|---|---|---|
| Pet/Avatar 정서 애착 (Finch) | 펫 대신 **세 사람의 인장이 채워지는 장부** — 대리돌봄을 *관계 인증*으로 치환 | 캐릭터 없음 |
| Endowed Progress / 시각 진행 (Forest) | 숲 대신 **완성본 책장**(로마숫자 책등) | 숲/나무 메타포 없음 |
| Gentle / Anti-streak (Atoms, Finch) | 빈 날 = **음악의 쉼표**, 끊김 수치심 0 | — |
| Social Accountability (Habitica) | 또래 비교 대신 **부모·선생님의 실제 인장** (소셜 비교 0) | 리더보드 비연계 |
| Milestone (음악 본연) | **곡 완성 → 제본 → 출판(발표회)** | — |

### 핵심 통찰 — "진짜 사람의 잉크"

노트×악보 미학은 본래 *진짜 손글씨·도장·빨간펜*을 원하고, 노트북 스펙 §1.1.1 "시스템 생성 데이터는 자필(Gaegu) 금지" 원칙과도 충돌하지 않는다. 시스템이 자필을 흉내내는 것이 아니라, **학생·부모·선생님 세 사람의 실제 흔적**으로 장부가 채워지기 때문이다. 그리고 "선생님-부모-학생 잉크 의식"은 어떤 습관앱도 갖지 않은 구조라, **베낄 원본 자체가 없어** 트레이드드레스/IP 소송 리스크가 가장 낮다.

> 시장조사 출처(요약): Duolingo streak 심리/Earn Back, Finch 젠틀 설계, Habitica 소셜, Forest 진행감, EU DSA(2025) 미성년 streak 기본 OFF 가이드, FTC COPPA 2024. 상세 URL은 기획 리서치 노트 참조.

---

## 3. 핵심 제약 (HARD 전제)

| # | 제약 | 근거 |
|---|------|------|
| C1 | **재해석 강제** — 평면 잉크 + Playfair serif + 로마숫자 + 한글 손글씨 미학. 한자 컴파운드 금지(날짜 `6月 18日` 장식만 허용) | 브랜드 정체성 (§11) |
| C2 | **미성년 = 부모 계정** — 미성년 단독 가입 없음. 아이는 **부모계정 내 자녀 프로필**로 상호작용 | 사용자 결정 (COPPA형) |
| C3 | **법적 차별화** — 타 서비스 클론 금지. 고유 메커니즘만 | 사용자 결정 |
| C4 | **비처벌 / 비압박** — 스트릭 깨짐 수치심·소셜 비교·구매 유도 0 | EU DSA / COPPA, 미성년 안전 |
| C5 | **자가 연습 지원** — 선생님 없이도 학생이 **자가 검인**으로 스스로 평가. 선생님 연결 시 검인은 **과제(assignment) 한정** | 현재 앱은 선생님 없이 학생 단독 연습 가능 |

---

## 4. 용어 (Ubiquitous Language)

UI 표기는 **한글**, 코드명은 **영문**으로 동일. UI 표기는 자녀 프로필 연령에 따라 **연령별 적응**(도장판 ↔ 연습장).

| UI (표준 톤) | UI (어린이 톤) | 코드 (FE=BE 동일) | 정의 |
|---|---|---|---|
| 연습장 | 도장판 | `PracticeLedger` | 월 단위 인장 모음 (한 자녀 프로필의 한 달) |
| 연습 도장 | 연습 도장 | `PracticeMark` | 학생 일일 도장 — 그날 연습 활동에서 자동 파생 |
| 확인 도장 | 칭찬 도장 | `GuardianSeal` | 부모 주간 인장 (+ 선택적 한 줄 응원) |
| 선생님 도장 | 참 잘했어요 도장 | `Endorsement(by: teacher)` | 선생님 검인 — **과제(assignment) 한정** + 빨간펜 한 줄 |
| 자가 검인 | 내 도장 | `Endorsement(by: self)` | 학생 스스로의 평가 — 자가 도장 + **한 줄 회고**(Gaegu). 선생님 없을 때 평가 주체 |
| 완성본 | 완성본 | `BoundVolume` | 완성한 곡 1권 — 책등은 로마숫자 (VOL. I·II·III) |

> 연령 톤 전환은 **presentation 레이어 문자열 resolver**가 담당한다. 도메인 엔티티는 톤을 모른다(순수 유지). 연령 정보(birthdate)가 없으면 **표준 톤** 기본, 부모가 자녀 프로필에서 override.
> 구현 착수 시 위 용어를 `.harness/knowledge/glossary.md`(SSOT)와 `docs/specs/glossary.md`에 머지한다(`glossary-sync.md`).

---

## 5. 핵심 컨셉 — 의식 (The Ritual)

### 5.1 세 인장의 삼각형

연습은 매일 **인장 한 번**으로 기록되고, 세 사람이 각자 다른 인장을 찍어 한 장의 장부를 함께 완성한다.

```
   +--------- 연습장 · 6月 · 지우 ---------+      (날짜 6月만 기존 장식 유지)
   |  월 화 수 목 금 토 일                  |
   |  ●  ●  ●  𝄽  ●  ●  ◐    주│확인 ●    |      부모 주1회 '확인 도장'
   |  ●  ◐  ●  ●  𝄽  ●  ●    주│확인 ●    |
   | ------------------------------------- |
   |     선생님 도장 ✓ · 빨간펜 한 줄        |      선생님 '검사 도장'(레슨 시)
   +---------------------------------------+
       ●  연습 도장(완전)   ◐ 짧은 연습   𝄽 쉼표(빈 날)
       완성본 책등: VOL. I  II  III  (로마숫자)
```

| 인장 | 주체 | 트리거 | 마찰 |
|---|---|---|---|
| 연습 도장 (`PracticeMark`) | 자녀 프로필 | 그날 연습 활동 → 자동 파생 + 마지막 "도장 꾹!" 축하 탭 | 최저 |
| 확인 도장 (`GuardianSeal`) | 부모 | 주 1회 장부에서 탭 (+ 선택 한 줄) | 낮음 |
| 선생님 검인 (`Endorsement` by teacher) | 선생님 | 레슨 시 + **과제 한정** 탭 + 빨간펜 한 줄 | 낮음 |
| 자가 검인 (`Endorsement` by self) | 학생 | 선생님 미연결 시 스스로 도장 + 한 줄 회고 | 낮음 |

> "연습 도장"은 **기존 연습 활동(practice 도메인)에서 자동 파생**한다. 별도 수동 기록을 강요하지 않는다(이중 기록 0). 단 연습 완료 직후의 "도장 꾹!" 탭은 남겨 아이의 **보상 순간**으로 둔다.

### 5.2 젠틀 설계 (차별화 + 미성년 안전, C4)

- 빈 날은 "스트릭 깨짐"이 아니라 **음악의 쉼표 𝄽**로 표기 — 쉼표도 악보의 일부다. 처벌·수치심 메시지 0.
- 카운트는 "연속 N일"이 아니라 **"이번 달 도장 12개"** (누적·비압박). 기존 `gamification` 스트릭의 끊김 압박을 이 장부는 **증폭하지 않는다**.
- 알림 절제: "도장 찍을 시간!" 류 daily nag 금지. 부모 주간 리마인드 1회만(§9, 기존 notification 정책 준수).
- 소셜 비교 0(리더보드 비연계), 구매 유도 0.

### 5.3 A+C 레이어 — 일일 심장박동 + 장기 보상

- **A (연습장)**: 매일 열 이유. 도장이 칸을 채운다.
- **C (제본)**: 계속할 이유. 한 곡(레퍼토리/챕터)을 끝내면 그 기록이 **완성본 한 권**으로 제본되어 책장에 꽂힌다. 연습이 페이지를 채우고, 숙련이 챕터를 매듭짓고, 발표가 "출판"한다.

> 곡 완성의 정의는 **기존 repertoire 완료 이벤트를 재사용**한다(새 완성 기준을 만들지 않는다, §6).

---

## 6. 사용자 시나리오 (역할별 + 2자 fallback)

### 6.1 자녀(연습 주체)
1. 연습을 마친다(기존 practice 플로우).
2. "도장 꾹!" 축하 탭 → 오늘 칸에 연습 도장이 찍힌다.
3. 연습장에서 이번 달 도장과 부모/선생님 인장이 쌓이는 것을 본다.
4. 곡을 끝내면 "완성본으로 제본" 축하 → 책장에 VOL.가 추가된다.

### 6.2 부모
1. 홈에서 "이번 주 확인 도장" 카드(자녀별, 미확인 배지)를 본다.
2. 자녀 연습장을 열어 한 주를 보고 **확인 도장**을 찍는다(+ 선택 한 줄 응원).

### 6.3 선생님
1. 학생 상세에서 "연습장" 섹션(이번 달 현황, 읽기)을 본다.
2. 레슨 시 **선생님 도장 + 빨간펜 한 줄**을 남긴다.

### 6.4 적응형 평가 — 연결 상태별 (C2/C5 대응)

세 역할은 **기록(학생) · 평가(선생님 또는 자가) · 응원·확인(부모)** 로 분리된다. "응원·확인"은 부모의 역할로, 잘함/못함 판단이 아니라 "봤다 + 응원한다"는 정서적 인정이다(채점 아님). 평가 주체는 연결 상태에 따라 적응한다.

| 연결 상태 | 기록 | 평가 주체 | 부모 응원·확인 |
|---|---|---|---|
| 선생님+부모 (미성년) | 학생 연습 도장 | 선생님 검인 (과제 한정) | 확인 도장 |
| 선생님만 (성인) | 학생 연습 도장 | 선생님 검인 (과제 한정) | — |
| 부모만 (미성년 자가연습) | 학생 연습 도장 | 학생 자가 검인 | 확인 도장 |
| 단독 (성인 자가연습) | 학생 연습 도장 | 학생 자가 검인 | — |

- **자가 검인은 항상 가능**(학생 본인의 연습일지 회고). 선생님이 없으면 자가 검인이 평가 주체가 된다(단순 노드 생략 아님 — C5).
- **선생님 검인은 과제(assignment) 한정**. 학생의 자유 연습 전체가 아니라 선생님이 부여한 과제에 대해서만 판단한다.
- **부모 응원·확인은 평가가 아니다** — 채점관이 되지 않도록 정서적 지지로만.
- 빈 노드는 "아직 없음" 중립 라벨, 압박 문구 금지.

---

## 7. 화면 · 진입점 (5단 wiring — 고아 위젯 금지)

> `entry_point_wiring` 규칙: 위젯만 만들고 화면 통합을 미루는 "덩그러니" 패턴 금지. 모든 진입점에 시각 affordance + wiring.

### 7.1 자녀
```
홈(student_dashboard) ─▶ [연습장 카드: 이번 달 ●12 · 미니그리드 미리보기]
   └▶ 연습장 화면(월 그리드)  ◀─ 연습 완료 시 "도장 꾹!" 축하 탭
        └▶ 곡 완성 ─▶ "완성본으로 제본" 축하 ─▶ 책장(VOL. I·II·III)
```

### 7.2 부모
```
홈(parent_dashboard) ─▶ [이번 주 확인 도장 카드: 자녀별 · 미확인 배지]
   └▶ 자녀 연습장 ─▶ "확인 도장 찍기"(주1회) ─▶ (선택) 한 줄 응원 ─▶ 결과 표시
   알림(주1회): "이번 주 OO이 연습장 확인하기"
```

### 7.3 선생님
```
학생 상세 ─▶ [연습장 섹션: 이번 달 현황(읽기)]
   └▶ 연습장 화면 ─▶ "선생님 도장 + 빨간펜 한 줄"(레슨 시) ─▶ 검인 표시
```

### 7.4 신규 화면/위젯 (도메인 린터 명명)
| 파일 | 클래스 | 역할 |
|---|---|---|
| `presentation/screens/practice_journal_screen.dart` | `PracticeJournalScreen` | 월 그리드 장부 (3역할 공용, 역할별 액션 분기) |
| `presentation/screens/bound_shelf_screen.dart` | `BoundShelfScreen` | 완성본 책장 |
| `presentation/widgets/practice_journal_card.dart` | `PracticeJournalCard` | 홈 진입 카드 (미니 그리드) |
| `presentation/widgets/journal_month_grid.dart` | `JournalMonthGrid` | 월 도장 그리드 |
| `presentation/widgets/stamp_press_sheet.dart` | `StampPressSheet` | "도장 꾹!" 축하 + 인장 찍기 액션 |
| `presentation/widgets/bound_volume_spine.dart` | `BoundVolumeSpine` | 완성본 책등 (로마숫자) |

---

## 8. 데이터 모델 (Mock-first)

> 구현 순서: Entity(`@JsonSerializable` + copyWith — 본 코드베이스는 gamification/practice 도메인과 동일하게 json_annotation 사용, Hive 아님) → Repository 인터페이스 → MockRepository(메모리) → `@riverpod` Provider(`createRepository` 헬퍼) → build_runner → UI.
> 연계: 연습 도장 파생 훅 = `features/practice/domain/services/practice_recording_service.dart`의 `PracticeRecordingService.recordPractice()`. 자녀 프로필 = `Student.parentConsentAt`(null=자가 연습 전용) + `profileColorKey`. 곡 완성(P2) = `PracticeRepertoireRepository.archiveRepertoire()`.

### 8.1 엔티티

| 엔티티 | 핵심 필드 | 생성 시점 |
|---|---|---|
| `PracticeLedger` | `id`, `childProfileId`, `year`, `month`, `marks: List<PracticeMark>` | 매월 1일 (lazy 생성) |
| `PracticeMark` | `date`, `intensity: MarkIntensity{full, short}` | 연습 활동 파생 |
| `GuardianSeal` | `weekStart`, `guardianUserId`, `cheerNote: String?` | 부모 주간 액션 |
| `Endorsement` | `by: EndorsedBy{self, teacher}`, `date`, `authorUserId`, `assignmentRef: String?`(teacher 한정), `note: String`(빨간펜/회고) | 선생님 검인(레슨 시) 또는 자가 검인(자가 평가 시) |
| `BoundVolume` | `childProfileId`, `pieceId`, `volumeNo: int`(로마 렌더), `boundDate` | 곡 완성 이벤트 |

### 8.2 도메인 규칙
- `PracticeMark`는 한 `(childProfileId, date)`당 **최대 1개**. 같은 날 여러 연습 → intensity만 갱신(full 우선).
- `MarkIntensity`: 일정 시간/세션 충족 시 `full(●)`, 짧으면 `short(◐)`. 임계값은 구현 시 practice 도메인 기준 재사용(새 임계값 신설 금지 — design-principles SSOT). 단 practice에 해당 임계값이 없으면 계획 단계에서 명시 정의한다(undefined 값 금지).
- `GuardianSeal`은 한 `(childProfileId, weekStart)`당 최대 1개(주 1회).
- `Endorsement`: `by=teacher`는 반드시 `assignmentRef`(과제 참조)를 가진다 — 과제 한정. `by=self`는 `assignmentRef` 없음(자유 회고). 선생님 미연결 시 `by=teacher` 생성 불가, 자가 검인(`by=self`)이 평가 주체. 자가 검인은 **회고(서술)만**, 점수/등급 금지(C4 압박 방지).
- 월 경계: 매월 1일 새 `PracticeLedger`. 이전 달 장부는 히스토리로 보관(삭제하지 않음).
- 완성본 `volumeNo`는 자녀 프로필별 1부터 증가, `romanOf()`(노트북 §6.3)로 렌더.

### 8.3 레이어 / 의존성 방향 (`flutter-architecture.md`)
```
practice_journal/
├── domain/        # 엔티티(순수), repository 인터페이스
│   └── entities, repositories(abstract)
├── data/          # MockRepository, (후속) RemoteRepository
└── presentation/  # screens, widgets, providers(@riverpod), extensions(연령 톤/표시 변환)
```
- 도메인은 화면 표시 getter(label/emoji/route) 금지. 표시 변환은 `presentation/extensions`.
- 연습 활동→연습 도장 파생은 **application service**(`presentation`)에서 practice facade를 주입받아 조립(도메인이 practice provider를 import하지 않는다).

---

## 9. 상태 / 이벤트 흐름

### 9.1 연습 → 연습 도장
```
practice 완료 이벤트
  → JournalMarkService.onPracticeLogged(childProfileId, date, intensity)
  → 해당 월 PracticeLedger 확보(없으면 생성)
  → PracticeMark upsert(중복 없으면 추가, 있으면 intensity 갱신)
  → "도장 꾹!" 축하(StampPressSheet) — 보상 순간
```

### 9.2 곡 완성 → 제본
```
repertoire 완료 이벤트(기존)
  → BoundVolumeService.onPieceCompleted(childProfileId, pieceId)
  → volumeNo = (기존 완성본 수 + 1)
  → BoundVolume 영속화 → "완성본으로 제본" 축하 → 책장 갱신
```

> 트리거 소스 주의: 현재 "곡/레퍼토리 완성"은 별도 `features/repertoire/`가 아니라 `features/profile/`(레퍼토리 관리)·`practice` 하위에 있다. 계획 단계에서 실제 완성 이벤트 진원지를 확정한 뒤 §9.2를 와이어링한다.

### 9.3 알림 (기존 notification 재사용, 신규 인프라 금지)
| 알림 | 대상 | 빈도 | 비고 |
|---|---|---|---|
| 주간 확인 리마인드 | 부모 | 주 1회 | 기존 DND/한도 정책 준수 |
| 검인 프롬프트(선택) | 선생님 | 레슨 후 1회 | 미배정 시 생략 |

---

## 10. 디자인 토큰 / 노트북 정합

| 요소 | 토큰/위젯 | 비고 |
|---|---|---|
| 표면 | `NotebookScreenScaffold` / `NotebookDetailScaffold` | 직접 Scaffold 금지 |
| 타이틀/매스트헤드 | `NotebookTypography.masthead` (Playfair) | |
| 완성본 책등 번호 | `romanOf()` + `NotebookTypography.roman` | 로마숫자 (C1) |
| 손글씨(부모 응원/선생님 빨간펜/**학생 자가 회고**) | `NotebookTypography.hand/handEmphasis` (Gaegu) | **사람 작성**이라 자필 허용 (§1.1.1 Tier 1) |
| 인장/글리프 | `NotebookGlyph` (시그니처 영역, Material Icons 금지) | 도장=원형 잉크, 쉼표=음표 글리프 |
| 모서리 | `BorderRadius.zero` | 각진 원칙 |

### 10.1 인장 색 (잉크) — 권장: 기존 토큰 재사용
| 인장 | 색 토큰 | 의미 |
|---|---|---|
| 연습 도장(학생) | `AppColors.ink` (차콜) | 일상의 잉크 |
| 확인 도장(부모) | `AppColors.paperOk` (녹색) | 확인·안심 |
| 선생님 도장 | `AppColors.paperAccent` (버밀리온) | 권위·교정(빨간펜 동일 계열) |

> 신규 토큰 없이 즉시 구현 가능(Ask First 회피). 부모 녹색은 구독 "정기" 녹색과 surface가 달라 의미 충돌 경미. 강한 색 분리를 원하면 §15의 남색(藍) 신규 토큰 대안 — **별도 승인 필요**.

---

## 11. 엣지 케이스 / 미성년 안전 (C4)

| 케이스 | 처리 |
|---|---|
| 빈 날 / 연속 결석 | 쉼표 𝄽 표기, 수치심 메시지 0 |
| 소셜 비교 | 리더보드 비연계, 타인 장부 노출 0 |
| 구매 유도 | 0 (인장/제본 모두 무과금) |
| 성인 학생 | 부모 노드 생략(2자), 표준 톤 |
| 자가 학습(선생님 미연결) | 선생님 검인 대신 **학생 자가 검인**이 평가 주체 (omission 아님 — C5) |
| 선생님 평가 범위 | **과제(assignment) 한정** — 자유 연습 전체 평가 금지 |
| 자가 검인 형태 | 자가 도장 + **한 줄 회고**(서술). 점수/등급화 금지(미성년 압박 방지) |
| 연령 정보 없음 | 표준 톤 기본, 부모 override 가능 |
| 월 경계 | 매월 새 장부, 과거 보관 |
| 곡 완성 기준 | 기존 repertoire 이벤트 재사용(신설 금지) |

---

## 12. 단계 (YAGNI — 하나의 flagship을 단계적으로)

### Phase 1 (MVP) — 연습장(A) 코어
- 자동 연습 도장(practice 파생) + 월 그리드 + 3역할 뷰
- 부모 응원·확인 도장 + 평가(선생님 검인=**과제 한정** / 자가 검인=**한 줄 회고**, 연결 상태별 적응)
- 기존 잉크 토큰 재사용, 표준/어린이 톤 2종(연령 기본 + 부모 override)
- 홈 진입 카드(자녀·부모) + 학생 상세 섹션(선생님)

**AC(P1)**
- [ ] 연습 1회 → 해당 날짜 도장 1개(자동), "도장 꾹!" 축하 1회
- [ ] 같은 날 재연습 시 도장 중복 생성 안 됨(intensity만 갱신)
- [ ] 빈 날이 쉼표로 표기되고 스트릭 압박 문구가 없음
- [ ] 부모가 주 1회 확인 도장을 찍고 자녀 장부에 반영됨
- [ ] 선생님이 검인 + 빨간펜 한 줄을 남기고 장부에 반영됨
- [ ] 2자 fallback(성인/자가학습)에서 빈 노드가 압박 없이 처리됨
- [ ] 연령 톤 전환(도장판/연습장)이 자녀 프로필 연령으로 결정됨
- [ ] 선생님 미연결 시 학생이 자가 검인(도장 + 한 줄 회고)으로 스스로 평가할 수 있음
- [ ] 선생님 연결 시 검인이 과제(assignment) 범위로 한정됨 (자유 연습 전체 평가 안 됨)
- [ ] 부모 응원·확인이 평가(점수/판단)가 아닌 정서적 인정으로만 동작함

### Phase 2 — 제본(C)
- 곡 완성 → 완성본 생성 + 책장 화면(로마숫자 책등)
- 알림 연계(부모 주간 확인 리마인드, 선생님 검인 프롬프트)

**AC(P2)**
- [ ] 곡(레퍼토리) 완성 시 완성본 1권 생성, volumeNo 1부터 증가(로마 렌더)
- [ ] 책장에서 완성본/연습중(점선)이 구분됨
- [ ] 부모 주간 리마인드가 기존 DND/한도 정책을 준수함

### Phase 3 (선택)
- 연령 톤 적응 정교화, 부모 한 줄 응원 확장, 완성본 발표회(출판) 연계

---

## 13. 검증 / 테스트 전략

- **도메인 유닛**: 도장 중복 방지, 월 경계, 주간 1회 제약, 완성본 번호 증가, 2자 fallback.
- **Provider 테스트**: MockRepository 기반 3역할 상태.
- **위젯 smoke test (HARD-GATE)**: 신규 top-level 위젯(`PracticeJournalScreen`/`BoundShelfScreen`/카드/그리드/시트/책등) 각각 `pumpAndSettle` + `takeException() isNull`. 좁은 제약(Row/Column/Expanded) 회귀 1건 포함.
- **토큰/아이콘 컴플라이언스**: 시그니처 영역 `Icons.*` 0(NotebookGlyph), `Color(0x` 0(AppColors), `BorderRadius.circular` 0(각진 원칙).
- **i18n**: 하드코딩 한글 0(AppStrings), 연령 톤은 presentation resolver. domain/data가 AppStrings 직접 import 0.

---

## 14. 비목표 (Non-goals / 명시적 배제)

- 점수/레벨/뱃지/리더보드 신설 — 기존 `gamification`이 담당, **중복 금지**.
- 펫/아바타/캐릭터 양육 — 클론 회피(C3).
- 미성년 단독 계정 / 미성년 소셜 그래프 — C2/C4 위반.
- 새 연습 완료 임계값/완성 기준 신설 — 기존 practice/repertoire 재사용.
- 신규 알림 인프라 — 기존 notification 재사용.
- 선생님 평가를 과제 밖 자유 연습으로 확대 — 과제 한정 원칙(C5) 위반.
- 자가 평가를 점수/등급화 — 회고(서술)만, 점수화 금지(미성년 압박).

---

## 15. 미해결 / Ask First

| 항목 | 결정 (2026-06-15) | 비고 |
|---|---|---|
| 인장 색 | **기존 잉크 재사용** (학생 `ink` / 부모 `paperOk` / 선생님 `paperAccent`) | 남색 신규 토큰 보류 |
| 자녀 birthdate | **스키마 변경 없음** — 표준 톤 기본 + 부모 override | 자동 연령 전환 보류(추후 birthdate 추가 시) |
| 출시 범위 | **P1(연습장) 우선** | P2(제본)는 P1 검증 후 |
| 곡 완성 트리거 진원지 | 계획 단계 확정 (`features/profile` 레퍼토리 이벤트) | §9.2 |
| 완성본 발표회 연계(P3) | 미정 | 발표회 도메인과 인터페이스 합의 후 |

---

## 16. 의사결정 요약

> 결정의 "왜/배제"는 구현 커밋의 git trailer(`Directive:`/`Constraint:`/`Rejected:`)로 기록한다(`lore-trailer-migration.md`). 본 절은 합의 사실만 평문 보관.

- 리텐션 대상 = **삼자 연결 의식** (단일 플레이어 모델 배제 — 미성년 안전 + IP 차별화).
- 접근 = **A(연습장 일일) + C(제본 장기) 레이어드** (B 왕복서신 전체는 쓰기 마찰로 배제, 영혼만 부모·선생님 인장에 흡수).
- 미성년 동선 = **부모계정 내 자녀 프로필**.
- 표기 = **한글 + 연령별 적응**(한자 컴파운드 배제 — 브랜드 불일치).
- 인장 색 = **기존 잉크 재사용 권장**(신규 토큰 Ask First 회피).
- 평가 = **연결 상태별 적응** — 선생님 연결 시 과제 한정 검인 / 미연결 시 학생 자가 검인(한 줄 회고). 부모는 평가 아닌 응원·확인. 단순 노드 생략 배제(C5).
