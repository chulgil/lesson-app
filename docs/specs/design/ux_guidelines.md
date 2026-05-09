# UX Guidelines

> 최종 수정: 2026-05-04
> 목적: Claude가 UI 구현 시 참고하는 디자인 시스템 + UX 원칙

---

## 1. 디자인 토큰 (Design Tokens)

> **절대 규칙**: 모든 색상/타이포/간격은 공통 클래스만 사용. 하드코딩 금지.
> Notebook x Score 적용 화면은 `docs/specs/design/notebook/README.md`를 색상·표면 SSOT로 우선한다.

### 1.1 색상 시스템 (AppColors)

> 파일: `lib/core/theme/app_colors.dart`
> **Notebook x Score 마이그레이션 완료 (2026-05)**: 레거시 브랜드/시맨틱/서피스/텍스트 토큰(`primary`, `success`, `surfaceLight`, `textPrimaryLight` 등)은 코드에서 완전 제거됨. 현재 앱 전체가 아래 Notebook 팔레트를 사용.

**Notebook 표면 (Surface)** — 종이 계열

| 토큰 | HEX | 용도 |
|------|-----|------|
| `paper` | #F2ECDD | 전체 배경, 카드/시트 배경 (크림색 종이) |
| `paperDark` | #E8DFC7 | 강조 영역, 칩 배경, scaffold 배경 (주간 그리드 등) |

**Notebook 잉크 (Text/Icon)** — ink 알파 계층

| 토큰 | HEX / Alpha | 용도 |
|------|-------------|------|
| `ink` | #14161C (100%) | 제목, 본문, 아이콘 (딥 블루-블랙) |
| `inkSecondary` | #14161C (75%) | 부제목, 보조 아이콘 |
| `inkTertiary` | #14161C (55%) | 힌트, 비활성 라벨 |
| `inkQuaternary` | #14161C (25%) | 비활성 텍스트, 테두리, 구분선 |
| `inkScrim` | #14161C (54%) | 모달 배리어 |
| `paperPencil` | #14161C (60%) | 손글씨 (Gaegu 폰트용) |

**Notebook 액센트 (Semantic)** — 2색 체계

| 토큰 | HEX | 의미 | 사용 예 |
|------|-----|------|---------|
| `paperAccent` | #9B1B12 | 핵심 액션, CTA, 오류/긴급 | 버튼, 입금 기한 초과, 삭제, 결석 |
| `paperAccentSoft` | #9B1B12 (12%) | 액센트 배경 | 선택 상태 배경, 칩 선택 |
| `paperOk` | #3F5D2F | 완료/정상, 정기권 잉크 | 체크 마크, 완료 상태 (녹색 펜), 정기권 카드 액센트 |
| `paperTrial` | #C4923A | 체험레슨 잉크 | 체험레슨 카드 액센트 (세피아 앰버) |
| `paperTrialSoft` | #C4923A (12%) | 체험레슨 배경 | 체험레슨 카드 배경 |
| `paperHighlight` | #F7D755 | 형광펜 (배경색 전용) | 텍스트 하이라이트 마커 |

> **레거시 토큰 참고**: `primary`/`secondary`/`success`/`warning`/`error`/`info` 및 `*Light` 변형, `surfaceLight`/`borderLight`/`textPrimaryLight` 등은 모두 제거됨. 코드에 잔존하지 않으며, 신규 사용 금지. Notebook 팔레트의 `paperAccent`가 CTA + 오류/긴급을 통합하고, `paperOk`가 완료/정상을 담당.

**직접 색상 원칙**: UI 표면과 텍스트에는 `AppColors` 토큰만 사용한다. 순백/순검정도 직접 쓰지 않고 `AppColors.paper`, `AppColors.ink`, `AppColors.inkScrim` 계열로 표현한다.

**예외**: `Colors.transparent`는 route layer, overlay 제거, 선택 상태의 빈 배경처럼 실제 투명도가 의미인 경우 허용한다. 카메라, 이미지 cropper, waveform canvas처럼 외부 미디어 대비가 주 표면인 영역은 Notebook README §1.2.0 예외를 따른다.

#### `paperHighlight` (노란 형광펜) 사용 규칙

> **텍스트 색상으로 사용 금지.** 노트에서 형광마커로 글자 위를 칠하는 용도로만 사용.

