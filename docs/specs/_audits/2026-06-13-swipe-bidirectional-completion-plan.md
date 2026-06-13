# 양방향 스와이프 표준 완성 — 구현 계획 (Phase 1)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development 또는 superpowers:executing-plans 로 task 단위 실행. 스텝은 체크박스(`- [ ]`) 추적.

**Goal:** 어제(2026-06-12) 시작된 양방향 스와이프 전환을 표준 레벨에서 완성한다 — `SwipeActionTone` 3색 잉크 확장 + 전 문서(swipe_action.md / ux-rules.md / CLAUDE.md) drift 제거. 적용(전수 마이그레이션)은 Phase 2 별도 계획.

**Architecture:** 위젯 `SwipeActionTile`은 이미 양방향(`actions` 우→좌, `startActions` 좌→우) 구현 완료. 이 계획은 (1) 편의 액션용 `convenience` tone(녹색 `paperOk`)을 추가하고, (2) 정책 문서 3종의 내부 모순·누락을 제거해 "단방향 destructive 1개" 시대 잔재를 정리한다. 코드 변경은 위젯 1파일 + 테스트 1파일로 한정, 나머지는 문서.

**Tech Stack:** Flutter 3.29.0, `flutter_test` (widget test), 아키텍처 계약 테스트(`dart:io` 소스 grep 방식).

---

## 배경 — 현재 상태와 drift (2026-06-13 감사)

사용자 지시("리스트 스와이프 공통화 — 우→좌=삭제/편집, 좌→우=편의기능")는 **이미 부분 구현된 상태**:

- 위젯 `frontend/lib/core/widgets/swipe_action_tile.dart` — 양방향 완성 (`actions` + `startActions`, `_settleDrag` 양방향 처리).
- 스펙 `docs/_components/swipe_action.md` v3.0 — "원칙 4(방향 정책)" 추가됨.
- 회귀 테스트 `test/core/widgets/swipe_action_tile_test.dart` — 양방향 5케이스 통과.
- 계약 테스트 `test/architecture/swipe_action_contract_test.dart` — 3개 파일에서 편집-스와이프(`AppStrings.swipeActionEdit`) 강제.

**확정된 설계 결정 (사용자 2026-06-13):**

| 항목 | 결정 |
|---|---|
| 우→좌 (`actions`) | 맥락별 **1개** — 삭제(`destructive`, 버밀리온) 또는 편집(`normal`, ink) |
| 좌→우 (`startActions`) | 도메인별 핵심 **1개** (없으면 단방향), `convenience` tone(녹색) |
| 다중액션 | 2개 이하(우1+좌1) 스와이프 흡수 / 3개↑ 복잡건 행 탭 → BottomSheet 유지 |
| destructive 확인 | 다이얼로그 유지(원칙 3) |
| 범위 | 단계적 — 본 계획은 **표준 정립**만 |

**제거할 drift (Phase 1 범위):**

| 위치 | 문제 |
|---|---|
| `swipe_action.md` 원칙1 ↔ 원칙4 | "destructive **1개만**" vs "삭제·**편집**" 모순 |
| `swipe_action.md` Props 표 | `startActions` 누락 + `actions` 설명 "왼쪽 노출"(실제 오른쪽) 오류 |
| `swipe_action.md` 상태 표 | 구(舊) 단방향 설명 ("왼쪽 스와이프 → 닫힘") |
| `swipe_action_tile.dart` tone | `{normal, destructive}` 2종 → 편의 액션에 의미 색 부재 |
| `.claude/rules/ux-rules.md` | "스와이프 액션 3원칙" (원칙 4 미반영) |
| `CLAUDE.md` (프로젝트) | "swipe 3원칙" (원칙 4 + tone 미반영) |

---

## File Structure

