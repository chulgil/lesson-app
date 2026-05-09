# 상세 화면 공통 템플릿

> 적용 범위: 레슨요청 상세, 수강권 상세, 스케줄 조절 상세처럼 "프로그레스바 + 채팅/이벤트 히스토리 + 하단 액션" 구조를 가진 화면.
> 기준 화면: `request_detail_screen.dart` (레슨요청 상세)
> 디자인 SSOT: `docs/specs/design/notebook/README.md` (Notebook × Score)
> 토큰 SSOT: `AppColors` (§2), `NotebookTypography` (§4), `AppTypography` (본문), `AppSpacing`

## 0. Notebook × Score 토큰 요약

본 문서의 모든 시각 규칙은 Notebook × Score 디자인 시스템을 따른다. 레거시 토큰은 사용하지 않는다.

| 역할 | 토큰 | 레거시 (금지) |
|------|------|--------------|
| 기본 배경 | `AppColors.paper` | `surfaceLight`, `white`, `Colors.white` |
| 강조 배경 | `AppColors.paperDark` | — |
| 보더/구분선 | `AppColors.inkQuaternary` 1px | `borderLight`, `dividerColor` |
| 구분선 위젯 | `ThinRule` (1px inkQuaternary) | `Divider`, `BoxDecoration(border)` |
| 액센트 | `AppColors.paperAccent` (Vermillion) | `primary`, `Theme.of(context).primaryColor` |
| 완료 | `AppColors.paperOk` | `Colors.green`, `success` |
| 본문 텍스트 | `AppColors.ink` | `Colors.black`, `textColor` |
| 보조 텍스트 | `AppColors.inkSecondary`, `inkTertiary` | `grey`, `Colors.grey` |
| 타이포 (제목) | `NotebookTypography` (masthead, pieceTitle, appBarTitle) | — |
| 타이포 (본문) | `AppTypography` (bodySmall, bodyMedium, buttonSmall) | — |
| 모서리 | `BorderRadius.zero` | `radiusMedium`, `BorderRadius.circular(N)` |
| 그림자 | 없음 (평면 잉크 §7.115) | `BoxShadow`, `elevation > 0` |
| 카드 | `Container` + `BoxDecoration(border: inkQuaternary 1px)` | `Card`, `Material(elevation)` |

## 1. 표면 SSOT

신규 전체 화면/상세 화면/팝업/바텀시트는 아래 공통 래퍼를 우선 사용한다 (README.md §1.2.0). 개별 화면이 직접 `Scaffold`, `AlertDialog`, `showModalBottomSheet`의 표면을 설계하면 배경색, 모서리, 타이포그래피가 다시 분기되므로 금지한다.

| 표면 | 공통 래퍼 | 파일 | 필수 계약 |
|------|------|------|------|
| 일반 화면 | `NotebookScreenScaffold` | `core/widgets/notebook/notebook_surfaces.dart` | `backgroundColor: AppColors.paper` |
| 상세 화면 | `NotebookDetailScaffold` | `core/widgets/notebook/notebook_surfaces.dart` | `AppColors.paper` 배경, `titleSpacing: 0`, `NotebookTypography.appBarTitle` |
| 다이얼로그 | `NotebookAlertDialog` / `showNotebookDialog` | `core/widgets/notebook/notebook_surfaces.dart` | `AppColors.paper` 배경, `surfaceTintColor: Colors.transparent`, 각진 `AppColors.ink` 테두리, `NotebookTypography.dialogTitle`. 확인/삭제/입력/선택 다이얼로그 공통 표면 |
| 일반 바텀시트 | `showNotebookBottomSheet` / `NotebookBottomSheet` | `core/widgets/notebook/notebook_surfaces.dart` | transparent route, `AppColors.paper` 배경, `BorderRadius.zero`, `BottomSheetHandle`, SafeArea |
| 커스텀/드래그 바텀시트 route | `showNotebookModalBottomSheet` | `core/widgets/notebook/notebook_surfaces.dart` | transparent route, 각진 route shape. child가 `DraggableScrollableSheet` 또는 자체 paper frame을 소유 |
| 카드 표면 | `NotebookCard` | `core/widgets/notebook/notebook_surfaces.dart` | 직접 `Card(` 금지, 각진 paper 카드, `surfaceTintColor: Colors.transparent` |

