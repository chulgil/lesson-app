# Notebook × Score Design System

> Last updated: 2026-05-05
> 컨셉: **괘선 종이의 아날로그 손맛 + 클래식 악보의 엄격한 타이포그래피**
> 상태: 전 도메인 Notebook × Score 적용 완료 (Phase 1~9). 테마 레이어 전역 통일 + BoxShadow 전수 제거 + BorderRadius 포화
> 레퍼런스: `design-plan/hybrid/`

---

## 1. 컨셉 정의

**Notebook × Score**는 다음 두 세계의 하이브리드다.

| 레이어 | 영감 | 표현 |
|--------|------|------|
| Notebook | 수업용 노트 / 연습일지 | 크림색 종이, 붉은 왼쪽 여백선, 손글씨 주석 |
| Score | 클래식 악보 (17~19C) | Playfair Display serif, 로마숫자 악장 번호, 오선/Fine, 버밀리온 액센트 |

### 1.1 정체성 시그니처 4대

이 컨셉을 식별하게 하는 **4가지 필수 요소**. 하나라도 빠지면 Notebook × Score가 아니다 — 점수 산식과 무관하게 1개 누락 = **BLOCK**.

| # | 시그니처 | 규칙 |
|---|---------|------|
| 1 | **Playfair Display serif** | 타이틀·매스트헤드·주요 숫자. `FontWeight.w700` + italic 변형 |
| 2 | **로마숫자 (I, II, III, IV…)** | 레슨 번호, 섹션 번호, 탭 아이템 인덱스 |
| 3 | **Vermillion Red (#9B1B12)** | 강조 액션·현재 진행·하이라이트. 왼쪽 여백선은 #A83E3A (번진 잉크톤) |
| 4 | **Gaegu 손글씨 주석** | 사람이 작성한 자필 본문/완료 마크. **§1.1.1 4계층 적용 의사결정** 필수 준수 |

#### 1.1.1 Gaegu 손글씨 4계층 적용 의사결정 (§7.127, 2026-04-28)

> 클래식 전공 선생님의 종이 노트북 메타포에서 **자필**은 인격적 메시지·즉흥 평어로, **인쇄체**는 객관적 데이터로 사용된다. 두 매체의 혼합이 노트북 메타포의 본질. 시스템이 자동 생성한 데이터에 자필을 입히면 "가짜 자필" → 메타포 신뢰 훼손.
>
> **의사결정 트리**: "이 텍스트의 작성 주체는 누구인가?" → 사람이면 자필(Tier 1·2), 시스템이면 인쇄체(Tier 3·4).
>
> **§7.130 이항 룰 (단순화 우선)**: "사람의 액션 산출물 = hand, 시스템 정의 라벨/카운트/식별자 = sans-serif." 새 화면 추가 시 이 한 질문으로 결정. 모호하면 아래 4계층 매트릭스 적용.

| 계층 | 작성 주체 | 텍스트 종류 | 스타일 | 예시 |
|------|---------|----------|--------|------|
| **Tier 1** (필수 자필) | 선생님·학생·학부모 | 자필 본문 (≥1 줄) | `NotebookTypography.hand` | 선생님 피드백 본문/입력, 연습 팁, 학생 메모/입력, 곡 메모, 연습노트 본문, **연습 과제 제목·설명**, **레퍼토리·곡명 입력**, **일괄 피드백 입력/미리보기** — **사람의 액션 산출물 모두 (§7.129, §7.130)** |
| **Tier 2** (조건부 자필) | 사람 | 짧은 자필 강조 (≤5 자) / 완료 체크 | `hand` 또는 `handOk` | "✓ 보잉 좋음", 자필 체크 마크 |
| **Tier 3** (논쟁 영역) | 시스템 | 안내문·온보딩 톤 | `hand` 또는 Pretendard | "선생님 톤" 의도 명확 → `hand` / 일반 안내 → 기본 본문 |
| **Tier 4** (산세리프 강제) | 시스템 | 자동 인디케이터·입력 필드·메뉴 라벨·데이터값 | `indicatorLabel` (Pretendard italic) 또는 기본 | "오늘", "D-N", "입금대기(후불)", "필수", "진행 중" |

**Tier 4 회피 신호 (이 패턴이면 자필 적용 금지)**:
- 앱이 자동 계산한 시간 라벨: "오늘", "내일", "D-N"
- 시스템 상태 뱃지: "입금대기(후불)", "필수", "진행 중", "대기", "완료"
- 검색·식별자·번호·메뉴 입력 필드 — 산세리프 (자유 서술 입력은 §1.1.1 Tier 1, §7.129)
- 시스템 라벨 (uppercase 카테고리, "STUDENT · INSTRUMENT")
- 데이터값 (날짜·시간·금액 — Mono 또는 Sans)

**Tier 3 결정 가이드 (안내문, §7.128 정제)**:

| 안내문 패턴 | 스타일 | 사례 |
|------------|------|------|
| 시간대 인사·온보딩 부드러운 톤·로그인 인삿말 | `hand` 유지 | "오늘은 비 오는 화요일이에요", "— 시작하시겠어요?", "학부모이신가요?" |
| **빈 상태 부연 (subtitle)** | `AppTypography.bodyMedium` | "새로운 신청이 들어오면 표시돼요", "아래 버튼을 눌러 추가하세요" |
| **정책 footnote / 객관적 정보** | `AppTypography.bodyMedium` | "* 5주차가 있는 달은 기본 휴강이에요" |
| **인터랙션 힌트 / 시스템 가이드** | `AppTypography.bodyMedium` | "미참석자만 탭하세요", "스크롤해서 더 보기" |

결정 모호 시 검사:
1. 같은 화면에 자필이 다른 영역(피드백 본문 등)에 이미 쓰이는가? → 중복되면 Pretendard로 분리
2. 텍스트가 객관적 데이터/정책/시스템 가이드인가? → Pretendard
3. 텍스트가 인격적 대화 톤인가? → `hand` 후보

**구현 토큰** (`NotebookTypography`):
- `hand` — Tier 1 자필 본문 (Gaegu 16/400)
- `handOk` — Tier 2 완료 마크 (Gaegu 13/700, paperOk)
- `indicatorLabel` — Tier 4 시스템 인디케이터 (Pretendard 11/700 italic)

### 1.2 감사 시그니처 6대 (정체성 4 + 구조 2)

§1.1 4대 + 다음 2 구조 시그니처 = 감사 점수 분모. `home_screens_audit.md` 와 SSOT 정렬.

| # | 시그니처 | 분류 | 규칙 | 현황 (2026-05-04) |
|---|---------|------|------|------|
| 1 | Playfair italic 헤더 | 정체성 (§1.1 #1) | `NotebookTypography.masthead/mastheadLabel/pieceTitle` | 전 화면 적용 |
| 2 | 로마숫자 인덱스 | 정체성 (§1.1 #2) | `NotebookTypography.roman/romanActive` + `romanOf()` | 전 화면 적용 |
| 3 | Vermillion 액센트 | 정체성 (§1.1 #3) | `AppColors.paperAccent` foreground/border | 전 화면 적용 |
| 4 | Gaegu 손글씨 | 정체성 (§1.1 #4) | `NotebookTypography.hand/handEmphasis/handOk` | 31개 파일 52건 적용 |
| 5 | **NotebookMasthead 스캐폴드** | 구조 | 원칙적으로 모든 화면·탭의 진입 헤더 — `AppBar` 사용 금지. 단, 반복 업무 화면은 §1.2.1 Compact Work Header 예외 가능 | 전 화면 적용 |
| 6 | **"Fine." 페이지 종지부** | 구조 | 스크롤 종료 영역의 italic 마커 (`NotebookTypography.fine`) | 대시보드 3종 + 상세 화면 8개 포함 11개 화면 파일 적용 |

`ThinRule` 위젯은 `NotebookMasthead` 와 `NotebookSectionHeader` 의 부속 — 시그니처가 아닌 구성요소.

#### 1.2.0 Surface Wrapper SSOT

화면, 상세, 다이얼로그, 바텀시트의 표면은 공통 래퍼로만 시작한다. 개별 화면이 직접 Material 기본 `Scaffold`/`AlertDialog`/sheet surface를 설계하면 `paper` 배경, 각진 원칙, Playfair 타이틀이 다시 분기된다.

| 표면 | 공통 래퍼 | 파일 | 계약 |
|------|------|------|------|
| 일반 화면 | `NotebookScreenScaffold` | `core/widgets/notebook/notebook_surfaces.dart` | `backgroundColor: AppColors.paper` |
| 상세 화면 | `NotebookDetailScaffold` | `core/widgets/notebook/notebook_surfaces.dart` | paper 배경 + `titleSpacing: 0` + `NotebookTypography.appBarTitle` |
| 다이얼로그 | `NotebookAlertDialog` / `showNotebookDialog` | `core/widgets/notebook/notebook_surfaces.dart` | paper 배경 + `surfaceTintColor: Colors.transparent` + 각진 ink 테두리 + `dialogTitle`. 확인/삭제/입력/선택 다이얼로그 모두 이 표면을 사용 |
| 일반 바텀시트 | `showNotebookBottomSheet` / `NotebookBottomSheet` | `core/widgets/notebook/notebook_surfaces.dart` | transparent route + paper 배경 + `BorderRadius.zero` + `BottomSheetHandle` + SafeArea |
| 커스텀/드래그 바텀시트 route | `showNotebookModalBottomSheet` | `core/widgets/notebook/notebook_surfaces.dart` | transparent route + 각진 route shape. child가 `DraggableScrollableSheet` 또는 자체 paper frame을 소유 |
| 카드 표면 | `NotebookCard` | `core/widgets/notebook/notebook_surfaces.dart` | 직접 `Card(` 금지. 각진 paper 카드 + `surfaceTintColor: Colors.transparent` |

신규 코드 금지:
- production UI에서 직접 `Scaffold(` 호출. 허용 범위는 `NotebookScreenScaffold`/`NotebookDetailScaffold` 구현 파일 내부뿐이다.
- 직접 `Card(` 호출. 반복 카드/진단 카드/선택 카드도 `NotebookCard`를 사용한다.
- 직접 `AlertDialog(` 호출. 신규/수정 코드는 `NotebookAlertDialog` 또는 `showNotebookDialog`를 사용한다.
- `showModalBottomSheet` 직접 호출. 신규/수정 코드는 `showNotebookBottomSheet` 또는 `showNotebookModalBottomSheet`를 사용한다.
- `Colors.white`/Material surface에 의존하는 popup/sheet

예외:
- 카메라, 녹음 파형, 튜너 등 실제 미디어/캔버스가 주 표면인 화면
- 이미지 크롭러 등 외부 플러그인이 자체 대비를 요구하는 표면
- `showNotebookModalBottomSheet` 내부 child가 자체 frame을 소유하는 드래그형 시트. 이 경우 child 내부 첫 표면은 반드시 `AppColors.paper`/`paperDark` 계열이어야 한다.

#### 1.2.1 Compact Work Header 예외

스케줄 탭처럼 하루에도 여러 번 확인·수정하는 반복 업무 화면은 대형
`NotebookMasthead`/Programme Title 을 강제하지 않는다. 이 경우 시그니처보다
작업 가능 높이와 조작 효율을 우선한다.

예외 조건:
- 화면의 핵심 과업이 목록/시간표를 반복 확인하고 즉시 조작하는 업무일 것
- 상단은 56~72px 수준의 compact toolbar 로 제한할 것
- toolbar 안에 화면명, 주요 보기 전환, 주요 생성 액션을 함께 배치할 것
- 날짜/필터/정렬 조작은 별도 대형 설명 블록이 아니라 sticky 또는 compact control row 로 배치할 것
- `NotebookTypography`, Vermillion accent, ink line 등 나머지 Notebook × Score 언어는 유지할 것

현재 적용 화면:
- `schedule/presentation/screens/schedule_tab.dart`: 선생님 스케줄 탭. 대형
  `SCHEDULE` eyebrow/`Programme of Schedule` 헤더 제거, `스케줄 + 보기 전환 + 추가`
  compact toolbar 와 `CompactWeekStrip + 날짜/정렬` 조작 영역으로 대체.

**점수 임계값**:

| 조건 | 판정 |
|------|------|
| 정체성 4 중 1+ 빠짐 | **BLOCK** (점수 산식 무시) |
| 정체성 4 ✓ + 구조 6/6 | **PASS** (10점) |
| 정체성 4 ✓ + 구조 5/6 | **FLAG** (8.33점) |
| 정체성 4 ✓ + 구조 ≤4/6 | **BLOCK** |

### 1.3 메타 원칙 2종

시그니처가 "이 앱이 Notebook × Score 인가" 의 정체성 측정이라면, 메타 원칙은 **인지 부하 절제**의 측정. 두 원칙은 신규 화면 추가 시 시그니처와 동등하게 강제.

#### 1.3.1 각진 (BorderRadius.zero) — §7.118 포화 (2026-05-04 확인)

`app_theme.dart` 테마 레이어 + 인라인 override 모두 `BorderRadius.zero`. 전체 코드베이스에서 `BorderRadius.circular` 잔여 **2건만** (포화 상태):

| 예외 | 파일 | 사유 |
|------|------|------|
| 튜너 고양이 캐릭터 | `tuner_cat_widgets.dart` | 곡률은 감정 표현 (캐릭터 예외) |
| 드래그 핸들 pill (`height / 2`) | `bottom_sheet_handle.dart` | "끌어올리기" 어포던스 |

> 이전 3 예외 중 "변수 표현식 기반 원형 오브젝트" 는 정리 완료. `like_stamp.dart`·`feedback_template_form_sheet.dart` 에 미세 잔류(stamp pill·indicator 2px)가 있으나 시그니처 영역 외 미미한 수준.

신규 위젯에 `BorderRadius.circular(radiusMedium)` 등 정적 상수 사용 = 위반.

#### 1.3.2 평탄화 (변별 단일성) — §7.122 도출

**같은 정보 차원의 변별은 헤더 OR 본문 둘 중 한 곳에서만**. 두 곳에서 동시에 변별하면 노이즈가 카드·텍스트 가독성을 침식.

| 적용 사례 | 헤더 변별 | 본문 변별 |
|----------|---------|---------|
| 주간 그리드 today | `CompactWeekStrip` vermillion 칩 | 본문 alpha 0.06 (보조만) |
| 일간 타임라인 휴무 | 상단 배너 `weekend_outlined` | 배경 alpha 0.5 (단색 평탄) |
| 주간 zebra (제거됨) | — | — (둘 다 변별 안 함 = 평탄) |

신규 시각 인코딩 도입 시 "변별 채널은 한 곳" 원칙으로 검토. 구체 위반 패턴: zebra 격색상, 모든 행 다른 좌측 보더 색상, 카드 배경에 채도 + 좌측 보더 + 우측 칩 동시 강조.

#### 1.3.3 채팅 히스토리 말풍선 일관성 — §7.69c

레슨요청 상세와 수강권 스케줄 조절 상세는 모두 `RequestEvent`를 시간순으로 읽는 히스토리다. 같은 도메인 사건을 다루므로 채팅 문법도 동일해야 한다.

| 레이어 | 규칙 |
|------|------|
| 이벤트 컨테이너 | 모든 사용자 이벤트는 둥근 말풍선으로 표시 |
| 정렬 | viewer 기준. 내 이벤트 오른쪽, 상대 이벤트 왼쪽 |
| 말풍선 색 | 내 이벤트 `paperAccentSoft`, 상대 이벤트 `paperDark` |
| 스케줄 데이터 | 말풍선 내부의 각진 사각형 카드로만 표시 |
| 상태 이벤트 | 수락/거절/응답대기/결정변경/취소는 별도 성공 박스가 아니라 같은 말풍선 안의 텍스트 이벤트 |

금지:
- 화면별로 말풍선 유무를 다르게 적용
- 수락 이벤트만 `paperOk` 체크 아이콘 Row로 강조
- 같은 히스토리 안에서 둥근 말풍선과 각진 말풍선 혼용
- 스케줄 후보 카드가 말풍선 밖으로 독립되어 보이는 구성

허용:
- 말풍선 내부 일정 후보/현재 일정 카드의 각진 사각형
- 결정 변경 이벤트의 이전 일정 취소선
- 상대 메시지의 아바타/발신자 라벨

---

## 2. 컬러 토큰

| 토큰 | HEX | 용도 |
|------|-----|------|
| `paper` | `#F2ECDD` | 기본 배경 (크림색 종이) |
| `paperDark` | `#E8DFC7` | 강조 영역 / 선택된 셀 |
| `ink` | `#14161C` | 본문 텍스트 |
| `inkSecondary` | `rgba(20,22,28,0.75)` | 보조 텍스트 |
| `inkTertiary` | `rgba(20,22,28,0.55)` | 캡션, 메타정보 |
| `inkQuaternary` | `rgba(20,22,28,0.25)` | 비활성 / 완료 |
| `paperPencil` | `rgba(20,22,28,0.60)` | 손글씨 본문 |
| `paperMargin` | `#A83E3A` | ~~왼쪽 여백선~~ — **제거됨 (2026-04-21)**. 토큰 자체는 레거시 호환용으로 유지. 신규 사용 금지 |
| `paperAccent` | `#9B1B12` | **Vermillion Red** — 핵심 액션 |
| `paperAccentSoft` | `rgba(155,27,18,0.12)` | 액센트 배경 |
| `paperOk` | `#3F5D2F` | 완료 (녹색 펜) |
| `paperHighlight` | `#F7D755` | 형광펜 |
| `paperTrial` | `#C4923A` | **세피아 앰버** — 체험레슨 전용 잉크 |
| `paperTrialSoft` | `rgba(196,146,58,0.12)` | 체험레슨 배경 (12% alpha) |

### 2.1 수강권 3색 잉크 체계 (만년필 잉크 메타포)

수강권 타입별로 "만년필 잉크 색"을 달리하여 종이 위에 적힌 수강 기록의 성격을 한눈에 식별한다.

| 수강권 타입 | 토큰 | HEX | 잉크 이름 | 감성 |
|------------|------|-----|----------|------|
| 체험레슨 (trial) | `paperTrial` | `#C4923A` | 세피아 앰버 | 호기심 · 첫 만남 |
| 정기권 (monthly) | `paperOk` | `#3F5D2F` | 녹색 펜 | 안정 · 꾸준 |
| 회차권 (package) | `paperAccent` | `#9B1B12` | 버밀리온 | 매회 출석 체크 |

`SubscriptionCard` 헤더 액센트 라인과 프로그레스바 색상이 이 3색에 매핑된다.

Flutter 구현: `lib/core/theme/app_colors.dart`의 Notebook 섹션.

---

## 3. 왼쪽 붉은 여백선 — 제거됨 (2026-04-21)

### 3.1 현재 상태

**왼쪽 붉은 여백선은 더 이상 렌더되지 않는다.** `PaperScaffold` 는 크림색 종이 배경만 제공한다.

### 3.2 제거 사유

| 시도 | 결과 |
|------|------|
| `left: 0, width: 3` (플러시 마진) | 기기 베젤·라운드 코너·SafeArea 에 가려 선이 거의 안 보임 |
| `left: 14, width: 3` (14px 들여쓰기) | 선은 보이나 콘텐츠 padding(16px)과 간격이 1px 로 좁아 **지저분해 보임** |

- 두 방식 모두 모바일에서 만족스러운 결과를 내지 못했다.
- 노트북 은유는 **크림색 종이 배경(`paper`)** + Playfair Display + 로마숫자 + Gaegu 손글씨 주석으로 충분히 전달 가능.
- 4대 시그니처(§1.1) 에 여백선은 포함되지 않으므로 제거해도 컨셉 훼손 없음.

### 3.3 현재 구현

```dart
PaperScaffold(
  child: SafeArea(child: child),
)

// 내부: ColoredBox(color: AppColors.paper) 만.
```

### 3.4 레거시 토큰

- `AppColors.paperMargin` (#A83E3A) — 삭제하지 않고 **유지**. 향후 다른 용도(보더 액센트 등)로 재사용 가능.
- 신규 코드에서 이 토큰을 **왼쪽 세로선 용도로 사용 금지**.

### 3.5 금지 사항

- `PaperScaffold` 를 수정하거나 래핑하여 왼쪽 세로선을 다시 그리는 행위 (이유 기록 없이)
- 다른 형태(점선·점묘·음영)로 노트 여백을 표현하려는 시도 — §1.1 4대 시그니처로 충분

---

## 4. 타이포그래피

**Phase 1부터 적용**. `google_fonts` 패키지를 사용한다.

| 역할 | Font | 용도 | Weight |
|------|------|------|--------|
| **Display** | Playfair Display | 매스트헤드, 페이지 타이틀, 로마숫자, 큰 숫자 | 700 / Italic 700 |
| Serif | Noto Serif KR | 한글 대형 제목 (선택) | 600 |
| Sans | Pretendard | 본문 (기본 유지) | 400 / 500 / 600 |
| **Hand** | Gaegu | 손글씨 주석 / 마지널리아 | 400 / 700 |
| **Mono** | IBM Plex Mono | 날짜, VOL·NO 라벨, 템포 표기 | 400 / 500 |

Flutter 구현: `lib/core/theme/notebook_typography.dart`.

### 4.1 타이포 스케일 (Notebook 전용)

`NotebookTypography` 클래스에 정의된 모든 스타일. 본문은 기존 `AppTypography` 사용.

| 스타일 | Font | Size | Weight | Extra | 용도 |
|--------|------|------|--------|-------|------|
| `masthead` | Playfair Display | 38 | 700 | letterSpacing -0.8, height 1.0 | 메인 타이틀 ("오늘의 레슨") |
| `mastheadLabel` | Playfair Display italic | 12 | 600 | letterSpacing 2 | 부제 ("Programme for Thursday") |
| `mastheadDate` | Playfair Display italic | 13 | 400 | — | 날짜·레슨수 ("4月 18日 · 다섯 편…") |
| `eyebrow` | Playfair Display | 11 | 600 | letterSpacing 5 | 매스트헤드 로고 ("LESSONAZA") |
| `metaMono` | IBM Plex Mono | 9 | 400 | letterSpacing 1 | VOL·NO·DATE |
| `roman` | Playfair Display italic | 14 | 600 | — | 로마숫자 번호 (기본) |
| `romanActive` | Playfair Display italic | 14 | 600 | color: paperAccent | 현재 진행 중 레슨 번호 |
| `pieceTitle` | Playfair Display | 16 | 600 | letterSpacing -0.2, height 1.3 | 곡명·레슨 제목 |
| `fine` | Playfair Display italic | 15 | 500 | — | 푸터 "Fine." |
| `sectionLabel` | (app 기본 sans)* | 11 | 500 | letterSpacing 1.5 | 업퍼케이스 섹션 라벨 |
| `hand` | Gaegu | 16 | 400 | height 1.5, color: paperPencil | 손글씨 본문 |
| `handEmphasis` | Gaegu | 13 | 700 | color: paperAccent | "지금", "발표회!" |
| `handOk` | Gaegu | 13 | 700 | color: paperOk | "✓ 보잉 좋음" 등 완료 메모 |
| `tempoMono` | IBM Plex Mono | 9 | 500 | letterSpacing 1 | 템포 표기 "♩ = 92" |

\* `sectionLabel`은 `fontFamily`를 명시하지 않고 앱 전역 기본 폰트(Pretendard)를 상속한다.

---

## 5. 컴포넌트 매핑 (선생님 홈화면)

기존 기능을 **제거하지 않고** Notebook 토큰으로 리스타일.

### 5.1 Phase 1 (구현 완료 — 커밋 f425ff11)

| 기존 요소 | Notebook 매핑 | 변경 범위 |
|-----------|---------------|-----------|
| `Scaffold` 배경 | `PaperScaffold` — 크림색 종이 배경 (왼쪽 여백선 제거됨, §3 참조) | 스캐폴드 래퍼 |
| `_buildHeader` "Lessonaza" | `NotebookMasthead` (상단 2px / 하단 1px 라인 + Playfair eyebrow + trailing 알림 아이콘) | 교체 |
| 타이틀 영역 (신규) | `_buildProgrammeTitle` — "Programme for {Weekday}" + "오늘의 레슨" + "M月 D日 · N 편의 수업" + thin rule | 추가 |
| `UrgentAlertZone` | 그대로 | 변경 없음 |
| `StatCardRow` | 그대로 | 변경 없음 |
| 오늘의 레슨 헤더 | `roman` 카운트 + "Today's Programme" italic + 일괄 피드백(paperAccent) | 스타일 교체 |
| `LessonCard` 리스트 | **로마숫자 인덱스(I., II., III.…)** 를 각 카드 앞에 prepend | 래퍼 추가 |
| "더보기" 버튼 | `inkQuaternary` 보더 + `ink` 텍스트 | 스타일만 |
| `LessonRequestSection` | 그대로 | 변경 없음 |
| `ScheduleChangeRequestSection` | 그대로 | 변경 없음 |
| `AssignmentSummarySection` | 그대로 | 변경 없음 |
| `_buildAnalyticsLink` | **thin rule + "Fine." (fine 스타일) + 통계 더보기 링크** | 교체 |

**원칙**: Phase 1은 스캐폴드·헤더·타이틀·리스트 래퍼·푸터만 Notebook으로 교체. 각 위젯 **내부는 변경 없음**.

### 5.2 Phase 2 (구현 완료 — 커밋 3462459b · c361592d · 89f04f94)

공통 위젯 + 홈 전용 섹션 + 대시보드 서브위젯을 Notebook × Score 토큰으로 일괄 리스타일. 기능·Provider·라우팅은 보존.

#### 5.2.A 공통 위젯 (커밋 3462459b)

| 위젯 | 변경 |
|------|------|
| `ThinRule` (신규) | 1px `inkQuaternary` 라인. 섹션 구분 공통 유틸 |
| `NotebookSectionHeader` (신규) | uppercase 라벨 + 선택 trailing + 하단 `ThinRule`. 모든 섹션 헤더 공통화 |
| `StatCard` | `paperDark` 배경 + 좌측 3px `ink` 세로선. `color` 파라미터는 보존(무시됨)하여 기존 호출부 파괴 없음 — 42 callsites 일괄 반영 |
| `EmptyStateWidget` | 32px `ink` 아이콘 + Playfair `pieceTitle` + Gaegu `hand` 서브타이틀 + `ink` OutlinedButton — 12 callsites 일괄 반영 |

#### 5.2.B 홈 공통 섹션 (커밋 c361592d)

| 위젯 | Notebook 매핑 |
|------|--------------|
| `SubscriptionBadge` | 사각 1px 보더 스탬프 · IBM Plex Mono 카운트 ("3/10", "D-5", "TRIAL", "EXP") · ink/paperAccent/inkTertiary 단색 — 8 callsites 일괄 반영 |
| `TimeContextBanner` | 좌측 3px `paperAccent` 세로선 + 투명 배경 + **Gaegu 손글씨** (`NotebookTypography.hand`) |
| `GettingStartedCard` | `NotebookSectionHeader` + **로마숫자 스텝 인덱스** (I, II, III) + Playfair `pieceTitle` 제목 · 완료 항목은 `paperOk` 체크 + 취소선 |
| `LessonRequestSection` | 투명 배경 + 상·하단 `inkQuaternary` 1px · 헤더를 `NotebookSectionHeader` 로 교체 |

#### 5.2.C 대시보드 서브위젯 (커밋 89f04f94)

| 위젯 | Notebook 매핑 |
|------|--------------|
| `LessonCard` | 투명 배경 + 좌측 3px 상태 세로선 (`ink`/`paperOk`/`inkTertiary`/`paperAccent`) + 하단 1px `inkQuaternary` · **IBM Plex Mono 13px 시간** (52px 컬럼) · Playfair `pieceTitle` 학생·악기 · sans uppercase 상태 라벨 (10px) |
| `AssignmentSummarySection` | `NotebookSectionHeader` + 4px thin linear bar (`inkQuaternary` 트랙 · `ink`/`paperAccent` 스트로크) · 완료율 < 50% 만 `paperAccent` 경고 (3색 원칙) |
| `ScheduleChangeRequestSection` | `NotebookSectionHeader` + 상·하단 `inkQuaternary` 1px · `paperDark` 아바타 · 사각 1px 보더 상태 스탬프 (fill 제거) · urgent 점은 `paperAccent` |
| `UrgentAlertZone` | 좌측 3px 세로선 (`paperAccent` urgent · `ink` 일반) + 투명 배경 · semantic error/warning/info 3색 분리 제거 (3색 원칙) |

### 5.3 Phase 3 이후 대상

| 항목 | 계획 | Phase |
|------|------|-------|
| `StaffDivider` | 오선 + 높은음자리표 기반 섹션 구분선 (CustomPainter) | Phase 3 — **완료** |
| `PencilUnderline` / `PencilBox` / `PencilCircle` | 손그림 프리미티브 3종 (CustomPainter) | Phase 3 — **완료** |
| 학생/학부모 홈 | Notebook × Score 적용 | Phase 4 — **완료** |
| 전 화면 확산 | 설정/프로필/수강권/스케줄 | Phase 5 — **완료** |
| 전 화면 scaffoldBackgroundColor 통일 | `app_theme.dart` `scaffoldBackgroundColor: AppColors.paper` 전역 적용 | Phase 7~9 — **완료** |
| BoxShadow 전수 제거 | 126+건 → 0건 (`BoxShadow` 잔재 없음) | Phase 7~9 — **완료** |
| BorderRadius.circular 포화 | 38건 → 2건 예외(tuner_cat + drag handle)만 잔류 | Phase 7~9 — **완료** |
| fontSize/EdgeInsets 토큰 통일 | `AppTypography`·`AppSpacing` 토큰으로 전수 치환 | Phase 7~9 — **완료** |

---

## 6. 핵심 컴포넌트 스펙

### 6.1 PaperScaffold

파일: `lib/core/widgets/notebook/paper_scaffold.dart`

```dart
class PaperScaffold extends StatelessWidget {
  final Widget child;

  const PaperScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.paper, child: child);
}
```

크림색 종이 배경만 제공한다. 과거에는 왼쪽 3px 붉은 여백선을 그렸으나 §3 사유로 제거했다. 파라미터/getter 없음 — 단순 `child` 만 받는다.

### 6.2 NotebookMasthead

파일: `lib/core/widgets/notebook/notebook_masthead.dart`

상단 2px 라인 + 하단 1px 라인 사이에 Playfair Display eyebrow(좌) + IBM Plex Mono 메타(우).

**파라미터**

| 이름 | 타입 | 설명 |
|------|------|------|
| `eyebrow` | `String` | 좌측 로고 라벨 (letterSpacing 5, 대문자 권장) |
| `meta` | `String` | 우측 메타 ("VOL. IV · NO. 18 · APR MMXXVI") |
| `onMetaTap` | `VoidCallback?` | 메타 탭 시 콜백 |
| `trailing` | `Widget?` | **`meta`를 대체**하여 우측에 표시할 커스텀 위젯 (예: 알림 아이콘). `trailing`이 제공되면 `meta`는 렌더되지 않는다. |

### 6.3 Roman Numeral

파일: `lib/core/theme/notebook_typography.dart`

```dart
String romanOf(int index) {
  const table = ['I','II','III','IV','V','VI',
                 'VII','VIII','IX','X','XI','XII'];
  if (index < 0) return '';                    // 음수 가드
  if (index < table.length) return table[index];
  return (index + 1).toString();               // XII 초과 시 아라비아 폴백
}
```

**규칙**
- 0-based index (index 0 → 'I')
- 0~11 → 로마자 테이블
- 12+ → 아라비아 숫자 (XIII 이상 가독성 하락 방지)
- 음수 → 빈 문자열
- 렌더: Playfair Display · italic · `FontWeight.w600` (`NotebookTypography.roman`)

### 6.4 Pencil 프리미티브 (Phase 3)

파일: `lib/core/widgets/notebook/pencil_primitives.dart`

| 위젯 | 생성자 기본값 | 용도 |
|------|---------------|------|
| `PencilUnderline` | width=80, color=paperAccent, strokeWidth=1.8 | 강조 텍스트 밑 곡선 밑줄 (roman tab, 제목 밑줄 등) |
| `PencilBox` | checked=false, size=16, borderColor=ink, checkColor=paperAccent | 과제/체크리스트 체크박스 |
| `PencilCircle` | size=18, color=paperAccent | 현재 활성/선택 항목 표시 (외곽 링 + 중앙 점) |

기하 기준은 `design-plan/hybrid/primitives.jsx` viewBox(18x18, 22x22)이며 Flutter에서는 size 스케일링 후 `CustomPainter`로 드로잉.

### 6.5 StaffDivider (Phase 3)

파일: `lib/core/widgets/notebook/staff_divider.dart`

5선 오선 + 우측 더블 바 + 좌측 높은음자리표(𝄞) + 옵션 템포 마킹을 단일 `CustomPaint`로 렌더.

```dart
const StaffDivider()                        // 기본 (height 22)
const StaffDivider(showTempo: true)         // "♩ = 92" 템포 표시
const StaffDivider(showTempo: true, tempoText: '♩ = 120')
```

- 오선: `AppColors.ink @ alpha 0.45`, strokeWidth 0.8
- 세로 종료 바: 1.4px + 0.8px (barline pair)
- 높은음자리표: 유니코드 `𝄞` (U+1D11E), fontSize 34, serif
- 템포: IBM Plex Mono 9pt · letterSpacing 1 · `AppColors.inkSecondary`

### 6.6 손글씨 마지널리아

```dart
Text(
  '10시 김서연 — 발표회 준비',
  style: NotebookTypography.hand.copyWith(color: AppColors.paperPencil),
)
```

형광펜 강조는 `backgroundColor: AppColors.paperHighlight` 인라인 span.

### 6.7 컴포넌트 카탈로그

> Notebook × Score 시그니처를 사용하는 모든 시스템 컴포넌트의 카탈로그. 신규 화면 작성 시 이 표에서 재사용 후보부터 검토.

#### 6.7.1 core/widgets/notebook/ — 시그니처 프리미티브

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `PaperScaffold` | `notebook/paper_scaffold.dart` | 크림색 종이 배경. §6.1 |
| `NotebookMasthead` | `notebook/notebook_masthead.dart` | Playfair eyebrow + IBM Plex Mono 메타. AppBar 대체. §6.2 |
| `SectionHeader` | `notebook/section_header.dart` | Playfair italic 섹션 제목 + 옵션 trailing. §7.17 정적 명사 도메인 진원지 |
| `StaffDivider` | `notebook/staff_divider.dart` | 5선 + 더블 바 + 𝄞. 섹션 구분자. §6.5 |
| `ThinRule` | `notebook/thin_rule.dart` | 1px 수평 디바이더 (ink alpha 0.3) |
| `PencilUnderline` | `notebook/pencil_primitives.dart` | 곡선 밑줄 CustomPainter. 강조용 |
| `PencilBox` | `notebook/pencil_primitives.dart` | 손그림 체크박스 |
| `PencilCircle` | `notebook/pencil_primitives.dart` | 활성/선택 표시 외곽 링 + 중앙 점 |
| `NotebookAlertDialog` | `notebook/notebook_alert_dialog.dart` | paper 배경 + 각진 ink 테두리 + `dialogTitle`. 커스텀 actions/content 허용, 표면 스타일 재정의 금지. §1.2.0 Surface Wrapper |
| `NotebookBottomSheet` | `notebook/notebook_bottom_sheet.dart` | paper 배경 + `BorderRadius.zero` + `BottomSheetHandle` + SafeArea. §1.2.0 Surface Wrapper |
| `NotebookScreenScaffold` | `notebook/notebook_screen_scaffold.dart` | `backgroundColor: AppColors.paper`. 일반 화면 공통 래퍼. §1.2.0 Surface Wrapper |
| `NotebookDetailScaffold` | `notebook/notebook_detail_scaffold.dart` | paper 배경 + `titleSpacing: 0` + `NotebookTypography.appBarTitle`. 상세 화면 래퍼. §1.2.0 Surface Wrapper |
| `NotebookCard` | `notebook/notebook_surfaces.dart` | 각진 paper 카드 + `surfaceTintColor: transparent`. 직접 `Card(` 금지. §1.2.0 Surface Wrapper |

#### 6.7.2 core/widgets/ — 도메인 중립 공통 위젯

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `StatCard` | `stat_card.dart` | 숫자 stat + 라벨 + 옵션 아이콘. primary 단색 통일 (§7.14 3색 이하 원칙) |
| `EmptyStateWidget` | `empty_state_widget.dart` | 빈 상태 아이콘 + 제목 + 설명 + CTA. NO-OP 금지 |
| `CompactWeekStrip` | `compact_week_strip.dart` | 7일 가로 스트립 (선생님 주간/일간 + 학생 레슨/연습 + 신청 5개 화면 공유) |
| `LessonProgressBar` | `lesson_progress_bar.dart` | 점선 커넥터 (`_DashedLinePainter`) + 가운데 정렬. 상세 화면 진행 표시 |
| `ChipInputField` | `chip_input_field.dart` | 태그 입력 + 칩 렌더 |
| `BottomSheetHandle` | `bottom_sheet_handle.dart` | 시트 상단 drag handle (캐릭터·각진 예외) |
| `AppDatePicker` | `app_date_picker.dart` | DatePicker 테마 wrapper. Vermillion 선택 + 2px ink 테두리 (§7.24) |
| `ChapterSummary` | `chapter_summary.dart` | 챕터 카드 요약 (제목 + 진행률 + 메타) |
| `ProfilePhotoHeader` | `profile_photo_header.dart` | 프로필 사진 + 이름 + 메타 헤더 |
| `QuickToolButton` | `quick_tool_button.dart` | 그리드 도구 진입 버튼 |

#### 6.7.3 features/home/ — 선생님 홈 섹션

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `TeacherSubscriptionSection` | `home/...subscription_section.dart` | 수강권 임박/만료 통합 배너 (§7.16 같은 행동 단일 CTA) |
| `GettingStartedCard` | `home/...getting_started_card.dart` | 첫 사용자 온보딩 카드 |
| `TimeContextBanner` | `home/...time_context_banner.dart` | 시간대 인사 + 다음 액션 CTA (10x Vision 시간대 배너) |
| `LessonCard` | `home/...lesson_card.dart` | 레슨 카드 (시간 + 학생 + 곡 + 상태). 주간/일간 그리드 공유 (§7.110) |
| `AssignmentSummarySection` | `home/...assignment_summary_section.dart` | 과제 요약 stat 카드 |
| `ScheduleChangeRequestSection` | `home/...schedule_change_request_section.dart` | 일정 변경 요청 리스트 |
| `UrgentAlertZone` | `home/...urgent_alert_zone.dart` | 긴급 알림 존 (Vermillion accent) |

#### 6.7.4 features/schedule/ — 스케줄 도메인

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `ScheduleTimelineView` | `schedule/...schedule_timeline_view.dart` | 일간 타임라인 + 휴무 시각 인코딩 (§7.121) |
| `ScheduleWeeklyGridView` | `schedule/...schedule_weekly_grid_view.dart` | 주간 그리드 + 4단 우선순위 (휴가·휴무·추가오픈·근무시간, §7.123) |
| `CurrentRequestBox` | `schedule/...current_request_box.dart` | 진행 중 요청 박스 + 하단 액션바 (`buttonHeightSmall`) |
| `RequestHistoryChat` | `schedule/...request_history_chat.dart` | 챗 형식 요청 히스토리 + 가이드 메시지 (§7.25) |
| `RequestProfileCard` | `schedule/...request_profile_card.dart` | 요청자 프로필 카드 |
| `WeeklyCalendarPicker` | `schedule/...weekly_calendar_picker.dart` | 주간 단위 날짜 픽커 |
| `AlternativeTimeGrid` | `schedule/...alternative_time_grid.dart` | 대체 시간 제안 그리드. §6.7.4.1 시각 규칙 필수 |
| `ScheduleVisualHelpers` | `schedule/...utils/schedule_visual_helpers.dart` | `weeklyColumnBackground` + `isTeacherRestDay` 순수 함수 (§7.122 단순화) |

##### 6.7.4.1 `AlternativeTimeGrid` 일정비교 그리드 시각 규칙 (2026-05-04)

레슨요청과 스케쥴변경의 일정비교 상세화면은 같은 `AlternativeTimeGrid`를 사용한다. 그리드는 “종이 위에 적은 주간 시간표” 메타포를 유지하되, 선택·비교 행동은 즉시 읽혀야 한다.

| 요소 | 규칙 | 사유 |
|---|---|---|
| 기존 레슨 셀의 학생명 | `NotebookTypography.hand` 기반 Gaegu 손글씨, `captionXSmall * 2`, `FontWeight.w700`, 셀 중앙 정렬 | 학생명은 실제 사람/레슨 맥락의 주석이므로 Notebook × Score의 손글씨 계층에 해당. 작은 시간표 안에서도 읽혀야 함 |
| 학생명 세로 정렬 | `Center` + `StrutStyle(forceStrutHeight: true)` + 필요 시 1px 이하 시각 보정 | Gaegu 폰트 메트릭은 산세리프와 달라 기계적 center만으로는 위로 떠 보일 수 있음 |
| 선택한 희망일정 라벨 | 선택 시작 셀에 `희망` 표시. 기존 레슨과 겹치더라도 선택 포커스가 우선되어 `희망`을 표시 | 사용자가 카드에서 선택한 희망일정 위치를 그리드에서 즉시 확인해야 함 |
| 희망일정 포커스 | 희망일정 카드 선택 시 해당 주로 이동하고, 그리드가 선택 시간대로 자동 스크롤. `date`가 없는 주간 반복 슬롯은 현재 표시 주의 `dayOfWeek` 날짜로 해석해 동일하게 표시 | 레슨요청/스케쥴변경 비교 모두 동일한 상호작용. 스케쥴변경 이벤트는 API/Mock에서 요일+시간만 전달되는 케이스가 있음 |
| 내부 그리드 라인 | 인접 셀이 동시에 같은 경계선을 그리지 않도록 한쪽 방향 보더만 사용. 외곽선은 1px, 내부선도 1px | `Border.all` 반복 적용 시 내부선이 2px처럼 보여 악보 오선의 얇은 선 질감과 충돌 |

금지:
- 학생명에 `captionXSmall` 그대로 사용
- 학생명을 좌상단 padding으로 배치
- 내부 셀마다 `Border.all`을 반복 적용해 이중선처럼 보이게 하는 구현
- 희망일정 선택 후 `희망` 라벨 또는 자동 스크롤 포커스가 누락되는 구현
- `PreferredTimeSlot.date == null`인 주간 슬롯을 포커스 불가 상태로 방치하는 구현

#### 6.7.5 features/practice/ + features/students/ — 학생/연습

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `LessonHeaderCard` | `students/...lesson_header_card.dart` | 상세 화면 진입 히어로 카드 (NotebookMasthead 승격, §7.72) |
| `BulkCancelScreen` | `students/...bulk_cancel_screen.dart` | 휴강 일괄 공지 (Sliver + 컴팩트 버튼 minimumSize override) |
| `BulkMessageSheet` | `students/...bulk_message_sheet.dart` | 일괄 메시지 시트 (DraggableSheet + 키보드 인셋) |

#### 6.7.5a features/subscription/ — 수강권 도메인

| 컴포넌트 | 파일 | 1-라인 스펙 |
|---|---|---|
| `SubscriptionCard` | `subscription/...subscription_card.dart` | 수강권 카드 — 3색 잉크 체계 (trial=`paperTrial`, monthly=`paperOk`, package=`paperAccent`). `compact: true` 티켓 스타일 (리스트/홈), `compact: false` 상세 카드 (프로그레스바 포함). compact 헤더 배경색 제거 (paper 배경만). `SubscriptionTicketCard` 삭제됨 — 이 위젯으로 통합. §2.1 3색 잉크 체계 참조 |

#### 6.7.6 핵심 토큰 진원지

| 토큰 그룹 | 파일 | 사용 규칙 |
|---|---|---|
| `AppColors` | `core/theme/app_colors.dart` | `paper`·`paperAccent`·`paperOk`·`paperTrial`·`paperTrialSoft`·`paperHighlight`·`ink`·`scheduleMutedBackground` 등. 하드코딩 `Color(0x...)` 금지 |
| `AppTypography` | `core/theme/app_typography.dart` | `bodyLarge`·`bodyMedium`·`titleLarge` 등. `fontSize: N` 직접 사용 금지 |
| `NotebookTypography` | `core/theme/notebook_typography.dart` | `masthead`·`pieceTitle`·`roman`·`romanActive`·`hand`·`handEmphasis`·`handOk`. Playfair/Gaegu/Roman 시그니처 진원지 |
| `AppSpacing` | `core/theme/app_spacing.dart` | `space1~8`·`buttonHeight`·`buttonHeightSmall`. `EdgeInsets.all(N)` 금지 |
| `AppStrings` | `core/strings/app_strings.dart` | UI 한글 텍스트 상수. 하드코딩 `Text('한글')` 금지 (다국어 대비) |
| `AppRoutes` | `core/router/app_routes.dart` | 라우트 경로 상수. 문자열 리터럴 금지 |

#### 6.7.7 사용 우선순위 (HARD-GATE)

신규 화면 작성 시 다음 순서로 재사용 후보 확인:

1. **§6.7.1 시그니처 프리미티브** 부터 검토 — `PaperScaffold` + `NotebookMasthead` + `SectionHeader` 가 화면 골격
2. **§6.7.2 도메인 중립 공통 위젯** — `StatCard`·`EmptyStateWidget`·`CompactWeekStrip` 등 재사용
3. **§6.7.3~5 도메인별 위젯** — 동일 도메인 위젯 재사용 (예: 스케줄 화면은 `LessonCard` 재사용)
4. **§6.7.6 토큰** — 새 색상·타이포·간격이 필요해 보이면 먼저 토큰 진원지를 확인
5. 위 4단계에서 후보가 없을 때만 신규 컴포넌트 작성

---

## 7. 적용 Phase

> **이력 분리 (Wave 2, 2026-04-27)**: §7.1~§7.123 의 phase 별 산출물 기록은 [phase-log.md](./phase-log.md) 로 이전. 본 README 는 정의·원칙 SSOT, phase-log.md 는 시점별 적용 이력 SSOT.

| Phase | 범위 | 상태 |
|-------|------|------|
| Phase 1 | 선생님 홈화면 — 토큰 + PaperScaffold + NotebookMasthead + Programme Title + 로마숫자 레슨 리스트 + Fine. 푸터 | **완료** (2026-04-21, f425ff11) |
| Phase 2 | 공통 위젯 + 홈 섹션 + 대시보드 서브위젯 | **완료** (2026-04-21) |
| Phase 3 | StaffDivider + PencilUnderline/Box/Circle CustomPainter | **완료** |
| Phase 4 | 학생 홈 — 쉘 + 대시보드 + 레슨/연습 탭 + 카드 팔레트 이식 | **완료** |
| Phase 5 | 학생 설정·프로필 + 대시보드 잔재 정리 | **완료** |
| Phase 6.A/B | 수강권/스케줄/선생님 토큰 이식 (기계 + 시맨틱) | **완료** |
| Phase 7~9 | 전 도메인 레거시 토큰 정리 + core/ 공통 위젯 + 최종 잔재 제거 | **완료** |

### 핵심 마일스톤

| 그룹 | 범위 | 상세 |
|------|------|------|
| §7.13~§7.16 | 전역 테마 통일 (BottomNav · AppBar · TabBar · Dialog · SnackBar) | [phase-log §7.13~§7.16](./phase-log.md#빠른-내비게이션) |
| **§7.17** | **섹션 헤더 Playfair "정적 명사" 법칙** — 매스트헤드→AppBar→섹션→곡명 위계 확립 | [phase-log §7.17](./phase-log.md#717-섹션-헤더-playfair-통일--매스트헤드appbar섹션곡명-위계-확립) |
| §7.18~§7.49 | 위젯별 §7.17 보급 (Switch·Icon·Popup·DatePicker·Radio·Slider·Chip·Expansion·Bottom·Filled·Icon·Dialog·FAB) + Dark 대칭 + Material 잔재 ink 치환 | [phase-log](./phase-log.md) |
| **§7.30** | **Gothic 예외** — "동적 값 집중" 도메인은 Playfair 보호 | [phase-log §7.30](./phase-log.md) |
| §7.50~§7.65 | Vermillion / paper alpha / shadow 토큰 일괄 치환 | [phase-log §7.50~§7.65](./phase-log.md) |
| §7.67~§7.78 | NotebookMasthead 탭/도메인 승격 (students_tab · schedule_tab · lesson_header_card 등) | [phase-log](./phase-log.md) |
| **§7.79~§7.86** | **자동 판정 프로토콜 정착** (3-법칙: §7.17/§7.27/§7.30) | [phase-log §7.84](./phase-log.md#784-search-선생님학원-상세-717--practicelessons-730-전수-감사--동적-값-집중-도메인-재확인) |
| §7.87~§7.101 | 학생/선생님 진입 경험 전수 감사 + 비선생님 도메인 + 소급 감사 | [phase-log](./phase-log.md) |
| **§7.102~§7.109** | **4대 시그니처 SSOT 감사 포화** (Gaegu · Roman · Vermillion · display* · marginalia) | [phase-log §7.102~§7.109](./phase-log.md#7102--11-4-gaegu-손글씨-서명-최초-전수-감사-2026-04-24) |
| **§7.110~§7.118** | **각진 원칙 (BorderRadius.zero) 확장 + 테마 레이어 포화** | [phase-log §7.118](./phase-log.md#7118--테마-레이어-전수-각진-포화-app_themedart--인라인-override-2026-04-24) |
| **§7.120~§7.123** | **평탄화 + 4단 우선순위** (주간/일간 그리드 · 휴가·휴무·추가오픈·근무시간) | [phase-log §7.122~§7.123](./phase-log.md#7122--주간-그리드-컬럼-배경-단순화-4단--2단-2026-04-27) |
| **2026-05-04** | **전 화면 scaffoldBackgroundColor 통일** — `app_theme.dart` `scaffoldBackgroundColor: AppColors.paper` 전역 적용 | — |
| **2026-05-04** | **BoxShadow 전수 제거** — 126+건 → 0건. 종이 평면 잉크 원칙 완성 | — |
| **2026-05-04** | **BorderRadius.circular 포화** — 38건 → 2건 예외(tuner_cat + drag handle)만 잔류 | §1.3.1 |
| **2026-05-04** | **fontSize/EdgeInsets 토큰 통일** — `AppTypography`·`AppSpacing` 전수 치환 | — |
| **2026-05-04** | **SubscriptionCard 통합 재설계** — `SubscriptionTicketCard` 삭제, `SubscriptionCard(compact)` 로 통합. 3색 잉크 체계 도입 (trial=`paperTrial` 세피아, monthly=`paperOk` 녹색, package=`paperAccent` 버밀리온). §2.1 참조 | — |
| **2026-05-04** | **"Fine." 종지부 상세 화면 확산** — 대시보드 3종 + 상세 화면 8개 포함 11개 화면 파일 적용 | §1.2 #6 |
| **2026-05-04** | **detail_screen_template.md Notebook 토큰 SSOT 갱신** | — |
| **2026-05-04** | **공통 래퍼 4종 도입** — NotebookAlertDialog · NotebookBottomSheet · NotebookScreenScaffold · NotebookDetailScaffold | §1.2.0, §6.7.1 |

> **참조 규칙**: 본 README 의 다른 섹션(§1.1·§8 등)에서 `§7.X` 앵커로 가리키는 모든 항목은 phase-log.md 에 보존됨. 시점별 정의(예: "당시 4대 시그니처") 도 그대로 유지.


## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **감사 시그니처 6대 필수 (§1.2)**: 정체성 4 (Playfair · 로마숫자 · Vermillion · Gaegu) + 구조 2 (NotebookMasthead · "Fine.") = 감사 점수 분모. **정체성 4 중 1 누락 = 점수 무관 BLOCK**. 구조 2 누락은 FLAG 단계.
6. **메타 원칙 2종 (§1.3)**: 모든 화면은 (a) 각진 — `BorderRadius.zero` 기본, 3 예외(캐릭터·handle·변수표현식)에만 `BorderRadius.circular` 허용, (b) 평탄화 — 변별 채널은 헤더 OR 본문 둘 중 한 곳에서만. 두 원칙은 신규 화면 추가 시 시그니처와 동등 강제. 상세: §1.3.1 / §1.3.2.
7. **각진 원칙 구현 출처 (§7.112 · §7.113 · §7.114 · §7.115 · §7.118)**: app_theme 테마 레이어 전체가 `BorderRadius.zero` (§7.118, 2026-04-24 포화). 바텀시트 상단도 각진 (10x Vision). `radiusSmall/Medium/Large/XLarge` 를 Notebook × Score 사용자 정의 컨테이너에 사용 금지. **BoxShadow 도 동반 제거** (§7.115) — 종이는 평면 잉크이지 떠있는 material 이 아님.
8. **테마 레이어 전역 적용 (2026-05-04)**: `app_theme.dart` 에서 `scaffoldBackgroundColor: AppColors.paper`, `dialogTheme`, `bottomSheetTheme`, `cardTheme` 으로 전역 통일. 개별 위젯에서 테마 오버라이드 금지 (paper 배경, zero radius, flat elevation). 표면 계약은 §1.2.0 Surface Wrapper SSOT 를 따르며, 직접 `Scaffold(backgroundColor:)` / `Card(` / `AlertDialog(` 를 호출하지 않는다.

---

## 9. 아이콘 정책 (2026-04-29 inception)

> 노트북 × 스코어 메타포는 **손맛 + 잉크 + 종이** 의 평면 매체. Material/Cupertino 픽토그램 아이콘은 "디지털 UI 시스템" 의 시각 코드라 메타포와 충돌한다. 본 정책은 **시그니처 영역에 한해** ASCII/Unicode 글리프 사용을 강제한다.

### 9.1 정책 강도 — A2 (선택적 강제)

**시그니처 영역에서만 ASCII/Unicode 글리프 강제. 일반 navigation/utility 는 Material 허용.**

| 영역 | 분류 | 정책 | 사유 |
|------|------|------|------|
| `core/widgets/notebook/` | 시그니처 프리미티브 | **ASCII 강제** | §1.2 시그니처 진원지 — 메타포 SSOT |
| `*_stamp.dart` | 도장(스탬프) | **ASCII 강제** | "잉크 도장 찍힘" 메타포 |
| `*_masthead.dart` | 매스트헤드 | **ASCII 강제** | §1.2 #5 구조 시그니처 |
| `core/widgets/empty_state_widget.dart` 및 `*empty_state*.dart` | 빈 상태 | **ASCII 강제** | 손글씨 안내문 톤 (§1.1.1 Tier 3) |
| 일반 navigation (`chevron_right`, `arrow_back`, `close`, `more_vert`, `search`) | 시스템 affordance | Material 허용 | 운영체제 컨벤션 우선 (사용성) |
| 데이터 표시 아이콘 (`calendar_today`, `schedule`, `access_time`) | 정보 인디케이터 | Material 허용 | Tier 4 산세리프 영역과 정합 |
| 대화/입력 affordance (`edit`, `camera_alt`, `delete`) | 사용자 액션 | Material 허용 | 시스템 컨벤션 |

**핵심 결정 트리** (신규 아이콘 도입 시):

```
이 아이콘이 어느 영역에 들어가는가?
  ├─ §6.7.1 시그니처 프리미티브 / 스탬프 / 매스트헤드 / 빈 상태?
  │   └─ YES → NotebookGlyph 사용 (Material Icons.* 금지)
  │
  └─ NO (일반 화면 navigation/utility/데이터)
      ├─ 시스템 affordance 인가? (chevron_right, arrow_back, close 등)
      │   └─ YES → Material Icons.* 유지 (사용성 ↑)
      └─ 손맛 표현이 필요한가? (음악 노트, 별, 좋아요 등)
          └─ YES → NotebookGlyph 사용 권장
```

### 9.2 NotebookGlyph 위젯

**파일**: `frontend/lib/core/widgets/notebook/notebook_glyph.dart`

```dart
NotebookGlyph(
  NotebookGlyph.trebleClef,
  size: 32,
  color: AppColors.paperAccent,
)
```

**파라미터**:

| 이름 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `glyph` (positional) | `String` | — | 글리프 문자. `NotebookGlyph.<name>` 상수 권장 |
| `size` | `double` | `16` | fontSize |
| `color` | `Color?` | `AppColors.ink` | 글리프 색상 |
| `fontFamily` | `String?` | null (serif fallback) | 폰트 패밀리 |
| `semanticLabel` | `String?` | null (글리프 자체) | 스크린리더 라벨 |

### 9.3 매핑표 — Material → NotebookGlyph

상위 30+ Material 아이콘 ASCII/Unicode 대체. **시그니처 영역에서만 강제**.

| 카테고리 | Material | NotebookGlyph | 글리프 |
|----------|----------|---------------|--------|
| **음악** | `music_note` | `note` | `♩` |
| | (8분음표) | `eighthNote` | `♪` |
| | — | `beamedNotes` | `♫` |
| | — | `sixteenthNotes` | `♬` |
| | (높은음자리표) | `trebleClef` | `𝄞` |
| | (낮은음자리표) | `bassClef` | `𝄢` |
| **체크** | `check` / `check_circle` | `check` | `✓` |
| | `cancel` / `error` | `cross` | `✗` |
| | `close` (시그니처 영역만) | `close` | `✕` |
| **화살표** | `arrow_forward` | `arrowRight` | `→` |
| | `arrow_back` (시그니처) | `arrowLeft` | `←` |
| | `arrow_upward` | `arrowUp` | `↑` |
| | `arrow_downward` | `arrowDown` | `↓` |
| | `chevron_right` (시그니처) | `chevronRight` | `›` |
| | `chevron_left` (시그니처) | `chevronLeft` | `‹` |
| | (강조 진행) | `doubleChevronRight` | `»` |
| **별** | `star` | `starFilled` | `★` |
| | `star_border` | `starOutline` | `☆` |
| **좋아요** | `favorite` / `thumb_up_alt` | `heartFilled` | `♥` |
| | `favorite_border` / `thumb_up_alt_outlined` | `heartOutline` | `♡` |
| **점·마커** | (불릿) | `bullet` | `•` |
| | (메타 구분자) | `middleDot` | `·` |
| | `radio_button_checked` | `dotFilled` | `●` |
| | `radio_button_unchecked` | `dotOutline` | `○` |
| **부호** | `add` (시그니처) | `plus` | `+` |
| | `remove` (시그니처) | `minus` | `−` |
| **편집** | `edit` (시그니처) | `pencil` | `✎` |
| | `lightbulb_outline` | `sparkle` | `✦` |
| **텍스트** | (스펙 인용) | `section` | `§` |
| | (단락) | `paragraph` | `¶` |
| | (참고) | `referenceMark` | `※` |

> **주의 — 일반 영역에서는 Material 유지**: 위 표의 navigation/utility 매핑(`close`, `chevron_right`, `arrow_back`, `add`, `edit` 등)은 시그니처 영역에서만 강제다. 일반 화면에서는 사용성·접근성 표준 영향으로 Material 유지.

### 9.4 시그니처 영역 정의 (강제 대상)

다음 경로 패턴의 파일에서만 §9 정책이 강제된다:

| 패턴 | 예시 |
|------|------|
| `core/widgets/notebook/**.dart` | `like_stamp.dart`, `notebook_masthead.dart`, `paper_scaffold.dart`, `staff_divider.dart`, `pencil_primitives.dart`, `thin_rule.dart`, `section_header.dart` |
| `core/widgets/empty_state_widget.dart` | 공통 빈 상태 |
| `**/widgets/*_stamp.dart` | 도메인별 도장 |
| `**/widgets/*_masthead.dart` | 도메인별 매스트헤드 |
| `**/widgets/*empty_state*.dart` | 도메인별 빈 상태 |

### 9.5 예외 처리

다음 3 종류는 정책 적용 제외:

| 예외 | 사유 |
|------|------|
| `notebook_glyph.dart` 자체 | 정책 구현체 |
| 폰트 fallback 미지원 글리프 | SMP plane (𝄞 U+1D11E) 등은 폰트 검증 후 제한적 사용 |
| 의도적 Material 사용 (시그니처 영역) | `// ignore: notebook-icon` 주석 + 사유 기록 |

**옵트아웃 예시**:

```dart
// ignore: notebook-icon — Material thumb_up 이 손맛 ♥ 보다 인지도 ↑
const Icon(Icons.thumb_up_alt, size: 14)
```

### 9.6 검증

| 시점 | 도구 | 동작 |
|------|------|------|
| 코드 편집 시 | `.claude/hooks/check-notebook-icon.sh` | 시그니처 영역 `Icons.*` 감지 → stderr 경고 (exit 0, 차단 X) |
| 수동 grep | `grep -rn "Icons\." frontend/lib/core/widgets/notebook/` | 시그니처 영역 잔재 확인 |
| 테스트 | `frontend/test/core/widgets/notebook/notebook_glyph_test.dart` | 위젯 smoke + 30개 글리프 검증 |

### 9.7 마이그레이션 로드맵

| Phase | 범위 | 상태 |
|-------|------|------|
| **Phase 1** (2026-04-29) | §9 정책 + NotebookGlyph 위젯 + smoke test + 훅 + 규칙 | **완료** |
| **Phase 2** (2026-04-29) | Pilot — `like_stamp.dart` 2건 NotebookGlyph 치환 (♥/♡) + 21/21 PASS | **완료** |
| **Phase 3** (2026-04-29) | 시그니처 영역 5 패턴 전수 감사 — 마이그레이션 대상 0건 확정, 게이트 활성 | **완료** |
| **Phase 4** (2026-04-29) | 결정 게이트 2 — 훅 패턴 일괄 확장 지양, cherry-pick 전략 채택. `getting_started_card.dart` 1건(`Icons.check` → `NotebookGlyph.check`) 치환 | **완료** |
| **최종** | 시그니처 영역 `Icons.*` 잔재 0건 | **달성** (§9.4 5 패턴 모두) |
| 결정 게이트 1 | 일반 영역 emoji (시그니처 외부 30+ 건) | 대기 (사용자 결정) |

### 9.8 금지

- 시그니처 영역에 신규 `Icons.*` 도입 (사유 없는 도입)
- 일반 영역의 모든 `Icons.*` 강제 치환 (A2 정책 위반 — 시스템 affordance 컨벤션 침해)
- NotebookGlyph 매핑 상수에 emoji 추가 (예: 🎵, 🎶) — emoji 는 OS 별 색상 렌더, 노트북 평면 잉크 메타포 위반
