<!-- @defines: components/swipe_action -->
<!-- @uses: tokens/colors, tokens/typography, tokens/spacing -->

# Swipe Action

> 버전: 3.0
> 최종 업데이트: 2026-06-12 (방향 정책 추가 — 4원칙)

리스트 행에서 반복 관리 액션을 숨겨두고, 스와이프로 액션 버튼을 드러내는 공통 패턴이다.

## 4원칙 (HARD-GATE)

### 원칙 1 — swipe = destructive 단일

한 swipe 액션 안에는 **destructive 액션 1개만** 둔다 (`SwipeActionTone.destructive`). 보통 [삭제] / [연결 해제] 등 1건.

### 원칙 2 — 다중 액션 = 행 탭 → BottomSheet

수정/공유/대표설정 등 2개 이상의 액션이 필요하면 **swipe 대신 행 탭 → `showModalBottomSheet`** 로 액션 리스트를 펼친다. swipe 안에 2+ 액션을 넣으면 좁은 화면 가독성 저하 + 사용자 멘탈 모델 분산 + destructive 시각 구분 약화.

### 원칙 3 — 모든 destructive 는 확인 다이얼로그

swipe 의 destructive 액션 `onPressed` 는 **반드시 `showDialog<AlertDialog>`** 로 확인 단계를 거친 뒤 실행한다. 영향 범위가 있으면 강화 메시지 (영향 카운트 / 학생 노출 등).

### 원칙 4 — 방향: 우→좌 = 관리(삭제·편집) / 좌→우 = 편의 (2026-06-12)

- **오른쪽→왼쪽 스와이프** = 삭제·편집 등 관리/destructive 액션 (`SwipeActionTile.actions`, **오른쪽에서 노출**). iOS/Android trailing 삭제 관행과 일치.
- **왼쪽→오른쪽 스와이프** = 다른 편의 기능 (`SwipeActionTile.startActions`, **왼쪽에서 노출** — 선택적). 정의하지 않으면 좌→우 스와이프는 열린 패널 닫기만 수행.
- 두 방향의 의미를 화면별로 바꾸지 않는다 — 전 화면 공통.

## 사용 원칙

- 리스트 행의 주요 정보는 항상 먼저 보이고, 보조 관리 액션은 **우→좌 스와이프**로 노출한다 (원칙 4).
- 한 행의 swipe 액션은 destructive **1개**만. 다중 액션은 BottomSheet 로 분리 (원칙 2).
- 삭제 같은 파괴적 액션은 `paperAccent` 배경 + `SwipeActionTone.destructive` 사용.
- 같은 화면 안에서 행별 trailing 아이콘 버튼과 스와이프 액션을 혼용하지 않는다.
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

### 원칙 1+3 — swipe destructive 단일 + 확인 다이얼로그

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

### 원칙 2 — 다중 액션은 BottomSheet

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
| `actions` | `List<SwipeAction>` | O | - | 왼쪽에 노출할 액션 (원칙 1 — destructive 1개만) |
| `actionWidth` | `double` | X | `72` | 액션 버튼 너비 |

## 상태

| 상태 | 동작 |
|------|------|
| 기본 | 본문만 표시 |
| 오른쪽 스와이프 | 왼쪽에 액션 버튼 표시, 본문은 오른쪽으로 이동 |
| 왼쪽 스와이프 | 액션 버튼 닫힘 |
| 액션 탭 | 액션 닫힘 후 콜백 실행 (destructive 는 확인 다이얼로그 경유) |

## 구현

- Flutter 공통 위젯은 `frontend/lib/core/widgets/swipe_action_tile.dart`를 사용한다.
- production UI 문구는 `AppStrings`를 사용한다.
- raw color, raw spacing, raw typography를 쓰지 않는다.

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

> 정비 audit: `docs/specs/_audits/2026-06-10-swipe-action-consistency-audit.md`

<!-- @used-by: profile/lesson_time_settings, schedule/time_exception_screen, practice/section_recording_list_item, profile/instrument_management_screen, profile/bank_account_edit_screen, settings/all_recordings_screen, invite/my_connections_screen -->