금지:
- production UI에서 직접 `Scaffold(` 호출. 허용 범위는 `NotebookScreenScaffold`/`NotebookDetailScaffold` 구현 파일 내부뿐이다.
- 직접 `Card(` 호출 (`NotebookCard` 사용)
- 직접 `AlertDialog(` 호출. 신규/수정 코드는 `NotebookAlertDialog` 또는 `showNotebookDialog`를 사용한다.
- `showModalBottomSheet` 직접 호출. 신규/수정 코드는 `showNotebookBottomSheet` 또는 `showNotebookModalBottomSheet`를 사용한다.
- `Colors.white`/Material surface에 의존하는 popup/sheet
- `showDialog`에서 투명 route 위에 spinner만 띄우는 로딩 팝업. 처리중 상태도 `NotebookAlertDialog`/`showNotebookDialog` paper 표면 안에 표시한다.
- 커스텀 `Dialog` 직접 반환 시 `backgroundColor: AppColors.paper`, `surfaceTintColor: Colors.transparent`, `shape: const RoundedRectangleBorder()` 누락
- `Card` 위젯 사용 (평면 잉크 원칙 위반 — `Container` + `BoxDecoration(border)` 사용)
- `BoxShadow`/`elevation > 0` (종이는 평면 잉크, 떠있는 material이 아님 §7.115)

예외:
- 카메라, 녹음 파형, 튜너처럼 실제 미디어 또는 캔버스가 주 표면인 화면은 별도 배경을 허용한다.
- `showNotebookModalBottomSheet` 내부 child가 자체 frame을 소유하는 드래그형 시트는 허용한다. 이 경우 child 내부 첫 표면은 반드시 `AppColors.paper`/`paperDark` 계열이어야 한다.
- 반복 업무 화면의 compact header 예외는 `docs/specs/design/notebook/README.md#121-compact-work-header-예외`를 따른다.

## 2. 레이아웃 구조

```text
NotebookDetailScaffold
  ├─ AppBar
  │   ├─ titleSpacing: 0
  │   ├─ title: "학원이름 학생이름 (타입)" or "학생이름 (타입)"
  │   └─ style: NotebookTypography.appBarTitle
  ├─ Body: Column
  │   ├─ ProgressBar (고정, paper 배경 + inkQuaternary 하단)
  │   ├─ GuideInfoBox (고정, 상황별 가이드)
  │   └─ Expanded: 스크롤 가능 영역 (채팅/이벤트 히스토리)
  └─ bottomNavigationBar: ActionBar (하단 고정)
```

## 3. AppBar 규칙

**HARD-GATE**: 모든 상세 화면은 `NotebookDetailAppBar`를 사용한다. `AppBar(` 직접 사용 금지.

| 항목 | 규칙 |
|------|------|
| 위젯 | `NotebookDetailAppBar(title:)` 또는 `NotebookDetailAppBar(titleWidget:)` |
| titleSpacing | 0 (NotebookDetailAppBar 내부 자동 적용) |
| title 포맷 | `학원이름 학생이름 (타입)` 또는 `학생이름 (타입)` |
| title 스타일 | `NotebookTypography.appBarTitle` |
| 학원 판별 | `LessonClass.type == academy` → name이 학원 이름 |
| 타입 라벨 | 레슨요청: `request.typeDisplayLabel`, 수강권: `subscription.typeLabel` |
| 배경 | 화면 배경과 같은 `AppColors.paper` 톤. Material 기본 surface tint 금지 |
| 액션 | `DetailAppBarAction` enum 사용 (add/edit/delete/share/more/settings) |
| 적용 화면 | RequestDetailScreen, SubscriptionDetailScreen, AnnouncementHistoryScreen, BillingPlansScreen |