| 용도 | 허용 | 예시 |
|------|------|------|
| 배경색 (형광마커) | O | `Container(color: AppColors.paperHighlight.withValues(alpha: 0.3))` |
| 텍스트 색상 | **X** | ~~`Text(style: TextStyle(color: AppColors.paperHighlight))`~~ |
| border 색상 | **X** | ~~`Border.all(color: AppColors.paperHighlight)`~~ |
| 아이콘 색상 | **X** | ~~`Icon(color: AppColors.paperHighlight)`~~ |

글자색은 반드시 `ink` / `inkSecondary` / `inkTertiary` / `paperAccent` / `paperOk` 중 하나 사용.
**금지**: `Colors.white`, `Colors.black`, `Colors.grey`, `Colors.red`, `Colors.green`, `Color(0xFF...)` 등 직접 색상 사용 금지.

#### 색상 사용 결정 기준

```
Q: 이 색상은 무엇을 의미하나?
├─ 핵심 액션 / CTA / 오류 / 긴급 → paperAccent
├─ 성공 / 완료 → paperOk
├─ 배경 / 카드 표면 → paper (기본) / paperDark (강조 영역)
├─ 텍스트 → ink / inkSecondary / inkTertiary
├─ 비활성 텍스트 / 테두리 / 구분선 → inkQuaternary
├─ 선택 배경 / 액센트 배경 → paperAccentSoft
├─ 체험레슨 액센트 → paperTrial / paperTrialSoft
├─ 형광 강조 (배경색 전용) → paperHighlight
└─ 손글씨 텍스트 → paperPencil (+ Gaegu 폰트)
```

#### 새 색상이 필요한 경우

1. 기존 토큰으로 대체 가능한지 먼저 확인
2. 불가능하면 `AppColors`에 새 상수 추가 후 사용
3. **절대** 위젯 내부에 하드코딩하지 않음

### 1.2 타이포그래피 (AppTypography)

> 파일: `lib/core/theme/app_typography.dart`
> 폰트: Pretendard

| 토큰 | 크기 | 무게 | 용도 |
|------|------|------|------|
| `displayLarge` | 32 | Bold | 히어로 숫자 |
| `displayMedium` | 28 | Bold | 대형 제목 |
| `headingLarge` | 24 | SemiBold | 화면 제목 |
| `headingMedium` | 20 | SemiBold | 섹션 제목 |
| `headingSmall` | 18 | SemiBold | 카드 제목 |
| `bodyLarge` | 16 | Regular | 본문 (기본) |
| `bodyMedium` | 14 | Regular | 부제목, 설명 |
| `bodySmall` | 12 | Regular | 캡션, 메타 |
| `caption` | 11 | Regular | 작은 라벨 |
| `button` | 16 | SemiBold | 버튼 텍스트 |
| `buttonSmall` | 14 | Medium | 작은 버튼 |

**금지**: `fontSize: N` 직접 사용. 반드시 `AppTypography.xxx` 사용.

#### 1.2.2 카드/리스트 아이템 최소 타이포 규칙

> 대시보드 카드, 레슨 요청 리스트, 스케줄 변경 리스트 등 반복 리스트 아이템에 적용.
> 가독성 최소 기준: 보조 정보도 `bodySmall`(12px) 이상 사용.

| 역할 | 최소 토큰 | 크기 | 예시 |
|------|----------|------|------|
| 주요 정보 (이름, 제목) | `bodyMedium` | 14px | 학생명, 곡명 |
| 보조 정보 (설명, 시간) | `bodySmall` | 12px | 악기·레벨, 선호 시간, 경과 시간 |
| 상태 라벨 (칩, 뱃지) | `bodySmall` | 12px | "확인 대기", "승인 필요" |
| 메타 라벨 (소속, 유형) | `bodySmall` | 12px | "개인레슨 · 체험" |

**`caption`(11px) 사용 제한**: 카드/리스트 아이템 본문에는 사용 금지. 캘린더 셀, 그리드 라벨, 아바타 이니셜 등 공간 제약이 극심한 경우에만 허용.

**`NotebookTypography.sectionLabel`(13px)**: 대시보드 섹션 타이틀("레슨요청 · 14" 등). 이전 11px에서 13px으로 상향. uppercase + letterSpacing으로 시인성 확보.