| 파일 | 변경 | 책임 |
|---|---|---|
| `frontend/lib/core/widgets/swipe_action_tile.dart` | Modify | `SwipeActionTone`에 `convenience` 추가 + 색 매핑 |
| `frontend/test/core/widgets/swipe_action_tile_test.dart` | Modify | convenience tone 색 회귀 테스트 추가 |
| `docs/_components/swipe_action.md` | Modify | 원칙1↔4 정합, Props/상태 표 갱신, tone 3종, 도메인별 편의 매핑 가이드 |
| `.claude/rules/ux-rules.md` | Modify | 스와이프 3원칙 → 4원칙 + tone |
| `CLAUDE.md` (프로젝트 루트) | Modify | swipe 3원칙 → 4원칙 + tone |

코드 변경은 위젯+테스트 2파일로 한정 (surgical). 계약 테스트(`swipe_action_contract_test.dart`)는 **변경 없음** — Phase 1은 적용 파일을 건드리지 않으므로 그대로 통과해야 한다.

---

## Task 1: `convenience` tone 추가 (위젯, TDD)

**Files:**
- Modify: `frontend/lib/core/widgets/swipe_action_tile.dart:11` (enum), `:195-196` (색 매핑)
- Test: `frontend/test/core/widgets/swipe_action_tile_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`swipe_action_tile_test.dart`의 `group('SwipeActionTile 방향 정책', ...)` 안에 추가:

```dart
testWidgets('convenience tone 버튼 배경 = paperOk(녹색)', (tester) async {
  await tester.pumpWidget(
    harness(
      actions: [deleteAction(() {})],
      startActions: [
        SwipeAction(
          label: '완료',
          icon: Icons.check,
          tone: SwipeActionTone.convenience,
          onPressed: () {},
        ),
      ],
    ),
  );

  await tester.drag(find.text('row-content'), const Offset(200, 0));
  await tester.pumpAndSettle();

  final material = tester.widget<Material>(
    find.ancestor(of: find.text('완료'), matching: find.byType(Material)).first,
  );
  expect(material.color, AppColors.paperOk);
});
```

테스트 상단에 `import 'package:lessonaza/core/theme/app_colors.dart';` 추가 (없으면).

- [ ] **Step 2: 테스트 실패 확인**

Run: `cd frontend && flutter test test/core/widgets/swipe_action_tile_test.dart`
Expected: FAIL — `SwipeActionTone.convenience` 미정의 (컴파일 에러) 또는 색 불일치.

- [ ] **Step 3: 최소 구현**

`swipe_action_tile.dart:11`:
```dart
enum SwipeActionTone { normal, destructive, convenience }
```

`swipe_action_tile.dart:194-196` `_SwipeActionButton.build` 색 매핑 교체:
```dart
final color = switch (action.tone) {
  SwipeActionTone.destructive => AppColors.paperAccent,
  SwipeActionTone.convenience => AppColors.paperOk,
  SwipeActionTone.normal => AppColors.ink,
};
```

dartdoc(`SwipeAction` 위 주석)에 tone 의미 한 줄 추가:
```
///   - tone: normal(편집·ink) / destructive(삭제·버밀리온) / convenience(편의·녹색)
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `cd frontend && flutter test test/core/widgets/swipe_action_tile_test.dart`
Expected: PASS (기존 5 + 신규 1 = 6 케이스).

- [ ] **Step 5: analyze + 계약 테스트 회귀**

Run: `cd frontend && flutter analyze lib/core/widgets/swipe_action_tile.dart && flutter test test/architecture/swipe_action_contract_test.dart`
Expected: analyze 0 issue, 계약 2 테스트 PASS (변경 없으므로 영향 없음).

- [ ] **Step 6: 커밋**

```bash
git add frontend/lib/core/widgets/swipe_action_tile.dart frontend/test/core/widgets/swipe_action_tile_test.dart
git commit -m "feat(ux): SwipeActionTone convenience(녹색) 추가 — 양방향 3색 잉크"
```

---

## Task 2: `swipe_action.md` 정합화 (스펙)

**Files:** Modify `docs/_components/swipe_action.md`

- [ ] **Step 1: 버전 헤더 갱신** — `> 버전: 3.1` / `> 최종 업데이트: 2026-06-13 (원칙1↔4 정합, tone 3종, 편의 매핑)`

