<!-- @defines: components/swipe_action -->
<!-- @uses: tokens/colors, tokens/typography, tokens/spacing -->

# Swipe Action

> 버전: 3.2
> 최종 업데이트: 2026-06-13 (관리/기타 분리 — 우→좌=편집·삭제, 좌→우=기타 편의)

리스트 행에서 반복 액션을 숨겨두고, 스와이프로 액션 버튼을 드러내는 공통 패턴이다. **양방향** — 우→좌는 관리(편집·삭제), 좌→우는 그 외 기타/편의 기능(공유·대표설정 등).

## 4원칙 (HARD-GATE)

### 원칙 1 — 우→좌 = 관리 액션 (편집·삭제)

우→좌 스와이프(오른쪽 노출)에는 **관리 액션**을 둔다 — 삭제(`SwipeActionTone.destructive`)·편집(`SwipeActionTone.normal`). **편집과 삭제가 둘 다 필요하면 둘 다 우→좌에 둔다** (관리 묶음, 최대 2개). 삭제만 또는 편집만 필요하면 1개.

### 원칙 2 — 좌→우 = 기타/편의 기능 (3번째 액션부터)

공유·대표설정·복원·재발송·완료 등 **관리(편집·삭제) 외 기타 기능**은 좌→우 스와이프(`convenience`, 왼쪽 노출)에 둔다. 즉 우→좌에 편집·삭제를 채운 뒤 **3번째 액션부터는 좌→우로 분산**한다. 좌→우 기타 기능이 여러 개로 늘어 한눈에 안 들어오면 그때 행 탭 → `showModalBottomSheet` 로 펼친다.

### 원칙 3 — 모든 destructive 는 확인 다이얼로그

swipe 의 destructive 액션 `onPressed` 는 **반드시 `showDialog<AlertDialog>`** 로 확인 단계를 거친 뒤 실행한다. 영향 범위가 있으면 강화 메시지 (영향 카운트 / 학생 노출 등). 편의(`convenience`)·편집(`normal`) 액션은 즉시 실행(토글성).

### 원칙 4 — 방향: 우→좌 = 관리(삭제·편집) / 좌→우 = 편의

- **오른쪽→왼쪽 스와이프** = 삭제·편집 등 관리 액션 (`SwipeActionTile.actions`, **오른쪽에서 노출**). iOS/Android trailing 삭제 관행과 일치.
- **왼쪽→오른쪽 스와이프** = 편의 기능 (`SwipeActionTile.startActions`, **왼쪽에서 노출** — 선택적). 정의하지 않으면 좌→우 스와이프는 열린 패널 닫기만 수행(단방향).
- 두 방향의 의미를 화면별로 바꾸지 않는다 — 전 화면 공통.

### tone — 3색 잉크 메타포