#### 1.2.4 스케줄 그리드 셀 타이포 + 레이아웃 규칙

> 주간 스케줄 그리드와 일정비교 캘린더 셀에 적용되는 통일 규칙.

**셀 border 패턴 (SSOT)**:
- 레슨 셀: **좌측 2px accent border** (악기별 색상). 상단 border 금지.
- preview 레슨: **좌측 2px dashed accent border**
- 이동 셀: **좌측 2px travel accent border**

**셀 내부 텍스트 (Notebook × Score)**:
| 내용 | 폰트 | 크기 | 무게 |
|------|------|------|------|
| 학생 이름 | `NotebookTypography.hand` (Gaegu) | 12px | w700 |
| 이동 라벨 | `NotebookTypography.hand` (Gaegu) | 11px | w700 |
| 휴무 라벨 | `NotebookTypography.hand` (Gaegu) | 11px | w700 |
| 선호 시간 라벨 | `AppTypography.captionXSmall` | 9px | w700 |

**UX 근거**: 스케줄 그리드의 학생 이름/이동/휴무는 선생님이 글씨를 적어넣은 듯한 노트 메타포. Gaegu(손글씨)로 통일하여 Notebook × Score 시그니처를 강화.

**적용 범위**:
- `schedule_weekly_grid_view.dart` — 선생님 홈 주간 스케줄
- `alternative_time_grid.dart` — 일정비교(대안 시간 제안) 화면

#### 1.2.3 완료/취소 항목 디밍 규칙

> 대시보드 리스트에서 "아직 해야 할 것"을 즉시 식별할 수 있어야 한다.

| 상태 | 시각 처리 | 구현 |
|------|----------|------|
| 예정 (scheduled) | 정상 표시 (opacity 1.0) | 기본 |
| 완료 (completed) | **opacity 0.45 + 취소선** | `Opacity(opacity: 0.45)` + `TextDecoration.lineThrough` |
| 취소 (cancelled 계열) | **opacity 0.45 + 취소선** | 동일 |
| 노쇼/결석 | 정상 + accent 색상 강조 | paperAccent 세로선 |

**UX 근거**: 선생님의 시선은 "다음에 해야 할 것"에 집중해야 함. 완료/취소된 항목이 같은 시각 무게로 표시되면 스캔 비용 증가 → Hick's Law 위반.

#### 1.2.1 NotebookTypography — 자필·악보 시그니처 (Notebook × Score)

> 파일: `lib/core/theme/notebook_typography.dart`
> 폰트: Gaegu (자필) / Playfair Display (악보 헤더) / IBM Plex Mono (시간·템포)

| 토큰 | 폰트 | 용도 |
|------|------|------|
| `hand` | Gaegu 16 | **사람의 액션 산출물 일체**: 선생님 피드백 입력/표시, 학생 메모 입력/표시, 연습노트 본문, 곡 메모, 연습 과제 제목·설명, 레퍼토리·곡명 입력, 일괄 피드백 입력/미리보기 — TextField input style 도 포함 (§7.129, §7.130) |
| `handOk` | Gaegu 13 / paperOk | 자필 완료 마크 ("✓ 보잉 좋음") |
| `indicatorLabel` | Pretendard 11 italic | 시스템 자동 인디케이터 ("오늘", "D-N", "입금대기(후불)") |
| `pieceTitle` | Playfair w700 | 곡 제목, 카드 헤더 |
| `sectionTitle` | Playfair italic | 섹션 헤더 |
| `roman` / `romanActive` | Playfair italic | 로마숫자 인덱스 |

**4계층 결정 트리**: "이 텍스트의 작성 주체는 누구인가?" → 사람=자필(Tier 1·2), 시스템=인쇄체(Tier 3·4).

**§7.130 이항 룰**: "사람의 액션 산출물 = hand, 시스템 정의 라벨/카운트/식별자 = sans-serif." 모호하면 4계층으로.

상세 가이드 + 회피 신호 + Tier 3 안내문 매트릭스 → `docs/specs/design/notebook/README.md` §1.1.1.

### 1.3 간격 (AppSpacing)

> 파일: `lib/core/theme/app_spacing.dart`
> 체계: 4pt 기반

