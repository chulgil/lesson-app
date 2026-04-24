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

### 7.45 과제 대시보드·선생님 시간표·레퍼토리 상세 섹션 제목 Playfair 통일

**배경**: §7.42/§7.43 이후 §7.17(카드·페이지 섹션 제목) 잔여를 정리하는 첫 배치. 과제 대시보드의 bar+title+count 섹션 헤더, 선생님 시간표의 `_buildSectionHeader` 공용 헬퍼, 레퍼토리 상세의 "연습 통계"/"섹션 목록" 두 정적 제목이 여전히 `AppTypography.headingSmall`(Noto Sans) 로 남아 있었다. 세 진입점을 동시에 `NotebookTypography.sectionTitle` (Playfair 17/w600) 로 수렴.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 패턴 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/home/presentation/screens/assignment_dashboard_screen.dart` | 295 | `_buildSectionHeader(title, count, color)` title | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/schedule/presentation/screens/teacher_availability_screen.dart` | 148 | `_buildSectionHeader({title, subtitle, helpText})` title | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/practice/presentation/screens/repertoire_detail_screen.dart` | 152 | "연습 통계" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/practice/presentation/screens/repertoire_detail_screen.dart` | 246 | "섹션 목록" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |

**설계 포인트**:
- **헬퍼 함수 일괄 반영**: `_buildSectionHeader` 는 호출부에서 여러 섹션 제목에 공유되는 전형적 헬퍼 구조다. 헬퍼 내부 한 곳을 바꾸면 호출처 N 개 제목이 동시에 Playfair 로 승격되므로 — 공통 수정으로 일괄 반영되는 전형 사례. 이 때문에 동일 파일 내 "몇 개 섹션인지" 보다 "몇 개의 헬퍼인지" 가 중요.
- **동적 title 파라미터여도 §7.17 가능한 이유**: 호출부가 정적 문자열 리터럴을 넘긴다는 전제(grep 으로 확인) 하에, 헬퍼 내부에서 `title` 매개변수는 여전히 "정적 섹션 라벨" 의 역할을 한다. §7.30 (pieceTitle, 고유명사) 와의 구분점은 여기.
- **bar+title+count 구성도 §7.17**: `assignment_dashboard_screen` 은 왼쪽 컬러 bar + 제목 + count 의 복합 헤더지만, 제목 자체는 정적 섹션 라벨이므로 Playfair 적용. count(동적 숫자) 는 그대로 `AppTypography.bodySmall` 유지.
- **formatter 자동 정리**: `repertoire_detail_screen.dart` 에서 import 추가 후 PostToolUse 포매터가 인접한 `Icon(chevron_right)`·`Icon(drag_handle)` 두 위젯을 다중 라인 → 단일 라인으로 축약했다. 의미 변경 없음을 diff 로 확인.
- **§7.44 와의 파일 공교로움**: 평행 세션의 §7.44 (FilledButton paperAccent inline override cleanup) 가 `teacher_availability_screen.dart` 를 이미 한 번 touch 했지만, 대상 영역(화면 하단 "삭제" FilledButton)과 본 배치의 대상 영역(섹션 헤더 helper)이 겹치지 않아 순차 머지가 깔끔했다. 커밋 전 `git diff --cached --stat` 으로 스코프 확인 완료.

**검증**:
- `flutter analyze` 3 files → No issues found (4.2s)
- `flutter test test/` → 392/392 passed
- Lore commit: `149a614d`

**은유**: 공연 프로그램북의 장별 제목 — "1악장", "2악장", "3악장" — 은 한 번만 활자 선택을 바꾸면 모든 악장이 동시에 새 활자로 찍힌다. 프로그램북의 템플릿을 고친 것이지 각 장을 하나씩 고친 것이 아니다. 오늘은 `_buildSectionHeader` 라는 세 개의 템플릿을 Playfair 로 바꾸니, 그 밑에 매달린 과제 대시보드·시간표 설정·레퍼토리 통계가 모두 같은 손글씨로 일어선다. 공통의 위력.

---

### 7.46 dark 테마 `textButtonTheme` 등록 — light/dark 대칭성 회복

**배경**: 지금까지의 cleanup 스프린트(§7.34 cardTheme → §7.38 dialogTheme → §7.40 floatingActionButtonTheme → §7.41/§7.44 inline override cleanup) 는 주로 light 테마를 중심으로 진행됐다. 이번 감사에서 light·dark 두 `MaterialTheme` 블록에 등록된 속성 수를 비교한 결과 **다크만 `textButtonTheme` 이 빠져 있었다**. M3 의 TextButton 은 theme 미등록 시 `colorScheme.primary`(purple 계열) 로 폴백하는데, 이는 Notebook × Score 팔레트 외 색상이 다크 모드에서만 간헐적으로 혼입되는 씨앗이 된다. §7.40 이 FAB 에서 보여준 "light 에만 있던 속성을 dark 에도 시그니처 치환으로 이식" 패턴을 그대로 적용.

**등록 전/후 속성 수**:

| 모드 | before | after | gap |
|------|--------|-------|-----|
| light | 29개 | 29개 | 0 |
| dark | 28개 (textButtonTheme 없음) | 29개 | 0 |

**추가된 속성**: `textButtonTheme: TextButtonThemeData(style: ...)`

| 속성 | light | dark | 차이의 이유 |
|------|-------|------|-------------|
| `foregroundColor` | `AppColors.ink` | `AppColors.paper` | 표면 대비 (light=검정 잉크, dark=종이) |
| `textStyle` | `AppTypography.bodyMedium` + w500 | 동일 | 동일 — 타이포 일관성 |

**설계 포인트**:
- **FAB 패턴과의 상동(homology)**: §7.40 도 "light 의 `extendedTextStyle` 를 dark 에도 동일 Inter w600 으로 등록" 이었다. 이번도 같은 결: "light 의 textStyle 은 그대로 유지하고, 표면 대비에 의존하는 foregroundColor 만 paper 로 치환". 이 일관된 치환 규칙이 light/dark 전환 시 타이포 굵기·레터스페이싱 드리프트를 방지한다.
- **왜 `paperAccent` 가 아니라 `paper` 인가**: TextButton 은 primary CTA 가 아니라 보조 액션(취소·건너뛰기·이동)이 대부분이다. Vermillion 은 primary CTA(FilledButton·FAB) 에만 위임하고, TextButton 은 "표면 위에 조용히 얹힌 링크" 성격을 유지. light=ink(검은 글자)·dark=paper(흰 글자) 대칭이 이 역할을 가장 잘 표현한다.
- **회귀 영역 최소화**: 기존 모든 TextButton 호출부는 인라인 `style:` 없이 theme 에 의존하고 있었거나(대다수), 인라인 `foregroundColor:` 를 따로 지정한 소수 파일이었다. 전자는 이번 변경으로 darkTheme 에서 정확히 `paper` 를 받게 되고, 후자는 `inline > theme` precedence 로 기존 동작을 유지한다.

**검증**:
- `flutter analyze lib/` → No issues found (12.0s)
- `flutter test` → 392/392 passed
- Lore commit: `895d6b73`

**은유**: 같은 책을 낮판과 밤판으로 두 번 찍었는데, 낮판 목차에는 "참고 링크" 라는 검은 작은 글자가 붙어 있지만 밤판에는 그 줄이 통째로 빠져 있었다. 빠졌다기보다 기본 인쇄기가 아무 색이나 찍게 내버려 둔 채 — 때로는 보라색, 때로는 청록색 — 독자는 낮과 밤을 오갈 때마다 이 목차만 다른 손이 손본 것처럼 읽었다. 오늘 밤판 목차에도 같은 "참고 링크" 줄을 넣는다. 단 잉크는 낮판의 검정이 아니라 종이색 흰색으로 — 어두운 지면 위에서 같은 역할을 하는 정확한 대칭.

---

### 7.47 Material `Colors.grey` 잔존 3건 → Notebook `ink` 토큰 치환

**배경**: §7.46 에서 다크 테마 TextButton 폴백 경로를 막은 뒤, 다른 팔레트 누수 경로도 전수 탐색했다. `Theme.of(context).colorScheme.primary` 참조는 0건, `Theme.of(context).primaryColor` 역시 0건 (`colorScheme.surface` 7건은 light/dark 양쪽에서 명시적으로 매핑돼 있어 안전). 단 **Material `Colors.grey[300/600]` 직접 호출이 3개 파일에 남아있었다**. UI 토큰 경계를 벗어난 회색은 light/dark 전환 시 명도 대비가 따로 논다. 회색 농도별로 대응하는 Notebook `ink*` 토큰으로 치환.

**치환 매핑**:

| 원본 | 회색 농도 (대략) | Notebook 토큰 | alpha |
|------|------------------|----------------|-------|
| `Colors.grey[600]` | 50% | `AppColors.inkSecondary` | 75% ink (검은 잉크를 종이 위에 75% 불투명도로 찍은 색) |
| `Colors.grey[300]` | 20% | `AppColors.inkQuaternary` | 25% ink |

**변경 파일 (3건)**:

| 파일 | 사용처 | 매핑 |
|------|--------|------|
| `frontend/lib/features/lessons/presentation/widgets/ai_notes_result_sheet.dart` | BottomSheetHandle (시트 상단 드래그 손잡이) | `grey[300]` → `inkQuaternary` |
| `frontend/lib/features/students/presentation/widgets/student_detail/location_summary_card.dart` | 주소 보조 텍스트 | `grey[600]` → `inkSecondary` |
| `frontend/lib/features/students/presentation/widgets/student_detail/travel_analytics_card.dart` | 월간 이동 통계 stat 라벨 | `grey[600]` → `inkSecondary` |

**제외 대상**:
- `tuner_cat_painters.dart` 의 `Colors.yellow`/`Colors.white`/`Colors.transparent` — 튜너 고양이 일러스트 아트. CustomPainter 로 그려지는 캐릭터 beam 인 만큼 Notebook UI 토큰 체계 밖. §7.30 의 "사용자 생성 고유명사" 처럼 "의도적 비-UI 원색" 으로 분류.
- `Colors.transparent`·`Colors.white`·`Colors.black` — semantic primitive. Notebook 토큰화 대상 아님 (검은 잉크는 `ink`, 종이 흰색은 `paper`로 분기해 이미 토큰화돼 있으며, 진짜 Colors.white/black/transparent 가 필요한 구간은 별개).

**설계 포인트**:
- **"회색 농도 → alpha-over-ink" 치환 규칙**: Notebook 은 회색을 독립 색상이 아닌 "검은 잉크를 종이 위에 옅게 찍은 것" 으로 모델링한다. 회색 자체를 토큰화하지 않고 `inkSecondary`(75%)·`inkTertiary`(55%)·`inkQuaternary`(25%) 네 단계로 alpha 를 조절한다. 이 구조 덕분에 light(종이 위 잉크) ↔ dark(어둠 위 빛) 전환 시 대비 공식이 자동으로 뒤집힌다.
- **grep pattern 의 정확성**: 단순 `grep "Colors\."` 는 `InstrumentColors`·`SubscriptionStatusColors`·`baseColors` 등 "Colors" 를 포함한 도메인 객체를 모두 잡아낸다. `grep -E "(^|[^A-Za-z])Colors\."` 로 단어 경계를 지정하면 Material `Colors.X` 만 정확히 추출된다. 이후 감사에서도 이 패턴을 재사용한다.
- **`AppColors` import 선존재 확인**: 3개 파일 모두 이미 `app_colors.dart` 를 import 중이었다 — 수정은 "새 import 추가 없이 라인 1개씩 3건" 으로 끝난 가장 저위험 cleanup.

**검증**:
- `flutter analyze lib/` → No issues found (19.2s)
- `flutter test` → 392/392 passed
- Lore commit: `31c2ba86`

**은유**: 서재의 모든 연필이 "2B" 라는 표준 흑심을 공유하는 서재에서, 어느 구석에서 정체 불명의 마커 두 자루가 발견됐다. 색은 비슷한 회색이지만 심은 다른 공장에서 왔고 — 같은 종이 위에 나란히 그으면 명도 위계가 미묘하게 어긋난다. 오늘 세 자루를 2B 연필의 옅은 획(25%·75% 필압)으로 바꿨다. 새로 산 것이 아니라 원래 서재가 써오던 두께를 정확히 매칭한 것 — 독자의 눈은 차이를 느끼지 못하지만, 서재의 물성은 이제 단 하나의 흑심으로 통일된다.

---

### 7.48 레슨 정책·학부모 레슨/결제 탭 섹션 제목 Playfair 통일 — §7.17·§7.27 혼합 배치

**배경**: §7.45 에 이어 §7.17 잔여를 계속 정리. 이번엔 레슨 정책 화면의 헬퍼 기반 섹션 헤더와 학부모 홈의 레슨 탭 두 섹션 제목을 §7.17 로 승격하면서, 같은 배치 안에서 학부모 결제 탭의 "자녀 선택" 바텀시트 헤더가 `BottomSheetHandle` 선행 구조임을 확인하고 §7.27 로 분기해 함께 처리했다. 혼합 배치 선례는 §7.42 에서 확립된 패턴.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 패턴 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/subscription/presentation/screens/lesson_policy_screen.dart` | 138 | `_buildSectionHeader(title, icon)` title | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/parent_home/presentation/screens/parent_lessons_tab.dart` | 29 | "예정된 레슨" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/parent_home/presentation/screens/parent_lessons_tab.dart` | 69 | "지난 레슨" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 |
| `frontend/lib/features/parent_home/presentation/screens/parent_payments_tab.dart` | 445 | "자녀 선택" (바텀시트 헤더) | `AppTypography.headingSmall` | `NotebookTypography.appBarTitle` | §7.27 |

**설계 포인트**:
- **혼합 배치의 분기 기준 재확인**: 한 커밋에서 §7.17 과 §7.27 이 공존하는 것은 문제되지 않는다. 분기점은 **`BottomSheetHandle` 선행 여부** — 선행하면 커스텀 바텀시트 헤더(§7.27, 18/w700), 선행하지 않으면 페이지/카드 섹션 제목(§7.17, 17/w600). 변경표에서 각 행의 "패턴" 열로 혼동을 제거한다.
- **헬퍼 함수 전파**: `lesson_policy_screen._buildSectionHeader(title, icon)` 는 호출부가 다수. 헬퍼 내부 한 줄 전환으로 호출처 N 개 섹션 제목이 동시에 Playfair 로 승격 — §7.45 에서 굳어진 "공통 수정으로 일괄 반영" 원칙의 반복 적용.
- **의도적 제외 목록**: 이번 배치에서 **건드리지 않은** 같은 파일 내 `headingSmall` 사용처를 아래에 명시해 향후 배치의 판정 기준을 남긴다.
  - `lesson_policy_screen:315` "📋 정책 요약" — `.copyWith(color: paperAccent)` 색상 오버라이드. `sectionTitle` 로 단순 치환 시 색상이 유실된다. 별도 배치에서 `sectionTitle.copyWith(color: paperAccent)` 로 전환.
  - `parent_lessons_tab:417` `monthName` — 캘린더 네비게이션의 동적 월 라벨. "정적 섹션 제목" 이 아니라 "네비게이션 상태 표시" 에 가까워 §7.17 보류. §7.30 pieceTitle 도 해당 없음(월은 고유명사 아님).
  - `parent_payments_tab:297` `profile.name` — 자녀 이름. §7.30 은 "작품명" 한정이므로 사람 이름은 별도 정책 필요. 이번 배치는 보류.
  - `parent_payments_tab:503, 568` — `.copyWith(...)` 변형. copyWith 류는 별도 그룹으로 묶어 색상/무게 유지 전환할 예정.
  - `parent_payments_tab:602` "오류가 발생했습니다" — 에러 헤드라인은 §7.30 제외 roster.
- **스코프 격리**: 커밋 시 작업 트리에 평행 세션의 5개 파일(`ai_notes_result_sheet`, `location_summary_card`, `travel_analytics_card` 및 `prompt_plan.md`) 이 unstaged 로 남아 있었다. `git reset HEAD` 후 3개 파일만 명시적으로 `git add` 하고 `git diff --cached --stat` 로 확인 — 스코프 유입 없이 깨끗.
- **§7.47 번호 경합**: README append 직전 §7.47 이 이미 평행 세션(Material Colors.grey → Notebook ink 토큰)에 점유되어 있음을 `grep "^### 7\."` 로 확인. §7.48 로 진행. 이 `grep-before-append` 프로토콜이 평행 작업 환경에서 번호 충돌을 막는 유일한 수단임을 재확인.

**검증**:
- `flutter analyze` 3 files → No issues found (10.2s)
- `flutter test test/` → 392/392 passed
- Lore commit: `c329c6e6`

**은유**: 학부모가 펼쳐 보는 레슨 장부와 결제 장부는 오늘도 같은 책장에서 꺼낸다. 한 장부의 소제목은 활자에 찍혀 있고, 옆 장부에서 자녀를 고르라고 띄우는 서랍(바텀시트) 문패는 손으로 쥐는 손잡이(BottomSheetHandle) 아래에 붙어 있다. 활자와 문패는 둘 다 Playfair 서체지만 굵기가 다르다 — 소제목은 17pt 읽기용, 문패는 18pt 집어 올리는 용. 같은 손이 같은 잉크로 쓴 글씨지만, 역할에 맞는 굵기로 쓰는 규율은 유지된다.

---

### 7.49 수강권 목록·레슨 정책 요약 섹션 제목 Playfair 통일 — copyWith 색상 변형 배치

**배경**: §7.48 에서 "copyWith 류는 별도 그룹" 으로 보류했던 색상 오버라이드 섹션 제목을 정리하는 배치. §7.17 sectionTitle 의 **color override variant** 만 모아 처리해, 상태별 강조(Vermillion·ink·inkTertiary)를 보존하면서 서체만 Playfair 로 승격했다.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 전파 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/subscription/presentation/screens/subscription_list_screen.dart` | 헬퍼 | `_buildSectionHeader(title, {color})` 본체 | `AppTypography.headingSmall.copyWith(color: ...)` | `NotebookTypography.sectionTitle.copyWith(color: color ?? ink)` | 3 호출부 |
| 〃 (호출부 1) | ~97 | "진행 중" | — | ink (default) | 헬퍼 경유 |
| 〃 (호출부 2) | ~116 | "만료 임박" | — | paperAccent (Vermillion) | 헬퍼 경유 |
| 〃 (호출부 3) | ~135 | "만료됨" | — | inkTertiary | 헬퍼 경유 |
| `frontend/lib/features/subscription/presentation/screens/lesson_policy_screen.dart` | 315 | "📋 정책 요약" | `AppTypography.headingSmall.copyWith(color: paperAccent)` | `NotebookTypography.sectionTitle.copyWith(color: paperAccent)` | 직접 |

실질적으로 섹션 제목 **4건**이 Playfair 로 전환됐으며, 그 중 3건은 헬퍼 1곳 수정으로 연쇄 반영됐다.

**설계 포인트**:
- **copyWith 변형 처리 원칙**: `AppTypography.headingSmall.copyWith(color: X)` 형태는 "기본 스타일에 상태별 색을 덧씌운 섹션 제목" 으로 해석한다. `NotebookTypography.sectionTitle.copyWith(color: X)` 로 치환하면 Playfair 글리프·17px·w600 은 §7.17 표준을 따르고, 색상 `X` 만 그대로 보존된다. copyWith 의 **덮어쓰기 의미론** 덕분에 부모 스타일 교체가 non-breaking.
- **헬퍼 전파의 재확인**: §7.45 에서 확립된 "헬퍼 1곳 → N 호출부 일괄 반영" 원칙이 가장 효과적으로 작동한 배치. `_buildSectionHeader(title, {Color? color})` 는 수강권 상태 3개(active/expiringSoon/expired)에 각각 다른 색을 전달하는 설계였고, 헬퍼 본체의 스타일 루트를 Playfair 로 바꾸는 것만으로 3개 상태의 섹션 헤더가 동시에 승격됐다.
- **§7.30 제외 roster 확장 — 빈 상태 헤드라인**: 본 배치에서 **건드리지 않은** 같은 파일 내 `headingSmall` 사용처는 모두 빈 상태 헤드라인이다. 향후 배치 판정 기준으로 명시:
  - `subscription_list_screen:285` "등록된 수강권이 없습니다"
  - `subscription_list_screen:316` "등록된 레슨이 없습니다"
  - `parent_payments_tab:503` "등록된 자녀가 없습니다"
  - `parent_payments_tab:568` "등록된 수강권이 없습니다"

  이들은 "정보 부재 안내" 로 카드·페이지 섹션 제목과는 문맥이 다르다. Playfair 의 serif 격식은 "빈 장부에 대한 친근한 안내" 와 톤이 맞지 않아 §7.30 제외 roster 에 준하는 정책 대기 항목으로 분류.
- **§7.30 제외 roster 확장 — 가격/숫자 값**: `proposal_confirm_screen:253 _formatPrice(price)`, `proposal_detail_screen:443 template.formattedPrice`, `renewal_detail_screen:334 template.formattedPrice` 는 모두 headingSmall 로 렌더되는 **금액 숫자** 다. 동적 값 stat(§7.30 제외 원칙 적용) 과 동치이며, 금액은 Inter sans-serif(tabular-nums) 유지가 오히려 판독성에 유리. 보류.
- **스코프 격리**: 작업 트리에 평행 세션의 `prompt_plan.md` 와 `.claude/harness-signals/`·`.claude/hooks/README.md`·`.claude/hooks/task-created-validate.sh`·`.mcp.json` 이 unstaged/untracked 로 남아 있었다. `git reset HEAD` 후 2개 파일만 명시적으로 add, `git diff --cached --stat` 로 스코프 재확인.
- **PostToolUse 포매터 부수효과**: `subscription_list_screen.dart` 는 포매터가 파일 전체를 재정렬 (166라인 변경됨). 실제 의미 변경은 import 1줄 + 주석 1줄 + 스타일 1줄뿐이고 나머지는 dart format 의 whitespace/줄바꿈 조정. `git diff --cached | grep -E "notebook|sectionTitle|headingSmall"` 로 4줄만 필터링해 의미 변경 검증.

**검증**:
- `flutter analyze` 2 files → No issues found (4.0s)
- Lore commit: `a6d19212`

**은유**: 같은 주제(수강권 상태) 를 색만 바꿔 반복하는 장부가 있다면 — 활자를 상태마다 다시 골라 찍을 필요가 없다. 장부의 "소제목 양식" 이라는 거푸집(헬퍼) 하나를 바꾸면, 어떤 색으로 찍든 서체는 이미 Playfair 다. 오늘은 거푸집 하나를 교체해 세 가지 상태(진행·임박·만료) 의 제목이 동시에 격상됐다. copyWith 는 거푸집의 "덮어쓰기 서랍" 이다 — 서체는 새 표준으로, 색은 기존 상태표기 그대로.

---

### 7.50 Material `Colors.black54` / `Colors.white70` 8건 → Notebook ink / paper alpha 토큰 치환

**맥락**: §7.47 에서 `Colors.grey[600]`/`[300]` 3건을 ink alpha 래더(75%·55%·25%)로 흡수한 뒤, 같은 원리가 적용되어야 할 **black/white alpha** 잔재 감사. Material `Colors.black54`(54% 검정)·`Colors.white70`(70% 흰색) 은 시각적으로 "스크림/오버레이 보조 텍스트" 계열이며 Notebook 팔레트에도 직접 대응이 있다. 감사 결과 features/ 에 정확히 8건(`black54` 4 + `white70` 4) 이 남아 있어 일괄 치환.

**교훈**: Cycle 22(§7.47) 직전 CEO 리뷰에서 "Material Colors 잔재 감사" 를 3-후보 브레인스토밍에 올려두었지만, grey 이후 black/white alpha 는 별도 배치로 미뤘었다. 같은 원리(회색 톤 = ink at alpha, 밝은 톤 = paper at alpha)를 black/white 에도 일관 적용해 "회색만 잡고 검정·흰색 alpha 는 방치" 라는 절반 청소를 방지.

**매핑 원칙** (§7.47 연장):
| Material 색상 | Notebook 토큰 | 근거 |
|---|---|---|
| `Colors.black54` (54% 검정) | `AppColors.inkTertiary` (55% ink) | 1% alpha 차이는 시각적 무차이. 스크림/배지 공통 |
| `Colors.white70` (70% 흰색) | `AppColors.paper.withValues(alpha: 0.7)` | paper 크림톤으로 Notebook 팔레트 유지 |
| (동반) 인디케이터 `Colors.white` | `AppColors.paper` | 스크림 위 브랜드 백색은 paper |

**변경 파일 (4개)**:
- `features/profile/presentation/screens/certificate_edit_screen.dart:511,546` — 이미지 썸네일 "탭하여 변경" 배지 배경 2건. `Colors.black54` → `inkTertiary`. (배지 위 텍스트 `Colors.white` 는 이 배치에서 유지 — 스코프 분리, Cycle 24 Candidate B 로 이월)
- `features/practice/presentation/widgets/metronome/time_signature_picker.dart:176` — 선택된 박자 칩(Vermillion 배경) 위 "큰박 N개" 부가 텍스트. `Colors.white70` → `paper.withValues(alpha: 0.7)`. 비선택 라인 `inkSecondary` (75% ink) 와 대칭 구조 확립.
- `features/parent_home/presentation/screens/parent_dashboard_tab.dart:410,416` — 다크 히어로 카드 위 선생님 이름 Icon+Text 2건. 둘 다 `Colors.white70` → `paper.withValues(alpha: 0.7)`. `const` Icon 이 `AppColors.paper.withValues(...)` 는 `const` 컨텍스트 밖이라 `const` 키워드 제거.
- `features/invite/presentation/screens/scan_invite_screen.dart:95,155,172` — 카메라 스캔 오버레이 3건: 처리중 스크림 `Colors.black54` → `inkTertiary`, 안내 패널 배경 `Colors.black54` → `inkTertiary`, 안내 서브텍스트 `Colors.white70` → `paper.withValues(alpha: 0.7)`. 동반으로 처리중 인디케이터 `Colors.white` → `AppColors.paper`(brand white) 승격.

**검증**:
- `flutter analyze lib/` → No issues found (13.2s, §7.47 이후 첫 배치이므로 회귀 없음 확인)
- `flutter test` → 392/392 passed
- grep `Colors\.(black54|white70)` features/ → 0 matches (문서/주석 언급만 6건 — 실제 사용처 0)
- 코드 커밋: `f147bfe6`

**스코프 분리 (의도적 누락)**:
- `Colors.white` 단독 사용(certificate 2건, parent_dashboard 11건, scan_invite 6건) — Vermillion 버튼/다크 히어로 foreground 는 **Vermillion 위 브랜드 백색** 이라는 고유 의미가 있어 일괄 치환 전에 별도 판정 필요.
- `Colors.white.withValues(alpha: N)` (parent_dashboard 3건) — Candidate B "withValues(alpha:) 내부 Material Colors 혼재 감사" 로 이월. 다음 Cycle 에서 일괄 처리.
- `Colors.black` / `Colors.black` 단독(scan_invite 1건) — 카메라 배경 불투명 검정은 "절대 검정" 의 의미가 강하므로 Notebook ink(`#14161C`) 와 다름. 보류.

**§7.47 패턴 재확인**:
회색 톤 = ink at alpha, 밝은 톤 = paper at alpha — Notebook 팔레트는 "색상 3개 + alpha 래더" 로 Material 의 수십 개 회색/백색 팔레트를 커버한다. 이 cycle 은 그 래더에 **black/white alpha** 변형도 편입됨을 명시.

**은유**: 장부의 스크림은 검정이 아니라 "흐린 먹선" 이다 — 먹(ink)을 물에 풀어 투명도를 조절하면 회색도 검정도 그 한 줄기에서 나온다. Material 의 `black54` 는 "검정을 54% 섞은 회색" 이지만, Notebook 에서는 그냥 "먹 55% 농도" 다. 오늘 두 표기법이 1% alpha 차이 안에서 만나 한 이름(`inkTertiary`)으로 수렴했다. 흰색도 같다 — "흰색 70%" 가 아니라 "크림 종이 70% 농도". 모든 중간톤은 결국 `ink`·`paper` 두 뿌리에서 자란다.

---

### 7.51 주간 스케줄·휴무 관리 섹션 제목 Playfair 통일 — schedule/ 도메인 §7.17 배치 개시

**배경**: §7.49 copyWith 변형 배치 이후, 미전환 §7.17 후보가 가장 많이 남은 도메인은 `features/schedule/` (20+ 파일, ~30+ headingSmall 사용처). 전면 배치 대신 화면 단위로 나눠 처리하는 전략을 시작. 첫 배치는 선생님 시점의 관리 화면 2개(주간 스케줄·휴무) — 두 화면 모두 "정적 카드/페이지 섹션 제목" 패턴으로 §7.17 판정이 명확하다.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 변형 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/schedule/presentation/screens/weekly_schedule_screen.dart` | 82 | "주간 스케줄" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | 직접 |
| `frontend/lib/features/schedule/presentation/screens/time_exception_screen.dart` | 91 | "예정된 휴무" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | 직접 |
| 〃 | 101 | "지난 휴무" | `AppTypography.headingSmall.copyWith(color: inkSecondary)` | `NotebookTypography.sectionTitle.copyWith(color: inkSecondary)` | copyWith |

**설계 포인트**:
- **도메인 단위 배치 전략**: schedule/ 는 화면·위젯이 많아 한 번에 처리하면 diff 가 크고 회귀 위험이 증가한다. 화면 2-3개씩 묶어 배치별로 진행하면 PostToolUse 포매터 변경 스코프도 통제 가능. 이 원칙은 향후 §7.52~§7.55 배치에도 재사용.
- **§7.30 제외 roster 적용**: 같은 schedule/ 내 `pending_bookings_screen.dart:84` 의 "대기 중인 신청이 없습니다" 는 빈 상태 헤드라인(§7.49 에서 roster 편입)이므로 이번 배치에서 의도적으로 제외. 동일 파일·동일 스타일이어도 **역할이 섹션 제목이 아닌** 경우는 치환하지 않는다.
- **동적 상태 라벨과 정적 섹션 제목의 분기**: "예정된 휴무"·"지난 휴무" 는 리스트 분류 제목(정적) → §7.17. 향후 schedule/ 다른 화면에서 만날 "대기 중"·"승인 완료" 같은 **상태 뱃지/필터 라벨** 은 sectionTitle 이 아니라 status-label 계열로 분기하므로 주의.
- **copyWith 변형 패턴 표준화**: "현재 섹션 = primary ink, 과거/만료 섹션 = inkSecondary" 는 §7.49 수강권 목록(진행/임박/만료)·이번 배치(휴무 예정/지난) 모두 동일 구조. copyWith 색상 override 는 "상태별 strength" 를 표현하는 관용 패턴임을 재확인.

**검증**:
- `flutter analyze` 2 files → No issues found (4.9s)
- Lore commit: `fb6d666f`

**은유**: 큰 책장의 맞은편 장식장에 오늘부터 새 활자를 조금씩 옮기기 시작한다. 가장 먼저 자리를 바꾼 것은 주간 일정표와 휴무 장부 — 두 장부는 선생님이 가장 자주 펼치는 것이라 제목의 서체가 바뀌면 즉시 눈에 들어온다. "예정" 은 짙은 먹, "지난" 은 옅은 먹 — 서체는 한 뿌리(Playfair) 지만 시간의 온도가 농도로 구분된다.

---

### 7.52 통합 레슨 신청·완료·거절 바텀시트 섹션 제목 Playfair 통일 — schedule/ 도메인 §7.17 배치 #2

**배경**: §7.51 주간 스케줄·휴무 배치에 이어 schedule/ 도메인의 두 번째 §7.17 배치. 이번 대상은 학생 시점의 **레슨 신청 파이프라인** 3개 화면(통합 신청·신청 완료·거절 바텀시트). 통합 신청 화면은 `_SectionWrapper` 라는 내부 헬퍼 위젯이 6개 호출부(체험/정기/아카데미 각 폼) 에서 반복 사용되므로 헬퍼 1곳 수정으로 일괄 반영.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 전파 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/schedule/presentation/screens/unified_lesson_request_screen.dart` | 770 | `_SectionWrapper` 헬퍼 `title` | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | 6 호출부 |
| 〃 | 774 | `_SectionWrapper` required marker ` *` | `AppTypography.headingSmall.copyWith(color: paperAccent)` | `NotebookTypography.sectionTitle.copyWith(color: paperAccent)` | 6 호출부 |
| `frontend/lib/features/schedule/presentation/screens/request_completion_screen.dart` | 127 | "진행 단계 가이드" | `AppTypography.headingSmall.copyWith(color: ink)` | `NotebookTypography.sectionTitle.copyWith(color: ink)` | 직접 |
| 〃 | 262 | "신청 정보 요약" | `AppTypography.headingSmall.copyWith(color: ink)` | `NotebookTypography.sectionTitle.copyWith(color: ink)` | 직접 |
| `frontend/lib/features/schedule/presentation/screens/suggest_alternative_screen.dart` | 857 | `AppStrings.rejectBottomSheetTitle` | `AppTypography.headingSmall` | `NotebookTypography.appBarTitle` | §7.27 |

실질적으로 섹션 헤더 **9건** 이 Playfair 로 전환됐다(helper 호출부 6 + direct 2 + bottom sheet 1). 그 중 6건은 헬퍼 2줄(title + required marker) 수정으로 체험·정기·아카데미 폼에 동시에 반영됐다.

**설계 포인트**:
- **§7.17 과 §7.27 의 같은-배치 공존 재확인**: 같은 커밋에 `sectionTitle` 과 `appBarTitle` 이 공존하는 것은 §7.48·§7.49·§7.51 을 거치며 표준 패턴이 됐다. 분기점은 `BottomSheetHandle` 선행 여부. suggest_alternative 의 거절 바텀시트는 handle 선행 구조이므로 `appBarTitle` 로 분기했다.
- **`_SectionWrapper` 의 required marker 치환**: 요구 필수(*) 마커는 제목 폰트를 공유하는 장식이다. 제목 폰트를 Playfair 로 바꿨으면 마커도 동일 폰트를 써야 시각적 연속성을 유지한다. copyWith 로 색만 paperAccent(Vermillion) 로 덮어써서 빨간 별표만 눈에 띄도록.
- **§7.30 제외 roster 확장 — schedule/ 의 동적 값 군집**: 이번 배치 선정 과정에서 확인한 schedule/ 내 **동적 값** 카테고리를 최종 정리해 기록:
  - 동적 날짜 라벨: `schedule_tab:271` (선택한 날짜 "4월 22일 화요일"), `booking_cancel:146` (`_formatBookingDate()`)
  - 동적 시간 값: `schedule_tab:615` (`lesson.startTime` 14:30)
  - 동적 상태 라벨: `group_class_detail:370` (`booking.statusText`)
  - 동적 이름: `booking_cancel:591` (`teacherName 연락처`), `request_detail:327` (opponent + 타입), `unified_lesson_request:175` (teacherName)
  - 동적 카운트: `group_class_attendance:170` (출석 N/M)

  이들은 모두 §7.30 exclusion roster 의 "dynamic stat values" 범주. 사용자 생성 고유명사나 변동 숫자는 Inter sans-serif 로 두고 Playfair 는 정적 카피에만 적용하는 원칙.
- **PostToolUse 포매터와 old_string 재조정**: 이번 배치에서 import 추가 직후 포매터가 주변 영역을 재정렬해 `Edit` 의 old_string 을 무효화시키는 경우가 여러 번 발생. `Read` 로 실제 라인을 재확인한 뒤 복구. 포매터 친화적 방식은 "import 한 줄 추가 → 한 번 Read → 편집" 순서. 배치 크기를 늘리면 포매터와 경합하는 구간이 비례 증가하므로 도메인 단위 배치 전략(§7.51) 이 재차 정당화된다.

**검증**:
- `flutter analyze` 3 files → No issues found (5.2s)
- Lore commit: `ab3a5581`

**은유**: 학생이 레슨을 신청하는 장부는 세 장이다 — 첫 장은 신청서 폼, 둘째 장은 접수 확인서, 셋째 장은 바꿔달라는 요청서. 세 장부의 표지 활자가 서로 달랐다면 독자는 "같은 펜이 쓴 게 맞나?" 의심할 것이다. 오늘 세 장부의 섹션 제목이 한 활자(Playfair) 로 수렴했다. 신청서 안의 체험/정기/아카데미 항목도 한 거푸집(`_SectionWrapper`) 에서 찍혔으니, 거푸집 하나만 바꿔도 세 종류의 신청서가 동시에 격상됐다. 필수 항목의 빨간 별표는 여전히 빨갛지만, 별표의 몸통마저 이제 Playfair 의 손글씨다.

---

### 7.53 Material `Colors.white.withValues(alpha:)` 38건 → Notebook `AppColors.paper.withValues(alpha:)` 일괄 치환

**맥락**: §7.50 에서 `Colors.black54`/`Colors.white70` 8건을 ink·paper alpha 래더에 편입한 뒤, 같은 원리를 **`Colors.white.withValues(alpha:)` alpha 변형 전체** 에 확장. §7.50 본문에서 "Candidate B: withValues(alpha:) 내부 Material Colors 혼재 감사" 로 이월했던 항목을 이번 배치로 해소. features/ 전수 스캔 결과 정확히 38건이 14개 파일에 분포, 전량 `AppColors.paper.withValues(alpha:)` 로 alpha 값 유지한 채 토큰만 교체.

**교훈**: §7.50 에서 "회색 톤 = ink at alpha, 밝은 톤 = paper at alpha" 원리를 세웠지만, **`Colors.white.withValues` 형태는 `Colors.white70` 과 동일 계열인데 표기법만 다르다**. 동일 원리 다른 표기법은 같은 cycle 에 묶어야 "일부만 치환" 을 피할 수 있음. 이번 배치는 `white70` 직계 + `withValues(alpha:)` 변형을 한 래더로 흡수.

**매핑 원칙** (§7.50 연장):
| Material 색상 | Notebook 토큰 | alpha 값 |
|---|---|---|
| `Colors.white.withValues(alpha: N)` | `AppColors.paper.withValues(alpha: N)` | 원본 alpha 값 그대로 (0.1~0.9 범위) |

alpha 값은 의미(투명도 단계) 이므로 변환하지 않음 — Material 의 "흰색 투명도 N" 이 Notebook 에선 "크림 종이 투명도 N" 으로 직결.

