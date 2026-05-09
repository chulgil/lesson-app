# Notebook × Score 디자인 게이트 — 신규 화면 필수 준수

> 모든 신규 화면은 Notebook × Score 디자인 시스템을 따라야 한다.
> 스펙: `docs/specs/design/notebook/README.md`

## 필수 사항 (HARD-GATE)

### 1. Scaffold
- `Scaffold` 직접 사용 금지 → `NotebookScreenScaffold` 사용
- 배경색: `AppColors.paper` (기본값)

### 2. AppBar / 헤더
- `AppBar` 직접 사용 금지 → `NotebookDetailAppBar` 또는 `NotebookMasthead` 사용
- 탭 화면: `NotebookMasthead` (eyebrow + meta + trailing)
- 상세 화면: `NotebookDetailAppBar` (title + actions)

### 3. 색상 (3색 이하 원칙)
- 본문: `AppColors.ink` / `inkSecondary` / `inkTertiary`
- 배경: `AppColors.paper` / `paperDark`
- 액센트: `AppColors.paperAccent` (1가지만)
- **금지**: `Colors.white`, `Colors.blue`, `profilePurple`, `amber` 등 다색 사용
- **금지**: `color.withOpacity(0.08)` 같은 임의 투명도 배경 → `paperAccentSoft` 또는 `paperDark` 사용

### 4. 테두리 / 모서리
- `borderRadius` 금지 → 직선(0) 또는 `RoundedRectangleBorder()` (기본 직각)
- `BoxDecoration(border:)` → `Border.all()` 또는 방향별 `Border()` 사용
- 구분선: `ThinRule()` 위젯 사용

### 5. 아이콘 — 시그니처 영역
- 시그니처 영역: `NotebookGlyph` 사용 (체크 ✓, 별 ★, 점 ●, 화살표 → 등)
- 일반 영역: Material Icons 허용하되, `_rounded` / `_sharp` 접미사 아이콘 사용 자제
- `Icons.workspace_premium_rounded` 같은 장식적 아이콘 금지

### 6. 버튼
- `shape: const RoundedRectangleBorder()` — 직선 모서리 필수
- 배경색: `AppColors.paperAccent` (primary action) / `inkQuaternary` border (secondary)
- **금지**: `backgroundColor: accentColor` 같은 다색 버튼

### 7. 타이포그래피
- `Theme.of(context).textTheme` 금지 → `AppTypography.*` 또는 `NotebookTypography.*` 사용
- 제목: `NotebookTypography.sectionTitle`
- 본문: `AppTypography.bodyMedium`
- 캡션: `AppTypography.captionSmall`

### 8. 바텀시트
- `showModalBottomSheet` 금지 → `showNotebookModalBottomSheet` 사용
- 배경: paper, 직선 모서리

## 검증 grep 패턴

```bash
# Scaffold 직접 사용 (NotebookScreenScaffold 미사용)
grep -rn "return Scaffold(" --include="*.dart" features/billing/

# AppBar 직접 사용
grep -rn "AppBar(" --include="*.dart" features/billing/ | grep -v "NotebookDetailAppBar\|NotebookMasthead"

# borderRadius 사용
grep -rn "borderRadius:" --include="*.dart" features/billing/ | grep -v "BorderRadius.zero\|RoundedRectangleBorder()"

# Colors.white 사용
grep -rn "Colors.white" --include="*.dart" features/billing/

# Theme.of(context).textTheme 사용
grep -rn "Theme.of(context).textTheme" --include="*.dart" features/billing/

# showModalBottomSheet 직접 사용
grep -rn "showModalBottomSheet" --include="*.dart" features/billing/ | grep -v "showNotebookModalBottomSheet"
```

## 적용 범위

- `features/*/presentation/screens/*.dart` — 모든 신규 화면
- `features/*/presentation/widgets/*.dart` — 모든 신규 위젯
- 기존 화면 수정 시에도 위반 사항 발견 시 즉시 수정

## 자동 감지

- `.claude/hooks/check-notebook-design.sh` — PostToolUse 훅 (Edit/Write)
- 신규 screen/widget 파일에서 `Scaffold(`, `AppBar(`, `borderRadius`, `Colors.white`, `Theme.of` 패턴 감지
- stderr 경고, exit 0 (advisory)