| 토큰 | 값 | 용도 |
|------|-----|------|
| `space1` | 4 | 최소 간격 |
| `space2` | 8 | 요소 내부 |
| `space3` | 12 | 요소 간 |
| `space4` | 16 | 섹션 내부 (= `screenPadding`, `cardPadding`) |
| `space5` | 20 | |
| `space6` | 24 | 섹션 간 (= `sectionSpacing`) |
| `space8` | 32 | 큰 섹션 간 |

| 레이아웃 | 토큰 | 값 |
|----------|------|-----|
| 화면 좌우 패딩 | `screenPadding` | 16 |
| 카드 내부 패딩 | `cardPadding` | 16 |
| 섹션 간 간격 | `sectionSpacing` | 24 |
| 버튼 높이 | `buttonHeight` | 48 |
| 입력 높이 | `inputHeight` | 48 |
| 라운딩 | `radiusSmall/Medium/Large/XLarge` | 4/8/12/16 |

> **§7.117 각진 시그니처**: Notebook x Score 적용 후 테마 기본값은 `BorderRadius.zero`. Card/Button/Dialog/BottomSheet/Input/SnackBar 모두 직각. `radiusSmall` 등은 아바타, 프로그레스바 등 일부 특수 컴포넌트에서만 사용.

**금지**: `EdgeInsets.all(16)` 대신 `EdgeInsets.all(AppSpacing.space4)` 사용.

---

## 2. 핵심 UX 원칙

### 2.1 3가지 황금 규칙

| 원칙 | 설명 |
|------|------|
| **원클릭** | 핵심 작업은 한 번 탭으로 완료. 불필요한 확인 다이얼로그 제거 |
| **얕은 뎁스** | 모든 기능 2탭 이내 도달 (홈 → 상세 끝) |
| **재사용** | 동일 컴포넌트를 역할별로 다르게 표시 |

### 2.2 타겟 사용자

```
"음악인은 IT에 관심이 적으므로 최대한 심플하면서 효율적으로"
```

- 직관적 UI (설명 없이 이해)
- 충분한 터치 영역
- 3초 내 원하는 화면 도달
- 기술 용어 금지 (동기화 → 새로고침, NULL → 없음)

### 2.3 정보 우선순위

```
1순위: 긴급 (paperAccent) — 입금 기한 초과 D+, 승인 대기
2순위: 오늘 — 당일 레슨/과제
3순위: 트렌드 — 스트릭, 주간 연습, 월간 레슨
4순위: 도구 — 메트로놈, 튜너, 녹음
```

### 2.4 액션 라벨 규칙 (취소/닫기)

문맥에 따라 버튼 라벨을 분리한다.  

- **닫기**: 팝업/시트/모달을 단순히 닫거나 현재 기능 진입점을 종료할 때 사용한다.
  - 예: 안내 팝업 닫기, 폼 닫기, 바텀시트 닫기, 화면 나가기 전 확인 없이 나가기
- **취소**: 사용자가 의도한 비즈니스 액션 자체를 되돌리거나 철회할 때 사용한다.
  - 예: 요청 취소, 제안 취소, 변경 제안 취소, 등록/저장 전 임시 입력 되돌리기
- 동일 UI 안에서 `dismiss` 동작과 `action cancel`이 동시에 존재하면 라벨을 분리해서 표시한다.
  - 예: `[닫기]` + `[취소 요청]`, `[다시 선택]` + `[요청 취소]`

검증 규칙:
- 오버레이의 주된 동작이 **열기/마감/종료**일 때는 `취소` 대신 `닫기`를 우선 사용한다.
- `취소` 라벨은 실제로 상태가 바뀌는 **의도된 취소 액션**에서만 사용한다.
- 스펙/컴포넌트 문서에 `취소`가 클로즈 목적으로 쓰일 여지가 있으면 반드시 라벨 재작성한다.

변경 이력:
| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.1 | 2026-05-08 | "닫기"와 "취소" 의미 분리 규칙 추가 |

### 2.5 긴급도 색상 규칙

| 긴급도 | 색상 토큰 | 표시 |
|--------|----------|------|
| 긴급 (기한 초과) | `paperAccent` | D+3 (Vermillion) |
| 경고 (7일 이내) | `paperAccent` | D-5 (Vermillion — 2색 체계로 경고/긴급 통합) |
| 주의 (임박) | `inkSecondary` | 2회 남음 |
| 정상 | `inkTertiary` | 기본 표시 |