- [ ] **Step 2: 원칙 1 정정** — "destructive 액션 1개만" → **"우→좌 관리 액션은 맥락별 1개(삭제=`destructive` 또는 편집=`normal`). 한 방향에 2개 이상 금지."**

- [ ] **Step 3: 원칙 2 정정** — "swipe 안에 2+ 액션 금지" → **"한 방향(우→좌 또는 좌→우)에는 1개. 양방향 합쳐 최대 2개(관리 1 + 편의 1). 3개 이상 또는 양쪽에 안 떨어지는 액션 = 행 탭 → BottomSheet."**

- [ ] **Step 4: tone 3종 표 추가** (원칙 4 아래):

```markdown
### tone — 3색 잉크 메타포

| tone | 색 | 용도 |
|---|---|---|
| `destructive` | `paperAccent` (#9B1B12 버밀리온) | 삭제·연결 해제 (우→좌, 확인 다이얼로그 필수) |
| `normal` | `ink` (검정) | 편집 (우→좌) |
| `convenience` | `paperOk` (#3F5D2F 녹색 펜) | 편의 기능 (좌→우, 즉시 실행) |
```

- [ ] **Step 5: Props 표 교체** — `startActions` 행 추가 + `actions` 설명 "왼쪽" → "오른쪽" 정정:

```markdown
| `actions` | `List<SwipeAction>` | O | - | **우→좌** 스와이프로 **오른쪽**에 노출. 관리(삭제 OR 편집) 1개 |
| `startActions` | `List<SwipeAction>` | X | `const []` | **좌→우** 스와이프로 **왼쪽**에 노출. 편의 기능 1개 (없으면 단방향) |
```

- [ ] **Step 6: 상태 표 교체** — 양방향 반영:

```markdown
| 우→좌 스와이프 | 오른쪽에 관리 액션, 본문 왼쪽 이동 |
| 좌→우 스와이프 | startActions 있으면 왼쪽에 편의 액션 / 없으면 닫기만 |
| 관리 노출 중 좌→우 | 닫힘 (편의 패널로 점프 안 함) |
| 액션 탭 | 닫힘 후 콜백 (destructive는 확인 다이얼로그 경유) |
```

- [ ] **Step 7: 편의(좌→우) 코드 예시 + 도메인별 매핑 가이드 추가** (사용처 표 위):

```markdown
### 좌→우 편의 액션 예시

\```dart
SwipeActionTile(
  child: ListTile(title: Text(item.title)),
  actions: [ /* 우→좌: 삭제 또는 편집 1개 */ ],
  startActions: [
    SwipeAction(
      label: AppStrings.swipeActionShare, // Phase 2: 도메인별 편의 라벨을 AppStrings에 추가
      icon: Icons.share_outlined,
      tone: SwipeActionTone.convenience,
      onPressed: () => _share(item),
    ),
  ],
)
\```

### 도메인별 편의 액션 매핑 (Phase 2 적용 기준)

| 리스트 도메인 | 좌→우 편의 (1개) | 우→좌 관리 (1개) |
|---|---|---|
| 녹음(recordings) | 공유 | 삭제 |
| 레퍼토리/곡 | 대표설정 또는 보관 | 삭제 |
| 피드백·팁 템플릿 | (없음 — 단방향) | 편집 |
| 연습 노트 | (없음 — 단방향) | 편집 |
| 입금 계좌 | 대표설정 | 삭제 |
| 연결(학생/학부모) | (없음 — 단방향, 복잡건 BottomSheet) | 연결 해제 |
| 휴무/일정 예외 | (없음 — 단방향) | 삭제 |
| 알림 | 읽음 처리 | 삭제 |

> 매핑은 Phase 2 착수 시 도메인 담당과 재확인. "편의 없음" 행은 좌→우 미설정(단방향 유지).
```

- [ ] **Step 8: 검증 + 커밋**

Run: `cd frontend && flutter test test/architecture/swipe_action_contract_test.dart` (스펙 변경이 계약을 깨지 않는지)
Expected: PASS.

```bash
git add docs/_components/swipe_action.md
git commit -m "docs(swipe): §원칙1↔4 정합 + Props/상태 표 갱신 + tone 3종 + 편의 매핑"
```

