# §7.117 테마 전수 각진화 — Notebook × Score Theme Layer Saturation

> 작성일: 2026-04-24
> 모드: `/plan --ceo` → 10x Vision 확정
> 사용자 결정: BottomSheet·FAB·Dialog 모두 각진

## 배경

§7.113~115 각진 원칙이 위젯 레벨(`Container`, `BoxDecoration`, `OutlineInputBorder`)만 적용 → Flutter 테마의 FilledButton/ElevatedButton/OutlinedButton/Card/Dialog/BottomSheet/Input/Popup/Dropdown/DatePicker/TimePicker/SnackBar/Checkbox 가 여전히 `radiusLarge (20px)` / `radiusMedium (8px)` / `radiusSmall (4px)` 로 라운드 처리. 첫인상 "Material 앱" 회귀 지속.

## Phase 1: app_theme.dart 테마 단일 지점 전환 (light + dark)

| 대상 | 현재 | 변경 |
|------|------|------|
| elevatedButtonTheme | radiusLarge | **zero** |
| filledButtonTheme | radiusLarge | **zero** |
| outlinedButtonTheme | radiusLarge | **zero** |
| cardTheme | radiusLarge | **zero** |
| dialogTheme | radiusLarge | **zero** |
| bottomSheetTheme (top) | radiusLarge | **zero** |
| inputDecorationTheme (4 borders) | radiusMedium | **zero** |
| popupMenuTheme | 4px | **zero** |
| dropdownMenuTheme | 4px | **zero** |
| datePickerTheme | 8px | **zero** |
| timePickerTheme + hourMinuteShape | 8px / 4px | **zero** |
| snackBarTheme | radiusMedium | **zero** |
| checkboxTheme | radiusSmall | **zero** |
| floatingActionButtonTheme | StadiumBorder 기본 | `shape: RoundedRectangleBorder(zero)` 명시 |

예외 (§7.113 원형 매트릭스 유지):
- CircleAvatar · BoxShape.circle · 웰컴 waving_hand · 이모지 가족 bg · now-indicator dot

## Phase 2: 인라인 shape override 감사 (141 지점)

grep 으로 `shape: RoundedRectangleBorder(BorderRadius.circular(...))` 141 지점 전수 검토:
- 유지 카테고리: FAB·avatar·chip·이모지·ticket/pill 은유
- 잔재 제거: 스케줄·학생·수강권·연습 도메인의 테마 override 가 아닌 것

목표: 제거 가능한 지점을 zero 로 전환. Flutter 속성 우선순위로 인라인 override 는 테마 뒤 — Phase 1 만으로도 회귀 0 보장.

## Phase 3: §7.117 스펙 문서화

`docs/specs/design/notebook/README.md` 에 §7.117 섹션 추가:
- app_theme 기본 shape 는 `BorderRadius.zero`
- 예외 카테고리 명문화
- Lore-directive: 테마 단일 지점 각진이 §7.113~115 포화의 종착점

## Phase 4: 검증 + 커밋

1. `flutter analyze --no-pub` 통과
2. 수동 실기 확인 안내 (홈 · 학생 추가 · 다이얼로그 · 레슨 상세 4개 스폿)
3. 커밋 분할:
   - `feat(notebook): §7.117 Phase 1 — app_theme 테마 전수 각진화`
   - `feat(notebook): §7.117 Phase 2 — 인라인 shape override 감사`
   - `docs(notebook): §7.117 스펙 추가`

## 리스크

| 리스크 | 완화 |
|-------|------|
| 141 인라인 override 미분류 시 시각 회귀 | Flutter 속성 우선순위로 인라인이 테마 위 — 회귀 0 |
| flutter analyze 는 시각 검증 못함 | 실기 확인 (`flutter run` 스폿 체크) |
| Dialog 완전 각진이 OS 네이티브 감성에 이질적 | 사용자 결정 "각진" 확정 |

## 복잡도 총합

- Phase 1: 30분
- Phase 2: 1시간 (141 지점 스캔)
- Phase 3: 20분
- **총 2시간**