## 4. 프로그레스바 규칙

| 항목 | 값 |
|------|-----|
| 배경 | `AppColors.paper` + `AppColors.inkQuaternary` 하단 border |
| 내부 패딩 | `AppSpacing.screenPadding` horizontal, `AppSpacing.space2` vertical |
| 정렬 | `Row` + `Expanded` 커넥터 |
| dot 크기 | 20px dot, 28px active ring |
| 완료 상태 | `AppColors.paperAccent` filled + checkmark 12px + `AppColors.paper` |
| 활성 상태 | `paperAccent` filled + `paperAccentSoft` outer ring 2px |
| 미래 상태 | hollow circle, `inkQuaternary` 1.5px |
| 커넥터 완료 | `_DashedLinePainter(AppColors.paperAccent, 1.5, dash 4, gap 3)` |
| 커넥터 미완료 | `_DashedLinePainter(AppColors.inkQuaternary, 1.5, dash 4, gap 3)` |
| 라벨 색상 | completed/active=`paperAccent`, future=`inkTertiary` |
| 라벨 weight | active/selected=w600, 나머지=normal |

## 5. 하단 액션바 규칙

| 항목 | 값 |
|------|-----|
| 컨테이너 배경 | `AppColors.paper` |
| 상단 border | `AppColors.inkQuaternary` |
| 패딩 | `AppSpacing.space3` 사방 + SafeArea bottom |
| 메시지 입력 | `AppTypography.bodySmall`, 각진 `OutlineInputBorder(borderRadius: BorderRadius.zero)`, `AppColors.inkQuaternary` border, maxLines 8, minLines 1, maxLength 200 |
| 메시지 힌트 | `AppTypography.bodySmall`, `AppColors.inkTertiary`, counterText `''`. 역할 중립 문구를 기본으로 한다. 예: `전달할 메시지를 입력하세요`. 학생 화면에서 `학생에게 전달...`처럼 viewer와 충돌하는 힌트 금지 |
| 버튼 높이 | `AppSpacing.buttonHeightSmall` |
| 버튼 shape | `RoundedRectangleBorder()` (= `BorderRadius.zero`, 각진 원칙 §1.3.1) |
| 버튼 elevation | `0` (평면 잉크 §7.115 — `BoxShadow`/elevation 금지) |
| 버튼 폰트 | `AppTypography.buttonSmall` |
| 주요 버튼 | `ElevatedButton`, `AppColors.paperAccent` 배경, `AppColors.paper` 텍스트, elevation 0 |
| 보조 버튼 | `OutlinedButton`, `AppColors.inkQuaternary` side, `AppColors.inkSecondary` 텍스트 |

```dart
Row(
  children: [
    Expanded(
      child: SizedBox(
        height: AppSpacing.buttonHeightSmall,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.inkQuaternary),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          ),
          child: Text(
            label,
            style: AppTypography.buttonSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: AppSpacing.space2),
    Expanded(
      child: SizedBox(
        height: AppSpacing.buttonHeightSmall,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.paperAccent,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          ),
          child: Text(
            label,
            style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
          ),
        ),
      ),
    ),
  ],
)
```

## 6. 채팅 히스토리 시각 문법

레슨요청 상세(`RequestHistoryChat`)과 수강권 스케줄 조절 상세(`ScheduleChangeEventBubble`)은 같은 채팅 문법을 사용한다. 화면별로 말풍선 유무, 색상, 모서리, 상태 박스가 달라지면 사용자는 이벤트 의미보다 디자인 차이를 먼저 읽게 되므로 금지한다.

상세 화면 배경은 동일하게 `AppColors.paper`를 사용한다. `Scaffold.backgroundColor`를 명시하지 않아 Material 기본 배경이 섞이는 구성을 금지한다.

### 6.1 말풍선 컨테이너