---

## Task 3: `ux-rules.md` 4원칙 + tone 갱신 (룰)

**Files:** Modify `.claude/rules/ux-rules.md` (인터랙션 규칙 §스와이프 액션 3원칙)

- [ ] **Step 1:** "스와이프 액션 3원칙 (HARD-GATE, audit 2026-06-10)" → **"스와이프 액션 4원칙 (HARD-GATE, 2026-06-13 방향+tone)"** 으로 제목 갱신.

- [ ] **Step 2:** 원칙 1·2 문구를 swipe_action.md Task 2와 동일하게 정정 (맥락별 1개 / 양방향 최대 2개 / 3+ BottomSheet).

- [ ] **Step 3:** 원칙 4 추가: "우→좌=관리(삭제 `destructive` 또는 편집 `normal`) 오른쪽 노출 / 좌→우=편의(`convenience` 녹색) 왼쪽 노출, 없으면 단방향. 전 화면 공통."

- [ ] **Step 4: 커밋**

```bash
git add .claude/rules/ux-rules.md
git commit -m "docs(rules): ux-rules 스와이프 3원칙 → 4원칙(방향+tone) 갱신"
```

---

## Task 4: `CLAUDE.md` 4원칙 갱신 (프로젝트 루트)

**Files:** Modify `CLAUDE.md`

> ⚠️ CLAUDE.md는 다중 세션 편집 파일 — surgical edit, 고유 앵커로 정확히 1곳만 교체.

- [ ] **Step 1:** "핵심 규칙" 표의 "스와이프 액션 (3원칙)" 행 → "(4원칙)" + 방향/tone 한 줄 추가.

- [ ] **Step 2:** "공통 UI 패턴 > swipe 3원칙 (audit 2026-06-10 — HARD-GATE)" 블록에 원칙 4(방향) + tone 3종 1줄 추가. 기존 1~3 문구는 맥락별 1개로 미세 정정.

- [ ] **Step 3: 커밋**

```bash
git add CLAUDE.md
git commit -m "docs(claude): swipe 3원칙 → 4원칙(방향+3색 tone) 반영"
```

---

## Verification (Phase 1 완료 게이트)

- [ ] `cd frontend && flutter test test/core/widgets/swipe_action_tile_test.dart` → 6/6 PASS
- [ ] `cd frontend && flutter test test/architecture/swipe_action_contract_test.dart` → 2/2 PASS (회귀 없음)
- [ ] `cd frontend && flutter analyze lib/core/widgets/swipe_action_tile.dart` → 0 issue
- [ ] `grep -n "convenience" lib/core/widgets/swipe_action_tile.dart` → enum + 색 매핑 확인
- [ ] swipe_action.md / ux-rules.md / CLAUDE.md 에 "destructive 1개만" 잔재 grep → 0건
- [ ] Lore trailer: 정책 변경이므로 마지막 커밋에 `Directive:` (양방향 3색 채택) 기록 (프로젝트 bare-key 포맷)

**Red-Green 검증(tone)**: Task 1 Step 2에서 FAIL 확인 → Step 4 PASS 확인으로 충족.

---

## 로드맵 — 후속 Phase (별도 계획)

| Phase | 범위 | 산출 |
|---|---|---|
| **2** | 전수 적용 — 21개 `SwipeActionTile`에 도메인별 `startActions` 추가, `schedule_tab` `Dismissible`→`SwipeActionTile` 일원화, PopupMenu/BottomSheet 중 2개 이하 흡수, 계약 테스트 확장 | 양방향 실사용 + 회귀 테스트 |
| **3** | 공통 카드 통합 — `LessonInfoCard`/`StatsGridCard`/`ActionBottomSheet` 등 중복 위젯 공통화 | core/widgets 신규 + 중복 제거 |
| **4** | 노트북×악보 일관성 보강 — 6대 시그니처 체크리스트로 신규/누락 화면 감사 | 화면별 위반 정정 |

각 Phase는 독립 worktree + PR. Phase 1 머지 후 Phase 2 계획 착수.
