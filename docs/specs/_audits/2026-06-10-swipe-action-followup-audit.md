# Swipe Action 일관성 후속 audit — 신규 8건 (D1~D8)

> 작성일: 2026-06-10
> 작성자: Claude (재검증 세션)
> 상태: 사용자 승인 완료, 구현 진행
> 선행: `2026-06-10-swipe-action-consistency-audit.md` (1차 7건 — 모두 main 반영 ✅)
> 범위: P0 3건 + P1 4건 + P2 1건 = **8건** (D1~D8)

---

## 1. 결론

1차 audit 의 C1~C7 모두 main 반영 확인. 사용자 재검증 요청에 따라 추가 grep 으로 **8건의 위반 후보** 신규 식별. 3원칙(swipe destructive 단일 / 다중 BottomSheet / 항상 확인) 그대로 적용.

---

## 2. 갭 카탈로그

### P0 (HIGH — destructive + 다중액션, 사용 빈도 높음)

| # | 위치 | 현재 | 통일 후 |
|---|---|---|---|
| D1 | `practice/practice_recording_screen.dart:802~850` _RecordingItem | PopupMenu(대표/공유/**삭제**) | SwipeActionTile [삭제] + 행 탭 → `RecordingActionsBottomSheet` **재사용** |
| D4 | `profile/repertoire_management_widgets.dart:261` PieceCard | PopupMenu(편집/**삭제**/배정) | SwipeActionTile [삭제] + 행 탭 → 신규 `PieceActionsBottomSheet` ([편집][배정][삭제]) |
| D7 | `students/announcement_history_screen.dart:199` _AnnouncementItem | PopupMenu(편집/**삭제**) | SwipeActionTile [삭제] + 행 탭 → 편집 (단일이라 BottomSheet 불요) |

### P1 (MEDIUM)

| # | 위치 | 현재 | 통일 후 |
|---|---|---|---|
| D2 | `practice/practice_repertoire_screen.dart:169~203` _RepertoireCard | PopupMenu(편집/**보관**) | SwipeActionTile [보관] (destructive 톤) + 행 탭 = 상세 진입 |
| D3 | `practice/section_management/archive_repertoire_tile.dart:46~78` | PopupMenu(복원/**영구삭제**) | SwipeActionTile [영구삭제] + **강화 확인 다이얼로그** + 행 탭 = [복원] |
| D5 | `profile/extended_profile_widgets.dart:230, 342, 465` (Education/Career/Certificate × 3 카드 동일 패턴) | PopupMenu(편집/**삭제**) × 3 | SwipeActionTile [삭제] + 행 탭 = 편집 시트 (3 카드 일괄) |
| D8 | `notifications/notification_item.dart` | InkWell onTap 만 (액션 없음) | `Dismissible` 또는 SwipeActionTile [삭제] + DELETE endpoint(#629) wiring. 행 탭 onTap 유지 |

### P2 (LOW)

| # | 위치 | 현재 | 통일 후 |
|---|---|---|---|
| D6 | `settings/backup_widgets.dart:577` BackupItem | PopupMenu(복원/공유/**삭제**) | SwipeActionTile [삭제] + 행 탭 → 신규 `BackupItemActionsBottomSheet` ([복원][공유][삭제]) |

---

## 3. 통일 디자인 (8건 공통)

3원칙은 1차 audit 와 동일:
1. swipe = destructive 단일 (`SwipeActionTone.destructive`)
2. 다중 액션 = 행 탭 → `showModalBottomSheet`
3. 모든 destructive = `showDialog<AlertDialog>` 확인

### 강화 확인 (영향도 있는 destructive)

- **D3 영구삭제**: "이 항목을 영구 삭제할까요? 복구할 수 없습니다." (붉은 강조)
- **D6 백업 삭제**: "이 백업을 삭제할까요? 복구 불가."
- **D1 녹음 삭제** (이미 C2 패턴): "복구할 수 없습니다." 유지

### 신규 BottomSheet 위젯 (2개)

- `PieceActionsBottomSheet` — 곡 (Piece) 의 [편집][배정][삭제]
- `BackupItemActionsBottomSheet` — 백업 의 [복원][공유][삭제]

### 재사용

- `RecordingActionsBottomSheet` (1차 audit 의 C2 신규) — D1 에서 재사용

---

## 4. 합리적 유지 (변경 없음 — 정책 명문화)

| 위치 | 사유 |
|---|---|
| AppBar customActions × 3 (repertoire_detail/section_detail/edit_lesson) | 헤더 컨트롤, 반복 리스트 아님 |
| recording_player_sheet (속도 메뉴) | non-destructive 단일 선택 |
| profile_visibility / schedule_tab / student_*_tab | 정렬·표시 선택 메뉴 (non-destructive) |
| subscription_template_list (5-10개) | 1차 audit 합의 — PopupMenu 관례 유지 |
| proposal_card / profile_switcher | 단일 선택 |
| students_tab (bulk action) | 행 InkWell 이 선택/상세 담당, bulk 모드와 swipe 충돌 |
| dashboard_tab | 단일 액션만 |

---

## 5. Worktree 분할 (3개)

| Worktree | 브랜치 | 갭 | 도메인 |
|---|---|---|---|
| **WT-A** | `feat/swipe-practice-v2` | D1 + D2 + D3 | practice |
| **WT-B** | `feat/swipe-profile-settings-v2` | D4 + D5 + D6 | profile + settings |
| **WT-C** | `feat/swipe-students-notif` | D7 + D8 | students + notifications |

---

## 6. GitHub 이슈 (3개)

| 이슈 | 갭 | 도메인 |
|---|---|---|
| 신규 | D1 + D2 + D3 | practice |
| 신규 | D4 + D5 + D6 | profile + settings |
| 신규 | D7 + D8 | students + notifications |

---

## 7. 검증 계획

각 worktree:
- 변경된 위젯에 위젯 스모크 테스트
- swipe 동작 (Dismissible 기반)
- 확인 다이얼로그 분기
- D8 (NotificationItem): DELETE endpoint wiring 통합 테스트
- `flutter analyze` exit 0

main 머지 전 통합:
- 1차 audit 7건 + 본 8건 = 총 15곳에서 일관성 유지 확인
- ux-rules grep 패턴 회귀 → PopupMenuButton 위반 후보 0건 (합리적 유지 제외)

---

## 8. 변경 이력

| 날짜 | 변경 |
|---|---|
| 2026-06-10 | 초안 — 1차 audit 후속 8건 + 3원칙 그대로 적용 |