### 2.6 긴급 알림 Top 1 정책 (2026-04-16)

**원칙**: 홈 화면 긴급 알림은 최상위 1건만 표시. 나머지는 Expandable.

| 알림 수 | 표시 방식 |
|:---:|------|
| 0건 | 섹션 숨김 |
| 1건 | 단일 카드 |
| 2+건 | Top 1 + "외 N건 ▼" |

**근거**: 토스 홈 패턴 — 사용자 인지 부하 감소. 5가지 알림 동시 표시는 과부하.

**Top 1 결정 우선순위**: 입금대기(후불) 관리 > 입금 확인 필요 > 만료 > 갱신 예정 > 확인 필요 > 예약 대기

### 2.6 Progressive Disclosure (점진적 공개)

**원칙**: 초기에는 요약 N개만 노출. "전체보기"로 확장.

| 섹션 | 기본 노출 | 확장 |
|------|:---:|------|
| 오늘 레슨 | 5건 | "전체보기 (N건 더)" |
| 레슨 요청 | 3건 | "전체보기" |
| 스케줄 변경 | 3건 | "전체보기" |
| 과제 미완료 | 3명 | "전체보기" |

**근거**: 네이버 예약 "다가오는 예약" 패턴. 하루 10+ 레슨 선생님의 홈 압박 방지.

### 2.7 스파크라인 가이드라인

**용도**: 7일 연습 추이를 미니 막대 그래프로 시각화. 학생 상세/연습 화면처럼 연습 맥락이 주 목적인 화면에 한정한다.

**수강관리 리스트 제외**: 수강관리 학생 리스트 카드는 수강권·입금·만료 판단을 우선하므로 연습 스파크라인과 `N/7일` 요약을 노출하지 않는다.

| 규칙 | 값 |
|------|-----|
| 기본 기간 | 최근 7일 |
| 막대 수 | 7개 고정 |
| 색상 | 평균 수준별 🟢🟡🔴 (2.4 긴급도 색상 규칙 참조) |
| 클릭 | 해당 학생 연습 상세 또는 연습 화면으로 이동 |

**구현**: `PracticeSparkline` 위젯 — 높이 16px, 너비 60-80px

---

## 3. 공통 컴포넌트 패턴

### 3.1 공통 위젯 (`core/widgets/`)

> **원칙**: 새 위젯 작성 전 반드시 기존 위젯 확인. 있으면 재사용.

| 위젯 | 용도 |
|------|------|
| `WeekCalendarWidget` | 주간 캘린더 (연습/레슨/예약) |
| `StatCard` | 통계 카드 |
| `QuickToolButton` | 빠른 도구 버튼 |
| `PracticeCenterButton` | 연습 센터 버튼 |
| `EmptyStateWidget` | 빈 상태 UI |
| `selectors/LessonCountSelector` | 레슨 횟수 선택 |
| `selectors/LessonDurationSelector` | 수업 시간 선택 |
| `selectors/ValidityPeriodSelector` | 유효기간 선택 |
| `selectors/DiscountPercentSelector` | 할인율 선택 |
| `selectors/BonusCountSelector` | 보너스 횟수 선택 |

### 3.2 카드 레이아웃

**이벤트 카드** (시간 기반):
```
┌─────────────────────────────────────────────┐
│ ┃  14:00     김지수 · 피아노       예정   > │
│ ┃  50분      모차르트 소나타...            │
└─────────────────────────────────────────────┘
  ↑   ↑(48px)     ↑(Flexible)    ↑(72px)  ↑
  바   시간        정보            상태   화살표
```

**엔티티 카드** (사람/객체):
```
┌─────────────────────────────────────────────┐
│ (아바타) 김지수 [학원]                       │
│          피아노 · 8회 남음                   │
│          매주 토 14:00       ●●●●○○       > │
└─────────────────────────────────────────────┘
```

**카드 스타일 코드**:
```dart
NotebookCard(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    child: ...
  ),
)
```

Notebook x Score 표면은 평면 종이 계약을 따른다. 카드에 그림자나 elevation을 추가하지 않고, 구분이 필요하면 `AppColors.inkQuaternary` 1px border 또는 `ThinRule`을 사용한다.