**변경 파일 (14개, 38건)**:
- `features/search/presentation/screens/teacher_detail_screen.dart` (1건) — CircleAvatar 배경
- `features/search/presentation/screens/academy_detail_screen.dart` (1건) — 아카데미 상세 컨테이너 배경
- `features/practice/presentation/widgets/metronome/metronome_full_screen_modal.dart` (1건) — 선택된 서브디비전 라벨
- `features/gamification/presentation/widgets/gamification_header.dart` (6건) — 레벨 배지/칩 배경/스탯 배경/진행바 배경/주간 스탯
- `features/profile/presentation/widgets/extended_profile_widgets.dart` (4건) — 프로필 완성도 헤더
- `features/profile/presentation/screens/profile_tab.dart` (2건) — 스탯 캡션/구분선
- `features/parent_home/presentation/screens/parent_assignments_tab.dart` (3건) — 과제 카드
- `features/parent_home/presentation/screens/parent_dashboard_tab.dart` (3건) — CircleAvatar 배경 + 스탯 배경
- `features/practice/presentation/widgets/section_detail/recording_control.dart` (1건) — `waveColor`. **훅 `dart format` 자동 적용으로 148줄 diff 발생 — 의미 변경은 1건, 나머지는 순수 포매팅(삼항 전개/trailing comma 정규화)**
- `features/profile/presentation/screens/profile_preview_screen.dart` (2건) — 프리뷰 헤더/스탯
- `features/profile/presentation/screens/outstanding_payments_screen.dart` (2건) — 미수금 그라디언트 위 텍스트
- `features/practice/presentation/widgets/waveform/zoomable_waveform.dart` (2건) — 뷰포트 사각형 paint
- `features/students/presentation/screens/student_detail_screen.dart` (3건) — TabBar 비선택/배지 보더/악기 칩
- `features/practice/presentation/widgets/practice_streak_card.dart` (7건) — 스트릭 카드 텍스트/주간 점

**검증**:
- `flutter analyze lib/` → No issues found (12.7s)
- `flutter test` → 392/392 passed
- grep `Colors\.white\.withValues` features/ → 2 matches (둘 다 `tuner_cat_painters.dart` 일러스트 빔 — §7.47/§7.50 에서 회화적 예외로 제외 명시, 이 배치에서도 유지)
- 코드 커밋: `2853d51b` (14 files changed, 162 insertions, 133 deletions — 순수 변경은 38건이고 나머지는 recording_control 포매팅)

**스코프 분리 (의도적 누락)**:
- `Colors.white` 단독 19건 — Vermillion 위 paper 표기로 일괄 치환할지, "절대 백색" 의미가 있는 경우(이미지 플레이스홀더/카메라 UI) 별도 판정할지 Cycle 25 Candidate A 로 이월.
- `Colors.black` / `Colors.black.withValues(alpha:)` — Cycle 25 Candidate B. 스크림 검정은 §7.50 에서 `inkTertiary`(55%) 로 매핑했으나, 불투명 검정/alpha 가 1.0 에 가까운 경우 Notebook ink(`#14161C`, 완전 검정 아님) 와 시각 차이 발생. 별도 감사 필요.
- `instrument_colors.dart` 13개 악기별 hex 팔레트 — post-edit 훅이 `Color(0x` 패턴을 차단. 훅 스킵 등록(프로젝트 설정 변경)은 Cycle 25 Candidate C.

**§7.50 패턴 재확인 — alpha 래더의 완결**:
이번 cycle 로 Notebook 의 "ink/paper 두 뿌리 + alpha 래더" 가 Material `white` 계열을 전량 흡수. 남은 Material 잔재는 **단색**(`Colors.white`, `Colors.black`) 과 **팔레트 배열**(악기별 hex) 뿐이며, alpha 변형은 더 이상 features/ 에 존재하지 않는다. 회색·흰색·검정의 "투명도가 있는 중간톤" 은 모두 `ink.withValues(alpha: N)` 또는 `paper.withValues(alpha: N)` 로 수렴.

**훅 부산물 (비의미적)**:
`recording_control.dart` 의 148줄 diff 중 147줄은 post-edit 훅이 `dart format` 을 파일 전체에 재실행하며 발생한 **순수 포매팅**(이전 코드의 스타일 드리프트 교정). 로직 변경은 1줄(`waveColor`). 이는 훅이 강제하는 프로젝트 컨벤션의 비의미적 부산물로 수용.

**은유**: 장부 위에 비단 한 자락을 덮으면 글자가 반쯤 보인다 — Material 에선 "흰색 비단 70%", Notebook 에선 "크림 종이 70%". 같은 비단이 색조만 다를 뿐, 투명도 자체는 의미가 있어 그대로 유지된다. 오늘 14장의 장부 위에 덮인 38조각의 흰색 비단이 일제히 크림 비단으로 교체됐다. alpha 래더 — 100%→90%→80%→...→10% — 가 이제 두 뿌리(`ink`·`paper`) 의 줄기를 따라 매끈하게 이어진다. Material 의 수백 가지 투명 흰색 변형은 Notebook 에서 단 한 줄의 `AppColors.paper.withValues(alpha: N)` 호출로 귀결한다.

---

### 7.54 schedule/ 위젯 수강료·예약 확정 다이얼로그·도전 과제 카드 제목 Playfair 통일 — schedule/ 배치 #3 + 다이얼로그 테마 상속 패턴

**배경**: §7.51·§7.52 로 schedule/ 도메인 선생님/학생 주요 화면을 정리한 뒤, 세 번째 배치는 schedule/ **위젯 레이어** + gamification/ 1건으로 확장. schedule/widgets/ 9개 파일을 전수 스캔해 eligible 2건만 추출. 나머지 7건은 §7.30 exclusion (아바타 이니셜 5 + 동적 이름 2 + 동적 시간 1 + 동적 날짜+라벨 1 + 가격 1). 동일 배치에 **AlertDialog 테마 상속 전환 패턴** 이 처음 등장 — dialogTheme.titleTextStyle 이 §7.53 이전에 이미 Playfair dialogTitle 로 등록돼 있었던 점을 활용.

**변경표**:

| 파일 | 라인 | 제목 | 이전 스타일 | 이후 스타일 | 패턴 |
|------|------|------|-------------|-------------|------|
| `frontend/lib/features/schedule/presentation/widgets/regular_lesson_widgets.dart` | 656 | "월 수강료" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 direct |
| `frontend/lib/features/schedule/presentation/widgets/availability/booking_confirm_dialog.dart` | 68 | AlertDialog title (ternary "레슨 시간을 변경하시겠습니까?" / "예약을 확정하시겠습니까?") | `AppTypography.headingSmall.copyWith(fontWeight: w600)` | (style 제거 → dialogTheme 상속) | §7.41 cleanup |
| `frontend/lib/features/gamification/presentation/widgets/challenges_card.dart` | 51 | "도전 과제" | `AppTypography.headingSmall` | `NotebookTypography.sectionTitle` | §7.17 direct |

**설계 포인트**:
- **AlertDialog 테마 상속 전환 패턴**: `app_theme.dart:60` 의 `dialogTheme.titleTextStyle: NotebookTypography.dialogTitle` 이 이미 등록돼 있으므로, AlertDialog 의 `title: Text(..., style: X)` 형태에서 `style:` 인자를 제거하면 **자동으로 `dialogTitle`(Playfair 19/w700) 상속**. 기존 인라인 override 는 `AppTypography.headingSmall.copyWith(fontWeight: w600)` 였으므로, 제거 후 weight 가 w600→w700 로 올라감. 이는 Notebook dialogTitle 표준과 일치하는 승격. **향후 AlertDialog/Dialog 호출부는 style 인라인 override 를 모두 정리하는 것이 원칙**.
- **§7.41 cleanup 패턴과의 구조적 유사성**: §7.41 은 FloatingActionButton 인라인 override 를 `floatingActionButtonTheme` 으로 흡수, 이번은 AlertDialog 인라인 override 를 `dialogTheme.titleTextStyle` 로 흡수. 컴포넌트가 전역 테마를 갖는 경우 인라인 override 제거가 "stylistic diff 최소화 + 테마 일관성 보장" 의 최적 경로임을 재확인.
- **§7.30 제외 roster — schedule/ 위젯의 아바타 이니셜 군집**: 이번 스캔에서 §7.30 "avatar initials" 카테고리가 schedule/widgets/ 에 집중돼 있음이 드러남. 5 파일 5건:
  - `request_profile_card:120` (`name[0]`)
  - `teacher_approval_card:164,412` (`booking.studentName[0]` 2건)
  - `booking_card:70` (`booking.studentName[0]`)
  - `regular_lesson_widgets:47` (`studentName[0]`)

  이들은 원 모양 컨테이너(CircleAvatar) 안의 단일 문자 + 색 배경 + 화이트 텍스트 조합 — "사용자 생성 고유명사의 시각적 요약" 이라 §7.30 pieceTitle 과 판정 기준이 다르다. Sans-serif 로 유지해야 CircleAvatar 의 동그라미 안에서 글자 중심이 시각적으로 맞음(serif 의 세리프 꼬리는 원형 컨테이너에서 중심이탈 유발).
- **§7.30 제외 roster — gamification/ 의 level-title 토큰**: `badge_collection_screen:103` 은 `data.levelTitle` (예: "브론즈 견습생", "실버 연습생") 을 표시. 사용자 등급에 따라 문자열이 동적으로 바뀌는 **게이미피케이션 레벨 토큰** 이므로 §7.30 의 "level-title tokens" 범주. 동적 값이고 해당 화면의 핵심 "자랑 포인트" 라 Inter sans-serif 로 유지해 주목도를 확보.

**검증**:
- `flutter analyze` 3 files → No issues found (3.7s)
- Lore commit: `322a5486`

**은유**: 세 곳의 오래된 일기장에서 각자 다른 활자로 새긴 소제목 몇 줄을 찾아냈다. 한 장부의 "월 수강료" 는 카드 안에 숨은 정적 제목, 다른 장부의 "예약 확정" 은 다이얼로그의 외침, 세 번째 장부의 "도전 과제" 는 아이들이 매일 보는 도감의 장 제목. 셋 다 Playfair 로 옮겼지만 한 가지가 특별하다 — "예약 확정" 은 자기 활자를 고집하던 위치에서 **활자를 아예 빼버렸다**. 장부의 기본 표준(dialogTheme) 이 이미 Playfair 로 정해져 있으니, 굳이 각자 고를 필요가 없다. 빈 자리가 오히려 표준을 드러낸다. 장부 관리자는 이제 소제목 폰트를 일일이 지정하지 않는다 — 장부 전체의 약속이 이미 그 일을 한다.

---

### 7.55 profile/ 화면 예약 설정·악기 관리·계좌 편집 섹션 제목 Playfair 통일 — profile/ 도메인 §7.17 배치 #1

**배경**: schedule/ 도메인 3배치 완료(§7.51·§7.52·§7.54) 후 profile/ 로 이동. 이번 배치는 profile/ **화면 레이어** 3개 파일 7건을 전수 스캔해 eligible 7건 모두 §7.17 sectionTitle 로 전환. 페이지 섹션 헤더 2건 + `showModalBottomSheet` 내부 섹션 헤더 2건 + `DraggableScrollableSheet` 제목 1건 + 폼 섹션 헤더 2건이 섞인 **혼합 컨텍스트 배치**.

**변경표**:

| 파일 | 라인 | 제목 | 컨텍스트 | 패턴 |
|------|------|------|---------|------|
| `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart` | 228 | "예약 설정" | 페이지 섹션 | §7.17 direct |
| 〃 | 280 | "레슨 간 휴식 시간" | 바텀시트 섹션 (showModalBottomSheet) | §7.17 direct |
| 〃 | 329 | "최소 예약 가능 시간" | 바텀시트 섹션 (showModalBottomSheet) | §7.17 direct |
| `frontend/lib/features/profile/presentation/screens/instrument_management_screen.dart` | 98 | "현재 가르치는 악기" | 페이지 섹션 | §7.17 direct |
| 〃 | 198 | "악기 추가" | 페이지 섹션 | §7.17 direct |
| `frontend/lib/features/profile/presentation/screens/bank_account_edit_screen.dart` | 451 | "개인정보 수집·이용 동의" | DraggableScrollableSheet 제목 | §7.17 direct |
| 〃 | 504 | "계좌 추가" | 폼 섹션 | §7.17 direct |

**설계 포인트**:
- **showModalBottomSheet + BottomSheetHandle 없음 → sectionTitle**: `lesson_time_settings_screen` 의 두 바텀시트(`_showBreakTimeDialog`, `_showMinBookingHoursDialog`) 는 SafeArea + Column 구조로 **커스텀 핸들 프리픽스가 없음**. §7.27 appBarTitle 패턴(커스텀 핸들 + 상단 제목)과 달라 sectionTitle 판정. BottomSheet 제목의 Playfair 적용은 "커스텀 핸들 포함 여부"가 appBarTitle 대 sectionTitle 판별 기준임을 재확인.
- **DraggableScrollableSheet 역시 sectionTitle**: `bank_account_edit_screen:451` 의 "개인정보 수집·이용 동의" 는 DraggableScrollableSheet 내부 Padding + Text 구조. 다이얼로그가 아니므로 dialogTitle 아닌 sectionTitle 적용. 법적 문서 제목이지만 **섹션 헤더의 계층적 역할**은 동일.
- **폼 섹션 헤더도 sectionTitle**: `bank_account_edit_screen:504` 의 "계좌 추가" 는 Form + Column 안의 첫 Text. 페이지 루트의 섹션 구획 역할이므로 §7.17 적용.
- **§7.30 예외 해당 없음**: 7건 모두 **정적 라벨** 이고 동적 값·이름·날짜·시간·가격·아바타 이니셜·빈 상태·레벨 토큰 어디에도 해당되지 않음. 완전 eligible.

**검증**:
- `flutter analyze` 3 files → No issues found (4.0s)
- Lore commit: `c1924195`

**은유**: 장부의 표지를 새로 꾸미는 일이라면 이번엔 여러 서랍의 제목표를 동시에 바꿨다. 첫 서랍의 "예약 설정" 은 활짝 열린 장부의 소제목, 두 번째·세 번째 서랍의 "레슨 간 휴식 시간"·"최소 예약 가능 시간" 은 살짝 꺼내 보는 메모의 머리글, 네 번째 서랍의 "현재 가르치는 악기"·"악기 추가" 는 가로놓인 장부의 양면 제목, 다섯 번째 서랍의 "개인정보 수집·이용 동의"·"계좌 추가" 는 반쯤 접어둔 서식의 제목표. 서로 다른 형태의 제목표지만 **모두 같은 서체** 로 묶였다. 서랍이 달라도 장부 주인이 같으므로, 활자는 하나여야 한다.

---

### 7.56 profile/ 미수금·프로필 미리보기·확장 프로필·공개 프로필 시트 섹션 제목 Playfair 통일 — profile/ 배치 #2 + helper 전파 최적화

**배경**: profile/ 배치 #1(§7.55, 화면 레이어 3파일) 에 이어 이번 배치는 **helper 전파 패턴을 의도적으로 활용**. profile/ 영역에 산재한 `_buildSection`·`_buildSectionTitle` 같은 section title helper 2개를 한 번씩만 수정하여 9 개 정적 타이틀에 일괄 반영. 공통-우선 원칙(users direction: "공통을 수정하면 일괄반영이 가능하기때문에 공통수정쪽으로 설계되어야합니다") 의 정석 구현.

**변경표**:

| 파일 | 라인 | 제목 | 패턴 | 전파 효과 |
|------|------|------|------|---------|
| `frontend/lib/features/profile/presentation/screens/outstanding_payments_screen.dart` | 87 | "미수금 목록" | §7.17 direct | 1건 |
| `frontend/lib/features/profile/presentation/screens/profile_preview_screen.dart` | 350 | `_buildSection` helper `title` 파라미터 | §7.17 helper propagation | **6건** (소개/교수 스타일/전문 분야/학력/경력/자격증) |
| `frontend/lib/features/profile/presentation/screens/extended_profile_screen.dart` | 86 | `_buildSectionTitle` helper | §7.17 helper propagation | **3건** (학력/경력/자격증) |
| `frontend/lib/features/profile/presentation/widgets/profile_visibility_widgets.dart` | 514 | "공개 프로필 미리보기" | §7.27 appBarTitle | 1건 (BottomSheetHandle + title 조합) |

**설계 포인트**:
- **helper 전파 = 공통-우선 원칙의 정량적 증거**: 코드 교체는 4 라인이지만 렌더링 결과는 **11 개 섹션 타이틀** 이 Playfair 로 전환됨. 비율 2.75 배. profile/ 영역처럼 section helper 가 이미 존재하는 도메인에서는 helper 1 수정이 direct 1 수정보다 항상 우위.
- **§7.27 appBarTitle 판별 — BottomSheetHandle 의 위치**: `profile_visibility_widgets:512` 의 "공개 프로필 미리보기" 는 DraggableScrollableSheet 내부 Column 안에 `BottomSheetHandle` (line 499) + `Padding > Row > [Icon + Text + Spacer + IconButton]` 구조. **BottomSheetHandle 가 같은 Column 의 직전 자식** 이므로 §7.27 판별 적중. `lesson_time_settings_screen` 의 `showModalBottomSheet + SafeArea + Column` 구조와는 달리 handle 이 명시적으로 붙어 있어 appBarTitle 로 판정.
- **§7.30 예외 5건 정리 (profile/ 도메인)**:
  - Empty-state headline: `outstanding_payments_screen:48` "미수금이 없습니다"
  - 가격: `outstanding_payments_screen:224` `formatWonWithComma(subscription.amount)` (paperAccent 강조색)
  - 동적 연도 라벨: `payment_management_screen:244` `'$selectedYear년'` (IconButton 사이 동적 연도 스와이퍼)
  - 동적 요금 범위: `extended_profile_dialogs:177` `FeeRange(...).formatted` (슬라이더 아래 동적 금액)
  - 아바타 이니셜: `payment_detail_sheet:52` `payment.studentName[0]` (CircleAvatar 내부 화이트 문자)

**검증**:
- `flutter analyze` 4 files → No issues found (9.0s)
- Import cleanup: `extended_profile_screen.dart` 의 `app_typography` 임포트가 helper 교체 후 unused 가 되어 제거. AppTypography 를 참조하지 않는 `profile_preview_screen`/`outstanding_payments_screen` 도 기존 `bodyMedium`/`bodySmall` 등에서 계속 사용하므로 유지.
- Lore commit: `b73da2b8`

**은유**: 장부에는 때로 한 줄을 고치면 여러 페이지가 한꺼번에 바뀌는 공통 양식이 있다. profile 장부의 "미리보기 챕터" 와 "확장 프로필 챕터" 에는 바로 그런 **공통 제목 서식** 이 인쇄되어 있었다. 서식의 한 칸 — `_buildSection` 의 style 한 곳 — 을 Playfair 로 바꾸자 "소개"·"교수 스타일"·"전문 분야"·"학력"·"경력"·"자격증" 여섯 제목이 한꺼번에 새 서체로 갈아탔다. 한 번 더 — `_buildSectionTitle` 을 손대자 또 다른 세 제목이 따라 바뀌었다. 장부 관리자의 규칙은 명확하다: **같은 제목을 반복해서 쓴 자리에는 공통 서식이 있어야 하고, 그 공통 서식이 있어야 나중에 한 번에 바꿀 수 있다.** 이번 배치는 그 규칙이 일에서 얼마나 빛을 발하는지 보여주는 기록이다.

---

### 7.57 students/ 학생 상세 탭 연습·노트·레슨 섹션 제목 Playfair 통일 — students/ 위젯 레이어 §7.17 배치 #1

**배경**: profile/ 도메인 2배치(§7.55·§7.56) 완료 후 students/ 도메인으로 이동. screens 레이어(`student_detail_screen`, `students_tab`) 는 parallel session 이 점유 중이므로, 이번 배치는 **screens 우회 후 위젯 레이어 직진입** 전략. `students/widgets/student_detail/` 4개 파일 7건 모두 §7.17 sectionTitle 로 전환, 2건 §7.30 예외(동적 일자 + 동적 stat value) 를 명확히 분리.

**변경표**:

| 파일 | 라인 | 제목 | 컨텍스트 | 패턴 |
|------|------|------|---------|------|
| `frontend/lib/features/students/presentation/widgets/student_detail/student_practice_section.dart` | 32 | "이번 주 연습" | 카드 섹션 | §7.17 direct |
| `frontend/lib/features/students/presentation/widgets/student_detail/student_notes_section.dart` | 30 | "레슨 노트" | 카드 섹션 | §7.17 direct |
| `frontend/lib/features/students/presentation/widgets/student_detail/student_practice_tab.dart` | 79 | "이번 주 연습 요약" | 탭 섹션 | §7.17 direct |
| 〃 | 177 | "주간 연습 현황" | 탭 섹션 | §7.17 direct |
| 〃 | 316 | "공유된 녹음" | 탭 섹션 | §7.17 direct |
| `frontend/lib/features/students/presentation/widgets/student_detail/student_lessons_sections.dart` | 33 | "다가오는 레슨" | 카드 섹션 | §7.17 direct |
| 〃 | 120 | "최근 레슨" | 카드 섹션 | §7.17 direct |

**설계 포인트**:
- **screens 우회 전략**: parallel session 이 점유한 파일(`student_detail_screen.dart`, `students_tab.dart`) 과의 conflict 를 피하기 위해, 동일 도메인 안에서 **위젯 레이어로 진입점을 우회**. 학생 상세 화면의 섹션 제목은 대부분 **위젯 레이어의 하위 컴포넌트** 가 소유하므로, 이 전략이 실질 커버리지를 크게 떨어뜨리지 않음. 학생 상세 탭의 세 섹션(이번 주 연습 요약 / 주간 연습 현황 / 공유된 녹음) + 카드 섹션 4종이 모두 위젯 레이어에 분산돼 있어 7건 일괄 처리 가능.
- **§7.30 예외 2건 — 학생 상세 특유 패턴**:
  - `student_lesson_card:65` `'${lesson.date.day}'` — 레슨 카드의 상단 "날짜 숫자 + 요일" 조합에서 일자는 2자리 굵은 숫자(12/5/31 등). 동적 값이고 **달력 요소 성격** 이므로 Inter 유지.
  - `student_practice_tab:139` `Text(value, ...)` — `_StatCard` 의 아이콘 + value + label 3단 구조에서 value 는 동적 stat(예: "5.2h", "12회"). §7.30 "동적 stat 값" 카테고리 표준 대응.
- **카드 섹션 vs 탭 섹션 둘 다 sectionTitle**: `student_practice_section`/`student_notes_section` 은 카드 형태의 컴포넌트 헤더, `student_practice_tab` 은 SingleChildScrollView 의 큰 섹션 헤더, `student_lessons_sections` 은 둘 사이. 컨텍스트가 달라도 "섹션의 의미 기반 제목" 이면 sectionTitle 판정 — 이는 §7.17 의 범용성 재확인.

**검증**:
- `flutter analyze` 4 files → No issues found (3.6s)
- dart formatter 가 import 재정렬로 큰 diff 유발(153 insertions/128 deletions)이지만, semantic 변경은 7 라인 + 3 import. 포매터는 프로젝트 convention 이므로 수용.
- Lore commit: `e7d89513`

**은유**: 학생 장부는 한 학생마다 여러 탭 — 연습 기록, 레슨 노트, 받아온 녹음, 다가오는 일정 — 으로 나뉜다. 각 탭의 제목만 Playfair 로 바꿨는데, 특히 레슨 카드 위에 박힌 **"31"** 같은 굵은 일자와, 연습 요약의 "5.2h" 같은 **숫자가 말하는 제목** 은 손대지 않았다. 활자는 의미의 그릇이지, 숫자의 그릇은 아니다. 숫자는 Inter 의 가지런함이 더 어울린다 — 장부의 통계 페이지가 늘 그렇듯.

### 7.58 학생 대시보드 Notebook × Score 정리 — home audit Phase 4b 해소

**배경**: 2026-04-22 홈 통일성 감사(`home_screens_audit.md`) 에서 학생 홈이 FLAG 5.75 판정. 선생님 홈(PASS 9.5) 과 시각적 브랜드 일체감 부재. Material `Row` 헤더 + 0/6 Notebook 시그니처.

**수정**:
- `student_dashboard_tab.dart` Material Row 헤더(날짜+인사+IconButton×2) → `NotebookMasthead` + `_buildProgrammeTitle` 블록으로 교체
- `trailing` 파라미터에 `Row(친구초대 IconButton + 알림 IconButton)` 로 기존 기능 유지
- Programme Title: `Programme for ${englishWeekday}` + `'오늘의 연습'` + `${month}月 ${day}日 · 오늘도 화이팅!` + `ThinRule`
- 하단 `_buildFineFooter` 추가: `ThinRule` + Playfair italic `'Fine.'` + '연습 기록 더보기' TextButton → `AppRoutes.practice`
- 섹션 그룹핑: `TeacherFeedbackSection` + `PracticeSummarySection` + `TrialBookingsSection` 3개 → `learning_record_group.dart` 신규 wrapper 로 묶어 10 → 8 섹션으로 축약(내부 `ThinRule` 2개로 시각 구분)

**4대 필수 시그니처 커버리지**:
- Playfair italic: `NotebookTypography.masthead/mastheadLabel/mastheadDate/fine` 4곳
- Masthead 스캐폴드: `NotebookMasthead:107`
- ThinRule: 2곳 (Programme Title 하단 + Fine. 상단) + LearningRecordGroup 내부 2곳
- "Fine." footer: 존재

**제외**:
- Roman numerals 인덱스 — Phase 4c 선택 작업으로 이월 (NextLesson 카드 단일 항목은 인덱스 불필요)
- TimeContextBanner / GamificationHeader 내부 타이포 — 별 섹션의 자체 시각 언어 유지

**영향**:
- 수정 1 파일 (`student_dashboard_tab.dart` +127 / −46)
- 신규 1 파일 (`learning_record_group.dart` 34줄)
- 감사 점수: 5.75 FLAG → **8.59 PASS** (+2.84)

**검증**:
```bash
flutter analyze lib/features/student_home/
# No issues found! (ran in 9.9s)

grep -c "NotebookMasthead|NotebookTypography|ThinRule|'Fine\\.'" \
  lib/features/student_home/presentation/screens/student_dashboard_tab.dart
# 7 (NotebookMasthead×1, NotebookTypography×4, ThinRule×2)
```

**은유**: 감사 보고서에 따르면 학생 장부는 표지 없이 첫 장부터 본문이 시작되는 초고였다. 오늘의 조판은 선생님 장부에서 쓰던 **동일한 활자판** 을 그대로 옮겨왔다 — Playfair 의 eyebrow, Programme Title 의 중심 정렬, 얇은 선 한 줄, 페이지 끝의 "Fine." 까지. 그리고 3개의 산발적 피드백 섹션은 **"학습 기록"** 이라는 한 장으로 묶었다. 세 기록의 구분은 여전히 있지만(내부 Thin Rule), 독자의 눈에는 "한 페이지의 세 단락" 으로 읽힌다. Miller 가 말한 7±2 의 부담은, 이름을 붙이는 순간 반으로 준다.

### 7.59 parent_home/ 위젯 섹션·바텀시트 제목 Playfair 통일 — parent_home/ 도메인 §7.17/§7.27 배치 #1

**배경**: students/ 배치 #1 (§7.57) 완료 후 parent_home/ 진입. parent_home/screens/ 중 `parent_dashboard_tab`·`parent_assignments_tab`·`parent_payments_tab`·`parent_lessons_tab` 은 병행 세션 영향에서 벗어난 것으로 확인되었으나, 이번 배치는 먼저 **위젯 레이어 4 파일만** 선별하여 helper 전파 효과를 우선 확인한다. `SectionCard` 는 이 도메인에서 가장 많이 재사용되는 공통 카드 헬퍼이므로, 1회 수정으로 다수 호출부에 일괄 반영되는 "공통 먼저" 원칙의 모범 사례.

| 파일 | 라인 | 제목 | 치환 | 근거 |
|------|------|------|------|------|
| `section_card.dart` | 44 | `title` (parameter) | `sectionTitle` | §7.17 카드 헬퍼. 호출부 4곳(`parent_dashboard_tab`) 일괄 반영 |
| `profile_children_section.dart` | 208 | "자녀 추가 방법" | `sectionTitle` | §7.17 카드 섹션 |
| `profile_switcher.dart` | 393 | "프로필 전환" | `sectionTitle` | §7.17. `BottomSheetHandle` 없이 `showModalBottomSheet` 사용 → appBarTitle 아닌 sectionTitle 적용 |
| `notification_settings_sheet.dart` | 59 | "알림 상세 설정" | `appBarTitle` | §7.27. 파일 초입 `BottomSheetHandle` 존재 확인 |

**설계 포인트**:
1. **Helper 전파 최적화**: `SectionCard.title` 한 줄 수정 → 4 호출부(parent_dashboard_tab) 일괄 반영. 코드 1 → 렌더 5 (section_card 자체 + 4 호출부). §7.56 profile 배치의 helper 전파 패턴 재확인.
2. **section_card.dart import 교체**: `app_typography.dart` 가 유일 사용처였으므로 그대로 `notebook_typography.dart` 로 **교체**. §7.56 `extended_profile_screen` 와 동일 전략. 다른 3 파일은 `app_typography` 가 파일 내부에서 다른 용도(예: bodyMedium, caption 등)로 사용 중이므로 **추가** import.
3. **Sheet title 분류 재확인**: `BottomSheetHandle` 존재 여부가 판별 기준.
   - `notification_settings_sheet.dart` (handle 존재) → §7.27 `appBarTitle`
   - `profile_switcher.dart` (handle 부재, 단순 `showModalBottomSheet`) → §7.17 `sectionTitle`
4. **§7.30 제외 로스터 재확인**: `stat_card.dart:36` `Text(value, ...)` — dynamic stat value. Inter 의 균등함이 숫자 정렬에 적합하므로 Playfair 변환 불필요. 제외 로스터에 명시.
5. **병행 세션 회피 전략 지속**: `git status --short` 로 parallel-contested 파일 사전 확인 → schedule/screens, students/screens, profile screens, search, subscription screens 모두 회피. parent_home/widgets/ 가 uncontested 로 확보된 네 파일 모두 전환.

**§7.30 제외 누적 로스터 (11 → 12 항목)**:
1. 아바타 initial 글자 (CircleAvatar 내부)
2. Dynamic stat value (가격·카운트·날짜·시간)
3. Empty state headline
4. Error headline
5. Gamification level-title token
6. Dynamic name (teacher/student/opponent)
7. Calendar month label
8. Dynamic year/date label
9. Dynamic fee range
10. (§7.57) Student lesson card dynamic date
11. (§7.57) Student practice tab dynamic stat value
12. **(§7.59 신규)** Parent stat card dynamic stat value (`stat_card.dart:36`)

**검증** (commit `4ec26c28`):

```bash
flutter analyze \
  lib/features/parent_home/presentation/widgets/section_card.dart \
  lib/features/parent_home/presentation/widgets/profile_children_section.dart \
  lib/features/parent_home/presentation/widgets/notification_settings_sheet.dart \
  lib/features/parent_home/presentation/widgets/profile_switcher.dart
# Analyzing 4 items... No issues found! (ran in 8.9s)
```

**은유**: 학부모 장부의 공통 카드는 마치 편집자의 조판 틀과 같다. 네 편의 단락이 한 카드에 실릴 때, 카드 틀만 활자를 바꾸면 네 편 모두 같은 판형으로 다시 인쇄된다. 한 번의 조판 교체가 네 번의 재조판을 덜어낸다 — **공통은 손을 적게 쓰고 일을 많이 시키는 친구**다. 그리고 바텀시트의 두 가지 제목 스타일(§7.17 과 §7.27)은 독자에게 **표지의 유무** 를 알려주는 단서다: 핸들이 있는 시트는 "이건 임시로 열린 탭이니 언제든 닫아도 됩니다" 라고 말하고, 핸들이 없는 시트는 "이건 한 문단을 차분히 읽고 넘어가세요" 라고 말한다. 활자는 기능을 장식하지 않고 기능을 **번역** 한다.

### 7.60 parent_home/ 유도 카드·lessons/ 학습 자료 시트 제목 Playfair 통일 — §7.17/§7.27 교차 도메인 배치

**배경**: §7.59 parent_home/widgets/ 배치 완료 직후, 동일 도메인 screens 레이어와 uncontested lessons/widgets/ 중 §7.17/§7.27 전환 타겟이 남은 파일을 교차 탐색. parent_home/ 에서는 Phase 4a (commit `3e711f72`) 가 대시보드 masthead/Programme Title 구조를 먼저 바꿔놓은 상태라, `parent_dashboard_tab.dart` 잔존 headingSmall 8건은 모두 §7.30 제외 대상(가격·카운트·empty state·error headline)만 남음. 따라서 이번 배치는 남은 **의미 있는 3 파일**만 전환.

**배치 대상**:

| 파일 | 라인 | 제목 | 치환 | 근거 |
|------|------|------|------|------|
| `parent_assignments_tab.dart` | 114 | "이번 주 과제" | `sectionTitle` | §7.17. Accent 배너 내부 섹션 헤더. `color: Colors.white` copyWith 유지 |
| `unconnected_child_dashboard.dart` | 220 | "선생님과 연결하세요" | `sectionTitle` | §7.17. 연결 유도(CTA) 카드 제목. Empty state 아닌 action-prompt |
| `unconnected_child_dashboard.dart` | 468 | `title` (helper) | `sectionTitle` | §7.17. `_FeatureCard(icon+title+subtitle)` helper. 호출부 1곳(`_buildFeatureCards` line 166 "연습 기록") |
| `resource_attachment_section.dart` | 311 | "학습 자료 추가" | `appBarTitle` | §7.27. `BottomSheetHandle` at line 313 |
| `resource_attachment_section.dart` | 400 | "내 학습 자료" | `appBarTitle` | §7.27. `BottomSheetHandle` at line 399 |

**설계 포인트**:
1. **교차 도메인 배치 근거**: parent_home/ 은 §7.59 직후 남은 연속성, lessons/ 은 동일 세션 병렬 탐색에서 uncontested 로 확보. 두 도메인 모두 `BottomSheetHandle` 판별 원칙이 그대로 적용되므로 같은 배치로 묶어도 논리 혼선 없음.
2. **Phase 4a 와의 스코프 분리**: `3e711f72` 는 `parent_dashboard_tab.dart` 와 `unconnected_child_dashboard.dart` 일부 영역에 `Colors.white → AppColors.paper` 치환을 반영했으나, 타이포 변환(`headingSmall → sectionTitle`)은 수행하지 않았다. 이번 배치는 타이포 축만 전환 — 색상 축과 **서로 겹치지 않는 diff** 로 혼합 없이 반영.
3. **§7.17 sectionTitle 의 광범위 적용성 재확인**: 배너(accent 배경) / 연결 유도 카드 / 기능 설명 helper / 시트 내 섹션 — 네 가지 다른 컨텍스트가 모두 `sectionTitle` 로 수렴. §7.30 만 제외하면 §7.17 이 가장 일반적인 선택지임을 실전에서 반복 검증.
4. **parent_dashboard_tab.dart 잔존분 §7.30 근거 기록**: 라인 154 "등록된 자녀가 없습니다" (empty state headline), 라인 484 "28" (dynamic count), 라인 661 "300,000원" (가격). 모두 기존 §7.30 로스터 항목. 다음 배치에서는 건드리지 않음을 명시.

**Parallel-session race condition 기록** (교훈):
- 중간 `git commit` 이 "no changes added to commit" 으로 실패.
- 원인: Parallel session (`3e711f72`, "Autopus Cycle 28 / Phase 4a") 이 동일 3 파일에 대한 staging 을 가로채면서 내 stage 가 잠시 비워짐.
- 해결: 동일 파일 재확인 후 `git add && git commit` 을 **단일 Bash 호출** 로 chain → race window 최소화.
- 재발 방지: 병행 세션 감지 시 code batch 는 항상 `git add && git commit` 을 **&&** 로 묶어 단일 명령으로 실행. README commit 은 별도 세션으로 분리 가능 (충돌 가능성 낮음).

**검증** (commit `20147b55`):

```bash
flutter analyze \
  lib/features/parent_home/presentation/screens/parent_assignments_tab.dart \
  lib/features/parent_home/presentation/screens/unconnected_child_dashboard.dart \
  lib/features/lessons/presentation/widgets/resource_attachment_section.dart
# Analyzing 3 items... No issues found! (ran in 3.2s)
```

**은유**: 서로 다른 장부가 나란히 책상에 놓여 있었다 — 한 장부는 학부모의 주간 점검표, 다른 장부는 선생님의 학습 자료 서랍. 두 장부의 표지는 다르지만 **인쇄 기계는 같다**. 오늘의 작업은 새로 찍어낸 활자(Playfair)를 두 장부에 동시에 얹는 일이었다. 그 사이 옆 책상에서 다른 편집자(병행 세션)가 내 활자판에 손을 대려던 찰나가 있었지만, 빠르게 인쇄기로 밀어넣으면서(`add && commit` chain) 활자를 지켜냈다. 편집실에서는 속도가 때로 논리보다 중요한 순간이 있다.

### 7.61 학부모 대시보드 Notebook × Score 정리 — home_screens_audit §2.3 BLOCK 해소 (Phase 4a)

**배경**: `home_screens_audit.md` Cycle 26 감사에서 학부모 홈이 **BLOCK 4.30** 판정. 선생님 9.5 / 학생 5.75 와 극단적 불균형 — Material `AppBar('학부모 홈')` + Notebook 시그니처 0/6 + Colors.white 8건 + 우선순위 주석 부재. Cycle 27 (학생 FLAG → PASS 8.59) 완료 후 남은 마지막 블로커.

**수정 파일 (1)**: `frontend/lib/features/parent_home/presentation/screens/parent_dashboard_tab.dart` (+184/−82)

**변경 요약**:

| 항목 | Before | After |
|------|--------|-------|
| 헤더 스캐폴드 | `Scaffold + AppBar(title: '학부모 홈', actions: [swap_horiz])` | `ColoredBox(paper) + SafeArea + NotebookMasthead('LESSONAZA', meta: VOL/NO, trailing: swap_horiz IconButton)` |
| Programme Title | 없음 | `'Programme for $dayLabel'` + `'$name의 레슨'` + `'$month月 $day日 · $instrument'` + ThinRule |
| 정보 계층 주석 | 섹션명만 | 0~5순위 주석 (자녀 정보 → 통계 → 다음 레슨 → 스트릭 → 과제 → 결제) |
| Fine. 푸터 | 없음 | ThinRule + Playfair italic "Fine." |
| Colors.white | 8건 (line 172, 262, 335, 348, 366, 391, 397, 583) | `AppColors.paper` 8건 치환 (replace_all) |

**Notebook 시그니처 적용**: 4/6 — `NotebookMasthead` ×1, `NotebookTypography.masthead/mastheadLabel/mastheadDate` ×4, `ThinRule` ×2, Playfair italic "Fine." ×1. Roman numerals 는 Phase 4c 대상으로 보류.

**검증**:

```bash
flutter analyze lib/features/parent_home/presentation/screens/parent_dashboard_tab.dart
# No issues found! (ran in 7.4s)
```

**점수 변화**: `home_screens_audit.md §2.3` BLOCK 4.30 → PASS 8.58 (+4.28). 세 홈 모두 PASS 달성:
- 선생님 9.5 / 학생 8.59 / 학부모 8.58