| 항목 | 규칙 |
|------|------|
| 적용 대상 | 모든 사용자 이벤트: 요청, 제안, 수락, 거절, 취소, 결정 변경, 일반 메시지 |
| 정렬 | viewer 기준. 내 이벤트는 오른쪽, 상대 이벤트는 왼쪽 |
| 색상 | 내 이벤트: `AppColors.paperAccentSoft`, 상대 이벤트: `AppColors.paperDark` |
| 모서리 | `AppSpacing.radiusLarge` 기반 말풍선. 꼬리 방향만 4px로 줄여 발신 방향 표시 |
| 최대 너비 | 260px 전후. 화면 너비에 따라 Flexible |
| 발신자 라벨 | 상대 메시지는 이름/역할 표시. 내 메시지도 역할 혼동이 있는 화면에서는 표시 가능 |
| 시간 | 말풍선 외부 하단 caption. 모든 이벤트 동일 |

### 6.2 하단 액션바 상태

| 최신 이벤트 | viewer 기준 | 하단 액션바 |
|------|------|------|
| 내가 보낸 요청/제안/역제안 | 내 이벤트 | `상대방님의 응답을 기다리고 있습니다` + `결정 변경` |
| 상대가 보낸 요청/제안/역제안 | 상대 이벤트 | 후보 슬롯 선택 + `일정 비교` + `수락` |
| 내가 수락한 이벤트 | 내 이벤트 | `상대방님의 응답을 기다리고 있습니다` + `결정 변경` |
| 내가 결정 변경 | 내 이벤트 | 직전 후보를 다시 선택 가능한 상태 |

판정 기준:
- 최신 이벤트의 `actorType`을 viewerRole과 비교해 내 이벤트/상대 이벤트를 판정한다.
- `scheduleChanged`, `scheduleChangeProposed`, `scheduleChangeCountered`, `scheduleChangeAccepted`는 하단 액션 상태를 바꾸는 이벤트다.
- `suggestedSlots`가 없는 이벤트에서는 후보 선택 UI를 노출하지 않는다.
- 목록/상세 deep-link로 특정 회차에 진입한 경우, 그 회차가 아직 일반 visible range 밖이어도 상세는 해당 회차를 보여준다.

### 6.3 말풍선 내부 일정 카드

스케줄 데이터는 말풍선 자체와 분리해 내부 각진 카드로 표시한다.

| 대상 | 내부 카드 |
|------|----------|
| 레슨 신청 희망 일정 1~3순위 | 각진 사각형 일정 카드 |
| 스케줄 변경 후보 1~3순위 | 각진 사각형 일정 카드 |
| 전체 스케줄 변경 고정 요일/시간 | 각진 사각형 일정 카드 |
| 현재/확정 일정 요약 | 각진 사각형 일정 카드 또는 동일한 일정 텍스트 블록 |

내부 일정 카드는 `borderRadius`를 주지 않는다. Notebook × Score의 각진 종이 조각 메타포를 따른다.

### 6.4 상태 이벤트 금지 패턴

수락, 거절, 응답 대기, 결정 변경, 취소 확정은 별도 성공/경고 카드가 아니다. 같은 말풍선 안에서 텍스트와 필요 시 취소선만 사용한다.

금지:
- 수락 이벤트만 초록 체크 아이콘 Row로 렌더
- 결정 변경만 별도 안내 박스로 렌더
- 스케줄 조절 화면만 말풍선이 없고 레슨요청은 말풍선이 있는 형태
- 같은 히스토리 안에서 둥근 말풍선과 각진 말풍선을 혼합

필수:
- `withdrawApproval`은 이전 선택 일정에 `TextDecoration.lineThrough`
- 일정 후보/확정 일정은 같은 시간 라벨 포맷 사용
- 레슨요청과 스케줄 조절 모두 동일한 말풍선 토큰 사용

## 7. 팝업, 다이얼로그, 바텀시트