### 3.3 버튼 패턴

| 용도 | 위젯 | 스타일 (테마 기본값) |
|------|------|--------|
| 주요 액션 (CTA) | `FilledButton` | `backgroundColor: paperAccent`, `foregroundColor: paper` |
| 보조 액션 | `OutlinedButton` | `side: BorderSide(color: ink)`, `foregroundColor: ink` |
| 위험 액션 | `FilledButton` | `backgroundColor: paperAccent` (CTA와 동일 — 2색 체계) |
| 텍스트 액션 | `TextButton` | `foregroundColor: ink` |
| Elevated 버튼 | `ElevatedButton` | `backgroundColor: ink`, `foregroundColor: paper` |

> 모든 버튼은 `BorderRadius.zero` (§7.117 각진 시그니처). `radiusMedium`/`radiusLarge` 등 둥근 모서리 금지.

### 3.4 상태 뱃지 색상

| 상태 | 배경 | 텍스트 |
|------|------|--------|
| 활성/수강중 | `paperAccentSoft` | `paperAccent` |
| 완료 | `paperOk` (alpha 적용) | `paperOk` |
| 경고/만료임박/긴급 | `paperAccentSoft` | `paperAccent` |
| 오류/입금 기한 초과 | `paperAccentSoft` | `paperAccent` |
| 비활성 | `paperDark` | `inkTertiary` |

### 3.5 선택자 칩 스타일

| 상태 | 배경 | 테두리 | 텍스트 |
|------|------|--------|--------|
| 비선택 | `paperDark` | `inkQuaternary` | `ink` |
| 선택됨 | `paperAccentSoft` | `paperAccent` | `paperAccent` (bold) |

### 3.6 피드백 패턴

| 액션 | 피드백 |
|------|--------|
| 저장 성공 | 하단 토스트 "저장되었습니다" (2초) |
| 삭제 성공 | 하단 토스트 + 되돌리기 |
| 에러 | 빨간 토스트 + 재시도 버튼 |
| 로딩 | `CircularProgressIndicator` |
| 빈 상태 | `EmptyStateWidget` (아이콘 + 안내 + CTA) |

---

## 4. 네비게이션

### 4.1 메인 탭

| 역할 | 탭 1 | 탭 2 | 탭 3 | 탭 4 |
|------|------|------|------|------|
| 선생님 | 홈 | 학생 | 일정 | 설정 |
| 학생 | 홈 | 연습 | 레슨 | 설정 |
| 학부모 | 홈 | 자녀 | 결제 | 설정 |

### 4.2 메뉴 배치

| 빈도 | 배치 |
|------|------|
| 매일 | 메인 탭, 홈 대시보드 |
| 주 1회 | 상세 화면 내부 |
| 월 1회 | 별도 탭 또는 설정 |
| 가끔 | 설정 메뉴 |

### 4.3 상세 화면 헤더 (NotebookDetailAppBar) — 2026-05-09

> **모든 뒤로가기가 필요한 상세 화면**의 헤더는 동일한 컨셉으로 작성한다.
> 일관성이 최우선.

```
──────────────────────────────────────
 [←] 주제                    [+] [⋮]
──────────────────────────────────────  ← bottom border (ink 15%)
```

**공통 위젯**: `core/widgets/notebook/notebook_detail_app_bar.dart`

#### Leading (왼쪽)

| 타입 | 아이콘 | 용도 |
|------|--------|------|
| `back` (기본) | `←` arrow_back | 일반 탐색 (상세 → 목록) |
| `close` | `×` close | 편집/생성 화면 (저장 안 하고 닫기) |

#### Actions (오른쪽) — enum 기반

| 액션 | 아이콘 | 용도 예시 |
|------|--------|----------|
| `add` | `+` add | 항목 추가 |
| `edit` | edit_outlined | 편집 모드 진입 |
| `delete` | delete_outline | 삭제 (편집 모드) |
| `share` | share_outlined | 공유 |
| `more` | **more_vert (⋮ 세로)** | 메뉴 (가로 ··· 금지) |
| `settings` | settings_outlined | 설정 |
| `filter` | filter_list | 필터 |
| `search` | search | 검색 |
| `copy` | copy_outlined | 복사 |
| `history` | history | 이력 |