**결정 근거**:
1. **AppBar 제거 우선순위 최상단**: 홈 화면 통일성의 핵심은 상단 스캐폴드. AppBar 잔존 시 "같은 앱인가?" 인지 부조화 유발.
2. **Colors.white → paper 일괄 치환**: Vermillion 다크 히어로 위 foreground 는 원래부터 "브랜드 백색"(AppColors.paper)의 의미. Material 기본 색은 의미 누락.
3. **Roman numerals 보류**: 자녀 전환 UI 복잡성(조건부 다중 자녀 선택) + 섹션 인덱스 가산은 별도 검토. Phase 4c 에 회송.
4. **커밋 분리**: 코드(`fd564014`) + 문서(후속) 분리 — 병행 세션과의 파일 충돌 방지. Cycle 28 개시 시 파일 3건 우발 스테이징 → 재 커밋 사이클 학습.

**은유**: 학부모 장부의 표지가 드디어 같은 활자공의 손에서 찍혔다. 전에는 학부모 장부만 다른 인쇄소의 조판 — 같은 책장에 꽂혀 있어도 시리즈 의혹을 불러일으켰다. 이제 세 장부(선생님·학생·학부모) 가 같은 활자판, 같은 잉크, 같은 종이결. 독자는 표지를 보고 "같은 시리즈" 를 망설임 없이 확인한다. 활자의 일체감은 읽기의 속도를 늘리고, 의심을 줄인다 — **통일은 주의를 해방시킨다**.

---

### 7.62 practice/widgets 카드 섹션 제목 Playfair 통일 — practice/ 도메인 §7.17 배치 #1

**트리거**: parent_home/·lessons/ 교차 도메인(§7.60) 완료 후, practice/widgets/ 레이어의 잔존 `AppTypography.headingSmall` 카드 제목을 §7.17 로 맞추기 위한 첫 배치.

**변경 파일 (4 files / 5 transfers)**:

| 파일 | 라인 | 카드 제목 | 호출부 | 렌더 수 |
|---|---|---|---|---|
| `practice/widgets/goal/goal_progress_widget.dart` | 75 | "오늘의 목표" | 직접 | 1 |
| `practice/widgets/pitch_analysis_card.dart` | 47 | "피치 분석" | 직접 | 1 |
| `practice/widgets/section_form/date_range_section.dart` | 65 | "연습 기간" | 직접 | 1 |
| `practice/widgets/section_form/add_section_widgets.dart` | 43 (`SectionHeader`) | `title` prop | `edit_repertoire_screen:283` | 1 |
| `practice/widgets/section_form/add_section_widgets.dart` | 144 (`SettingSectionHeader`) | `title` prop | `edit_repertoire_screen:362` + `RepeatCountSection` + `TargetTimeSection` | 3 |

**양적 헬퍼 전파**: 5 code-line edits → **8 rendered titles** (3 direct + 1 single-call helper + 4 multi-call helper). §7.56·§7.59·§7.60 에 이어 헬퍼 우선 패턴의 네 번째 사례 — 단일 편집점이 호출 그래프를 따라 확산.

**§7.30 제외 (practice/widgets/ 내부)**:

| 파일 | 라인 | 사유 |
|---|---|---|
| `history_summary_card.dart` | 82 | 동적 stat value |
| `practice_tools_modal.dart` | 163 | TabBar `unselectedLabelStyle` (Text 위젯 아님) |
| `circular_tuner_indicator.dart` | 367 | cent 수치 (동적 value) |
| `month_group_header.dart` | 43 | 캘린더 월 라벨 (동적 날짜) |
| `section_detail/practice_stats_card.dart` | 80 | 동적 stat value |
| `stats/stats_summary_card.dart` | 131 | 동적 stat value |
| `tuner/tuner_cat_widgets.dart` | — | 병렬 세션 수정 진행 중 (skip) |

정적 카드 제목과 동적 수치·계산값을 분리하는 §7.30 원칙 그대로 적용.

**커밋**: `a4044d77 feat(notebook): practice/widgets §7.17 카드 섹션 제목 Playfair 통일`

**검증**: `flutter analyze <4 files>` → `No issues found`.

**은유**: 한 명의 활자공이 다섯 개 틀(frame) 을 동시에 갖고 있는데, 두 개 틀은 여러 책자에서 공용으로 쓰인다. 이 날 활자공은 다섯 틀의 활자만 바꾸면 여덟 페이지의 표제가 한꺼번에 같은 서체로 찍혀 나온다. 다섯 번의 손길로 여덟 번의 인쇄가 정돈된다 — **공용 틀(helper) 의 경제학**. 학생이 레퍼토리를 편집할 때 보이는 제목, 반복 설정을 조절할 때 보이는 제목, 목표시간을 고를 때 보이는 제목 — 세 곳의 인상이 같은 활자공의 결정 하나로 동시에 변한다.

### 7.63 Roman numerals 학생/학부모 홈 섹션 인덱스 통일 — home_screens_audit §7.3 Phase 4c 해소

**배경**: Cycle 28 에서 학부모 홈 Notebook 4/6, 학생 홈 Notebook 4/6 달성 후 audit §7.3 의 선택 작업(Roman numerals)만 남았다. 선생님 홈(`dashboard_tab.dart:307,387`) 은 `romanOf(index)` 을 섹션 카운트·리스트 인덱스에 이미 사용 중. 학생·학부모 홈은 Roman numerals 0/1 로 시각 리듬이 한 박자 허전했다.

**수정 파일 (3)**:

| 파일 | 변경 |
|------|------|
| `parent_home/widgets/section_card.dart` | `int? romanIndex` optional prop 추가. romanIndex 전달 시 icon 앞에 `NotebookTypography.roman` 로마숫자 렌더 |
| `parent_home/screens/parent_dashboard_tab.dart` | 4개 `SectionCard` 호출부(다음 레슨·이번 주 연습·과제 현황·결제 현황) 에 `romanIndex: 0~3` 부여 |
| `student_home/widgets/dashboard/next_lesson_card.dart` | "다음 레슨" 레이블 Row 에 `${romanOf(0)}.` prefix (paper 0.9 alpha, fontSize 12) |

**설계 결정**:

1. **SectionCard API 확장 vs title 문자열 hack**: `title: 'I · 다음 레슨'` 로 문자열에 박는 방식은 단순하지만 sectionTitle Playfair italic 스타일로만 렌더 — `NotebookTypography.roman` 시그니처 효과 소멸. optional prop 방식으로 시그니처 보존 + 향후 확장 여지.
2. **다크 배경 위 Roman**: 학생 NextLesson 카드의 `AppColors.ink` 다크 배경 위에서는 `NotebookTypography.roman` 의 기본 ink 색이 가려짐. `paper.withValues(alpha: 0.9)` 로 paper 색 유지 + 반투명으로 무게 조절.
3. **인덱스 시작값**: 선생님 홈은 "Today's Programme" 카운트 = 1 (로마숫자 `I`). 학부모는 섹션이므로 `I, II, III, IV`. 0-based `romanIndex` 가 `romanOf(0)='I'` 를 반환하므로 호출부는 `0,1,2,3` 전달 = 화면에는 `I,II,III,IV` 표시.
4. **QuickStats는 Roman 제외**: StatCard 3개 수평 배치 — SectionCard 래퍼가 없어 Roman 부여 불가. 디자인 상 "섹션 1개" 로 취급하는 것이 자연스러움.

**검증**:

```bash
flutter analyze lib/features/parent_home/presentation/widgets/section_card.dart \
  lib/features/parent_home/presentation/screens/parent_dashboard_tab.dart \
  lib/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart
# No issues found! (ran in 7.2s)
```

**점수 변화** (audit §2.2.1, §2.3.1):
- 학생 홈: 8.59 → **9.17 PASS** (Notebook 시그니처 4/6 → 5/6)
- 학부모 홈: 8.58 → **9.17 PASS** (Notebook 시그니처 4/6 → 5/6)
- 세 홈 모두 9점대 진입 (선생님 9.5 / 학생 9.17 / 학부모 9.17)

**은유**: 세 장부의 장(章) 번호가 드디어 일치한다. 전에는 선생님 장부만 로마숫자 쪽 번호로 단장됐고, 학생·학부모 장부는 번호 없는 민무늬 제목만 달려 있었다. 독자가 페이지를 넘길 때 **번호가 진행감을 만든다** — "I. 다음 레슨 → II. 이번 주 연습 → III. 과제" 의 리듬이 생기면 스크롤은 **읽기** 가 되고, 없으면 스크롤은 **찾기** 로 떨어진다. 로마숫자는 장식이 아니라 **시간의 방향** 이다.

---

### 7.64 practice/widgets 바텀시트·다이얼로그 제목 Playfair 통일 — practice/ 도메인 §7.27 배치 #1

**트리거**: §7.62(practice/widgets/ §7.17 배치) 에 이어, 같은 도메인의 바텀시트·다이얼로그 상단 제목 5종을 §7.27 / dialogTitle 패턴으로 맞추기 위한 배치.

**변경 파일 (5 files / 5 transfers)**:

| 파일 | 라인 | 제목 | 패턴 | 토큰 |
|---|---|---|---|---|
| `practice/widgets/teacher_feedback_sheet.dart` | 153 | `AppStrings.recordingFeedbackTitle` | BottomSheetHandle + `_Header` | `appBarTitle` (§7.27) |
| `practice/widgets/notes/note_edit_dialog.dart` | 85 | `isEditing ? '연습노트 수정' : '연습노트 추가'` | `Dialog` 위젯 헤더 Row | `dialogTitle` |
| `practice/widgets/metronome/metronome_full_screen_modal.dart` | 195 | `'메트로놈'` | BottomSheetHandle + `_Header` | `appBarTitle` (§7.27) |
| `practice/widgets/tuner/tuner_settings_sheet.dart` | 51 | `'튜너 설정'` | BottomSheetHandle + 상단 Padding+Text | `appBarTitle` (§7.27) — `.copyWith(bold)` 제거 (이미 w700) |
| `practice/widgets/section_form/range_picker_sheet.dart` | 79 | `widget.title` | modal sheet + Cancel/Title/Confirm Row | `appBarTitle` (§7.27) |

**패턴 확장**:
- §7.27 은 지금까지 "BottomSheetHandle + 상단 제목" 으로 좁게 기술되었으나, 이 배치는 **Cancel/Title/Confirm 3열 Row 헤더(handle 없음)** 도 같은 범주에 포함. 핵심 기준은 handle 유무가 아니라 **모달 시트의 최상단 제목 블록** 인지 여부.
- dialogTitle: `showDialog` + `Dialog` 위젯의 헤더는 `appBarTitle`(18) 이 아니라 한 단계 위 `dialogTitle`(19) 적용. Dialog 는 화면 중앙에 떠오르는 독립 컨텍스트로, 시트(sheet) 보다 높은 위계를 가진다 (§7.x dialogTitle 패턴 강화).

**§7.30 제외 (practice/widgets/ 내부, 이 배치 범위 외)**:
- `tuner/tuner_settings_sheet.dart` 내부 섹션 제목 (Reference Frequency 등) 은 정적이면 §7.17 대상. 다음 배치에서 처리.
- `metronome_full_screen_modal.dart` 내부 세부 섹션 (BPM, Time Signature 라벨 등) — 동적 수치는 §7.30, 정적 레이블은 §7.17 대상.
- `tuner/tuner_cat_widgets.dart` 는 병렬 세션 수정 진행 중 (skip 유지).

**커밋**: `ee7b229e feat(notebook): practice/widgets §7.27 바텀시트·다이얼로그 제목 Playfair 통일`

**검증**: `flutter analyze <5 files>` → `No issues found`.

**은유**: 다섯 개의 작은 방(sheet, dialog) 이 각기 다른 문패를 달고 있었다 — 하나는 맨손 글씨, 하나는 인쇄 서체, 하나는 굵은 고딕. 같은 건물 안인데 방마다 다른 서체가 붙어 있으니 방문자는 각 방에 들어설 때마다 "여기는 다른 곳인가?" 의심한다. 오늘 다섯 방 문패가 모두 같은 활자공의 Playfair 로 교체되었다. 방은 여전히 다섯 개지만 건물은 하나로 느껴진다 — **시트와 다이얼로그도 같은 책의 접지(折紙)**, 펼치는 방식만 다를 뿐.

### 7.65 Colors.black 그림자 → AppColors.ink 팔레트 통일 (17 files 일괄)

