<!-- @defines: components/swipe_action -->
<!-- @uses: tokens/colors, tokens/typography, tokens/spacing -->

# Swipe Action

> 버전: 3.1
> 최종 업데이트: 2026-06-13 (원칙1↔4 정합, tone 3종, 도메인별 편의 매핑)

리스트 행에서 반복 관리 액션을 숨겨두고, 스와이프로 액션 버튼을 드러내는 공통 패턴이다. **양방향** — 우→좌는 관리(삭제·편집), 좌→우는 편의 기능.

## 4원칙 (HARD-GATE)

### 원칙 1 — 우→좌 관리 액션은 맥락별 1개

한 방향(우→좌)에는 관리 액션 **1개만** 둔다. 행 성격에 맞춰 **삭제**(`SwipeActionTone.destructive`) **또는 편집**(`SwipeActionTone.normal`) 중 하나. 보통 [삭제] / [연결 해제] / [편집] 등 1건. **한 방향에 2개 이상 금지.**

### 원칙 2 — 다중 액션 한도와 BottomSheet 분리

양방향을 합쳐 **최대 2개**(우→좌 관리 1 + 좌→우 편의 1)까지만 스와이프로 노출한다. 3개 이상이거나 양쪽으로 자연스럽게 떨어지지 않는 액션 묶음은 **swipe 대신 행 탭 → `showModalBottomSheet`** 로 액션 리스트를 펼친다. 한 방향에 2+ 액션을 넣으면 좁은 화면 가독성 저하 + 멘탈 모델 분산 + destructive 시각 구분 약화.

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
- 한 방향의 swipe 액션은 **1개**만. 양방향 합쳐 2개 초과 시 BottomSheet 로 분리 (원칙 2).
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
| `actions` | `List<SwipeAction>` | O | - | **우→좌** 스와이프로 **오른쪽**에 노출. 관리(삭제 OR 편집) 1개 (원칙 1) |
| `startActions` | `List<SwipeAction>` | X | `const []` | **좌→우** 스와이프로 **왼쪽**에 노출. 편의 기능 1개 (없으면 단방향) |
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
