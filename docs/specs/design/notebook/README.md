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

### 7.11 Phase 3 후속 실적용 (StaffDivider + PencilCircle 도입)

**범위**: Phase 3에서 신설한 공용 위젯을 실제 화면 3곳에 적용. "추가만 하고 쓰이지 않는 위젯" 잔여물 제거.

| 위젯 | 적용 파일 | 변경 | 커밋 |
|------|-----------|------|------|
| `StaffDivider` | `features/lessons/presentation/screens/lesson_detail_screen.dart` | 피드백/포인트/연습 팁 3개 섹션 경계에 삽입 (2곳) | 9bf29b02 |
| `StaffDivider` | `features/practice/presentation/widgets/month_group_header.dart` | 월 그룹 헤더 상단에 배치 — "새 월 = 새 악장" 은유. 기존 Row 우측 1px Expanded 라인 제거 | 3b4b6d60 |
| `PencilCircle` | `features/parent_home/presentation/widgets/profile_switcher.dart` | 선택된 프로필 표시를 `Icons.check_circle` 에서 `PencilCircle(size: 20)` 로 교체 | 3b4b6d60 |
| `PencilCircle` | `features/practice/presentation/widgets/goal/goal_setting_chips.dart` | `ChoiceChip.avatar` 슬롯에 `PencilCircle(size: 16)`. `showCheckmark: false` 로 Material 체크마크 대체 | 795b5c18 |

**검증**:
- `flutter analyze` → 0 issues (4곳 모두)
- 기능·Provider·라우팅 변경 없음 (style-only)

**은유 요약**:
- StaffDivider: 섹션 구분 = 악보의 새 악장
- PencilCircle: 선택 상태 = 연필로 그은 동그라미

---

## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **4대 시그니처 필수**: 어느 화면이든 Notebook × Score를 적용했다면 Playfair · 로마숫자 · Vermillion · Gaegu 네 가지가 모두 관찰되어야 한다.