**TextButton ("저장" 등)**: `customActions` 파라미터 사용
**PopupMenuButton**: `customActions`에 직접 전달 (아이콘은 반드시 `Icons.more_vert`)

#### 적용 대상 / 제외

| 대상 | 제외 |
|------|------|
| push navigation 상세 화면 (~65개) | 메인 탭 화면 (home, schedule_tab 등) |
| 편집/생성 화면 (close leading) | SliverAppBar (teacher_detail, academy_detail) |
| 설정 하위 화면 | 로그인/온보딩 (별도 플로우) |
| | 팝업/바텀시트/다이얼로그 |

#### 금지

- `Icons.more_horiz` (가로 ···) → 반드시 `Icons.more_vert` (세로 ⋮)
- `backgroundColor: AppColors.paperDark` 수동 설정 → 테마 상속
- `elevation` 수동 설정 → 테마 상속
- `leading: IconButton(Icons.arrow_back, ...)` 수동 배치 → NotebookDetailAppBar 사용

---

## 5. 역할별 화면 재사용

| 구분 | 선생님 | 학부모 | 학생 |
|------|--------|--------|------|
| 데이터 권한 | 읽기/쓰기 | 읽기 전용 | 본인만 읽기/쓰기 |
| 과제 | 생성/수정 | 열람 | 완료 체크 |
| 결제 | 청구서 발행 | 결제 | 열람 |

**읽기 전용 표시**: 눈 아이콘 + 체크박스 비활성화 (회색)

---

## 6. 도메인별 UI 규칙

### 6.1 수강권 카드

#### 6.1.1 3색 잉크 체계 (Notebook × Score 만년필 잉크 메타포)

수강권 타입별로 만년필 잉크 색을 달리하여 종이 위 수강 기록의 성격을 한눈에 식별한다.

| 수강권 타입 | 토큰 | HEX | 잉크 이름 | 감성 |
|------------|------|-----|----------|------|
| 체험레슨 (trial) | `paperTrial` | `#C4923A` | 세피아 앰버 | 호기심 · 첫 만남 |
| 정기권 (monthly) | `paperOk` | `#3F5D2F` | 녹색 펜 | 안정 · 꾸준 |
| 회차권 (package) | `paperAccent` | `#9B1B12` | 버밀리온 | 매회 출석 체크 |

> 상세 토큰 정의: `docs/specs/design/notebook/README.md` §2.1

#### 6.1.2 SubscriptionCard 통합

`SubscriptionTicketCard`는 삭제되었다. `SubscriptionCard` 하나가 두 모드를 제공한다.

| 모드 | 파라미터 | 용도 | 특징 |
|------|---------|------|------|
| 티켓 | `compact: true` | 리스트 아이템, 홈 배너 | 1줄 요약 (학생명·악기), 잉크 색 좌측 액센트 라인. 수강 기간 표시 없음 |
| 상세 | `compact: false` | 수강권 상세 화면 | 프로그레스바 포함, 전체 메타 표시 |

- compact 헤더 배경색 제거됨 — paper 배경만 사용 (Notebook 평면 원칙)
- compact 모드에서 수강 기간(예: 2026.02~07) 표시 삭제됨 — `_formatCompactPeriod` 메서드 제거
- 헤더 액센트 라인 및 프로그레스바 색상은 수강권 타입에 따라 3색 잉크 토큰 자동 매핑
- 갱신 제안 수동 UI 삭제됨 — `onRenewalTap` 파라미터 제거. 갱신 제안은 `AutoProposalService`/`ProposalReminderService`/`SubscriptionRenewalService`가 자동 처리

#### 6.1.3 잔여/만료 경고

**잔여 경고**: ≤25% `paperAccent` | ≤2회 `paperAccent` | =1회 `paperAccent` (강조)
**만료 경고**: ≤7일 `paperAccent` | ≤3일 `paperAccent` (강조)

### 6.2 레슨 유형 구분

| 유형 | 아이콘 | 색상 |
|------|--------|------|
| 개인 레슨 | Icons.music_note | `ink` |
| 그룹 레슨 | Icons.groups | `inkSecondary` |

### 6.3 예약 슬롯 색상