**배경**: Cycle 25 에서 `grep -rn "Colors\.black"` 검색을 통해 `BoxShadow(color: Colors.black.withValues(alpha: 0.05~0.1))` 패턴이 17개 파일에 퍼져 있음을 식별. Notebook 팔레트 원칙(`AppColors.ink` = #14161C) 과 Material Default 팔레트(`Colors.black` = #000000) 의 혼재 — alpha 0.05 기준 시각적 차이는 거의 없지만 **토큰 레이어 분리 부재**가 디자인 시스템 감사 도구를 무력화. Cycle 25 ~ 29 간 home_screens_audit 후속 작업에 밀려 uncommitted 로 누적되었다가 Cycle 30 에 일괄 해소.

**수정 파일 (17, 도메인별 묶음)**:

| 도메인 | 파일 수 | 대표 파일 |
|--------|---------|----------|
| practice (tuner) | 1 | `tuner_cat_widgets.dart` |
| profile | 3 | `profile_tab.dart` / `payment_card.dart` / `repertoire_management_widgets.dart` |
| schedule (screens + widgets) | 7 | `schedule_tab.dart` / `booking_reschedule_screen.dart` / `availability_booking_preview.dart` 등 |
| search | 2 | `academy_detail_screen.dart` / `teacher_search_filter_sheet.dart` |
| students | 2 | `students_tab.dart` / `student_detail_screen.dart` |
| subscription | 2 | `proposal_detail_screen.dart` / `renewal_detail_screen.dart` |

**치환 패턴**: `Colors.black.withValues(alpha: X)` → `AppColors.ink.withValues(alpha: X)` (23건 전부 alpha 0.05 ~ 0.1).

**보존 결정**:

1. **`Colors.white` 는 치환하지 않음**: 일부 파일에 `isSelected ? Colors.white : AppColors.ink` 같은 selected-state foreground 가 있다. 이건 Vermillion 다크 히어로가 아닌 일반 Material selected state — 기존 Notebook § 규약(§7.50 Vermillion 위 foreground 만 paper) 상 보존 대상.
2. **dart format 재배치 동반**: post-edit hook (`.claude/scripts/post-edit-check.sh`) 이 자동 실행한 공백·줄바꿈 정리. Colors.black 치환 23건 외 나머지 diff 는 포매터 결과 — 기능적 무해.

**검증**:

```bash
flutter analyze <17 files>
# Analyzing 17 items... No issues found! (3.3s + 6.7s, 두 배치)
```

**커밋**: `5bd7cf52 style(notebook): Colors.black 그림자 → AppColors.ink 팔레트 통일 (17 files)`

**범위 챌린지 반성**: Cycle 25 에서 17 파일 한 번에 수정 완료 후 커밋 타이밍을 놓쳐 4~5 Cycle 간 working tree 에 누적. 다음부터는 **같은 세션에서 변경-커밋 사이클을 닫지 않으면 working tree 가 압축(compaction) 직전 잠재 쓰레기** 가 된다는 교훈. `.claude/rules/workflow.md` 의 "작업 완료 체크리스트" 에 "변경 후 세션 내 커밋" 항목 추가 검토.

**은유**: 건물 17채의 그림자 색이 다 다른 게 아니라, 사실 거의 같은 검정이었다 — 그러나 페인트 통은 세 통이었다. 오늘의 작업은 "색이 다르지 않으니 되지 않느냐" 가 아니라 "**같은 통에서 찍자**" 를 택했다. 감사자(디자인 감사 도구) 는 페인트 통의 이름표를 읽지 색을 보지 않기 때문이다. 같은 통에서 찍힌 그림자는 같은 표식(`AppColors.ink`) 으로 감사되며, 같은 표식은 한 번의 결정(토큰 변경) 으로 17채의 그림자를 동시에 바꿀 수 있다 — **토큰의 경제학**.

---

### 7.66 practice/screens 폼·상세 섹션 제목 Playfair 통일 — practice/ 도메인 §7.17 배치 #2

**트리거**: §7.62(practice/widgets/ §7.17 배치 #1) + §7.64(practice/widgets/ §7.27 배치 #1) 에 이어, practice/screens/ 레이어의 잔존 `AppTypography.headingSmall` 섹션 제목을 §7.17 로 맞추기 위한 배치 #2.

**변경 파일 (5 files / 9 edits → 10 rendered titles)**:

| 파일 | 라인 | 제목 | 렌더 |
|---|---|---|---|
| `practice/screens/quick_add_screen.dart` | 349 | '섹션 목록' | 1 |
| `practice/screens/section_detail_screen.dart` | 178 | '연습기록' | 1 |
| `practice/screens/section_detail_screen.dart` | 200 | '녹음' | 1 |
| `practice/screens/edit_section_screen.dart` | 342 | '범위 유형' | 1 |
| `practice/screens/edit_section_screen.dart` | 373 | '마디 범위 *' | 1 |
| `practice/screens/edit_section_screen.dart` | 393 | '줄 범위 *' | 1 |
| `practice/screens/add_section_screen.dart` | 421 | '범위 유형' | 1 |
| `practice/screens/add_section_screen.dart` | 463 | ternary '마디/줄 범위 *' | 1 |
| `practice/screens/practice_goal_setting_screen.dart` | 265 (`_buildSectionHeader`) | `title` prop | 2 (일일 목표 / 주간 목표) |

**양적 헬퍼 전파**: 9 code-line edits → **10 rendered titles** (8 direct + 1 ternary + 1 helper×2). 헬퍼 우선 패턴 다섯 번째 사례 (§7.56·§7.59·§7.60·§7.62 이어서).

**§7.30 제외 (practice/screens/ 동일 배치 내)**:

| 파일 | 라인 | 내용 | 사유 |
|---|---|---|---|
| `quick_add_screen.dart` | 414 | '섹션 ${index + 1}' (paperAccent) | 동적 인덱스 라벨 |
| `edit_section_screen.dart` | 301 | `_repertoire!.name` (paperAccent) | dynamic name |
| `add_section_screen.dart` | 319 | `_repertoire!.name` (paperAccent) | dynamic name |
| `section_picker_screen.dart` | 202 | '섹션이 없습니다' (inkSecondary) | empty state headline |

§7.30 exclusion roster 지속 적용 — 동적 값·이름·빈 상태는 Gothic 계열 유지로 정보 위계 구분.

**커밋**: `c38db867 feat(notebook): practice/screens §7.17 폼/상세 섹션 제목 Playfair 통일`

**검증**: `flutter analyze <5 files>` → `No issues found`.

**부수 포맷터 reflow**: `quick_add_screen.dart` 는 비정규 포맷 상태였던 탓에 PostToolUse dart formatter 가 대량 reflow (156+/105- 라인 중 대부분 whitespace/wrap). 로직 변경 없음.

**practice/ 도메인 §7.17/§7.27 완료 현황**:
- §7.17 widgets: §7.62 (5 transfers → 8 renders)
- §7.27 widgets: §7.64 (5 transfers → 5 renders)
- §7.17 screens: §7.66 (이번, 9 transfers → 10 renders)
- 누적 **19 transfers → 23 renders** in practice/ 도메인 전체

**은유**: 악보 가게의 서재(screens)와 진열장(widgets) 이 드디어 같은 활자공의 서체로 정돈된다. 서재에는 대형 악보(폼 화면), 진열장에는 소형 카드(위젯). 전에는 서재의 라벨과 진열장 라벨이 미묘하게 달라 방문자는 "여기가 같은 가게 맞나" 순간 의심했다. 오늘 '섹션 목록' · '연습기록' · '녹음' · '범위 유형' · '마디 범위 *' · '줄 범위 *' · '일일 목표' · '주간 목표' — 여덟 개의 서재 라벨이 모두 같은 서체로 교체되었다. 고객의 시선은 라벨 서체에 걸리지 않고 **내용** 으로 흐른다 — **통일은 주의를 해방시킨다**(§7.61 은유 재인용).

### 7.67 students_tab 헤더 Notebook masthead 승격 — 탭 레벨 홈 일관성

**트리거**: 선생님 주요 탭 3종 중 홈(`dashboard_tab`), 학부모/학생 홈은 이미 `NotebookMasthead` + `Programme Title` 2단 구조로 PASS 9점대 (home_screens_audit §2.1·§2.2·§2.3). 반면 선생님이 가장 자주 들르는 "학생 관리" 탭(`students_tab.dart`) 은 `AppTypography.headingLarge` 로만 표시되어 탭 간 시각 언어 단절. "선생님 학생화면의 Notebook 전환" 디렉티브의 1순위 대상.

**변경 파일 (1 file, 69+/19-)**:

| 파일 | 영역 | 변경 |
|---|---|---|
| `students/presentation/screens/students_tab.dart` | `_buildHeader()` 재작성 | 단일 Row → Column (Masthead + ProgrammeTitle + ThinRule + 액션 Row) |

**적용 시그니처 (4/6)**:

| 시그니처 | 적용 위치 |
|---|---|
| `NotebookMasthead` | eyebrow "STUDENTS" + trailing `check_box_outlined` (선택 모드 진입) |
| `NotebookTypography.mastheadLabel` | "Programme of Students" (Playfair italic 소제목) |
| `NotebookTypography.masthead` | "학생 관리" (Playfair large) |
| `ThinRule` | ProgrammeTitle 하단 1px 분리선 |
| `romanOf` | `_volumeIssueString` meta 생성 (VOL. · NO.) |

**보존 결정**:
1. **선택 모드는 masthead 승격 제외**: `_isSelectionMode == true` 일 때는 기존 "N명 선택됨 / 취소" 단순 Row 유지. 선택 모드는 **일시적 작업 맥락**(홈이 아닌 툴바)이므로 Playfair masthead 로 승격하면 "홈인가? 작업인가?" 혼란을 유발. 분리는 의도적.
2. **선택 진입 버튼은 TextButton → IconButton 로 승격**: `check_box_outlined` 아이콘으로 Masthead trailing 자리에 통합. "선택" 텍스트 TextButton 이 Masthead eyebrow 와 경쟁하는 문제 해소.
3. **학생 추가 FilledButton 은 Masthead 바깥 별도 Row 에 배치**: Masthead 는 감정 낮은 선언적 헤더, FilledButton 은 강한 CTA → 분리하여 시각 위계 명확화.

**검증**: `flutter analyze students_tab.dart` → `No issues found! (3.2s)`.

**탭 레벨 일관성 현황**:

| 탭 | 파일 | Masthead | Notebook 시그니처 |
|---|---|---|---|
| 선생님 홈 | `home/dashboard_tab.dart` | ✅ "LESSONAZA" | 6/6 (감사 PASS 9.5) |
| 학생 홈 | `student_home/student_dashboard_tab.dart` | ✅ | 5/6 (감사 PASS 9.17) |
| 학부모 홈 | `parent_home/parent_dashboard_tab.dart` | ✅ | 5/6 (감사 PASS 9.17) |
| 학생 관리 | `students/screens/students_tab.dart` | ✅ "STUDENTS" (이번) | 4/6 |
| 일정 | `schedule/screens/schedule_tab.dart` | ❌ | 0/6 (다음 후보) |

**다음 후보**: `schedule_tab.dart` (선생님 일정 탭, 845줄). students_tab 과 동일 패턴으로 승격 가능.

**은유**: 네 개의 탭 바로 이루어진 선생님의 책상 위, 세 개 탭(홈·학생 홈·학부모 홈)은 같은 활자공이 찍은 Playfair 머리글자로 시작했는데 네 번째 탭(학생 관리)만 혼자 고딕 볼드로 소리쳤다 — 같은 책상인데 한 서랍만 다른 공방에서 만든 손잡이가 달려 있는 셈. 오늘 그 서랍의 손잡이가 교체되었다. 책상은 이제 **하나의 공방 작품**으로 보인다 — 일정 탭이라는 다섯 번째 서랍만 교체되면 책상 전체가 완전해진다.

---

### 7.68 subscription/widgets 폼·요약·모달 제목 Playfair 통일 — subscription/ 도메인 §7.17/§7.27 배치 #1

**트리거**: 수강권 발급 폼은 "유형 → 기간 → 정가 → 결제 방식 → 시작일 → 레슨 장소 → 이동시간 → 요약" 의 8단계 서식으로 구성되는데, 섹션 제목이 모두 Gothic `AppTypography.headingSmall` 로 선언되어 있어 Notebook × Score 의 Playfair 섹션 규칙과 불일치했다. 모달 시트(sessionCancelTitle) 까지 포함하여 subscription/widgets/ 전체를 일괄 정돈한다.

**변경 파일 (7 files / 12 code edits → 20 rendered titles)**:

| 파일 | 라인 | 제목 | 패턴 | 렌더 |
|---|---|---|---|---|
| `chip_input_field.dart` | 75 (헬퍼 `title` prop) | - | §7.17 | **9** (lesson_policy ×5 + issue_form_type_options ×2 + issue_form_discount_bonus ×2) |
| `issue_form_sections.dart` | 28 | '수강권 유형' | §7.17 | 1 |
| `issue_form_sections.dart` | 164 | '결제 방식' | §7.17 | 1 |
| `issue_form_sections.dart` | 344 | '정가' | §7.17 | 1 |
| `issue_form_sections.dart` | 455 | '시작일' | §7.17 | 1 |
| `issue_form_summary_widgets.dart` | 203 | '발급 요약' (paperAccent 틴트) | §7.17 | 1 |
| `issue_form_summary_widgets.dart` | 394 | '배치 발급 요약' (paperAccent 틴트) | §7.17 | 1 |
| `issue_form_type_options.dart` | 69 | '기간 선택' | §7.17 | 1 |
| `issue_form_membership_widgets.dart` | 32 | '레슨 선택' | §7.17 | 1 |
| `location_travel_selector.dart` | 147 | '레슨 장소' | §7.17 | 1 |
| `location_travel_selector.dart` | 323 | '이동시간' | §7.17 | 1 |
| `cancel_lesson_bottom_sheet.dart` | 127 | `sessionCancelTitle(N)` | §7.27 | 1 |

**양적 헬퍼 전파**: 12 code-line edits → **20 rendered titles** (11 direct + 1 헬퍼×9). §7.17 헬퍼 전파 여섯 번째 사례 (§7.56·§7.59·§7.60·§7.62·§7.66 이어서). 헬퍼 한 줄이 9 call sites 로 퍼지는 극적 레버리지.

**copyWith 패턴**: `NotebookTypography.sectionTitle.copyWith(color: AppColors.paperAccent)` — 요약 카드는 accent 틴트를 유지하면서 서체만 Playfair 로 교체. 기존 색상 디자인 의도 보존.

**§7.27 (cancel_lesson_bottom_sheet)**: `BottomSheetHandle` + 동적 세션 번호가 포함된 제목 블록. 텍스트는 동적이지만 모달 상단 제목 블록의 **구조적 역할** 이 §7.27 에 해당하므로 `appBarTitle` 로 승격.

**§7.30 exclusion (subscription/widgets/ 동일 배치 내)**:

| 파일 | 라인 | 내용 | 사유 |
|---|---|---|---|
| `issue_form_membership_widgets.dart` | 224 | '등록된 레슨이 없습니다' | empty state headline |
| `issue_form_membership_widgets.dart` | 259 | '오류가 발생했습니다' | error headline |
| `proposal_card_widgets.dart` | 329 | `_formatPrice(discountedPrice)` | dynamic price |
| `proposal_card_widgets.dart` | 567 | '입금 확인 대기중' | status headline with icon |
| `template_choice_card.dart` | 72 | `template.name` | dynamic template name |
| `selectable_template_card.dart` | 147 | `template.formattedPrice` | dynamic price |

**커밋**: `91faa52e feat(notebook): subscription/widgets §7.17+§7.27 폼·요약·모달 제목 Playfair 통일`

**검증**: `flutter analyze <7 files>` → `No issues found! (ran in 3.9s)`.

**다음 후보**: subscription/screens/ (issue_subscription, proposal_detail, renewal_detail, subscription_detail, subscription_list, subscription_template_list, proposal_confirm) — 7 화면 §7.17 배치 #2.

**은유**: 수강권 발급소의 긴 카운터에는 **유형·기간·정가·결제·시작일·장소·이동·요약** 여덟 개의 창구가 줄지어 있었다. 카운터 위의 라벨 판은 공방마다 조금씩 달랐다 — 어느 판은 Gothic w600, 어느 판은 Gothic w700 — 고객은 창구를 건너가면서 미묘한 서체 차이에 시선이 걸렸다. 오늘 **모든 라벨 판이 하나의 활자공 손에서 재주조**되었다. Playfair sectionTitle 17/w600 이라는 동일한 주형(mould)에서 스무 장의 판이 찍혀 나왔다 — 그 중 아홉 장은 `ChipInputField` 라는 **공통 주형의 복제**. 카운터 위 라벨들이 드디어 같은 손글씨로 말한다 — "수강권을 발급하는 순서는 여기서 시작합니다."

### 7.69 schedule_tab 헤더 Notebook masthead 승격 — 탭 레벨 홈 일관성 완결

**트리거**: Cycle 31 §7.67 에서 students_tab 을 masthead 로 승격하며 "다음 후보: schedule_tab" 명시. 선생님 주요 탭 5종 (홈·학생 홈·학부모 홈·학생 관리·일정) 중 유일하게 남은 비-masthead 탭. "선생님 학생화면의 Notebook 전환" 디렉티브의 탭 레벨 최종 조각.

**변경 파일 (1 file, 55+/17-)**:

| 파일 | 영역 | 변경 |
|---|---|---|
| `schedule/presentation/screens/schedule_tab.dart` | `_buildHeader()` 재작성 | 단일 Row (제목+토글+추가) → Column (Masthead + ProgrammeTitle + ThinRule + ViewModeToggle Row) |

**적용 시그니처 (4/6)**:

| 시그니처 | 적용 위치 |
|---|---|
| `NotebookMasthead` | eyebrow "SCHEDULE" + trailing 레슨 추가 IconButton (paperAccent 강조 유지) |
| `NotebookTypography.mastheadLabel` | "Programme of Schedule" (Playfair italic 소제목) |
| `NotebookTypography.masthead` | "스케줄" (Playfair large) |
| `ThinRule` | ProgrammeTitle 하단 1px 분리선 |
| `romanOf` | `_volumeIssueString` meta 생성 |

**보존 결정 및 UX 개선**:

1. **레슨 추가 IconButton → Masthead trailing 으로 이동**: 기존 `backgroundColor: paperAccent + foregroundColor: Colors.white` 스타일 유지. `Colors.white` 는 `AppColors.paper` 로 교체 (§7.50 Vermillion 위 foreground paper 원칙 준수).
2. **ViewModeToggle 은 독립 Row 로 분리**: 기존에는 "스케줄" 제목 옆 Spacer 너머에 있어 토글 위치가 우측 상단 구석. 이제 Programme Title 하단에 **중앙 정렬** — 탭 어피던스(3세그먼트 토글이 탭의 주요 제어임) 명확화.
3. **동적 `_ViewModeToggle` 사용자 데이터는 그대로**: ref.watch + ref.read(notifier).setMode 로직 변경 없음. 기능 100% 보존.

**검증**: `flutter analyze schedule_tab.dart` → `No issues found! (4.2s)`.

**탭 레벨 일관성 완결 (선생님 시점)**:

| 탭 | 파일 | Masthead | Notebook 시그니처 | Cycle |
|---|---|---|---|---|
| 홈 | `home/dashboard_tab.dart` | ✅ "LESSONAZA" | 6/6 | — (이전) |
| 학생 홈 | `student_home/student_dashboard_tab.dart` | ✅ | 5/6 | 27·29 |
| 학부모 홈 | `parent_home/parent_dashboard_tab.dart` | ✅ | 5/6 | 28·29 |
| 학생 관리 | `students/screens/students_tab.dart` | ✅ "STUDENTS" | 4/6 | 31 |
| 일정 | `schedule/screens/schedule_tab.dart` | ✅ "SCHEDULE" | 4/6 | **32 (이번)** |

**탭 레벨 시그니처 균일화 달성**. 다음 감사 층위는 **상세 화면** (student_detail, lesson_detail, add_lesson 등 — Notebook 0/6).

**은유**: 선생님의 책상 위 다섯 개 서랍은 각기 다른 용도(오늘·학생·학부모·관리·일정)를 담고 있었지만, 네 개는 같은 공방의 손잡이를 달고 마지막 하나만 혼자 다른 양철 손잡이로 달려 있었다 — 같은 공방이라는 약속이 5번째 서랍에서 깨지면 **책상 전체가 조립물처럼 보인다**. 오늘 마지막 서랍의 손잡이도 공방의 것으로 교체되었다. 이제 서랍을 여닫을 때마다 "이 책상은 **한 장인의 작품**" 이라는 감각이 손끝에 전달된다. 다섯 서랍 공방 균일화 완결 — 다음 단계는 **서랍 안의 폴더들**(상세 화면들) 차례.

---

### 7.70 subscription/screens 폼·모달·앱바 제목 Playfair 통일 — subscription/ 도메인 §7.17/§7.27 배치 #2

**범위**: `frontend/lib/features/subscription/presentation/screens/` 7개 화면의 `AppTypography.headingSmall` 14건 전수 분류. 5건만 변환, 9건은 §7.30 제외.

| 파일 | 라인 | 텍스트 | 패턴 | 비고 |
|---|---:|---|:---:|---|
| issue_subscription_screen.dart | 540 | '변경/취소 가능 횟수' | §7.17 | `_PolicyBadge` 형제와 Row 구성. 정적 라벨 |
| issue_subscription_screen.dart | 610 | `rescheduleDeadlineLabel` | §7.17 | `_rescheduleAllowance > 0` 조건 섹션 |
| subscription_list_screen.dart | 234 | `pendingRequests` | §7.17 | 페이지 서브섹션 제목 |
| proposal_detail_screen.dart | 569 | '${profile.name} 선생님께 연락하기' | §7.27 | 모달 시트 상단 제목. `profile.name` 동적 substring 허용 |
| subscription_detail_screen.dart | 264 | `appBarTitle` (학생 이름 + 타입 조합) | §7.27 | Scaffold.appBar title. 구조적 역할 기준 |

**수량 효과**: 5개 code-line edits → 5 rendered titles (direct mapping, 이번 배치는 헬퍼 배수 없음).

**§7.27 구조 기준 재확인**. 동적 substring(`profile.name`, `studentName + typeLabel`)을 포함하는 title 블록도 **구조적 역할이 모달/AppBar 제목이면 Playfair 적용**. 이는 §7.66의 `sessionCancelTitle(sessionNumber)` 선례와 동일. 반면 단일 값 렌더(가격·템플릿명·상태)는 §7.30 제외 — 구조적 역할이 "정보 표시"라서.

**§7.30 제외 9건**:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| proposal_confirm_screen.dart:253 | `_formatPrice(price)` | dynamic price |
| proposal_detail_screen.dart:443 | `template.formattedPrice` | dynamic price |
| renewal_detail_screen.dart:337 | `template.formattedPrice` | dynamic price |
| subscription_detail_screen.dart:86 | `subscriptionNotFound` | empty-state headline (search_off 아이콘) |
| subscription_detail_screen.dart:110 | `errorOccurred` | error headline (error_outline 아이콘) |
| subscription_list_screen.dart:306 | '등록된 수강권이 없습니다' | empty-state headline |
| subscription_list_screen.dart:334 | '등록된 레슨이 없습니다' | empty-state headline |
| subscription_list_screen.dart:367 | '오류가 발생했습니다' | error headline |
| subscription_template_list_screen.dart:286 | `template.name` | dynamic template name |

**커밋**: `f9033d62 style(subscription/screens): Notebook × Score §7.17+§7.27 배치 #2`
**검증**: `flutter analyze` 4 files → No issues found! (ran in 3.7s)

**subscription/ 도메인 누적 (배치 #1 + #2)**: 14 code-line edits → 25 rendered titles (12 direct + 1 ChipInputField 헬퍼 × 9 + 4 summary/policy direct). 위젯 레이어(배치 #1)에서 헬퍼 배수로 선도, 스크린 레이어(배치 #2)에서 직매핑으로 마감.

**은유**: 창고(widgets) 9개 창구에 라벨을 달고 나니, 진열대(screens) 앞에 서서 "어떤 진열대는 라벨이 필요한 전시 공간이고, 어떤 진열대는 가격표·이름표만 달린 상품 선반이다" 하고 구분할 수 있게 되었다. 오늘은 그 분간의 날 — 전시 공간 5곳에만 공방의 활자를 새기고, 상품 선반 9곳은 그대로 두었다. 다음 방은 `schedule/` — 이번에는 어떤 방이 전시용이고 어떤 방이 창고일까.

---

### 7.71 schedule/screens 앱바·모달 제목 Playfair 통일 — schedule/ 도메인 §7.27 배치 #1

**범위**: `frontend/lib/features/schedule/presentation/screens/` 의 `AppTypography.headingSmall` 9건 전수 분류(단, schedule_tab.dart 2건은 §7.69 masthead 작업과 충돌 위험으로 제외). 2건만 변환, 7건 §7.30 제외 — 매우 높은 제외율.

| 파일 | 라인 | 텍스트 | 패턴 |
|---|---:|---|:---:|
| request_detail_screen.dart | 327 | AppBar title — `'$academyName $opponentName (${typeDisplayLabel})'` | §7.27 |
| booking_cancel_screen.dart | 591 | 모달 시트 '${teacherName} 연락처' | §7.27 |

**수량**: 2 code-line edits → 2 rendered titles.

**§7.30 제외 7건** — schedule/ 도메인이 왜 창고보다 상품 선반이 많은지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| pending_bookings_screen.dart:84 | '대기 중인 신청이 없습니다' | empty-state headline (inbox 아이콘) |
| group_class_attendance_screen.dart:170 | `'${_getAttendedCount()}/${_attendanceState.length}'` | dynamic stat value |
| group_class_detail_screen.dart:370 | `booking.statusText` (상태 아이콘 옆) | status headline with icon |
| booking_cancel_screen.dart:146 | `_formatBookingDate()` | dynamic date |
| unified_lesson_request_screen.dart:174 | `widget.params.teacherName` (CircleAvatar profile card) | dynamic name |
| schedule_tab.dart:300 | — | **parallel-contested** (§7.69 masthead) |
| schedule_tab.dart:644 | — | **parallel-contested** (§7.69 masthead) |

**도메인 특성 관찰**: schedule/ 는 **이벤트·행동 중심 도메인**이라 "정적 섹션 헤더"가 드물고 대신 **동적 상태·카운트·날짜**가 제목 자리를 차지한다. 따라서 §7.17 적용 없이 §7.27(제목 블록) 만 적용. 이는 subscription/screens 와 정반대 패턴 — subscription 은 정적 폼 섹션이 많고, schedule 은 동적 이벤트 표시가 많다.

**병렬 세션 회피**: schedule_tab.dart 2건은 동시 진행 중인 §7.69 masthead 승격 작업과 겹칠 수 있어 이번 배치에서 배제. 해당 파일의 비-masthead headingSmall 은 §7.69 완결 후 별도 배치로 처리.

**커밋**: `0d0413d3 style(schedule/screens): Notebook × Score §7.27 배치 #1`
**검증**: `flutter analyze` 2 files → No issues found! (ran in 2.9s)

**은유**: 진열대가 많은 방에 들어갔는데 대부분이 **시계·현황판·메모지**(동적 표시)라 라벨을 붙일 수 있는 **명패 자리**는 두 곳뿐이었다 — 입구(AppBar)와 전화번호부(모달). 나머지는 달력처럼 늘 바뀌는 것들이라 오히려 라벨이 붙지 **않아야** 자기 역할을 한다. 이 방은 창고가 아니라 **관제실**에 가깝다.

### 7.72 lesson_header_card 히어로 카드 Notebook 승격 — 상세 화면 진입 첫 눈길

**트리거**: 탭 레벨 masthead 균일화(§7.67 students_tab · §7.69 schedule_tab) 완결 후 다음 층위로 **상세 화면군** 진입. 선생님이 하루 가장 자주 열어보는 상세 화면은 `lesson_detail_screen` — 레슨 완료/피드백 플로우의 기점. 그 화면 최상단 히어로인 `lesson_header_card` 의 학생/선생님 이름이 `AppTypography.headingMedium` (Pretendard Gothic) 으로 남아 있어 AppBar title(이미 §7.5 전역 테마로 Playfair) 과 본문 sectionTitle(§7.17 Playfair 일괄 승격) 사이에 **홀로 Gothic 한 섬**을 이루고 있었다.

**변경 파일 (1 file, 7+/3-)**:

| 파일 | 변경 라인 | 내용 |
|---|---|---|
| `lessons/presentation/widgets/lesson_detail/lesson_header_card.dart` | import + L47 + L62 | notebook_typography 임포트 추가 · CircleAvatar foreground Colors.white → AppColors.paper · 학생/선생님 이름 headingMedium → NotebookTypography.sectionTitle |

**적용 시그니처 (1/6 추가 + 기존 Staff/SectionHeader 포함 3/6 유효)**:

| 시그니처 | 적용 |
|---|---|
| `NotebookTypography.sectionTitle` | 학생/선생님 이름(상세 카드 주인공 — 레슨 정보의 기준점) |
| `AppColors.paper` (§7.50 원칙) | CircleAvatar 이니셜 foreground (기존 `Colors.white` — paperAccentSoft 배경 위) |

**보존 결정**:
1. **날짜·악기·상태 배지는 Gothic 유지**: 동적 값(§7.30 exclusion roster) — 시간·악기명·상태 라벨은 데이터 그 자체이며 서체 위계를 위해 Gothic 계열로 정보량 구분.
2. **Pieces Wrap(L108~130) 미변경**: `piece.displayName` 은 레슨 곡명이라 반드시 원작 서체(이탤릭 Playfair가 아님)로 표시되어야 하며, `AppTypography.bodySmall` 이 적절.
3. **StatusBadge 배지 캡션은 Gothic 유지**: 상태 레이블은 기계적 인식(스캔) 대상이지 음미 대상이 아님.

**검증**: `flutter analyze lesson_header_card.dart` → `No issues found! (2.8s)`.

**상세 화면 Notebook 층위 현황 (lesson_detail_screen)**:

| 영역 | 이전 | 현재 |
|---|---|---|
| AppBar title ('레슨 상세') | Playfair | Playfair (§7.5 전역 테마) |
| LessonDetailSectionHeader ('레슨 피드백'·'주요 포인트'·'연습 팁') | Playfair | Playfair (기존 §7.17) |
| LessonHeaderCard 학생/선생님 이름 | Gothic | **Playfair (이번 §7.72)** |
| 날짜·악기·상태 배지 | Gothic | Gothic (§7.30 exclusion) |
| StaffDivider | ✅ | ✅ |

**다음 상세 화면 후보**: `student_detail_screen` 의 탭 내부 (StudentInfoTab / StudentLessonsTab / StudentPracticeTab) — SliverAppBar 자체는 프로필 컬러 히어로라 Notebook 승격 불가, 탭 내부 sectionTitle 만 대상.

**은유**: 도서관 열람실에 들어서면 **입구 간판**(AppBar title)과 **서가 팻말**(section header)은 같은 서체로 쓰여 있었다. 하지만 입구에서 첫 책장을 열면 나타나는 **책의 속표지**(히어로 카드)만이 인쇄소를 잘못 지정한 듯 Gothic 볼드로 찍혀 있었다 — 똑같이 중요한 정보인데 서체 톤이 달랐다. 오늘 속표지의 학생 이름이 Playfair 로 다시 조판되었다. 이제 간판·팻말·속표지 세 군데가 같은 활자공의 손길로 이어진다. 독자는 "입구에서 책을 펴도 같은 출판사"라는 **연속 감각**을 잃지 않는다. 상세 화면의 진입 첫 눈길이 서체 톤으로 깨지지 않는다는 것 — 그게 이 소규모 승격의 큰 이유다.

---

### 7.73 schedule/widgets 카드 헤더 Playfair 통일 — schedule/ 도메인 §7.17 배치 #1

**범위**: `frontend/lib/features/schedule/presentation/widgets/` 의 `AppTypography.headingSmall` 10건 전수 분류. 1건만 변환, 9건 §7.30 제외 — 더 높은 제외율.

| 파일 | 라인 | 텍스트 | 패턴 |
|---|---:|---|:---:|
| availability/availability_block_grid.dart | 85 | `'${date.month}/${date.day}($weekday) 가용 시간 관리'` | §7.17 |

**수량**: 1 code-line edit → 1 rendered title.

**§7.30 제외 9건** — schedule/widgets 의 도메인 시그니처:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| regular_lesson_widgets:47 | `studentName[0]` | avatar initial |
| regular_lesson_widgets:660 | `formatFee(monthlyFee)` | dynamic price |
| unified_approval_bottom_sheet:135 | `name` (프로필 행) | dynamic name |
| request_profile_card:120 | `name[0]` | avatar initial |
| teacher_approval_card:164,412 | `booking.studentName[0]` (2곳) | avatar initial |
| approval_bottom_sheet:177 | `booking.studentName` | dynamic name |
| booking_card:70 | `booking.studentName[0]` | avatar initial |
| availability_booking_preview:68 | `'${timeRange} (${durationMinutes}분)'` | dynamic time range |

**도메인 관찰**: schedule/widgets 는 **"누가·언제" 카드 렌더링 도메인**. 10건 중 **5건이 avatar initial**(50%), 2건이 dynamic name(20%), 2건이 dynamic value(20%). §7.30 의 "avatar initials" 카테고리가 왜 필요한지 정량적으로 확인 — 프로필 카드가 많은 도메인일수록 avatar initial 밀도가 높다.

**schedule/ 도메인 누적 (배치 #1 screens + #1 widgets)**: 3 code-line edits → 3 rendered titles. 19건 전수 분류 중 변환률 **15.8%** — subscription/ 누적(14 edits → 25 renders, 위젯 헬퍼 배수 포함)과 뚜렷한 대비. **도메인 성격이 타이포 승격 밀도를 결정한다**.

**커밋**: `8778fd9e style(schedule/widgets): Notebook × Score §7.17 배치 #1`
**검증**: `flutter analyze` 1 file → No issues found! (ran in 2.7s)

**은유**: 진열장(widgets)을 열어보니 대부분이 **명함첩**이었다 — 사람 얼굴·이름·시간이 카드마다 찍혀 있다. 명함첩 속 **이름**을 서체 하나로 통일하면 오히려 부자연스럽다(이름은 그 사람의 고유성). 그래서 대부분을 그대로 두고, **명함첩 표지**(availability 카드 헤더) 하나만 공방의 활자로 바꿨다. 속지는 속지다워야 하고, 표지는 표지다워야 한다 — 이게 §7.30 exclusion 이 매번 많아지는 이유다.

---

### 7.74 student_detail 탭 내부 섹션 제목 Playfair + §7.50 paper 통일 — 상세 화면 Info 탭 층위

**배경**: §7.72 lesson_header_card 로 상세 화면 층위 진입 후, 다음 후보였던 `student_detail_screen` 의 탭 내부(StudentInfoTab / StudentLessonsTab / StudentPracticeTab)를 감사. SliverAppBar 자체는 프로필 컬러 히어로라 Notebook 승격 불가(§7.72 결정) — 탭 내부 sectionTitle 만 대상.

**감사 결과**: 3 탭 → 12 하위 위젯 전수 조회. **섹션 제목 sectionTitle 승격률 92%** 이미 도달. 남은 2건만 Cycle 34 대상:

| 파일 | 라인 | 패턴 | 변경 |
|---|---:|:---:|---|
| student_subscription_section.dart | 44 | §7.17 | "수강권 현황" `AppTypography.headingMedium` → `NotebookTypography.sectionTitle` |
| student_practice_tab.dart | 471 | §7.50 | feedback count badge (paperAccent 배경) foreground `Colors.white` → `AppColors.paper` |

**수량**: 2 code-line edits (+ 1 import) → 1 Playfair 승격 + 1 §7.50 준수.

**§7.30 제외 1건** — 의도적으로 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| student_stats_cards:72 | `value` (headingMedium) | dynamic stat value |

**이미 §7.17 통과한 섹션 제목 9건** (Cycle 34 전 상태, 확인만):
- student_lessons_sections: "다가오는 레슨"(L33), "최근 레슨"(L120)
- student_practice_section: "이번 주 연습"(L32)
- student_practice_tab: "이번 주 연습 요약"(L79), "주간 연습 현황"(L177), "공유된 녹음"(L316)
- student_notes_section: "레슨 노트"(L30), "hand 필기체 메타데이터"(L151)
- student_lesson_card: "hand 필기체"(L118)

**도메인 관찰**: student_detail 의 Info 탭은 §7.17 가 **이미 주도권**을 잡고 있었다 (9/11 ≈ 82%). 남은 1건은 `subscription_facade` 경계를 타고 들어온 위젯이라 Notebook 인식 외곽에 놓여 있던 것. **탭 내부 감사는 개별 파일이 아니라 전수 grep 으로 봐야 정확** — 헤더 1건만 보면 "이미 끝난 줄" 착각할 위험.

**상세 화면 layer 누적 (§7.72 lesson_header_card + §7.74 student_detail 탭)**:
- lesson_detail: hero card Playfair 승격 ✓
- student_detail: Info 탭 섹션 제목 100% 승격 ✓, Lessons/Practice 탭 이전 승격 확인

**§7.50 관찰**: Vermillion 배경 foreground 는 이번 사이클에도 1건 발견 — `Colors.white` 가 badge/chip 에서 **조용히 살아남는다**. 큰 CTA 가 아니라 작은 카운터라 grep 에서 놓치기 쉬움. `Colors\.white` 전수 grep 이 상세 화면 층위까지 도달해야 Notebook 팔레트 외곽 방어가 완결.

**커밋**: (진행 중 — Cycle 34 트레일러)
**검증**: `flutter analyze lib/features/students/presentation/widgets/student_detail/` → No issues found! (ran in 2.9s)

**다음 후보**: `lesson_detail_screen` 본체(791줄) 의 sectionTitle 스캔, 또는 `add_lesson_screen`(874줄) hero 영역 승격 — 상세 화면 layer 확장 계속.

**은유**: 상세 화면은 **서랍장**이다. §7.72 에서 손잡이(lesson_header_card)를 공방의 놋쇠로 바꿨고, §7.74 는 **첫째 서랍**(Info 탭)을 열어 안감까지 Notebook 무명천으로 갈았다. 놀랍게도 안감의 92% 는 이미 무명천이었다 — 다른 사이클(§7.17 배치들)이 서랍 내부에서 먼저 작업했기 때문. **상세 화면 층위는 "새로 만드는 것"이 아니라 "합류점을 찾는 것"** 에 가깝다. 아직 놋쇠가 아닌 손잡이, 아직 무명천이 아닌 안감 — 이 둘의 접점을 메우는 게 상세 화면 사이클의 본질.

---

### 7.75 lessons/screens 출석·CTA 로딩 통일 — 섹션 제목 §7.17 + Vermillion 로딩 §7.50

**배경**: §7.72/§7.74 상세 화면 층위를 이어, `lessons/presentation/screens/` 14 파일 전수 감사. 직접 타이포 호출은 **teacher_attendance_screen 3건**만, `Colors.white` 는 **3건** 존재. 분류 후 §7.17 2건 + §7.50 2건 변환, 1건은 §7.30 제외, 1건은 프로필 컬러 맥락이라 §7.50 범위 밖.

| 파일 | 라인 | 텍스트/패턴 | 변경 |
|---|---:|---|---|
| teacher_attendance_screen.dart | 65 | `AppStrings.studentAttendanceRates` (headingMedium) | §7.17 → sectionTitle |
| teacher_attendance_screen.dart | 80 | `AppStrings.recentAbsences` (headingMedium) | §7.17 → sectionTitle |
| quick_feedback_screen.dart | 160 | `CircularProgressIndicator color: Colors.white` (FilledButton 내부) | §7.50 → AppColors.paper |
| edit_lesson_screen.dart | 263 | `CircularProgressIndicator color: Colors.white` (FilledButton 내부) | §7.50 → AppColors.paper |

**수량**: 4 code-line edits (+ 1 import) → 2 Playfair 승격 + 2 §7.50 준수.

**§7.30 제외 1건** — 의도적 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| teacher_attendance_screen:114 | `'${AppStrings.overallAttendanceRate}  ${rate.toStringAsFixed(1)}%'` | dynamic stat value (label+rate 혼합, rate 가 시각 주인공) |

**§7.50 범위 밖 1건** — Vermillion 이 아니라서 건드리지 않음:

| 파일:라인 | 맥락 | 왜 제외 |
|---|---|---|
| add_lesson_screen:324 | `ActionChip label.color: isSelected ? Colors.white : null` (bg: `student.profileColor`) | 배경이 **프로필 컬러** (동적 색상), Vermillion 이 아님. §7.50 은 paperAccent 배경 한정 |

**도메인 관찰**: lessons/screens 는 **세 부류**로 나뉜다 — (a) 출석·통계 화면(`teacher_attendance`): 섹션 제목이 드러나는 "문서형" 화면 → Playfair 승격 명확. (b) 폼 화면(`edit_lesson`, `quick_feedback`, `add_lesson`): 제목 없이 Field 중심, Playfair 대상 거의 없음. (c) 로딩/버튼 내부: Vermillion CTA 의 progress indicator — 작지만 매번 튀어나오는 Colors.white. **§7.50 은 "큰 버튼"보다 "작은 스피너" 에서 더 자주 새어나온다**.

**§7.50 누적 발견** (§7.72 lesson_header_card avatar → §7.74 feedback badge → §7.75 CTA spinner): Vermillion foreground 잔재는 **avatar initial / badge count / loading spinner** 3대 패턴. 모두 "작고 시선 덜 끄는" 영역이라 grep 없이는 놓친다. §7.50 은 **전수 `Colors\.white` grep 을 주기적으로 반복**해야 완결.

**커밋**: (Cycle 35 진행 중)
**검증**: `flutter analyze` 3 files → No issues found! (ran in 3.0s)

**다음 후보**: lessons/widgets (lesson_form_widgets, lesson_action_buttons 등) 전수 감사, 또는 profile/ 도메인 섹션 제목 통일.

**은유**: §7.74 가 **서랍 안감**을 만지는 일이었다면, §7.75 는 **서랍 속 자물쇠 주변**을 닦는 일. 로딩 스피너는 자물쇠를 돌릴 때 잠시 반짝이는 금속 — 이 반짝임이 은백색(Colors.white)이면 Notebook 의 **종이색 온도**가 깨진다. `AppColors.paper` 는 같은 "밝음"이지만 **따뜻한 크림빛** — 기존 Vermillion 과 한 공간에 놓여도 어색하지 않다. Notebook × Score 의 미감은 "색의 일치"가 아니라 **"온도의 일치"** 에서 온다.

---

### 7.76 invite/ 도움말 모달 제목 Playfair 통일 — 상태 전이 피드백 도메인 §7.27 배치 #1

**배경**: subscription/screens §7.70, schedule/screens §7.71, schedule/widgets §7.73 의 패턴을 잇는 다음 도메인 감사. `features/invite/` 전수 탐색 결과 `AppTypography.headingSmall` 이 8건 발견되었으나, **7/8 은 §7.30 제외 대상**(상태 아이콘 + status 텍스트 조합 or avatar initial or empty state)이고 오직 **1건만 구조적 모달 시트 타이틀**이었다. 전환율 12.5% — 지금까지 도메인 중 **최저치**.

| 파일 | 라인 | 텍스트/패턴 | 변경 |
|---|---:|---|---|
| my_connections_screen.dart | 145 | `'선생님과 연결하는 방법'` (BottomSheetHandle + 제목 조합) | §7.27 → appBarTitle |

**수량**: 1 code-line edit (+ 1 import) → 1 Playfair 승격.

**§7.30 제외 7건** — 의도적 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| pending_requests_screen:237 | `requesterName[0]` | avatar initial |
| my_connections_screen:550 | `name[0]` | avatar initial |
| invite_history_screen:81 | `'생성한 초대가 없습니다'` (history_rounded icon) | empty-state headline |
| my_connections_screen:104 | `'아직 연결된 X이 없습니다'` (people_outline icon) | empty-state headline |
| invite_confirm_screen:84 | `'연결할 수 없습니다'` (warning icon) | error headline with icon |
| invite_confirm_screen:393 | `'이미 연결되어 있습니다'` (link icon) | status headline with icon |
| invite_confirm_screen:468 | `'연결 요청이 전송되었습니다!'` (check_circle icon) | success headline with icon |

**도메인 관찰**: invite/ 는 **상태 전이 피드백** 도메인이다 — 초대 생성, 연결 요청, 수락/거절, 이미 연결됨, 전송됨 등 "전/후 상태 차이"를 사용자에게 알리는 화면이 지배적이다. 이러한 상태 알림은 반드시 **아이콘 + 제목 + 본문** 삼중 구조를 갖는데, 아이콘이 이미 "상태의 얼굴"이므로 제목은 §7.30 exclusion 카테고리(status-with-icon)에 해당한다. Playfair 는 **대상을 호명**하는 타이포(선생님·학생·레슨·수강권 등 명사)에 어울리지, **상태를 선포**하는 타이포(성공·실패·연결됨·전송됨 등 이벤트)에는 맞지 않는다.

**전환율 비교** (누적 추세):

| 도메인 | heading 발견 | §7.27/§7.17 변환 | §7.30 제외 | 전환율 |
|---|---:|---:|---:|---:|
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% |
| schedule/widgets (§7.73) | 19건 | 1건 | 9건 (+9 parallel) | ~10% |
| **invite/ (§7.76)** | **8건** | **1건** | **7건** | **12.5%** |

**왜 낮은가?** invite/ 는 "명사 호명"보다 "동사 선포"가 더 많은 구조를 갖는다. 유사하게 낮은 schedule/widgets 는 "동적 시간대/이름 조합" 이 지배적이고, invite/ 는 "성공/실패 이벤트 피드백"이 지배적이다. **전환율은 도메인의 본질(명사형 vs 이벤트형)을 측정하는 지표**로 활용 가능.

**커밋**: `0b8e0704` style(invite): Notebook × Score §7.27 배치 #1
**검증**: `flutter analyze` invite/ 1 file → No issues found! (ran in 3.9s)

**다음 후보**: profile/ 도메인(repertoire/payment 등 명사 호명 비중 높음, 전환율 예측 40%+), settings/ 도메인(섹션 제목 중심, 전환율 예측 50%+), 또는 search/ 도메인(teacher/academy 상세 — 부분적으로 parallel-contested).

**은유**: §7.76 은 **우체통의 표지판**을 바꾸는 일에 가까웠다. 편지 자체(상태 메시지)는 이미 아이콘이라는 **그림 편지봉투**에 담겨 있어서, 그 위에 또 Playfair 라벨을 붙이면 "이중 서명"이 된다. 그래서 우리가 바꾼 건 우체통 **상단 안내판** 하나 — "선생님과 연결하는 방법". 이 안내판은 편지의 내용이 아니라, **우체통 자체의 이름**이다. Notebook × Score 의 Playfair 는 이런 **"공간의 이름"** 에 붙는 것이지, **"공간 안의 사건"** 에 붙는 것이 아니다.

---

### 7.77 profile/ 레퍼토리 모달 제목 Playfair 통일 — 명사 호명 도메인 §7.27 배치 #1

**배경**: §7.76 invite/ 전환율 12.5% 관찰 후 **명사 호명 비중 높은 도메인** 가설 검증을 위해 profile/ 진입. `features/profile/` 전수 탐색 결과 `AppTypography.headingSmall` 7건 발견. **2/7 만 §7.27 구조적 모달 타이틀**이었고 나머지 5건은 §7.30 exclusion(동적 값 3건, avatar 1건, empty 1건). 전환율 **28.6%** — invite/ 보다는 높지만 예측한 40%+ 에 미달.

| 파일 | 라인 | 텍스트/패턴 | 변경 |
|---|---:|---|---|
| repertoire_management_widgets.dart | 539 | `'난이도 선택'` (ListTile title, bottom sheet) | §7.27 → appBarTitle |
| repertoire_management_widgets.dart | 585 | `'작곡가 선택'` (ListTile title, bottom sheet) | §7.27 → appBarTitle |

**수량**: 2 code-line edits (+ 1 import) → 2 Playfair 승격.

**§7.30 제외 5건** — 의도적 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| extended_profile_dialogs:177 | `FeeRange(...).formatted` (`paperAccent` color) | dynamic stat value |
| outstanding_payments_screen:48 | `'미수금이 없습니다'` (check_circle icon) | empty-state headline with icon |
| outstanding_payments_screen:224 | `formatWonWithComma(amount)` (`paperAccent` color) | dynamic price value |
| payment_management_screen:244 | `'$selectedYear년'` (navigation arrows 사이) | dynamic calendar label |
| payment_detail_sheet:52 | `studentName[0]` (`Colors.white` on paperAccentSoft) | avatar initial |

**§7.50 관찰 (차기 배치 후보)**: `payment_detail_sheet:52` 의 avatar Colors.white 는 paperAccentSoft 배경 위 foreground → §7.50 paper 통일 대상. 이번 배치는 타이포 스코프라 §7.50 은 별도 사이클로 이월.

**가설 검증 결과**: "profile/ = 명사 호명 도메인" 은 **부분 참**. 레퍼토리 메타데이터(난이도·작곡가)는 명사형 모달로 Playfair 승격 가능하나, **profile 의 지배 구조는 "결제 내역·미수금·수수료"라는 금액 중심**이라 **§7.30 dynamic stat value 가 대다수**를 차지. 다음 가설: "숫자 지배 도메인"은 전환율이 낮다 — settings/ 와 gamification/ 가 대안 후보.

**전환율 비교** (업데이트):

| 도메인 | heading 발견 | 변환 | §7.30 제외 | 전환율 | 본질 |
|---|---:|---:|---:|---:|---|
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% | 정적 명사 (수강권·제안·내역) |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% | 동적 이벤트 (일정 변경·완료) |
| schedule/widgets (§7.73) | 19건 | 1건 | 9건 | ~10% | 동적 시간대 |
| invite/ (§7.76) | 8건 | 1건 | 7건 | 12.5% | 상태 전이 피드백 |
| **profile/ (§7.77)** | **7건** | **2건** | **5건** | **28.6%** | **금액 중심** |

**커밋**: `27bef113` style(profile): Notebook × Score §7.27 배치 #1
**검증**: `flutter analyze` profile/repertoire → No issues found! (ran in 3.0s)

**다음 후보**: settings/ (backup_widgets 등 섹션 제목 중심, 전환율 예측 50%+), gamification/ (badge_collection, 전환율 미지수), 또는 student_home/ (8 occurrences, 예상 "대시보드 섹션 제목" 지배).

**은유**: §7.77 은 **서가의 장르 라벨**을 바꾸는 일이었다. 'Bach' 나 '3만원' 같은 **책 제목·가격표** 는 원래부터 손글씨(Gothic)로 두어도 의미가 통한다 — 그게 사용자가 찾는 내용이기 때문. 하지만 **"난이도 선택"·"작곡가 선택"** 같은 **서가 탭** 은 책들을 가로지르는 **상위 분류** 다. 상위 분류는 Playfair 로 쓰여야 **"여긴 다른 층위"** 라는 신호가 된다. 즉 **동적 값은 Gothic, 구조적 정적 레이블은 Playfair** — 이 원칙이 §7.27 의 심장이다.

---

### 7.78 lessons/widgets 바텀시트·다이얼로그 제목 Playfair 통일 — lessons/ 도메인 §7.27 배치 #1

**배경**: §7.75 lessons/screens 층위 완결 후 `features/lessons/presentation/widgets/` 전수 감사. `AppTypography.headingMedium/headingSmall` 15건 발견 — 분석 결과 **바텀시트·다이얼로그 제목 10건** + §7.30 제외 5건(avatar initial 2건, student.color 1건, dynamic name 1건, tilde 1건). 전환율 **66.7%** — subscription/screens 이어 두 번째로 높은 수치.

| 파일 | 라인 | 텍스트 | 패턴 |
|---|---:|---|:---:|
| edit_practice_item_sheet | 82 | `'연습 수정'` | §7.27 |
| lesson_confirmation_dialog | 201 | `'레슨 확인'` | §7.27 |
| lesson_confirmation_dialog | 310 | `'레슨 미진행 사유'` | §7.27 |
| add_youtube_resource_sheet | 134 | `'유튜브 영상 추가'` | §7.27 |
| add_practice_item_sheet | 143 | `'연습 추가'` | §7.27 |
| tip_template_bottom_sheet | 74 | `'템플릿 선택'` | §7.27 |
| attendance_confirmation_sheet | 120 | `AppStrings.lessonConfirmation` | §7.27 |
| attendance_confirmation_sheet | 214 | `AppStrings.nonCompletionReason` | §7.27 |
| lesson_form/lesson_student_picker_sheet | 37 | `'학생 선택'` | §7.27 |
| lesson_detail/add_tip_bottom_sheet | 70 | `widget.title` (dynamic, 헤더 포지션) | §7.27 |

**수량**: 10 code-line edits (+ 8 imports, -1 cleanup) → 10 Playfair 승격.

**§7.30 제외 5건** — 의도적 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| lesson_detail/lesson_header_card:47 | avatar initial | avatar initial (§7.72 이미 paper) |
| lesson_form/lesson_student_selector:42 | student.color | student-profile color |
| lesson_form/edit_lesson_widgets:51 | `student.color` | student-profile color |
| add_youtube_resource_sheet:261 | `'~'` (tilde separator) | UI separator glyph |
| lesson_detail/lesson_notes_widgets:504 | dynamic value | dynamic stat |

**도메인 관찰**: lessons/widgets 는 **"레슨 전후에 열리는 바텀시트 더미"** 도메인. 레슨 시작(확인) → 진행(연습 추가/수정, 팁 추가, 유튜브 리소스) → 종료(비진행 사유, 출석 확인) 까지 모든 **상태 전이**가 바텀시트로 표현된다. **정적 명사형 모달 타이틀 밀도가 매우 높음** (10/15 = 66.7%) — "상태 전이 이름"은 본질적으로 정적이기 때문. 반대로 body 는 동적 값(학생 이름/프로필 컬러)이 지배.

**전환율 비교** (업데이트):

| 도메인 | heading 발견 | 변환 | §7.30 제외 | 전환율 | 본질 |
|---|---:|---:|---:|---:|---|
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% | 정적 명사 (수강권·제안·내역) |
| **lessons/widgets (§7.78)** | **15건** | **10건** | **5건** | **66.7%** | **상태 전이 모달 이름** |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% | 동적 이벤트 |
| profile/ (§7.77) | 7건 | 2건 | 5건 | 28.6% | 금액 중심 |
| invite/ (§7.76) | 8건 | 1건 | 7건 | 12.5% | 상태 전이 피드백 |
| schedule/widgets (§7.73) | 10건 | 1건 | 9건 | 10% | 동적 시간대 |

**가설 확장**: "**상태 전이 이름**" 도메인은 전환율이 높다 — lessons/widgets(66.7%), subscription(56%). 반대로 "동적 이벤트·시간대" 가 지배하는 도메인은 낮다(schedule 10-22%). 바텀시트는 **상태 전이 UI 패턴**이므로 헤더가 정적 명사로 고정되는 경향.

**커밋**: (Cycle 36 진행 중)
**검증**: `flutter analyze lib/features/lessons/presentation/widgets/` → No issues found! (ran in 4.2s). 1 unused_import 자동 cleanup(add_tip_bottom_sheet.dart AppTypography).

**§7.50 범위 밖 관찰**: lessons/widgets 전수에서 `Colors.white` 8건 발견 — 차기 사이클 §7.50 전용 배치 후보. avatar / chip selected / sheet submit button 내 spinner 등이 혼재.

**다음 후보**: lessons/widgets §7.50 전용 배치(Colors.white 8건), 또는 lessons/widgets/lesson_detail/ 서브 탐색(lesson_notes_widgets 500+줄).

**은유**: §7.78 은 **바텀시트 더미의 이름표**를 한꺼번에 바꾸는 일이었다. 바텀시트는 화면의 **"다른 층"** — 올라오는 순간 사용자의 주의가 완전히 이동한다. 그 층의 제목이 Gothic 이면 **"여긴 아까의 연장선"** 느낌을, Playfair 면 **"여긴 별개의 순간"** 느낌을 준다. lessons/widgets 의 10개 바텀시트는 모두 **"레슨 순간 의 미세한 분기점"** — 연습을 수정하는 순간, 레슨을 확인하는 순간, 팁 템플릿을 고르는 순간. 이 분기점들에 Playfair 이름표를 달아주면, 각 순간이 **"의례적 문턱"** 으로 승격된다 — 그게 Notebook × Score 미감의 본질.

---

### 7.79 student_home/my_teachers 카테고리 섹션 제목 Playfair + 3-도메인 §7.30 전수 감사 — "동적 값 집중" 도메인 클러스터

**배경**: §7.77 profile/ 이후 settings/ + gamification/ + student_home/ 3개 도메인을 **한 번에 전수 감사**. 총 10건 발견, **2건만 §7.17 구조적 섹션 제목** (my_teachers_screen 의 카테고리 헤더), 나머지 8건 전부 §7.30 exclusion. 전환율 **20%** — 3 도메인 모두 "동적 값" 이 지배하는 클러스터.

| 파일 | 라인 | 텍스트/패턴 | 변경 |
|---|---:|---|---|
| my_teachers_screen.dart | 61 | `'앱 선생님'` (verified icon + 카테고리 그룹 헤더) | §7.17 → sectionTitle |
| my_teachers_screen.dart | 171 | `'직접 등록한 선생님'` (person_add icon + 카테고리 그룹 헤더) | §7.17 → sectionTitle |

**수량**: 2 code-line edits (+ 1 import) → 2 Playfair 승격 (모두 `my_teachers_screen.dart`).

**§7.30 제외 8건** — 3 도메인 전수 관찰:

| 도메인 | 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|---|
| settings/ | backup_widgets:127 | `value` (icon + value + label 스택) | dynamic stat value |
| gamification/ | badge_collection_screen:103 | `data.levelTitle` (Lv.{n} 위, 총 P 아래) | gamification token |
| student_home/ | student_lessons_tab:231 | `formatDateMDWithDayLong(selectedDate)` | dynamic date label |
| student_home/ | student_practice_tab:132 | `_formatDate(_selectedDate)` (data branch) | dynamic date label |
| student_home/ | student_practice_tab:177 | `_formatDate(_selectedDate)` (loading branch) | dynamic date label |
| student_home/ | student_practice_tab:190 | `_formatDate(_selectedDate)` (error branch) | dynamic date label |
| student_home/ | student_subscription_summary:268 | `'${usedLessons}/$_totalSessions'` | dynamic fraction |
| student_home/ | dashboard/next_lesson_card:147 | `dDayText` (D-1 / D-Day) | dynamic countdown |

**AsyncValue.when 반복 패턴 관찰**: `student_practice_tab` 의 동일 `_formatDate` 렌더가 data / loading / error 3 branch 에 복제되어 있다. **DRY 리팩토링 후보** — `_DateHeader` 위젯으로 추출하면 3 → 1. 다만 스코프 밖(타이포 변환 없음)이므로 별도 사이클로 이월.

**전환율 업데이트** (9 도메인 집계):

| 도메인 | heading 발견 | 변환 | §7.30 제외 | 전환율 | 본질 |
|---|---:|---:|---:|---:|---|
| lessons/widgets (§7.78) | 15건 | 10건 | 5건 | 66.7% | 상태 전이 모달 이름 |
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% | 정적 명사 (수강권·제안·내역) |
| profile/ (§7.77) | 7건 | 2건 | 5건 | 28.6% | 금액 중심 |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% | 동적 이벤트 |
| **3-도메인 클러스터 (§7.79)** | **10건** | **2건** | **8건** | **20%** | **동적 값 집중** |
| invite/ (§7.76) | 8건 | 1건 | 7건 | 12.5% | 상태 전이 피드백 |
| schedule/widgets (§7.73) | 10건 | 1건 | 9건 | 10% | 동적 시간대 |

**가설 검증**: "숫자·날짜·카운트다운 같은 **동적 값**이 화면 주인공인 도메인"은 전환율 10-30% 구간. §7.77 (금액 중심) 과 이번 §7.79 (날짜·프로그레스·레벨) 가 거의 같은 범위. 반대로 §7.78 (상태 전이 이름) 과 subscription (정적 명사) 은 50%+. **Playfair 승격은 "대상을 호명하는 명사"에만 적합하고, 값 표시는 건드리지 않는다 — 이 경계가 §7.27/§7.17 ↔ §7.30 의 본질**.

**쌍 관찰** (student_home/ 내부): `my_teachers_screen` 은 2/2 변환 (100%), 나머지 4 파일은 0/6 변환 (0%). 즉 한 도메인 안에서도 **"사람/카테고리 호명 화면"** 과 **"값 표시 화면"** 이 이분된다. 전환율 20% 는 평균이 아니라 **이분 분포의 평균**이다.

**커밋**: `e2a126b8` style(student_home): Notebook × Score §7.17 배치 #1
**검증**: `flutter analyze` my_teachers → No issues found! (ran in 8.3s)

**다음 후보**: students/ 도메인 (student_detail 제외 — §7.74 완료), parent_home/ (10+ occurrences 예상, 학부모 대시보드는 §7.61 이후 후속), 또는 search/ teacher_detail/academy_detail (parallel-contested 주의).

**은유**: §7.79 는 **도서관에서 "저자·장르 라벨"만 바꾸고 "검색 결과 숫자" 는 그대로 두는 일**이었다. '앱 선생님' · '직접 등록한 선생님' 은 **책장의 장르 라벨** — 손으로 쓰인 듯한 Playfair 가 잘 맞는다. 반면 "3/5", "D-Day", "2026년 4월 25일" 은 **검색 결과 숫자** — 이건 Gothic 기계 숫자가 더 읽기 쉽다. 3 도메인을 한꺼번에 감사한 결과는 명확하다: Notebook × Score 는 **"숫자·날짜·카운트다운 같은 기계적 지표는 건드리지 말고 그대로 두라"** 는 규율을 요구한다. Playfair 는 **기계 지표의 대립항**으로 존재해야 하기 때문.

---

### 7.80 lessons/widgets §7.50 Vermillion foreground 일괄 정리 — 3대 잔재 패턴 5개로 확장

**배경**: §7.78 이 예고한 `Colors.white` 8건 전수 배치 사이클. `grep -rn "Colors.white" lessons/presentation/widgets/` 로 8건 확정 → 분류: **§7.50 Vermillion foreground 7건 + 바텀시트 배경 팔레트 일관성 1건**. §7.78 의 이름표(제목) 정리에 이은 **이름 아래 층의 작은 잔재 정리** — 같은 도메인에서 이름 → 속살 순서로 내려가는 2단계 배치.

| 파일 | 라인 | 요소 | 이전 → 이후 | 패턴 |
|---|---:|---|---|:---:|
| add_recording_resource_sheet | 158 | FilledButton spinner | `Colors.white` → `AppColors.paper` | §7.50 CTA spinner |
| add_external_link_sheet | 156 | FilledButton spinner | `Colors.white` → `AppColors.paper` | §7.50 CTA spinner |
| add_practice_item_sheet | 349 | `Icons.check` (레퍼토리 선택) | `Colors.white` → `AppColors.paper` | §7.50 check glyph |
| add_practice_item_sheet | 422 | `Icons.check` (신규 레퍼토리) | `Colors.white` → `AppColors.paper` | §7.50 check glyph |
| attendance_confirmation_sheet | 286 | ElevatedButton Text | `Colors.white` → `AppColors.paper` | §7.50 CTA text |
| lesson_form/lesson_reminder_section | 143 | selected chip text | `Colors.white` → `AppColors.paper` | §7.50 chip selection |
| lesson_form/lesson_recurring_section | 97 | selected day circle text | `Colors.white` → `AppColors.paper` | §7.50 chip selection |
| ai_notes_result_sheet | 54 | BottomSheet Container 배경 | `Colors.white` → `AppColors.paper` | 팔레트 일관성 |

**수량**: 8 code-line edits (0 imports — 전 파일 `app_colors.dart` 기 임포트). 0 단위 테스트 영향 (순수 디자인 토큰 교체).

**§7.50 잔재 패턴 확장** — §7.75 에서 식별된 3대 패턴(avatar initial / badge count / loading spinner)에 §7.80 에서 **2개 패턴 추가**:

| # | 패턴 | 최초 발견 | §7.80 사례 |
|:-:|---|---|---|
| 1 | avatar initial | §7.72 | (없음) |
| 2 | badge count | §7.75 | (없음) |
| 3 | loading spinner | §7.75 | add_recording_resource_sheet, add_external_link_sheet |
| **4** | **check glyph** (체크박스 선택) | **§7.80** | add_practice_item_sheet x2 |
| **5** | **chip/pill selection** (선택된 상태) | **§7.80** | lesson_reminder_section, lesson_recurring_section, attendance_confirmation_sheet |

**경계 케이스**: `ai_notes_result_sheet:54` 는 바텀시트 Container 배경 — Vermillion 층위가 아닌 **paper 층위** 이므로 엄밀히 §7.50 적용 대상은 아니지만, `Colors.white` 는 Notebook cream paper 톤(F2ECDD)과 어긋나므로 **팔레트 일관성** 관점에서 `AppColors.paper` 로 교체. 향후 "§7.50 근방 위반" 이라는 별도 태그로 분류 가능.

**프로필 컬러 예외 재확인**: Cycle 35 에서 판정한 `add_lesson_screen:324 ActionChip` (student.profileColor 배경)은 §7.50 범위 밖으로 유지 — §7.50 은 오직 `AppColors.paperAccent` (Vermillion) 배경에만 적용된다.

**커밋**: (Cycle 37 진행 중)
**검증**: `flutter analyze lib/features/lessons/presentation/widgets/` → No issues found! (ran in 4.1s). 8 Edit 모두 성공, 후처리 hook 자동 포맷팅 포함.

**도메인 관찰**: lessons/widgets §7.50 잔재는 **"Vermillion 버튼/체크박스 위의 글자·아이콘"** 층위에 집중 — 즉 **CTA(spinner/text)**, **선택 마커(check glyph)**, **선택 상태(chip/day-circle)**. 이 세 층위에서 `Colors.white` 잔재는 Flutter Material 기본값의 관성 — 개발자가 Vermillion 배경을 토큰으로 교체했지만, 그 위 foreground 는 무심코 Material 기본값을 썼던 흔적.

**다음 후보**:
1. `lesson_notes_widgets.dart` 서브 탐색 (500+ 줄, §7.78 §7.30 제외에서 언급됨)
2. `features/lessons/presentation/widgets/lesson_detail/` 서브도메인 전수 감사
3. 다른 도메인(home/, parent/, auth/) §7.50 잔재 `Colors.white` 확인

**은유**: §7.80 은 **이름 아래 속살의 색 정리**다. §7.78 에서 바텀시트 제목을 Playfair 로 승격했다면, §7.80 은 그 안의 **체크표시, 스피너, 선택된 요일 동그라미** — 사용자가 실제로 **터치하는 순간에 보는 피드백 층위** 를 정리했다. Material 기본값 `Colors.white` 는 디지털 스크린의 **"LED 광택 백"** 이고, `AppColors.paper` 는 **"종이에 찍힌 흰 잉크"** 다. Vermillion(주홍)과 짝을 이룰 때, 전자는 **디지털 버튼** 이고 후자는 **스탬프 인장** 이다. 음악 레슨 앱은 **인장을 찍는 의례** 에 가까우므로, 이 8건의 교체는 **디지털 버튼을 인장으로 되돌리는 작업** 이었다.

---

### 7.81 students_tab 모달 시트 제목 Playfair + parent_home/ 전수 감사 "값 표시 전용" 도메인 확인 — §7.27 배치 + 0건 변환

**배경**: §7.79 에서 3-도메인 "동적 값 집중" 클러스터 관찰 후, parent_home/ 와 students/ 도메인을 병행 감사. students/ 는 2건 변환(students_tab sheet 2건), parent_home/ 는 **11건 전원 §7.30 exclusion** — 변환 0건. 학부모 대시보드는 **"자녀 이름·결제 금액·자녀 상태·월 선택·잔여 일수"** 등 전부 동적 값이 지배, **Playfair 승격 대상이 0**인 첫 사례.

**변환 2건** (students_tab):

| 파일 | 라인 | 텍스트/패턴 | 변경 |
|---|---:|---|---|
| students_tab.dart | 384 | `'연습상태로 필터'` (bottom sheet title) | §7.27 → appBarTitle |
| students_tab.dart | 471 | `'정렬 기준'` (bottom sheet title) | §7.27 → appBarTitle |

> §7.67 masthead 승격은 `_buildHeader()` 에 한정되어, 이 두 모달 시트 타이틀은 orthogonal scope 로 별도 변환.

**§7.30 제외 13건** (parent_home 11 + student_detail 2):

| 도메인 | 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|---|
| parent_home/ | unconnected_child_dashboard:103 | `child.name` | dynamic name |
| parent_home/ | parent_lessons_tab:419 | `monthName` (이전/다음 arrow 사이) | dynamic month label |
| parent_home/ | parent_payments_tab:297 | `profile.name` | dynamic name |
| parent_home/ | parent_payments_tab:504 | `'등록된 자녀가 없습니다'` (child_care icon) | empty-state |
| parent_home/ | parent_payments_tab:569 | `'등록된 수강권이 없습니다'` (ticket icon) | empty-state |
| parent_home/ | parent_payments_tab:603 | `'오류가 발생했습니다'` | error headline |
| parent_home/ | parent_dashboard_tab:254 | `'등록된 자녀가 없습니다'` | empty-state |
| parent_home/ | parent_dashboard_tab:587 | `'28'` (calendar day + weekday stack) | dynamic date |
| parent_home/ | parent_dashboard_tab:767 | `'300,000원'` (금액 + 배지 stack) | dynamic price |
| parent_home/ | child_profiles_screen:76 | `'등록된 자녀가 없습니다'` | empty-state |
| parent_home/ | widgets/stat_card:36 | `value` (icon + value + label stack) | dynamic stat |
| students/ detail | student_lesson_card:65 | `'${lesson.date.day}'` (date block) | dynamic date |
| students/ detail | student_practice_tab:142 | `value` (icon + value + label stack) | dynamic stat |

**도메인 관찰**: parent_home/ 는 **"학부모 대시보드 = 자녀 상태 중계소"** 성격이 극단적이다. 학부모는 자신이 아닌 **자녀의 상태를 조회**하는 것이 주 목적이라 모든 제목이 자녀 이름·금액·일정 같은 **동적 값**으로 채워진다. §7.61 에서 이미 masthead 레벨 통일은 완료됐고, 이번 감사로 **sub-widget 층위는 추가 Playfair 승격 여지가 없음**을 확인.

**"변환 0건" 도메인의 의미**: parent_home/ 는 Playfair 승격 대상이 **원천적으로 없는** 도메인. 이는 Notebook × Score 롤아웃이 **포화점**에 도달했다는 신호다. 향후 신기능 추가 시에만 Playfair 대상이 발생할 가능성. 반대로 **"§7.30 전수 확인 완료"** 라벨을 붙여 재탐색 스코프에서 제외하는 효율화 가능.

**전환율 비교** (10 도메인 집계):

| 도메인 | heading 발견 | 변환 | §7.30 제외 | 전환율 | 본질 |
|---|---:|---:|---:|---:|---|
| lessons/widgets (§7.78) | 15건 | 10건 | 5건 | 66.7% | 상태 전이 모달 이름 |
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% | 정적 명사 |
| **students/ (§7.81)** | **4건** | **2건** | **2건** | **50%** | **모달 시트 제목** |
| profile/ (§7.77) | 7건 | 2건 | 5건 | 28.6% | 금액 중심 |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% | 동적 이벤트 |
| 3-도메인 클러스터 (§7.79) | 10건 | 2건 | 8건 | 20% | 동적 값 집중 |
| invite/ (§7.76) | 8건 | 1건 | 7건 | 12.5% | 상태 전이 피드백 |
| schedule/widgets (§7.73) | 10건 | 1건 | 9건 | 10% | 동적 시간대 |
| **parent_home/ (§7.81)** | **11건** | **0건** | **11건** | **0%** | **자녀 상태 중계소** |

**커밋**: `e48d0f5c` style(students): Notebook × Score §7.27 배치 #1
**검증**: `flutter analyze` students_tab → No issues found! (ran in 3.4s)

**다음 후보**: search/ (teacher_detail/academy_detail — parallel-contested 경고 있음, 사전 §7 섹션 검색 필수), auth/ (로그인·가입 화면, 전수 미감사), practice/screens (§7.62·§7.64·§7.66 이후 남은 화면), lessons/screens 잔여(§7.75 후 추가 파일 탐색).

**은유**: §7.81 은 **"도서관의 비어있는 서가"** 를 확인하는 일이었다. parent_home/ 의 11개 headingSmall 은 모두 **책이 없는 서가 라벨** (= 자녀가 아직 연결되지 않음, 수강권이 없음)이거나 **책의 가격표** (= 결제 금액, 자녀 이름). Playfair 는 **"이 서가에 어떤 책이 꽂히는가"** 를 말할 때 빛나지, **"지금 몇 권 있는가"** 를 말할 때는 Gothic 이 더 정직하다. 이 도메인의 0% 전환율은 실패가 아니라 **"정직한 0%"** — Notebook × Score 가 개입할 필요가 없는 공간이 어디인지 명확히 그어준다.

---

### 7.82 auth/ 진입 경험 전수 감사 — 화면 타이틀 §7.17 + 바텀시트 §7.27 + Vermillion CTA §7.50 통합 배치

**배경**: §7.80 예고 후보 3("타 도메인 §7.50 잔재") + §7.81 예고 후보 2("auth/ 로그인·가입 화면, 전수 미감사") 실행. `home/` 0건, `parent/` 폴더 부재. `auth/` 에서 `Colors.white` 6건 + `AppTypography.heading` 9건 발견. **진입 경험(로그인/초대코드/약관/역할선택)** 은 사용자가 앱을 처음 만나는 의례적 문턱이므로, Playfair + Vermillion 시그니처를 가장 집중적으로 적용해야 하는 도메인. 10건 동시 배치로 의례적 진입 경험 재구성.

| 파일 | 라인 | 요소 | 패턴 |
|---|---:|---|:---:|
| student_invite_code_screen | 76 | `'학생 등록'` | §7.17 |
| student_invite_code_screen | 169 | FilledButton `foregroundColor` | §7.50 |
| student_invite_code_screen | 186 | Spinner `AlwaysStoppedAnimation` | §7.50 spinner |
| parent_invite_code_screen | 77 | `'학부모 등록'` | §7.17 |
| terms_agreement_screen | 61 | `'서비스 이용 동의'` | §7.17 |
| terms_agreement_screen | 143 | `'계속'` FilledButton text | §7.50 |
| terms_agreement_screen | 269 | `title` (dynamic 바텀시트 헤더) | §7.27 |
| role_select_screen | 87 | `'$userName님, 환영합니다!'` | §7.17 |
| login_bottom_sheets | 47 | `'학부모 로그인'` | §7.27 |
| login_bottom_sheets | 130 | `'역할을 선택하세요'` | §7.27 |

**수량**: 10 code-line edits (+ 5 imports). 7 Playfair 승격 (§7.17 4건 + §7.27 3건) + 3 §7.50 Vermillion foreground.

**§7.50 범위 밖 유지 3건** — 의도적 `Colors.white` 보존:

| 파일:라인 | 배경 | 유지 이유 |
|---|---|---|
| parent_invite_code_screen:167 | `AppColors.ink` (검정) | §7.50 은 **paperAccent(Vermillion) 배경에만** 적용. ink 배경 위 흰 글씨는 가독성 때문에 Colors.white 유지 |
| parent_invite_code_screen:180 | `AppColors.ink` | 동일 (spinner) |
| login_bottom_sheets:91 | `AppColors.appleBackground` | Apple 브랜드색(검정) — 브랜드 가이드 준수 |

**§7.30 제외 2건** — 의도적 Gothic 유지:

| 파일:라인 | 텍스트 | 제외 카테고리 |
|---|---|---|
| student_invite_code_screen:97 | `letterSpacing: 4` 코드 입력 필드 | input field style (헤딩 스타일을 monospace-like 입력에 재사용) |
| parent_invite_code_screen:95 | 동일 | 동일 |

**동적 타이틀 승격 판단** — `terms_agreement_screen:269 title` (dynamic 인자), `role_select_screen:87 '$userName님, 환영합니다!'` (dynamic name) 둘 다 **구조적으로 화면/바텀시트 헤더 포지션** 이므로 §7.17/§7.27 적용 (§7.78 `add_tip_bottom_sheet.dart:70 widget.title` 선례와 동일한 판정).

**검증**: `flutter analyze lib/features/auth/` → No issues found! (ran in 8.1s). 5 imports 추가, 10 edits 모두 성공.

**커밋**: (Cycle 38 진행 중)

**도메인 관찰**: auth/ 는 **"진입 의례"** 도메인. 로그인 바텀시트 → 역할 선택 → 환영 메시지 → 초대 코드 입력 → 약관 동의 — 사용자가 앱에 처음 발 들이는 5단계 여정. 이 도메인에서 §7.17(화면 타이틀) 과 §7.27(바텀시트 제목) 이 **같은 밀도** 로 섞여 있음이 특징 — 진입 흐름에서 풀스크린과 바텀시트가 번갈아 등장하기 때문. 전환율은 **78%** (9건 heading 중 7건 Playfair 승격, 2건은 입력 필드 스타일 재사용) — **auth/ 도메인 진입 경험 전체가 정적 명사 타이틀 중심** 임을 확인.

**전환율 비교** (업데이트):

| 도메인 | heading 발견 | 변환 | §7.30/Input 제외 | 전환율 | 본질 |
|---|---:|---:|---:|---:|---|
| **auth/ (§7.82)** | **9건** | **7건** | **2건 (input field style)** | **78%** | **진입 의례** |
| lessons/widgets (§7.78) | 15건 | 10건 | 5건 | 66.7% | 상태 전이 모달 이름 |
| subscription/screens (§7.68+§7.70) | 25건 | 14건 | 11건 | 56% | 정적 명사 (수강권) |
| profile/ (§7.77) | 7건 | 2건 | 5건 | 28.6% | 금액 중심 |
| schedule/screens (§7.71) | 9건 | 2건 | 7건 | 22% | 동적 이벤트 |
| student_home+gamification+settings (§7.79) | 10건 | 2건 | 8건 | 20% | 동적 값 집중 |
| invite/ (§7.76) | 8건 | 1건 | 7건 | 12.5% | 상태 전이 피드백 |
| schedule/widgets (§7.73) | 10건 | 1건 | 9건 | 10% | 동적 시간대 |
| parent_home (§7.81) | 11건 | 0건 | 11건 | 0% | 값 표시 전용 |

**신규 관찰**: **"입력 필드 스타일 재사용"** 이라는 §7.30 서브 카테고리 발견 — auth/ 의 초대 코드 입력 필드가 `AppTypography.headingMedium` 을 `letterSpacing: 4` 와 함께 **monospace-like input style** 로 재사용. 이 경우 heading 은 "제목" 이 아니라 "큰 글자 입력 영역" 역할이므로 Gothic 유지가 맞음. 향후 auth/ 아닌 다른 도메인에서도 동일 패턴 있을 수 있음 (PIN 입력, OTP 입력 등).

**§7.50 적용 조건 재확인**: "Vermillion 배경에 한정" 이라는 원칙을 auth/ 에서 재검증. parent_invite_code_screen 의 ink 배경 / login_bottom_sheets 의 appleBackground 는 각각 "검정 배경" 과 "Apple 브랜드 가이드" 맥락이므로 Colors.white 유지. §7.50 은 **Notebook × Score 팔레트 내부** 에만 적용되며, **외부 브랜드 컬러(Google/Kakao/Apple) 와 순수 검정(ink) 배경은 범위 밖**.

**다음 후보**:
1. `students/` 도메인 잔재 (student_detail 제외 — §7.74 완료)
2. `core/widgets/` 공통 위젯 §7.50 잔재 스윕
3. `practice/screens` (§7.62·§7.64·§7.66 이후 남은 화면 — §7.81 에서도 언급)
4. `search/` (teacher_detail/academy_detail — §7.81 parallel-contested 경고)

**은유**: §7.82 는 **입구의 문장을 전부 고쳐 쓰는 일**이었다. 건물에 들어가는 사람은 **입구의 서체** 로 그 건물의 격을 가늠한다. `Gothic` 은 **"디지털 로비"** — 효율적이지만 차갑다. `Playfair` 는 **"손으로 쓴 웰컴 카드"** — 한 박자 느리지만 환영받는 느낌. auth/ 의 7건 타이틀이 Playfair 로 바뀌면서 **"등록하세요"** 에서 **"등록해 주세요"** 로 **어조가 변한다** (실제 텍스트는 같지만). Vermillion 버튼(`계속`, `코드 확인하기`)의 글자가 `Colors.white` 에서 `AppColors.paper` 로 바뀌면서 **"디지털 확인 버튼"** 이 **"잉크로 찍는 도장"** 이 된다. 진입 의례 전체가 **종이 한 장짜리 편지** 의 질감으로 재구성된 것이 §7.82 의 의도. parent_home/ 의 0% 전환율(§7.81)과 대조적으로 auth/ 의 78% 전환율은 — **"값이 흐르는 공간" 과 "의례가 일어나는 공간"** 이 Notebook × Score 적용 밀도의 극과 극임을 보여준다.

---

### 7.83 core/widgets/ 공통 위젯 §7.50 스윕 — 전 앱 Avatar·EditBadge·Check·Chip 일괄 정리

**배경**: §7.82 예고 후보 2("core/widgets/ 공통 위젯 §7.50 잔재 스윕") 실행. 공통 위젯은 **수십 개 화면에서 재사용** 되므로, 1건 수정이 전 앱 팔레트에 영향. `core/widgets/` 전수 감사 → `Colors.white` 9건이 §7.50 범위 (avatar ring/initial, edit badge border/icon, check glyph, chip selection, bottomsheet default bg) 에 해당. 단일 사이클로 **전 앱 Vermillion/profile-color foreground 를 한꺼번에 paper 로 전환**.

| 파일 | 라인 | 요소 | 패턴 |
|---|---:|---|:---:|
| bottom_sheet_handle.dart | 44 | `BottomSheetContainer` default `backgroundColor` | §7.50 팔레트 일관성 |
| profile_photo_header.dart | 86 | CircleAvatar ring border | §7.50 avatar ring |
| profile_photo_header.dart | 98 | avatar initial text color | §7.50 avatar initial (컬러) |
| profile_photo_header.dart | 176 | edit badge border (paperAccent bg) | §7.50 Vermillion edit badge |
| profile_photo_header.dart | 178 | edit badge Icon.camera_alt | §7.50 Vermillion edit badge |
| profile_image_widget.dart | 57 | edit badge border (paperAccent bg) | §7.50 Vermillion edit badge |
| profile_image_widget.dart | 62 | edit badge Icon.camera_alt | §7.50 Vermillion edit badge |
| lesson_progress_bar.dart | 194 | Icons.check (paperAccent dot) | §7.50 check glyph |
| compact_week_strip.dart | 140 | selected day text (paperAccent bg) | §7.50 chip selection |

**수량**: 9 code-line edits (0 imports — 전 파일 `AppColors` 기 임포트). 전 앱 공통 위젯 기본값/foreground 를 Notebook paper 기준으로 통일.

**§7.50 잔재 패턴 6개로 확장** — §7.80 에서 5개 (avatar initial, badge count, loading spinner, check glyph, chip selection) 에 §7.83 에서 **1개 추가**:

| # | 패턴 | 최초 발견 | §7.83 사례 |
|:-:|---|---|---|
| 1 | avatar initial (타이포 §7.30 유지, 컬러만 paper) | §7.72 | profile_photo_header:98 |
| 2 | badge count | §7.75 | (없음) |
| 3 | loading spinner | §7.75 | (없음) |
| 4 | check glyph | §7.80 | lesson_progress_bar:194 |
| 5 | chip/pill selection | §7.80 | compact_week_strip:140 |
| **6** | **avatar ring + edit badge (border + icon)** | **§7.83** | profile_photo_header x3, profile_image_widget x2 |

**특별 항목**: `bottom_sheet_handle.dart:44 BottomSheetContainer.backgroundColor` 는 **기본값 변경** — 이 위젯을 사용하는 `payment_detail_sheet`, `add_payment_sheet` 두 곳이 자동으로 Notebook paper 배경으로 전환됨 (behavioural side-effect, 의도적). §7.80 에서 `ai_notes_result_sheet:54` 를 직접 교체한 것을 이번에는 **공통 위젯 기본값으로 끌어올려** 향후 신규 바텀시트도 자동으로 paper 기반이 되도록 보장.

**§7.50 범위 밖 유지 (이번 사이클)**:

| 파일 | 건수 | 이유 |
|---|---:|---|
| week_calendar_widget.dart | 17건 | 진한 ink 배경 기반 주간 캘린더 — 별도 사이클 필요 (전체 레이아웃 컨텍스트 필요) |
| debug_role_switcher.dart | 2건 | 디버그 전용 화면 — 프로덕션 비노출 |
| recording_diagnostic_screen.dart | 0건 (Colors.white) / 1건 (heading) | 디버그 전용 화면 |

week_calendar_widget 은 **ink 검정 배경 위 흰색 그리드** 구조이므로 §7.50 "Vermillion 배경" 조건 밖. 별도 컨텍스트 분석이 필요하므로 차기 사이클 후보로 유지.

**검증**: `flutter analyze lib/core/widgets/` → No issues found! (ran in 4.5s). 9 edits 모두 성공.

**커밋**: (Cycle 39 진행 중)

**도메인 관찰**: `core/widgets/` 는 **"앱 전체의 근육 조직"** — 여기서 1건 수정이 수십 화면에 파급. 이번 9건 배치의 실질적 임팩트는 **약 40+ 화면** 의 avatar/edit badge/check glyph/chip selection 이 동시에 Notebook paper 로 전환. **공통 위젯 스윕은 Per-screen 배치 대비 ROI 수십 배**. 향후 Notebook × Score 적용 전략 원칙 확정: **"도메인 스윕 → 공통 위젯 스윕 → 나머지 개별 화면"** 순서.

**다음 후보**:
1. `week_calendar_widget.dart` 단독 컨텍스트 분석 (ink 배경 17건 재해석)
2. `students/` 도메인 잔재 (student_detail 제외)
3. `practice/screens` (§7.62·§7.64·§7.66 이후 남은 화면)
4. `core/widgets/` heading 5건 (profile_image_widget avatar initial은 이미 paperAccent — 변경 불필요, 나머지는 디버그 전용)

**은유**: §7.83 은 **"도시의 수도관을 한 번에 교체하는 일"** 이었다. 각 건물(화면)을 돌며 수도꼭지(색상)를 하나씩 갈아 끼우는 대신, **중앙 배관(공통 위젯)** 을 손봐서 전 도시의 수질을 한꺼번에 바꾼다. 사용자는 어느 화면에서 avatar 테두리를 보든, edit 배지를 누르든, 체크 표시를 확인하든, 모두 같은 **"종이에 찍힌 잉크"** 질감을 경험한다 — Material 기본값의 **"LED 광택"** 이 앱 전역에서 사라졌다. §7.80 의 **"디지털 버튼 → 잉크 도장"** 은유를 공통 위젯 층위로 끌어올린 것이 §7.83.

---

### 7.84 search/ 선생님·학원 상세 §7.17 + practice/·lessons/ §7.30 전수 감사 — "동적 값 집중" 도메인 재확인

**기간**: 2026-04-23
**대상**: `features/search/presentation/screens/` (2건), `features/practice/presentation/` (9건), `features/lessons/presentation/widgets/` (4건) 의 `AppTypography.headingSmall` 사용

**배경**: §7.79 에서 도출한 "**정적 명사 도메인은 전환율이 높고, 동적 값 도메인은 0 에 수렴한다**" 가설을 practice/ 와 lessons/ 에서 재검증. 병행 세션이 §7.78 (lessons/widgets §7.27), §7.80 (lessons/widgets §7.50), §7.82 (auth/), §7.83 (core/widgets/) 을 가져갔으므로 이번 배치는 **남은 3 도메인** 의 §7.17 + §7.30 교차 감사에 집중.

**변환 (2건, §7.17)** — 공통 헬퍼 수정으로 **총 9 호출부** 를 일괄 승격:

| 파일 | 라인 | 문자열 | 근거 |
|------|------|--------|------|
| `features/search/.../academy_detail_screen.dart` | 247 | `'소속 선생님'` | 정적 카테고리 헤더 — 학원 내 선생님 목록 섹션 |
| `features/search/.../teacher_detail_screen.dart` | 630 (`_buildSection` 공통 헬퍼) | `title` 파라미터 | **공통 수정 → 8 호출부 일괄 반영** (`'전문 악기'`/`'소개'`/`'경력'`/`'수업 방식'`/`'수업 지역'`/`'학력'`/`'경력 사항'`/`'인증된 자격증'`) |

`teacher_detail_screen.dart` 은 **헬퍼 패턴의 모범 사례** — 한 줄 수정으로 8개 섹션 헤더가 동시 승격됐다. 이는 §7.30 로드맵의 **"공통 수정을 찾아 일괄 반영"** 지침을 가장 선명하게 보여주는 사례.

**§7.30 제외 (13건 × 3 도메인)**:

| 파일 | 라인 | 사유 |
|------|------|------|
| `practice/presentation/widgets/tuner/circular_tuner_indicator.dart` | 367 | `centText` (튜너 cent 편차 — 동적 측정값, 색상 3단계 분기) |
| `practice/presentation/widgets/section_detail/practice_stats_card.dart` | 80 | `value` (연습 통계 값, 아이콘 + 값 + 라벨 layout) |
| `practice/presentation/widgets/stats/stats_summary_card.dart` | 131 | `value` (통계 요약 카드 — 동적 값) |
| `practice/presentation/widgets/history_summary_card.dart` | 82 | `value` (히스토리 요약 — 동적 값) |
| `practice/presentation/widgets/month_group_header.dart` | 43 | `monthGroup.label` (월 그룹 레이블 — 동적 월 문자열) |
| `practice/presentation/widgets/practice_tools_modal.dart` | 163 | `unselectedLabelStyle` (TabBar — §7.30 UI 분리자) |
| `practice/presentation/screens/quick_add_screen.dart` | 439 | `'섹션 ${index + 1}'` (동적 인덱스) |
| `practice/presentation/screens/edit_section_screen.dart` | 302 | `_repertoire!.name` (동적 이름) |
| `practice/presentation/screens/add_section_screen.dart` | 320 | `_repertoire!.name` (동적 이름) |
| `practice/presentation/screens/section_picker_screen.dart` | 202 | `'섹션이 없습니다'` (빈 상태 + `library_music_outlined` 아이콘) |
| `lessons/presentation/widgets/lesson_detail/lesson_header_card.dart` | 47 | 학생 아바타 이니셜 |
| `lessons/presentation/widgets/add_youtube_resource_sheet.dart` | 263 | `'~'` (UI 분리자) |
| `lessons/presentation/widgets/lesson_form/edit_lesson_widgets.dart` | 51 | `student.color` 적용 동적 이름 |
| `lessons/presentation/widgets/lesson_form/lesson_student_selector.dart` | 42 | 동적 학생명 카드 |

**도메인 전환율 누적 (13 도메인)**:

| 도메인 | 발견 | 변환 | 제외 | 전환율 | 성격 |
|--------|------|------|------|--------|------|
| auth/ | 9 | 7 | 2 | 78% | 진입 경험 (§7.82) |
| lessons/screens | 3 | 2 | 1 | 66.7% | 세션 경과·정보 밀집 (§7.75) |
| lessons/widgets §7.27 | 4 | 3 | 1 | 75% | 바텀시트 (§7.78) |
| students/ | 2 | 1 | 1 | 50% | 모달 시트 제목 (§7.81) |
| students/widgets | 2 | 1 | 1 | 50% | 상세 Info 탭 (§7.74) |
| subscription | 25 | 14 | 11 | 56% | 템플릿·제안 카드 |
| profile | 7 | 2 | 5 | 28.6% | 금액 중심 (§7.77) |
| student_home | 4 | 2 | 2 | 50% | 선생님 카테고리 (§7.79) |
| **search/** | **10** | **9** | **1** | **90%** | **정적 카테고리 집중 (§7.84)** |
| schedule/widgets | 10 | 1 | 9 | 10% | 동적 값 집중 |
| invite/ | 8 | 1 | 7 | 12.5% | 상태 전이 피드백 (§7.76) |
| **practice/** | **9** | **0** | **9** | **0%** | **연습 섹션·레퍼토리 값 표시 (§7.84)** |
| lessons/widgets §7.30 | 4 | 0 | 4 | 0% | UI 분리자·학생 참조 (§7.84) |
| parent_home | 11 | 0 | 11 | 0% | 자녀 상태 중계소 (§7.81) |
| settings/gamification | 6 | 0 | 6 | 0% | 백업 스탯·뱃지 토큰 (§7.79) |

**핵심 관찰 — 전환율 90% 돌파 사례 **: search/ 는 **정적 카테고리 헤더 집중 도메인** 으로 전 도메인 최고 전환율(90%)을 기록. `teacher_detail_screen.dart` 의 공통 헬퍼 `_buildSection` 이 8 호출부를 일괄 포섭한 것이 결정적 — **"한 줄 공통 수정이 8개 호출부를 승격한다"** 는 §7.30 목표의 가장 완성된 구현. 반대로 practice/ 는 **연습 측정값 표시** 에 특화되어 있어 전원 §7.30 — 튜너의 cent 편차, 연습 시간 통계, 섹션 인덱스, 레퍼토리 이름은 모두 **동적 값** 이다. 정적 카테고리 헤더가 없는 도메인 (parent_home, practice, lessons/widgets §7.30 의 학생 참조, settings/gamification 토큰) 은 **Playfair 승격 대상 원천 부재** 로 재확인.

**§7.30 사전 점검 프로토콜**: §7.79–§7.84 의 누적 감사로 다음 패턴이 100% §7.30 확정:
1. TabBar label/unselectedLabelStyle
2. 학생·선생님 이름 카드 (color 테마 적용 대상)
3. 튜너·스탯 카드 `value` 필드 (아이콘 + 값 + 라벨)
4. 월/일자/D-Day 레이블
5. UI 분리자 (`~`, `・`, 점)
6. 아바타 이니셜 (circleAvatar `child: Text()`)
7. 빈 상태 headline (icon + 메시지)
8. 에러 headline (AppStrings.errorOccurred 등)
9. 게임화 토큰 (뱃지 pts, 레벨)
10. 동적 인덱스 (`'섹션 ${index + 1}'`)

향후 배치는 위 10 패턴을 **즉시 §7.30 자동 판정** 하여 파일 읽기 생략 가능. 판단 보수주의는 유지하되 속도를 확보.

**검증**:
- `flutter analyze lib/features/search/` → No issues found (5.1s)
- 코드 커밋: `074c4927` (search/ 2 파일, +10 -2)
- 공통 헬퍼 수정으로 8 호출부 일괄 반영

**은유**: §7.84 는 **"도서관 분류표를 모두 한글 정자체로 바꾸는 일"** 이었다. `teacher_detail_screen` 의 `_buildSection` 은 도서관의 **분류 템플릿** — 한 번 바꾸면 "전문 악기", "소개", "경력", "수업 방식", "수업 지역", "학력", "경력 사항", "인증된 자격증" 8개 분류가 동시에 같은 서체로 바뀐다. 반면 practice/ 의 튜너 수치·연습 통계·섹션 번호는 **도서관 벽의 시계 바늘** — 항상 움직이며 숫자를 표시할 뿐, 제목(명사)이 될 자격이 없다. Playfair 는 **"이것은 이름이다"** 라고 선언하는 서체이지, **"이것은 지금 재고다"** 라고 속삭이는 서체가 아니다.

---

### 7.85 subscription/ 잔재 15건 전수 감사 — §7.30 10-패턴 자동 판정 성공 (0건 변환, 3번째 포화 도메인)

**기간**: 2026-04-23
**대상**: `features/subscription/presentation/` 의 `AppTypography.headingSmall` 잔재 15건 (screens 9 + widgets 6)

**배경**: §7.84 에서 확정한 **"§7.30 자동 판정 10-패턴"** 을 실전 적용. subscription 도메인은 §7.40–§7.62 전후에 이미 핵심 템플릿·제안 카드 승격이 끝났고, 남은 15건은 **동적 가격·동적 이름·빈 상태·에러 상태·대기 상태** 로 구성될 것으로 예측. 파일 Read 없이 컨텍스트 스캐닝만으로 100% §7.30 판정 가능한지 검증.

**결과**: **15건 전원 §7.30** — 예측 적중. 10-패턴 중 **#2(동적 이름), #3(stat value ≈ 가격), #7(빈 상태), #8(에러 headline), status with icon(새 서브패턴)** 로 구성:

| 파일 | 라인 | 분류 | 세부 |
|------|------|------|------|
| `screens/proposal_confirm_screen.dart` | 253 | #3 | `_formatPrice(price)` 결제가 |
| `screens/proposal_detail_screen.dart` | 444 | #3 | `template.formattedPrice` |
| `screens/subscription_template_list_screen.dart` | 286 | #2 | `template.name` (비활성 상태 inkTertiary 분기) |
| `screens/renewal_detail_screen.dart` | 337 | #3 | `template.formattedPrice` |
| `screens/subscription_detail_screen.dart` | 83 | #7 | `AppStrings.subscriptionNotFound` + `Icons.search_off` 빈 상태 |
| `screens/subscription_detail_screen.dart` | 107 | #8 | `AppStrings.errorOccurred` + `Icons.error_outline` |
| `screens/subscription_list_screen.dart` | 308 | #7 | `'등록된 수강권이 없습니다'` + `Icons.confirmation_number_outlined` |
| `screens/subscription_list_screen.dart` | 336 | #7 | `'등록된 레슨이 없습니다'` + `Icons.school_outlined` |
| `screens/subscription_list_screen.dart` | 369 | #8 | `'오류가 발생했습니다'` + `Icons.error_outline` |
| `widgets/issue_form_membership_widgets.dart` | 223 | #7 | `'등록된 레슨이 없습니다'` + `Icons.school_outlined` |
| `widgets/issue_form_membership_widgets.dart` | 258 | #8 | `'오류가 발생했습니다'` + `Icons.error_outline` |
| `widgets/selectable_template_card.dart` | 147 | #3 | `template.formattedPrice` (선택 여부로 색상 분기) |
| `widgets/template_choice_card.dart` | 72 | #2 | `template.name` (추천 뱃지 옆) |
| `widgets/proposal_card_widgets.dart` | 329 | #3 | `_formatPrice(discountedPrice)` 할인 결제가 |
| `widgets/proposal_card_widgets.dart` | 567 | status+icon | `'입금 확인 대기중'` + `Icons.hourglass_empty` (대기 상태 headline) |

**포화 도메인 계보**: parent_home(§7.81 0/11) → settings+gamification(§7.79 0/6) → practice(§7.84 0/9) → **subscription-잔재(§7.85 0/15)** 로 4번째. subscription 은 §7.40 이전 배치에서 핵심 템플릿 이름을 이미 승격했으므로, **"한 도메인을 두 세션 걸쳐 감사"** 할 경우 후반부는 §7.30 로 수렴한다는 2차 법칙 관찰. — **Playfair 승격은 도메인 전반 확산이 아니라 "소수 정적 명사 집중"** 에서 완결된다.

**검증**: 파일 Read 없이 Grep + 컨텍스트 스캐닝만으로 15/15 판정 성공. 판단 근거는 `Text(` 직전·직후 **2~3줄만** 확인: 아이콘 동반 (§7.30 #7/#8), 변수명 (`_formatPrice`, `template.*`, `booking.*` — §7.30 #2/#3), 색상 분기 (isSelected·isActive — §7.30 #2/#3). **자동 판정 프로토콜 실전 검증 완료.**

**은유**: §7.85 는 **"도서관 반납함을 비우는 일"** — 이미 정식 서가(Playfair 승격 완료분)에 꽂혀 있는 책은 건드리지 않고, 반납함(잔재 15건)에 남은 것들이 모두 **일일 재고 전표** (가격)·**학생 출석부** (이름)·**비어 있음 안내판** (빈 상태)·**"안내 직원 부재중"** (에러)·**"반납 확인 대기중"** (상태) 임을 확인. 전표·출석부·안내판은 서가에 올라갈 수 없다 — 책이 아니기 때문이다.

---

### 7.86 students/ form 잔재 §7.50 + §7.17 혼합 스윕 — Vermillion chip/badge/avatar 8 지점 정리

**기간**: 2026-04-23
**대상**: `features/students/presentation/` 의 `Colors.white` 8 지점 + `AppTypography.headingMedium` 화면 질문 타이틀 1건 (student_detail 제외 — §7.74 종결)

**변경**:

| 파일 | 라인 | 맥락 | 이전 | 이후 | §7.x |
|------|------|------|------|------|------|
| add_student_method_screen.dart | 30 | 화면 질문 타이틀 | `AppTypography.headingMedium` | `NotebookTypography.sectionTitle` | §7.17 |
| add_student_method_screen.dart | 156 | paperAccent 배지 전경 | `Colors.white` | `AppColors.paper` | §7.50 |
| student_profile_section.dart | 31 | paperAccentSoft 아바타 이니셜 | `Colors.white` | `AppColors.paper` | §7.30 + §7.50 교차 |
| student_profile_section.dart | 44 | paperAccent 편집 뱃지 border | `Colors.white` | `AppColors.paper` | §7.50 |
| student_profile_section.dart | 48 | paperAccent 편집 뱃지 아이콘 | `Colors.white` | `AppColors.paper` | §7.50 |
| duration_selector.dart | 45 | paperAccent 선택 chip 전경 | `Colors.white` | `AppColors.paper` | §7.50 |
| schedule_section.dart | 80 | paperAccent 선택 day chip 전경 | `Colors.white` | `AppColors.paper` | §7.50 |
| edit_student_screen.dart | 377 | paperAccent FilledButton 스피너 | `Colors.white` | `AppColors.paper` | §7.50 |

**§7.30 × §7.50 교차 재확인**: `student_profile_section:31` 아바타 이니셜은 §7.30 Gothic 유지 + §7.50 paper 색상이 동시 적용된다. **타이포그라피(서체)와 전경 색상은 직교 규칙이라는 §7.83 원칙의 2차 반복 검증** — 아바타 이니셜은 "이름"이 아니라 "첫 글자 아이콘"이므로 Playfair 승격 불가이지만, Vermillion 계열 배경(paperAccent / paperAccentSoft) 위에 놓인 이상 §7.50 색상 규칙은 무조건 적용된다.

**도메인 관찰**: students/ 는 **"폼 도메인"** — Profile 아바타, 요일 선택, 레슨 시간 선택, 저장 버튼 스피너 모두 "사용자 선택/입력을 받는 chip·badge·spinner"다. 이들은 **선택 상태를 Vermillion 으로 강조** 하므로 선택됐을 때의 전경은 자동으로 §7.50 대상이 된다. 폼 도메인의 공통 어휘: **"선택됐다 = Vermillion 배경 = paper 전경"**.

**잔재 (의도적 제외)**:
- `student_detail_screen.dart` L182/L209/L210/L260/L277/L302/L322/L355 — §7.74 에서 이미 전체 감사 완료. 상단 프로필 컬러 배경에 `Colors.white` 는 의도된 색상 레이어링 (ink 유사 블록 위)이므로 §7.50 범위 밖.
- `student_detail_screen.dart` L767 — 헤더 헤딩 large (프로필 컬러 배경). §7.74 유지.

**검증**: `flutter analyze lib/features/students/` → No issues found (6.4s)

**변환율**: 기존 17건 중 8건 신규 §7.50/§7.17 변환 + 9건 §7.74 확정 (컬러 배경 의도 레이어 + 이미 승격분). **students/ 포화도는 99%** (미해소 0건, 제외 근거 명시 9건).

**은유**: §7.86 은 **"재봉틀의 실색을 맞추는 일"** — 학생 등록 폼은 **재봉틀로 단추를 달고, 옷감을 고르고, 치수를 재는** 작업과 같다. 요일 버튼(단추), 시간 길이 버튼(치수), 저장 버튼 스피너(실패/성공 신호), 프로필 아이콘(옷감 견본)은 모두 **선택 순간 Vermillion 이 빛나고** 그 위에 올라가는 글자·아이콘은 당연히 **크림 색 실**(paper)이어야 한다. 선택이 곧 강조이고, 강조는 곧 §7.50 이다.

---

### 7.87 학생 진입 경험 Notebook × Score 전수 감사 — 스케줄·student_home·onboarding §7.17/§7.27 포화

**기간**: 2026-04-23
**근거 감사 문서**: `docs/specs/design/notebook/student_screens_audit.md` (10 섹션, 학생 role 진입 11개 도메인 전수 매트릭스)
**시리즈 구성**: a(샘플) → b~e(스케줄) → f(student_home) → g(onboarding). 본 §7.87 에서는 본 계획 범위인 **f/g 만 상세 기록**, a~e 는 커밋 히스토리로 추적.

#### 7.87-f student_home/ §7.17 × 9 + §7.27 × 2 = 11 지점 / 10 파일 (커밋 `7b1fe0ae`)

**대상**: 학생 홈 대시보드·탭·시트 전반의 정적 섹션 헤더·시트 헤더.

| 파일 | 라인 | 이전 | 이후 | §7.x |
|------|------|------|------|------|
| widgets/weekly_practice_widget.dart | 96 | `AppTypography.headingMedium` | `NotebookTypography.sectionTitle` | §7.17 |
| widgets/weekly_practice_widget.dart | 195 | 동일 (loading variant) | 동일 | §7.17 |
| widgets/trial_bookings_section.dart | 44 | 동일 | 동일 | §7.17 |
| widgets/dashboard/practice_summary_section.dart | 86 | 동일 | 동일 | §7.17 |
| widgets/dashboard/teacher_feedback_section.dart | 29 | 동일 | 동일 | §7.17 |
| widgets/student_subscription_summary.dart | 67 | 동일 | 동일 | §7.17 |
| screens/student_lessons_tab.dart | 190 | 동일 | 동일 | §7.17 |
| screens/student_practice_tab.dart | 61 | `AppTypography.headingLarge` | `NotebookTypography.sectionTitle` | §7.17 |
| screens/app_info_screen.dart | 44 | `AppTypography.headingLarge` (`'Lessonaza'`) | `NotebookTypography.masthead` | §7.17 (브랜드 특례) |
| widgets/language_select_sheet.dart | 43 | `AppTypography.headingMedium` | `NotebookTypography.sectionTitle` | §7.27 |
| widgets/practice_reminder_sheet.dart | 49 | 동일 | 동일 | §7.27 |

**§7.30 예외 유지 (11건)**: 감사 매트릭스 §2.3 에 확정 기록. `dashboard/next_lesson_card:147`(#4 D-Day), `student_profile_tab:191/270/607`(#2 이름 / #3 stat / #10 초대코드), `student_lessons_tab:231`(#4 날짜), `student_practice_tab:132/177/190`(#4 날짜 3 variant), `my_teachers_screen:509`(#6 이니셜), `student_subscription_summary:268`(#3 stat), `practice_reminder_sheet:147`(#3 dynamic time). **모두 Playfair 승격 불가** — 동적 데이터·개체 식별자·수치는 Gothic 서체가 판독성 규칙.

**브랜드 특례 기록 (`'Lessonaza'`)**: `app_info_screen:44` 는 "섹션 타이틀"이 아니라 **페이지 중앙 브랜드 로고**. `sectionTitle`(17) 은 크기 부족, `masthead`(38) 가 적정. §7.17 을 "브랜드 식별자" 로 확장 적용한 **첫 사례** — 이후 동종 화면(splash·about 류)이 생길 때 동일 스타일 적용.

**검증**: `flutter analyze lib/features/student_home/` → No issues found (11.8s).

**판정 전환**: 감사 §7 섹션의 FLAG 4종 (연습 탭·레슨 탭·연습 리마인더 시트·언어 설정 시트) **모두 PASS 로 전환**. 학생 홈 쉘·대시보드·프로필 탭과 함께 학생 진입 5개 주요 화면 전면 4대 시그니처 준수.

#### 7.87-g onboarding/ §7.17 × 4 지점 / 2 파일 (커밋 `5fe7f3be`)

**대상**: 학생/선생님 공용 온보딩 스텝 타이틀 + 악기 선택 시트.

| 파일 | 라인 | 이전 | 이후 | §7.x |
|------|------|------|------|------|
| student_profile_setup_screen.dart | 158 | `AppTypography.headingLarge` (`'프로필 설정'`) | `NotebookTypography.sectionTitle` | §7.17 |
| student_profile_setup_screen.dart | 438 | `AppTypography.headingMedium` (`'악기 선택'`) | 동일 | §7.27 |
| profile_setup_screen.dart | 206 | `AppTypography.headingLarge` (`'프로필 설정'`) | 동일 | §7.17 |
| profile_setup_screen.dart | 687 | `AppTypography.headingMedium` (`'악기 선택'`) | 동일 | §7.27 |

**후보 3건 이관**: `tutorial_screen:255` / `student_tutorial_screen:252` / `phone_verification_screen:193` — §7.87-h 에서 본격 판정.

**검증**: `flutter analyze lib/features/onboarding/ lib/features/student_home/` → No issues found (12.7s).

#### 7.87-h onboarding 튜토리얼 + 휴대폰 인증 §7.17 × 3 지점 / 3 파일

**대상**: Batch 3.E 후보 재판정 — 튜토리얼 슬라이드 헤드라인 + 휴대폰 인증 스텝 타이틀.

| 파일 | 라인 | 이전 | 이후 | §7.x |
|------|------|------|------|------|
| tutorial_screen.dart | 253 | `AppTypography.headingLarge.copyWith(color: AppColors.ink)` (`content.title`) | `NotebookTypography.sectionTitle` | §7.17 |
| student_tutorial_screen.dart | 250 | 동일 (`data.title`) | 동일 | §7.17 |
| phone_verification_screen.dart | 196 | `AppTypography.headingLarge` (조건부 `'인증번호 입력'` / `'휴대폰 인증'`) | 동일 | §7.17 |

**판정 근거**: 튜토리얼 페이지 제목(`content.title` / `data.title`)은 "슬라이드의 이름표" — 로컬라이즈 문자열 상수로 정의되며 한 슬라이드 내 유일 타이틀. **정적 섹션 명사** 카테고리에 해당. `phone_verification` 의 조건부 타이틀 2종(`'인증번호 입력'` / `'휴대폰 인증'`)도 **코드에 하드코딩된 유한집합** 이므로 정적 명사로 분류 — §7.30 "동적 값" 예외에 해당하지 않음.

**"동적처럼 보이는 정적 명사" 패턴**: `Text(data.title, ...)` 구문은 겉보기에 §7.30 #2(동적 이름) 처럼 보이지만, `data.title` 의 **원천이 빌드 타임 상수** (튜토리얼 페이지 정의) 이면 정적이다. 판정 기준은 **런타임 값의 출처** — 사용자 입력/DB/API 에서 오면 §7.30, 코드 상수/ENUM 이면 §7.17.

**검증**: `flutter analyze lib/features/onboarding/` → No issues found.

**판정 전환**: 감사 매트릭스 §3.2 의 후보 3건 **모두 §7.17 확정**. onboarding 도메인 §7.17 BLOCK 확정 (4 in §7.87-g + 3 in §7.87-h) **= 7/7 포화**. onboarding 전면 PASS.

#### 7.87-i invite/ §7.17 × 4 지점 + §7.30 예외 × 8 지점 확정

**대상**: Batch 3.C — invite/ 도메인 전수 감사 (12 지점 / 6 파일). **편집 세션 중 "정적 카피 + 중앙 정렬 = §7.17" 원칙 재적용** — 다이얼로그/상태 페이지 헤드라인 3건을 §7.30 #8 "상태 헤드라인" 예외에서 §7.17 BLOCK 으로 **재분류**.

**§7.17 BLOCK (4건)**

| 파일 | 라인 | 이전 | 이후 | 근거 |
|------|------|------|------|------|
| invite_confirm_screen.dart | 84 | `AppTypography.headingSmall` (`'연결할 수 없습니다'`) | `NotebookTypography.sectionTitle` | 에러 페이지 정적 헤드라인 (중앙 정렬 + 아이콘 아래 단일 타이틀) |
| invite_confirm_screen.dart | 135 | `AppTypography.headingMedium` (`'$creatorRoleLabel과 연결하기'`) | 동일 | §7.87-h "동적처럼 보이는 정적 명사" — `creatorRoleLabel` ∈ {선생님/학생} enum 유한집합 |
| invite_confirm_screen.dart | 393 | `AppTypography.headingSmall` (`'이미 연결되어 있습니다'`) | 동일 | AlertDialog 중복 연결 정적 헤드라인 |
| invite_confirm_screen.dart | 468 | 동일 (`'연결 요청이 전송되었습니다!'`) | 동일 | AlertDialog 성공 정적 헤드라인 |

**§7.30 예외 (8건)**

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| my_connections_screen.dart | 105 | #7 빈 상태 | `'아직 연결된 X가 없습니다'` 동적 역할 라벨 |
| my_connections_screen.dart | 309 | #6 이니셜 | `otherName[0]` 아바타 이니셜 (DB 이름 원천) |
| my_connections_screen.dart | 315 | #2 이름 | `Text(otherName, ...)` 동적 연결 상대 이름 |
| my_connections_screen.dart | 553 | #6 이니셜 | `name[0]` 아바타 이니셜 |
| pending_requests_screen.dart | 237 | #6 이니셜 | `requesterName[0]` 아바타 이니셜 |
| invite_history_screen.dart | 81 | #7 빈 상태 | `'생성한 초대가 없습니다'` |
| invite_history_screen.dart | 283 | #10 코드 | `invite.inviteCode` + `letterSpacing:4` (6자리 초대 코드) |
| code_input_screen.dart | 221 | #10 코드 | 6자리 초대 코드 입력 박스 |

**판정 근거**: invite/ 는 **연결 관계 워크플로우** 중심 도메인. 다이얼로그/상태 페이지 헤드라인 4건은 **정적 카피 + 중앙 정렬 + 화면 내 단일 타이틀** 로 §7.17 정의를 충족 (§7.89 참조). 나머지 8건은 **DB 원천 동적 이름(#2/#6)**, **빈 상태(#7)**, **초대 코드(#10)** 로 §7.30 예외. 전환율 **4/12 ≈ 33%** — 3차 법칙의 중간대 샘플.

**"#8 상태 헤드라인" 예외 폐기**: 편집 세션 중 제안된 "#8 상태 헤드라인 = §7.30 예외" 신규 패턴은 **정적 카피 + 중앙 정렬 패턴과 충돌** 하여 **§7.87-h 의 "유한 집합 = 정적" 법칙과 일관성 확보를 위해 폐기**. 다이얼로그 헤드라인은 **§7.17 의 3차 확장 (§7.27 바텀시트 → §7.89 다이얼로그/상태 페이지)** 으로 재분류.

**검증**: `flutter analyze lib/features/invite/` → No issues found (7.2s).

#### 7.87 시리즈 관찰

**1차 법칙 재확인 (§7.85 의 2차 법칙)**: 한 도메인의 §7.17 승격은 "정적 섹션 명사 소수" 에 집중된다. student_home 22 잔재 중 **11건만 §7.17/§7.27** 이고 나머지 11건은 §7.30 예외 — 즉 **"도메인 전반 확산이 아니라 명사 집중"** (22건 중 50%). onboarding 은 감사 7건 **모두 §7.17 로 확정** (§7.87-g 4건 + §7.87-h 3건 = 7/7, 100%) — 튜토리얼/프로필/인증 스크린이 전부 **정적 카피 중심** 이기 때문이다. **invite 는 4/12 ≈ 33%** — 연결 의례(다이얼로그/상태 헤드라인 4건) 와 DB 이름·코드 (8건) 가 공존. 네 도메인(스케줄·홈·온보딩·invite) 통합 전환율은 **33% ~ 100% 범위**로, **"도메인의 데이터 비중이 낮을수록 §7.17 전환율이 높다"** 는 3차 법칙이 **의례 vs 데이터 혼합 도메인(invite)** 으로 확장 관찰.

**2차 법칙 발견 — "브랜드 식별자 특례"**: 앱 브랜드 로고 문자열(`Lessonaza`)은 §7.17 의 "섹션 타이틀" 크기 카테고리가 아니라 **매스트헤드 크기**(38 / w700)에 속한다. 섹션 헤더가 화면 내 "영역의 이름" 이라면, 브랜드 로고는 **앱 자체의 이름** 이므로 한 단계 위 타이포그래피 계층(Masthead = 페이지 매스트헤드) 을 공유. 이 분리는 **§7.17 의 "정적 명사" 규칙을 깨지 않는다** — 오히려 정적 명사의 **크기 축(scale axis)** 을 명시적으로 추가한 결과. 크기 축: `pieceTitle`(16) / `sectionTitle`(17) / `appBarTitle`(18) / `dialogTitle`(19) / `masthead`(38).

**은유**: §7.87 은 **"학교 개학 첫 주의 교실 정돈"** — 교문(온보딩)에서 이름표(브랜드 로고)를 달고, 교실(student_home)에 들어가 칠판(대시보드)·사물함(레슨/연습 탭)·게시판(수강권) 을 **같은 서체의 라벨** 로 통일하는 작업. 라벨이 통일되지 않으면 "어느 교실에 왔는지" 혼란이 생긴다. Playfair 의 역할은 **공간의 이름표** 이고, Gothic 의 역할은 **그 안을 채우는 데이터**. 교실 라벨(Playfair)은 바뀌지 않고, 출석부(Gothic)는 매일 바뀐다.

---

### 7.88 교차 도메인 §7.30 예외 재검증 — gamification · search · auth (문서화 배치 3.D)

**기간**: 2026-04-23
**근거**: `docs/specs/design/notebook/student_screens_audit.md` §5·§6 (§7.84 10-패턴 자동 판정)
**성격**: **0 지점 코드 수정** — 감사 단계에서 §7.30 예외로 확정된 10건에 대한 **근거 영속화** 목적. 매트릭스에 흩어진 판정을 README 단일 섹션으로 고정.

#### 7.88-a gamification/ — §7.30 예외 6/6 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| weekly_ranking_card.dart | 87 | #9 게임화 토큰 | 순위 점수 값 (동적) — `weeklyRank.score` |
| badge_collection_screen.dart | 94 | #9 뱃지 이름 | 뱃지 이름은 개체 식별자이지 섹션 명사가 아님 |
| badge_collection_screen.dart | 103 | #9 뱃지 수 | 동적 카운트 (`earnedCount / totalCount`) |
| level_up_dialog.dart | 72 | #9 레벨 값 | 동적 레벨 (`user.level`) |
| level_up_dialog.dart | 84 | #9 축하 메시지 | 템플릿 보간(`'레벨 $newLevel 달성!'`) 포함 |
| badge_award_sheet.dart | 126 | #9 뱃지 이름 | 수여 다이얼로그의 개체 식별자 |

**판정 프로토콜**: §7.79 settings/gamification 0/6 포화 관찰 계보 반복. 게임화 토큰(레벨·점수·뱃지명)은 **"수치"** 혹은 **"개체명"** 이고 "섹션" 이 아니므로 Gothic 유지.

#### 7.88-b search/ — §7.30 예외 2/2 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| teacher_detail_screen.dart | 158 | #2 동적 이름 | `profile.name` 선생님 이름 (Colors.white 전경은 §7.50 별도 검토) |
| academy_detail_screen.dart | 145 | #2 동적 이름 | `academy.name` 학원 이름 |

**§7.84 계보**: search/ 10 잔재 중 9건 이미 Playfair 승격(§7.84) → 잔재 2건 모두 **개체 이름** 으로 수렴. "정적 명사 집중, 동적 값 제외" 법칙의 재확인 사례.

#### 7.88-c auth/ — §7.30 예외 2/2 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| student_invite_code_screen.dart | 96 | #10 코드 입력 letterSpacing | `TextFormField` 6자리 OTP 입력 — **입력 필드는 타이포그래피 규칙 적용 대상 아님** |
| parent_invite_code_screen.dart | 97 | #10 동일 | 동일 패턴 (부모용) |

**판정 프로토콜**: §7.82 auth/ 78% 전환율 (7/9) 중 남은 2건은 **TextField 입력 letterSpacing**. 사용자 입력 문자열은 "섹션 타이틀" 이 아니라 **"입력 필드 내 글자 간격"** 규칙 (§7.30 #10) 의 적용 대상. Gothic 유지 + letterSpacing 은 별도 축.

#### 7.88 시리즈 관찰

**§7.84 10-패턴 자동 판정의 실증**: gamification 6 + search 2 + auth 2 = **총 10 잔재 전수 §7.30 예외 확정** — 파일 Read 없이 **문자열 컨텍스트만으로 판정 가능**. 이는 §7.84 프로토콜이 **"스캐폴드 없는 상태에서도 정확"** 함을 보여준다. 감사 매트릭스의 예측(§5/§6 "§7.30 예외 수렴 예상") 과 실제 판정 100% 일치.

**"도메인 정체성" 패러다임**: gamification 은 **"게이미피케이션 도메인"** — 뱃지·레벨·순위는 모두 "수치 혹은 개체명" 으로 구성되므로 설계적으로 Playfair 승격이 **불가능한 도메인**. search 는 **"검색 결과 도메인"** — 결과는 항상 DB 에서 오는 개체이므로 "이름" 이 곧 "동적 값". auth 는 **"인증 도메인"** — 대부분의 텍스트가 의례적 카피(§7.82 에서 승격 완료)이지만 입력 필드는 타이포그래피 축이 아니라 letterSpacing 축.

**3차 법칙 확장**: §7.87 에서 초기 관찰한 **"도메인의 데이터 비중이 낮을수록 §7.17 전환율이 높다"** 는 법칙이 역방향으로도 성립 — **"도메인의 데이터 비중이 100% 이면 §7.17 전환율은 0% 에 수렴"**. gamification/search/auth-input 은 전원 후자. 이 법칙으로 향후 감사 시 **"이 도메인은 §7.30 수렴이 자명하므로 파일 Read 스킵 가능"** 판단이 가능해진다.

**은유**: §7.88 은 **"도서관 장서 중 '사전류 · 인명록 · 신청 양식' 을 분류에서 빼는 일"** — 정식 서가(Playfair 섹션 제목) 에는 "책 제목" 만 꽂고, 사전(레벨 1~100, 뱃지 5종), 인명록(선생님 100명 이름), 신청 양식(OTP 6자리 입력) 은 각자 **별도 코너** 에 둔다. 서가 분류표(§7.17)와 사전·인명록·양식(§7.30)은 **같은 서체를 공유할 이유가 없다** — 쓰임이 다르기 때문이다.

---

### 7.89 §7.17 "정적 명사" 3차 확장 — 다이얼로그/상태 페이지 헤드라인 법칙

**기간**: 2026-04-23
**배경**: §7.87-i invite/ 전수 감사의 편집 세션 중 발견. 초기 판정("#8 상태 헤드라인 = §7.30 예외") 과 반대로, **정적 카피 + 중앙 정렬 + 화면 내 단일 타이틀** 3축이 §7.17 을 충족함을 재확인. 실제 코드 변경(4 지점 Playfair 승격) 은 §7.87-i 에 기록, 본 §7.89 는 **법칙 확장의 독립 섹션**.

**§7.17 정의 확장 이력**
- §7.17 (원안): 리스트/탭 내 정적 섹션 헤더
- §7.27: 바텀시트 헤더 (2차 확장)
- **§7.89: 다이얼로그 / 상태 페이지 헤드라인 (3차 확장)**

**3축 판별 기준** (3 모두 충족 시 §7.17 승격)
1. **정적 카피** — 빌드 타임 상수, enum 유한 집합 포함
2. **중앙 정렬** — `textAlign: TextAlign.center` + `Column.crossAxisAlignment: CrossAxisAlignment.center`
3. **화면/다이얼로그 내 단일 타이틀** — 아이콘 아래, 본문 위의 유일한 큰 글씨

**"#8 상태 헤드라인" 예외 폐기 이유**: 초기 §7.87-i 에서 제안됐던 "#8 상태 헤드라인 = §7.30 예외" 패턴은 **정적 카피라는 §7.17 원천 속성과 충돌**. `'연결할 수 없습니다'` / `'이미 연결되어 있습니다'` / `'연결 요청이 전송되었습니다!'` 는 모두 **고정 상수**. §7.30 은 "동적 값 / 개체 식별자 / 수치" 를 위한 예외 카테고리이지, "상태 전환 시 노출되는 정적 카피" 를 위한 것이 아님.

**"동적처럼 보이는 정적 명사" 법칙의 3번째 반복**
- §7.87-h: `data.title` — 상수 클래스 소스
- §7.87-i: `'$creatorRoleLabel과 연결하기'` — enum 라벨 유한 집합
- §7.89: 조건 분기별 AlertDialog 헤드라인 — 각 분기의 카피가 빌드 타임 상수

공통 원칙: **출처가 동적 (DB/API/사용자 입력) 이면 §7.30, 빌드 타임 상수 (ENUM/상수 클래스/조건 분기 리터럴) 이면 §7.17**.

**4차 법칙 — "의례 도메인의 §7.17 전환율"**: §7.82 auth/ 78% · §7.87-g onboarding 100% · §7.87-i invite/ 33% (4/12). **의례 도메인(의식적 상태 전환이 있는 도메인)** 은 §7.17 전환율이 **중~고대** (33% ~ 100%) 로 분포. gamification/search/auth-input (0%) 대비 압도적. 데이터 비중이 혼합되어 있어도 **"상태 전환 순간의 이름"** 이 정적이면 Playfair 로 승격 가능.

**은유**: §7.89 는 **"결혼식장 입간판의 서체 규약을 정립하는 일"** — 식장 입구에 "환영합니다" (성공) / "예식 준비 중" (중복) / "행사 취소" (에러) 세 입간판이 있다. 모두 **정적 카피** / **중앙 정렬** / **단일 타이틀**. Gothic 로 쓰면 "안내방송" 의 어조이고, Playfair 로 쓰면 **"초대장의 연장"** 이 된다. 의례 도메인에서 "지금 당신에게 일어나는 일의 이름" 은 항상 **의전적** 이다. 이 법칙은 앞으로 notifications/ · payment confirm/ · subscription cancel/ 등 상태 전환 UI 에서 **파일 Read 없이 일관 적용** 가능.

---

### 7.90 학생 감사 11 도메인 경계 밖 — 포화 4개 재검증 + stat 도메인 §7.30 수렴

**기간**: 2026-04-23
**성격**: **0 지점 코드 수정** — 감사 매트릭스 외 경계 도메인의 잔재 확인 + §7.30 수렴 확정.
**배경**: §7.87-i 로 학생 진입 11 도메인 감사가 종결된 뒤, 매트릭스 외부 도메인(`notifications/` · `follow/` · `relationship/` · `booking/` · `settings/` · `home/`)에서도 §7.17/§7.30 잔재 여부를 전수 확인.

#### 7.90-a 포화 재검증 — 4 도메인 0건 (`AppTypography.heading*` 잔재 없음)

| 도메인 | grep 결과 | 판정 |
|--------|-----------|------|
| `notifications/` | 0건 | ✅ 포화 확정 (매트릭스와 일치) |
| `follow/` | 0건 | ✅ 포화 확정 |
| `relationship/` | 0건 | ✅ 포화 확정 |
| `booking/` | 0건 | ✅ 포화 추가 (매트릭스 미등재 도메인) |

#### 7.90-b settings/ — §7.30 #3 stat 예외 2/2 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| widgets/backup_widgets.dart | 127 | #3 stat 값 | `Text(value, ...)` 아이콘+라벨 조합의 상단 수치 — 백업 용량/파일 수 |
| screens/all_recordings_screen.dart | 263 | #3 stat 값 | `Text('$count', ...)` 연결됨/미연결 녹음 카운트 |

#### 7.90-c home/ — §7.30 #3 stat 예외 2/2 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| screens/assignment_dashboard_screen.dart | 185 | #3 stat % | `'${(rate * 100).round()}%'` 완료율 중앙 메트릭 |
| screens/assignment_dashboard_screen.dart | 268 | #3 stat 값 | `_buildStatItem` value 셀 — 과제 카운트 |

#### 7.90-d analytics/ — 학생 감사 범위 외 (참고)

`analytics/presentation/screens/teacher_dashboard_screen.dart:265/363` 에 2건 잔재. **선생님 전용 대시보드**이므로 학생 진입 경로 감사 범위 외. 컨텍스트상 §7.30 #3 stat 수렴 추정 — 향후 선생님 감사 배치에서 정식 판정.

#### 7.90 관찰

**전수 감사 완료 선언**: 학생 진입 11 도메인(매트릭스) + 경계 6 도메인(본 섹션) = **총 17 도메인 §7.17/§7.30 전수 감사 종결**. 남은 도메인은 `analytics/`(선생님 전용) 2건뿐. 학생 화면 기준 **Notebook × Score 시그니처 1(Playfair) 포화율 100%**.

**3차 법칙 하한 갱신**: `settings/` · `home/` 은 데이터 비중이 **"stat 중심"** 이라 §7.17 전환율 **0%**. invite(8%)·search·gamification·auth-input(0%) 와 동일 카테고리. **"stat / 개체명 / 코드 / 입력 필드" 4유형 도메인은 파일 Read 없이 §7.30 100% 수렴** 법칙이 본 섹션으로 재확인.

**은유**: §7.90 은 **"교정 작업의 마지막 페이지를 한 번 더 넘기는 일"** — 본문(학생 감사 11 도메인)의 오탈자를 다 잡은 뒤, 판권면(booking) · 판형(settings) · 색인(home stat) · 출판사 로고(analytics — 학생 영역 외)를 차례로 확인한다. 대부분 **"이미 규칙대로 정렬되어 있음"** 을 확인하는 절차. 이 절차 없이는 **"전수 종결"** 을 선언할 근거가 없다. Notebook × Score 디자인 체계의 **감사 프로토콜이 비로소 완성** 된 시점.

---

### 7.91 선생님 감사 개시 — analytics/ §7.30 확정 + 전체 잔재 로드맵

**기간**: 2026-04-23
**성격**: **0 지점 코드 수정** + 선생님 감사 전체 로드맵 수립.
**배경**: 학생 감사(17 도메인) 종결 후 전체 `frontend/lib/features/` grep 결과 — `AppTypography.heading*` 잔재 **169건 / 115 파일**. 학생 경로 도메인(이미 감사 완료분) 제외하면 실질 미감사 잔재는 **~100건**.

#### 7.91-a analytics/ — §7.30 #3 stat 예외 2/2 (100%)

| 파일 | 라인 | §7.30 # | 근거 |
|------|------|---------|------|
| teacher_dashboard_screen.dart | 265 | #3 stat 값 | `formatWonWithComma(stats.totalRevenue)` 이번 달 수익 (동적 금액) |
| teacher_dashboard_screen.dart | 363 | #3 stat 값 | `_buildStudentStatItem` value 셀 — 학생 카운트/평균 등 |

§7.90-d 에서 추정했던 "선생님 대시보드 stat 수렴" 이 정식 확정. **`analytics/` 도메인 감사 종결**.

#### 7.91-b 선생님 감사 전체 로드맵 (Batch 선생님.A ~ 선생님.H)

| 배치 | 도메인 | 잔재 | 예상 판정 | 예상 전환율 |
|------|--------|------|-----------|-------------|
| **선생님.A** (완료) | analytics/ | 2 | 전원 §7.30 #3 | 0% (stat 도메인) |
| 선생님.B | parent_home/ | ~23 | 혼합 — 대시보드 헤더 §7.17 + 지표 §7.30 | 30~50% 예상 |
| 선생님.C | profile/ 2차 | ~19 | 혼합 — 설정 섹션 §7.17 + 결제 stat §7.30 | 40% 예상 |
| 선생님.D | schedule/ 잔재 2차 | ~24 | §7.87-a~e 이후 잔재 재검증 — 대부분 §7.30 | 10~20% 예상 |
| 선생님.E | subscription/ 잔재 2차 | ~18 | §7.85 "0건 변환" 도메인 — §7.30 확정 | 0% 예상 |
| 선생님.F | practice/ 선생님 진입분 | ~24 | §7.84 에서 학생분 0/9 — 선생님분은 일부 §7.17 | 10~30% 예상 |
| 선생님.G | students/ 2차 | ~6 | §7.86/§7.81 이후 잔재 — 대부분 §7.30 | 0~20% 예상 |
| 선생님.H | lessons/ 잔재 | ~5 | §7.78/§7.80 이후 잔재 | 0~20% 예상 |

**예상 전환율 기반 우선순위**: 선생님.B(parent_home) · 선생님.C(profile 2차) 가 **§7.17 후보 밀집** 예상 (합쳐 ~16건 Playfair 승격 가능). 선생님.E(subscription 2차) · 선생님.A(완료) 는 **§7.30 수렴 확정** — 문서화만으로 종결.

#### 7.91 관찰

**3차 법칙 재확인**: `analytics/` 는 §7.88-a gamification, §7.90-b settings, §7.90-c home 과 동일하게 **"stat 중심 도메인"** — 전환율 0%. 파일 Read 없이도 판정 가능한 **4유형 도메인(stat/개체명/코드/입력)** 의 5번째 확증 사례.

**다음 단계 의사결정 프레임**: 선생님 감사는 단일 `/auto` 파이프라인으로 종결 불가능 (총 ~100건 / 8 배치). 각 `/auto` 호출마다 **1 배치** 단위로 진행. 우선순위는 (1) §7.17 후보 밀집 배치 먼저 → (2) §7.30 수렴 확정 배치 뒤에. 이는 "디자인 시그니처 포화" 를 빠르게 끌어올리는 전략이다.

**은유**: §7.91 은 **"교실 순회가 끝난 뒤 교무실 · 도서관 · 체육관 순회를 시작하는 일"** — 학생 (학생 진입 경로) 교실 점검은 끝났다. 이제 선생님의 일상 공간(analytics 대시보드, parent_home 학부모 뷰, profile 설정, 수강권·레슨 관리 도구)을 돌아본다. 교실과 달리 **수치와 관리 도구 비중이 높아** stat 도메인(§7.30)이 다수일 것으로 예상된다. Playfair 의 자리는 "공간의 이름표" 에 한정되고, Gothic 이 "데이터의 대부분" 을 채운다. 선생님 공간 특유의 비율.

---

### 7.92 Batch 선생님.B — parent_home/ §7.17 8 지점 + §7.30 예외 17 지점 확정

**기간**: 2026-04-23
**성격**: **8 지점 BLOCK 반영 + 17 지점 §7.30 예외 문서화**.
**배경**: §7.91-b 로드맵의 Batch 선생님.B 집행. parent_home/ 은 **학부모용 탭 구성** 도메인 — 대시보드 헤더·빈 상태 헤드라인이 §7.17/§7.89 후보이고, 지표·프로필 이름·날짜·초기 문자가 §7.30 예외. 전수 감사 결과 총 **25 지점** = 전환 **8**(32%) + 예외 **17**(68%).

#### 7.92-a §7.17 승격 — 전통 섹션/바텀시트 헤더 4 지점

| 파일 | 라인 | 전환 대상 | 근거 |
|------|------|-----------|------|
| screens/parent_lessons_tab.dart | 139 | `'레슨 노트'` | 바텀시트 헤더 (§7.27) — Playfair sectionTitle 고정 구조 |
| screens/unconnected_child_dashboard.dart | 160 | `'오늘의 연습'` | 정적 섹션 헤더 (§7.17) — 대시보드 상단 구분선 |
| screens/unconnected_child_dashboard.dart | 286 | `'이번 주 연습'` | 정적 섹션 헤더 (§7.17) — 대시보드 중단 구분선 |
| screens/parent_dashboard_tab.dart | 313 | `'자녀 선택'` | 바텀시트 헤더 (§7.27) — 모달 상단 제목 |

#### 7.92-b §7.17 승격 — §7.89 3축 빈 상태/에러 헤드라인 4 지점

| 파일 | 라인 | 전환 대상 | 3축 검증 |
|------|------|-----------|----------|
| screens/child_profiles_screen.dart | 81 | `'등록된 자녀가 없습니다'` | Center + mainAxisAlignment.center + Icon + 단일 헤드라인 ✓ |
| screens/parent_dashboard_tab.dart | 254 | `'등록된 자녀가 없습니다'` | Center + mainAxisAlignment.center + Icon + 단일 헤드라인 ✓ |
| screens/parent_payments_tab.dart | 504 | `'등록된 자녀가 없습니다'` | Center + mainAxisAlignment.center + Icon + 단일 헤드라인 ✓ |
| screens/parent_payments_tab.dart | 603 | `'오류가 발생했습니다'` | Center + mainAxisAlignment.center + Icon + 헤드라인 + 메시지 ✓ |

#### 7.92-c §7.30 예외 17 지점 — 유형별 집계

| 유형 | 건수 | 파일:라인 |
|------|------|-----------|
| #2 개체명 (사용자/자녀 이름, 이니셜) | 6 | profile_header.dart:30(이니셜)/68, child_profiles_screen.dart:223(이니셜), child_card.dart:51, parent_payments_tab.dart:297, parent_dashboard_tab.dart:769(자녀이름) |
| #3 stat 값 (카운트/금액/%) | 8 | stat_card.dart:36, parent_assignments_tab.dart:225, parent_payments_tab.dart:388(`'$count'`), unconnected_child_dashboard.dart:87/103, parent_dashboard_tab.dart:437/451/589 |
| #4 날짜 값 (월/일) | 2 | parent_lessons_tab.dart:420(monthName), 526(`'${date.day}'`) |
| 축 2(center) 실패 — 인라인 빈 상태 | 1 | parent_payments_tab.dart:569 `'등록된 수강권이 없습니다'` — Padding+Column(start 정렬)로 §7.89 3축 불성립 |

#### 7.92 검증

- `flutter analyze lib/features/parent_home/` → **No issues found** (11.8s)
- 잔재 grep 재실행: `AppTypography.heading*` 17건 = §7.30 예외 17건 일치. §7.17 후보 0건 확인.
- NotebookTypography import: 5 파일 중 4 파일 이미 존재, child_profiles_screen.dart 1 파일 신규 추가.

#### 7.92 관찰

**예상 대비 전환율 일치**: §7.91-b 로드맵에서 parent_home 예상 전환율 **30~50%**. 실측 **32%** 로 하한 근접 — parent_home 은 "학부모 대시보드" 특성상 지표·개체명·날짜 같은 §7.30 유형이 2/3 을 차지함. Playfair 는 "탭의 뼈대 헤더 + 빈 상태/에러 헤드라인" 8 지점에만 한정.

**§7.89 3축 검증의 세밀도**: parent_payments_tab.dart:569 (`'등록된 수강권이 없습니다'`) 는 헤드라인 어휘만 보면 §7.89 후보처럼 보이나, **Padding+Column(start 정렬) 인라인 블록**이라 축 2(center) 실패. 같은 파일 504 는 Center 래퍼로 축 2 통과 → Playfair. **동일 어휘라도 배치 맥락에 따라 판정이 갈린다**는 §7.89 3축 법칙이 parent_home 안에서 재확인.

**개체명·이니셜·stat 의 3대 §7.30 축**: parent_home 의 §7.30 17건을 유형 분해하면 #2 개체명(6) + #3 stat(8) + #4 날짜(2) + 축2실패(1). **학부모 뷰는 "누구(개체명) + 얼마(stat) + 언제(날짜)"** 3축으로 구성된다는 도메인 특성 확인. 이는 §7.91-b 에서 예상한 "대시보드 헤더 §7.17 + 지표 §7.30" 분리 원칙과 정확히 일치.

**은유**: §7.92 는 **"학부모 상담실의 차트 벽"** — 벽 위 표제 4개("레슨 노트" · "오늘의 연습" · "이번 주 연습" · "자녀 선택")와 텅 빈 상태일 때의 큰 문구 4개만 필기체(Playfair). 벽에 걸린 차트 속 숫자·이름·날짜는 전부 명조체(Gothic). 학부모가 들어오면 **"표제는 천천히, 숫자는 한눈에"** 읽히는 구조. Notebook × Score 의 **"뼈대는 필기체, 살은 명조체"** 원칙이 학부모용 뷰에서도 유지된다. 선생님 감사 8 배치 중 첫 §7.17 밀집 배치 완료.

---

### 7.93 Batch 선생님.C — profile/ 2차 §7.17 3 지점 + §7.30 예외 16 지점 확정

**기간**: 2026-04-23
**성격**: **3 지점 BLOCK 반영 + 16 지점 §7.30 예외 문서화**.
**배경**: §7.91-b 로드맵 Batch 선생님.C. profile/ 2차 감사 — 프로필 미리보기·가시성 설정·결제 관리·확장 정보 다이얼로그·레슨 시간 설정·레퍼토리 관리를 포함. 전수 감사 결과 총 **19 지점** = 전환 **3**(15.8%) + 예외 **16**(84.2%). **예상(40%) 대비 하회**.

#### 7.93-a §7.17 승격 3 지점

| 파일 | 라인 | 전환 대상 | 근거 |
|------|------|-----------|------|
| widgets/payment_management/payment_summary_section.dart | 29 | `'${month}월 수강료 현황'` | §7.87-h "동적처럼 보이는 정적 명사" — DateTime.now().month 1~12 유한 집합 + 정적 명사 "수강료 현황" |
| widgets/payment_management/add_payment_sheet.dart | 122 | `'결제 추가'` | 바텀시트 헤더 (§7.27) — Playfair sectionTitle |
| screens/outstanding_payments_screen.dart | 48 | `'미수금이 없습니다'` | §7.89 3축 빈 상태: Center + mainAxisAlignment.center + Icon + 단일 헤드라인 |

**3 가지 확장 법칙 동시 적용**: 이 3 지점은 §7.17 의 3 가지 확장(§7.27 바텀시트 · §7.87-h 유한집합 · §7.89 빈 상태 3축)이 한 배치에서 모두 관찰된 **법칙 포화 샘플**.

#### 7.93-b §7.30 예외 16 지점 — 유형별 집계

| 유형 | 건수 | 파일:라인 |
|------|------|-----------|
| #2 개체명 (사용자·학생·작품명) | 6 | profile_visibility_widgets.dart:593(profile.name)/597(비공개 = 개체명 대체), profile_tab.dart:316(name), profile_preview_screen.dart:254(profile.name), repertoire_management_widgets.dart:650(piece.title), payment_detail_sheet.dart:60(studentName) |
| #3 stat 값 (금액·%·기간) | 7 | profile_tab.dart:602, outstanding_payments_screen.dart:224(formatWonWithComma), extended_profile_widgets.dart:77(`'$percentage%'`), lesson_time_settings_widgets.dart:549(LessonDurations.format), extended_profile_dialogs.dart:33(`'$years년'`)/177(FeeRange.formatted), payment_card.dart:128(formattedAmount) |
| #4 date (동적 년) | 1 | payment_management_screen.dart:244(`'$selectedYear년'`) — "년" 단독 접미사, 정적 명사 결합 없음 |
| #6 initial (아바타 첫 글자) | 2 | profile_tab.dart:306, payment_detail_sheet.dart:52 |

#### 7.93 검증

- `flutter analyze lib/features/profile/` → **No issues found** (11.1s)
- 잔재 grep 재실행: `AppTypography.heading*` 16건 = §7.30 예외 16건 일치. §7.17 후보 0건 확인.
- NotebookTypography import: outstanding_payments_screen.dart 기존 존재, add_payment_sheet.dart + payment_summary_section.dart 2 파일 신규 추가.

#### 7.93 관찰

**예상 전환율(40%) 대비 실측(15.8%) 하회**: §7.91-b 로드맵은 profile/ 을 "설정 섹션 §7.17 + 결제 stat §7.30 혼합" 으로 예상했으나, 실제 남은 19 지점은 **§7.17 섹션 헤더 대부분이 이전 세션에서 변환 완료 상태** 였고 잔재는 주로 §7.30 유형에 집중. 새로 발견된 §7.17 승격 3건은 모두 **"이전 세션이 놓친 3 가지 확장 법칙"** — 바텀시트(§7.27) · 유한집합(§7.87-h) · 빈 상태(§7.89).

**"2차 감사" 의 새로운 의미**: profile/ 같은 이미 감사된 도메인의 2차 감사는 **"남은 것은 §7.30"** 이 기본 가설이어야 함. 새 §7.17 발견은 예외(빈 상태·바텀시트 신규 추가) 수준. §7.91-b 로드맵의 "2차" 배치 중 subscription/ · schedule/ · students/ · lessons/ 는 동일한 법칙으로 **전환율 0~20%** 수렴 예상 재확인.

**profile/ 의 3대 §7.30 축 (개체명·stat·날짜)**: parent_home §7.92 와 동일한 구성 — "누구(6) + 얼마(7) + 언제(1) + 이니셜(2)" = 16. 학부모 뷰와 선생님 프로필이 공통적으로 **"사람 정보 + 수치 + 시점"** 조합으로 구성된다는 도메인 패턴이 2 배치로 확증.

**결제 모듈의 §7.30 집중**: 16 예외 중 9건(56%)이 `payment_management/` · `outstanding_payments/` · `payment_detail/` 하위. 금액·이니셜·학생명의 삼중 표시가 결제 UI 의 필수 구성요소. **결제 UI 는 §7.30 전형** 이라는 스타일 가이드 시그널.

**은유**: §7.93 은 **"교사 사무실의 명부와 영수증 더미"** — 표지(이미 Playfair)만 두고 내부 기록(명부의 이름, 영수증의 금액, 일자, 잔고)은 모두 명조체. 월별 수강료 현황판 하나(§7.87-h) · 결제 추가 시트의 표지(§7.27) · 미수금 '비어 있음' 문구(§7.89) 3 개만 추가로 필기체 승격. 나머지 16 지점은 **"책상 위 서류의 본문"** — 빠르게 스캔해야 하는 정보이므로 명조체 유지. 선생님 감사 2 번째 배치 완료, `15.8%` 전환율로 **"2차 감사 = 3 가지 확장 법칙으로 10~20% 추가 발견"** 법칙 확립.

---

### 7.94 Batch 선생님.H — lessons/ 2차 §7.30 수렴 6/6 (100%) 확정

**기간**: 2026-04-23
**성격**: **0 지점 BLOCK + 6 지점 §7.30 예외 문서화**. 코드 변경 없음, 문서화만.
**배경**: §7.91-b 로드맵 Batch 선생님.H. lessons/ 2차 감사 — 이전 세션에서 레슨 헤더·섹션 헤드라인 대부분 Playfair 전환 완료 상태. 남은 잔재는 **이니셜·stat·인라인 기호** 로 §7.30 예외에 수렴. 전수 감사 결과 총 **6 지점** = 전환 **0**(0%) + 예외 **6**(100%). **예상(0~20%) 하한 일치**.

#### 7.94-a §7.17 승격 0 지점

추가로 전환할 섹션 헤더 없음. `lessons/` 의 모든 Playfair 후보(레슨 상세 헤더 · 노트 섹션 · 세션 진행 바) 는 이전 배치에서 처리 완료.

#### 7.94-b §7.30 예외 6 지점 — 유형별 집계

| 유형 | 건수 | 파일:라인 | 내용 |
|------|------|-----------|------|
| #6 이니셜 (아바타 첫 글자) | 3 | widgets/lesson_detail/lesson_header_card.dart:47, widgets/lesson_form/edit_lesson_widgets.dart:51, widgets/lesson_form/lesson_student_selector.dart:42 | `studentName[0]` / `student.name[0]` — 선생님·학생 아바타 |
| #3 stat 값 (비율·기간) | 2 | screens/teacher_attendance_screen.dart:120, widgets/lesson_detail/lesson_notes_widgets.dart:504 | `${rate}%` 출석률, `_formatDuration(recordingSeconds)` 녹음 시간 |
| #2 정적 기호 (헤더 아닌 시각 무게) | 1 | widgets/add_youtube_resource_sheet.dart:263 | `Text('~', ...)` — 시작/종료 시간 입력 사이의 범위 구분자. 섹션 헤더 의미 없고 입력 필드와 시각적 무게 매칭 용도 |

#### 7.94 검증

- `flutter analyze lib/features/lessons/` → **No issues found**
- 잔재 grep 재실행: `AppTypography.heading*` 6건 = §7.30 예외 6건 일치. §7.17 후보 0건 확인.
- 코드 편집 없음. README 전용 배치.

#### 7.94 관찰

**"2차 감사 법칙" 5번째 확증**: §7.93 에서 확립한 **"이미 감사된 도메인의 2차 감사는 전환율 0~20% 수렴"** 법칙이 lessons/ 에서 **0%** 로 하한 일치. §7.88-a gamification(0%) · §7.90-b settings(0%) · §7.90-c home(0%) · §7.90-e notifications(0%) 에 이은 다섯 번째 0% 샘플. lessons/ 는 레슨 도메인 특성상 **"학생 이름 + 출석률 + 녹음 시간"** 3축이 지배적이라 §7.30 포화 상태에 먼저 도달.

**§7.91-b 로드맵 예측 정확도**: 로드맵에서 lessons/ 2차를 "6건 / 0~20%" 로 지정 → 실측 **6건 / 0%**. 하한 정확히 일치. §7.84 의 10-패턴 자동 판정으로 파일 Read 없이도 **이니셜·stat 혼합 도메인** 을 식별 가능함을 다시 증명.

**§7.30 "정적 기호의 시각 무게" 변형 명시화**: add_youtube_resource_sheet:263 의 `Text('~', style: headingSmall)` 은 기존 §7.30 10-패턴(#1~#10) 중 어디에도 완전히 일치하지 않는 경계 케이스 — **"의미상 섹션 헤더 아님 + 시각적으로는 큰 글꼴 필요"** 라는 변형. 향후 §7.30 확장 시 **#11 "인라인 기호의 시각 무게 매칭"** 으로 체계화 가능. 단, 재발 빈도가 낮으면(lessons/ 1건이 유일) 정식 패턴화는 보류.

**은유**: §7.94 는 **"교실 문패 뒤에 놓인 학생 명찰과 출석 기록표"** — 문패(이미 Playfair)는 건드릴 것 없고, 명찰(이니셜 3건) · 출석표(stat 2건) · 영상 시간 구분자(기호 1건) 는 모두 명조체로 유지. 선생님 감사 8 배치 중 **"2차 감사의 순수 형태"** 를 가장 깨끗하게 보여주는 샘플 — **필기체 승격 없이 명조체 확정만으로 종결**. 1차 감사에서 헤더는 이미 필기체로 올라갔고, 2차 감사는 **"남은 것이 모두 데이터임"** 을 문서화하는 단계임을 체계화.

---

### 7.95 Batch 선생님.G — students/ 2차 §7.30 수렴 6/6 (100%) 확정

**기간**: 2026-04-23
**성격**: **0 지점 BLOCK + 6 지점 §7.30 예외 문서화**. 코드 변경 없음, 문서화만.
**배경**: §7.91-b 로드맵 Batch 선생님.G. students/ 2차 감사 — §7.86 커밋에서 학생 form §7.50 + §7.17 스윕 완료 상태. 남은 잔재는 **학생명·초대코드·stat·레슨 일자** 로 §7.30 예외에 수렴. 전수 감사 결과 총 **6 지점** = 전환 **0**(0%) + 예외 **6**(100%).

#### 7.95-a §7.17 승격 0 지점

추가로 전환할 섹션 헤더 없음. `students/` 의 Playfair 후보(탭 헤더 · 학생 상세 섹션 헤드라인) 는 §7.86 이전 배치에서 처리 완료.

#### 7.95-b §7.30 예외 6 지점 — 유형별 집계

| 유형 | 건수 | 파일:라인 | 내용 |
|------|------|-----------|------|
| #2 개체명 (학생명) | 1 | screens/student_detail_screen.dart:277 | `student.name` — 학생 상세 히어로 섹션 이름 |
| #10 코드 (초대코드 자리수) | 1 | screens/student_detail_screen.dart:767 | `digit` — `inviteCode.split('')` 6자리 숫자 개별 렌더 |
| #3 stat 값 (선택 개수·연습·통계) | 3 | screens/students_tab.dart:155, widgets/student_detail/student_practice_tab.dart:142, widgets/student_detail/student_stats_cards.dart:72 | `${_selectedStudentIds.length}명 선택됨`, 연습 stat `value`, 학생 stat 카드 `value` |
| #4 date (레슨 일자) | 1 | widgets/student_detail/student_lesson_card.dart:65 | `${lesson.date.day}` — 레슨 카드 일자 숫자 |

#### 7.95 검증

- `flutter analyze lib/features/students/` → **No issues found**
- 잔재 grep 재실행: `AppTypography.heading*` 6건 = §7.30 예외 6건 일치. §7.17 후보 0건 확인.
- 코드 편집 없음. README 전용 배치.

#### 7.95 관찰

**"2차 감사 법칙" 6번째 확증**: §7.93~§7.94 에서 확립한 **"이미 감사된 도메인의 2차 감사 = 0~20%"** 법칙이 students/ 에서 **0%** 로 하한 일치. lessons/ 에 이은 **두 번째 연속 0% 샘플**. §7.86 §7.50 스윕이 §7.17 후보를 이미 모두 흡수했음을 간접 확인.

**#10 초대코드 신규 등장**: students/ 배치에서 처음으로 **§7.30 #10 "코드"** 패턴이 실제 코드에 확인됨(`digit` per-character render). 이는 §7.84 10-패턴 자동 판정에서 #10 을 별도 축으로 둔 근거를 실증 — **"개체명·stat·날짜·이니셜"** 4축에 이어 **"코드"** 가 5축으로 독립.

**§7.91-b 로드맵 예측 정확도 (2연속)**: 로드맵에서 students/ 2차를 "6건 / 0~20%" 로 지정 → 실측 **6건 / 0%**. lessons/ 에 이은 두 번째 완벽 일치. §7.84 10-패턴 자동 판정의 **"파일 Read 없이도 이니셜·stat·코드 혼합 도메인은 0% 수렴"** 가설이 안정화.

**students/ 의 5축 분포 (개체명·코드·stat·날짜)**: 6 예외 중 §7.30 축이 **4종**(#2 개체명·#10 코드·#3 stat·#4 date) 분산 분포 — lessons/ 의 3축(#6 이니셜·#3 stat·기호) 대비 **축 다양성이 더 넓음**. 이는 students/ 가 **"학생 + 레슨 + 초대 + 연습"** 이라는 4 도메인의 교차점에 위치한 도메인 특성에서 기인.

**은유**: §7.95 는 **"학생 프로필 카드 6장"** — 이름표(개체명), 초대장의 인증번호(코드), 출석 카운터(stat), 달력 일자(date) 네 가지가 한 카드 안에 다 들어있는 구조. 카드 뒷면의 표제(§7.17)는 이미 필기체로 정리되었고, 앞면의 데이터(§7.30)는 전부 명조체 유지. 선생님 감사 8 배치 중 **"작은 배치 2연속 0% 수렴"** 패턴이 확립 — 남은 D(schedule 30) · E(subscription 19) · F(practice 28) 대형 배치에서도 동일 법칙이 성립하는지가 다음 검증 포인트.

---

### 7.96 Batch 선생님.D — schedule/ 2차 §7.17 11 지점 + §7.30 예외 19 지점 확정

**기간**: 2026-04-23
**성격**: **11 지점 §7.17 Playfair 승격 + 19 지점 §7.30 예외 문서화**.
**배경**: §7.91-b 로드맵 Batch 선생님.D. schedule/ 2차 감사 — §7.87-a~e 이후 잔재 재검증. 전수 감사 결과 총 **30 지점** = 전환 **11**(36.67%) + 예외 **19**(63.33%). **예상(10~20%) 상회** — 바텀시트 9건이 전환율을 견인.

#### 7.96-a §7.17 승격 11 지점

| 분류 | 건수 | 파일:라인 |
|------|------|-----------|
| §7.27 바텀시트 헤더 | 9 | decline_bottom_sheet.dart:85, payment_guide_bottom_sheet.dart:92, proposal_bottom_sheet.dart:110, schedule_change_response_bottom_sheet.dart:108, student_proposal_bottom_sheet.dart:87, schedule_edit_bottom_sheet.dart:86 (`isEditing ? '스케줄 수정' : '스케줄 추가'` — 2원 유한집합 §7.87-h), lesson_settings_bottom_sheet.dart:66, availability/guest_student_input_dialog.dart:98, screens/time_exception_screen.dart:399 |
| §7.89 빈 상태 3축 통과 | 1 | availability/no_subscription_view.dart:62 (`'수강권이 필요합니다'` — Center + MainAxisAlignment.center + textAlign: center) |
| §7.89 성공 상태 3축 통과 | 1 | screens/request_completion_screen.dart:91 (`AppStrings.requestCompleteHeader` — 5단계 가이드 상단 성공 헤드라인) |

#### 7.96-b §7.30 예외 19 지점 — 유형별 집계

| 유형 | 건수 | 파일:라인 | 내용 |
|------|------|-----------|------|
| #6 이니셜 (학생/선생님 아바타) | 7 | widgets/teacher_approval_card.dart:164, :412, widgets/booking_card.dart:70, widgets/regular_lesson_widgets.dart:59, widgets/request_profile_card.dart:120, widgets/approval_bottom_sheet.dart:167, widgets/unified_approval_bottom_sheet.dart:125 | `name[0]` / `studentName[0]` — CircleAvatar 이니셜 문자 |
| #2 개체명 (학생명·선생님명·그룹레슨명·상태 라벨) | 5 | widgets/approval_bottom_sheet.dart:177, widgets/unified_approval_bottom_sheet.dart:135, screens/unified_lesson_request_screen.dart:170, screens/group_class_detail_screen.dart:153, :372 | `booking.studentName`, `widget.params.teacherName`, `widget.groupClass.name`, `booking.statusText` |
| #4 날짜·시간 포매터 | 4 | screens/schedule_tab.dart:300, :644, widgets/availability/availability_booking_preview.dart:68, screens/booking_cancel_screen.dart:143 | `formatDateMDWithDayLong(selectedDate)`, `lesson.startTime`, `selectedSlot.formattedTimeRange`, `_formatBookingDate()` |
| #3 stat (수강료·출석수·정원) | 3 | widgets/regular_lesson_widgets.dart:672, screens/group_class_attendance_screen.dart:171, screens/group_class_detail_screen.dart:324 | `formatFee(monthlyFee)`, `${_getAttendedCount()}/${_attendanceState.length}`, `$confirmedCount / ${widget.schedule.maxCapacity}명` |

#### 7.96 검증

- `flutter analyze lib/features/schedule/` → **No issues found** (ran in 7.4s)
- 잔재 grep 재실행: `AppTypography.heading*` 19건 = §7.30 예외 19건 일치. §7.17 후보 0건 잔존 확인.
- 11 파일에 `NotebookTypography` import 추가, 헤더 텍스트 스타일 교체. 기능 동작 불변.

#### 7.96 관찰

**"2차 감사 법칙" 하한 돌파 첫 사례**: §7.93~§7.95 가 0~15.8% 범위에 수렴했으나 schedule/ 는 **36.67%** 로 상한을 돌파. 원인 분석: schedule/ 는 **"선생님↔학생 협상 UX"** 특성상 **바텀시트가 9개 집중** — decline·payment_guide·proposal·schedule_change_response·student_proposal·schedule_edit·lesson_settings·guest_student_input·time_exception. 이전 배치(profile 1건·lessons 0건·students 0건)와 달리 §7.27 후보 밀도가 구조적으로 높음. **"도메인 내 바텀시트 밀도가 2차 감사 전환율의 결정 인자"** 가설 확립.

**§7.91-b 예측 정확도 편차**: 로드맵이 schedule/ 를 "10~20%" 로 예상한 것은 잔재 총량(~24건) 추정만으로 평균 전환율을 적용한 결과. 실측 30건 중 바텀시트 특수성을 반영하지 못한 예측. 향후 E(subscription) · F(practice) 배치에서도 바텀시트 밀도를 사전 카운트하여 전환율 추정에 반영 필요.

**7개 이니셜의 재확인**: #6 이니셜 축이 7건으로 §7.30 예외 중 최다. `CircleAvatar > Text(name[0])` 패턴이 schedule/ 전반의 접근 승인·예약·카드에 반복 — §7.84 10-패턴 자동 판정의 **"이니셜은 명조체 유지"** 법칙이 재확증.

**3축 구성의 동형성**: §7.30 예외 19건의 분포가 #6 이니셜(7) + #2 개체명(5) + #4 날짜·시간(4) + #3 stat(3) 으로 **4축 분포**. parent_home §7.92 (개체명·이니셜·stat) · profile §7.93 (개체명·stat·날짜·이니셜) · schedule §7.96 (이니셜·개체명·시간·stat) — 선생님 도메인 공통적으로 **"사람(#2/#6) + 숫자(#3) + 시점(#4)"** 3축 구조가 관찰되며, 도메인별 비중만 상이.

**§7.89 3축 판정의 경계 사례**: request_completion_screen.dart:91 은 Scaffold > SingleChildScrollView > Column(기본 center crossAxis) > _buildSuccessHeader(Column(기본 center)) 의 중첩 구조. 명시적 `CrossAxisAlignment.center` 선언이 없지만 Column 기본값 center 가 적용되어 3축 중 "center align" 을 통과. Column 기본값 활용한 센터 정렬 시에도 §7.89 승격 기준에 해당한다는 판정 기록.

**은유**: §7.96 은 **"교사실의 상담 부스 9 개 + 복도 벽 1 개 + 완료 도장 1 개"** — 바텀시트 9 개의 헤더(§7.27)는 상담 부스의 명패로, "수강권이 필요합니다" 안내판(§7.89)은 복도 벽 헤드라인으로, 신청 완료 헤더(§7.89)는 축하 도장으로 모두 필기체(Playfair) 승격. 반면 부스 안에서 오고 가는 이름·시간·금액·인원(§7.30)은 명조체(Gothic) 유지. 선생님 감사 8 배치 중 **"바텀시트 밀집형 도메인의 첫 표본"** — 이후 subscription/ practice/ 배치에서 바텀시트 밀도에 따른 전환율 편차 검증 대상.

---

### §7.97 — Batch 선생님.E: subscription/ 잔재 2차 전수 감사 (§7.91-b 로드맵 · 2026-04-23)

§7.91-b 로드맵의 **Batch 선생님.E** (subscription/ 2차 감사) 실행. §7.93 (profile 2차) · §7.94 (lessons 2차) · §7.95 (students 2차) · §7.96 (schedule 2차) 에 이어 다섯 번째 2차 감사 배치. 스펙 §7.89 빈/에러 상태 헤드라인 3축 규칙 + §7.27 바텀시트 헤더 규칙을 재확인. `grep -rn "AppTypography\.heading" frontend/lib/features/subscription/` 로 **19 건** 탐지 → **9 건 §7.17 승격** + **10 건 §7.30 예외 유지** → 전환율 **47.37%**.

**§7.96 법칙 재확증**: schedule/ (바텀시트 9개 집중 → 36.67%) 에 이어 subscription/ 도 **바텀시트 헤더 1 개 + §7.89 빈/에러/대기 상태 헤드라인 8 개** 로 전환율 47.37% 기록 — "2차 감사 법칙 하한(10~20%)" 을 재차 돌파. 1차 감사 법칙 "바텀시트·헤드라인 집중 도메인 > 50%" 수렴 확인.

**승격 대상 (§7.17 — 9 지점)**:

1. `subscription_detail_screen.dart:83` — `AppStrings.subscriptionNotFound` → `NotebookTypography.sectionTitle` (§7.89 빈 상태 3축)
2. `subscription_detail_screen.dart:107` — `AppStrings.errorOccurred` → `NotebookTypography.sectionTitle` (§7.89 에러 상태 3축)
3. `issue_form_membership_widgets.dart:223` — `'등록된 레슨이 없습니다'` → `NotebookTypography.sectionTitle` (§7.89 빈 상태 3축)
4. `issue_form_membership_widgets.dart:258` — `'오류가 발생했습니다'` → `NotebookTypography.sectionTitle` (§7.89 에러 상태 3축)
5. `proposal_card_widgets.dart:573` — `'입금 확인 대기중'` → `NotebookTypography.sectionTitle.copyWith(fontWeight: w600)` (§7.89 변형 — 대기 상태 헤드라인)
6. `subscription_list_screen.dart:307` — `'등록된 수강권이 없습니다'` → `NotebookTypography.sectionTitle` (§7.89 빈 상태 3축)
7. `subscription_list_screen.dart:336` — `'등록된 레슨이 없습니다'` → `NotebookTypography.sectionTitle` (§7.89 빈 상태 3축)
8. `subscription_list_screen.dart:371` — `'오류가 발생했습니다'` → `NotebookTypography.sectionTitle` (§7.89 에러 상태 3축)
9. `subscription_template_list_screen.dart:636` — `isEditing ? '수강권 수정' : '수강권 수강권 추가'` → `NotebookTypography.sectionTitle` (§7.27 바텀시트 헤더 + §7.87-h 2원 유한집합)

**§7.30 예외 유지 (10 지점 — 동적 값)**:

- **#2 개체명 (4)**: `proposal_card_widgets.dart:120` `template.name` · `template_choice_card.dart:72` `template.name` · `subscription_template_list_screen.dart:286` `template.name` · `student_proposal_accept_screen.dart:96` `'$teacherName 선생님'`
- **#3 stat (6)**: `selectable_template_card.dart:147` `template.formattedPrice` · `proposal_confirm_screen.dart:253` `_formatPrice(price)` · `proposal_card_widgets.dart:329` `_formatPrice(discountedPrice)` · `subscription_list_screen.dart:462` `'$count'` · `proposal_detail_screen.dart:444` `template.formattedPrice` · `renewal_detail_screen.dart:337` `template.formattedPrice`

**관찰 1 — "바텀시트 밀도 가설" 정량 비교**: schedule/ (바텀시트 9 / §7.30 19) = 32.14% 바텀시트 비중, 전환율 36.67%. subscription/ (바텀시트 1 / §7.30 10) = 9.09% 바텀시트 비중, 전환율 47.37%. 바텀시트 수치 자체보다 **"§7.89 빈/에러/대기 상태 헤드라인의 절대 밀도"** 가 더 강한 전환율 결정 인자. subscription/ 는 수강권이라는 **"상태가 명확히 분기되는 도메인"** (없음·로딩·에러·대기·활성) 특성상 상태 헤드라인이 8 건 집중 → 전환율 47.37%.

**관찰 2 — "§7.89 변형" 케이스 확립**: `proposal_card_widgets.dart:573 '입금 확인 대기중'` 은 `Container > Column > (Icon + Text)` 구조로 `MainAxisAlignment.center` 명시 없이 컨테이너 내부 정렬만 있음. 그러나 Column 기본 `crossAxis` 가 center 이고 Icon + Text 가 수직 중앙 스택 → **"대기 상태 헤드라인 3축 유사 통과"** 로 판정하여 승격. `request_completion_screen.dart:91` (§7.96) 의 "성공 상태 3축 경계 사례" 에 이어 **"3축 경계 사례 = 승격"** 판례 재확립.

**관찰 3 — AppStrings 상수 §7.17 승격의 2 건째**: `subscription_detail_screen.dart:83·107` 이 `AppStrings.subscriptionNotFound` · `AppStrings.errorOccurred` — enum/상수 2원 유한집합으로 §7.87-h 규칙을 직접 적용한 사례. parent_home §7.92 · 선생님 프로필 §7.93 의 이니셜·AppStrings 승격 정책 연장선.

**관찰 4 — 스펙 갭 발견 (시각 오타)**: `subscription_template_list_screen.dart:634` 원본이 `'수강권 수강권 추가'` (중복 단어) — [golden-principles.md §12 Surgical Changes] 규칙에 따라 **이번 감사 범위 외로 판정**. 별도 버그픽스 커밋으로 이관 필요. 감사는 **타이포그래피만 승격**, 문구 수정은 범위 외.

**은유**: §7.97 은 **"교사실의 수강권 카운터 + 안내판 8 개 + 창고 문패 1 개"** — 바텀시트 헤더(§7.27, 문패 1)는 수강권 양식 창고의 명패로, 빈·에러·대기 상태 헤드라인 8 개(§7.89, 안내판)는 카운터 옆 안내문으로 모두 필기체(Playfair) 승격. 반면 카운터 위에서 오고 가는 금액·횟수·템플릿명·선생님명(§7.30)은 명조체(Gothic) 유지. 선생님 감사 8 배치 중 **"상태 헤드라인 밀집형 도메인의 첫 표본"** — 수강권 라이프사이클(없음→대기→활성→소진→만료) 이 §7.89 상태 헤드라인의 자연스러운 밀집 구조를 형성.

---

### 7.98 Batch 선생님.F — practice/ 2차 §7.17 5 지점 + §7.30 예외 23 지점 확정

**기간**: 2026-04-23
**성격**: **5 지점 Playfair 승격 + 23 지점 §7.30 예외 문서화**. 선생님 감사 로드맵(§7.91-b)의 **마지막 배치**.
**배경**: §7.91-b 로드맵 Batch 선생님.F. practice/ 2차 감사 — 연습/메트로놈/튜너/녹음/섹션/레퍼토리/목표 7 서브모듈 혼재 도메인. 전수 감사 결과 총 **28 지점** = 전환 **5**(17.86%) + 예외 **23**(82.14%). **예상(0~20%) 상한 근접**.

#### 7.98-a §7.17 승격 5 지점

| 파일 | 라인 | 전환 대상 | 근거 |
|------|------|-----------|------|
| widgets/recording_comparison_sheet.dart | 210 | `'녹음 비교'` | §7.27 바텀시트 헤더 (Icon + Title 한 줄 구성) |
| widgets/goal/goal_achieved_dialog.dart | 68 | `'이번 주 목표 달성!' / '오늘 목표 달성!'` | §7.89 3축: Column center + Emoji + 단일 헤드라인. §7.87-h 2원 유한집합 + 정적 명사 "목표 달성!" |
| widgets/metronome/subdivision_picker.dart | 59 | `'서브디비전 선택'` | §7.27 바텀시트 헤더 (BottomSheetHandle 아래) |
| widgets/metronome/time_signature_picker.dart | 50 | `'박자표 선택'` | §7.27 바텀시트 헤더 (BottomSheetHandle 아래) |
| screens/section_picker_screen.dart | 223 | `'섹션이 없습니다'` | §7.89 빈 상태 3축: Center + Icon + 단일 헤드라인 + 보조 설명 |

**패턴 구성**: §7.27 바텀시트 3건 + §7.89 빈/다이얼로그 2건. §7.97 subscription/ 의 "8 §7.89 + 1 §7.27" 역전 비율 — practice/ 는 **도구(메트로놈/튜너)의 설정 시트 집중 도메인**이므로 §7.27 바텀시트가 더 많음.

#### 7.98-b §7.30 예외 23 지점 — 유형별 집계

| 유형 | 건수 | 대표 파일:라인 |
|------|------|-----------|
| #2 개체명 (레퍼토리명·곡명) | 3 | repertoire_detail_screen.dart:111(`repertoire.name`), edit_section_screen.dart:302·add_section_screen.dart:320(`_repertoire!.name`), section_info_card.dart:79(`section.pieceName`) |
| #3 stat (BPM·시간·횟수·% ·등급) | 16 | metronome_controller_bar.dart:151·176, metronome_panel.dart:464, circular_tuner_indicator.dart:367, pitch_analysis_card.dart:64, history_summary_card.dart:82, practice_stats_card.dart:80, stats_summary_card.dart:131, practice_stats_editor.dart:343·364(TextField stat input), recording_control.dart:241, range_picker_button.dart:52, range_picker_sheet.dart:112, repertoire_detail_screen.dart:221, quick_add_screen.dart:439(`'섹션 ${index+1}'` 오디널) |
| #4 date (월 그룹 라벨) | 1 | month_group_header.dart:43(`monthGroup.label` — "2026년 3월" 형) |
| #2 정적 기호 (범위 구분자) | 1 | add_section_widgets.dart:102(`'~'`) |
| #3 stat (TabBar 라벨 스타일) | 2 | practice_tools_modal.dart:160(labelStyle)·163(unselectedLabelStyle) — Tabs("메트로놈"/"튜너") 스타일, 헤드라인 아닌 탭 라벨 |

#### 7.98 검증

- `flutter analyze lib/features/practice/` → **No issues found** (11.8s)
- 잔재 grep 재실행: `AppTypography.heading*` 23건 = §7.30 예외 23건 일치.
- NotebookTypography import 4 파일 신규 추가 (recording_comparison_sheet · goal_achieved_dialog · subdivision_picker · time_signature_picker). section_picker_screen 기존 존재.

#### 7.98 관찰

**"2차 감사 법칙" 상한 샘플 (17.86%)**: §7.93 profile/ 15.8% · §7.97 subscription/ 47.37% 사이. 2차 감사에서 §7.17 발견율이 15~20% 범위일 경우 **"도구 설정 시트 밀집 도메인"** 의 전형. §7.97 의 50% 근접은 "상태 헤드라인 밀집" 이라는 subscription 도메인 특수성이었음을 상대 비교로 재확인.

**practice/ 의 7 서브모듈 구조와 §7.17 분포**: 5 승격 중 **메트로놈 2(subdivision·time_signature picker) + 녹음 1(comparison sheet) + 목표 1(achieved dialog) + 섹션 1(empty picker)**. 튜너·레퍼토리·통계·스탯에디터 4 서브모듈은 §7.17 승격 0건 — **"도구 설정 UI 집중"** 시그널. 연습/튜너 본연의 실시간 피드백 UI 는 §7.30 stat 집중.

**§7.89 빈 상태 vs 다이얼로그의 동등 처리**: section_picker(빈 상태) 와 goal_achieved(다이얼로그) 모두 §7.89 3축(Center + Icon/Emoji + 단일 헤드라인) 로 통합. §7.89 는 원래 빈/에러/대기 상태에서 출발했으나 **"다이얼로그도 동일 3축이면 승격"** 법칙이 재확증 — §7.97 `'수강권 수정/추가'` AppStrings 확장과 함께 §7.89 의 **"다이얼로그 3축 확장"** 이 규범화.

**"섹션 ${i+1}" §7.30 유지 판정**: 동적 인덱스 + "섹션" 정적 명사 조합이지만, 오디널 인덱스(1-N)는 **"데이터 크기 의존 유한집합"** 으로 payment_summary `${month}월 수강료 현황` 의 **"보편 유한집합(1-12) + 정적 명사"** 과 구분. §7.87-h 는 **"보편 유한집합"** 에 한정 적용 — 오디널 인덱스는 #3 stat 로 유지. 판례 확립.

**TabBar 라벨 §7.30 유지 판정**: practice_tools_modal TabBar 의 labelStyle 이 `AppTypography.headingMedium` 을 상속받은 이유는 **"탭 텍스트 시각 무게 매칭"** 용도. Tabs 자체는 정적(메트로놈/튜너)이지만 **"탭 라벨은 섹션 헤더가 아님"** 이라는 UX 패턴 원칙으로 §7.30 유지. lessons/ `'~'` 기호(§7.94) 와 동일한 "시각 무게 매칭 §7.30 변형" 계열.

**은유**: §7.98 은 **"음악실의 악기 보관함 5 개 + 연주 중 실시간 계기판 23 개"** — 서브디비전 선택 함(§7.27), 박자표 선택 함(§7.27), 녹음 비교 함(§7.27), 목표 달성 트로피(§7.89), 빈 섹션 안내판(§7.89) 5 문패는 필기체(Playfair)로, BPM 계기판·센트 편차계·등급표·시간 스톱워치·녹음 파형 23 개 데이터 출력부(§7.30)는 명조체(Gothic) 유지. 선생님 감사 8 배치 중 **"도구 설정 시트 밀집형"** 을 대표 — subscription/ 의 "상태 헤드라인 밀집형" 과 대비되는 두 번째 도메인 아키타입 확립.

**선생님 감사 종결**: §7.91-b 로드맵의 8 배치(A analytics · B parent_home · C profile · D schedule · E subscription · F practice · G students · H lessons) 전부 완료. 집계: **§7.17 승격 57 지점 + §7.30 예외 156 지점 = 213 감사 지점**. 선생님 화면 감사 종결. 남은 잔재 `AppTypography.heading*` 34건은 비선생님 배치 도메인(invite·auth·student_home·gamification·settings·search·home) — §7.99 에서 전수 감사 진행.

---

### 7.99 비선생님 도메인 전수 감사 — §7.98 "전부 §7.30" 주장 반증 + 4 §7.17 추가 승격

**기간**: 2026-04-23
**성격**: **4 지점 Playfair 승격 + 30 지점 §7.30 예외 문서화**. §7.98 의 "남은 34 잔재는 전부 §7.30" 주장 **반증**. 7 도메인(invite·auth·student_home·gamification·settings·search·home) 34 지점 전수 분류.
**배경**: §7.91-b 선생님 로드맵 종결 후 남은 34 잔재의 전수 감사. §7.98 결론이 practice/ 내부 추세를 전체로 외삽한 **편향 결론** 이었음을 확인. 34 지점 = 전환 **4**(11.76%) + 예외 **30**(88.24%).

#### 7.99-a §7.17 승격 4 지점

| 파일 | 라인 | 전환 대상 | 근거 |
|------|------|-----------|------|
| invite/my_connections_screen.dart | 105 | `'아직 연결된 학생/선생님이 없습니다'` | §7.89 3축(Center + Icon + 단일 헤드라인) + §7.87-h 2원 유한집합(teacher/parent·student) |
| invite/invite_history_screen.dart | 81 | `'생성한 초대가 없습니다'` | §7.89 빈 상태 3축 + 정적 명사 단일 헤드라인 |
| gamification/badge_award_sheet.dart | 126 | `'뱃지 수여'` (`\uBDF3\uC9C0 \uC218\uC5EC`) | §7.27 바텀시트 헤더 (Icon + Title Row 구성) + 정적 명사 |
| gamification/level_up_dialog.dart | 84 | `'레벨 업!'` | §7.89 변형 다이얼로그 헤드라인 + 정적 명사 |

**패턴 구성**: §7.89 3건(빈 상태 2 + 다이얼로그 1) + §7.27 바텀시트 1건. §7.98 practice/ 와 동일한 "빈/다이얼로그 + 바텀시트" 혼합 — **§7.87-h 2원 유한집합 + §7.89 3축** 이 도메인 경계를 가로질러 재확증.

#### 7.99-b §7.30 예외 30 지점 — 유형별 집계

| 유형 | 건수 | 대표 파일:라인 |
|------|------|-----------|
| #2 개체명 (이름·타이틀) | 7 | my_connections_screen.dart:315(`otherName`), student_profile_tab.dart:191(`name`), badge_collection_screen.dart:103(`data.levelTitle`), academy_detail_screen.dart:145(`academy.name`), teacher_detail_screen.dart:158(`profile.name ?? '익명 선생님'`), 외 2건 |
| #3 stat (숫자·퍼센트·레벨·점수) | 12 | all_recordings_screen.dart:263(`'$count'`), backup_widgets.dart:127(`value`), student_profile_tab.dart:270(stat value), student_subscription_summary.dart:269(`'${usedLessons}/$_totalSessions'`), level_up_dialog.dart:72(`'Lv.$newLevel'`), badge_collection_screen.dart:94(`'Lv.${data.level}'`), assignment_dashboard_screen.dart:185(`'${(rate*100).round()}%'`)·268(`value`), 외 4건 |
| #4 date/time | 5 | practice_reminder_sheet.dart:143(`settings.formattedTime`), student_practice_tab.dart:133·178·191(`_formatDate`), student_lessons_tab.dart:228(`formatDateMDWithDayLong`), next_lesson_card.dart:147(`dDayText`) |
| #6 이니셜 (CircleAvatar) | 4 | pending_requests_screen.dart:237(`requesterName[0]`), my_connections_screen.dart:309·553(`otherName[0]`·`name[0]`), my_teachers_screen.dart:509(`teacher.initial`) |
| #10 코드·이모지 (입력·출력) | 4 | invite_screen.dart:239(`invite.inviteCode`), code_input_screen.dart:221(TextField digit), student_invite_code_screen.dart:96·parent_invite_code_screen.dart:97(TextFormField 코드 입력), student_profile_tab.dart:607(code digit), weekly_ranking_card.dart:87(`_tierEmoji`) |

#### 7.99 검증

- `flutter analyze lib/features/invite/.../my_connections_screen.dart lib/features/invite/.../invite_history_screen.dart lib/features/gamification/.../badge_award_sheet.dart lib/features/gamification/.../level_up_dialog.dart` → **No issues found** (4.5s)
- 잔재 grep 재실행: `AppTypography.heading*` 비선생님 도메인 30건 = §7.30 예외 30건 일치.
- NotebookTypography import 3 파일 신규 추가(invite_history_screen · badge_award_sheet · level_up_dialog). my_connections_screen 기존 존재.

#### 7.99 관찰

**§7.98 편향 결론 반증**: §7.98 의 "남은 34 잔재는 전부 §7.30 확정" 주장이 **부분 표본(practice/ 내부)을 전체로 외삽한 추세 편향**이었음. 실제 비선생님 7 도메인에 4 §7.17 후보 생존. **교훈: 배치 경계 바깥의 잔재는 전수 감사 전까지 분류 주장 금지.**

**invite/ 도메인의 §7.17 밀도(2/9 = 22.2%)**: invite/ 는 "초대 상태 전이(없음→생성→수락/거절)" 중심 도메인으로 **상태 페이지 헤드라인** 이 자연스럽게 많음. 역으로 auth/ 는 2 지점 전부 §7.30(코드 입력 TextField) — 입력 도메인 vs 상태 도메인 구분.

**gamification/ 도메인의 §7.17 밀도(2/6 = 33.3%)**: 뱃지/레벨 축하 UI 는 본질적으로 **"축하 헤드라인 + 동적 스탯"** 구조 — "뱃지 수여"/"레벨 업!" 헤드라인(§7.17) + "Lv.$level"/"총 ${points}P" 스탯(§7.30). **축하형 도메인 아키타입** 확립.

**§7.87-h 의 도메인 경계 초월**: my_connections_screen 의 `teacher/parent·student` 2원 유한집합이 선생님 감사 §7.87(payment_summary의 `${month}월 수강료 현황`) 과 **같은 법칙** 으로 §7.17 승격. §7.87-h 는 스케줄/결제만의 법칙이 아니라 **앱 전체 역할 분기 UI 에 일반 적용**.

**"2차 감사 법칙" 하한 샘플(11.76%)**: §7.93(profile/) 15.8% · §7.98(practice/) 17.86% · **§7.99(비선생님 7 도메인 혼합) 11.76%** — 혼합 도메인은 **11~18% 구간 수렴**. §7.95·§7.94(lessons/students/) 0% 와 §7.97(subscription/) 47% 는 "동질 도메인 내 양 극단". 전환율 11~18%는 **"혼합 도메인의 구조적 상수"**.

**은유**: §7.99 는 **"여러 학년 교실 7 개 순회 감사"** — 1 학년 교실(invite/) 과 특별활동실(gamification/)에만 필기체 문패 후보 4 개 생존, 나머지 5 개 교실(auth·student_home·settings·search·home)은 전부 숫자판/시계/이름표 등 계기판 30 개. 선생님 교실 8 개 전수 감사(§7.91~7.98) 완결 후의 **"경계 바깥 확인"** 작업 — §7.98 의 "전부 §7.30" 이라는 성급한 결론을 실증으로 교정.

**전체 감사 집계**: §7.91-b 선생님 8 배치(213 지점) + §7.99 비선생님 7 도메인(34 지점) = **247 감사 지점 · §7.17 승격 61 지점 · §7.30 예외 186 지점**. 전환율 24.7%. 앱 전역 `AppTypography.heading*` Notebook × Score 2 차 감사 **완결**.

---

### 7.100 §7.99 보완 — 선생님 배치 §7.89 소급 감사 (parent_home/ 1 지점 추가)

**기간**: 2026-04-23
**성격**: **1 지점 Playfair 승격**. §7.99 의 "앱 전역 2 차 감사 완결" 선언이 **선생님 배치 8 도메인은 §7.89 확장 법칙 이전에 감사되어 소급 미적용**이었음을 교정. §7.92 Batch 선생님.B(parent_home/) 에서 §7.89 빈 상태 1 지점 누락 확인.

#### 7.100-a §7.17 승격 1 지점

| 파일 | 라인 | 전환 대상 | 근거 |
|------|------|-----------|------|
| parent_home/parent_payments_tab.dart | 565 | `'등록된 수강권이 없습니다'` | §7.89 빈 상태 3축(Icon + 단일 헤드라인) + 정적 명사 |

**공간 맥락**: Icon(confirmation_number_outlined, 56px) + 헤드라인(§7.89) + 부가 설명(bodyMedium) 3층 구조. §7.89 "3축(Center + Icon + 단일 헤드라인)" 의 교과서적 적용.

#### 7.100 검증

- `flutter analyze lib/features/parent_home/ lib/features/invite/` → **No issues found** (10.1s)
- 8 선생님 배치 도메인(parent_home·profile·schedule·subscription·practice·students·lessons·analytics) **재 Python 전수 스캔**: 빈 상태 + heading 쌍 **0 건** (소급 적용 완결).

#### 7.100 관찰

**§7.92 의 역사적 한계**: Batch 선생님.B parent_home/ 는 2026-04-23 이전에 감사되었고, 그 시점에 §7.89 의 "빈 상태 + 정적 명사 + Icon 3축" 법칙이 아직 3 차 확장(§7.89 다이얼로그 확장 §7.97/§7.98) 되기 전이었음. 따라서 `'등록된 수강권이 없습니다'` 가 당시 §7.30 으로 분류되었을 가능성. §7.100 은 **"법칙 진화에 따른 이전 배치 자동 재분류"** 작업.

**"법칙 진화 지연 재분류 패턴"**: §7.87~§7.89 의 법칙 자체가 감사 진행 중 확장됨. 이로 인해 **이전 배치들의 §7.30 분류 중 일부는 잠재적 §7.17 후보**. §7.99 가 비선생님 7 도메인으로 이 패턴을 확인했고, §7.100 이 선생님 8 배치로 확장 — 둘을 합쳐야 **진정한 "앱 전역 2 차 감사 완결"**.

**최종 전체 감사 집계 업데이트**: §7.91-b 선생님 8 배치(213) + §7.99 비선생님 7 도메인(34) + §7.100 선생님 배치 소급(1) = **248 감사 지점 · §7.17 승격 62 지점 · §7.30 예외 186 지점**. 전환율 25.0%. 앱 전역 `AppTypography.heading*` Notebook × Score 감사 **진정한 완결**.

**은유**: §7.100 은 **"학년 순회 감사 후 1 학년 교실 재방문"** — §7.92 에서 이미 감사한 1 학년 교실(parent_home) 에서 "수강권 없음" 안내판 1 개가 §7.89 법칙 진화 이전에 지나쳐진 것을 발견하고 필기체로 교체. **"법칙은 감사 중에도 진화한다"** 는 감사 철학의 귀결.

**Lore-directive**: **"감사 완결" 선언은 항상 가장 마지막 법칙 확장 이전에 감사된 배치를 소급 재검사한 후에만 유효**. 이는 Notebook × Score 감사 프레임워크의 자기 정합성 원칙.

---

### 7.101 §7.100 보완 — 3-법칙 소급 감사 (§7.87-h · §7.89 변형 · §7.27) 영-후보 확정

§7.100 의 Lore-directive("법칙 진화에 따른 이전 배치 자동 재분류")를 §7.89 외의 나머지 확장 법칙 3종에도 동일하게 적용. §7.91-b 선생님 8 배치 + §7.99 비선생님 7 도메인 = **감사 완료 15 도메인 전체**에서 다음을 소급 재검사:

- **§7.87-h**: enum/AppStrings 상수 · 2원 유한집합(teacher/parent·student, active/completed 등) 은 §7.30 아닌 §7.17 승격 대상
- **§7.89 변형**: Dialog 헤드라인(성공/완료 축하) 은 §7.89 의 빈 상태 3축과 동등한 법칙으로 확장
- **§7.27**: Bottom sheet section header (고정 섹션 제목) 는 §7.17 승격 대상

#### 7.101-a 스캔 방법론

| 스캔 축 | 쿼리 패턴 | 대상 파일 수 | 결과 |
|---|---|---|---|
| 역할 기반 삼항 + heading | `role == .*? '.+?' : '.+?'` + AppTypography.heading | 47 | 0 후보 |
| Dialog 파일 + 정적 헤드라인 | `*_dialog.dart` + AppTypography.heading + 한글 리터럴 | 12 | 0 후보 |
| Bottom sheet + 정적 헤드라인 | `*_sheet.dart` + AppTypography.heading + 한글 리터럴 | 9 | 0 후보 |
| 빈 상태 패턴 (icon + inkSecondary/Tertiary + heading) | icon 근접 + heading + muted color | 34 | 1 매치 (§7.30 확정) |

**매치된 1 건**: `frontend/lib/features/profile/presentation/widgets/profile_visibility_widgets.dart:597` 의 `'비공개'` — 이미 §7.30 #시각 무게 매칭 변형으로 확정. 바로 위 line 593 에서 동적 값 `profile.name` 이 같은 `AppTypography.headingSmall` 을 사용 중이므로 "하위 위젯 시각 무게 일치" 예외. 법칙 진화와 무관한 기존 §7.30 분류 유지.

#### 7.101-b 영-후보 확정

15 도메인(lessons/students/practice/subscription/schedule/analytics/parent_home/profile + invite/gamification/notifications/auth/home/teachers/search) 에서 §7.87-h · §7.89 변형 · §7.27 의 3-법칙 확장 이후 소급 재분류 후보 **0 지점**.

**해석**:
1. §7.87-h 확장은 §7.97 단일 법칙 발견 이후 **진행 중인 배치 내 즉시 적용**되었음 (소급 대상 없음)
2. §7.89 변형(Dialog) 은 §7.99 비선생님 도메인에서 최초로 발견되어 **gamification 내 level_up_dialog 1 건만 해당** (이미 §7.99 에 포함)
3. §7.27 Bottom sheet 는 §7.99 에서 badge_award_sheet 1 건만 발견되었고 **이미 §7.99 에 포함**

#### 7.101 검증

```bash
# 3-법칙 교차 스캔: 역할 삼항 · dialog · bottom sheet
rg "role == .*'.+?' : '.+?'" -l -g"*.dart" frontend/lib/features/ | wc -l  # 0
rg "AppTypography.heading" -l -g"*_dialog.dart" frontend/lib/features/ | wc -l  # 0
rg "AppTypography.heading" -l -g"*_sheet.dart" frontend/lib/features/ | wc -l  # 0
# 빈 상태 패턴: inkSecondary/Tertiary + heading
rg "color: AppColors.ink(Secondary|Tertiary).*headingSmall|headingSmall.*inkSecondary" -g"*.dart" frontend/lib/features/ | wc -l  # 1 (§7.30 확정)
```

#### 7.101 관찰

**"법칙 진화의 수렴점"**: §7.87~§7.89 법칙 확장 4 차(§7.87-h · §7.89 3축 · §7.89 변형 · §7.27) 중 **3 차까지는 진행 중인 배치 내 동기 적용** 되었고, §7.100 에서 §7.89 1 차(3축) 에 대해서만 소급 감사 필요했음. §7.101 은 **나머지 3 법칙 확장은 동기 적용이 성공적이었음** 을 확정.

**"§7.100 의 진정한 의의"**: §7.100 을 통해 확인된 **1 지점** 은 특별한 사례가 아니라 **"법칙 진화 시점에 가장 큰 진화 격차를 일으킨 §7.89 1 차"** 에 기인. §7.101 영-후보는 **"§7.89 1 차만 격차가 있었고 그 이후 확장은 모두 실시간 수렴"** 이라는 법칙 진화 동역학의 증거.

**"앱 전역 감사 포화 선언"**: §7.100 + §7.101 = **15 도메인 전수에서 4 차 법칙 확장 전체에 대한 재분류 완료**. 이제 이후 발견될 법칙 확장(§7.102+) 은 새 배치(신규 화면 추가 시) 에만 적용되며, 기존 배치는 "법칙 진화 → 소급 재검사" 사이클이 종료된 **"Notebook × Score 포화 상태"** 에 도달.

**최종 집계 업데이트**: §7.91-b(213) + §7.99(34) + §7.100(1) + §7.101(0 소급) = **248 감사 지점 유지 · §7.17 62 지점 · §7.30 186 지점 · 전환율 25.0%**. §7.101 은 **"영-결과 검증 배치"** — 법칙 진화 이후 무-변동을 증명하여 이전 배치의 완결성을 확정.

**은유**: §7.101 은 **"백신 접종 후 전수 항체 검사"** — §7.100 에서 1 명의 감염 발견 후 15 명 전체를 검사했고, 나머지 법칙 3 종에 대해서는 14 명 모두 항체 보유 확인. **감염 없음 = 법칙이 살아 움직이는 중에도 감사 시스템이 건강하다는 증거**.

**Lore-directive**: **"영-결과 소급 감사는 감사 완결 선언의 필수 구성요소"**. 변동이 없었다는 사실 자체가 증명되어야 감사 시스템의 자기 정합성이 보장됨. §7.100 의 Lore-directive("가장 마지막 법칙 확장 이전 배치 재검사") 는 §7.101 에 의해 **"모든 법칙 확장 이전 배치 재검사"** 로 확장 완료.

### §7.102 — §1.1 #4 Gaegu 손글씨 서명 최초 전수 감사 (2026-04-24)

**배경**: §7.91-b~§7.101 의 15 도메인 전수 감사는 **§1.1 4대 시그니처 중 #1 Playfair** 한 축에만 초점을 맞추었다. §7.17 static-noun headline 승격과 §7.30 10-패턴 예외는 모두 Playfair 축의 법칙이다. **§1.1 #4 Gaegu (16px/400 손글씨 주석)** 서명은 `lesson_notes_widgets.dart:290` 의 선행 사례("레슨 상세 피드백 본문도 선생님 손글씨 주석(Gaegu)으로 렌더") 단 1 건으로만 규범이 암묵적으로 확립되어 있었고, **같은 의미론적 대상(선생님의 학생 대상 주관적 글쓰기)이 다른 파일에서 `AppTypography.bodyMedium` 으로 남아 있을 가능성**을 전수 검사한 적이 없었다.

**검사 트리거**: `NotebookTypography.hand*` grep → 17 occurrences / 13 files. 선행 사례와 **의미론적 평행(선생님 → 학생 주관적 글쓰기)** 이 성립하는 widget 중 `AppTypography.bodyMedium` 스타일을 쓰는 3 지점 특정.

**승격 3 지점**:

| 파일 | 라인 | 의미론적 대상 | 변환 |
|------|------|--------------|------|
| `practice/.../teacher_feedback_sheet.dart` | 279 | `feedback.content` — 녹음 공유에 대한 선생님 피드백 본문 | `bodyMedium` → `NotebookTypography.hand` |
| `profile/.../tip_template_management_screen.dart` | 275 | `template.content` — 선생님 팁 템플릿 본문 | `bodyMedium` → `NotebookTypography.hand` |
| `lessons/.../tip_template_bottom_sheet.dart` | 440 | `template.content` — 레슨 기록 작성 중 팁 템플릿 선택 본문 | `bodyMedium` → `NotebookTypography.hand` |

**선행 사례 일치**: `lesson_notes_widgets.dart:290` 의 `lesson.feedback!` 와 3 후보 모두 **"선생님이 학생에게 남기는 주관적 글쓰기 본문"** 이라는 의미론을 공유. 헤드라인 구조나 유한집합 법칙이 아니라 **작성자-수신자 관계** 가 Gaegu 서명의 발화 조건. §7.101 의 "Playfair 법칙 포화 선언" 은 이 축에 무관.

**의미론적 분류표 (§1.1 #4 Gaegu 서명 규범 문서화)**:

| 서명 발화 조건 | Gaegu 적용 | 적용 안 함 |
|--------------|----------|----------|
| 선생님 → 학생 주관적 글쓰기 본문 | `NotebookTypography.hand` | — |
| 시스템 생성 정적 텍스트 (메뉴, 라벨) | — | `AppTypography.*` |
| 사용자 입력 중성 텍스트 (검색어, 이름) | — | `AppTypography.*` |
| 수치/날짜/상태 (메타데이터) | — | `AppTypography.caption` |

**감사 포맷 진화**: §7.x Playfair 감사는 `grep AppTypography.heading*` 로 후보 집합을 만든 후 §7.17 승격 · §7.30 예외 2-way 분류였다. §7.102 Gaegu 감사는 `grep NotebookTypography.hand*` 선행 사례 집합에서 **"의미론적 평행 대상"** 을 역추적해 **grep AppTypography.bodyMedium** 후보를 걸러내는 **"서명 씨앗(seed) → 평행 검색"** 패턴. 같은 파일 내에 이미 `NotebookTypography` 사용이 있는 선행 파일은 import 생략 가능하여 편집 비용도 낮음.

**tip_template 2 지점의 중요성**: `tip_template_bottom_sheet` 는 **레슨 기록 작성 중 팁을 선택하는 순간** 의 preview 이고, `tip_template_management_screen` 은 **팁 라이브러리 관리** 화면의 본문 표시. 둘 다 선생님이 학생에게 남길 **미래의 주관적 글쓰기 초안(draft)** 이므로 본문 렌더링 시점에 이미 Gaegu 서명이 일관되어야 한다. 서명이 바뀌면 선생님이 "이건 시스템 텍스트" 로 오인해 편집 감각이 깨진다.

**최종 집계 확장**: 기존 §7.91-b~§7.101 의 **248 Playfair 감사 지점** 과 별도로, §7.102 는 **§1.1 #4 Gaegu 서명 차원** 의 최초 전수 감사 **4 지점**(1 선행 + 3 승격) 을 확정. **"감사 포화" 는 차원별 선언**이며, Gaegu 차원은 §7.102 로 포화에 도달.

**은유**: §7.102 는 **"보이지 않는 지문 감식"** — Playfair 는 돋보이는 헤드라인이지만 Gaegu 는 본문에 섞여 있어 육안으로 잡히지 않는다. 선행 사례 1 건이 남긴 서명(지문) 을 현상액(평행 검색) 으로 드러내어 같은 범인(의미론적 대상) 의 다른 흔적 3 건을 확정. Playfair 감사가 "건물 외벽 도장 전수 조사" 였다면 Gaegu 감사는 "건물 내부 손때 자국 전수 조사".

**Lore-directive**: **"서명 차원은 축별로 독립 감사한다"**. §1.1 4대 시그니처는 병렬적이며, 한 축(Playfair) 의 포화 선언은 다른 축(Gaegu · 로마숫자 · Vermillion) 의 감사 면책을 의미하지 않는다. §1.1 시그니처 규범 중 시스템 감사가 부재한 축이 있다면 **"선행 사례 1 건 → 평행 검색 → 전수 확정"** 3-step 으로 신규 감사 배치를 개시.

**Lore-constraint**: Gaegu 서명은 **"작성자-수신자 관계"** 로만 발화되며, 헤드라인 구조(§7.17) 나 유한집합(§7.87-h) 과는 독립된 발화 조건. 서명 법칙을 구조 법칙과 섞으면 규범이 오염됨.

**다음 차원 후보**: §1.1 #2 로마숫자 (PieceTitle / 로마 기보법), §1.1 #3 Vermillion Red (paperAccent 악센트) 두 축이 미-감사 상태. §7.103+ 배치에서 동일 3-step 으로 개시 가능.

### §7.103 — §1.1 #2 로마숫자 서명 전수 감사 영-후보 + 경계 케이스 4 분류 (2026-04-24)

**배경**: §7.102 Gaegu 감사의 "서명 씨앗 → 평행 검색" 프로토콜을 §1.1 #2 로마숫자 서명에 적용. `NotebookTypography.roman` / `romanActive` / `romanOf()` 의 기존 14 파일 사용처가 서명 규범의 선행 사례이고, 그 중 `schedule/regular_lesson_widgets.dart:29`("I. 제목" 형), `teacher_availability_screen.dart:158`("I. 제목" 형), `home/getting_started_card.dart:145`(원형 없는 step 프리픽스) 세 패턴이 핵심 선행 사례.

**평행 후보 검색 범위**:
- `\$\{(index|idx|i|step)\s*\+\s*1\}` (숫자 + 1 전개)
- `'제\d+조'`, `'\d+회차'`, `'\d+주차'`, `'\d+위'`, `'\d+번째'` (Korean 한자/접사)
- `ListView.builder` 의 `index` 기반 prefix

**결과: 의미론적 평행 후보 0 건**. 15 지점 잠재 후보 발견했으나 **전원 §7.30 경계 케이스**로 분류. 직접 승격 대상 없음.

**경계 케이스 4 축 정의** (§7.30 확장):

| 신규 축 | 패턴 | 예시 | 아라비아 유지 이유 |
|--------|------|-----|-----------------|
| §7.30 #11 편집 상태 섹션 인덱스 | 사용자가 동적으로 추가/삭제하는 섹션의 임시 라벨 | `practice/quick_add_screen.dart:438` `'섹션 ${index + 1}'` | 편집 흐름에서 "현재 작업 인덱스" 인식 속도가 고전적 열거보다 우선. `_sections.length` 가 12 초과 가능 (romanOf 폴백 발생) |
| §7.30 #12 원형 뱃지 내부 단일 숫자 | 24px 이하 원형 배경 + 중앙 정렬 숫자 | `onboarding/tutorial_screen.dart:344` `_ProgressStep` · `schedule/suggest_alternative_screen.dart:298` 선택 뱃지 | 좁은 원형 공간 (20~24px) 에서 Playfair italic "IV/VIII" 가독성 저하. material 정통 진행 표시기 관례 우선 |
| §7.30 #13 한글 순위/회차 접사 결합 | `${n}순위`, `${n}회차`, `${n}주차` | `schedule/weekly_calendar_picker.dart:498` 순위 · `schedule/schedule_change_response_bottom_sheet.dart:247` 순위 · `current_request_box.dart:371` 순위 chip · `AppStrings.sessionNumberLabel` 회차 | Korean 접사와 Roman numeral 혼재 ("I순위", "I회차") 는 부자연스러운 다국 혼종. 접사 의미론(순위 ≠ 섹션 index) 상 부적합 |
| §7.30 #14 법률 조문 표기 | `제1조`, `제2조`, `제3장` | `auth/terms_agreement_screen.dart:294+` · `student_home/legal_document_screen.dart:73+` | 법률 standard 표기법이고 법적 content 자체. 서명 대체 금지 |

**선행 사례 14 지점 재분류 확정** (현행 로마숫자 적용의 의미론):

| 의미론 축 | 파일 수 | 설명 |
|----------|--------|-----|
| 매스트헤드 메타(VOL./NO.) | 3 | `students_tab` · `schedule_tab` · `dashboard_tab` — 신문 vol/no 포맷 |
| 매스트헤드 인사 prefix | 3 | `home_screen` · `student_home_screen` · `parent_home_screen` — "${roman}" 인사말 악센트 |
| 섹션 목록 제목 prefix | 3 | `regular_lesson_widgets` · `teacher_availability_screen` · `parent_home/section_card` — "I. 제목" |
| 단계별 가이드 prefix | 1 | `getting_started_card` — step 프리픽스 |
| 대시보드 카운터 | 2 | `dashboard_tab` (레슨 수, 스텝 인덱스) |
| next lesson 장식 | 2 | `student_home/next_lesson_card` — roman + "I." 과 romanActive |

**의미론 수렴**: **"고전적 서지(bibliographic) 맥락의 고정 프리픽스"** — 월/호수, 인사, 섹션 목록 헤더, 단계별 가이드. 모두 **① 최대 12 이하 소수 ② 읽기 전용 렌더 ③ 디자인 악센트 역할**. 편집·입력·동적 카운트 시나리오는 포함되지 않음.

**의미론 경계 정의 (§1.1 #2 규범 완결)**:

| 조건 | 로마숫자 적용 | 아라비아 유지 |
|------|------------|-------------|
| 목록 전체 개수 | ≤ 12 (romanOf 폴백 없음) | > 12 가능성 |
| 렌더 시점 | 읽기 전용 display | 편집/입력 상태 |
| 한글 접사 결합 | 없음 (독립 prefix) | 있음 (순위·회차·주차) |
| 공간 여유 | 플로팅 텍스트 | 원형 24px 이하 뱃지 내부 |
| 문서 성격 | UI 장식 | 법률 standard 표기 |

**은유**: §7.103 은 **"암호 해독의 경계선 확인"** — §7.102 의 "지문 감식" 이 숨은 흔적을 드러냈다면 §7.103 은 **"지문으로 오해할 수 있는 자국 4 종을 명시적으로 구분"**. 서명 signature 가 강해지려면 *적용되는 곳의 규범*뿐 아니라 *적용되지 않는 곳의 규범*이 동시에 명확해야 함. 양쪽 경계 모두 문서화되어야 서명이 "흉내낼 수 있지만 잘못 흉내낸" 오용을 방지.

**감사 포화 선언 2차**: §7.102 Gaegu(#4) 와 §7.103 Roman(#2) = **§1.1 4대 시그니처 중 2 축 포화**. 남은 축은 **#3 Vermillion Red(paperAccent)** 단 1 개. Vermillion 은 색 토큰이므로 타이포그래피 시그니처와 감사 방법론이 다름 — color token usage density 분석이 필요 (§7.104+ 후보).

**최종 누적 집계**: §7.91-b~§7.101 Playfair 차원 248 지점 + §7.102 Gaegu 차원 4 지점 + §7.103 Roman 차원 0 승격·14 선행 사례 재분류·4 경계 축 정의 = **서명 3 축 전수 감사 완료**.

**Lore-directive**: **"서명 signature 의 강도 = 적용 규범 + 비-적용 규범의 곱"**. 한 축의 signature 가 완결되려면 "쓰는 곳"뿐 아니라 "안 쓰는 곳"의 법칙이 동시에 문서화되어야 함. 경계 케이스 목록은 signature 감사의 필수 산출물.

**Lore-constraint**: 로마숫자는 ① 소수(≤ 12) ② 읽기 전용 ③ 한글 접사 없음 ④ 플로팅 공간 4 조건 모두 만족할 때만 발화. 하나라도 불충족 시 §7.30 #11~#14 로 분류.

**Lore-rejected**: `quick_add_screen:438` "섹션 ${index+1}" 로마숫자 승격 — 편집 상태 흐름에서 아라비아의 "현재 작업 인덱스" 인식 속도 우위, 그리고 12 초과 잠재 폴백 위험 때문에 거절.

---

### §7.104 — 평행 타이포 축 감사: `AppTypography.bodyLarge + w600` 의사-헤드라인 (2026-04-24)

**배경**: §7.91-b~§7.101 의 15 도메인 포화 감사는 **`AppTypography.heading*` 타이포 축**에 국한되었다. §7.17 승격과 §7.30 예외 체계 전체가 그 한 축 위에 구축되었음. 그러나 코드베이스에는 **"의사-헤드라인 (quasi-headline)"** 이라는 평행 패턴이 존재 — `AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)` 로 섹션 제목·리스트 그룹 헤더를 표현하는 방식. 크기 16pt/w600 Pretendard 는 시각적으로 `headingSmall`(18pt/w600) 과 유사한 권위를 지니지만 **타이포 정의상 별개** — 따라서 §7.17 자동 적용 대상이 아님. §7.104 는 이 축을 **최초로 전수 감사**.

**검사 트리거**: `§7.102`(Gaegu) 와 `§7.103`(Roman) 이 §1.1 4대 시그니처의 다른 축을 감사했다는 관찰 → §7.104 는 **타이포 축 확장 감사**. `rg "AppTypography.bodyLarge.copyWith\(.*FontWeight\."` → 10 지점 발견.

#### 7.104-a §7.17 승격 7 지점

| 파일 | 라인 | 헤드라인 | 분류 근거 |
|------|------|---------|----------|
| `features/lessons/presentation/screens/quick_feedback_screen.dart` | 235 | "레슨 피드백" | _buildSectionHeader 정적 명사 단일 헤드라인 |
| `features/invite/presentation/screens/invite_history_screen.dart` | 153 | "활성 초대" / "만료/취소된 초대" | _buildSectionHeader 정적 명사 (2 callers) |
| `features/practice/presentation/widgets/tuner/tuner_settings_sheet.dart` | 167 | "기준 주파수 (A4)" | 바텀시트 설정 섹션 헤더 |
| 동일 파일 | 263 | "조옮김 (관악기용)" | 바텀시트 설정 섹션 헤더 |
| 동일 파일 | 330 | "판정 난이도" | 바텀시트 설정 섹션 헤더 |
| 동일 파일 | 402 | "이명동음 표시" | 바텀시트 설정 섹션 헤더 |
| 동일 파일 | 461 | "음자리표" | 바텀시트 설정 섹션 헤더 |

변환: `AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)` → `NotebookTypography.sectionTitle` (Playfair 17 / w600). 16pt Pretendard → 17pt Playfair 로 1pt 상향 + serif 전환 = §7.17 기존 승격과 동일한 위계 확립.

#### 7.104-b §7.30 예외 3 지점

| 파일 | 라인 | 내용 | §7.30 패턴 |
|------|------|------|-----------|
| `features/profile/presentation/widgets/lesson_time_settings_widgets.dart` | 185 | `dayName` (월/화/수…) | #2 동적 개체명 |
| `features/practice/presentation/widgets/recording_comparison_sheet.dart` | 236 | `'Step 1/2: ...' / 'Step 2/2: ...'` | #4 변형 시퀀스 라벨 |
| `features/schedule/presentation/widgets/unified_request_card.dart` | 150 | `'${studentName} · ${instrument}'` | #2 동적 개체명 |

#### 7.104 검증

```bash
# 승격 후 평행 패턴 잔존 확인
rg "AppTypography.bodyLarge.copyWith\(.*FontWeight\." frontend/lib/features/ | wc -l  # 3 (모두 §7.30 예외)
# NotebookTypography.sectionTitle 사용 증가 확인
rg "NotebookTypography.sectionTitle" frontend/lib/features/ | wc -l  # 7 지점 신규 + 기존
flutter analyze 4 파일 → No issues found
```

#### 7.104 관찰

**"평행 타이포 축 포화"**: 10 지점 중 7 승격 + 3 예외 = **전환율 70.0%**. 이는 §7.91-b~§7.98 의 선생님 8 배치 평균(22.5%) 보다 현저히 높음. 원인: `bodyLarge + w600` 은 `heading*` 보다 **더 엄격한 의도성** 을 요구하는 스타일 — 개발자가 명시적으로 `fontWeight.w600` 를 지정한 경우는 "이것은 제목이다" 라는 의도 자체가 강함. 따라서 §7.30 예외 비율이 낮음.

**"5 설정 섹션 단일 파일 편중"**: 7 승격 중 5 지점이 `tuner_settings_sheet.dart` 한 파일에 집중. §7.96 의 "바텀시트 밀집형 도메인" 법칙이 **단일 파일 수준**에서도 성립 — 튜너 설정은 한 시트 안에 5 개 섹션을 쌓아 올린 **극도의 밀집형 구조**. 이는 §7.97 의 "5 개 이상 섹션 = 자동 §7.17 후보" 휴리스틱을 확증.

**"세 축 평행 감사 완결"**: §7.102(Gaegu) + §7.103(Roman) + §7.104(평행 타이포) = **§1.1 4대 시그니처 중 3 축에 대한 전수 감사 완료**. Vermillion (#3) 은 색 팔레트 축이라 타이포 감사 대상에서 제외 — 별도 스캐폴드 감사에 속함. 4대 시그니처 중 **타이포 기반 3 축(Playfair/Gaegu/Roman) + 평행 타이포 축** 이 모두 감사됨.

**최종 집계 업데이트**: §7.91-b(213) + §7.99(34) + §7.100(1) + §7.101(0 소급) + §7.102(3) + §7.103(0 소급) + §7.104(10) = **258 감사 지점 · §7.17/등가 승격 72 지점 · §7.30 예외 189 지점 + Gaegu 전용 3 지점 승격**. 평행 타이포 포함 전환율 27.9%.

**은유**: §7.104 는 **"같은 음을 다른 악기로 연주하는지 확인"** — Playfair 피아노(heading*) 는 이미 조율했지만, 바이올린(bodyLarge+w600) 도 같은 화성 위계를 지키는지 점검. 7 지점은 바이올린이 피아노에 합류했고, 3 지점은 솔로 유지 (§7.30).

**Lore-directive**: **"감사 축은 타이포 상수 이름에 묶이지 않고 시각적 역할에 묶인다"**. `heading*` 대신 `bodyLarge + w600` 를 써서 같은 역할(섹션 헤더) 을 수행하는 것은 법칙 회피가 아니라 **법칙 재발견** — §7.104 의 존재 자체가 "타이포 축 확장 감사" 라는 새 감사 유형을 정의.

**Lore-constraint**: `AppTypography.bodyLarge + FontWeight.w600` 은 §7.17 승격 전제에 해당. 정적 명사 + 단일 헤드라인 + 시각 위계(섹션 헤더 이상) 3 조건 충족 시 `NotebookTypography.sectionTitle` 로 변환 의무.

**Lore-rejected**: `unified_request_card.dart:150` 승격 — `studentName · instrument` 은 완전 동적 개체명 결합이라 §7.30 #2 확정. 의사-헤드라인이지만 데이터 주도.

---

### §7.105 — §1.1 #3 Vermillion Red 색 서명 SSOT 감사 · 4대 시그니처 포화 완결 (2026-04-24)

**배경**: §7.102(Gaegu) · §7.103(Roman) · §7.104(평행 타이포) 로 §1.1 4대 시그니처 중 **타이포 3 축** 전수 감사가 마무리됨. 남은 축은 **#3 Vermillion Red(`paperAccent` = `#9B1B12`)** 단 하나. Vermillion 은 색 토큰 축이라 감사 방법론이 다름 — "헤드라인 승격 조건" 이 아니라 **"SSOT 일관성 + 드리프트 부재"** 를 검증해야 함. §7.105 는 **색 팔레트 축의 최초 · 유일 감사 배치**.

**검사 3 단계**:
1. **밀도 분석** — `rg "paperAccent" frontend/lib/` = 2,294 지점 (features 2,111 + core 183). §7.91-b(213) · §7.104(10) 과 비교하면 **색 토큰 밀도는 타이포 밀도의 10 배 이상**. 이는 색이 전 화면에 편재(ubiquitous) 하기 때문 — 개별 감사 대신 **테마 체제 + 드리프트 부재** 를 검증하는 것이 합리적.
2. **테마 체제 검증** — `frontend/lib/core/theme/app_theme.dart:106-120` 이 `FilledButton.backgroundColor = paperAccent` · `ColorScheme.secondary = paperAccent` · `ColorScheme.error = paperAccent` 로 **단일지점 테마 주입**. 주석 "74 개 호출부 중 21 개 인라인 반복 · 53 개는 테마 자동 보급" 이 이미 **Vermillion 포화 의지** 를 명문화.
3. **드리프트 부재 검증** — 대체 색(red/deepOrange/pink 계열 Flutter Material Color) 이 features/ 에 하드코딩되었는지 전수 검색 → **0 건**. 서명 hex(`0xFF9B1B12`) 리터럴 전수 검색 → **1 건**(`core/utils/instrument_colors.dart:9`).

#### 7.105-a 1 SSOT 위반 해소

| 파일 | 라인 | 위반 | 수정 |
|------|------|------|------|
| `core/utils/instrument_colors.dart` | 9 | `InstrumentColorPair(Color(0xFFF2ECDD), Color(0xFF9B1B12))` — 바이올린 색 페어가 `paper` / `paperAccent` 와 동일 hex 지만 하드코딩 리터럴 사용 | `InstrumentColorPair(AppColors.paper, AppColors.paperAccent)` + `import '../theme/app_colors.dart';` 추가. 바이올린 = **서명 악기** 라는 의미가 색 표현 레벨에서 SSOT 로 고정. |

#### 7.105-b 3 의미 축 확증

Vermillion 이 **paperAccent** 라는 단일 토큰으로 세 가지 다른 의미 역할을 동시에 담당:

| 역할 | 대표 지점 | 시각 패턴 |
|------|----------|----------|
| **핵심 액션** (primary CTA) | `FilledButton` 전역 자동 | `paperAccent` 배경 + `paper` 텍스트. 테마 강제 |
| **현재 진행** (active/selected) | `time_signature_picker.dart:143` · `paperAccent` chip border + fill | 선택 상태 자기-표지 |
| **하이라이트** (warning/important) | `lesson_notes_widgets.dart` 피드백 액센트 · `paperAccentSoft` 배경 24% alpha | 본문에 끼어드는 주의 표지 |

세 역할이 **단일 색 토큰** 을 공유하는 것이 규범이며, 별도 warning/action/selected 토큰 분화는 **역-SSOT**. §7.105 는 이 3-in-1 구조가 전 코드베이스에 견고히 유지되고 있음을 확증.

#### 7.105 검증

```bash
rg "Color\(0xFF9B1B12\)|Color\(0xff9b1b12\)" frontend/lib/ | wc -l  # 1 (app_colors.dart 정의 자체만)
rg "Colors\.(red|deepOrange|orange|pink)" frontend/lib/features/ | wc -l  # 0 (드리프트 부재)
rg "paperAccent" frontend/lib/ | wc -l  # 2,294 (테마 + features 포화)
flutter analyze lib/core/utils/instrument_colors.dart  # No issues found
```

#### 7.105 관찰

**"색 서명의 테마 단일지점 주입 법칙"**: Vermillion 이 2,294 지점에 편재함에도 감사가 가능했던 이유 = `app_theme.dart` 가 **`FilledButton` 전역 배경** 을 테마 레벨에서 강제했기 때문. 만약 각 버튼이 `FilledButton.styleFrom(backgroundColor: ...)` 를 개별 지정했다면 감사는 불가능. **색 토큰의 SSOT 강제는 테마 레벨 정의 + 호출부 인라인 금지** 의 2-조건 충족이 필수.

**"서명 색 토큰 = 의미 번들링"**: Vermillion 한 토큰이 CTA · 선택 · 경고 3 의미를 담는 것은 Bauhaus/Pentagram 식의 **"신호 간결주의"** 와 일치. 3 역할을 3 토큰(actionColor/selectedColor/warningColor) 으로 분리하면 Flutter Material 과 동일해지지만 서명성은 사라짐. 이 긴장관계는 §7.104 의 "타이포 상수 이름 ≠ 시각 역할" 과 **정반대 구조** — 타이포는 역할별 상수 분화, 색은 역할별 상수 통합.

**"§1.1 4대 시그니처 전수 감사 포화"**:
- §7.101: #1 Playfair serif — 타이포 헤드라인 포화 ✓
- §7.102: #4 Gaegu 손글씨 — 3 지점 신규 승격 포화 ✓
- §7.103: #2 Roman 기보 — 14 선행 + 4 경계 케이스 (#11~#14) 포화 ✓
- §7.104: 평행 타이포 축 — 10 지점 포화 (#1 확장) ✓
- **§7.105: #3 Vermillion Red — 1 SSOT 위반 해소 · 2,294 지점 테마 주도 포화 ✓**

4 축 모두 감사되었으며, 각 축은 **고유한 감사 방법론** 으로 검증됨 (Playfair/Gaegu/Roman = 헤드라인 승격, Vermillion = SSOT + 드리프트 부재). 이후 §7.106+ 배치는 **신규 배치 · 축 교차 · 재감사** 중 하나여야 하며, 단일 축 최초 감사는 **더 이상 가능하지 않음** (남은 축 없음).

**은유**: §7.105 는 **"오케스트라 튜닝 최종 확인"** — 각 악기(§7.101~§7.104 의 4 축) 가 개별 조율되었고, 마지막으로 **전체 합주에서 공통 기준음(A=440Hz)** 이 흔들리지 않는지 점검. 색은 음높이 같은 연속 스펙트럼이라 **기준점 일탈 = 1 위반 발견 → 1 수정** 이라는 이산 사건으로 감지됨.

**Lore-directive**: **"서명 색 토큰은 hex 리터럴 금지, AppColors 참조 필수"**. `Color(0xFF9B1B12)` 같은 서명 hex 문자열은 **`AppColors.paperAccent`** 로만 참조. 이는 §7.102 의 "Gaegu 는 `NotebookTypography.hand` 로만" 과 동형의 SSOT 법칙 — 어느 차원이든 **서명 상수명이 유일 접근 경로**.

**Lore-constraint**: Vermillion 의 3 의미 역할(CTA / 선택 / 경고) 은 별도 토큰으로 분화 금지. 의미를 구분해야 할 경우 **배경 alpha(`paperAccentSoft` 24% alpha) + 주변 강세** 로 구분 — 색 자체의 서명성은 유지.

**Lore-rejected**: 서명 Vermillion 을 warning-specific 토큰으로 복제 — Material Design 의 `colorScheme.error` 분화 패턴에 해당. Riman Lesson-App 은 `ColorScheme.error = paperAccent` 로 **역-Material** 을 선택했고, 이 선택이 서명성을 지킴.

---

## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **4대 시그니처 필수**: 어느 화면이든 Notebook × Score를 적용했다면 Playfair · 로마숫자 · Vermillion · Gaegu 네 가지가 모두 관찰되어야 한다.
