# Swipe Action 일관성 audit + 통일 패턴 + 스펙/지침 갱신

> 작성일: 2026-06-10
> 작성자: Claude (UX 전수 점검 세션)
> 상태: 사용자 승인 완료, 구현 진행
> 범위: P0 5건 + P1 2건 = **7건** + 스펙/지침 갱신 + Claude 룰 보강

---

## 1. 결론 (Inverted Pyramid)

`SwipeActionTile` 공통 컴포넌트는 이미 6곳에 적용되었으나, **7곳에서 일관성 위반** (trailing IconButton 중복, PopupMenuButton 대신 사용, 다중 액션 정책 부재). 이번 작업으로 모든 반복 리스트의 행 단위 액션을 통일 패턴으로 정리하고, **CLAUDE.md / .claude/rules / 컴포넌트 스펙 / UX 가이드라인** 4곳에 명문화하여 향후 동일 실수 방지.

---

## 2. 통일 패턴 (3원칙)

### 원칙 1 — swipe 는 destructive 단일

```
swipe 좌(←) → destructive 액션 1개만 (보통 [삭제] / [연결 해제] 등)
```

`SwipeAction(label: ..., icon: Icons.delete_outline, tone: SwipeActionTone.destructive, onPressed: ...)`

### 원칙 2 — 다중 액션은 행 탭 → BottomSheet

```
행 ListTile/Card 탭 → showModalBottomSheet → 액션 리스트 ([수정] [공유] [전환] [삭제] ...)
```

이유: swipe 안에 2+ 액션을 넣으면 ⓐ 작은 화면 좁아짐 ⓑ 사용자 멘탈 모델 분산 ⓒ destructive 와 일반 액션의 시각적 구분 약함.

### 원칙 3 — 모든 destructive 는 확인 다이얼로그

```
swipe 액션 onPressed → AlertDialog 확인 → 실행
```

영향도가 있으면 강화 메시지:
- 일반: `"이 X를 삭제할까요?"`
- 강화: `"이 계좌를 삭제하면 학생에게 표시되는 결제 정보에서 사라집니다."` (영향 카운트 포함 시 더 좋음)

---

## 3. 갭 카탈로그 (P0 5건 + P1 2건)

### P0 (HIGH — ux-rules 위반)

| # | 위치 | 현재 | 통일 후 |
|---|---|---|---|
| C1 | `schedule/time_exception_screen.dart` 휴무 카드 | trailing IconButton(delete) | swipe [삭제] + 확인 다이얼로그 |
| C2 | `practice/section_recording_list_item.dart` 녹음 파일 | PopupMenuButton 3개 | swipe [삭제] + 탭 → BottomSheet [대표설정][공유][삭제] |
| C3 | `profile/instrument_management_screen.dart` 악기 | ListTile trailing delete | swipe [삭제] + 확인 |
| C4 | `profile/bank_account_edit_screen.dart` 계좌 | Card trailing delete | swipe [삭제] + 강화 확인 (학생 영향) |
| C5 | `settings/all_recordings_screen.dart` 녹음 목록 | Row 3 IconButton (play/link/delete) | swipe [삭제] + 탭 → BottomSheet [재생][공유][링크 복사] |

### P1 (MEDIUM)

| # | 위치 | 현재 | 통일 후 |
|---|---|---|---|
| C6 | `invite/my_connections_screen.dart` 연결 | more_vert PopupMenu | swipe [연결 해제] + 강화 확인 + 탭 → BottomSheet 상세 |
| C7 | `parent_home/child_profiles_screen.dart` 자녀 | Column 2 버튼 (전환/편집) | **swipe 없음** (자녀는 destructive 부적절) + 탭 → BottomSheet [학생 계정 전환][프로필 편집] |

> C7 예외: 자녀 카드의 swipe 삭제는 의미상 잘못된 메타포. 다중 액션 BottomSheet 만 적용.

---

## 4. 스킵 (swipe 부적절)

| 위치 | 사유 |
|---|---|
| `students_tab.dart` 학생 목록 | bulk action 모드와 충돌 — 별도 설계 필요 |
| `subscription_template_list_screen.dart` | PopupMenu 관례 OK (적은 수, ~5-10개) |
| `parent_dashboard_tab.dart`, `profile_tab.dart` masthead | 헤더 컨트롤 (단일 액션) |
| `lessons/feedback_*` 카드 | 상태 표시만, 액션 없음 |
| `student_lesson_card.dart`, `_InquiryCard`, `_SectionListItem`, `trial_booking_card.dart` | 행 단위 액션 자체 없음 |

---

## 5. 갱신 대상 스펙/지침 (4종)

| 파일 | 변경 |
|---|---|
| `docs/_components/swipe_action.md` | 3원칙 본문 추가 + 다중 액션 시 BottomSheet 패턴 + 확인 다이얼로그 패턴 + 코드 예시 |
| `.claude/rules/ux-rules.md` | "스와이프 액션 우선" 규칙 보강 — 3원칙 명문화 + 위반 grep 패턴 추가 |
| `docs/specs/design/ux_guidelines.md` | swipe 섹션 보강 — destructive 단일 + 다중액션 BottomSheet 정책 |
| `frontend/lib/core/widgets/swipe_action_tile.dart` 주석 | dartdoc 에 3원칙 요약 (옵션) |

---

## 6. Worktree 분할 (4개)

| Worktree | 브랜치 | 갭 | 도메인 |
|---|---|---|---|
| **WT-A** | `feat/swipe-schedule-practice` | C1 + C2 | schedule + practice |
| **WT-B** | `feat/swipe-profile-settings` | C3 + C4 + C5 | profile + settings |
| **WT-C** | `feat/swipe-relationship-parent` | C6 + C7 | invite + parent_home |
| **WT-D** | `docs/swipe-consistency-spec` | 가이드라인 4종 갱신 | docs only |

각 worktree 의 PR 은 독립적으로 머지 가능 (도메인 분리). audit doc 자체는 WT-D 에 포함.

---

## 7. GitHub 이슈 (3개 + 1 docs)

| 이슈 | 갭 | 도메인 |
|---|---|---|
| #N1 | C1 + C2 | swipe-schedule-practice |
| #N2 | C3 + C4 + C5 | swipe-profile-settings |
| #N3 | C6 + C7 | swipe-relationship-parent |
| #N4 | 가이드라인 갱신 | docs only |

---

## 8. 검증 계획

각 worktree:
- `flutter analyze` exit 0
- 위젯 스모크 테스트 (변경된 ListTile/Card 행마다)
- swipe 동작 통합 테스트 (Dismissible 기반)
- 확인 다이얼로그 테스트 (확인/취소 분기)

main 머지 전 통합:
- 메모리 노트 frontend-verify 규칙 — 시각 확인
- 7건 변경 후 ux-rules grep 패턴으로 회귀 검증 0건

---

## 9. 변경 이력

| 날짜 | 변경 |
|---|---|
| 2026-06-10 | 초안 — 7건 갭 + 3원칙 + 스펙/지침 갱신 계획 |
