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
| 위치 | `Positioned(left: 0, top: 0, bottom: 0)` |
| 너비 | **3px 고정** |
| 색상 | `AppColors.paperMargin` (#A83E3A) |
| 투명도 | 1.0 (불투명) |
| 상호작용 | `IgnorePointer` — tap/scroll 전달 금지 |

### 3.2 설계 근거

**왜 3px인가?**
- 레퍼런스 디자인은 52px 들여쓰기 + 1.2px 세로선이지만, 모바일에서는 **가로 공간이 부족**.
- 해당 영역은 **사용 빈도가 극히 낮은 장식 영역**이므로 52px 들여쓰기 비용이 크다.
- **3px 플러시 마진**으로 축소 → 콘텐츠 가로폭 최대화 + 노트북 은유 유지.

### 3.3 구현 예시

```dart
Stack(
  children: [
    Container(color: AppColors.paper),
    // ── 3px 고정 붉은 여백선 (불가침) ──
    const Positioned(
      left: 0, top: 0, bottom: 0, width: 3,
      child: IgnorePointer(
        child: ColoredBox(color: AppColors.paperMargin),
      ),
    ),
    child, // 콘텐츠
  ],
)
```

### 3.4 금지 사항

- 3px 외 다른 너비
- `left: 0` 이외의 위치 (들여쓰기 금지)
- 투명도/그라데이션
- 상하단 부분 그리기 (반드시 `top: 0, bottom: 0`)

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

| 스타일 | Font | Size | Weight | 용도 |
|--------|------|------|--------|------|
| `masthead` | Playfair Display | 38 | 700 | 메인 타이틀 ("오늘의 레슨") |
| `mastheadLabel` | Playfair Display (italic) | 12 | 600 | 부제 ("Programme for Thursday") |
| `eyebrow` | Playfair Display | 11 | 600 | 상단 로고 라벨, letterSpacing 5 |
| `metaMono` | IBM Plex Mono | 9 | 400 | VOL·NO·DATE |
| `roman` | Playfair Display (italic) | 13~15 | 600 | 로마숫자 번호 |
| `pieceTitle` | Playfair Display | 16 | 600 | 곡명·레슨 제목 |
| `sectionLabel` | Pretendard | 11 | 500 | 업퍼케이스 라벨, letterSpacing 1.5 |
| `body` | Pretendard | 14 | 400 | 본문 |
| `hand` | Gaegu | 16~17 | 400 | 손글씨 |
| `handEmphasis` | Gaegu | 13 | 700 | "지금", "발표회!" |

---

## 5. 컴포넌트 매핑 (선생님 홈화면)

기존 기능을 **제거하지 않고** Notebook 토큰으로 리스타일.

| 기존 요소 | Notebook 매핑 | 변경 범위 |
|-----------|---------------|-----------|
| `Scaffold` 배경 | Paper + 3px 왼쪽 마진선 | 스캐폴드 래퍼 |
| `_buildHeader` "Lessonaza" | **Masthead** (상단 2px / 하단 1px 라인 + Playfair eyebrow + IBM Plex Mono VOL·NO·DATE) | 스타일만 |
| 타이틀 영역 (신규) | **Programme Title** — "Programme for Thursday" + "오늘의 레슨" + 한글 날짜 | 추가 |
| 섹션 구분선 (신규) | **StaffDivider** — 오선 + 높은음자리표 | 추가 (선택) |
| `TimeContextBanner` | 그대로 + 손글씨 스타일 마지널리아로 감쌈 | 래퍼 스타일 |
| `UrgentAlertZone` | 그대로 | 변경 없음 |
| `StatCardRow` | 그대로 | 변경 없음 |
| "오늘의 레슨" 헤더 | Playfair Display headline + 카운트를 로마숫자로 | 스타일 |
| `LessonCard` 리스트 | **로마숫자 인덱스(I, II, III…)** 를 카드 앞에 prepend | 래퍼 스타일 |
| `LessonRequestSection` | 그대로 | 변경 없음 |
| `ScheduleChangeRequestSection` | 그대로 | 변경 없음 |
| `AssignmentSummarySection` | 그대로 | 변경 없음 |
| `_buildAnalyticsLink` | Playfair Display italic "Fine." + 링크 | 스타일 |

**원칙**: Phase 1은 스캐폴드 + 헤더 + 리스트 래퍼 + 푸터만 Notebook으로 교체. 각 위젯 내부는 그대로.

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

### 6.2 Masthead

상단 2px 라인 + 하단 1px 라인 사이에 Playfair Display eyebrow(좌) + IBM Plex Mono VOL·NO·DATE(우).

### 6.3 Roman Numeral

```dart
const _roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
String romanOf(int i) => i < _roman.length ? _roman[i] : (i + 1).toString();
```

Playfair Display · italic · `FontWeight.w600`.

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
| Phase 1 | 선생님 홈화면 — 토큰 + Paper 스캐폴드 + Masthead + 로마숫자 + 손글씨 | **진행 중** |
| Phase 2 | StaffDivider + PencilUnderline/Box/Circle CustomPainter | 계획됨 |
| Phase 3 | 개별 카드(LessonCard, StatCard) Notebook 리스타일 | 계획됨 |
| Phase 4 | 학생/학부모 홈 적용 | 계획됨 |
| Phase 5 | 전 화면 확산 | 계획됨 |

---

## 8. 구현 원칙

1. **Additive**: 기존 `AppColors`/`AppTypography` 유지. Notebook 팔레트·타이포는 추가.
2. **Non-breaking**: Notebook 스캐폴드 미적용 화면은 그대로 동작.
3. **Feature-preserving**: 기능 위젯 재사용. 기능 변경 금지.
4. **3px 규칙 불가침**: §3의 여백선 규칙은 전 화면에서 동일.
5. **4대 시그니처 필수**: 어느 화면이든 Notebook × Score를 적용했다면 Playfair · 로마숫자 · Vermillion · Gaegu 네 가지가 모두 관찰되어야 한다.
