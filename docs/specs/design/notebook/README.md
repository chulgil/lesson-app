# Notebook × Score Design System

> Last updated: 2026-04-21
> 컨셉: **괘선 종이의 아날로그 손맛 + 클래식 악보의 엄격한 타이포그래피**
> 상태: 선생님 홈화면 Phase 1 + Phase 2 완료 (공통 위젯 + 홈 섹션 + 대시보드 서브위젯 리스타일)
> 레퍼런스: `design-plan/hybrid/`

---

## 1. 컨셉 정의

**Notebook × Score**는 다음 두 세계의 하이브리드다.

| 레이어 | 영감 | 표현 |
|--------|------|------|
| Notebook | 수업용 노트 / 연습일지 | 크림색 종이, 붉은 왼쪽 여백선, 손글씨 주석 |
| Score | 클래식 악보 (17~19C) | Playfair Display serif, 로마숫자 악장 번호, 오선/Fine, 버밀리온 액센트 |

### 1.1 4대 시그니처

이 컨셉을 식별하게 하는 **4가지 필수 요소**. 하나라도 빠지면 Notebook × Score가 아니다.

| # | 시그니처 | 규칙 |
|---|---------|------|
| 1 | **Playfair Display serif** | 타이틀·매스트헤드·주요 숫자. `FontWeight.w700` + italic 변형 |
| 2 | **로마숫자 (I, II, III, IV…)** | 레슨 번호, 섹션 번호, 탭 아이템 인덱스 |
| 3 | **Vermillion Red (#9B1B12)** | 강조 액션·현재 진행·하이라이트. 왼쪽 여백선은 #A83E3A (번진 잉크톤) |
| 4 | **Gaegu 손글씨 주석** | 사용자/시스템 메모, "지금", "발표회!", 마지널리아 |

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
| 학생/학부모 홈 | Notebook × Score 적용 | Phase 4 — 완료 |
| 전 화면 확산 | 설정/프로필/수강권/스케줄 | Phase 5 — 완료 |

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

---

## 7. 적용 Phase

| Phase | 범위 | 상태 |
|-------|------|------|
| Phase 1 | 선생님 홈화면 — 토큰 + PaperScaffold + NotebookMasthead + Programme Title + 로마숫자 레슨 리스트 + Fine. 푸터 | **완료** (2026-04-21, f425ff11) |
| Phase 2 | 공통 위젯 (StatCard/EmptyStateWidget/ThinRule/SectionHeader) + 홈 섹션 (SubscriptionBadge/TimeContextBanner/GettingStartedCard/LessonRequestSection) + 대시보드 서브위젯 (LessonCard/AssignmentSummarySection/ScheduleChangeRequestSection/UrgentAlertZone) | **완료** (2026-04-21, 3462459b + c361592d + 89f04f94) |
| Phase 3 | StaffDivider + PencilUnderline/Box/Circle CustomPainter | **완료** (pencil_primitives.dart + staff_divider.dart 신설, login_screen 내 사적 복제 제거) |
| Phase 4 | 학생 홈 — 쉘(로마숫자 네비) + 대시보드 위젯 + 레슨/연습 탭 + 카드(학생/체험) 팔레트 이식 | **완료** (a4b8f54f + 4094f677 + 199c491f + 6cc52ca0) |
| Phase 5 | 학생 설정·프로필 화면 확산 + 대시보드 잔재 정리 (student_home 전역 레거시 팔레트 0건 달성) | **완료** (b365c8b5 + da93a738 + e2d97784 + 24c359dd + a00dd961 + 310d3435 + cd867abc) |
| Phase 6 | 수강권/스케줄/선생님 영역 전 화면 확산 | **완료** (6.A 기계적 토큰 + 6.B 시맨틱 토큰 이식. 328파일, 2,213줄) |
| Phase 7 | 나머지 전 도메인 레거시 토큰 이름 정리 (practice/lessons/profile/parent_home/auth/onboarding/settings/search/gamification/analytics/follow/invite/notifications) | **완료** (7.A 기계적 + 7.B 시맨틱 + 7.C primary·*Light. 476파일, 2,690줄) |
| Phase 8 | `core/` 공통 위젯/유틸 레거시 토큰 정리 (booking, models, utils, widgets, selectors) | **완료** (a471c19f + dd651c0e. 25파일, 344줄) |
| Phase 9 | 레거시 토큰 선언 제거 + features 잔재 일괄 정리 + `app_colors.dart` 정리 | **완료** (c062e038. 60파일, 주요 23개 레거시 토큰 선언 제거) |

### 7.1 Phase 1 실제 산출물

| 유형 | 경로 |
|------|------|
| 토큰 | `frontend/lib/core/theme/app_colors.dart` (Notebook 섹션 12종) |
| 타이포 | `frontend/lib/core/theme/notebook_typography.dart` (14 스타일 + `romanOf`) |
| 스캐폴드 | `frontend/lib/core/widgets/notebook/paper_scaffold.dart` |
| 매스트헤드 | `frontend/lib/core/widgets/notebook/notebook_masthead.dart` |
| 적용 화면 | `frontend/lib/features/home/presentation/widgets/dashboard_tab.dart` |
| 의존성 | `google_fonts: ^8.0.2` (pubspec.yaml) |

### 7.2 검증 결과

| 항목 | 결과 |
|------|------|
| `flutter analyze` | 0 issues |
| `flutter test` | 392/392 passed |
| 기능 보존 | 기존 10개 위젯 모두 유지 — 제거/대체 없음 |

#### 4대 시그니처 렌더 상태 (Phase 2 종료 시점)

| 시그니처 | 상태 | 렌더 위치 |
|----------|------|-----------|
| Playfair Display | **렌더** | Masthead eyebrow · Programme Title · mastheadDate · 로마숫자 · "Fine." · LessonCard 학생·악기 · GettingStartedCard 스텝 · EmptyStateWidget 타이틀 |
| 로마숫자 | **렌더** | "오늘의 레슨" 헤더 카운트 · 레슨 카드 앞 인덱스 · **GettingStartedCard 스텝 인덱스 (I, II, III)** |
| Vermillion Red | **렌더** | `paperAccent` 액센트 — UrgentAlertZone urgent 세로선 · TimeContextBanner 세로선 · SubscriptionBadge 만료임박 · AssignmentSummary 50% 미만 경고 |
| Gaegu 손글씨 | **렌더** | `NotebookTypography.hand` — **TimeContextBanner 메시지** · EmptyStateWidget 서브타이틀 |

> **평가**: Phase 2 종료 시점에 4대 시그니처 모두 실제 관찰 가능. §8의 "4대 시그니처 필수" 원칙(5번)은 **선생님 홈화면 내에서 충족**. Phase 4 에서 학생 홈으로 확산 중.

### 7.3 Phase 4 진행 산출물 (커밋 a4b8f54f + 4094f677 + 199c491f + 6cc52ca0)

| 영역 | 경로 | 상태 |
|------|------|------|
| 쉘 | `student_home_screen.dart` | 하단 네비를 로마숫자 (I/II/III/IV) + paperAccent active 로 교체 |
| 대시보드 탭 | `student_dashboard_tab.dart` · `student_lessons_tab.dart` · `student_practice_tab.dart` | legacy → Notebook 팔레트 |
| 대시보드 위젯 | `dashboard/next_lesson_card.dart` · `dashboard/practice_summary_section.dart` · `dashboard/subscription_renewal_banner.dart` · `dashboard/teacher_feedback_section.dart` | legacy → Notebook 팔레트 |
| 카드 | `student_lesson_card.dart` · `trial_booking_card.dart` · `compact_trial_booking_card.dart` · `weekly_practice_widget.dart` · `student_subscription_summary.dart` | legacy → Notebook 팔레트 · boxShadow 제거 |
| 시작 가이드 | `student_getting_started_card.dart` | gradient → paperDark, primary → ink/paperOk, 로마숫자 스텝 유지 |
| 체험/예약 | `trial_bookings_section.dart` | surfaceSecondaryLight → paperDark |
| 설정 시트 | `language_select_sheet.dart` · `practice_reminder_sheet.dart` | primary → paperAccent, surfaceLight → paper |
| 엔티티 | `domain/entities/manual_teacher.dart` | 프로필 색상 팔레트 ink/paperAccent/paperOk/paperHighlight 로 재정의 |
| 보류 | `student_profile_*.dart` | Phase 5 후반부 (프로필 편집·탭) 대상 |

### 7.4 Phase 5 산출물 (student_home 전역 정리)

| 영역 | 경로 | 커밋 |
|------|------|------|
| 설정 스크린 3종 | `my_teachers_screen.dart` · `notification_settings_screen.dart` · `app_info_screen.dart` | b365c8b5 |
| 도움말 + 수동 선생님 추가 | `help_screen.dart` · `add_manual_teacher_screen.dart` | da93a738 |
| 약관/정책 | `legal_document_screen.dart` | e2d97784 |
| 주간 연습 | `weekly_practice_widget.dart` | 24c359dd |
| 카드 위젯 4종 | `compact_trial_booking_card` · `trial_booking_card` · `student_subscription_summary` · `student_lesson_card` | a00dd961 |
| 프로필 탭/편집 | `student_profile_tab.dart` · `student_profile_edit_screen.dart` | 310d3435 |
| 대시보드 + 탭 잔재 | `dashboard/*.dart` · `student_lessons_tab.dart` · `student_practice_tab.dart` | cd867abc |

**검증**: `grep -rE "surfaceLight\|backgroundLight\|primaryLight\|secondaryLight\|successLight\|warningLight\|errorLight\|infoLight\|textSecondaryLight\|textTertiaryLight\|textPrimaryLight\|borderLight\|surfaceSecondaryLight\|practiceGood\|practicePoor" features/student_home` → 0건. `flutter analyze` → 0 issues.

### 7.5 Phase 6.A 산출물 (수강권/스케줄/선생님 기계적 토큰 이식)

**전략**: 시맨틱 동등한 9개 "safe" 토큰을 `perl -i -pe` 로 도메인 전역 sed 치환. 공통 수정 → 일괄 반영.

| 도메인 | 파일 수 | 커밋 |
|--------|---------|------|
| `features/subscription/` | 42개 | 50344636 |
| `features/schedule/` | 60개 | 76b5d196 |
| `features/students/` | 26개 | 76b5d196 |
| **합계** | **128개** | **1,175줄 치환** |

**치환 매핑** (semantically equivalent, visually neutral):

| 레거시 | Notebook |
|--------|---------|
| `surfaceLight` | `paper` |
| `backgroundLight` | `paperDark` |
| `surfaceSecondaryLight` | `paperDark` |
| `textPrimaryLight` | `ink` |
| `textSecondaryLight` | `inkSecondary` |
| `textTertiaryLight` | `inkTertiary` |
| `borderLight` | `inkQuaternary` |
| `practiceGood` | `paperOk` |
| `practicePoor` | `paperAccent` |

**검증**: 9개 토큰 Phase 6 3개 도메인 grep → 0건. `flutter analyze` → 0 issues.

**보류 (Phase 6.B 대상, 918 refs)**:
- `AppColors.primary/success/warning/error/info` 직접 사용 (시맨틱 검토 필요 — 예: primary가 purple accent로 쓰이는지 브랜드 컬러로 쓰이는지 per-file 판단)
- `*Light` 의미 변형 토큰 (`primaryLight`/`successLight` 등 — 18개 refs)
- `Color(0x...)` 하드코딩 — `ux-rules.md` HARD-GATE 위반 사례

### 7.6 Phase 6.B 산출물 (수강권/스케줄/선생님 시맨틱 토큰 이식)

**전략**: 공통 유틸 먼저 수정 → semantic 토큰은 3색 원칙으로 병합(warning+error) → sed 일괄 치환.

| 단계 | 내용 | 파일 수 | 커밋 |
|------|------|---------|------|
| (1) 공통 유틸 | `SubscriptionStatusColors` 상태색 매핑 Notebook 이식 | 1 (위젯 40+에 cascading) | a2e410da |
| (2) semantic 단독 | `success/warning/error/info` → `paperOk/paperAccent/paperAccent/ink` | 81 | 084faa24 |
| (3) *Light/Border | `*Light` 틴트/`*Border` → `paperDark/paperAccentSoft/paperOk/inkQuaternary` | 6 | d2c8fb87 |
| (4) primary 계열 | `primary/primaryLight/primaryDark` → `paperAccent/paperAccentSoft/paperAccent` | 113 | 754e49fa |
| **합계** | — | **200** | **1,038줄 치환** |

**시맨틱 매핑** (3색 원칙 + Notebook 팔레트):

| 레거시 | Notebook | 근거 |
|--------|---------|------|
| `success` | `paperOk` | 녹색 펜 (완료/건강) |
| `warning` | `paperAccent` | 3색 원칙: warning+error 병합 |
| `error` | `paperAccent` | Vermillion Red = 주의/취소 |
| `info` | `ink` | neutral 본문색 |
| `primary` | `paperAccent` | CTA (버튼/아이콘/진행바) |
| `primaryLight` | `paperAccentSoft` | 12% alpha vermillion 배경 |
| `primaryDark` | `paperAccent` | Notebook에는 dark 변형 없음 |
| `successLight` | `paperDark` | cream accent 배경 |
| `infoLight` | `paperDark` | cream accent 배경 |
| `warningLight` | `paperAccentSoft` | soft action 배경 |
| `errorLight` | `paperAccentSoft` | soft action 배경 |
| `successBorder` | `paperOk` | 녹색 펜 테두리 |
| `infoBorder` | `inkQuaternary` | neutral 테두리 |

**검증**: 14개 토큰 Phase 6 3개 도메인 grep → 0건. `flutter analyze` → 0 issues.

**Phase 6 총계 (6.A + 6.B)**: 328개 파일 작업, 2,213줄 치환. 3개 도메인(subscription/schedule/students) semantic/mechanical 레거시 토큰 완전 소거.

**보류 (Phase 7 대상)**:
- subscription/schedule/students 외 모든 도메인 (analytics, search, notifications, gamification, parent_home, follow, practice, auth 등)
- `app_colors.dart` 레거시 선언 자체는 아직 유지 (호환성)
- `Color(0x...)` 하드코딩 잔존 검토

### 7.7 Phase 7 산출물 (나머지 전 도메인 레거시 토큰 이름 정리)

**전략**: Phase 6에서 검증된 3단계 sed 치환을 features/ 전체에 확장. Phase 6 도메인은 이미 0건이라 영향 없음.

| 단계 | 대상 토큰 | 매핑 | 커밋 | 파일 | 줄 |
|------|-----------|------|------|------|----|
| 7.A | mechanical 9개 (surfaceLight/backgroundLight/surfaceSecondaryLight/textPrimary/Secondary/TertiaryLight/borderLight/practiceGood/Poor) | Phase 6.A 매핑 동일 | 1f510fa5 | 182 | 1,353 |
| 7.B | semantic 4개 (success/warning/error/info) | paperOk / paperAccent (×2, 3색 원칙) / ink | 3fc954e1 | 134 | 615 |
| 7.C | primary 계열 + *Light/*Border | paperAccent / paperAccentSoft / paperDark / paperOk / inkQuaternary | b6d068c3 | 160 | 722 |
| **합계** | — | — | — | **476** | **2,690** |

**검증**: 20개 레거시 토큰 features/ 전체 grep → 0건. `flutter analyze` → 0 issues 모든 단계.

**Phase 6 + 7 총계**: 804개 파일 작업, 4,903줄 치환. `frontend/lib/features/` 전체에서 레거시 토큰 *이름* 사용 0건 달성.

**보류 (향후 작업)**:
- `app_colors.dart`의 레거시 토큰 *선언* 자체 제거 (외부 세션 0da805ae가 값을 Notebook hex로 재매핑해둔 상태 — 선언만 남겨둔다고 기능 영향 없음)
- `Color(0x...)` 하드코딩 잔존 (ux-rules HARD-GATE 위반) 검토
- `features/` 외 `core/` 위젯들의 레거시 토큰 사용 검토

### 7.8 Phase 8 산출물 (core/ 공통 위젯 레거시 토큰 정리)

**범위**: `frontend/lib/core/` 의 공통 유틸/위젯/엔티티. Phase 6/7 매핑(22종)을 동일 적용.

| 커밋 | 파일 | 줄 |
|------|------|----|
| a471c19f | 20 | 152 |

**치환된 파일**: booking/entities/lesson_booking, models/shared_enums, utils/image_utils + snackbar_utils, widgets/chapter_summary + profile_photo_header + week_calendar_widget + bottom_sheet_handle + quick_tool_button + lesson_progress_bar + practice_center_button + chip_input_field + debug_role_switcher + compact_week_strip + profile_image_widget, widgets/selectors/* (5개).

**검증**: 22개 레거시 토큰 `core/` grep → 3건 잔존 (`recording_diagnostic_screen.dart`, 외부 세션 편집 중이라 다음 턴 처리). `flutter analyze` → 0 issues.

**Phase 6+7+8 총계**: 824개 파일 작업, 5,055줄 치환. `frontend/lib/features/` + `frontend/lib/core/` (외부 편집 3파일 제외) 레거시 토큰 이름 사용 **0건** 달성.

### 7.9 Phase 9 산출물 (레거시 선언 제거 + 최종 잔재 정리)

**범위**: Phase 6~8까지는 호출부 이름만 치환. Phase 9에서는 `app_colors.dart` 자체의 legacy 선언을 제거하고, 외부 세션 편집 완료된 3파일과 마지막 `secondary` 잔재까지 정리.

| 커밋 | 파일 | 줄 | 내용 |
|------|------|----|------|
| dd651c0e | 5 | 409 | `app_theme.dart` + `app_date_picker.dart` + `debug_role_switcher.dart` + `recording_diagnostic_screen.dart` + `discount_percent_selector.dart` 레거시 토큰 이식 |
| c062e038 | 60 | 166 | features/ 잔재 (`primary`/`secondary`/`success`/`warning`/`error`/`info` 계열) 최종 정리 + `lesson_booking.dart` `unavailable` → `paperAccent` + `app_colors.dart` 미사용 선언 제거 |

**`app_colors.dart`에서 제거된 23개 선언**:
- `primary`, `primaryLight`, `primaryDark`
- `secondary`, `secondaryLight`
- `success`, `successDark`, `successLight`, `successBorder`
- `warning`, `warningLight`
- `error`, `errorLight`
- `info`, `infoLight`, `infoBorder`
- `practiceGood`, `practicePoor`
- `backgroundLight`, `surfaceLight`, `surfaceSecondaryLight`, `borderLight`
- `textPrimaryLight`, `textSecondaryLight`, `textTertiaryLight`

**존속 토큰 (Light/Dark 분리 유지용)**: `textDisabledLight`, `practiceNormal`, `practicePaused`, Dark 모드 전 토큰.

**검증**: 
- `grep "AppColors\.(primary|secondary|success|warning|error|info|practiceGood|practicePoor|...Light)\\b"` → 0건
- `flutter analyze` → 0 issues
- `app_colors.dart` Notebook 섹션 12개 토큰 + 제품 고유 토큰(profile/streak/tuner/bubble/schedule/level 등)만 잔존

**Phase 6+7+8+9 총계**: 889파일, 5,630줄. `AppColors` 레거시 시맨틱 토큰 이름 **사용·선언 모두 0건** 달성. Notebook × Score 팔레트 이식 구조적으로 완료.

### 7.10 Phase 3 산출물 (CustomPainter 프리미티브)

**범위**: Phase 3 최초 계획의 `StaffDivider` + 후속 확장된 pencil 프리미티브 3종을 `core/widgets/notebook/`에 정식 위젯으로 신설. `design-plan/hybrid/primitives.jsx` JSX 레퍼런스를 Dart `CustomPainter`로 포트.

| 파일 | 공개 위젯 | 기하 레퍼런스 |
|------|-----------|---------------|
| `pencil_primitives.dart` | `PencilUnderline`, `PencilBox`, `PencilCircle` | JSX viewBox(18×18, 22×22) → Size 스케일 |
| `staff_divider.dart` | `StaffDivider` | JSX 5라인 y=[0,4,8,12,16] + top 3 |

**정리 사항**:
- `login_screen.dart` 내 사적 복제 `_PencilUnderline` + `_PencilUnderlinePainter` 제거 후 공용 위젯으로 교체.
- `PencilBox` / `PencilCircle` / `StaffDivider` 는 위젯 신설만. 향후 Phase에서 체크리스트/과제/활성 표시/섹션 구분에 단계적 도입.

**검증**:
- `flutter analyze` → 0 issues
- 스펙(§6.4 Pencil 프리미티브, §6.5 StaffDivider) 갱신

### 7.11 Phase 3 후속 실적용 (StaffDivider + PencilCircle + PencilBox 도입)

**범위**: Phase 3에서 신설한 공용 위젯을 실제 화면 8곳에 적용. "추가만 하고 쓰이지 않는 위젯" 잔여물 제거 + 연습 체크박스 일관성 확보.

| 위젯 | 적용 파일 | 변경 | 커밋 |
|------|-----------|------|------|
| `StaffDivider` | `features/lessons/presentation/screens/lesson_detail_screen.dart` | 피드백/포인트/연습 팁 3개 섹션 경계에 삽입 (2곳) | 9bf29b02 |
| `StaffDivider` | `features/practice/presentation/widgets/month_group_header.dart` | 월 그룹 헤더 상단에 배치 — "새 월 = 새 악장" 은유. 기존 Row 우측 1px Expanded 라인 제거 | 3b4b6d60 |
| `PencilCircle` | `features/parent_home/presentation/widgets/profile_switcher.dart` | 선택된 프로필 표시를 `Icons.check_circle` 에서 `PencilCircle(size: 20)` 로 교체 | 3b4b6d60 |
| `PencilCircle` | `features/practice/presentation/widgets/goal/goal_setting_chips.dart` | `ChoiceChip.avatar` 슬롯에 `PencilCircle(size: 16)`. `showCheckmark: false` 로 Material 체크마크 대체 | 795b5c18 |
| `PencilBox` | `features/auth/presentation/screens/terms_agreement_screen.dart` | Material `Checkbox` 2곳(전체 동의 20px · 개별 약관 18px) → `PencilBox`. 외부 `InkWell` 이 탭 처리 | ae35f194 |
| `PencilBox` | `features/lessons/presentation/widgets/practice_items_section.dart` | 연습 완료 표시 원형 컨테이너+Icon → `PencilBox(size: 20, checkColor: paperOk)`. 녹색 펜 느낌 유지, 원형 → 사각 체크로 변경 | ae35f194 |
| `PencilBox` | `features/practice/presentation/screens/practice_repertoire_screen.dart` | 섹션 완료 `Transform.scale + Checkbox(activeColor: paperOk)` → `GestureDetector + PencilBox(size: 22, checkColor: paperOk)` | 13b366d8 |
| `PencilBox` | `features/student_home/presentation/screens/student_practice_tab.dart` | 오늘(탭 가능) `Checkbox` + 과거/미래(읽기 전용) `Icons.check_circle/radio_button_unchecked` 혼재 → `PencilBox(size: 22, checkColor: paperOk)` 로 통일. 과거/미래는 `borderColor: inkSecondary` | 13b366d8 |

**검증**:
- `flutter analyze` → 0 issues (8곳 모두)
- `flutter test` → 392/392 passed
- 기능·Provider·라우팅 변경 없음 (style-only)

**은유 요약**:
- StaffDivider: 섹션 구분 = 악보의 새 악장
- PencilCircle: 선택 상태 = 연필로 그은 동그라미
- PencilBox: 완료 체크 = 손으로 그린 사각 체크박스 (paperOk = 녹색 펜)

### 7.12 Gaegu 손글씨 확장 — 선생님 피드백 + 연습 팁 + 학생 메모

**배경**: 4대 시그니처 중 Gaegu 사용처가 실제 렌더 기준 4곳(TimeContextBanner, EmptyStateWidget, GettingStartedCard, login_screen) 에 머물러 가장 약했음. 학생이 매일 보는 "선생님 피드백 / 연습 팁 / 메모" 는 "손글씨 주석" 은유와 가장 자연스럽게 부합하는 지점.

| 위젯 | 적용 파일 | 변경 | 커밋 |
|------|-----------|------|------|
| Gaegu 본문 | `features/student_home/presentation/widgets/dashboard/teacher_feedback_section.dart` | 대시보드 피드백 본문을 `AppTypography.bodyMedium` → `NotebookTypography.hand` + `paperPencil` | 5573fb4b |
| Gaegu 프리뷰 | `features/student_home/presentation/widgets/student_lesson_card.dart` | 레슨 리스트 피드백 2줄 프리뷰를 `AppTypography.bodySmall` → `NotebookTypography.hand.copyWith(fontSize: 13, height: 1.3)` | 5573fb4b |
| Gaegu 프리뷰 | `features/lessons/presentation/screens/lesson_note_history_screen.dart` | 노트 이력 카드 3종(피드백 3줄 / 연습 팁 1줄 / 학생 메모 2줄) → `NotebookTypography.hand`(프리뷰는 fontSize 13 / height 1.3) | 4eae2269 |
| Gaegu 본문 | `features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart` | `_PracticeTipsCard` 본문 `AppTypography.bodyMedium(color: ink)` → `NotebookTypography.hand(color: ink)`. 배경(ink α 0.1) 대비 유지 | 4eae2269 |
| Gaegu 프리뷰 | `features/students/presentation/widgets/student_detail/student_notes_section.dart` | 학생 상세 노트 프리뷰 피드백 2줄 `AppTypography.bodySmall` → `NotebookTypography.hand.copyWith(fontSize: 13, height: 1.3, paperPencil)` | b107379c |
| Gaegu 프리뷰 | `features/students/presentation/widgets/student_detail/student_lesson_card.dart` | 학생 상세 레슨 카드 피드백 1줄 프리뷰 `AppTypography.caption(inkTertiary)` → `NotebookTypography.hand.copyWith(fontSize: 13, height: 1.3, paperPencil)` | b107379c |
| Gaegu 본문 | `features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart` | `TeacherFeedbackCard` 정본 피드백 카드 본문 `AppTypography.bodyMedium(height: 1.6)` → `NotebookTypography.hand` (Gaegu 16 · paperPencil · height 1.5). 프리뷰↔본문 시각 위계 복원 | 1d26026b |

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed
- 기능·Provider 변경 없음 (렌더 스타일만)

**은유**: 선생님이 레슨 노트 여백에 손으로 적어준 코멘트·팁·메모 = Gaegu 손글씨.

### 7.13 바텀 네비 통일 — 로마숫자 + Vermillion 전 역할 확대

**배경**: 학생 홈(`student_home_screen.dart`) 만 4대 시그니처 중 "로마숫자 + Vermillion active" 를 바텀 네비에 적용. 선생님/학부모 홈은 Material `BottomNavigationBar` + outlined 아이콘 유지 → 역할 진입 경로에서 컨셉 이탈.

| 역할 | 파일 | 변경 | 커밋 |
|------|------|------|------|
| 선생님 | `features/home/presentation/screens/home_screen.dart` | `BottomNavigationBar` → paper 배경 + 2px ink top border + 로마숫자 4탭 (I 홈, II 스케줄, III 수강관리, IV 프로필). active = `paperAccent`, inactive = `inkTertiary` | f9c372cb |
| 학부모 | `features/parent_home/presentation/screens/parent_home_screen.dart` | 동일 패턴 5탭 (I 홈, II 레슨, III 과제, IV 결제, V 프로필). 사용하지 않게 된 `_buildNavItems` 제거 | f9c372cb |

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed
- 기능·Provider·라우팅 변경 없음 (네비 렌더만 교체)

**은유**: 각 탭 = 악장 번호 (I·II·III·IV·V). 진행 중 악장만 Vermillion 으로 강조.

### 7.14 AppBar 타이틀 Playfair 통일 — 전역 테마 1-지점 수정

**배경**: 본문·프리뷰·네비에 Playfair·Gaegu·로마숫자·Vermillion 을 모두 적용했지만 AppBar 타이틀은 Pretendard(산세리프) 로 남아있어 **상단부 전체가 4대 시그니처 이탈**. 하위 화면 수십 곳이 개별 수정 없이 한 번에 통일되도록 전역 테마를 수정.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/notebook_typography.dart` | `appBarTitle` 스타일 신설 — Playfair Display 18 / w700 / letterSpacing 0 / height 1.2 | f81dab87 |
| `core/theme/app_theme.dart` | light · dark 두 테마의 `appBarTheme.titleTextStyle` 을 `AppTypography.headingMedium`(Pretendard) → `NotebookTypography.appBarTitle` 로 교체 (dark 는 color override) | f81dab87 |

**영향 범위**: AppBar 를 사용하는 전 화면 (학부모 5탭 + 학생 하위 + 레슨·학생·결제·프로필 상세 등 수십 곳). 개별 화면 수정 없이 테마만으로 일괄 적용.

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed
- 개별 AppBar title override 없음 (grep 확인)

**은유**: AppBar 타이틀 = 악보 페이지 상단의 곡 제목(Playfair serif).

### 7.15 TabBar + Dialog 테마 통일 — 전역 1-지점으로 4대 시그니처 마감

**배경**: 상단(AppBar) · 하단(BottomNav) · 본문(Gaegu/Playfair) 이 통일됐지만 **중간 계층(TabBar · AlertDialog)** 이 여전히 도메인별 개별 override 또는 Material 기본값(파란색) 으로 산재. Vermillion 인디케이터를 5곳이 각자 지정하고, `tip_template_management_screen` 은 override 가 없어 Material 기본 파란색 TabBar 를 렌더. 테마 한 지점을 손대서 기본값 자체를 Notebook × Score 로 만들어 개별 override 를 최소화.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/notebook_typography.dart` | `dialogTitle` 스타일 신설 — Playfair Display 19 / w700 / letterSpacing 0 / height 1.25 (AppBar 18 보다 살짝 큼) | 51ef70f8 |
| `core/theme/app_theme.dart` (light/dark) | `tabBarTheme` 추가 — labelColor/indicator = `paperAccent`, unselected = `inkSecondary`(light)/`textSecondaryDark`(dark), 라벨은 `bodyMedium` w600 | 51ef70f8 |
| `core/theme/app_theme.dart` (light/dark) | `dialogTheme` 추가 — `titleTextStyle = NotebookTypography.dialogTitle` (dark 는 `textPrimaryDark` color override) | 51ef70f8 |

**영향 범위**:
- TabBar 를 사용하는 전 화면 (follow_list, teacher_subscription_list, teacher_search, payment_management, lesson_detail 등). 기존 `paperAccent` override 5곳은 그대로 작동(테마 기본값과 동일) + `tip_template_management_screen` 의 Material 기본 파란색 자동 수정.
- AlertDialog 를 사용하는 전 화면 (확인/경고 다이얼로그 수십 곳) — 제목이 Playfair 로 일괄 변경.
- 특수 override(학생 상세 흰색 TabBar, 스케줄 변경 pill 인디케이터) 는 개별 화면에서 그대로 유지됨.

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: TabBar 인디케이터 = 악보에서 현재 섹션을 짚는 Vermillion 연필 자국. Dialog 제목 = 페이지 상단 악장 표기.

### 7.16 SnackBar 테마 통일 — 앱 전반 알림을 Notebook 팔레트로

**배경**: SnackBar 는 `features/` 전반에서 **507회 호출 / 105 파일**(저장·삭제·오류·안내) 이지만 Material 기본 회색 배경을 그대로 사용. 페이퍼(paper) 스캐폴드 위에 회색 박스가 뜨면서 Notebook × Score 정체성 붕괴. 개별 `ScaffoldMessenger.of(context).showSnackBar(...)` 호출부를 전부 손댈 수 없기에 테마 한 지점으로 기본값 교체.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `snackBarTheme` 추가 — `backgroundColor = ink`, `contentTextStyle = bodyMedium + paper`, `actionTextColor = paperAccent`, `behavior = floating`, `shape = radiusMedium` | ff47d57e |
| `core/theme/app_theme.dart` (dark) | `snackBarTheme` 추가 — `backgroundColor = surfaceDark`, `contentTextStyle = bodyMedium + textPrimaryDark`, 액션·floating·shape 동일 | ff47d57e |

**영향 범위**:
- 저장/삭제 완료 안내, 네트워크 오류, 권한 거부, 공유 완료, 연습 시작 토스트 등 — 105 파일의 `ScaffoldMessenger` 호출부가 개별 수정 없이 Notebook 팔레트로 렌더.
- 액션 버튼(실행취소 등)은 Vermillion 으로 시선 집중.
- `floating + radiusMedium` 으로 페이퍼 위에 떠 있는 노트 카드 질감.

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: SnackBar = 악보 페이지 위에 잠깐 올려놓는 쪽지. 종이(페이퍼) 위의 쪽지(ink 박스)에 Vermillion 액션 링크.

### 7.17 섹션 헤더 Playfair 통일 — 매스트헤드→AppBar→섹션→곡명 위계 확립

**배경**: 레슨 상세의 `LessonDetailSectionHeader` 는 "레슨 피드백 / 선생님 피드백 / 주요 포인트 / 연습 팁 / 내 메모" 5종 + `StudentMemoCard` 타이틀까지 **6곳**에서 재사용되지만, 여전히 `AppTypography.headingSmall`(Pretendard 18/w600) 로 렌더되어 상단 AppBar(Playfair) ↔ 본문 섹션(Pretendard) 사이에 서체 단절 발생. 매스트헤드·AppBar 는 Playfair, 본문 입력·바디는 Pretendard/Gaegu 인 Notebook 위계를 섹션 헤더까지 연결해야 "악보 페이지의 표제 → 악장 → 마디"로 이어지는 리듬이 완성됨.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/notebook_typography.dart` | `sectionTitle` 추가 — Playfair 17 / w600 / letterSpacing -0.2 / height 1.3. `appBarTitle`(18) 과 `pieceTitle`(16) 사이 중간 위계. | 164d2d5b |
| `features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart` | `LessonDetailSectionHeader` 타이틀이 `NotebookTypography.sectionTitle` 사용. 1-지점 수정으로 5개 섹션 + StudentMemoCard 일괄 전환. | 164d2d5b |

**영향 범위**:
- `LessonDetailSectionHeader(title: '레슨 피드백')`, `'선생님 피드백'`, `'주요 포인트'`, `'연습 팁'`, `'내 메모'` — 5종 헤더가 Playfair 서체로 전환.
- `StudentMemoCard` 의 동일 헤더도 자동 반영.
- 아이콘(20px Vermillion) + Playfair 17 조합으로 "악장 표제" 질감 형성.

**위계 정리**:
- `masthead` (38pt) — 페이지 최상단 타이틀
- `appBarTitle` (18pt) — 앱바·다이얼로그 제목
- `sectionTitle` (17pt) — 화면 내부 영역 헤더 ← **신설**
- `pieceTitle` (16pt) — 곡명·레슨 제목

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 섹션 헤더 = 악보의 악장 표제(Andante, Allegro…). 매스트헤드가 교향곡 전체 제목이면, 섹션은 각 악장의 제목이므로 같은 Playfair 가문으로 묶되 한 단계 작은 크기로 위계 표시.

### 7.18 Switch + TextSelection 테마 통일 — 미세 인터랙션까지 Vermillion

**배경**: 큰 면(AppBar·TabBar·Dialog·SnackBar·섹션 헤더) 은 Notebook × Score 로 통일됐지만 **미세 인터랙션(토글·커서·드래그 선택)** 은 여전히 Material 기본(파란 thumb / 파란 커서). 설정·정책·필터 화면의 Switch 20 파일이 각자 `activeThumbColor: paperAccent` 를 지정하거나 지정하지 않아 일관성 부족. 텍스트 필드 커서도 Material 파랑으로 폼 입력 시 시그니처 이탈.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `switchTheme` 추가 — thumb/track/outline 을 `WidgetStateProperty` 로 제어. selected = `paperAccent` + `paperAccentSoft`, unselected = `paper` + `inkQuaternary` | 2d6e8739 |
| `core/theme/app_theme.dart` (dark) | `switchTheme` 추가 — selected 는 Vermillion 유지, unselected 는 `textSecondaryDark` + `borderDark` | 2d6e8739 |
| `core/theme/app_theme.dart` (light/dark) | `textSelectionTheme` 추가 — `cursorColor`, `selectionColor = paperAccentSoft`, `selectionHandleColor` 전부 `paperAccent` | 2d6e8739 |

**영향 범위**:
- Switch 사용 20 파일(설정·정책·필터·예약) 이 개별 `activeThumbColor` override 없이도 Vermillion active 렌더.
- 모든 `TextField` / `TextFormField` 커서·드래그 핸들·선택 배경이 Vermillion 으로 일괄 전환 (Material 파란 커서 제거).

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: Switch active = 체크박스에 찍는 Vermillion 도장. 텍스트 커서 = Vermillion 만년필 끝.

### 7.19 폼 화면도 sectionTitle 로 통일 — 학생/레슨 추가·편집 전 범위 확장

**배경**: §7.17 에서 레슨 상세의 섹션 헤더를 Playfair 로 전환했으나, "학생 추가/편집" 및 "레슨 추가/편집" 폼 화면은 여전히 Pretendard `headingSmall` 로 섹션을 구분하고 있었음. 사용자 플로우에서 상세→편집으로 이동하는 순간 서체가 Pretendard 로 바뀌면서 위계 단절 발생. 두 폼 화면 모두 공통 위젯(`FormSectionTitle`, `LessonFormSectionTitle`)을 사용하므로 2-지점 수정으로 전면 반영 가능.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/students/presentation/widgets/student_form/form_section_title.dart` | `FormSectionTitle` 이 `NotebookTypography.sectionTitle` 사용 | 0bb76420 |
| `features/lessons/presentation/widgets/lesson_form/lesson_student_info.dart` | `LessonFormSectionTitle` 동일 적용 + unused `AppTypography` import 제거 | 0bb76420 |
| `.gitignore` | `.autopus/` + `autopus.yaml` 추가 (로컬 툴 아티팩트 제외) | 0bb76420 |

**영향 범위** (23 instances / 2-widget change):
- `add_student_screen` 7곳: 기본 정보 / 보호자 정보 / 주소 / 악기 / 레벨 및 수강료 / 레슨 일정 / 메모
- `edit_student_screen` 7곳: 동일 7 라벨
- `add_lesson_screen` 5곳: 학생 선택 / 일시 / 레슨 시간 / 레슨 장소 / 레슨 내용
- `edit_lesson_screen` 4곳: 학생 / 일시 / 레슨 시간 / 레슨 내용

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 상세(공연 팸플릿) ↔ 편집(무대 뒤 악보)도 같은 Playfair 가문으로 연결. 사용자가 상세에서 편집으로 넘어가는 순간 "악보가 바뀌는" 어색함이 사라짐.

### 7.20 정기 레슨 + 프로필 공개 설정 + 레슨 시간 설정도 sectionTitle 로 확장

**배경**: §7.19 에서 학생/레슨 폼 섹션 제목까지 Playfair 로 전환했으나, 다음 3개 위젯이 여전히 `AppTypography.headingSmall` 를 사용 중이었음:
- `RegularLessonSectionTitle` — 정기 레슨 등록 폼 (schedule)
- `VisibilitySectionTitle` — 프로필 공개 범위 설정 시트 (profile)
- `LessonTimeSettingsSectionTitle` — 레슨 시간 설정 화면 (profile)

설정·등록 플로우가 상세·편집 화면과 서체가 달라 시각 위계 단절. 3-지점 추가 수정으로 일관성 마감.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/schedule/presentation/widgets/regular_lesson_widgets.dart` | `RegularLessonSectionTitle` 이 `NotebookTypography.sectionTitle` 사용 | 2ea52c03 |
| `features/profile/presentation/widgets/profile_visibility_widgets.dart` | `VisibilitySectionTitle` 동일 적용 + `.copyWith(fontWeight: bold)` 오버라이드 제거 (sectionTitle 의 w600 자체로 충분) | 2ea52c03 |
| `features/profile/presentation/widgets/lesson_time_settings_widgets.dart` | `LessonTimeSettingsSectionTitle` 동일 적용 | 2ea52c03 |

**영향 범위**:
- 정기 레슨 등록 폼 7 섹션 (학생 / 요일 / 시작시간 / 레슨 시간 / 반복 주기 / 기간 / 메모 등)
- 공개 범위 설정 시트 1 섹션
- 레슨 시간 설정 화면 6 섹션 (기본 시간 / 추가 시간 슬롯 / 수업 가능 시간대 등)

**누적 sectionTitle 사용처** (§7.17 + §7.19 + §7.20):
- 레슨 상세 6곳 + 학생/레슨 폼 23곳 + 정기 레슨/프로필 14곳 = **43 instances**
- 단 5개 공통 위젯 수정으로 달성 — "공통 수정 = 일괄 반영" 원칙 재확인

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 앱 전역의 섹션 타이틀이 한 오케스트라의 악장 표제처럼 통일됨. 사용자가 어느 화면에 있든 "악장 번호"가 같은 서체로 표시되어 악보를 읽는 듯한 연속성 확보.

### 7.21 Icon + ListTile 테마 통일 — 기본 ink, 선택 Vermillion 단일 진원지

**배경**: §7.18 까지 Switch/TextSelection 같은 미세 인터랙션을 마감했으나, 앱 전반에서 가장 흔한 `Icon` 기본 색상과 `ListTile` (36 파일 사용) 의 icon/text/선택 색상은 각 호출부가 개별 스타일을 지정하고 있었음. 기본값이 없으니 일부 화면은 ink, 다른 화면은 시스템 기본(파란색) 또는 grey 로 섞여 보여 일관성 깨짐. `app_theme.dart` 1-지점에서 `iconTheme` + `listTileTheme` 추가로 전 화면 일괄 정리.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `iconTheme` + `primaryIconTheme` 기본색 `ink`, `listTileTheme` icon/text `ink`, 선택 `paperAccent` + 배경 `paperAccentSoft` | f1055bac |
| `core/theme/app_theme.dart` (dark) | 기본색 `paper` / `textPrimaryDark`, 선택색은 동일 Vermillion 유지 | f1055bac |

**영향 범위**:
- `ListTile` 36 파일 (profile 메뉴, 설정 화면, 드로어, 선택 시트 등)의 icon/text 기본 색상이 ink 로 통일
- 선택 상태(`selected: true`)는 Vermillion + paperAccentSoft 배경으로 시각 강조
- 모든 `Icon()` 위젯의 기본 색상이 ink → 개별 `color: AppColors.ink` 지정 불필요
- 다크 테마 대응 포함 — 라이트/다크 모두 일관 규칙

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 악보의 표기 기호(♯, ♭, 강약)들이 모두 같은 잉크로 인쇄되는 원칙. 한 페이지 안에서 서로 다른 색의 기호가 섞이지 않듯, 앱의 아이콘과 리스트 항목도 단일 팔레트로 일관 적용.

### 7.22 학부모 홈 섹션 헤더도 sectionTitle 로 확장

**배경**: 학부모 앱의 과제 탭 / 결제 탭은 각 화면 내부에서 파일-private `_SectionHeader` 위젯을 정의하여 `AppTypography.headingSmall` 로 섹션 제목을 렌더. 공통 위젯이 아니므로 §7.17~§7.20 의 공통 위젯 수정으로는 닿지 않는 사각지대. 학부모 플로우의 핵심 탭 2개이므로 별도 이식 필요.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/parent_home/presentation/screens/parent_assignments_tab.dart` | `_SectionHeader` 가 `NotebookTypography.sectionTitle` 사용 (count 뱃지는 그대로 유지) | 17a4c194 |
| `features/parent_home/presentation/screens/parent_payments_tab.dart` | `_SectionHeader` 가 `NotebookTypography.sectionTitle.copyWith(color: ...)` 적용 — 미납/완료 등 상태별 색상은 유지 | 17a4c194 |

**영향 범위**:
- 학부모 과제 탭 — "미완료 과제 · 완료된 과제" 등 섹션 헤더
- 학부모 결제 탭 — "미납 결제 · 완료된 결제" 등 상태별 섹션 헤더 (색상 오버라이드 유지)

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 학부모 앱 = 선생님·학생 앱의 "관객석 뷰". 무대(선생님·학생)와 같은 프로그램 북(Playfair 섹션 표제)을 봐야 시각 일관성이 유지됨.

### 7.23 PopupMenu + DropdownMenu 테마 통일 — 메뉴 팝업에도 2px ink 테두리

**배경**: §7.21 까지 기본 아이콘·리스트 색상은 통일되었으나, `PopupMenuButton` (21 파일) / `showMenu` 호출이 띄우는 팝업과 `DropdownMenu` / `DropdownButton` (15 파일) 은 Material 기본 surface(흰색 + grey) 로 표시되어 Notebook 팔레트와 이질감. 팝업 배경을 종이색(`paper`) + 2px ink 테두리로 고정해 Notebook 카드 외곽선 규칙과 통일.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `popupMenuTheme` + `dropdownMenuTheme` 추가. `paper` 배경, 2px ink 테두리, 4px radius, ink 14/w500 텍스트 | 8a3138d5 |
| `core/theme/app_theme.dart` (dark) | 동일 구조에 `surfaceDark` 배경 + `paper` 2px 테두리 | 8a3138d5 |

**영향 범위** (36 파일):
- `PopupMenuButton` 21 파일: 레슨 상세 메뉴, 과제 편집, 설정 백업, 수강권 템플릿, 프로필 스위처, 리퍼토리 등
- `DropdownMenu` / `DropdownButton` 15 파일: 악기 선택, 레벨 선택, 요일 선택 등 폼 셀렉터
- 팝업 배경이 종이색으로 고정되어 앱 카드 외곽선(§3) 과 동일한 2px 규칙 적용
- `MenuStyle` 을 `WidgetStateProperty.all` 로 감싸 Material3 규격 준수

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 악보 뒷면에 접혀 나오는 주석 쪽지도 같은 종이와 같은 테두리로 인쇄되는 느낌. 메뉴 팝업이 본문 페이지의 축소판처럼 보여 "어디에 있어도 같은 악보집" 감각 유지.

### 7.24 DatePicker + TimePicker 테마 통일 — Material blue 제거, Vermillion 선택 + 2px ink 테두리

**배경**: §7.23 까지 팝업·드롭다운 메뉴는 통일되었으나, `showDatePicker` / `showDateRangePicker` / `showTimePicker` 호출(15 파일) 이 띄우는 날짜·시간 선택기는 Material3 기본 `ColorScheme.primary` (blue) 를 선택색으로 사용하여 Notebook 팔레트에서 가장 눈에 띄는 잔여 이질 영역. 스케줄링·과제 마감·레슨 시간 등 앱 핵심 플로우에서 반복 노출되어 사용자 몰입을 깨는 가장 큰 holdout 이었음.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `datePickerTheme` + `timePickerTheme` 추가. 배경 `paper`, 2px ink 테두리, 선택일/시간 `paperAccent` + 비선택 `paperAccentSoft`, 오늘 Vermillion 테두리 강조, 시계 다이얼 핸들 Vermillion | fe473cf1 |
| `core/theme/app_theme.dart` (dark) | 동일 구조에 `surfaceDark` 배경 + `paper` 2px 테두리 + `borderDark` 비선택 배경 | fe473cf1 |

**영향 범위** (15 파일):
- `showDatePicker` 호출: 레슨 일시 선택, 과제 마감일, 정기 레슨 기간 설정, 수강권 시작일 등
- `showDateRangePicker` 호출: 레슨 필터 기간 지정, 결제 내역 조회 기간
- `showTimePicker` 호출: 레슨 시작 시간, 연습 알림 시간, 수업 가능 시간대 설정
- `WidgetStateProperty.resolveWith` 로 selected/disabled 상태별 색상 분기
- `todayBorder` 로 오늘 날짜를 Vermillion 테두리로 항상 식별 가능하게 표시

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 악보집에 끼워진 달력·시계표도 Playfair 악보와 같은 잉크·같은 테두리로 인쇄된 느낌. Material 기본 blue 는 "공장에서 찍어낸 캘린더 스티커", Vermillion + 2px ink 는 "편집자가 손으로 표시한 달력" 의 차이. 앱의 모든 "시간 선택" 순간이 Notebook 카드 외곽선 규칙과 동일한 시각 언어로 통일.

### 7.25 분석 대시보드 섹션 헤더도 sectionTitle 로 확장

**배경**: §7.22 까지 레슨·학생·폼·프로필·정기레슨·학부모 홈 섹션 헤더를 Playfair sectionTitle 로 통일했으나, 교사 분석 대시보드(`teacher_dashboard_screen` + 2개 차트·랭킹 위젯) 의 섹션 헤더 4곳은 여전히 `AppTypography.headingSmall` (Noto Sans) 상태. 대시보드는 교사가 월 1회+ 진입하는 회고 플로우라 섹션 제목의 톤이 "리포트·회고 감각" 을 크게 좌우.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/analytics/presentation/screens/teacher_dashboard_screen.dart` | "수익 현황", "학생 현황" 2곳 | b96874bc |
| `features/analytics/presentation/widgets/monthly_trend_chart.dart` | "레슨 추이" 1곳 | b96874bc |
| `features/analytics/presentation/widgets/practice_ranking_list.dart` | "연습률 TOP 5" 1곳 | b96874bc |

**적용 범위** (총 4곳):
- 교사 대시보드 상단 섹션 2개 (수익/학생)
- 중간 차트 카드 섹션 제목 1개
- 하단 랭킹 리스트 섹션 제목 1개
- 카드 내부 본문·숫자(`headingLarge`, `bodyMedium`) 는 그대로 유지하여 "섹션 제목만 악보, 본문은 Noto" 구분 유지

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 교사가 한 달을 돌아볼 때 대시보드가 "악보집 끝에 붙은 월간 리포트" 처럼 느껴지도록. Playfair 로 찍은 "수익 현황 · 학생 현황 · 레슨 추이 · 연습률 TOP 5" 는 악보집 마지막 장 "이번 달 공연 결산" 섹션 제목 감각 — 숫자 본문은 여전히 읽기 편한 Noto Sans 로 남겨 가독성 희생 없이 몰입감만 강화.

### 7.26 Radio 테마 통일 — 선택 링·도트까지 Vermillion, Material blue 완전 제거

**배경**: §7.18 Switch, §7.15 TabBar, §7.16 SnackBar, §7.23 Popup/Dropdown, §7.24 DatePicker/TimePicker 로 대부분의 Material 기본 파랑을 Vermillion 으로 치환했지만, **Radio 위젯은 테마에서 누락** 되어 있었다. 앱 내 Radio 호출 5곳 중 2곳(`schedule_type_selector`, `lesson_time_settings_widgets`) 만 개별 `activeColor: AppColors.paperAccent` 로 오버라이드 상태이고, 나머지 3곳(`current_request_box` 템플릿 다중선택, `issue_form_membership_widgets` 수강권 선택, 기타) 은 Material blue 로 렌더되어 Notebook 팔레트에서 가장 눈에 띄는 이질 영역으로 남아 있었다. Switch 는 토글·On/Off 뉘앙스라 Vermillion 이 자연스러웠지만, Radio 는 "하나를 고르는 결정" 의 순간이라 더더욱 악보 위 붉은 연필 표시 감각이 필요하다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `radioTheme: RadioThemeData` 추가 — `fillColor` selected=paperAccent / unselected=inkQuaternary / disabled=inkTertiary, `overlayColor` pressed·hovered·focused=paperAccentSoft | 8cd2a276 |
| `core/theme/app_theme.dart` (dark) | 동일 스펙의 dark 버전 — unselected=borderDark / disabled=textSecondaryDark. Vermillion active 유지 | 8cd2a276 |

**영향 범위** (5개 Radio 호출):
- `schedule_type_selector.dart` — 개별 레슨 / 정기 레슨 스케줄 타입 선택 (기존 activeColor override → 이제 테마로 흡수)
- `lesson_time_settings_widgets.dart` — 레슨 시간 duration 선택 (30/45/60분)
- `current_request_box.dart` — 선생님 수강권 제안 중 다중 템플릿에서 하나 선택 (이제 Vermillion)
- `issue_form_membership_widgets.dart` — 수강권 발급 폼에서 멤버십 선택 (이제 Vermillion)
- 기타 호출부 — RadioListTile 포함 3 파일

**설계 포인트**: `fillColor` 는 Radio 의 외곽 링과 내부 도트를 동시에 결정한다 → selected 시 링도 Vermillion, 도트도 Vermillion 으로 두꺼운 붉은 원이 찍힌다. `overlayColor` 는 탭/호버 시 링 주변에 연한 Vermillion splash (`paperAccentSoft`) 가 번지도록 해 촉각적 피드백을 Notebook 팔레트 내에서 해결. 개별 `activeColor` override 는 남겨둬도 테마와 같은 색이므로 제거하지 않고 유지 (호환성).

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 악보집에서 연주자가 "오늘은 이 곡" 을 고를 때 연필 대신 붉은 색연필로 동그라미를 친다. 링·도트가 모두 Vermillion 이라 "선택됨" 이 한눈에 들어오고, 호버 시 번지는 연한 Vermillion splash 는 색연필이 살짝 번진 듯한 아날로그 감각.

---

### 7.27 수강권 발급 시트·회차 입력 다이얼로그 제목 Playfair 통일

**배경**: §7.5 AppBar 제목, §7.9 AlertDialog 제목 전역 테마로 대부분의 페이지/다이얼로그 상단이 Playfair Display 로 통일됐지만, `unified_subscription_sheet` 는 두 가지 이유로 예외로 남아 있었다. ① 바텀시트 헤더는 AppBar 가 아니라 커스텀 Row 구조라 전역 `appBarTitle` 이 닿지 않았고 `AppTypography.headingSmall` (Pretendard 18) 로 남아 있었다. ② 시트 내부에서 띄우는 회차 입력 AlertDialog 는 `dialogTheme` 이 자동 적용되지만 `title: Text('회차 입력', style: AppTypography.headingSmall)` 로 스타일을 직접 오버라이드해 테마를 무력화하고 있었다. 수강권 발급은 선생님이 가장 자주 진입하는 모달 플로우라 제목 타이포가 다르면 Notebook 팔레트의 경계가 가장 먼저 드러난다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/subscription/presentation/widgets/unified_subscription_sheet.dart` | 바텀시트 헤더 `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`, AlertDialog 제목의 `style:` 오버라이드 제거(전역 `dialogTheme` 위임) | 885c6c23 |

**설계 포인트**:
- 바텀시트 커스텀 헤더는 AppBar 와 시각 위계를 맞추기 위해 `appBarTitle` (Playfair 18/w700) 재사용. 별도 `bottomSheetTitle` 변형을 만들지 않고 AppBar 와 같은 스타일 채택 — 사용자가 "페이지 전환" 과 "모달 전환" 을 같은 무게로 경험하게 됨.
- AlertDialog 는 전역 `dialogTheme.titleTextStyle = NotebookTypography.dialogTitle` (Playfair 19/w700) 이 이미 붙어 있으므로 `style:` 을 제거하는 "공통 수정" 만으로 19pt 로 정렬. 앞으로 추가되는 다이얼로그는 기본값으로 같은 규칙을 따른다 → 단일 진원지 재확인.

**검증**:
- `flutter analyze lib/features/subscription/presentation/widgets/unified_subscription_sheet.dart` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 악보집 중간의 펼침 면(바텀시트)도, 그 위에 살짝 붙는 메모지(다이얼로그)도 표지와 같은 Playfair 로마자 제목을 쓴다. 제본 깊이가 달라도 "같은 책 안" 임을 제목 서체가 보증한다.

---

### 7.28 Slider 테마 통일 — BPM·튜닝·녹음임계값 트랙·Thumb 을 Vermillion 으로

**배경**: §7.18 Switch, §7.23 Popup/Dropdown, §7.24 DatePicker/TimePicker, §7.26 Radio 로 입력·선택 위젯의 Material blue 를 모두 걷어냈지만 **Slider 만 전역 테마에서 누락** 되어 있었다. 앱 내 Slider 호출 9곳 중 `tuner_settings_sheet` 1곳만 `activeColor: AppColors.paperAccent` 로 개별 override, 나머지 8곳(메트로놈 BPM 2곳, smart recording 임계값 2곳, 레슨시간 duration, 경력연수, 레슨비 min/max 2곳) 은 Material blue 트랙·썸으로 렌더되어 Notebook 팔레트에서 이탈. 연습·녹음·프로필 등 **매일 조정하는 핵심 파라미터** 가 4대 시그니처에서 빠져 있었다.

| 파일 | 변경 | 커밋 |
| core/theme/app_theme.dart (light) | sliderTheme: SliderThemeData — activeTrackColor/thumbColor=paperAccent, inactiveTrackColor=inkQuaternary, overlayColor=paperAccentSoft, valueIndicatorColor=ink + paper 텍스트 | a3a135c2 |
| core/theme/app_theme.dart (dark)  | 동일 스펙, inactiveTrackColor=borderDark, valueIndicatorColor=surfaceDark + textPrimaryDark | a3a135c2 |

**영향 범위** (9개 Slider 호출):
- metronome_full_screen_modal.dart — 전체화면 메트로놈 BPM 슬라이더
- practice_tools/bpm_controls.dart — 연습 패널 로그 스케일 BPM 슬라이더
- practice_tools/metronome_panel.dart — 연습 패널 (LogarithmicBpmSlider 재사용)
- tuner/tuner_settings_sheet.dart — 튜너 기준 주파수 (기존 override 유지, 동일 색)
- smart_recording/smart_recording_settings.dart — 무음 트림 임계값 + 중간 무음 임계값 2곳
- profile/lesson_time_settings_widgets.dart — 레슨 시간 duration (분)
- profile/extended_profile_dialogs.dart — 경력 연수 + 최소 레슨비 + 최대 레슨비 3곳

**설계 포인트**:
- `activeTrackColor` + `thumbColor` 를 동일 Vermillion 으로 묶어 "드래그 중 값 = 선택된 값" 시각 일체감 확보.
- `inactiveTrackColor` 는 light 에서 `inkQuaternary`, dark 에서 `borderDark` — 배경과의 최소 대비로 차분한 빈 구간 유지.
- `overlayColor` = `paperAccentSoft` — 썸 터치 시 부드러운 붉은 스프레드.
- `valueIndicatorColor` 는 bubble tooltip 배경. ink/surfaceDark + paper/textPrimaryDark 텍스트로 **잉크 방울** 이미지 유지.
- `tuner_settings_sheet` 의 개별 `activeColor: paperAccent` override 는 테마 값과 동일하므로 제거하지 않고 유지 (호환성, 이중 안전장치).

**검증**: flutter analyze → 0 issues / flutter test → 392/392 passed

**은유**: 오선지에 메트로놈 템포를 붉은 색연필로 그어 넣는다. 정해진 템포까지는 선이 진하게 칠해지고, 그 앞은 얇은 연필 밑줄만 남는다. 연필 끝을 누르는 지점(썸)도, 지나간 자국(active track)도 같은 붉은 색 — 연주자는 "어디까지 왔나" 를 한눈에 안다.

### 7.29 레슨 일정 변경 바텀시트 제목 Playfair 통일

**배경**: §7.27 에서 "바텀시트 커스텀 헤더는 전역 `appBarTitle` 이 닿지 않으므로 `NotebookTypography.appBarTitle` 을 직접 지정한다" 는 패턴을 세웠다. 같은 구독 플로우의 `reschedule_bottom_sheet` — 학생/선생님이 레슨 일정을 변경할 때 가장 먼저 마주하는 모달 — 역시 `AppTypography.headingSmall` (Pretendard 18/w600) 로 남아 있어 시트 안의 Vermillion 라디오·경고 박스와 시각 위계가 어긋났다. 자주 오가는 플로우일수록 제목 서체 불일치가 "다른 모듈에 들어온 느낌" 을 강하게 준다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/subscription/presentation/widgets/reschedule_bottom_sheet.dart` | 시트 헤더 `AppTypography.headingSmall` → `NotebookTypography.appBarTitle` (Playfair 18/w700) | 82292361 |

**설계 포인트**:
- §7.27 의 패턴(커스텀 헤더 = `appBarTitle` 재사용) 을 그대로 적용. 별도 신규 타이포 토큰 추가 없이 기존 단일 진원지(`NotebookTypography`) 만으로 해결.
- 주석에 `§7.27 패턴` 을 명시하여 이후 추가되는 바텀시트 구현자가 README 로 점프할 수 있게 함.

**검증**:
- `flutter analyze lib/features/subscription/presentation/widgets/reschedule_bottom_sheet.dart` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 같은 악보집(수강권 플로우) 안에서 페이지를 넘겨도(발급 → 일정 변경) 장 제목의 Playfair 로마자 서체는 변하지 않는다. 독자의 시선이 머무를 곳이 일관되게 예고되어 있어야 "다른 책" 으로 오해하지 않는다.

---

### 7.30 연결 요청 대기 빈 상태 제목 Playfair 통일

**배경**: 선생님/학생이 초대 코드로 연결을 주고받는 `pending_requests_screen` — 빈 상태("대기 중인 연결 요청이 없습니다") 가 대부분의 사용자가 처음 들어가서 마주하는 화면이다. 빈 상태 헤딩이 `AppTypography.headingSmall` (Pretendard 18/w600) 로 남아 있어, 같은 화면의 Vermillion 원형 아이콘 배경과 시각 위계가 어긋났다. 빈 상태일수록 제목 한 줄의 타이포 완성도가 앱의 "잘 만들었다는 인상"을 결정한다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/invite/presentation/screens/pending_requests_screen.dart` | 빈 상태 헤딩 `AppTypography.headingSmall` → `NotebookTypography.appBarTitle` (Playfair 18/w700) | 886ab275 |

**설계 포인트**:
- §7.27 의 "커스텀 헤더 = `appBarTitle` 재사용" 패턴을 빈 상태 헤딩으로 확장. 바텀시트 헤더(§7.27, §7.29) 와 같은 한 줄 치환 → 단일 진원지(`NotebookTypography`) 만으로 해결.
- 같은 파일 233행의 `CircleAvatar` 이니셜 글자(`requesterName[0]`) 는 의도적으로 제외. 이니셜 글리프는 섹션/화면 제목이 아닌 "프로필 기호"로서 별도 타이포 규칙이 필요하다. Playfair 를 강제하면 구형 세리프가 원형 아바타 안에서 잘리거나 커닝이 깨질 수 있어 추후 별도 SPEC 으로 다룬다.

**검증**:
- `flutter analyze lib/features/invite/presentation/screens/pending_requests_screen.dart` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 오선지 위 "TACET" (쉼표 마디) 표기처럼, 아무 음표가 없는 마디에도 장 제목의 서체는 유지된다. 쉼의 순간일수록 제목이 일관되게 남아 있어야 곡이 같은 악보 안에 있다는 감각을 해치지 않는다.

---

### 7.31 Chip 테마 통일 — FilterChip/ChoiceChip 선택 상태를 Vermillion 으로 단일 진원지 수렴

**배경**: `FilterChip`/`ChoiceChip`/`ActionChip`/`InputChip` 은 앱 전체 **174 발생 / 70 파일** 로 4대 시그니처 다음가는 밀도(연습 목표 설정, 튜너 설정, 선생님 검색 필터, 수강권 발급 폼, 가용 시간대 선택 등). §7.28 Slider 와 같이 Material blue 가 기본값으로 흘러나오던 컴포넌트이며, 20 여 개의 호출부는 이미 `selectedColor: paperAccent.withAlpha(30)` 또는 `paperAccent.withValues(alpha: 0.15)` 로 개별 override 중이었으나, **override 없는 칩은 여전히 Material blue 선택색을 드러냈다**. §7.18 Switch · §7.26 Radio · §7.28 Slider 로 이어진 "선택형 입력 = Vermillion" 원칙을 칩까지 확장.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `frontend/lib/core/theme/app_theme.dart` | light/dark `ThemeData` 에 `chipTheme: ChipThemeData` 추가. `backgroundColor` · `selectedColor` · `checkmarkColor` · `labelStyle` · `secondaryLabelStyle` · `side` · `elevation`/`pressElevation` 지정 | 3e99ce13 |

**영향 범위**: 칩을 쓰는 70 파일 중 명시적 override 가 없는 호출부(예: `tuner_settings_sheet` 의 상세 필터, `profile_setup_screen` 악기 칩, `add_section_widgets` 난이도 칩, `regular_lesson_widgets` 요일 칩 일부) 의 **미선택 배경 + 선택 배경 + 체크마크 + 라벨 색** 이 Notebook 팔레트로 자동 치환.

**설계 포인트**:
- `backgroundColor` 는 `paperDark` (light) / `surfaceDark` (dark) — 칩이 카드·시트 위에서 살짝 들려 보이는 두 번째 paper 톤.
- `selectedColor` 는 `paperAccentSoft` (12% Vermillion) — 기존 호출부가 손으로 맞추던 `paperAccent.withAlpha(30)` (≈12%) 와 동일 레이어. 이제 이 값을 테마에서 한 번만 정의하면 새 칩은 자동으로 같은 선택색을 얻는다.
- `secondaryLabelStyle` 을 `paperAccent / w600` 으로 지정 → `showCheckmark: true` 와 `secondaryLabelStyle` 을 함께 쓰는 칩에서 선택된 라벨이 잉크색 대신 Vermillion 으로 떠오른다. 기본 `labelStyle` 은 `ink` 유지하여 비선택 칩은 차분한 본문 톤.
- `elevation`/`pressElevation` 을 0 으로 지정해 Notebook flat 원칙 고수 — 기본 Material 칩의 탭 순간 그림자 팝업 제거.
- `side` 를 `inkQuaternary / borderDark` 1px 로 명시 — 칩이 paper 배경과 구분되어 "클릭 가능한 영역" 이 명확해짐. 개별 호출부가 `BorderSide(color: paperAccent)` 로 선택 테두리를 override 하는 경우 여전히 override 가 우선.
- `shape` 는 설정하지 않음 — 기존 `RoundedRectangleBorder(radiusMedium)` override 와 `StadiumBorder` 기본 양쪽을 방해하지 않기 위함.

**호환성**:
- 명시적 `selectedColor: paperAccent` (단색, 예: `trial_lesson_info_section`, `issue_subscription_screen`, `regular_lesson_widgets` 일부) 는 테마를 덮어 그대로 단색 Vermillion 으로 유지 — 강조형 칩은 계속 강조.
- 명시적 `selectedColor: paperAccent.withValues(alpha: 0.15~0.2)` 는 테마의 12% 와 거의 같은 값이라 시각 차이 미미 — 점진적으로 override 를 제거해 테마로 수렴시킬 수 있음 (후속 정리 여지 기록).

**검증**:
- `flutter analyze` → `No issues found!` (14.1s)
- `flutter test` → 392/392 passed (5s)

**은유**: 악보에 붙이는 포스트잇(칩) 의 색을 팀마다 다르게 고르던 연주자들에게, 이제 한 지휘자(테마) 가 "선택한 포스트잇은 항상 주홍" 이라는 단 한 문장만 내리면 된다. 여전히 어느 악장이 파란 포스트잇을 고집하고 싶다면 그 악장 안에서만 override 할 수 있지만, 공백 상태의 포스트잇은 자동으로 올바른 색을 가진다.

---

### 7.32 ExpansionTile 테마 통일 — FAQ·진단·요일설정의 접기/펼치기 flat 경계

**배경**: `ExpansionTile` 은 앱에서 **5 호출부 / 3 파일** 에 분포 — 학생 FAQ(`help_screen`), 녹음 파일 진단(`recording_diagnostic_screen` × 3), 선생님 레슨 시간 요일 설정(`lesson_time_settings_widgets`). 빈도는 낮지만 **Material 기본은 `primaryColor` 기반의 `iconColor`/`textColor`** 를 사용하므로 과거 보라 UI 시절의 잔재가 expand 화살표와 제목 텍스트에 남아 있었다. `help_screen` 의 FAQ 타일만 `shape: Border()`/`collapsedShape: Border()` 로 flat 경계를 손으로 맞추고 있었을 뿐, 나머지 호출부는 확장 시 Material 기본 구분선이 그어져 Card 경계와 이중으로 보이는 문제가 있었다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `frontend/lib/core/theme/app_theme.dart` | light/dark `ThemeData` 에 `expansionTileTheme: ExpansionTileThemeData` 추가. `iconColor` · `collapsedIconColor` · `textColor` · `collapsedTextColor` · `backgroundColor` · `collapsedBackgroundColor` · `shape` · `collapsedShape` 지정 | 30056f7c |

**영향 범위**: 3 파일 5 호출부의 expand 화살표와 제목 기본색이 Notebook 팔레트로 자동 치환. `help_screen` 의 수동 `Border()` 설정은 이제 테마가 기본값으로 제공하므로 **중복 설정**이 되었지만 제거하지 않고 유지 (Edit 범위 최소화 — 후속 정리 여지 기록). `recording_diagnostic` 의 타이틀 `Text` 가 직접 `color: paperAccent` 를 걸어둔 경우는 override 가 우선하므로 강조가 그대로 유지된다.

**설계 포인트**:
- `iconColor: ink` · `collapsedIconColor: inkSecondary` — 펼쳐졌을 때는 본문 잉크, 접혔을 때는 한 단계 연한 잉크로 위계를 표현 (접힌 상태는 "탐색 중" 힌트, 펼친 상태는 "현재 읽는 곳" 강조).
- `textColor` / `collapsedTextColor` 는 모두 `ink` 로 통일 — 확장 여부와 관계없이 제목의 식별력은 동일해야 FAQ/진단 타이틀을 훑어볼 때 흐름이 끊기지 않는다.
- `backgroundColor`/`collapsedBackgroundColor` 를 `Colors.transparent` 로 지정 — Card 가 배경을 담당하는 패턴(3 파일 모두 `Card > ExpansionTile`)을 그대로 존중해 이중 배경을 피함.
- `shape: Border()` · `collapsedShape: Border()` — 펼친 상태의 상하 구분선을 제거해 Card border 와 겹치지 않도록 함 (§7.16 SnackBar 처럼 "경계는 한 주체만 담당" 원칙).

**호환성**:
- `help_screen` 의 `shape: const Border()` 수동 override 는 테마와 값이 같아 시각 차이 없음. 제거 시 라인 수는 줄어들지만 테마 의존성을 명시적으로 드러내는 장점은 사라지므로 유지.
- `recording_diagnostic_screen` 의 조건부 `color: paperAccent` 타이틀 (고아 파일/파일 없음 섹션) 은 override 우선으로 여전히 Vermillion 강조 — 경고성 섹션의 시각 우선순위 유지.
- `lesson_time_settings_widgets` 의 `leading: Icon(paperOk/inkTertiary)` 는 expand 화살표가 아닌 leading 슬롯이므로 테마와 무관 — 휴무/활성 상태 구분 그대로.

**검증**:
- `flutter analyze` → `No issues found!` (10.2s)
- `flutter test` → 392/392 passed (5s)

**은유**: 악보 귀퉁이에 붙인 접을 수 있는 부록(진단 섹션·FAQ)들. 지금까지는 펼칠 때마다 책 제본선이 두 번 그어진 것처럼 보였다 — 노트의 Card 경계 한 번, Material 기본 구분선 한 번. 이제 접힘/펼침을 다루는 지휘자가 "제본선은 너희가 아니라 Card 가 긋는다" 고 선언하니, 부록은 깔끔하게 펼쳐졌다가 제자리로 돌아간다.

---

### 7.33 초대 QR 코드 카드·코드 입력 본문 제목 Playfair 통일

**배경**: 선생님이 학생을 초대하거나(`invite_screen`) 학생이 선생님 코드를 입력할 때(`code_input_screen`) 나타나는 두 화면은 연결 온보딩의 핵심 길목이다. AppBar 제목은 전역 테마로 이미 Playfair 가 닿지만, **본문 안쪽의 "QR 코드" 카드 제목과 "◯◯의 초대 코드를 입력하세요" 안내 제목**은 여전히 `AppTypography.headingSmall` (Pretendard 18/w600) 로 남아 있었다. 두 화면 모두 같은 화면 안에 Vermillion 원형 아이콘 배경이 있어 본문 헤딩이 산세리프로 남으면 아이콘 원·QR 그리드의 기하 구성과 위계가 흐트러진다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/invite/presentation/screens/invite_screen.dart` | QR 코드 카드 제목 `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`. `notebook_typography` import 추가 | 30056f7c |
| `features/invite/presentation/screens/code_input_screen.dart` | "◯◯의 초대 코드를 입력하세요" 본문 제목 `headingSmall` → `appBarTitle`. `notebook_typography` import 추가 | 30056f7c |

**설계 포인트**:
- §7.27 의 "커스텀 헤더·카드 내부 제목 = `appBarTitle` 재사용" 패턴을 QR 카드와 본문 안내 헤딩으로 확장. 두 화면 모두 같은 invite 도메인의 연속 흐름(코드 생성 → 코드 입력)이라 한 커밋으로 묶어 타이포 일관성을 유지.
- `code_input_screen` 의 하위 안내("6자리 숫자 코드를 입력해주세요") 는 `bodyMedium` 그대로 — 제목은 Playfair 로 세리프 존재감을 주되, 부제는 본문 위계로 낮춰 단일 제목-부제 관계를 명확히 함.
- 커밋 번호 30056f7c 는 병렬 세션의 ExpansionTile 테마 커밋과 같은 해시 — 해당 커밋에 본 두 파일 변경이 함께 staged 되어 한 커밋으로 기록됨. 문맥상 invite 도메인 변경은 별도지만, 커밋 이력 단일성을 해치지 않기 위해 이 §7.33 엔트리로 독립 기록을 남긴다.
- 두 화면의 `CircleAvatar`/`Icon` 기하 요소는 의도적으로 제외 — 이니셜·아이콘은 기호이지 제목이 아니므로 §7.30 과 동일 원칙 유지.

**검증**:
- `flutter analyze lib/features/invite/presentation/screens/invite_screen.dart lib/features/invite/presentation/screens/code_input_screen.dart` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 오선지 앞부분의 "Tempo di Minuetto" 표기와 그 아래 "dolce" 표기. 장르·속도 표기(appBarTitle) 는 이미 세리프로 격식을 갖추고 있었지만, 본문 첫 마디 위의 연주 지시(QR 코드·본문 헤딩) 까지 같은 서체로 맞추자 비로소 한 악장이 하나의 펜으로 필사된 인상이 남는다.

---

### 7.34 BottomSheet 테마 통일 — 61개 모달 시트에 paper 표면·flat elevation 단일 지점 보급

**배경**: 앱 전반에서 `showModalBottomSheet` 는 61개 호출부에 퍼져 있지만, `app_theme.dart` 에는 `bottomSheetTheme` 자체가 비어 있어 Material 기본값(흰 배경·elevation 1·M3 surfaceTint) 이 노출됐다. 많은 호출부가 `backgroundColor: Colors.transparent` 를 인라인으로 지정해 시트 내부 Card/Container 가 배경을 그리는 패턴으로 우회했지만, 그 인라인 지정이 없는 호출부(debug 롤 스위처·booking_cancel·auth 바텀시트·practice·parent_home 등 다수) 는 여전히 흰 사각 모달로 남아 Notebook 페이퍼 질감이 끊겼다. §7.29 AppBar·§7.31 Chip·§7.32 ExpansionTile 에 이어 **"Material 기본값이 보라/흰 잔재를 드러내는 마지막 큰 모달 창"** 을 전역 테마로 수렴할 시점.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `core/theme/app_theme.dart` (light) | `bottomSheetTheme: BottomSheetThemeData(backgroundColor: paper, modalBackgroundColor: paper, surfaceTintColor: transparent, modalBarrierColor: black54, elevation: 0, modalElevation: 0, dragHandleColor: inkQuaternary, shape: RoundedRectangleBorder(BorderRadius.vertical(top: radiusLarge)))` 추가 | 30f354ac |
| `core/theme/app_theme.dart` (dark) | 같은 구조로 `backgroundColor/modalBackgroundColor: surfaceDark`, `dragHandleColor: borderDark`, `modalBarrierColor: black87` | 30f354ac |

**영향 범위**: 61개 `showModalBottomSheet` 호출부. 그중 인라인 `backgroundColor: Colors.transparent` 를 지정한 호출부(subscription·auth·lessons·schedule·invite 등 다수) 는 기존 거동 그대로 — 시트 내부 컨테이너가 Notebook 배경을 직접 그리는 계약이 깨지지 않는다. 인라인 지정이 없는 호출부(debug_role_switcher·booking_cancel_screen·schedule_timeline_view·terms_agreement·login_bottom_sheets·students_tab·student_detail·lesson_time_settings·bank_account_edit·repertoire_management·quick_feedback·lesson_student_picker·parent_home 시리즈·practice 편집 화면들·onboarding 프로필 셋업 등 20+ 호출부) 는 흰 배경이 `paper` 로 자동 승격된다.

**설계 포인트**:
- `backgroundColor` 와 `modalBackgroundColor` 를 같은 값으로 쌍으로 지정. Flutter 의 BottomSheetThemeData 는 일반 persistent sheet(`backgroundColor`) 와 modal sheet(`modalBackgroundColor`) 를 분리 제어하는데, 앱에서는 둘 다 Notebook paper 표면이 맞으므로 동시에 묶는다.
- `surfaceTintColor: Colors.transparent` — Material 3 의 overlay tint(primary 색 기반) 제거. Notebook 은 elevation 이 0 이어야 하므로 tint 자체가 무의미하며, 남겨두면 미세한 보라 잔재가 시트 상단에 번진다.
- `elevation: 0` / `modalElevation: 0` — Notebook 은 종이 한 장이 책상 위로 올라오는 flat 인상. 그림자는 `modalBarrierColor` 가 대신 맡는다.
- `shape: RoundedRectangleBorder(BorderRadius.vertical(top: radiusLarge))` — 하단이 화면에 붙은 시트 특성상 상단만 12px 라운드. §7 의 Card 전역 `radiusLarge` 와 동일 값으로 모달 모서리 위계를 시트까지 연장.
- `dragHandleColor` 는 light 에서 `inkQuaternary` (25% 알파 잉크) 로 중립, dark 에서는 같은 알파가 표면과 구분이 약해서 `borderDark` 로 한 단계 올림.
- `modalBarrierColor` 는 Material 기본 `black54` 를 light 에 유지하되, dark 에서는 `black87` 로 심화 — 어두운 표면 위 시트가 뜰 때 배경과의 거리감을 확보.

**호환성**:
- 인라인 `backgroundColor: Colors.transparent` 는 테마 기본값을 덮어쓰므로 기존 "내부 컨테이너가 배경 담당" 패턴은 변형 없음. 회귀 0.
- 일부 호출부(`my_connections_screen` 등) 가 인라인 `shape: RoundedRectangleBorder(...)` 을 직접 지정한 곳은 호출부 오버라이드가 우선 — 향후 Cycle 에서 인라인 shape 를 제거해 테마로 일원화하는 정리가 가능하나, 이번 턴은 편집 범위 최소화 원칙에 따라 인라인 지정을 보존.
- `surfaceTintColor` 와 `elevation` 은 기존 인라인 지정이 없던 속성이라 테마 설정이 그대로 적용 — 이 지점이 이번 턴의 실질 효과가 가장 큰 속성.

**검증**:
- `flutter analyze` → No issues found
- `flutter test` → 392/392 passed (regression 0)
- 정성 검증 기대치: `backgroundColor: Colors.transparent` 없이 호출되는 20+ 모달(debug 롤 스위처·예약 취소·약관 동의·요일 설정 편집 시트 등) 의 배경이 Notebook paper 로 전환됨. 인라인 transparent 호출은 시트 내부 컨테이너가 배경 담당 — 기존 거동 유지.

**은유**: 책상 위에 올려놓은 낱장 악보. 어떤 장(chapter) 에서 꺼내든 같은 갱지 톤이 깔리고, 모서리는 같은 반경으로 둥글며, 그 아래 책상 면은 같은 어조로 어두워진다. 장(章) 마다 다른 흰 포스트잇을 쓰던 상태에서, 한 권의 필사본으로 모이는 전환.

---

### 7.35 FilledButton 테마 통일 — 74개 CTA 에 Vermillion 단일 지점 보급

**배경**: M3 `FilledButton` 은 앱 전반의 1차 행동(예약 요청, 취소, 저장, 로그인, 결제 등) 74개 호출부에서 쓰이고 있었다. 그 중 21개 는 `style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent)` 를 인라인으로 반복 — 같은 의도를 각 화면이 독자적으로 표현 중. `filledButtonTheme` 이 `app_theme.dart` 에 미등록이었기 때문에, 오버라이드 없는 53개 호출부는 M3 colorScheme.secondary 폴백을 받아 미세한 색조 편차가 누적됐다.

**변경**: `app_theme.dart` 에 `filledButtonTheme` 을 light/dark 각 1회씩 등록 — `elevatedButtonTheme` 시그니처를 미러링하여 두 CTA 계열의 구조 통일.

| 위치 | 설정 | 의도 |
|------|------|------|
| light `filledButtonTheme` | `backgroundColor: paperAccent` · `foregroundColor: paper` · `elevation 0` · `minimumSize(infinity, buttonHeight)` · `shape: radiusLarge` · `textStyle: AppTypography.button` | Notebook Vermillion CTA 기본값. 21개 인라인 오버라이드와 동일 — 중복 제거 후에도 시각적 결과 동일 |
| dark `filledButtonTheme` | 동일 (paperAccent/paper) | dark surface 위에서도 Vermillion 유지 — 테마 전환 시 CTA 색 불변 보장 |
| 커밋 | `f69f2a70` | |

**영향 범위**: 74개 FilledButton 호출부 전체가 영향을 받는다.

- **21개** 인라인 `backgroundColor: paperAccent` 호출부: 테마가 동일 색을 기본값으로 제공하므로 인라인 오버라이드는 중복(추후 §7.36 cleanup 대상 후보) — 지금은 그대로 유지해 회귀 0
- **53개** 오버라이드 없는 호출부: Material 기본 secondary 대신 Notebook paperAccent 로 **자동 승격** — 특히 `recording_diagnostic_screen`, `booking_reschedule_screen`, `payment_guide_bottom_sheet`, `approval_bottom_sheet` 등 바텀시트 계열의 주요 CTA 가 일관된 Vermillion 으로 수렴
- 개별 호출부에서 `FilledButton.styleFrom(backgroundColor: ...)` 을 다른 색으로 덮어쓰는 경우(예: 파괴적 액션에 다른 강조) 는 인라인 우선 규칙으로 그대로 유지

**설계 포인트**:

- `minimumSize: Size(double.infinity, AppSpacing.buttonHeight)` — ElevatedButton 과 동일. Row/Expanded 래퍼 안에서만 호출되는 패턴에서 안전하게 폭 제약을 따르고, 단독 호출 시 full-width Notebook CTA 형태가 기본.
- `elevation: 0` — Notebook flat 원칙. 그림자 대신 색상 강도(paperAccent) 로만 주목도 확보.
- `shape: RoundedRectangleBorder(BorderRadius.circular(radiusLarge))` — Card/BottomSheet 와 동일 반경. 버튼이 카드 위에 올라갈 때 모서리 대칭.
- `textStyle: AppTypography.button` — Inter(또는 기본 sans) 의 CTA 라벨. CTA 계열(Elevated/Filled/Outlined) 타이포 통일.
- light = dark 동일 CTA 색상 — colorScheme.secondary 를 paperAccent 로 통일해둔 §5 결정을 버튼 테마에서 강제. Vermillion 은 두 배경(paper/surfaceDark) 모두에서 WCAG AA 수준의 대비 확보.

**호환성 / 회귀 범위**:

- 인라인 `backgroundColor: paperAccent` 오버라이드는 Flutter 속성 우선순위(inline > theme)에 따라 동일 결과 — 회귀 0
- 인라인 다른 색 오버라이드(예: 상태별 warning/success) 역시 유지
- `FilledButton.icon()` variant 은 동일 테마 상속 — 아이콘 포함 버튼도 자동 승격
- 정성 검증 기대치: 오버라이드 없는 `recording_diagnostic_screen` · `schedule_change_slot_screen` 등의 FilledButton 이 M3 secondary 대신 Notebook Vermillion 으로 렌더. 기존 paperAccent 인라인 호출부는 변화 없음.

**검증**: `flutter analyze` 0 issues · `flutter test` 392/392 passed.

**은유**: 한 권의 악보집에서 모든 '강한 강조 마디' 가 같은 붉은 잉크로 찍혀 있는 상태. 서로 다른 페이지에서 붉은 색을 섞던 작업자가 한 자리에 모여 한 병의 Vermillion 잉크를 쓰기 시작한 전환.

---

### 7.36 녹음 시트·시작 가이드·주간 랭킹 카드 제목 Playfair 통일

**배경**: §7.34 의 BottomSheet 전역 테마가 모달 표면 톤을 paper 로 일원화했지만, 정작 그 시트 **안쪽 커스텀 헤더 제목**과 카드 내부 **섹션 제목**은 여전히 `AppTypography.headingSmall` (Pretendard 18/w600) 로 남아 있는 지점이 세 군데 있었다. 선생님이 시범 녹음을 올리는 `AddRecordingResourceSheet`, 학생 홈의 `StudentGettingStartedCard`, 클래스 리더보드의 `WeeklyRankingCard` — 모두 바깥 표면·CTA 는 Notebook 팔레트로 전환됐는데 제목만 산세리프라 페이퍼 위 서체 위계가 끊겨 있었다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/lessons/presentation/widgets/add_recording_resource_sheet.dart` | 바텀시트 커스텀 헤더 `'시범 연주 녹음 추가'` `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`. `notebook_typography` import 추가 | 34b44fc4 |
| `features/student_home/presentation/widgets/student_getting_started_card.dart` | 시작 가이드 카드 제목 `'시작 가이드'` `AppTypography.headingSmall.copyWith(color: AppColors.ink)` → `NotebookTypography.sectionTitle.copyWith(color: AppColors.ink)`. `notebook_typography` import 추가 | 34b44fc4 |
| `features/gamification/presentation/widgets/weekly_ranking_card.dart` | 주간 랭킹 카드 제목 `AppStrings.weeklyRanking` `AppTypography.headingSmall.copyWith(color: AppColors.ink)` → `NotebookTypography.sectionTitle.copyWith`. `notebook_typography` import 추가 | 34b44fc4 |

**설계 포인트**:
- **두 위계의 분리 적용**: 바텀시트 커스텀 헤더(`add_recording_resource_sheet`) 는 §7.27 의 "커스텀 헤더 = `appBarTitle` 재사용" 패턴을 따르고, 카드 내부 섹션 제목(`student_getting_started_card`·`weekly_ranking_card`) 은 §7.17 의 "섹션 헤더 = `sectionTitle`" 패턴을 따른다. 두 파일이 Row 안에서 아이콘(`rocket_launch_rounded`·tier emoji) 과 병치되지만, 아이콘은 §7.30 원칙대로 제목이 아니므로 제외.
- **`.copyWith(color: AppColors.ink)` 보존**: 두 카드 모두 헤더 색을 의도적으로 `ink` 로 낮춰 본문 톤과 맞췄다. `NotebookTypography.sectionTitle` 자체는 기본 잉크 색이지만 `.copyWith` 체인을 제거하지 않고 유지 — 향후 다크 모드 대응이나 상태별 색 변조(비활성 회색 등) 가 들어올 여지를 같은 체인 안에서 관리한다.
- **주간 랭킹 tier emoji 는 `headingMedium` 그대로**: 🥇🥈🥉 는 `headingMedium` 으로 크기만 맞춘 기호 열이라 Playfair 대상이 아니다. `_tierEmoji` 는 `RankingTier` enum → 이모지 매핑으로, 서체가 아니라 글리프 자체가 의미를 전달한다.
- **바텀시트 배경·CTA 와의 조합**: §7.34 커밋으로 `AddRecordingResourceSheet` 배경은 `paper` 로 자동 승격됐고, §7.35 커밋으로 그 안의 FilledButton 이 Vermillion 으로 전환됐다. 이번 턴에 헤더 제목이 Playfair 로 마감되면서, 시트가 올라올 때 "갱지 + Playfair 제목 + 닫기 아이콘 + Vermillion CTA" 순으로 Notebook 4대 시그니처가 한 시트 안에 한 번에 드러난다.

**검증**:
- `flutter analyze lib/features/lessons/presentation/widgets/add_recording_resource_sheet.dart lib/features/student_home/presentation/widgets/student_getting_started_card.dart lib/features/gamification/presentation/widgets/weekly_ranking_card.dart` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 세 개의 서로 다른 연습실 — 선생님 책상 위의 녹음 부스, 학생의 첫 수업 입구, 교실 벽의 주간 기록판. 바닥과 벽은 이미 같은 갱지로 발라졌지만, 각 방 문패만 유독 고딕체 인쇄물이었다. 세 문패를 한 번에 세리프로 필사해 붙이자, 세 공간이 같은 악보 속 서로 다른 악장처럼 읽히기 시작한다.

---

### 7.36 IconButton 테마 등록 — 175개 아이콘 버튼 기본색 ink 승격

**배경**: `iconButtonTheme` 이 등록되지 않아 Material 3 이 `colorScheme.onSurfaceVariant` 기본값으로 폴백. 현재 colorScheme 은 primary/secondary/surface/error 만 명시하고 `onSurfaceVariant` 는 미지정 상태 — M3 의 회색 슬레이트 폴백(`#49454E` 계열) 이 적용되어 Notebook 잉크 팔레트(`ink = #1A1A2E`) 와 미세한 색상 이질감. `IconButton()` 실사용 164건 + `.filled`/`.outlined`/`.styleFrom` 변형 11건 = 175건 중 인라인 `icon: Icon(..., color: ...)` 오버라이드 21건을 제외한 다수가 이 폴백 색상에 의존.

**변경**: `lib/core/theme/app_theme.dart` 라이트/다크 각 블록의 `iconTheme` 직후에 `iconButtonTheme` 삽입.

| 테마 | 위치 | foregroundColor |
|---|---|---|
| light | `iconTheme` 직후 (329 라인대) | `AppColors.ink` |
| dark | `iconTheme` 직후 (790 라인대) | `AppColors.textPrimaryDark` |

커밋: `1b2b3bbf`.

**영향 범위**: 175 IconButton 호출부 — 21개 인라인 `icon: Icon(..., color: paperAccent/white/...)` 오버라이드는 Flutter 의 Icon `color:` 속성이 부모 IconTheme 보다 우선하므로 불변. **나머지 154개 호출부가 M3 회색 슬레이트 폴백 → Notebook `ink`/`textPrimaryDark` 로 자동 승격**.

**설계 포인트**:
- `foregroundColor` 만 지정 — `size`/`shape` 는 기본값 유지(M3 40x40 tap target, default 24px icon size 는 `iconTheme.size` 가 담당)
- `appBarTheme.foregroundColor == ink` (light) / `textPrimaryDark` (dark) 와 정확히 일치 → AppBar actions 내부 IconButton 이 AppBar IconTheme 과 동일 색으로 렌더링되어 라이트/다크 전환 시 이질감 제거
- M3 버튼 패밀리 테마 5종(`ElevatedButtonThemeData` · `FilledButtonThemeData` · `OutlinedButtonThemeData` · `TextButtonThemeData` · `IconButtonThemeData`) **전체 등록 완료** — 버튼 단일 지점 테마 통일 작업 마무리

**호환성**:
- 인라인 `color:` 오버라이드(21건) 회귀 0 — 속성 우선순위상 Icon 의 color 가 IconTheme 보다 우선
- `IconButton.filled` (9건) / `IconButton.outlined` (2건) 변형도 동일한 `IconButton.styleFrom` 을 상속하므로 foregroundColor 자동 전파
- 이미 적용된 `iconTheme: IconThemeData(color: ink)` 과 이중으로 동일 색을 지정 — Flutter 는 IconButton 내부에서 styleFrom 값을 우선 적용하지만 둘 다 `ink` 이므로 동일 결과

**검증**:
- `flutter analyze` → 0 issues
- `flutter test` → 392/392 passed

**은유**: 같은 악보집 전체가 이미 같은 잉크로 필사되어 있었지만, 페이지 하단의 작은 연습번호(♯)만 유독 연필 흑연 색으로 남아 있었다. 한 줄의 테마 등록으로 그 작은 부호들까지 같은 잉크로 덮어쓰자, 종이 위 모든 글자와 기호가 비로소 같은 한 사람이 한 번에 써 내려간 것처럼 읽힌다.

---

### 7.37 외부 링크·AI 노트·일정 변경·검색 필터 바텀시트 제목 Playfair 통일

**배경**: §7.34 가 61개 바텀시트의 **표면 톤**을 paper 로 단일화하고 §7.36(녹음 시트·시작 가이드·주간 랭킹 카드) 이 일부 커스텀 헤더를 Playfair 로 옮겼지만, 네 개의 자주 쓰이는 바텀시트 — 선생님이 교재 링크를 추가하는 `AddExternalLinkSheet`, AI 가 생성한 노트를 확인하는 `AiNotesResultSheet`, 단일/일괄 일정 변경을 선택하는 `ScheduleChangeTypeBottomSheet`, 선생님 검색 결과를 좁히는 `TeacherSearchFilterSheet` — 의 **커스텀 헤더 제목**은 여전히 `AppTypography.headingSmall` (Pretendard 18/w600) 로 남아 있었다. 종이 표면 위에 산세리프 제목만 떠 있는 상태였다.

| 파일 | 변경 | 커밋 |
|------|------|------|
| `features/lessons/presentation/widgets/add_external_link_sheet.dart` | 바텀시트 헤더 `'외부 링크 추가'` `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`. `notebook_typography` import 추가 | c708bef8 |
| `features/lessons/presentation/widgets/ai_notes_result_sheet.dart` | 바텀시트 헤더 `'AI 레슨 노트'` `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`. `auto_awesome` 아이콘과 `Save` TextButton 은 §7.30 에 따라 유지 | c708bef8 |
| `features/schedule/presentation/widgets/schedule_change_type_bottom_sheet.dart` | 바텀시트 헤더 `AppStrings.scheduleChangeTypeTitle` `AppTypography.headingSmall` → `NotebookTypography.appBarTitle` | c708bef8 |
| `features/search/presentation/widgets/teacher_search_filter_sheet.dart` | 바텀시트 헤더 `'필터'` `AppTypography.headingSmall` → `NotebookTypography.appBarTitle`. `NotebookTypography.appBarTitle` 은 getter 이므로 `Text` 의 `const` 제거 | c708bef8 |

**설계 포인트**:
- **§7.27 패턴 일관 적용**: 네 파일 모두 `showModalBottomSheet` 안에서 헤더 `Row` 를 직접 만들어 `Text(..., style: AppTypography.headingSmall)` 과 닫기 버튼/초기화 버튼/저장 버튼을 `spaceBetween` 으로 정렬한 전형적 커스텀 헤더다. 별도 분기 없이 §7.27 의 "커스텀 헤더 = `appBarTitle` 재사용" 패턴을 그대로 적용한다.
- **`const Text` 제거 이유**: `NotebookTypography.appBarTitle` 은 `TextStyle` getter(런타임 평가)이므로 `Text` 를 `const` 로 선언하면 컴파일 에러. `teacher_search_filter_sheet.dart:62` 에서 `const` 만 제거하고 나머지 구조는 유지.
- **아이콘·액션 버튼은 §7.30 제외**: `Icons.auto_awesome`(AI 노트), `Icons.close`(외부 링크), `TextButton('초기화')`(필터), `TextButton('저장')`(AI 노트)는 제목이 아닌 심볼·액션이므로 Playfair 적용 대상이 아니다. §7.30 의 아이콘·제스처 제외 규칙을 그대로 따른다.
- **네 시트의 역할 다양성**: 생성(외부 링크 추가), 결과 확인(AI 노트), 선택(일정 변경 타입), 필터(검색 필터) — 네 가지 다른 상호작용 유형이지만 모두 "페이퍼 표면 위의 한 행짜리 제목" 이라는 공통 골격을 가진다. 한 번의 치환으로 역할별 색채는 유지하되 서체 계보만 통일된다.

**검증**:
- `flutter analyze [4 files]` → 0 issues
- `flutter test test/` → 392/392 passed

**은유**: 네 개의 서로 다른 작업대 — 악보 보관함의 링크 바인더, AI 가 타이핑을 마친 노트 패드, 일정표의 분기 결정판, 선생님 명부의 필터 카드. 각자 다른 상호작용을 담고 있지만 이제 모두 같은 캘리그래퍼의 손글씨로 "제목"이 적혀 있다. 종이 위의 Playfair 는 표지의 위엄이 아니라 그 아래 모든 행위에 같은 사람이 책임지고 있다는 표시다.

---

### 7.38 Dialog 테마 등록 — 312개 AlertDialog 에 paper 표면·flat radius 단일 지점 보급

**배경**: `app_theme.dart` 의 `dialogTheme` 이 light/dark 모두 `titleTextStyle` 만 등록되어 있었다(§7.29 이후 Playfair 통일). 그러나 `backgroundColor` / `shape` / `surfaceTintColor` / `elevation` 은 모두 미등록 상태로 Material 3 기본값(`colorScheme.surfaceContainerHigh` 회색 tint + radius 28 + elevation 6)으로 폴백되던 상태. 결과적으로 Notebook 팔레트가 지정되지 않은 `colorScheme` 의 파생값이 회색 틴트를 남기고, 모서리는 과도하게 둥근 M3 pillowy 형태로 `BottomSheet`(radiusLarge=20) 와 시각적으로 분리되어 있었다.

**변경**:

| 속성 | Light 등록값 | Dark 등록값 | 설계 근거 |
|---|---|---|---|
| `backgroundColor` | `AppColors.paper` | `AppColors.surfaceDark` | `bottomSheetTheme` 와 동일한 modal 표면 팔레트 — 라이트/다크 전환 시 Dialog↔BottomSheet 일관성 |
| `surfaceTintColor` | `Colors.transparent` | `Colors.transparent` | M3 기본 primary tint 제거 — Notebook 팔레트 외 색 섞임 차단 |
| `elevation` | `0` | `0` | Flat Notebook 평면 유지 — 종이 위에 떠 있는 카드가 아닌 한 장의 인서트 |
| `shape` | `RoundedRectangleBorder(radiusLarge)` | `RoundedRectangleBorder(radiusLarge)` | `cardTheme` / `bottomSheetTheme` 와 radius 통일 (20px). M3 기본 radius 28 보다 타이트 |
| `titleTextStyle` | `NotebookTypography.dialogTitle` (유지) | `dialogTitle.copyWith(color: textPrimaryDark)` (유지) | §7.29 에서 등록한 Playfair 19 / w700 유지 |

커밋: `6538805b`.

**영향 범위**: 전 코드베이스 `AlertDialog` / `showDialog` / `Dialog` 호출 **312건 (79 파일)**. 이 중 라이트 배경·flat·radius 를 인라인으로 명시한 호출은 거의 없었고, 대부분은 M3 기본값으로 구성되어 Notebook 질감이 끊겼다. 테마 단일 지점 등록으로 312개 모두 자동 승격. Dialog 내부 컨테이너가 자체 배경을 그리는 예외 호출부가 있다면 Flutter 의 속성 우선순위(지정된 `backgroundColor:` 인라인 오버라이드가 우선)로 회귀 없음.

**설계 포인트**:
1. **`bottomSheetTheme` 와 시그니처 통일** — 두 modal 표면(Dialog · BottomSheet)이 같은 `paper` / `surfaceDark` + `elevation 0` + `surfaceTintColor transparent` + `shape radiusLarge` 를 공유. 사용자가 어느 modal 을 열어도 같은 종이 질감.
2. **`cardTheme` 와 radius 통일** — Notebook 의 모든 paper 표면은 `AppSpacing.radiusLarge` (20px) 로 수렴. M3 기본 Dialog radius 28 은 Notebook 프레임(3px 여백 + serif 타이포그래피)과 시각적으로 부정합.
3. **최소 추가 속성** — `titleTextStyle` 외에 `contentTextStyle` 은 의도적으로 미등록. Dialog 본문은 화면별로 `Text` / `Column` 등 커스텀 렌더링이 많아 전역 스타일 고정은 오히려 방해. 본문은 Material 의 `textTheme.bodyMedium` 기본값에 맡기고 표면·형태만 Notebook 으로 정렬.
4. **`titleTextStyle` 은 기존 값 그대로** — §7.29 에서 이미 Playfair 로 통일된 상태. 이번 추가는 모든 Dialog 가 이 제목 스타일 위에 **Notebook 종이 질감도 함께** 입도록 완성.

**호환성**:
- Dialog 호출부에서 `backgroundColor:` / `shape:` / `surfaceTintColor:` / `elevation:` 을 인라인으로 이미 지정한 경우는 Flutter 의 속성 우선순위로 그대로 유지됨 → 회귀 0.
- `DialogThemeData` 는 `AlertDialog` · `Dialog` · `showDialog` 의 자식 `Dialog` 위젯 모두에 적용됨. 커스텀 Dialog subclass 도 `Theme.of(context).dialogTheme` 을 참조하면 자동 승격.

**검증**:
- `flutter analyze` → 0 new issues (기존 4건 unused_import 경고는 무관한 다른 파일)
- `flutter test` → 392/392 passed

**마일스톤**: 이로써 Notebook × Score 의 **3대 표면 테마(Card · BottomSheet · Dialog)** 가 모두 동일한 paper/surfaceDark + elevation 0 + radiusLarge + surfaceTintColor transparent 시그니처로 수렴했다. 앞으로 새로 추가되는 Dialog 호출부는 명시적 오버라이드 없이도 Notebook 질감을 갖는다.

**은유**: 악보집 사이에 끼워 넣는 인서트 카드. 표지(BottomSheet)도, 본문(Card)도, 때때로 손에 들어 올리는 확인서(Dialog)도 모두 같은 크림색 종이에 같은 모서리 둥글기를 가진다. 펼쳐볼 때마다 "이것도 같은 책에서 나왔다"는 감각. M3 의 기본 회색 틴트는 다른 제조사의 인서트처럼 이 일관성을 깨뜨리던 참이었다.

---

### 7.39 연습 통계·뱃지·정책 시트 섹션 제목 Playfair 통일

**배경**: §7.17 sectionTitle 패턴은 카드 내부 섹션 제목이 아이콘과 함께 소분류를 구분할 때 쓰는 축소판 Playfair 표기다. `AppTypography.headingSmall` 로 남아 있던 통계 카드 4종 + 뱃지 콜렉션 + 정책 시트의 섹션 제목을 §7.17 로 이관해 화면 간 섹션 리듬을 일치시킨다.

**변경표**:

| 파일 | 라인 | 제목 | 변경 전 | 변경 후 |
|---|---|---|---|---|
| `practice/widgets/stats/daily_bar_chart.dart` | 46 | 일별 연습 시간 | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` |
| `practice/widgets/stats/stats_summary_card.dart` | 38 | 요약 | 동상 | 동상 |
| `practice/widgets/stats/weekly_trend_chart.dart` | 46 | 주간 트렌드 | 동상 | 동상 |
| `practice/widgets/stats/repertoire_stats_list.dart` | 50 | 레퍼토리별 연습 | 동상 | 동상 |
| `gamification/screens/badge_collection_screen.dart` | 55 | 획득한 뱃지 | 동상 | 동상 |
| `gamification/screens/badge_collection_screen.dart` | 63 | 포인트 히스토리 | 동상 | 동상 |
| `subscription/widgets/subscription_policy_sheet.dart` | 105 | 적용 정책 | `headingSmall.copyWith(color: paperAccent)` | `NotebookTypography.sectionTitle.copyWith(color: paperAccent)` |

**설계 포인트**:
- **§7.17 일관 적용**: 아이콘 + 섹션 제목 조합(`Row > Icon + Text`)의 Text 는 전부 `NotebookTypography.sectionTitle` 로 고정한다. 이 패턴은 연습 통계, 뱃지, 정책 세 모듈에서 서로 다른 맥락이지만 "같은 크기의 소제목" 이라는 시각적 리듬이 유지돼야 한다.
- **§7.30 제외 항목 엄수**: `stats_summary_card` 의 수치 `value` 와 `badge_collection_screen` 의 `data.levelTitle` 은 동적 데이터 값이라 제목이 아닌 **stat value** 성격이다. §7.30 기준(수치·이니셜·동적 값은 타이틀이 아니다)에 따라 `AppTypography.headingSmall.copyWith(...)` 를 유지한다. `Icons.bar_chart`, `Icons.insights`, `Icons.trending_up`, `Icons.library_music`, `Icons.description` 같은 아이콘도 그대로 둔다.
- **copyWith 체인 유지**: `subscription_policy_sheet` 는 `paperAccent` 강조색을 얹는 패턴이라 `NotebookTypography.sectionTitle.copyWith(color: ...)` 로 체인을 그대로 옮긴다. sectionTitle 기저에 있는 Playfair Display 17/w700 은 `fontFamily` 필드가 copyWith 로 덮이지 않는 한 유지된다.
- **모듈 간 중첩 패턴**: 통계(daily/weekly/summary/repertoire)는 네 개의 서로 다른 카드이지만 전부 동일 구조 — 아이콘 → space2 → 제목 → space4 → 본문 — 로 짜여 있다. 한 번의 §7.17 적용이 네 카드의 헤더 질감을 한 번에 일치시킨다.

**검증**:
- `flutter analyze` (6 files) → No issues found
- `flutter test` → 392/392 passed
- Lore commit: `aa0fb419`

**은유**: 연습 통계는 매일 열어 보는 장부다. "요약", "일별", "주간", "레퍼토리별" 이라는 네 개의 탭 헤더가 동일한 펜촉으로 쓰여 있어야 장부 전체가 한 사람의 필체로 읽힌다. §7.17 은 이 "같은 펜촉" 을 강제하는 규칙이고, 오늘 배치는 네 카드가 서로 다른 잉크병에서 뽑혀 나오던 흔적을 마지막으로 정리했다.

---

### 7.40 FloatingActionButton 테마 등록 — 18개 확장 FAB 에 Vermillion·flat 단일 지점 보급

**배경**: `.extended` FAB 는 목록 화면의 "추가" 동선에 집중적으로 쓰인다(레슨 예약·스케줄 추가·수강권 템플릿·결제·계좌·곡·템플릿·섹션 등). 그러나 `floatingActionButtonTheme` 가 미등록인 상태에서 15개 파일 18개 호출부 중 6개만 인라인 `backgroundColor: AppColors.paperAccent` 를 지정했고, 나머지 9개는 M3 기본값 `colorScheme.primaryContainer`(→ inkQuaternary 회색)로 폴백돼 Notebook Vermillion CTA 시그니처가 끊겼다. filledButtonTheme(§7.35)·dialogTheme(§7.38)·bottomSheetTheme(§7.34)·cardTheme 와 함께 "네 번째 표면·CTA 테마" 로 통일할 차례.

**변경** (`lib/core/theme/app_theme.dart`, +37/-0 lines, light/dark 양쪽 등록):

| 속성 | light | dark | 비고 |
|---|---|---|---|
| `backgroundColor` | `paperAccent` | `paperAccent` | Vermillion — filledButtonTheme 와 시그니처 통일 |
| `foregroundColor` | `paper` | `paper` | 크림 라벨 — 밝은 톤 유지 |
| `elevation` + 4개 상태 | 0 | 0 | focus/hover/highlight/disabled 모두 0 — cardTheme·bottomSheetTheme·dialogTheme flat 질감과 일치 |
| `extendedTextStyle` | Inter w600 paper | Inter w600 paper | `.extended` 라벨은 UI 단문이라 Playfair 대신 Inter Medium |
| `shape` | (기본 StadiumBorder) | (기본 StadiumBorder) | Notebook ticket/pill 형태와 조화 — 명시 생략 |

**영향 범위**: `FloatingActionButton.extended` 18개 호출 / 15개 파일.

| 상태 | 파일 수 | 동작 |
|---|---|---|
| 인라인 `backgroundColor: paperAccent` 보유 | 6 | 속성 우선순위로 유지 — 회귀 0 |
| 인라인 오버라이드 없음 | 9 | M3 기본(primaryContainer) → Vermillion 자동 승격 |

주요 승격 대상 호출부:
- 프로필 관리 FAB 3개: `tip_template_management_screen.dart`, `repertoire_management_screen.dart`, `payment_management_screen.dart`, `bank_account_edit_screen.dart` (계좌)
- 연습 섹션 FAB 3개: `add_section_screen.dart`, `edit_section_screen.dart`, `quick_add_screen.dart`
- 학생 상세 FAB: `student_detail_screen.dart`(레슨 예약) — 이미 오버라이드 없음 → Vermillion 승격 핵심 수혜 화면

**설계 포인트**:

1. **4개 elevation 상태 모두 0**: `elevation`·`focusElevation`·`hoverElevation`·`highlightElevation`·`disabledElevation` 를 전부 0 으로 고정. M3 FAB 기본값은 6/8/8/8/0 이라 눌림·포커스 시 그림자가 튀어 올라 cardTheme/bottomSheetTheme/dialogTheme 의 flat 합창과 어긋났다. Notebook 은 "종이 위에 붙은 스티커" 느낌이 아니라 "종이에 직접 쓴 도장" 느낌.
2. **extendedTextStyle 은 Inter w600**: 라벨이 짧은 UI 단문("레슨 예약", "곡 추가", "계좌 추가")이라 Playfair Display 보다 Inter Medium/Semibold 가 가독성이 높다. `bodyMedium.copyWith(fontWeight: w600, color: paper)` — bottomNavigationBar 의 selectedLabel 과 동일 로직.
3. **shape 미지정**: `.extended` 의 기본 `StadiumBorder()` 는 이미 Notebook ticket/pill 형태와 일치 — 명시 등록해 오버라이드하면 `.small`/`.large`/기본 FAB 파생 형태가 깨진다(현재 사용되지 않지만 향후 확장 대비).
4. **파생 변형 고려**: 현재 전체 코드베이스에서 `FloatingActionButton.small`/`.large`/기본 생성자 사용이 0건 — 오직 `.extended` 만 사용. 향후 `.small` 추가 시에도 같은 Vermillion 시그니처로 자동 승격.

**호환성**: Flutter 속성 우선순위로 인라인 오버라이드 6건은 그대로 유지. 9건의 오버라이드 없는 호출부만 승격.

**검증**:
- `flutter analyze` → No issues found (14.8s)
- `flutter test` → 392/392 passed (5s)
- Lore commit: `8e5ad822`

**마일스톤**: Notebook × Score **4대 표면·CTA 테마(Card · BottomSheet · Dialog · FAB)** 단일 지점 수렴 완료. 추가 모달·플로팅 표면은 이 네 테마 중 가장 가까운 시그니처를 기준점으로 확장.

**은유**: 플로팅 액션 버튼은 노트 귀퉁이에 붙인 빨간 포스트잇이다. 15개 장부(화면) 중 6개만 빨간색, 9개는 연필로 얇게 칠한 회색으로 섞여 있던 기존 상태는 "이 노트를 쓴 사람이 다섯 명쯤 있나?" 라는 질문을 만든다. 오늘 테마는 15개 귀퉁이에 모두 같은 버밀리언 인주를 찍어 한 사람이 같은 손으로 노트를 정리하고 있음을 증명한다.

---

### 7.41 FloatingActionButton 인라인 override cleanup — §7.40 이후 중복 제거

**배경**: §7.40에서 `floatingActionButtonTheme` 를 등록해 18개 `.extended` FAB 전부에 Vermillion + paper + elevation 0 시그니처를 자동 공급했다. 그러나 6개 호출부(`backgroundColor: paperAccent` 3건 + `Colors.white` 라벨 강제 3건 + `foregroundColor: Colors.white` 1건이 4개 파일에 중첩)는 여전히 인라인 오버라이드를 유지해 테마를 가리고 있었다. Flutter 속성 우선순위에 따라 인라인이 테마를 덮어 쓰므로, 테마가 의도한 `paper` 라벨(크림 `0xFFF2ECDD`)이 아니라 pure `Colors.white (0xFFFFFFFF)` 가 라벨로 고정돼 있었다.

**변경**:

| 파일 | 제거 |
|------|------|
| `features/schedule/presentation/screens/weekly_schedule_screen.dart` | `backgroundColor: paperAccent` · `Icon(color: white)` · `Text(style: copyWith(white))` |
| `features/schedule/presentation/screens/time_exception_screen.dart` | 동일 3건 |
| `features/subscription/presentation/screens/subscription_template_list_screen.dart` | 동일 3건 |
| `features/invite/presentation/screens/my_connections_screen.dart` | `backgroundColor: paperAccent` · `foregroundColor: Colors.white` |

**영향 범위**: 4개 화면(주간 스케줄·휴무 예외·수강권 템플릿·내 연결)의 `.extended` FAB 이 §7.40 테마의 `paperAccent + paper + Inter w600 + elevation 0` 시그니처로 자동 복귀. 라벨 색이 pure white 에서 크림 paper 로 전환되어 Vermillion 배경과의 대비가 약간 완화되며, Notebook × Score 전 화면이 동일한 CTA 외피를 공유한다.

**설계 포인트**:
- `Colors.white`(순백) → `AppColors.paper`(크림)로 승격: §7.40 `foregroundColor: paper` 기본값이 자동 적용. Notebook 파지 톤과 라벨이 한 팔레트로 수렴.
- `AppTypography.bodyMedium.copyWith(color: white)` 제거: 테마의 `extendedTextStyle: bodyMedium w600 paper` 가 DefaultTextStyle 로 라벨에 주입됨. 기존 `w400` 에서 `w600` 으로 강조도 승격.
- 나머지 11개 `.extended` FAB(학생 상세·계좌 편집·결제 관리·레퍼토리·팁 템플릿 등)는 이미 오버라이드가 없어 §7.40 직후 자동 승격된 상태. 이번 cleanup 으로 18개 FAB 전부가 테마 단일 진원지 체제로 완전 수렴.

**회귀 방지**: 속성 우선순위 체인(`inline > theme`)은 유지되므로 향후 개별 화면이 `backgroundColor` 를 재설정해 특수 CTA 를 만들 수 있는 확장성은 그대로. 단, 기본 Vermillion 이 맞다면 인라인은 더 이상 필요 없음을 §7.41 이 기록한다.

**검증**:
- `flutter analyze` → No issues (편집 4 파일 기준, 기존 2건 경고는 `notebook_typography` 임포트 건으로 범위 밖)
- `flutter test` → 392/392 passed
- 임포트 정리: 3개 파일(`weekly_schedule_screen`·`time_exception_screen`·`subscription_template_list_screen`)에서 `AppTypography` 임포트가 다른 용도(FAB 외)로 계속 사용 중이라 유지. 미사용 경고 없음.

**마일스톤**: §7.40 이론적 수렴(테마 등록)과 §7.41 물리적 수렴(인라인 정리)이 한 쌍으로 완결. 이후 `.extended` FAB 신규 추가 시 `onPressed · icon · label` 세 프로퍼티만 명시하면 Notebook CTA 가 자동 적용된다.

**커밋**: 코드는 `95fb5b5e` 에 §7.42 Playfair 통일 작업과 묶여 포함됨(병렬 세션이 스코프 격리 후 두 변경을 함께 커밋). 5개 파일 중 FAB cleanup 분은 4 파일 · -36 lines 축소가 해당 분. 이전 참조였던 `59be7339` 는 `git reset --soft` 로 소멸된 dangling SHA 로 실효.

**은유**: §7.40 이 15개 노트 귀퉁이에 같은 인주를 찍어 뒀다면, §7.41 은 그 위에 붙어 있던 네 장의 반투명 스티커(`pure white 라벨 · 순백 아이콘 · 바탕색 고정 주석`)를 떼어낸 작업이다. 스티커 밑에 이미 같은 색이 찍혀 있었기에 떼는 순간 노트 전체가 한 번에 정돈된다 — 추가로 칠할 필요 없이 이미 칠해진 것을 드러내는 것이 단일 진원지 패턴의 본질.

---

### 7.42 연습 편집 바텀시트·녹음 섹션·도움말 FAQ 제목 Playfair 통일

**배경**: 연습 카운트/시간을 조정하는 두 개의 바텀시트 커스텀 헤더와, 섹션 상세 안에서 녹음 개수를 함께 노출하는 리스트 제목, 그리고 도움말 화면 FAQ 입구 제목이 `AppTypography.headingSmall`(Noto Sans) 로 남아 있었다. §7.27(바텀시트 커스텀 헤더) 와 §7.17(카드·페이지 섹션 제목) 분기 기준으로 각각 Playfair `appBarTitle` / `sectionTitle` 로 수렴한다.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 패턴 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/practice/presentation/widgets/section_detail/practice_stats_editor.dart` | 202 | 연습 횟수 설정 | `AppTypography.headingSmall` | `NotebookTypography.appBarTitle` | §7.27 |
| `frontend/lib/features/practice/presentation/widgets/section_detail/practice_stats_editor.dart` | 328 | 총 연습 시간 설정 | `AppTypography.headingSmall` | `NotebookTypography.appBarTitle` | §7.27 |
| `frontend/lib/features/practice/presentation/widgets/section_detail/section_recordings_section.dart` | 40 | 녹음 기록 (N) | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/student_home/presentation/screens/help_screen.dart` | 65 | 자주 묻는 질문 | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |

**설계 포인트**:
- **§7.27 vs §7.17 분기**: 같은 파일 안에 있더라도 `BottomSheetHandle` 이 선행하는 커스텀 바텀시트 헤더는 `appBarTitle`, 본문 카드 안쪽에서 아이콘·카운트 등과 함께 노출되는 제목은 `sectionTitle` 을 쓴다.
- **§7.30 제외 엄수**: `practice_stats_card` 의 통계 값 Text, `next_lesson_card` 의 D-day 배지 Text, `invite_history_screen` 의 빈 상태 헤드라인, `student_practice_tab` 의 레퍼토리 이름 Text 는 본 배치에서 손대지 않는다. 레퍼토리 이름은 추후 `NotebookTypography.pieceTitle` 전환 대상으로 별도 섹션에서 다룬다.
- **보간 문자열 유지**: 녹음 개수 `${recordings.length}` 가 포함된 제목은 `const Text` 로 바꿀 수 없으므로 Playfair 전환 시에도 일반 `Text` 위젯으로 유지한다.
- **스코프 격리**: §7.41(FAB cleanup) 작업 중이던 4개 파일(my_connections/time_exception/weekly_schedule/subscription_template_list) 이 index 에 잔존해 본 배치 커밋에 편승할 뻔했으므로 `git reset HEAD <file>` 으로 분리해 미커밋 상태로 되돌렸다. 커밋 전 `git diff --cached` 로 스코프 외 파일 유입 여부를 반드시 확인해야 한다.

**검증**:
- `flutter analyze` 3 files → No issues found (2.4s)
- `flutter test` → 392/392 passed (6s)
- Lore commit: `bd810204`

**은유**: 연습 장부의 편집 페이지와 도움말 노트는 사용자 손가락이 가장 많이 머무는 장소다. 장부 바깥의 서랍(바텀시트) 문패와 장부 안쪽의 소제목이 서로 다른 필체로 적혀 있다면 같은 노트가 아닌 것처럼 느껴진다. 오늘은 서랍 문패에는 Playfair 18pt (`appBarTitle`), 장부 소제목에는 Playfair 17pt (`sectionTitle`) 를 각각 분기해 찍어 — 다른 굵기지만 같은 손으로 쓴 글씨라는 점을 분명히 한다.

---

### 7.43 레퍼토리·곡 이름 3개 사이트 Playfair pieceTitle 통일

**배경**: §7.42 후속으로 미뤄 둔 "레퍼토리 이름" 타이틀 처리. 학생 홈 연습 탭·연습 레퍼토리 화면·아카이브 타일 세 진입점에서 `repertoire.name` 이 여전히 `AppTypography.headingSmall`(Noto Sans) 로 렌더되고 있었다. §7.30 pieceTitle 패턴의 "작품명=고유명사=세리프" 원칙을 세 곳에 동시 반영해 다른 진입점에서 같은 작품이 다른 서체로 보이는 어긋남을 제거한다.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 패턴 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/practice/presentation/screens/practice_repertoire_screen.dart` | 144 | 레퍼토리 카드 헤더 (`repertoire.name`) | `AppTypography.headingSmall` | `NotebookTypography.pieceTitle` | §7.30 |
| `frontend/lib/features/practice/presentation/widgets/section_management/archive_repertoire_tile.dart` | 37-43 | 아카이브 타일 제목 (`repertoire.name`) | `AppTypography.headingSmall` | `NotebookTypography.pieceTitle` | §7.30 |
| `frontend/lib/features/student_home/presentation/screens/student_practice_tab.dart` | 453-458 | 학생 홈 연습 탭 레퍼토리 카드 (`widget.repertoire.name`) | `AppTypography.headingSmall` | `NotebookTypography.pieceTitle` | §7.30 |

**설계 포인트**:
- **§7.30 pieceTitle 의 경계**: pieceTitle 은 "작품명·레퍼토리명" 과 같이 사용자가 스스로 붙인 고유명사에만 적용한다. stat 값(§7.17 이하에서도 제외), D-day 동적 토큰, empty-state 헤드라인, avatar 이니셜, `levelTitle` 등 "상태를 드러내는 텍스트" 는 대상에서 제외한다. 이번 배치는 레퍼토리 이름 세 곳에만 국한했다.
- **동적 텍스트여도 pieceTitle 가능한 이유**: §7.30 은 "정적 vs 동적" 기준이 아니라 "작품명 vs 상태표기" 기준으로 분기한다. `repertoire.name` 은 런타임에 결정되지만 "고유명사"이므로 Playfair 가 맞다. 반대로 같은 위젯 안의 `sections.length` 개 섹션 같은 카운트는 Playfair 를 쓰지 않는다.
- **16pt 위계 포지션**: `pieceTitle` (16/w600, letterSpacing -0.2, height 1.3) 는 `sectionTitle` (17/w600) 보다 한 단계 낮아, 카드 안에서 섹션 제목이 아니라 "콘텐츠의 주인공" 으로 읽히도록 한다. 이 때문에 `repertoire.name` 은 항상 `sectionTitle` 이 아닌 `pieceTitle` 로 맞춘다.
- **스코프 격리 재적용**: §7.42 때 index 에 잔존하던 4개 파일이 편승한 사고를 반복하지 않기 위해, 이번에는 `git reset HEAD 2>/dev/null; git add <3 files>; git diff --cached --stat` 삼단 확인으로 오직 세 파일만 스테이징된 상태를 사전 검증했다. 결과: `3 files changed, 16 insertions(+), 8 deletions(-)` 로 깨끗.

**검증**:
- `flutter analyze` 3 files → No issues found (8.6s)
- `flutter test test/` → 392/392 passed
- Lore commit: `2b319c81`

**은유**: 악보 위의 곡 제목은 장부의 글씨가 아니라 작곡가의 사인이다. "Mendelssohn — Violin Concerto" 는 오늘의 연습 카운트와 같은 손글씨로 적히면 무게가 반감된다. 같은 이름이 학생 홈·연습 장부·아카이브 서랍 어느 곳에서 마주쳐도 똑같이 Playfair 16pt 세리프로 찍혀 있어야, 진지한 작품이 진지한 활자로 남는다.

---

### 7.44 FilledButton paperAccent 인라인 override 16개 파일 cleanup

**배경**: §7.35 에서 `filledButtonTheme` 를 `MaterialTheme` 레벨에 등록하며 `backgroundColor: AppColors.paperAccent`·`foregroundColor: AppColors.paper`·Inter 17/w600 `textStyle` 을 default 로 공급했다. 그러나 도입 이전에 `style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent)` 로 직접 배경을 지정하던 16개 파일이 그대로 남아, 동일한 Vermillion 값을 인라인 override 로 재공급하는 중복 구간이 유지되고 있었다. §7.41 (FloatingActionButton cleanup) 과 동일한 "theme 등록 → inline override 정리" 2단계 패턴의 두 번째 적용.

**원칙 재확인**:
- `inline > theme` precedence 에 따라 override 는 항상 theme 값을 가린다. 따라서 override 와 theme default 가 동일할 때 외형은 불변이지만 — 향후 theme 값을 조정(예: darkTheme 에서 elevation 변경, Vermillion 배경 대체)하려 할 때 override 가 동시에 변경되지 않아 화면 파편화가 일어난다. 중복 제거는 "현재 무변화, 미래 일관성" 을 위한 투자.
- 단일 라인 `style:` 만 존재하는 경우 전체 파라미터를 제거한다. 추가 속성(예: `minimumSize`, `shape`) 이 있는 경우 `backgroundColor:` 라인만 제거하고 나머지는 보존해야 하지만, 이번 스위프에서는 대상 16개 모두 단일 라인 — 안전한 대규모 mechanical 정리.

**변경 파일** (16개, 모두 `style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),` 단일 라인 삭제):

| 도메인 | 파일 | 라벨 |
|--------|------|------|
| schedule | `teacher_availability_screen.dart` | 삭제 |
| schedule | `booking_cancel_screen.dart` | 취소하기 |
| students | `student_detail_screen.dart` | 삭제 |
| profile/screens | `instrument_management_screen.dart` | 삭제 |
| profile/screens | `bank_account_edit_screen.dart` | 삭제 |
| profile/screens | `tip_template_management_screen.dart` | 삭제 |
| profile/screens | `profile_tab.dart` | 로그아웃 |
| profile/widgets | `extended_profile_dialogs.dart` | 삭제 |
| profile/widgets | `repertoire_management_widgets.dart` | 삭제 |
| lessons/widgets | `edit_practice_item_sheet.dart` | 삭제 |
| parent_home | `parent_profile_tab.dart` | 로그아웃 |
| practice/screens | `practice_note_list_screen.dart` | 삭제 |
| practice/screens | `section_detail_screen.dart` | 삭제 |
| practice/screens | `section_detail_recording_mixin.dart` | 삭제 |
| practice/screens | `edit_repertoire_screen.dart` | 삭제 |
| practice/screens | `practice_goal_setting_screen.dart` | 초기화 |

**시각적 불변성 확인**:
- theme 의 `backgroundColor` default 가 `AppColors.paperAccent` (§7.35) 로 동일 — 색상 동일.
- theme 의 `foregroundColor` default 가 `AppColors.paper` (§7.35), 인라인에서는 foregroundColor 를 지정하지 않았으므로 이전에도 theme default 가 적용됨 — 글자색 동일.
- Inter 17/w600 `textStyle`·`shape`·`padding` 역시 theme default 그대로 사용 중이었음 — 구조 동일.

**검증**:
- `flutter analyze` → No issues found (13.1s)
- `flutter test` → 392/392 passed
- Lore commit: `0255cf0d`

**은유**: 장부의 빨간 도장이 문서마다 찍혀 있다. 모두 같은 인주(印朱) 에서 나왔지만, 어떤 페이지는 "도장을 이 위치에 찍으라" 는 지시까지 수기로 덧붙여 있었다. 오늘 16개 페이지에서 그 지시를 지운다 — 인주는 이미 표준 위치에 배치되어 있고, 수기 지시는 남아 있어도 같은 자리를 가리키고 있을 뿐이었다. 도장 자체는 그대로, 페이지 여백만 깨끗해진다.

---

## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **4대 시그니처 필수**: 어느 화면이든 Notebook × Score를 적용했다면 Playfair · 로마숫자 · Vermillion · Gaegu 네 가지가 모두 관찰되어야 한다.