> 스케줄 슬롯은 도메인 특수 색상(`slotAvailable` 등)을 사용. `app_colors.dart` 참조.

| 상태 | 색상 토큰 |
|------|----------|
| 예약 가능 | `slotAvailable` |
| 내 예약 | `slotMyBooking` |
| 거의 만석 | `slotAlmostFull` |
| 만석 | `paperAccent` |
| 예약 불가 | `slotUnavailable` |

### 6.4 레슨 상태 색상

| 상태 | 색상 토큰 |
|------|----------|
| 예정 | `ink` |
| 완료 | `paperOk` |
| 취소 | `inkTertiary` |
| 결석 | `paperAccent` |

---

## 7. Claude 체크리스트

### UI 구현 전

```
- [ ] 기존에 유사한 화면/패턴이 있는가? → 있으면 동일 패턴 사용
- [ ] 공통 위젯(core/widgets/)으로 해결 가능한가?
- [ ] 다르게 구현하려면 사용자 동의 받았는가?
```

### UI 구현 중

```
- [ ] 색상: AppColors만 사용 (하드코딩 금지)
- [ ] 타이포: AppTypography만 사용 (fontSize 직접 금지)
- [ ] 간격: AppSpacing만 사용 (EdgeInsets 숫자 직접 금지)
- [ ] 빈 상태: EmptyStateWidget 사용
- [ ] 로딩: CircularProgressIndicator 사용
- [ ] 피드백: 토스트로 성공/실패 알림
```

### UI 구현 후

```
- [ ] flutter analyze 경고 없음
- [ ] 다른 화면과 레이아웃 일관적인가?
- [ ] 2탭 이내 도달 가능한가?
- [ ] 헤더에 + 액션이 있으면 바디 동일 add CTA 중복이 없는가?
```

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-28 | 초안 작성 |
| 2026-01-27 | 수강권 UI, 슬롯 색상, 인터랙션 패턴 추가 |
| 2026-02-02 | 리스트 카드 디자인 패턴 추가 |
| 2026-03-07 | **v3 전면 개편** — 디자인 토큰 중심 재구성, AppColors/Typography/Spacing 통합 가이드, 불필요한 중복 제거, Claude 체크리스트 간소화 |
| 2026-04-16 | 긴급 알림 Top 1 정책, Progressive Disclosure 원칙, 스파크라인 가이드라인 추가 (§2.5~2.7) |
| 2026-05-04 | **Notebook x Score 팔레트 마이그레이션 반영** — 레거시 토큰(primary/success/warning/error/info/surfaceLight/borderLight/textPrimaryLight 등) 제거, Notebook 팔레트(paper/ink/paperAccent/paperOk) 기준으로 전면 갱신. 카드·버튼·뱃지·칩·긴급도 색상 규칙 모두 현행 코드와 동기화. 버튼 BorderRadius.zero 시그니처 반영 |
| 2026-05-04 | **수강권 3색 잉크 체계 추가** — `paperTrial`/`paperTrialSoft` 토큰, §6.1 수강권 카드 섹션에 3색 잉크 체계(trial=세피아, monthly=녹색, package=버밀리온) 및 `SubscriptionCard(compact)` 통합 문서화 |
| 2026-05-09 | 헤더 + 액션 우선 규칙: 동일 엔티티 add 액션은 헤더에서만 노출하고 바디 중복 CTA를 제거한다 |
| 2026-05-09 | **§4.3 상세 화면 헤더 통일** — `NotebookDetailAppBar` 공통 위젯 + 적용 규칙. 모든 상세 화면 헤더 일관성 (back/close leading, enum 기반 actions, bottom border). `Icons.more_vert` (세로 ⋮) 통일, `more_horiz` 금지 |
| 2026-05-05 | **회계식 기존 표현 → "입금대기(후불)" 용어 변경** — 회계/채권 뉘앙스를 줄이고 후불 발급 상태를 명확히 드러내도록 통일. indicatorLabel 예시, Top 1 우선순위 라벨 갱신. **갱신 제안 수동 UI 삭제** — 자동 서비스(AutoProposal/ProposalReminder/SubscriptionRenewal)로 대체, `onRenewalTap` 제거. **SubscriptionCard compact 기간 표시 삭제** — `_formatCompactPeriod` 제거 |
