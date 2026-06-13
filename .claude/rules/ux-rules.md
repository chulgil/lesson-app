# UX 규칙 — 반복 위반 방지

> lessons-learned.md에서 UX 관련 교훈을 분리. 에이전트가 구현 시 자동 참조.
> 상세 디자인 토큰/컴포넌트: `docs/specs/design/ux_guidelines.md`

## 코딩 전 필수 조회 (HARD-GATE)

1. `AppColors` 클래스 → 색상 확인 (없으면 상수 추가)
2. `AppStrings` 클래스 → UI 텍스트 상수 사용 (하드코딩 금지, 다국어 대비)
3. `core/utils/` → 기존 유틸 사용 (NameUtils, date_format_utils 등)
4. `core/widgets/` → 기존 공통 위젯 확인

**공통 유틸 필수 사용:**
- 이름: `NameUtils.givenName()` | 날짜: `formatDateYMD()` | 악기색상: `InstrumentColors.getColor()`
- 스케줄 뮤트: `AppColors.scheduleMutedBackground`, `AppColors.scheduleMutedAccent`

**원샷 UX**: 한 번 탭으로 모든 연관 작업 완료 → [UX 가이드라인](docs/specs/design/ux_guidelines.md)

## 색상 규칙

- **AppColors만 사용** — `Color(0x...)` 하드코딩 절대 금지 (#6)
- **3색 이하 원칙** — 한 화면에서 semantic color(success/warning/error) 3종 이상 동시 사용 금지. stat 카드는 primary 단색 통일 (#14)
- **멀티 뷰 색상 일관성** — 같은 데이터를 보여주는 뷰(주간/일간)에서 색상 규칙이 동일해야 함. 새 뷰 추가 시 기존 뷰 grep 필수 (#17)

## 위젯 재사용

- **공통 위젯 우선** — `core/widgets/` 에 유사 위젯이 있으면 반드시 재사용. 새로 만들기 전 기존 확인 필수
- **AppTypography만 사용** — `fontSize: N` 직접 사용 금지
- **AppSpacing만 사용** — `EdgeInsets.all(16)` 대신 `EdgeInsets.all(AppSpacing.space4)`

## 메뉴/진입점 규칙

- **중복 메뉴 금지** — 프로필 탭에 수정 + 메뉴 안에 또 수정 = 중복. 하나로 통합 (#9, #19)
- **같은 행동 → 하나의 CTA** — "수강권 임박"과 "수강권 만료"처럼 상태는 다르지만 행동(재발급)이 같으면 통합 (#16)
- **관련 정보 한곳 관리** — 설정이 3개 이상 화면에 분산되면 단일 스크롤로 통합 검토 (#9)

## 인터랙션 규칙

- **얕은 뎁스** — 모든 기능 2탭 이내 도달
- **원클릭** — 핵심 작업은 한 번 탭으로 완료
- **스와이프 액션 4원칙 (HARD-GATE, 2026-06-13 방향+tone)** — 반복 리스트의 행 단위 액션은 다음 4원칙을 따른다. trailing 아이콘 버튼/PopupMenuButton 과 중복 배치 금지.
  1. **우→좌 관리 액션은 맥락별 1개** — 행 성격에 맞춰 삭제(`SwipeActionTone.destructive`) **또는** 편집(`normal`) 중 하나. 한 방향에 2개 이상 금지.
  2. **양방향 최대 2개, 초과 시 BottomSheet** — 우→좌 관리 1 + 좌→우 편의 1 까지만 swipe. 3개 이상이거나 양쪽으로 안 떨어지는 묶음은 행 탭 → `showModalBottomSheet` 안에 `ListTile` 로 나열.
  3. **모든 destructive 는 확인 다이얼로그** — `showDialog<AlertDialog>` 로 확인 받기. 영향도가 있으면 강화 메시지 ("계좌 삭제 시 학생 결제 표시에서 사라집니다" + 영향 카운트). Undo SnackBar 단독 금지. 편의·편집은 즉시 실행.
  4. **방향 + tone (3색 잉크)** — 우→좌=관리(삭제 `destructive` 버밀리온 / 편집 `normal` ink), 오른쪽 노출. 좌→우=편의(`convenience` 녹색 `paperOk`), 왼쪽 노출 — 없으면 단방향. 두 방향 의미는 전 화면 공통.
  - **예외**: 자녀/관계 같은 메타포상 destructive 부적절한 카드는 swipe 적용하지 않음 — BottomSheet 다중 액션만.
  - 스펙: `docs/_components/swipe_action.md` (4원칙 + tone 3종 + 코드 예시 + 도메인별 편의 매핑)
  - audit: `docs/specs/_audits/2026-06-10-swipe-action-consistency-audit.md`
- **Hick's Law** — 하루 10회+ 반복 인터랙션은 선택지 1개. 뉘앙스 필요 시 텍스트 입력 (#22)
- **플레이스홀더 UI 금지** — 미구현 기능의 UI 요소는 코드에서 제거. "Phase N에서 구현 예정"은 스펙에만 명시 (#15)
- **NO-OP 버튼 금지** — 탭해도 아무 일도 안 일어나는 버튼은 앱 신뢰 하락 (#4, #15)

## 레이아웃 규칙

- **Row 카드 수 고정** — 조건부 카드가 Row를 깨트리면 별도 배너로 분리 (#13)
- **BoxDecoration border** — 0.5px OVERFLOW 유발하므로 별도 Container(height: 0.5)로 분리 (#5)

## 검증 grep 패턴

```bash
# 하드코딩 색상 검출
grep -rn "Color(0x" --include="*.dart" features/

# fontSize 직접 사용
grep -rn "fontSize:" --include="*.dart" features/ | grep -v "AppTypography"

# EdgeInsets 숫자 직접
grep -rn "EdgeInsets\." --include="*.dart" features/ | grep -v "AppSpacing"

# 빈 상태 위젯 미사용
grep -rn "Text('데이터가 없습니다')" --include="*.dart" features/

# 하드코딩 UI 텍스트 (AppStrings 미사용) — /auto, /plan 완료 후 필수 실행
# 한글 문자열이 Text() 또는 label/hint 파라미터에 직접 사용된 경우 검출
grep -rn "Text('[가-힣]" --include="*.dart" features/
grep -rn "label: '[가-힣]\|hint.*'[가-힣]" --include="*.dart" features/

# NO-OP 콜백
grep -rn "onTap: () {}" --include="*.dart" features/
grep -rn "onPressed: null" --include="*.dart" features/

# 반복 리스트의 trailing 편집/삭제 버튼 후보. SwipeActionTile 적용 검토
grep -rn "Icons\\.edit\\|Icons\\.delete" --include="*.dart" features/ | grep -E "Tile|Card|List"

# 액션 박스 하드코딩 메시지 (AppStrings 미사용)
grep -rn "message: '[가-힣]" --include="*.dart" features/

# 테마 minWidth=∞ × 컴팩트 배치 크래시 감지 — Align/Row-end/Wrap 내부 버튼에 minimumSize override 없음
# 훅(check-button-compact-layout.sh)이 자동 검출하나 수동 회귀 grep
grep -rn -B 3 -A 5 "FilledButton\|ElevatedButton\|OutlinedButton" --include="*.dart" features/ \
  | grep -E "(Align\(|mainAxisAlignment.*\.end|Wrap\()" | head
```

## 레이아웃 크래시 방지 (HARD-GATE)

- **모든 top-level 위젯은 widget smoke test 필수** — `Screen|Page|Tab|Widget|Stamp|Card|Bar|Sheet|Dialog|Masthead|Header|Section|View` 접미사를 가진 클래스를 신규 추가/변경할 때, `flutter analyze` 가 `RenderBox`/`RenderMetaData`/`BoxConstraints` 류 런타임 크래시를 잡지 못한다. 따라서 다음을 필수 작성:
  - 위치: `test/.../<snake_name>_test.dart` (또는 `_layout_test.dart`/`_smoke_test.dart`/`_widget_test.dart`)
  - 최소: `testWidgets` 1개 — `pumpWidget(MaterialApp(home: ...))` + `pumpAndSettle()` + `expect(tester.takeException(), isNull)`
  - 권장: Row/Column/Expanded 등 좁은 제약 컨텍스트에서 렌더 회귀 케이스 1건
  - 의도적 예외: 클래스 정의 위 줄 `// ignore: widget-smoke-test` 주석 + 사유 필수
  - 자동 감지: `.claude/hooks/check-widget-smoke-test.sh` 가 신규 위젯 도입 시 누락 경고
  - 사례: 2026-04-24 수강관리 탭 BoxConstraints 재발 / 2026-04-29 §7.133 LikeStamp `RenderMetaData` 회귀
- **컴팩트 버튼 배치 규칙** — 트레일링/인라인 FilledButton/ElevatedButton/OutlinedButton 은 반드시 `styleFrom(minimumSize: Size(0, AppSpacing.buttonHeight))` override. 테마가 `Size(∞, h)` 인데 Row/Align/Wrap 은 loose 폭을 주기 때문 → [tech-patterns.md](tech-patterns.md#flutter-레이아웃) 참조

## 상세 화면 일관성 규칙 (HARD-GATE)

> 프로그레스바+챗+하단액션 구조의 상세 화면은 반드시 공통 템플릿을 따른다.
> 스펙: `docs/specs/design/detail_screen_template.md`

- **프로그레스바 패턴 통일** — 점선 커넥터 + 가운데 정렬 필수. `_DashedLinePainter` + `MainAxisAlignment.center` (#26)
- **하단 액션바 패턴 통일** — `buttonHeightSmall` + `radiusMedium` + `buttonSmall` 폰트. `CurrentRequestBox` 참조 (#26)
- **아이콘 통일** — 일정 변경: `swap_horiz_rounded`, 레슨 완료: `check_circle_outline`. 화면별 다른 아이콘 금지 (#26)
- **새 상세 화면 추가 전** — `detail_screen_template.md` 체크리스트 통과 필수

```bash
# 상세 화면 프로그레스바 일관성 검증
grep -rn "MainAxisAlignment.center" --include="*.dart" features/ | grep -i "progress\|session"
# 하단 바 버튼 높이 통일 검증
grep -rn "buttonHeightSmall" --include="*.dart" features/ | grep -i "bottom\|input\|action"
```

## 상태별 가이드 메시지 규칙

- **상단 가이드 title = 리스트 actionLabel** — 리스트↔챗 일관성 (#25)
- **가이드 색상 2색** — action(primary) / wait(grey). 5색 이상 금지 (#25)
- **과거 챕터 펼침 시 가이드 숨김** — `showGuide: false` 전달 (#25)
- **상태 라벨은 역할별** — 선생님: 행동 중심 (입금 대기), 학생: 상태 중심 (결제 필요) (#25)
- **가이드 스펙**: `docs/specs/schedule/chat_guide_message_spec.md`

## Notebook × Score 아이콘 정책 (HARD-GATE)

> 스펙: `docs/specs/design/notebook/README.md` §9 (A2 — 선택적 강제)

**시그니처 영역 (강제)**: `core/widgets/notebook/`, `*_stamp.dart`, `*_masthead.dart`, `*empty_state*.dart`
- Material `Icons.*` 금지 → `NotebookGlyph` 사용 (`core/widgets/notebook/notebook_glyph.dart`)
- 30개 글리프 상수 제공 (음악 ♩ 𝄞 / 체크 ✓ ✗ / 화살표 → ‹ › / 별 ★ ☆ / 좋아요 ♥ ♡ / 점 • · ● ○ 등)

**일반 영역 (Material 허용)**: navigation/utility/데이터 인디케이터 — 시스템 affordance 컨벤션 우선

**예외**: `// ignore: notebook-icon` 주석 + 사유 (시그니처 영역에서 의도적 Material 사용)

**검증 grep**:

```bash
# 시그니처 영역 Icons.* 잔재 검출 (위반 후보)
grep -rn "Icons\." frontend/lib/core/widgets/notebook/ --include="*.dart"
grep -rn "Icons\." frontend/lib/core/widgets/empty_state_widget.dart
grep -rn "Icons\." frontend/lib --include="*_stamp.dart"
grep -rn "Icons\." frontend/lib --include="*_masthead.dart"
grep -rn "Icons\." frontend/lib --include="*empty_state*.dart"

# emoji 사용 검출 (정책 위반 — 평면 잉크 메타포 X)
grep -rn "🎵\|🎶\|❤️\|⭐" frontend/lib --include="*.dart"
```

**자동 감지**: `.claude/hooks/check-notebook-icon.sh` PostToolUse 훅 (stderr 경고, exit 0)