| tone | 색 | 방향 | 용도 | 확인 |
|---|---|---|---|---|
| `destructive` | `paperAccent` (#9B1B12 버밀리온) | 우→좌 | 삭제·연결 해제 | 다이얼로그 필수 |
| `normal` | `ink` (검정) | 우→좌 | 편집 | 즉시 |
| `convenience` | `paperOk` (#3F5D2F 녹색 펜) | 좌→우 | 편의 기능(공유·대표설정·완료 등) | 즉시 |

## 사용 원칙

- 리스트 행의 주요 정보는 항상 먼저 보이고, 보조 관리 액션은 **우→좌 스와이프**로 노출한다 (원칙 4).
- 우→좌는 관리(편집·삭제, 최대 2개), 좌→우는 기타/편의 기능. 기타가 많아 한눈에 안 들어오면 BottomSheet 로 분리 (원칙 2).
- 삭제 같은 파괴적 액션은 `paperAccent` 배경 + `SwipeActionTone.destructive`, 편의 액션은 `paperOk` + `SwipeActionTone.convenience`.
- 같은 화면 안에서 행별 trailing 아이콘 버튼/`PopupMenuButton` 과 스와이프 액션을 혼용하지 않는다.
- 삭제 후 행이 속한 그룹이 비어도 그룹 헤더는 유지하고, 상태를 `휴무`처럼 비활성 라벨로 표시한다.

## 구조

```text
┌────────────────────────────────────┐
│ 09:00 - 18:00                      │  기본 상태
└────────────────────────────────────┘

┌──────────────────────────┬────────┐
│ 09:00 - 18:00            │ 삭제   │  ← 우→좌 스와이프 후 (관리, 오른쪽 노출)
└──────────────────────────┴────────┘

┌────────┬──────────────────────────┐
│ 공유   │ 09:00 - 18:00            │  → 좌→우 스와이프 후 (편의, 왼쪽 노출 — 선택)
└────────┴──────────────────────────┘
```

## 코드 예시

### 원칙 1+3 — 우→좌 삭제 + 확인 다이얼로그

```dart
SwipeActionTile(
  child: ListTile(
    title: Text(item.title),
    onTap: () => _openDetail(context, item),
  ),
  actions: [
    SwipeAction(
      label: AppStrings.delete,
      icon: Icons.delete_outline,
      tone: SwipeActionTone.destructive,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppStrings.deleteConfirmTitle),
            content: Text(AppStrings.deleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.delete),
              ),
            ],
          ),
        );
        if (confirmed == true) await delete();
      },
    ),
  ],
)
```

### 원칙 4 — 좌→우 편의 액션 (convenience tone)

```dart
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
```

### 원칙 2 — 3개 이상은 BottomSheet

```dart
ListTile(
  title: Text(recording.title),
  onTap: () => showModalBottomSheet(
    context: context,
    builder: (_) => RecordingActionsBottomSheet(
      recording: recording,
      onShare: () => _share(recording),
      onSetPrimary: () => _setPrimary(recording),
      onDelete: () => _confirmDelete(recording),
    ),
  ),
)
```

BottomSheet 내부는 `ListTile` 로 액션을 나열하며, destructive 액션은 색상으로 시각 구분한다.

## Props

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `child` | `Widget` | O | - | 이동되는 리스트 행 본문 |
| `actions` | `List<SwipeAction>` | O | - | **우→좌** 스와이프로 **오른쪽**에 노출. 관리(편집·삭제, 최대 2개) (원칙 1) |
| `startActions` | `List<SwipeAction>` | X | `const []` | **좌→우** 스와이프로 **왼쪽**에 노출. 기타/편의 기능 (없으면 단방향) (원칙 2) |
| `actionWidth` | `double` | X | `72` | 액션 버튼 너비 |

`SwipeAction.tone` 은 `normal`(편집·ink) / `destructive`(삭제·버밀리온) / `convenience`(편의·녹색).

## 상태

| 상태 | 동작 |
|------|------|
| 기본 | 본문만 표시 |
| 우→좌 스와이프 | 오른쪽에 관리 액션 버튼, 본문은 왼쪽으로 이동 |
| 좌→우 스와이프 | `startActions` 있으면 왼쪽에 편의 액션 / 없으면 닫기만 |
| 관리 노출 중 좌→우 | 닫힘 (편의 패널로 점프 안 함) |
| 액션 탭 | 닫힘 후 콜백 실행 (destructive 는 확인 다이얼로그 경유) |

## 구현

- Flutter 공통 위젯은 `frontend/lib/core/widgets/swipe_action_tile.dart`를 사용한다.
- production UI 문구는 `AppStrings`를 사용한다.
- raw color, raw spacing, raw typography를 쓰지 않는다.

## 도메인별 편의 액션 매핑 (Phase 2 적용 기준)

| 리스트 도메인 (파일) | 좌→우 기타/편의 | 우→좌 관리 |
|---|---|---|
| 녹음 (all_recordings) | 공유 | 삭제 |
| 수강권 회수 (payment_pending) | 재발송 | 회수 |
| 입금 계좌 (bank_account) | 기본설정 | 삭제 |
| 섹션 녹음 (section_recording_list_item) | 대표설정 | 삭제 |
| 보관 레퍼토리 (archive_repertoire_tile) | 복원 | 영구삭제 |
| 곡 카드 (piece_card) | 배정 | 편집·삭제 |
| 레슨 카드 (schedule_tab) | 완료 | 취소 |
| 피드백·팁 템플릿 | (없음 — 단방향) | 편집·삭제 |
| 연습 노트 (note_list_item / note_card) | (없음 — 단방향) | 편집·삭제 |
| 악기·이력·휴무·일정예외·알림 | (없음 — 단방향) | 삭제 |
| 연결(학생/학부모) | (없음 — 복잡건 BottomSheet) | 연결 해제 |

> 우→좌는 관리(편집·삭제)까지, 그 외 기타 기능(공유·재발송·기본설정·대표설정·복원·배정·완료)만 좌→우. "단방향" 행은 좌→우 미설정.

## 사용처 (적용 사례)

| # | 위치 | 패턴 |
|---|---|---|
| 1 | `profile/lesson_time_settings` | swipe [삭제] 단일 |
| 2 | `schedule/time_exception_screen` (휴무 카드) | swipe [삭제] + 확인 (C1 정비 후) |
| 3 | `practice/section_recording_list_item` | swipe [삭제] + 탭 → BottomSheet (C2 정비 후) |
| 4 | `profile/instrument_management_screen` | swipe [삭제] + 확인 (C3 정비 후) |
| 5 | `profile/bank_account_edit_screen` | swipe [삭제] + 강화 확인 (C4 정비 후) |
| 6 | `settings/all_recordings_screen` | swipe [삭제] + 탭 → BottomSheet (C5 정비 후) |
| 7 | `invite/my_connections_screen` | swipe [연결 해제] + 강화 확인 + 탭 → BottomSheet (C6 정비 후) |

> 좌→우 편의(`startActions`) 실적용은 Phase 2(전수 적용)에서 위 매핑대로 추가.
> 정비 audit: `docs/specs/_audits/2026-06-10-swipe-action-consistency-audit.md`

<!-- @used-by: profile/lesson_time_settings, schedule/time_exception_screen, practice/section_recording_list_item, profile/instrument_management_screen, profile/bank_account_edit_screen, settings/all_recordings_screen, invite/my_connections_screen -->
