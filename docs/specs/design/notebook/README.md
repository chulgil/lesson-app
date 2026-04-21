# Notebook × Score Design System

> Last updated: 2026-04-21
> 컨셉: **괘선 종이의 아날로그 손맛 + 클래식 악보의 엄격한 타이포그래피**
> 상태: 선생님 홈화면부터 적용 (Phase 1)
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
| `paperMargin` | `#A83E3A` | **왼쪽 여백선** (3px 고정) |
| `paperAccent` | `#9B1B12` | **Vermillion Red** — 핵심 액션 |
| `paperAccentSoft` | `rgba(155,27,18,0.12)` | 액센트 배경 |
| `paperOk` | `#3F5D2F` | 완료 (녹색 펜) |
| `paperHighlight` | `#F7D755` | 형광펜 |

Flutter 구현: `lib/core/theme/app_colors.dart`의 Notebook 섹션.

---

## 3. 왼쪽 붉은 여백선 규칙 (CRITICAL)

### 3.1 스펙

| 항목 | 값 |
|------|-----|
| 위치 | `Positioned(left: 14, top: 0, bottom: 0)` (기본값) |
| 너비 | **3px 고정** |
| 색상 | `AppColors.paperMargin` (#A83E3A) |
| 투명도 | 1.0 (불투명) |
| 상호작용 | `IgnorePointer` — tap/scroll 전달 금지 |
| 콘텐츠 좌측 padding | **≥ 17px** (선 우측 끝 = left 14 + width 3) |

### 3.2 설계 근거

**왜 `left: 14` 인가?**
- 레퍼런스 디자인(웹)은 52px 들여쓰기 + 1.2px 세로선이지만, 모바일에서는 **가로 공간이 부족**.
- 과거에는 `left: 0 + width: 3` 플러시 마진을 사용했으나, **기기 베젤·라운드 코너·SafeArea** 에 가려 선 자체가 잘 안 보이는 문제가 발생 (2026-04-21 피드백).
- 14px 들여쓰기로 선이 **명확히 보이면서도** 콘텐츠 가로폭 손실은 최소화 (전체 폭의 ~3.7%).
- 너비는 3px 유지 — 모바일에서 1.2px 은 너무 가늘어 저대비 상황에서 실종된다.

### 3.3 구현 예시

```dart
// 일반 사용 — 기본값(left: 14, width: 3)
PaperScaffold(
  child: SafeArea(child: child),
)

// 튜닝 — 매우 좁은 화면에서 더 붙이고 싶을 때
PaperScaffold(
  marginLineLeft: 8,
  marginLineWidth: 2.5,
  child: SafeArea(child: child),
)
```

`PaperScaffold` 내부는 `Stack` + `Positioned` 로 구성되며, 콘텐츠(`Positioned.fill`) 는 선 **위에** 올라간다. 콘텐츠의 좌측 padding 이 `marginLineLeft + marginLineWidth` 미만이면 텍스트가 선과 겹치므로, 기본 설정에서는 `horizontal: AppSpacing.screenPadding` (16px) 이상을 사용한다. 17px 미만으로 가야 한다면 `marginLineLeft` 를 줄여 맞춘다.

### 3.4 금지 사항

- 화면 중앙·우측 배치 (반드시 좌측, `left` ≤ 24)
- 투명도/그라데이션 (불투명 단색만)
- 상하단 부분 그리기 (반드시 `top: 0, bottom: 0`)
- 너비 1.5px 미만 (모바일 가독성 부족)
- 콘텐츠 padding < 여백선 우측 끝 → 텍스트가 선과 겹침

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
| `Scaffold` 배경 | `PaperScaffold` — paper + 3px 왼쪽 마진선 | 스캐폴드 래퍼 |
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

### 5.2 Phase 2 이후 대상 (미구현)

| 항목 | 계획 | Phase |
|------|------|-------|
| `StaffDivider` | 오선 + 높은음자리표 기반 섹션 구분선 (CustomPainter) | Phase 2 |
| `TimeContextBanner` 손글씨 래핑 | Gaegu 마지널리아 스타일 외곽 래퍼 | Phase 2 |
| `GettingStartedCard` | Notebook 스타일 체크리스트 (`PencilBox`) | Phase 2 |
| `LessonCard` 내부 | 로마숫자 시간·곡명·노트 — 완전 이식 | Phase 3 |
| `StatCard` | "Fine." 푸터에 HBStat 방식 수치 이식 | Phase 3 |

---

## 6. 핵심 컴포넌트 스펙

### 6.1 PaperScaffold

```dart
// core/widgets/notebook/paper_scaffold.dart
class PaperScaffold extends StatelessWidget {
  final Widget child;
  const PaperScaffold({required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: ColoredBox(color: AppColors.paper)),
      const Positioned(
        left: 0, top: 0, bottom: 0, width: 3,
        child: IgnorePointer(
          child: ColoredBox(color: AppColors.paperMargin),
        ),
      ),
      child,
    ],
  );
}
```

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

### 6.4 손글씨 마지널리아

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
| Phase 2 | StaffDivider + PencilUnderline/Box/Circle CustomPainter · TimeContextBanner·GettingStartedCard 래핑 | 계획됨 |
| Phase 3 | 개별 카드(LessonCard, StatCard) Notebook 내부 이식 + HBStat 수치 표기 | 계획됨 |
| Phase 4 | 학생/학부모 홈 적용 | 계획됨 |
| Phase 5 | 전 화면 확산 (설정/프로필/수강권/스케줄) | 계획됨 |

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

#### 4대 시그니처 렌더 상태

| 시그니처 | Phase 1 상태 | 렌더 위치 |
|----------|-------------|-----------|
| Playfair Display | **렌더** | Masthead eyebrow · Programme Title · mastheadDate · 로마숫자 · "Fine." · "Today's Programme" |
| 로마숫자 | **렌더** | "오늘의 레슨" 헤더 카운트 · 레슨 카드 앞 인덱스(I., II., III.…) |
| Vermillion Red | **렌더** | 왼쪽 3px 여백선(#A83E3A) · "일괄 피드백" 텍스트(#9B1B12) |
| Gaegu 손글씨 | **스타일만 정의 · 미렌더** | Phase 2에서 TimeContextBanner·마지널리아·"지금" 라벨 등에 투입 예정 |

> **정직한 평가**: Phase 1은 4대 시그니처 중 **3종이 실제 관찰 가능**하며 Gaegu는 토큰 준비 완료·실사용은 Phase 2. §8의 "4대 시그니처 필수" 원칙(5번)은 **Phase 2 종료 후부터** 화면 단위 감사 대상이다.

---

## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **4대 시그니처 필수**: 어느 화면이든 Notebook × Score를 적용했다면 Playfair · 로마숫자 · Vermillion · Gaegu 네 가지가 모두 관찰되어야 한다.