> 모든 오버레이 표면은 §1 Surface Wrapper SSOT (README.md §1.2.0)를 따른다.
> 핵심 원칙: `AppColors.paper` 배경 + `BorderRadius.zero` + `BoxShadow` 없음 + `AppColors.inkQuaternary` 1px 테두리.

### 7.0 공통 규칙

| 항목 | 규칙 |
|------|------|
| 배경 | `AppColors.paper` (Material surface/`Colors.white` 금지) |
| 모서리 | `BorderRadius.zero` (각진 원칙 §1.3.1) |
| 테두리 | `AppColors.inkQuaternary` 또는 `AppColors.ink` 1px |
| 그림자 | 없음 — `elevation: 0`, `BoxShadow` 금지 (평면 잉크 §7.115) |
| 제목 타이포 | `NotebookTypography.dialogTitle` (다이얼로그), `NotebookTypography.pieceTitle` (시트 헤더) |
| 본문 타이포 | `AppTypography.bodyMedium` |
| 버튼 | §5 하단 액션바 규칙과 동일 (`buttonHeightSmall`, 각진 shape, `buttonSmall` 폰트) |
| 구분선 | `ThinRule` (1px `AppColors.inkQuaternary`). `Divider` 위젯 금지 |
| 내부 카드 | `Container` + `BoxDecoration(border: BorderSide(color: AppColors.inkQuaternary))`. `Card` 위젯 금지 |

### 7.1 다이얼로그

```dart
showDialog<void>(
  context: context,
  builder: (_) => NotebookAlertDialog(
    title: '확인',
    content: const Text('내용'),
    actions: [...],
  ),
);
```

`NotebookAlertDialog` 계약:
- `backgroundColor: AppColors.paper`
- `surfaceTintColor: Colors.transparent`
- `shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.ink))`
- `titleTextStyle: NotebookTypography.dialogTitle`
- `elevation: 0`
- 입력/선택/복수 액션이 필요한 경우에도 `actions`/`content`만 커스터마이즈하고 표면 스타일은 재정의하지 않는다.

금지:
- 기본 `AlertDialog`를 직접 사용해 표면 계약을 화면마다 재정의
- 둥근 dialog shape (`RoundedRectangleBorder(borderRadius: ...)`)
- 투명 로딩 overlay (`Center(child: CircularProgressIndicator())` 단독 반환)
- `Colors.white`, `surfaceTintColor` 기본값 의존
- `BoxShadow`/`elevation > 0`
- 다이얼로그 내부에 `Card` 위젯 중첩

### 7.2 바텀시트

```dart
showNotebookBottomSheet<void>(
  context: context,
  builder: (_) => const SheetContent(),
);
```

`showNotebookBottomSheet` / `NotebookBottomSheet` 계약:
- `Container(color: AppColors.paper)` (내부 배경)
- `BorderRadius.zero` (각진 상단 — 10x Vision)
- `BottomSheetHandle` (drag handle — 3가지 `BorderRadius.circular` 예외 중 하나)
- `SafeArea(bottom: true)`
- 상단 `ThinRule` (1px `AppColors.inkQuaternary` 구분선)

`showNotebookModalBottomSheet`는 child가 이미 `DraggableScrollableSheet`,
키보드 인셋, 자체 frame을 소유한 경우에만 사용한다. 일반 선택/확인/입력 시트는
`showNotebookBottomSheet`가 기본이다.

금지:
- 내부 content에 `AppColors.paper`가 아닌 Material 기본 surface 사용
- handle 없는 업무용 바텀시트
- content 카드 안에 또 카드처럼 보이는 중첩 카드 (`Card` 안의 `Card`)
- `BorderRadius.circular`로 둥근 상단 모서리
- `BoxShadow`/`elevation > 0`

### 7.3 확인/선택 팝업 (BottomSheet 내부 리스트)

바텀시트 안의 선택 리스트(슬롯 선택, 역할 선택 등)는 다음 패턴을 따른다:

| 항목 | 규칙 |
|------|------|
| 리스트 아이템 구분 | `ThinRule` (1px `inkQuaternary`). 각 아이템 사이 |
| 선택 상태 | `AppColors.paperAccentSoft` 배경 + `AppColors.paperAccent` 좌측 3px 세로선 |
| 비선택 상태 | `AppColors.paper` 배경 |
| 아이템 패딩 | `AppSpacing.space3` horizontal, `AppSpacing.space2` vertical |
| 아이템 텍스트 | `AppTypography.bodyMedium` (`AppColors.ink`) |
| 보조 텍스트 | `AppTypography.bodySmall` (`AppColors.inkTertiary`) |

## 8. 화면별 차이점

| 항목 | 레슨요청 상세 | 수강권 상세 |
|------|-------------|-----------|
| 프로그레스바 | LessonProgressBar (5 phase: 신청→확정→결제→진행→완료) | SessionProgressBar (N session: 1회차~8회차) |
| AppBar 타입 | `request.typeDisplayLabel` | `subscription.typeLabel` |
| 채팅 내용 | 전체 이벤트 히스토리 | 스케줄 변경 내역 중심 |
| 하단 주요 버튼 | Phase별 동적 (수락/결제/레슨완료 등) | 메시지 전송 또는 상태 기반 응답 |
| 하단 보조 버튼 | Phase별 동적 (역제안/취소 등) | 일정 변경 또는 결정 변경 |

## 9. 아이콘 규칙

| 액션 | 아이콘 |
|------|--------|
| 일정 변경 | `Icons.swap_horiz_rounded` |
| 레슨 완료 | `Icons.check_circle_outline` |
| 취소 | `Icons.cancel_outlined` |
| 대기 | `Icons.hourglass_top` |
| 결제 | `Icons.card_membership` |

## 10. 새 상세 화면 추가 체크리스트

### Notebook × Score 토큰

- [ ] 배경: `AppColors.paper` (Material surface/`Colors.white` 금지)
- [ ] 보더/구분선: `AppColors.inkQuaternary` 1px 또는 `ThinRule` (`Divider` 금지)
- [ ] 모서리: `BorderRadius.zero` (`radiusMedium`/`BorderRadius.circular` 금지 — 3가지 예외만)
- [ ] 그림자: 없음 (`BoxShadow`/`elevation > 0` 금지, 평면 잉크 §7.115)
- [ ] 카드: `Container` + `BoxDecoration(border)` (`Card` 위젯 금지)

### 표면 래퍼

- [ ] 화면 표면: `NotebookScreenScaffold` 또는 `NotebookDetailScaffold`
- [ ] AppBar: `titleSpacing: 0` + `NotebookTypography.appBarTitle` + "상대방 (타입)" 포맷
- [ ] 팝업: `NotebookAlertDialog` (paper 배경 + 각진 ink 테두리 + elevation 0)
- [ ] 바텀시트: transparent route + `NotebookBottomSheetShell` (paper 배경 + `BorderRadius.zero`)

### 프로그레스바

- [ ] 완료=`AppColors.paperAccent`, 미완료=`AppColors.inkQuaternary`
- [ ] 배경: `AppColors.paper` + `AppColors.inkQuaternary` 하단 1px

### 하단 액션바

- [ ] `AppSpacing.space3` 패딩 + SafeArea + `AppColors.inkQuaternary` 상단 1px
- [ ] 버튼: `AppSpacing.buttonHeightSmall` + 각진 shape + `AppTypography.buttonSmall` + elevation 0
- [ ] 메시지 입력: `AppTypography.bodySmall` + 각진 `OutlineInputBorder(borderRadius: BorderRadius.zero)` + maxLength 200

### 채팅 히스토리

- [ ] 모든 사용자 이벤트 말풍선 + viewer 기준 정렬
- [ ] 말풍선 내부 일정 카드: 각진 사각형 (`BorderRadius.zero`)
- [ ] 상태 이벤트: 별도 성공/경고 카드 아님 — 같은 말풍선 내 텍스트
